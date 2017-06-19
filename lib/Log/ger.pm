package Log::ger;

# DATE
# VERSION

#IFUNBUILT
use strict;
use warnings;
#END IFUNBUILT

our %Levels = (
    off     => 0,
    fatal   => 1,
    error   => 2,
    warn    => 3,
    info    => 4,
    debug   => 5,
    trace   => 6,
);

our $Current_Level = 3;

our @Hooks_Create_Log_Routine = (
    sub { ["", sub {0}] },
);

our @Hooks_Create_Log_Is_Routine = (
    sub {
        my %args = @_;
        my $code = sub {
            $Current_Level <= $args{level};
        };
        ["", $code];
    },
);

our @Hooks_Install_Routine = (
    sub {
        no strict 'refs';

        my %args = @_;
        my $caller   = $args{caller};
        my $name     = $args{name};
        my $code     = $args{code};
        *{"$caller\::$name"} = $code;
        ["", 1];
    },
);

sub import {
    my ($self, %args) = @_;

    my $caller = caller(0);
    for my $lname (keys %Levels) {
        my $lnum = $Levels{$lname};
        my ($res, $code);

        for my $rname ("log_$lname") {
            for my $h (@Hooks_Create_Log_Routine) {
                $res = $h->(
                    caller => $caller,
                    import_args => \%args,
                    name   => $rname,
                    level  => $lnum,
                    prev   => $code,
                );
                die $res->[0] if $res->[0];
                if ($res->[1]) {
                    $code = $res->[1];
                    last unless $res->[2];
                }
            }
            die "No hooks created log routine '$rname'" unless $code;
            for my $h (@Hooks_Install_Routine) {
                $res = $h->(
                    caller   => $caller,
                    import_args => \%args,
                    name     => $rname,
                    code     => $code,
                    level    => $lnum,
                );
                die $res->[0] if $res->[0];
                last if $res->[1];
            }
        }

        $code = undef;
        for my $rname ("log_is_$lname") {
            for my $h (@Hooks_Create_Log_Is_Routine) {
                $res = $h->(
                    caller => $caller,
                    import_args => \%args,
                    name   => $rname,
                    level  => $lnum,
                    prev   => $code,
                );
                die $res->[0] if $res->[0];
                if ($res->[1]) {
                    $code = $res->[1];
                    last unless $res->[2];
                }
            }
            die "No hooks created log routine '$rname'" unless $code;
            for my $h (@Hooks_Install_Routine) {
                $res = $h->(
                    caller   => $caller,
                    name     => $rname,
                    code     => $code,
                    level    => $lnum,
                );
                die $res->[0] if $res->[0];
                last if $res->[1];
            }
        }
    }
}

1;
# ABSTRACT: A lightweight, flexible logging framework

=for Pod::Coverage ^(import|create_logger_routines)$

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
 use Log::ger::Output::Screen;

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

See L<Log::ger::Import::OptAway>.

=item * Interoperability with other logging frameworks;

See L<Log::ger::Import::LogAny> to interop with L<Log::Any>.

=back


=head1 INTERNALS

=head2 Hooks

Hooks are how Log::ger provides its flexibility. A hook is passed a hash
argument and is expected to return an array:

 [$err*, ...]

C<$err> is a string and can be set to "" to signify success or a non-empty error
message to signify error. Log::ger usually dies after a hook returns error.

=head2 Create_Log_Routine hook

Used to create "log_I<level>" routines.

Arguments received: C<caller>, C<import_args>, C<name> (name of subroutine, e.g.
C<log_warn>), C<level> (numeric level), prev (coderef).

Expected return:

 [$err*, $code, $continue]

Hook that wants to decline can return undef in C<$code>. Log::ger will stop
after the hook that produces a non-undef code unless when set to $continue 1
then Log::ger will continue to the next hook and passing the code to C<prev> to
allow onion-style nesting of code.

=head2 Create_Log_Is_Routine hook

Used to create "log_I<level>" routines.

=head2 Install_Routine hook

Used to install to the caller (log producer) package.

Arguments:

 [$err*, $installed]

C<$installed> can be set to 1 to signify that the hook has installed the
routine, so Log::err will stop. Otherwise, Log::ger will try the next hook.


=head1 SEE ALSO

Some other recommended logging frameworks: L<Log::Any>, L<Log::Contextual>.

=cut
