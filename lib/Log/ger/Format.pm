package Log::ger::Format;

# DATE
# VERSION

use parent qw(Log::ger::Plugin);

1;
# ABSTRACT: Use a format plugin

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

To set globally:

 use Log::ger::Format;
 Log::ger::Format->set('Block');

or:

 use Log::ger::Format 'Block';

To set for current package only:

 use Log::ger::Format;
 Log::ger::Format->set_for_current_package('Block');


=head1 SEE ALSO

L<Log::ger::Layout>

L<Log::ger::Output>

L<Log::ger::Plugin>
