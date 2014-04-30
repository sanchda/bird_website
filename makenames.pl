#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser); # Remove this in production
use Redis


# Connect to the Redis server
my $r = Redis->new( server => '127.0.0.1:6379', debug => 0 );
my $r = Redis->new( reconnect => 60, every => 5000 );
my $r = Redis->new( password => 'aeonflux' );

# Create new CGI context
my $q = new CGI;

print $q->header();


output_top($q);
if ($q->param()) {
    # Form has already been submitted
    auth_check($q);
} else {
    # Form has not been submitted
    auth_content($q);
}

output_end($q);

exit 0;


sub output_top {
    my ($q) = @_;
    print $q->start_html(
	-title => 'Admin page',
	-bgcolor => 'white'
    );
    print $q->h2("Admin page");
}

sub auth_content {
    my ($q) = @_;
    print $q->start_form(
	-name => 'main',
	-method => 'POST',
    );

    print $q->start_table;
    print $q->Tr(
	$q->td('Password'),
	$q->td(
	  $q->textfield(-name => 'password', -size => 50)
	)
    );
    print $q->Tr(
        $q->td($q->submit(-value => 'Submit')),
        $q->td('&nbsp;')
    );
    print $q->end_table;
    print $q->end_form;
}

sub auth_check {
    my ($q) = @_;
    my $password = $q->param('password');
    if ( $password eq 'aeonflux' ) {
        auth_continue($q);
    } else {
        auth_failed($q);
    }
}

sub auth_failed {
    my ($q) = @_;
    print "Password failed."

}

sub auth_continue {
    # Make a hard list of names
    my @family_names = ('David', 'Don', 'Haley', 'Josh', 'Laura', 'LeAnn', 'Lori', 'Ryan');
    
    # Grab state the Perl way
    my ($q) = @_;

    print $q->h5("Name shuffler");

    # Delete existing sorted set of names
    $r->del('names');
    $r->del('santanames');

    # Define counter for later
    my $i = 0;    

    # Shuffle list of family names
    fisher_yates_shuffle( \@family_names );
    @family_names =   ('Don', 'David', 'Haley', 'Laura', 'LeAnn', 'Josh', 'Ryan', 'Lori');
    my @santa_names = ('Josh','Haley', 'Laura', 'LeAnn', 'David', 'Ryan', 'Lori', 'Don');

    # Make new sorted set of names
    foreach(@family_names)
   {
        print "$_\r\n";
        $r->zadd('names', $i, $_);
        $i++;
#        $r->zadd('santanames', $i++, $_);
   }
   $i = 0;
   print "----";
   foreach(@santa_names)
   {
      print "$_\r\n";
      $r->zadd('santanames', $i++, $_);
   }

    # Make sure that Laura gets Haley
    # TODO TODO!!!
   
}

sub output_end {
    my ($q) = @_;
    print $q->end_html;
}

# randomly permutate @array in place
sub fisher_yates_shuffle
{
    my $array = shift;
    my $i = @$array;
    while ( --$i )
    {
        my $j = int rand( $i+1 );
        @$array[$i,$j] = @$array[$j,$i];
    }
}
