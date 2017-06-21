package Log::ger::Output;

# DATE
# VERSION

use strict;
use warnings;

sub set {
    my $pkg = shift;

    require Log::ger::Util;
    Log::ger::Util::set_output(@_);
}

sub import {
    my $pkg = shift;
    if (@_) {
        set($pkg, @_);
    }
}

1;
# ABSTRACT: Set logging output

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use Log::ger::Output;
 Log::ger::Output->set('Screen', use_color=>1, ...);

or:

 use Log::ger::Output Screen => (
     use_color => 1,
     ...
 );


=head1 SEE ALSO

Modelled after L<Log::Any::Adapter>.
