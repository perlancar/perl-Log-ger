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

# keep track of our importers (= log producers) to be able to re-export log
# routines to them when we change output, etc.
our %Importers;

our $Current_Level = 3;

my @hooks_before_create_routine;

my @hooks_create_log_routine = (
    # default: null
    [90, sub { ["", sub {0}] }, __PACKAGE__],
);

my @hooks_create_log_is_routine = (
    # default: compare with $Current_Level
    [90, sub {
         my %args = @_;
         my $level = $args{level};
         my $code = sub {
             $Current_Level >= $level;
         };
         ["", $code];
     }, __PACKAGE__],
);

my @hooks_after_create_routine;

my @hooks_after_install_routine;

sub add_hook {
    my ($phase, $prio, $hook, $key) = @_;

    my $hooks;
    if ($phase eq 'before_create_routine') {
        $hooks = \@hooks_before_create_routine;
    } elsif ($phase eq 'create_log_routine') {
        $hooks = \@hooks_create_log_routine;
    } elsif ($phase eq 'create_log_is_routine') {
        $hooks = \@hooks_create_log_is_routine;
    } elsif ($phase eq 'after_create_routine') {
        $hooks = \@hooks_after_create_routine;
    } elsif ($phase eq 'after_install_routine') {
        $hooks = \@hooks_after_install_routine;
    } else {
        die "Unknown phase '$phase'";
    }

    $key ||= caller(0);
    return 0 if grep { $_->[2] eq $key } @$hooks;

    unshift @$hooks, [$prio, $hook, $key];
}

sub _setup {
    my ($target, $target_arg, $caller) = @_;

    for my $lname (keys %Levels) {
        my $lnum = $Levels{$lname};

        my ($res, $code_log, $code_log_is);
        my %hook_args = (
            caller     => $caller,
            level      => $lnum,
            str_level  => $lname,
        );

        for my $hrec (sort { $a->[0] <=> $b->[0] }
                          @hooks_before_create_routine) {
            my $hook = $hrec->[1];
            $res = $hook->(%hook_args);
            die $res->[0] if $res->[0];
        }

        my $rname_log = "log_$lname";
        #print "D:creating $rname_log routine ...\n";
        for my $hrec (sort { $a->[0] <=> $b->[0] }
                          @hooks_create_log_routine) {
            my $h = $hrec->[1];
            $res = $h->(%hook_args);
            die $res->[0] if $res->[0];
            if ($res->[1]) {
                $code_log = $res->[1];
                last;
            }
        }
        die "No hooks created log routine '$rname_log'" unless $code_log;

        my $rname_log_is = "log_is_$lname";
        #print "D:creating $rname_log routine ...\n";
        for my $hrec (sort { $a->[0] <=> $b->[0] }
                          @hooks_create_log_is_routine) {
            my $h = $hrec->[1];
            $res = $h->(%hook_args);
            die $res->[0] if $res->[0];
            if ($res->[1]) {
                $code_log_is = $res->[1];
                last;
            }
        }
        die "No hooks created log routine '$rname_log_is'" unless $code_log_is;

        #print "D:running after_create_routine for $rname_log routine ...\n";
        for my $hrec (sort { $a->[0] <=> $b->[0] }
                          @hooks_after_create_routine) {
            my $hook = $hrec->[1];
            $res = $hook->(%hook_args);
            die $res->[0] if $res->[0];
        }

        # install
        if ($target eq 'package') {
            no strict 'refs';
            no warnings 'redefine';

            *{"$target_arg\::$rname_log"} = $code_log;
            *{"$target_arg\::$rname_log_is"} = $code_log_is;
        } elsif ($target eq 'hash') {
            $target_arg->{$rname_log} = $code_log;
            $target_arg->{$rname_log_is} = $code_log_is;
        } elsif ($target eq 'object') {
            no strict 'refs';
            no warnings 'redefine';

            *{"$target_arg\::$rname_log"}    = sub { shift; $code_log->(@_) };
            *{"$target_arg\::$rname_log_is"} = $code_log_is;
        }

        for my $hrec (sort { $a->[0] <=> $b->[0] }
                          @hooks_after_install_routine) {
            my $h = $hrec->[1];
            $res = $h->(%hook_args);
            die $res->[0] if $res->[0];
        }

    } # for level
}

sub setup_package {
    my $package = shift;
    my $caller = shift || caller(0);
    _setup('package', $package, $caller);
}

sub setup_hash {
    my $caller = shift || caller(0);
    my $hash = {};
    _setup('hash', $hash, $caller);
    $hash;
}

sub setup_object {
    my $caller = shift || caller(0);
    # create a random package, XXX check if already exists?
    my $pkg = "Log::ger::Object::O".int(100_000_000 + rand()*900_000_000);
    _setup('object', $pkg, $caller);
    bless [], $pkg;
}

sub set_output {
    my ($mod, %args) = @_;
    die "Invalid output module syntax" unless $mod =~ /\A\w+(::\w+)*\z/;
    $mod = "Log::ger::Output::$mod" unless $mod =~ /\ALog::ger::Output::/;
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;
    $mod->import(%args);
    for my $pkg (keys %Importers) {
        setup_package($pkg);
    }
}

sub import {
    my $self = shift;

    my $caller = caller(0);
    $Importers{$caller}++;
    setup_package($caller, $caller);
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

 [$err*, ...]

C<$err> is a string and can be set to "" to signify success or a non-empty error
message to signify error. Log::ger usually dies after a hook returns error.

Arguments received by hook: C<caller>, C<name> (name of
subroutine, e.g. C<log_warn>), C<level> (numeric level).

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
