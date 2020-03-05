package Log::ger::Filter::Code;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;

    $conf{code} or die "Please specify code";

    return {
        create_filter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                [$conf{code}];
            }],
    };
}

1;
# ABSTRACT: Filter using a coderef

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use Log::ger::Filter Code => (
     code => sub { ... },
 );


=head1 DESCRIPTION

Mainly for testing only.


=head1 CONFIGURATION

=head2 code => coderef

Required.


=head1 SEE ALSO

L<Log::ger>

=cut
