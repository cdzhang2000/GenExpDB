#package src::test::currenttime;
  
  use strict;
  use warnings;
 use File::stat;
  
  use Apache2::RequestRec ();
  use Apache2::RequestIO ();
  
  use Apache2::Const -compile => qw(OK);

	use CGI qw(:standard);
	print header(),
	start_html(),
	p("Hello World"),
	end_html();
	# Object oriented interface (recommended)

use CGI;

my $cgi = CGI->new;


my $r = shift;

print $cgi->header(),
$cgi->start_html(),
$cgi->p("Hello World");
$cgi->p(  $r->print("Now is: " . scalar(localtime) . "\n\n"));

my $filename="/var/www/perl/hello.pl";

my $sb=stat($filename);
$cgi->p(  $r->print("file stat mtime: " . $sb->mtime . "\n"));

$cgi->end_html();

 
 
  sub handler {
      my $r = shift;
  
      $r->content_type('text/plain');
      $r->print("Now is: " . scalar(localtime) . "\n");
  
      return Apache2::Const::OK;
  }
  1;
