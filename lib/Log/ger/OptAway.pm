package Log::ger::OptAway;

# DATE
# VERSION

use strict;
use warnings;

use Log::ger ();

my $hook = sub {
    require B::CallChecker;
    require B::Generate;

    my %args = @_;
    my $caller   = $args{caller};

    if ($Log::ger::Current_Level > $args{level}) {
        B::CallChecker::cv_set_call_checker(
            \&{"$caller\::$args{name}"},
            sub { B::SVOP->new("const",0,!1) },
            \!1,
        );
        return ["", 1];
    }
    ["", 0];
};

sub import {
    my $self = shift;

    unshift @Log::ger::Hooks_Install_Routine, $hook
        unless grep { $_ == $hook } @Log::ger::Hooks_Install_Routine;
}

sub unimport {
    my $self = shift;

    @Log::ger::Hooks_Install_Routine =
        grep { $_ != $hook } @Log::ger::Hooks_Install_Routine;
}

1;
# ABSTRACT: Optimize away higher-level log statements

=head1 SYNOPSIS

 use Log::ger::OptAway;


=head1 DESCRIPTION

 % perl -MLog::ger -MO=Deparse -e'log_warn "foo\n"; log_debug "bar\n"'
 log_warn("foo\n");
 log_debug("bar\n");
 -e syntax OK

 % perl -MLog::ger::OptAway -MLog::ger -MO=Deparse -e'log_warn "foo\n"; log_debug "bar\n"'
 log_warn("foo\n");
 '???';
 -e syntax OK

This module installs an Install_Routine hook that replaces logging call that are
higher than the current level (C<$Log::ger::Current_Level>) into a null
statement. By default, since Current_Level is pre-set at 3 (warn) then
C<log_info()>, C<log_debug()>, and C<log_trace()> calls will be turned

Note: C<use Log::ger::OptAway> must be performed before C<use Log::ger>.
