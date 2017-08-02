package Log::ger::Output::ArrayML;

# DATE
# VERSION

use strict;
use warnings;

use Log::ger::Util;

sub get_hooks {
    my %conf = @_;

    $conf{array} or die "Please specify array";

    return {
        create_logml_routine => [
            __PACKAGE__, 50,
            sub {
                my %args = @_;
                my $logger = sub {
                    my $level = Log::ger::Util::numeric_level($_[1]);
                    return if $level > $Log::ger::Current_Level;
                    push @{$conf{array}}, $_[2];
                };
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Log to array

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use Log::ger::Output ArrayML => (
     array         => $ary,
 );


=head1 DESCRIPTION

Mainly for testing only.

This output is just like L<Log::ger::Output::Array> except that it provides a
C<create_logml_routine> hook instead of C<create_log_routine>.


=head1 CONFIGURATION

=head2 array => arrayref

Required.


=head1 SEE ALSO

L<Log::ger>

=cut
