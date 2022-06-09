package Log::ger::Plugin;

use strict;
use warnings;

use Log::ger::Util;

# AUTHORITY
# DATE
# DIST
# VERSION

sub set {
    my $pkg = shift;

    my %args;
    if (ref $_[0] eq 'HASH') {
        %args = %{shift()};
    } else {
        %args = (name => shift, conf => {@_});
    }

    $args{prefix} ||= $pkg . '::';
    $args{replace_package_regex} = $pkg->_replace_package_regex;
    Log::ger::Util::set_plugin(%args);
}

sub set_for_current_package {
    my $pkg = shift;

    my %args;
    if (ref $_[0] eq 'HASH') {
        %args = %{shift()};
    } else {
        %args = (name => shift, conf => {@_});
    }

    my $caller = caller(0);
    $args{target} = 'package';
    $args{target_arg} = $caller;

    set($pkg, \%args);
}

sub _import_sets_for_current_package { 0 }

sub _replace_package_regex { undef }

sub import {
    if (@_ > 1) {
        if ($_[0]->_import_sets_for_current_package) {
            goto &set_for_current_package;
        } else {
            goto &set;
        }
    }
}

1;
# ABSTRACT: Use a plugin

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

To set globally:

 use Log::ger::Plugin;
 Log::ger::Plugin->set('OptAway');

or:

 use Log::ger::Plugin 'OptAway';

To set for current package only:

 use Log::ger::Plugin;
 Log::ger::Plugin->set_for_current_package('OptAway');


=head1 SEE ALSO

L<Log::ger::Format>

L<Log::ger::Layout>

L<Log::ger::Output>

L<Log::ger::Filter>
