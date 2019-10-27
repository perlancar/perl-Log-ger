package Log::ger::Format::None;

# DATE
# VERSION

sub get_hooks {
    return {
        create_formatter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_;
                my $formatter = sub { shift };
                [$formatter];
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
