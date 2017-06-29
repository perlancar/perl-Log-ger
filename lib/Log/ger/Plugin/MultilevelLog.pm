package Log::ger::Plugin::MultilevelLog;

# DATE
# VERSION

use strict;
use warnings;

use Log::ger::Util;

sub get_hooks {
    my %conf = @_;

    return {
        create_routine_names => [
            __PACKAGE__, 50,
            sub {
                return [{
                    logml_subs    => [[$conf{sub_name}    || 'log', undef]],
                    logml_methods => [[$conf{method_name} || 'log', undef]],
                }];
            },
        ],
    };
}

1;
# ABSTRACT: Create a log($LEVEL, ...) subroutine/method

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use Log::ger::Plugin MultilevelLog => (
     sub_name => 'log',    # optional
     method_name => 'log', # optional
 );
 use Log::ger;


=head1 DESCRIPTION

The default way is to create separate C<log_LEVEL> subroutine (or C<LEVEL>
methods) for each level, e.g. C<log_trace> subroutine (or C<trace> method),
C<log_warn> (or C<warn>), and so on. But sometimes you might want a log routine
that takes $level as the first argument, e.g. instead of:

 log_warn('blah ...');

or:

 $log->debug('Blah: %s', $data);

you prefer:

 log('warn', 'blah ...');

or:

 $log->log('debug', 'Blah: %s', $data);

This plugin can create such log routine for you.

Note: the multilevel log is slower because of extra argument and additional
string level -> numeric level conversion.

Note: the individual separate C<log_LEVEL> subroutines (or C<LEVEL> methods) are
still installed.


=head1 CONFIGURATION

=head2 sub_name => str (default: "log")

=head2 method_name => str (default: "log")
