package Log::ger::Output::Screen;

# DATE
# VERSION

use strict;
use warnings;

use Log::ger ();

my $code_print = sub {
    my $msg = sprintf @_;
    print $msg;
    print "\n" unless $msg =~ /\R\z/;
};

my $code_null = sub {0};

my $hook = sub {
    my %args = @_;
    ["", $Log::ger::Current_Level <= $args{level} ? $code_print : $code_null];
};

sub import {
    my $self = shift;

    unshift @Log::ger::Hooks_Create_Routine, $hook
        unless grep { $_ == $hook } @Log::ger::Hooks_Create_Routine;
}

sub unimport {
    my $self = shift;

    @Log::ger::Hooks_Create_Routine =
        grep { $_ != $hook } @Log::ger::Hooks_Create_Routine;
}

1;
# ABSTRACT: Output log to screen

=head1 SYNOPSIS

 use Log::ger::Output::Screen;
 use Log::ger;


=head1 DESCRIPTION

Note: C<use Log::ger::Output::Screen> must be performed before C<use Log::ger>
because by default Log::ger installs a null output.
