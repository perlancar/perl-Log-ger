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

our @Hooks_Create_Log_Routine = (
    sub { ["", sub {0}] },
);

our @Hooks_Create_Log_Is_Routine = (
    sub {
        my %args = @_;
        my $level = $args{level};
        my $code = sub {
            $Current_Level >= $level;
        };
        ["", $code];
    },
);

our @Hooks_Install_Routine = (
    sub {
        no strict 'refs';
        no warnings 'redefine';

        my %args = @_;
        my $package = $args{package};
        my $name    = $args{name};
        my $code    = $args{code};
        *{"$package\::$name"} = $code;
        ["", 1];
    },
);

sub install_to_package {
    my ($package, %args) = @_;

    for my $lname (keys %Levels) {
        my $lnum = $Levels{$lname};
        my ($res, $code);

        for my $rname ("log_$lname") {
            #print "D:creating $rname routine ...\n";
            for my $h (@Hooks_Create_Log_Routine) {
                $res = $h->(
                    package   => $package,
                    name      => $rname,
                    level     => $lnum,
                    str_level => $lname,
                    prev      => $code,
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
                    package   => $package,
                    name      => $rname,
                    code      => $code,
                    level     => $lnum,
                    str_level => $lname,
                );
                die $res->[0] if $res->[0];
                last if $res->[1];
            }
        }

        $code = undef;
        for my $rname ("log_is_$lname") {
            #print "D:creating and installing $rname ...\n";
            for my $h (@Hooks_Create_Log_Is_Routine) {
                $res = $h->(
                    package   => $package,
                    name      => $rname,
                    level     => $lnum,
                    str_level => $lname,
                    prev      => $code,
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
                    package    => $package,
                    name       => $rname,
                    code       => $code,
                    level      => $lnum,
                    str_level => $lname,
                );
                die $res->[0] if $res->[0];
                last if $res->[1];
            }
        }
    }
}

sub set_output {
    my ($mod, %args) = @_;
    die "Invalid output module syntax" unless $mod =~ /\A\w+(::\w+)*\z/;
    $mod = "Log::ger::Output::$mod" unless $mod =~ /\ALog::ger::Output::/;
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;
    $mod->import(%args);
    for my $pkg (keys %Importers) {
        install_to_package($pkg);
    }
}

sub import {
    my $self = shift;

    my $caller = caller(0);
    $Importers{$caller}++;
    install_to_package($caller);
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

Arguments received: C<name> (name of subroutine, e.g. C<log_warn>), C<level>
(numeric level), C<package>, C<prev> (coderef).

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

Arguments: C<package> (target package to install to), C<name> (routine name),
C<code> (routine code), C<level> (the numeric level of the routine).

Expected return:

 [$err*, $installed]

C<$installed> can be set to 1 to signify that the hook has installed the
routine, so Log::err will stop. Otherwise, Log::ger will try the next hook.

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

=item * Multiple outputs, filtering based on category

With the exception of the default/null routines (and perhaps the simple Screen
output too), the other logging routines should be constructed using a code
generation approach so we can have multiple outputs, etc.

=back


=head1 SEE ALSO

Some other recommended logging frameworks: L<Log::Any>, L<Log::Contextual>.

=cut
