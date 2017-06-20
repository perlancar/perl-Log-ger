#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger ();

package My::P1;
use Log::ger;

package main;

my $str1 = "";
my $str2 = "";
Log::ger::reset_hooks('create_log_routine');
require Log::ger::Output;
Log::ger::Output->set('Composite', outputs=>{String=>[ {args=>{string=>\$str1}}, {args=>{string=>\$str2}} ]});
My::P1::log_warn("warn");
My::P1::log_debug("debug");
is($str1, "warn\n");
is($str2, "warn\n");

# XXX test filtering: output level
# XXX test filtering: output category_level
# XXX test filtering: category_level

done_testing;
