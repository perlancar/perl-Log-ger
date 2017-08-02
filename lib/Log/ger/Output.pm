package Log::ger::Output;

# DATE
# VERSION

use parent 'Log::ger::Plugin';

# we only use one output, so set() should replace all hooks from previously set
# plugin package
sub _replace_package_regex { qr/\ALog::ger::Output::/ }

1;
# ABSTRACT: Set logging output

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

To set globally:

 use Log::ger::Output;
 Log::ger::Output->set(Screen => (
     use_color => 1,
     ...
 );

or:

 use Log::ger::Output 'Screen', (
     use_color=>1,
 ...
 );

To set for current package only:

 use Log::ger::Output;
 Log::ger::Output->set_for_current_package(Screen => (
     use_color => 1,
     ...
 );


=head1 SEE ALSO

L<Log::ger::Format>

L<Log::ger::Layout>

L<Log::ger::Plugin>
