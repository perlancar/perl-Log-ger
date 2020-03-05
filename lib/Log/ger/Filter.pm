package Log::ger::Filter;

# AUTHORITY
# DATE
# DIST
# VERSION

use parent qw(Log::ger::Plugin);

# we only use one filter, so set() should replace all hooks from previously set
# plugin package
sub _replace_package_regex { qr/\ALog::ger::Filter::/ }

1;
# ABSTRACT: Use a filter plugin

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

To set globally:

 use Log::ger::Filter;
 Log::ger::Filter->set('Foo');

or:

 use Log::ger::Filter 'Foo';

To set for current package only:

 use Log::ger::Filter;
 Log::ger::Filter->set_for_current_package('Foo');


=head1 SEE ALSO

L<Log::ger::Output>

L<Log::ger::Plugin>

L<Log::ger::Format>

L<Log::ger::Layout>
