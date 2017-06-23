package Log::ger::Output::Null;

# DATE
# VERSION

sub get_hooks {
    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                $Log::ger::_logger_is_null = 1;
                [sub {0}];
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
