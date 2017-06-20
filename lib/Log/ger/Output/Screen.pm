package Log::ger::Output::Screen;

# DATE
# VERSION

use strict;
use warnings;

use Log::ger ();

#my %Installed_Hooks;

my %colors = (
    1 => "\e[31m"  , # fatal, red
    2 => "\e[35m"  , # error, magenta
    3 => "\e[1;34m", # warning, light blue
    4 => "\e[32m"  , # info, green
    5 => "",         # debug, no color
    6 => "\e[33m"  , # trace, orange
);

my $code_null = sub {0};

sub import {
    my ($self, %import_args) = @_;

    my $stderr = $import_args{stderr};
    $stderr = 1 unless defined $stderr;
    my $handle = $stderr ? \*STDERR : \*STDOUT;
    my $use_color = $import_args{use_color};
    $use_color = $ENV{COLOR} unless defined $use_color;
    $use_color = (-t STDOUT) unless defined $use_color;
    my $formatter = $import_args{formatter};

    my $dumper;

    my $hook = sub {
        my %args = @_;
        my $level = $args{level};
        my $code_print = sub {
            my $msg;
            if (@_ < 2) {
                $msg = $_[0];
            } else {
                my $fmt = shift;
                my @args;
                for (@_) {
                    if (ref $_) {
                        unless ($dumper) {
                            eval { require Data::Dmp };
                            if ($@) {
                                require Data::Dumper;
                                $dumper = sub {
                                    local $Data::Dumper::Terse = 1;
                                    local $Data::Dumper::Indent = 0;
                                    local $Data::Dumper::Useqq = 1;
                                    local $Data::Dumper::Deparse = 1;
                                    local $Data::Dumper::Quotekeys = 0;
                                    local $Data::Dumper::Sortkeys = 1;
                                    local $Data::Dumper::Trailingcomma = 1;
                                    Data::Dumper::Dumper($_[0]);
                                };
                            } else {
                                $dumper = sub { Data::Dmp::dmp($_[0]) };
                            }
                        }
                        push @args, $dumper->($_);
                    } else {
                        push @args, $_;
                    }
                }
                $msg = sprintf $fmt, @args;
            }
            if ($formatter) {
                $msg = $formatter->($msg);
            }
            if ($use_color) {
                print $handle $colors{$level}, $msg, "\e[0m";
            } else {
                print $handle $msg;
            }
            print $handle "\n" unless $msg =~ /\R\z/;
        };
    ["", $Log::ger::Current_Level >= $level ? $code_print : $code_null];
    };

    unshift @Log::ger::Hooks_Create_Log_Routine, $hook;
}

1;
# ABSTRACT: Output log to screen

=head1 SYNOPSIS

 use Log::ger::Output Screen => (
     # stderr => 1,    # set to 0 to print to stdout instead of stderr
     # use_color => 0, # set to 1/0 to force usage of color, default is from COLOR or (-t STDOUT)
     # formatter => sub { ... },
 );
 use Log::ger;

 log_warn "blah...";


=head1 DESCRIPTION


=head1 CONFIGURATION

=head2 stderr => bool (default: 1)

Whether to print to STDERR (the default) or st=head2 use_color => bool

=head2 use_color => bool

The default is to look at the COLOR environment variable, or 1 when in
interactive mode and 0 when not in interactive mode.

=head2 formatter => code

When defined, will pass the formatted message (but being applied with colors) to
this custom formatter.


=head1 TODO

Allow customizing colors.


=head1 ENVIRONMENT

=head2 COLOR => bool


=head1 SEE ALSO

L<Log::Any::Adapter::Screen>
