package Log::ger::Output::String;

use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    $plugin_conf{string} or die "Please specify string";

    my $formatter = $plugin_conf{formatter};
    my $append_newline = $plugin_conf{append_newline};
    $append_newline = 1 unless defined $append_newline;

    return {
        create_outputter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"
                my $level = $hook_args{level};
                my $outputter = sub {
                    my ($per_target_conf, $msg, $per_msg_conf) = @_;
                    if ($formatter) {
                        $msg = $formatter->($msg);
                    }
                    ${ $plugin_conf{string} } .= $msg;
                    ${ $plugin_conf{string} } .= "\n"
                        unless !$append_newline || $msg =~ /\R\z/;
                };
                [$outputter];
            }],
    };
}

1;
# ABSTRACT: Set output to a string

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 BEGIN { our $str }
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
