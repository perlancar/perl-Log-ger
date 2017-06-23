package Log::ger::Filter;

# DATE
# VERSION

use parent 'Log::ger::Plugin';

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
