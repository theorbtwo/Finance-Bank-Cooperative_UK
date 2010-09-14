#!/usr/bin/perl
use warnings;
use strict;
use Finance::Bank::Cooperative_UK;
# FIXME: Something about the API of this rubs me the wrong way.  Could
# have sworn the last time I looked that it was less evil...
use YAML::Any 'LoadFile';
use Data::Dump::Streamer 'Dump';

my $conf = LoadFile(glob('~/.coop'));
Dump $conf;

my $coop = Finance::Bank::Cooperative_UK->new(%$conf);
$coop->login;
