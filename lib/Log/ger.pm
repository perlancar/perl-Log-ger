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
    warning => 3,
);

# keep track of our importers (= log producers) to be able to re-export log
# routines to them when we change output, etc.
our %Import_Args;

our $Current_Level = 3;

my $dumper;
sub _dump {
    unless ($dumper) {
        eval { require Data::Dmp };
        if ($@) {
            require Data::Dumper;
            $dumper = sub {
                local $Data::Dumper::Terse = 1;
                local $Data::Dumper::Indent = 0;
                local $Data::Dumper::Useqq = 1;
                local $Data::Dumper::Deparse = 1;
                local $Data::Dumper::Quotekeys = 0;
                local $Data::Dumper::Sortkeys = 1;
                local $Data::Dumper::Trailingcomma = 1;
                Data::Dumper::Dumper($_[0]);
            };
        } else {
            $dumper = sub { Data::Dmp::dmp($_[0]) };
        }
    }
    $dumper->($_[0]);
}

our $_log_is_null;

my %default_hooks = (
    before_create_routine => [],

    create_filter_routine => [],

    create_formatter_routine => [
        # default: sprintf-style
        [90, sub {
             my %args = @_;
             my $code = sub {
                 return $_[0] if @_ < 2;
                 my $fmt = shift;
                 my @args;
                 for (@_) {
                     if (!defined($_)) {
                         push @args, '<undef>';
                     } elsif (ref $_) {
                         push @args, _dump($_);
                     } else {
                         push @args, $_;
                     }
                 }
                 sprintf $fmt, @args;
             };
             [$code];
         }, __PACKAGE__],
    ],

    create_log_routine => [
        # default: null
        [90, sub {
             $Log::ger::_log_is_null = 1;
             [sub {0}];
         }, __PACKAGE__ . " (null default output)"],

        # create a null subroutine for higher-levels
        [10, sub {
             my %args = @_;
             my $level = $args{level};
             if ($Current_Level >= $level) {
                 return [undef];
             } else {
                 $Log::ger::_log_is_null = 1;
                 return [sub {0}];
             }
         }, __PACKAGE__ . " (null higher level)"],
    ],

    create_log_is_routine => [
        # default: compare with $Current_Level
        [90, sub {
             my %args = @_;
             my $level = $args{level};
             my $code = sub {
                 $Current_Level >= $level;
             };
             [$code];
         }, __PACKAGE__],
    ],

    after_create_routine => [],

    after_install_routine => [],
);

my %hooks;
{
    for my $phase (keys %default_hooks) {
        $hooks{$phase} = [@{ $default_hooks{$phase} }];
    }
}

sub _action_on_hooks {
    my $action = shift;

    my $phase = shift;
    my $hooks = $hooks{$phase} or die "Unknown phase '$phase'";

    if ($action eq 'add') {
        my ($prio, $hook, $key) = @_;
        $key ||= caller(1);
        return 0 if grep { $_->[2] eq $key } @$hooks;
        unshift @$hooks, [$prio, $hook, $key];
    } elsif ($action eq 'reset') {
        my $saved = $hooks{$phase};
        $hooks{$phase} = [@{ $default_hooks{$phase} }];
        return $saved;
    } elsif ($action eq 'empty') {
        my $saved = $hooks{$phase};
        $hooks{$phase} = [];
        return $saved;
    } elsif ($action eq 'save') {
        return [@{ $hooks{$phase} }];
    } elsif ($action eq 'restore') {
        my $saved = shift;
        $hooks{$phase} = [@$saved];
        return $saved;
    }
}

sub add_hook {
    my ($phase, $prio, $hook, $key) = @_;
    _action_on_hooks('add', $phase, $prio, $hook, $key);
}

sub reset_hooks {
    my ($phase) = @_;
    _action_on_hooks('reset', $phase);
}

sub empty_hooks {
    my ($phase) = @_;
    _action_on_hooks('empty', $phase);
}

sub save_hooks {
    my ($phase) = @_;
    _action_on_hooks('save', $phase);
}

sub restore_hooks {
    my ($phase, $saved) = @_;
    _action_on_hooks('restore', $phase, $saved);
}

sub run_hooks {
    my ($phase, $hook_args, $stop_after_first_result) = @_;

    #use DD; print "D: run_hooks, hook_args=", DD::dump($hook_args), "\n";
    my $hooks = $hooks{$phase} or die "Unknown phase '$phase'";

    my $res;
    for my $hrec (sort {$a->[0] <=> $b->[0]} @$hooks) {
        my $hook = $hrec->[1];
        my ($res0, $flow_control) = @{ $hook->(%$hook_args) };
        if (defined $res0) {
            $res = $res0;
            #print "D:   got result from $hrec->[2]\n";
            last if $stop_after_first_result;
        }
        last if $flow_control;
    }
    $res;
}

sub _setup {
    my ($target, $target_arg, $caller, $setup_args) = @_;

    my $code_filter =
        run_hooks('create_filter_routine', {
            setup_args => $setup_args,
            caller     => $caller,
        }, 1);

    my $code_formatter =
        run_hooks('create_formatter_routine', {
            setup_args => $setup_args,
            caller     => $caller,
        }, 1);
    die "No hooks created formatter routine" unless $code_formatter;

    for my $lname (keys %Levels) {
        my $lnum = $Levels{$lname};

        my %hook_args = (
            setup_args => $setup_args,
            caller     => $caller,
            level      => $lnum,
            str_level  => $lname,
        );

        run_hooks('before_create_routine', \%hook_args, 0);

        $_log_is_null = 0;
        my $code0_log =
            run_hooks('create_log_routine', \%hook_args, 1);
        die "No hooks created log routine 'log_$lname'" unless $code0_log;
        my $code_log;
        if ($_log_is_null) {
            # we don't need to format null logger
            $code_log = $code0_log;
        } elsif ($code_filter) {
            $code_log = sub {
                return unless $code_filter->($lnum, $setup_args);
                my $msg = $code_formatter->(@_);
                $code0_log->($setup_args, $msg);
            };
        } else {
            $code_log = sub {
                my $msg = $code_formatter->(@_);
                $code0_log->($setup_args, $msg);
            };
        }

        my $code_log_is =
            run_hooks('create_log_is_routine', \%hook_args, 1);
        die "No hooks created log routine 'log_is_$lname'" unless $code_log_is;

        run_hooks('after_create_routine', \%hook_args, 0);

        # install
        if ($target eq 'package') {
            no strict 'refs';
            no warnings 'redefine';

            *{"$target_arg\::log_$lname"}    = $code_log;
            *{"$target_arg\::log_is_$lname"} = $code_log_is;
        } elsif ($target eq 'hash') {
            $target_arg->{"log_$lname"}    = $code_log;
            $target_arg->{"log_is_$lname"} = $code_log_is;
        } elsif ($target eq 'object') {
            no strict 'refs';
            no warnings 'redefine';

            *{"$target_arg\::log_$lname"}    = sub { shift; $code_log->(@_) };
            *{"$target_arg\::log_is_$lname"} = $code_log_is;
        }

        run_hooks('after_install_routine', \%hook_args, 0);
    } # for level
}

sub setup_package {
    my $package = shift;
    my $args = shift;
    _setup('package', $package, $package, $args);
}

sub setup_hash {
    my $caller = shift || caller(0);
    my $hash = {};
    my $args = shift;
    _setup('hash', $hash, $caller, $args);
    $hash;
}

sub setup_object {
    my $caller = shift || caller(0);
    # create a random package, XXX check if already exists?
    my $pkg = "Log::ger::Object::O".int(100_000_000 + rand()*900_000_000);
    my $args = shift;
    _setup('object', $pkg, $caller, $args);
    bless [], $pkg;
}

sub resetup_importers {
    for my $pkg (keys %Import_Args) {
        setup_package($pkg, $Import_Args{$pkg});
    }
}

sub set_output {
    my ($mod, %args) = @_;
    die "Invalid output module syntax" unless $mod =~ /\A\w+(::\w+)*\z/;
    $mod = "Log::ger::Output::$mod" unless $mod =~ /\ALog::ger::Output::/;
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;
    $mod->import(%args);
    resetup_importers();
}

sub numeric_level {
    my $level = shift;
    return $level if $level =~ /\A\d+\z/;
    return $Levels{$level} if defined $Levels{$level};
    return $Level_Aliases{$level} if defined $Level_Aliases{$level};
    die "Unknown level '$level'";
}

sub set_level {
    $Log::ger::Current_Level = numeric_level(shift);
    resetup_importers();
}

sub import {
    my ($self, %args) = @_;

    my $caller = caller(0);
    $args{category} = $caller if !defined($args{category});
    $args{category} = join(".", split /::|\./, lc $args{category}); # normalize
    $Import_Args{$caller} = \%args;
    setup_package($caller, \%args);
}

1;
# ABSTRACT: A lightweight, flexible logging framework

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

In your module (producer):

 package Foo;
 use Log::ger; # will import some logging methods e.g. log_warn, log_error

 # produce some logs
 sub foo {
     ...
     log_warn "an error occurred";
     log_error "an error occurred: %03d - %s", $errcode, $errmsg;
 }
 1;

In your application:

 use Foo;
 use Log::ger::Output 'Screen';

 foo();


=head1 DESCRIPTION

B<EARLY RELEASE, EXPERIMENTAL.>

This is yet another logging framework. Like L<Log::Any>, it separates producers
and consumers. Unlike L<Log::Any> (and like L<Log::Contextual>), it uses plain
functions (non-OO). Some features:

=over

=item * Low startup overhead;

=item * Low overhead;

=item * Customizable levels;

=item * Changing levels and outputs during run-time;

For example, you can debug your running server application to turn on trace logs
temporarily when you need to investigate something.

=item * Option to optimize away the logging statements when unnecessary;

See L<Log::ger::OptAway>.

=item * Interoperability with other logging frameworks;

See L<Log::ger::LogAny> to interop with L<Log::Any>.

=back


=head1 INTERNALS

=head2 Hooks

Hooks are how Log::ger provides its flexibility. A hook is passed a hash
argument and is expected to return an array:

 [$result, $flow_control]

Some phases will stop after the first hook that returns non-undef C<$result>.
C<$flow_control> can be set to 1 to stop immediately after this hook.

Aguments received by hook: C<caller>, C<level> (numeric level), C<str_level>.

=over

=item * before_create_routine phase

=item * create_log_routine phase

Used to create "log_I<level>" routines.

Expected return:

 [$err*, $code]

Hook that wants to decline can return undef in C<$code>. Log::ger will stop
after the first hook that produces a non-undef code.

=head2 create_log_is_routine phase

Used to create "log_I<level>" routines.

=head2 after_create_routine phase

=head2 Plans

=over

=item * Multiple loggers

To support logging to two+ different loggers in the same producer package, a la
in L<Log::Any>:

 $log->debugf("Headers is: %s", $http_res->{headers});
 $log_dump->debug($http_res->{content});

we can do something like (XXX find a more appropriate name):

 my $log      = Log::ger::install_to_object(...); # instead of installing to package
 my $log_dump = Log::ger::install_to_object(...); # or perhaps install to hash?
 $log->log_debug(...);
 $log_dump->log_debug(...);

=item * Custom formatting

For example, a la L<Log::Contextual>:

 log_warn { 'The number of stuffs is: ' . $obj->stuffs_count };

can be implemented by a hook in Create_Log_Routine that wraps routine from the
other hook and perform the conversion from custom formatting to sprintf-style
(or a single string).

=back


=head1 SEE ALSO

Some other recommended logging frameworks: L<Log::Any>, L<Log::Contextual>.

=cut
