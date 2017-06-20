package Log::ger::Output::Composite;

# DATE
# VERSION

use strict;
use warnings;

use Log::ger ();

sub import {
    my ($package, %import_args) = @_;

    # form a linear list of output specifications, and require the output
    # modules
    my @ospecs;
    {
        my $outputs = $import_args{outputs};
        for my $oname (sort keys %$outputs) {
            my $ospec0 = $outputs->{$oname};
            my @ospecs0;
            if (ref $ospec0 eq 'ARRAY') {
                @ospecs0 = map { +{ %{$_} } } @$ospec0;
            } else {
                @ospecs0 = (+{ %{ $ospec0 } });
            }

            die "Invalid output name '$oname'"
                unless $oname =~ /\A\w+(::\w+)*\z/;
            my $mod = "Log::ger::Output::$oname";
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            require $mod_pm;
            for my $ospec (@ospecs0) {
                $ospec->{_mod} = $mod;
                push @ospecs, $ospec;
            }
        }
    }

    Log::ger::add_hook(
        'create_log_routine',
        50,
        sub {
            my %args = @_;
            my $saved;
            my @codes;
            # extract the code from each output module's hook, collect them and
            # call them all in our code
            for my $ospec (@ospecs) {
                my $saved0 = Log::ger::empty_hooks('create_log_routine');
                $saved ||= $saved0;
                my $oargs = $ospec->{args} || {};
                my $mod = $ospec->{_mod};
                $mod->import(%$oargs);
                my $res = Log::ger::run_hooks(
                    'create_log_routine', \%args, 1);
                my $code = $res or die "Hook from output module '$mod' ".
                    "didn't produce log routine";
                push @codes, $code;
            }
            Log::ger::restore_hooks('create_log_routine', $saved) if $saved;
            if (@codes) {
                # XXX add setting level by output, e.g. Screen=>{level=>'info',
                # ...} then for that output the level is fixed at 'info'. or if
                # Screen=>{category_level=>{'c1'=>'info', ...}} then if category
                # is c1 then level is set at info (and if there isn't a matching
                # category, output's level is used, then ...
                #
                # if no level output is specified, try category level, e.g.
                # category_level=>{c1 => 'info'}. if there is no matching
                # category level, use general level.
                [sub { $_->(@_) for @codes }];
            } else {
                $Log::err::_log_is_null = 1;
                [sub {0}];
            }
        },
    );
}

1;
# ABSTRACT: Composite output

=head1 SYNOPSIS

 use Log::ger::Output Composite => (
     outputs => {
         # output => 1 | 0 | {option=>..., ...} | [{opt=>..., ...}, {...}, ...]
         Screen => {level=>'info', use_color=>1},
         File   => [{level=>'warn', path=>'/var/log/myapp.log'}, {category=>'myapp.security.alert', path=>'/var/log/myapp-security.log'}],
         ...
    },
    category_level => {
        'category1.sub1' => 'info',
        'category1.sub2' => 'off',
        'category2' => 'debug',
        ...
    },
 );
 use Log::ger;

 log_warn "blah...";


=head1 DESCRIPTION


=head1 CONFIGURATION



=head1 TODO

Allow customizing colors.


=head1 ENVIRONMENT

=head2 COLOR => bool


=head1 SEE ALSO

L<Log::Any::Adapter::Screen>
