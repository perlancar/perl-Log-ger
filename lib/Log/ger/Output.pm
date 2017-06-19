package Log::ger::Output;

use strict;
use warnings;

sub set {
    my $pkg = shift;

    require Log::ger;
    Log::ger::set_output(@_);
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
