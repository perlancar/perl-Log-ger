## no critic: TestingAndDebugging::RequireUseStrict
package Log::ger::Layout;

# AUTHORITY
# DATE
# DIST
# VERSION

use parent qw(Log::ger::Plugin);

# we only use one layout, so set() should replace all hooks from previously set
# plugin package
sub _replace_package_regex { qr/\ALog::ger::Layout::/ }

1;
# ABSTRACT: Use a layout plugin

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

To set globally:

 use Log::ger::Layout;
 Log::ger::Layout->set('Pattern');

or:

 use Log::ger::Layout 'Pattern';

To set for current package only:

 use Log::ger::Layout;
 Log::ger::Layout->set_for_current_package('Pattern');


=head1 SEE ALSO

L<Log::ger::Output>

L<Log::ger::Plugin>

L<Log::ger::Format>
