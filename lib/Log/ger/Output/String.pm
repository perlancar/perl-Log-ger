package Log::ger::Output::String;

# DATE
# VERSION

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;

    $conf{string} or die "Please specify string";

    my $formatter = $conf{formatter};
    my $append_newline = $conf{append_newline};
    $append_newline = 1 unless defined $append_newline;

    return {
        create_log_routine => [
            __PACKAGE__, 50,
            sub {
                my %hook_args = @_;
                my $level = $hook_args{level};
                my $logger = sub {
                    my $msg = $_[1];
                    if ($formatter) {
                        $msg = $formatter->($msg);
                    }
                    ${ $conf{string} } .= $msg;
                    ${ $conf{string} } .= "\n"
                        unless !$append_newline || $msg =~ /\R\z/;
                };
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Set output to a string

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use var '$str';
 use Log::ger::Output 'String' => (
     string => \$str,
     # append_newline => 0, # default is true, to mimic Log::ger::Output::Screen
 );
 use Log::ger;

 log_warn "warn ...";
 log_error "debug ...";

C<$str> will contain "warn ...\n".


=head1 DESCRIPTION

For testing only.


=head1 CONFIGURATION

=head2 string => scalarref

Required.

=head2 formatter => coderef

Optional.

=head2 append_newline => bool (default: 1)
