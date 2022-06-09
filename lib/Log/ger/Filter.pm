## no critic: TestingAndDebugging::RequireUseStrict
package Log::ger::Filter;

# AUTHORITY
# DATE
# DIST
# VERSION

use parent qw(Log::ger::Plugin);

1;
# ABSTRACT: Use a filter plugin

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

To set globally:

 use Log::ger::Filter;
 Log::ger::Filter->set('Code', code => sub{ ... });

or:

 use Log::ger::Filter 'Code', (code => sub { ... });

To set for current package only:

 use Log::ger::Filter;
 Log::ger::Filter->set_for_current_package('Code', code => sub { ... });


=head1 SEE ALSO

L<Log::ger::Output>

L<Log::ger::Plugin>

L<Log::ger::Format>

L<Log::ger::Layout>
