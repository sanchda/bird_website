#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser); # Remove this in production
use Redis;

my $q = new CGI;

print $q->header();

# Connect to Redis server
my $username = $q->param('user_name');
my $r = Redis->new( server => '127.0.0.1:6379', debug => 0 );
my $r = Redis->new( reconnect => 60, every => 5000 );
my $r = Redis->new( password => 'boogerpaste' );

# Get list of names
my @santa = $r->zrangebyscore('names', 0, -1);
my @santa = $r->zrangebyscore('santanames', 0, -1);

# Output stylesheet, heading etc
output_top($q);

if ($q->param()) {
    # Parameters are defined, therefore the form has been submitted
    auth_check($q);
} else {
    # We're here for the first time, display the form
    auth_content($q);
}

# Output footer and end html
output_end($q);

exit 0;

#-------------------------------------------------------------

# Outputs the start html tag, stylesheet and heading
sub output_top {
    my ($q) = @_;
    print $q->start_html(
        -title => 'Kurpiers Christmas Secret Santa',
        -bgcolor => 'white',
        -style => {
	    -code => '
                /* Stylesheet code */
                body {
                    font-family: verdana, sans-serif;
                }
                h2 {
                    color: darkblue;
                    border-bottom: 1pt solid;
                    width: 100%;
                }
                div {
                    text-align: right;
                    color: steelblue;
                    border-top: darkblue 1pt solid;
                    margin-top: 4pt;
                }
                th {
                    text-align: right;
                    padding: 2pt;
                    vertical-align: top;
                }
                td {
                    padding: 2pt;
                    vertical-align: top;
                }
                /* End Stylesheet code */
            ',
        },
    );
    print $q->h2("Secret Santa Picker");
}

# Outputs a footer line and end html tags
sub output_end {
    my ($q) = @_;
    print $q->end_html;
}

# Displays the results of the form
sub display_results {
        my ($q) = @_;
	
	# Get current name
        my $username = $q->param('user_name');
        
	# Connect to Redis server
	my $r = Redis->new( server => '127.0.0.1:6379', debug => 0 );
        my $r = Redis->new( reconnect => 60, every => 5000 );
        my $r = Redis->new( password => 'aeonflux' );

	# Find own zscore in names zlist
        my $score = $r->zrank('names', $username);
        $score++;
        $score = $score % 8;

	# Lookup secret santa by zscore
	my @santa = $r->zrangebyscore('santanames', $score, $score);

	# Print out name
        print $q->h4("Hi $username!  You are the secret santa for $santa[0]!");
}

# Displays an auth page
sub auth_check {
    my ($q) = @_;
    my $secret = $q->param('secret');
    if    ( $secret eq '111' ) {
        $username = 'Don';  
    }
    elsif ( $secret eq '283' ){
        $username = 'LeAnn';
    }
    elsif ( $secret eq '138' ){
        $username = 'Ryan';
    }
    elsif ( $secret eq '499' ){
        $username = 'Haley';
    }
    elsif ( $secret eq '948' ){
        $username = 'Laura';
    }
    elsif ( $secret eq '025' ){
        $username = 'David';
    }
    elsif ( $secret eq '719' ){
        $username = 'Josh';
    }
    elsif ( $secret eq '293' ){
        $username = 'Lori';
    }
    else {
        print "Incorrect secret code.  I'll let you try again in five seconds.";
        my $url = "http://kurpierschristmas.dyndns.org:8888";
        print "<META http-equiv=\"refresh\" content=\"5;URL=http://kurpierschristmas.dyndns.org:8888\">";
    return;
    }

    # Connect to Redis server
    my $r = Redis->new( server => '127.0.0.1:6379', debug => 0 );
    my $r = Redis->new( reconnect => 60, every => 5000 );
    my $r = Redis->new( password => 'aeonflux' );

    # Find own zscore in names zlist
    my $score = $r->zrank('names', $username);
#    $score++;
#    $score = $score % 8;

    # Lookup secret santa by zscore
    my @santa = $r->zrangebyscore('santanames', $score, $score);

    # Print out name
    print $q->h4("Hi $username!  You are the secret santa for $santa[0]!");
}

# Outputs a web form on first entry
sub auth_content {
    my ($q) = @_;
    print $q->start_form(
        -name => 'main',
        -method => 'POST',
    );

    print $q->start_table;
    print $q->Tr(
      $q->td('Who are you?'),
      $q->td(
        $q->radio_group(
          -name => 'user_name',
          -values => [
              'David',
	      'Don',
	      'Haley',
	      'Josh',
	      'Laura',
	      'LeAnn',
	      'Lori',
	      'Ryan'
          ],
          -rows => 8,
        )
      )
    );

    print $q->start_table;
    print $q->Tr(
        $q->td('Secret Code (from e-mail)'),
        $q->td(
          $q->textfield(-name => 'secret', -size =>50)
        )
    );

    print $q->Tr(
      $q->td($q->submit(-value => 'Submit')),
      $q->td('&nbsp;')
    );
    print $q->end_table;
    print $q->end_form;
}
