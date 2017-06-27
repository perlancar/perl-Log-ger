package Log::ger;

# DATE
# VERSION

#IFUNBUILT
use strict;
use warnings;
#END IFUNBUILT

our %Levels = (
    fatal   => 1,
    error   => 2,
    warn    => 3,
    info    => 4,
    debug   => 5,
    trace   => 6,
);

our %Level_Aliases = (
    off => 0,
    warning => 3,
);

our $Current_Level = 3;

# a flag that can be used by null output to skip using formatter
our $_logger_is_null;

our $_dumper;

our %Global_Hooks;

# key = phase, value = [ [key, prio, coderef], ... ]
our %Default_Hooks = (
    create_formatter => [
        [__PACKAGE__, 90,
         # the default formatter is sprintf-style that dumps data structures
         # arguments as well as undef as '<undef>'.
         sub {
             my %args = @_;

             my $formatter = sub {
                 return $_[0] if @_ < 2;
                 my $fmt = shift;
                 my @args;
                 for (@_) {
                     if (!defined($_)) {
                         push @args, '<undef>';
                     } elsif (ref $_) {
                         require Log::ger::Util unless $_dumper;
                         push @args, Log::ger::Util::_dump($_);
                     } else {
                         push @args, $_;
                     }
                 }
                 sprintf $fmt, @args;
             };
             [$formatter];
         }],
    ],

    create_routine_names => [
        [__PACKAGE__, 90,
         # the default names are log_LEVEL() and log_is_LEVEL() for subroutine
         # names, or LEVEL() and is_LEVEL() for method names
         sub {
             my %args = @_;

             my $levels = [keys %Levels];

             return [{
                 log_subs    => [map { ["log_$_", $_]    } @$levels],
                 is_subs     => [map { ["log_is_$_", $_] } @$levels],
                 # used when installing to hash or object
                 log_methods => [map { ["$_", $_]        } @$levels],
                 is_methods  => [map { ["is_$_", $_]     } @$levels],
             }];
         }],
    ],

    create_log_routine => [
        [__PACKAGE__, 10,
         # the default behavior is to create a null routine for levels that are
         # too high than the global level ($Current_Level). since we run at high
         # priority (10), this block typical output plugins at normal priority
         # (50). this is a convenience so normally a plugin does not have to
         # deal with level checking.
         sub {
             my %args = @_;
             my $level = $args{level};
             if ($Current_Level < $level ||
                     # there's only us
                     @{ $Global_Hooks{create_log_routine} } == 1
                 ) {
                 $_logger_is_null = 1;
                 return [sub {0}];
             }
             [undef]; # decline
         }],
    ],

    create_is_routine => [
        [__PACKAGE__, 90,
         # the default behavior is to compare to global level. normally this
         # behavior suffices. we run at low priority (90) so normal plugins
         # which use priority 50 can override us.
         sub {
             my %args = @_;
             my $level = $args{level};
             [sub { $Current_Level >= $level }];
         }],
    ],

    before_install_routines => [],

    after_install_routines => [],
);

for my $phase (keys %Default_Hooks) {
    $Global_Hooks{$phase} = [@{ $Default_Hooks{$phase} }];
}

our %Package_Targets; # key = package name, value = \%init_args
our %Per_Package_Hooks; # key = package name, value = { phase => hooks, ... }

our %Hash_Targets; # key = hash address, value = [$hashref, \%init_args]
our %Per_Hash_Hooks; # key = hash address, value = { phase => hooks, ... }

our %Object_Targets; # key = object address, value = [$obj, \%init_args]
our %Per_Object_Hooks; # key = object address, value = { phase => hooks, ... }

sub run_hooks {
    my ($phase, $hook_args, $stop_after_first_result,
        $target, $target_arg) = @_;
    #print "D: running hooks for phase $phase\n";

    $Global_Hooks{$phase} or die "Unknown phase '$phase'";
    my @hooks = @{ $Global_Hooks{$phase} };

    if ($target eq 'package') {
        unshift @hooks, @{ $Per_Package_Hooks{$target_arg}{$phase} || [] };
    } elsif ($target eq 'hash') {
        my ($addr) = "$target_arg" =~ /\(0x(\w+)/;
        unshift @hooks, @{ $Per_Hash_Hooks{$addr}{$phase} || [] };
    } elsif ($target eq 'object') {
        my ($addr) = "$target_arg" =~ /\(0x(\w+)/;
        unshift @hooks, @{ $Per_Object_Hooks{$target_arg}{$phase} || [] };
    }

    my $res;
    for my $hook (sort {$a->[1] <=> $b->[1]} @hooks)  {
        my ($res0, $flow_control) = @{ $hook->[2]->(%$hook_args) };
        if (defined $res0) {
            $res = $res0;
            #print "D:   got result from hook $hook\n";
            last if $stop_after_first_result;
        }
        last if $flow_control;
    }
    return $res;
}

sub add_target {
    my ($target, $target_arg, $args, $replace) = @_;
    $replace = 1 unless defined $replace;

    if ($target eq 'package') {
        unless ($replace) { return if $Package_Targets{$target_arg} }
        $Package_Targets{$target_arg} = $args;
    } elsif ($target eq 'object') {
        my ($addr) = "$target_arg" =~ /\(0x(\w+)/;
        unless ($replace) { return if $Object_Targets{$addr} }
        $Object_Targets{$addr} = [$target_arg, $args];
    } elsif ($target eq 'hash') {
        my ($addr) = "$target_arg" =~ /\(0x(\w+)/;
        unless ($replace) { return if $Hash_Targets{$addr} }
        $Hash_Targets{$addr} = [$target_arg, $args];
    }
}

sub init_target {
    my ($target, $target_arg, $init_args) = @_;

    #print "D:init_target($target, $target_arg, ...)\n";
    my %hook_args = (
        target     => $target,
        target_arg => $target_arg,
        init_args  => $init_args,
    );

    my $package;
    if ($target eq 'package') {
        $package = $target_arg;
    }

    my $formatter =
        run_hooks('create_formatter', \%hook_args, 1, $target, $target_arg);

    my $routine_names0 =
        run_hooks('create_routine_names', \%hook_args, 1,
                  $target, $target_arg);
    die "No hook created routine names" unless $routine_names0;

    my @routines;
    my $object = $target eq 'object';

  CREATE_LOGGER:
    {
        my $routine_names = $target eq 'package' ?
            $routine_names0->{log_subs} : $routine_names0->{log_methods};
        for my $rn (@$routine_names) {
            my ($rname, $lname) = @$rn;
            my $lnum = $Levels{$lname};

            local $hook_args{level} = $lnum;
            local $hook_args{str_level} = $lname;

            $_logger_is_null = 0;
            my $logger0 =
                run_hooks('create_log_routine', \%hook_args, 1,
                          $target, $target_arg);
            next unless $logger0;
            my $logger;
            if ($_logger_is_null) {
                # we don't need to format null logger
                $logger = $logger0;
                last;
            }

                if ($object) {
                    if ($formatter) {
                        $logger = sub {
                            shift;
                            my $msg = $formatter->(@_);
                            $logger0->($init_args, $msg);
                        };
                    } else {
                        # no formatter
                        $logger = sub {
                            shift;
                            $logger0->($init_args, @_);
                        };
                    }
                } else {
                    # not object
                    if ($formatter) {
                        $logger = sub {
                            my $msg = $formatter->(@_);
                            $logger0->($init_args, $msg);
                        };
                    } else {
                        # no formatter
                        $logger = sub {
                            $logger0->($init_args, @_);
                        };
                    }
                }
            }
            push @routines, [$code_log, $rname, $lnum, ($object ? 2:0) | 1];
        }
    }
    {
        my $routine_names = $target eq 'package' ?
            $routine_names0->{is_subs} : $routine_names0->{is_methods};
        for my $rn (@$routine_names) {
            my ($rname, $lname) = @$rn;
            my $lnum = $Levels{$lname};

            local $hook_args{level} = $lnum;
            local $hook_args{str_level} = $lname;

            my $code_is =
                run_hooks('create_is_routine', \%hook_args, 1,
                          $target, $target_arg);
            next unless $code_is;
            push @routines, [$code_is, $rname, $lnum, ($object ? 2:0) | 0];
        }
    }

    {
        local $hook_args{routines} = \@routines;
        run_hooks('before_install_routines', \%hook_args, 0,
                  $target, $target_arg);
    }

    # install
    if ($target eq 'package') {
#IFUNBUILT
        no strict 'refs';
        no warnings 'redefine';
#END IFUNBUILT
        for my $r (@routines) {
            my ($code, $name) = @$r;
            *{"$target_arg\::$name"} = $code;
        }
    } elsif ($target eq 'object') {
#IFUNBUILT
        no strict 'refs';
        no warnings 'redefine';
#END IFUNBUILT
        my $pkg = ref $target_arg;
        for my $r (@routines) {
            my ($code, $name) = @$r;
            *{"$pkg\::$name"} = $code;
        }
    } elsif ($target eq 'hash') {
        for my $r (@routines) {
            my ($code, $name) = @$r;
            $target_arg->{$name} = $code;
        }
    }

    {
        local $hook_args{routines} = \@routines;
        run_hooks('after_install_routines', \%hook_args, 0,
                  $target, $target_arg);
    }
}

sub import {
    my ($package, %args) = @_;

    my $caller = caller(0);
    $args{category} = $caller if !defined($args{category});
    add_target(package => $caller, \%args);
    init_target(package => $caller, \%args);
}

sub get_logger {
    my ($package, %args) = @_;

    my $caller = caller(0);
    $args{category} = $caller if !defined($args{category});
    my $obj = []; $obj =~ /\(0x(\w+)/;
    my $pkg = "Log::ger::Obj$1"; bless $obj, $pkg;
    add_target(object => $obj, \%args);
    init_target(object => $obj, \%args);
    $obj; # XXX add DESTROY to remove from list of targets
}

1;
# ABSTRACT: A lightweight, flexible logging framework

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

In your module (producer):

 package Foo;
 use Log::ger; # will import some logging methods e.g. log_warn, log_error

 sub foo {
     ...
     # produce some logs
     log_error "an error occurred: %03d - %s", $errcode, $errmsg;
     ...
     log_debug "http response: %s", $http; # automatic dumping of data
 }
 1;

In your application (consumer/listener):

 use Foo;
 use Log::ger::Output 'Screen';

 foo();


=head1 DESCRIPTION

Log::ger is yet another logging framework with the following features:

=over

=item * Separation of producers and consumers/listeners

Like L<Log::Any>, this offers a very easy way for modules to produce some logs
without having to configure anything. Configuring output, level, etc can be done
in the application as log consumers/listeners. To read more about this, see the
documentation of L<Log::Any> or L<Log::ger::Manual> (but nevertheless see
L<Log::ger::Manual> on why you might prefer Log::ger to Log::Any).

=item * Lightweight and fast

B<Slim distribution.> No non-core dependencies, extra functionalities are
provided in separate distributions to be pulled as needed.

B<Low startup overhead.> Only around 1-1.5ms or less, comparable with Log::Any
0.15, less than Log::Any 1.0x at around 4-10ms, and certainly less than
L<Log::Log4perl> at 20-30ms. This is measured on a 2014-2015 PC and before doing
any output configuration. For more benchmarks, see
L<Bencher::Scenarios::LogGer>.

B<Conditional compilation.> There is a plugin to optimize away unneeded logging
statements, like assertion/conditional compilation, so they have zero runtime
performance cost. See L<Log::ger::Plugin::OptAway>.

Being lightweight means the module can be used more universally, from CLI to
long-running daemons to inside routines with tight loops.

=item * Flexible

B<Customizable levels and routine/method names.> Can be used in a procedural or
OO style. Log::ger can mimic the interface of L<Log::Any>, L<Log::Contextual>,
L<Log::Log4perl>, or some other popular logging frameworks, to ease migration or
adjust with your personal style.

B<Per-package settings.> Each importer package can use its own format, output,
or filter. For example, some modules that are migrated from Log::Any uses
Log::Any-style logging, while another uses native Log::ger style, and yet some
other uses block formatting like Log::Contextual. This eases code migration and
teamwork. Each module author can preserve her own logging style, if wanted, and
all the modules still use the same framework.

B<Dynamic.> Outputs and levels can be changed anytime during run-time and
logging routines will be updated automatically. This is useful in situation like
a long-running server application: you can turn on tracing logs temporarily to
debug problems, then turn them off again, without restarting your server.

B<Interoperability.> There are modules to interop with Log::Any, either consume
Log::Any logs (see L<Log::Any::Adapter::LogGer>) or produce logs to be consumed
by Log::Any (see L<Log::ger::Output::LogAny>).

B<Many output modules and plugins.> See C<Log::ger::Output::*>,
C<Log::ger::Format::*>, C<Log::ger::Filter::*>, C<Log::ger::Plugin::*>. Writing
an output module in Log::ger is easier than writing a Log::Any::Adapter::*.

=back

For more documentation, start with L<Log::ger::Manual>.


=head1 SEE ALSO

Some other popular logging frameworks: L<Log::Any>, L<Log::Contextual>,
L<Log::Log4perl>, L<Log::Dispatch>, L<Log::Dispatchouli>.

=cut
