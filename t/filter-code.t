#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

use vars '$flag', '$str';
use Log::ger::Filter 'Code', code => sub { $main::flag };
use Log::ger::Output 'String', string => \$str;

package My::P1;
use Log::ger::Plugin 'MultilevelLog';
use Log::ger;

sub x {
    log(30, "warnmsg");
    log(50, "debugmsg");
}

package main;

$flag = 1;
$str = "";
My::P1::x();
is($str, "warnmsg\n");

$flag = 0;
$str = "";
My::P1::x();
is($str, "");

done_testing;
