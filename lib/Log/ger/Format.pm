package Log::ger::Format;

# DATE
# VERSION

use parent qw(Log::ger::Plugin);

sub _import_sets_for_current_package { 1 }

1;
# ABSTRACT: Use a format plugin

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

To set for current package only:

 use Log::ger::Format 'Block';

or:

 use Log::ger::Format;
 Log::ger::Format->set_for_current_package('Block');

To set globally:

 use Log::ger::Format;
 Log::ger::Format->set('Block');


=head1 DESCRIPTION

Note: Since format plugins affect log-producing code, the import syntax defaults
to setting for current package instead of globally.


=head1 SEE ALSO

L<Log::ger::Layout>

L<Log::ger::Output>

L<Log::ger::Plugin>
