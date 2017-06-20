package Log::ger::Output::String;

# DATE
# VERSION

use Log::ger ();

sub import {
    my ($package, %import_args) = @_;

    my $hook = sub {
        my %args = @_;
        my $level = $args{level};
        my $code = sub {
            my $msg = $_[1];
            if ($formatter) {
                $msg = $formatter->($msg);
            }
            ${ $import_args{string} } .= $msg;
            ${ $import_args{string} } .= "\n" unless $msg =~ /\R\z/;
        };
        [$code];
    };

    Log::ger::add_hook('create_log_routine', 50, $hook);
}

1;
# ABSTRACT: Set output to a string

=head1 SYNOPSIS

 use Log::ger;
 use var '$str';
 use Log::ger::Output 'String' => ( string => \$str );

 log_warn "blah ...";
 log_error "blah ...";

C<$str> will contain "blah ...\nblah ...\n".


=head1 DESCRIPTION

For testing only.


=head1 CONFIGURATION

=head2 string => scalarref
