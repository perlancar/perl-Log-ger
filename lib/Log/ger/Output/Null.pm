package Log::ger::Output::Null;

# DATE
# VERSION

use Log::ger ();

my $code_null = sub {0};

sub import {
    Log::ger::add_hook(
        'create_log_routine',
        50,
        sub {
            $Log::ger::_log_is_null = 1;
            [$code_null];
        },
    );
}

1;
# ABSTRACT: Null output

=head1 SYNOPSIS

 use Log::ger;
 use Log::ger::Output 'Null';

 log_warn "blah...";


=head1 DESCRIPTION


=head1 CONFIGURATION
