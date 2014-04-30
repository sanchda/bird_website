#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser); # Remove this in production
use Redis;
use List::Util;

my $q = CGI->new;
my $week = $q->param( "week" );
my $user = $q->param( "user" );
if( $week eq "" ) {
	$week = 1;
}

if( $user eq "" ) {
	$user = "default";
}


# Connect to Redis server
my $r = Redis->new( server => '127.0.0.1:6379', debug => 0, reconnect => 60, every => 5000 );

# Check for session cookie.  This identifies a Redis set with the birds we want.
my $sessionID = $q->cookie('sessionID');

# If there is no ID, make one and populate a set of birds
my @birdlist;
if( $sessionID == '' ) {
	$sessionID = int(rand(100000000));
	@birdlist = $r->smembers('birds:week:' . $week);
	foreach my $bird (@birdlist) {
		$r->sadd('birds:week:' . $week . ':' . $sessionID, $bird);
	}
}

# Make cookie from sessionID and write to header
my $c = $q->cookie(-name=>'sessionID', value=>$sessionID, expires=>'+15m');
print $q->header(-type=>'text/html', -cookie=>$c);

# Check to see that the set is nonempty (or whether it exists)
my @redis_birds = $r->smembers('birds:week:'. $week . ':' . $sessionID);
if( scalar @redis_birds == 0) {
        @birdlist = $r->smembers('birds:week:' . $week);
        foreach my $bird (@birdlist) {
                $r->sadd('birds:week:' . $week . ':' . $sessionID, $bird);
        }
	print "(Re)starting the test.  Good luck!<br />";
}

# Pop a bird off the set and continue
my $cur_bird = $r->spop('birds:week:' . $week . ':' . $sessionID);

# Refresh Redis sessionID expiry
$r->expire('birds:week:' . $week . ':' . $sessionID, 900);


# Save to the http query and display
$q->param(-name=>'cur_bird', -value=>$cur_bird);

# Output stylesheet, heading etc
output_top($q);

# Display bird
display_bird($q);

# Output footer and end html
output_end($q);

exit 0;

#-------------------------------------------------------------

# Outputs the start html tag, stylesheet and heading
sub output_top {
    my ($q) = @_;
    my $cur_bird = $q->param('cur_bird');
    print $q->start_html(
        -title => 'Bird test',
        -script=> [
                    {
                        -src=>'../../test/shortcut.js',
                        -type=>'text/javascript'
                    },
                    {
                        -type=>'text/javascript',
                        -code=>'function initKeys() {
                                  shortcut.add("k", function() {
                                        window.location = "?week=' . $week .'";
                                  },
				    {"disable_in_input":true}
                                  );
                                  
                                  shortcut.add("j", function() {
				  	document.getElementById("birdname").value="' . $cur_bird . '";
				  },
				    {"disable_in_input":true}
                                  );
                                }

                                window.onload = initKeys;'

                    }
                  ],

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
    print $q->h2("Bird test");
    print $q->h4("Use 'j' to display the bird name, 'k' to move to the next bird. (or click/mouseover as before)");
}

# Outputs a footer line and end html tags
sub output_end {
    my ($q) = @_;
    print $q->end_html;
}

# Displays a bird for the given week
sub display_bird {
        my ($q) = @_;
	
	# Recover the current bird
	my $cur_bird = $q->param('cur_bird');	
       
	# Pick up bird name
	my $bird_name = $cur_bird;
 
	# Pick a random image
	my $bird_pic = $r->srandmember('birds:' . $cur_bird . ':pictures');
	$bird_pic = "../birds/week" . $week . "/" . $cur_bird . "/" . $bird_pic;

	# Format the page
        print "<center> <a href=\"./weeklybird.pl?week=" . $week . "\"><img src=" . $bird_pic . " title=" . $bird_name . " height=400></a>";
        print "<br /> <span style=\"color:#ffffff;background-color:#ffffff;\">" . $bird_name ."</span></p> </center>";
	print "<center><input id=\"birdname\" type=\"text\" value=\"\" /></center><br>";

}

