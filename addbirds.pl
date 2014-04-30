#!/usr/bin/perl

use strict;
use warnings;
use Redis;

my $r = Redis->new( server => '127.0.0.1:6379', debug => 0 , reconnect => 60, every => 5000);

my $weeknum = $ARGV[0];
my $weekdir = "/var/www/birds/week" . $weeknum . "/";

# Check to see if this week exists
my @weekset = $r->smembers('birds:week:' .  $weeknum);
if(scalar @weekset != 0) {
	print "This week has already been defined.  Please delete.\n";
	exit 1
} else {
	print "Week undefined.  Populating week" . $weeknum . ".\n";
}

# Week exists.  Make sure $weekdir exists and has birds.
my @weekbirds = `ls $weekdir`;
chomp(@weekbirds);
print $weekdir . "\n";
print join(", ", @weekbirds);
print "\n";
if(scalar @weekbirds == 0) {
	print "The directory " . $weekdir . " is empty.  Exiting.\n";
	exit 1
}

# Iterate through, making the proper redis sets and populating with pictures
foreach my $bird (@weekbirds) {
	# Add underscored bird name to Redis
	$r->sadd('birds:week:' . $weeknum, $bird);

	# Add bird common name to Redis
	my $common_name = $bird;
	$r->sadd('birds:' . $bird . ':realname', $common_name);

	# Add filenames to Redis
	my $birddir = $weekdir . $bird;
	my @piclist = `ls $birddir`;
	chomp(@piclist);
	if(scalar @piclist == 0) {
		print "The " . $weekdir . $bird . " directory is empty.\n";
	}
	foreach my $pic (@piclist) {
		$r->sadd('birds:' . $bird . ':pictures', $pic);
	}
	

}
