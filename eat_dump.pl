#!/usr/bin/perl
use warnings;
use strict;
use Finance::Bank::Cooperative_UK;
use Data::Dump::Streamer;

my $data = do {local $/; <>};
my $coop = Finance::Bank::Cooperative_UK->new(sortcode => undef,
                                              accountnum => undef,
                                              pin => undef,
                                              name => undef,
                                              place_of_birth => undef,
                                              first_school => undef,
                                              last_school => undef,
                                              date => undef);
Dump($coop->parse_recent_items($data));

