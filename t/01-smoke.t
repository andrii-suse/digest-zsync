#!/usr/bin/perl -w

use strict;
use Digest::Zsync;
use Test::More tests => 1;

sub calc_digest {
    my $len = 0;
    for my $s (@_) {
        $len += length($s);
    }
    my $d = Digest::Zsync->new;
    $d->init($len);
    for my $s (@_) {
        $d->add($s);
    }
    return $d->digest;
}


my $in = "1111111111\n";
my $r  = calc_digest($in);
my $hex = uc unpack 'H*', $r;

is_deeply($hex, '96FF97CCB1', 'test 1');
