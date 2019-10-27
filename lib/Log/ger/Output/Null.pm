package Log::ger::Output::Null;

# DATE
# VERSION

sub get_hooks {
    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %hook_args = @_;

                $Log::ger::_logger_is_null = 1;
                my $logger = sub {0};
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Null output

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use Log::ger;
 use Log::ger::Output 'Null';

 log_warn "blah...";


=head1 DESCRIPTION


=head1 CONFIGURATION
