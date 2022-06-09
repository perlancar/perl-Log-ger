## no critic: TestingAndDebugging::RequireUseStrict
package Log::ger::Output::Null;

# AUTHORITY
# DATE
# DIST
# VERSION

sub meta { +{
    v => 2,
} }

sub get_hooks {
    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                $Log::ger::_outputter_is_null = 1;
                my $outputter = sub {0};
                [$outputter];
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
