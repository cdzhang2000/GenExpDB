use CGI qw(:standard);
print header(),
start_html(),
p("Hello World"),
end_html();

# Object oriented interface (recommended)

use CGI;

my $cgi = CGI->new;

$first="temp/var/www";

$second=~s/$first//; #set second string with empty

 $dbRec   = {};

 $eid=1;

 $dbRec->{$eid}{datasets}{eid}            = $eid;

 $dbRec->{$eid}{datasets}{type}           = "Geo";


print $cgi->header(" Testing page"),

$cgi->start_html(),

$cgi->p("Hello World"),

$cgi->p("first= ".$first),

$cgi->p("first length= ". length ($first) ),

$cgi->p("Second should be empty =".$second),


$cgi->p("second string length= ". length ($second) ),


$cgi->p("dbRec =".$dbRec[$eid][datasets][eid] ),

$cgi->end_html();

