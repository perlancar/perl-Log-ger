package Log::ger::Output::Null;

# DATE
# VERSION

use Log::ger ();

sub PRIO_create_log_routine { 50 }

sub create_log_routine {
    $Log::ger::_log_is_null = 1;
    [sub {0}];
}

sub import {
    Log::ger::add_plugin('create_log_routine', __PACKAGE__, 'replace');
}

1;
# ABSTRACT: Null output

=head1 SYNOPSIS

 use Log::ger;
 use Log::ger::Output 'Null';

 log_warn "blah...";


=head1 DESCRIPTION


=head1 CONFIGURATION
