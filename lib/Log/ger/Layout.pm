package Log::ger::Layout;

# DATE
# VERSION

use parent qw(Log::ger::Plugin);

1;
# ABSTRACT: Use a layout plugin

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use Log::ger::Layout;
 Log::ger::Layout->set('Log4perl', layout => $);


=head1 DESCRIPTION

Layout module is just a term for a formatter that does its formatting after a
Log::ger::Format::* module. So it usually receives an already-formatted string.


=head1 SEE ALSO

L<Log::ger::Format>

L<Log::ger::Output>

L<Log::ger::Plugin>

L<Log::ger::Filter>
