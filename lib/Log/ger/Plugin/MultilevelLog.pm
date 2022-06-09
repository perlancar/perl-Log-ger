package Log::ger::Plugin::MultilevelLog;

use strict;
use warnings;

use Log::ger::Util;

# AUTHORITY
# DATE
# DIST
# VERSION

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %conf = @_;

    my $sub_name    = $conf{sub_name}    || 'log';
    my $method_name = $conf{method_name} || 'log';

    return {
        create_filter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $filter = sub {
                    my $level = Log::ger::Util::numeric_level(shift);
                    return 0 unless $level <= $Log::ger::Current_Level;
                    {level=>$level};
                };

                [$filter, 0, 'ml'];
            },
        ],

        create_formatter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $formatter =

                 # just like the default formatter, except it accepts first
                 # argument (level)
                    sub {
                        shift; # level
                        return $_[0] if @_ < 2;
                        my $fmt = shift;
                        my @args;
                        for (@_) {
                            if (!defined($_)) {
                                push @args, '<undef>';
                            } elsif (ref $_) {
                                push @args, Log::ger::Util::_dump($_);
                            } else {
                                push @args, $_;
                            }
                        }
                        # redefine is just a dummy category for perls < 5.22
                        # which don't have 'redundant' yet
                        no warnings ($warnings::Bits{'redundant'} ? 'redundant' : 'redefine');
                        sprintf $fmt, @args;
                    };

                [$formatter, 0, 'ml'];
            },
        ],

        create_routine_names => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"
                return [{
                    logger_subs    => [[$sub_name   , undef, 'ml', undef, 'ml']],
                    logger_methods => [[$method_name, undef, 'ml', undef, 'ml']],
                }, $conf{exclusive}];
            },
        ],
    };
}

1;
# ABSTRACT: (DEPRECATED) Old name for Log::ger::Format::MultilevelLog

=for Pod::Coverage ^(.+)$

=head1 DESCRIPTION

This plugin has been renamed to L<Log::ger::Format::MultilevelLog> in 0.038. The
old name is provided for backward compatibility for now, but is deprecated and
will be removed in the future. Please switch to the new name and be aware that
format plugins only affect the current package.


=head1 SEE ALSO

L<Log::ger::Format::MultilevelLog>
