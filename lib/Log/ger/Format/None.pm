package Log::ger::Format::None;

# DATE
# VERSION

sub get_hooks {
    return {
        create_formatter => [
            __PACKAGE__, 50,
            sub {
                [sub {shift}];
            }],
    };
}

1;
# ABSTRACT: Perform no formatting on the message

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use Log::ger::Format 'None';


=head1 DESCRIPTION



=head1 CONFIGURATION


=head1 SEE ALSO

L<Log::ger>

=cut
