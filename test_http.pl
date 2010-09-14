#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Server::Brick;
use Finance::Bank::Cooperative_UK;
use Test::More;

my $http_port = 4696;
my $server = HTTP::Server::Brick->new( port => $http_port );
$server->mount('/' => { path => 't/data/' });
# In the parent, fork returns the PID of the new process.  In the child, it returns zero.
# On error, it returns undef (in the parent, there is no child).
my $fork_ret = fork();
if (not defined $fork_ret) {
  die "Couldn't fork: $!";
} elsif (not $fork_ret) {
  # This is the child

  $server->start;

  exit;
}

# This is the parent

my $coop = Finance::Bank::Cooperative_UK->new({
                                               start_url => "http://localhost:$http_port/index.html",
                                               sortcode => '',
                                               accountnum => '',
                                               pin => '',
                                               name => '',
                                               place_of_birth => '',
                                               first_school => '',
                                               last_school => '',
                                               date => '',
                                               });

$coop->login;
done_testing;

END {
  # ???: Why doesn't HUP work?  HTTP::Server::Brick's documentation says
  # HUP should cause the ->start call to return.

  kill 'KILL', $fork_ret or die "Couldn't kill off server child: $!";
}
