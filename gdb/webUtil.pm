#------------------------------------------------------------------------------------------
# FileName    : gdb/webUtil.pm
#
# Description : Main
# Author      : jgrissom
# DateCreated : 22 Apr 2011
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package gdb::webUtil;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use Apache::Session::File;
use Apache2::Cookie;

use File::stat;
use Time::localtime;
use DBI;

use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";

our $version = "2.1";
our ( $r, $fid, %frmData );
our ( $username, $useremail, $usertype, $usergroup, $useracclevel );

#----------------------------------------------------------------------
# return get/POSTdata
# input: hash
# return: hash
#----------------------------------------------------------------------
sub getPOSTdata {

	%frmData = ();
	my $FormData = '';
	if ( $r->method() =~ /^GET$/ ) {
		$FormData = $r->args();
	} else {
		my $cnt = $r->read( $FormData, $ENV{'CONTENT_LENGTH'} );
	}

	return if !$FormData;

	my @pairs = split( /&/, $FormData );    # Get the name and value for each form input

	foreach my $pair (@pairs) {
		my ( $name, $value ) = split( /=/, $pair );    # Separate the name and value:
		$value =~ tr/+/ /;                                              # Convert + signs to spaces
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;    # Convert hex pairs (%HH) to ASCII characters:

		if ( exists $frmData{$name} ) {
			$frmData{$name} .= '~' . $value;
		} else {
			$frmData{$name} = $value;
		}
	}
}

#----------------------------------------------------------------------
# Create sessions
# input: hash
# return: hash
#----------------------------------------------------------------------
sub createSession {

	#cookie contains the sessionID, if we have it?
	#if not we will create a new sessionID and then save it in a cookie
	my %cookies = Apache2::Cookie->fetch($r);
	my $cookie  = '';
	if ( exists $cookies{'GDB'} ) {
		$cookie = $cookies{'GDB'}->value;
	}

	my %session;
	eval { tie %session, 'Apache::Session::File', $cookie, { Directory => '/run/shm', LockDirectory => '/run/shm', Transaction => 1 }; };
	if ($@) {
		die "Global data is not accessible: $@";
	} else {

		$fid                = $session{_session_id};
		$session{TIMESTAMP} = rand();
		$session{msg}       = '';

		#ckeck username
		if ( exists $session{username} ) {
			if ( $frmData{uname} ) {
				my ( $dbuemail, $dbuname, $dbutype, $dbugroup, $dbacclevel ) = checklogin( $frmData{uname}, $frmData{upass} );
				if ( $dbuname && $dbacclevel ) {
					$session{username}     = $dbuname;
					$session{useremail}    = $dbuemail;
					$session{usertype}     = $dbutype;
					$session{usergroup}    = $dbugroup;
					$session{useracclevel} = $dbacclevel;

					$frmData{reset} = 'reset'    #reset on logon
				} else {
					$session{msg} = 'Login invalid!';
				}
			}
			if ( $frmData{logoff} ) {
				$session{username}     = "guest";
				$session{useremail}    = '';
				$session{usertype}     = '-1';
				$session{usergroup}    = '-1';
				$session{useracclevel} = '-1';

				$frmData{reset} = 'reset'        #reset on logoff
			}
		} else {
			$session{username}     = "guest";
			$session{useremail}    = '';
			$session{usertype}     = '-1';
			$session{usergroup}    = '-1';
			$session{useracclevel} = '-1';
		}

		$username     = ( $session{username} )     ? $session{username}     : "guest";
		$useremail    = ( $session{useremail} )    ? $session{useremail}    : '';
		$usertype     = ( $session{usertype} )     ? $session{usertype}     : '-1';
		$usergroup    = ( $session{usergroup} )    ? $session{usergroup}    : '-1';
		$useracclevel = ( $session{useracclevel} ) ? $session{useracclevel} : '-1';

		#set cookie with the sessionID
		$cookie = Apache2::Cookie->new( $r, -name => 'GDB', -value => $fid, -path => '/' );
		$r->err_headers_out->add( 'Set-Cookie' => $cookie );
	}
}

#----------------------------------------------------------------------
# validate login
# input: string uname,upass
# return: string uname,acclevel
#----------------------------------------------------------------------
sub checklogin {
	my ( $uname, $upass ) = @_;

	my ( $dbh, $sth, $sql, $row );
	

	### added by VBI
	my $user="genexpdb";
 	my $passwd="vb1g3n3xpdb";
 	my $host="genexpdb.ccrlikknzibd.us-east-1.rds.amazonaws.com";
 	my $sid="GENEXPDB";
 	my $database_name="GENEXPDB";
 	my $port="3306";


	$dbh = DBI->connect("dbi:Oracle:host=$host;port=3306;sid=$sid", $user, $passwd, {RaiseError => 1}) or die "$DBI::errstr";

	#ended here

	#$dbh = DBI->connect( 'dbi:Oracle:oubcf', '<user>', '<pass>', { PrintError => 1, RaiseError => 1, AutoCommit => 1 } );

	my ( $dbuemail, $dbuname, $dbutype, $dbugroup, $dbacclevel );

	#$sql = qq{ select email,username,user_type,group_id,acclevel from users where username = ? and sec_pack.decpw(password) = ? };
	
	$sql = qq{ select email,username,user_type,group_id,acclevel from users where username = ? and password= ? };
	$sth = $dbh->prepare($sql);
	$sth->execute( $uname, $upass );

	my ( $email, $username, $user_type, $group_id, $acclevel );

	$sth->bind_columns( \$email, \$username, \$user_type, \$group_id, \$acclevel );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbuemail   = ($email)     ? $email     : '';
		$dbuname    = ($username)  ? $username  : '';
		$dbutype    = ($user_type) ? $user_type : '';
		$dbugroup   = ($group_id)  ? $group_id  : '';
		$dbacclevel = ($acclevel)  ? $acclevel  : '';
	}
	$sth->finish;

	return ( $dbuemail, $dbuname, $dbutype, $dbugroup, $dbacclevel );
}

#----------------------------------------------------------------------
# display all session variable
# input: session_id
# return: none
#----------------------------------------------------------------------
sub dispSessVars {

	my %session;
	eval { tie %session, 'Apache::Session::File', $fid, { Directory => '/run/shm', LockDirectory => '/run/shm', Transaction => 1 }; };
	if ($@) {
		print "Global data is not accessible: $@";
		return Apache2::Const::OK;
	}

	print "<pre>" . Dumper(%session) . "</pre>";
}

#----------------------------------------------------------------------
# Get session variable
# input: session_id, name
# return: string value
#----------------------------------------------------------------------
sub getSessVar {
	my ($name) = @_;

	my %session;
	eval { tie %session, 'Apache::Session::File', $fid, { Directory => '/run/shm', LockDirectory => '/run/shm', Transaction => 1 }; };
	if ($@) {
		print "Global data is not accessible: $@";
		return Apache2::Const::OK;
	}
	my $vars = ( $session{$name} ) ? $session{$name} : '';
	return $vars;
}

#----------------------------------------------------------------------
# Put session variable
# input: session_id, name, value
# return: none
#----------------------------------------------------------------------
sub putSessVar {
	my ( $name, $value ) = @_;

	my %session;
	eval { tie %session, 'Apache::Session::File', $fid, { Directory => '/run/shm', LockDirectory => '/run/shm', Transaction => 1 }; };
	if ($@) {
		print "Global data is not accessible: $@";
		return Apache2::Const::OK;
	}

	$session{TIMESTAMP} = rand();
	$session{$name} = $value;

	#untie %session;
}

#----------------------------------------------------------------------
# print the heading/menus
# input: hash
#		$id			session id
#		$title		optional
#		$jsCssArr	optional js/css file
# return: none
#----------------------------------------------------------------------
sub pageHead {
	my $msg = getSessVar('msg');
	$msg = ($msg) ? $msg : '';

	print
	  qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">\n},
	  qq{<html>\n},
	  qq{<head>\n},
	  qq{<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">\n},
	  qq{<title>OU E.coli Gene Expression Database (ver $version)</title>\n},
	  qq{<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">\n},
	  qq{<meta name="description" content="University of Oklahoma E.coli Gene Expression Database">\n},
	  qq{<meta name="keywords" content="microarray, E.coli, ecoli, gene, expression, database, K-12, MG1655, technology, science">\n},

	  qq{<!--[if lt IE 7]><style type="text/css">#menuh{float:none;}body{behavior:url($gdb::util::webloc/web/csshover.htc);font-size:100%;}#menuh ul li{float:left;width:100%;}#menuh a{height:1%;font:bold 0.7em/1.4em arial, sans-serif;}</style><![endif]-->\n},
	  qq{<link rel="stylesheet" type="text/css" href="$gdb::util::webloc/web/main.css">\n},
	  qq{<script type="text/javascript" src="$gdb::util::webloc/web/main.js"></script>\n},
	  qq{<script type="text/javascript" src="$gdb::util::webloc/web/sorttable2.js"></script>\n},
	  qq{<script type="text/javascript" src="$gdb::util::webloc/web/overlib_mini.js"></script><!-- overLIB (c) Erik Bosrup -->\n},
	  qq{</head>\n},
	  qq{<body bgcolor="#ffffff">\n},
	  qq{<noscript>\n},
	  qq{<h3><font color="red">** NOTICE ** This page requires JavaScript be available and enabled to function properly</font></h3>\n},
	  qq{</noscript>\n},
	  ## load message box
	  qq{<div class="hidden" id="load_msg"></div>\n};

	if ( !$username or ( $useracclevel and $useracclevel < 0 ) ) {
		loginbox($msg);    #user is not logged in
	} else {
		logofflink($username);    #we have a valid login
	}

}

#----------------------------------------------------------------------
# Display the login box
# input: string
# return: none
#----------------------------------------------------------------------
sub loginbox {
	my ($msg) = @_;

	print
	  qq{<div id="loginhead">\n},
	  qq{<form name="loginfrm" action="$ENV{REQUEST_URI}" method="post">\n},
	  qq{<font size="2" color="red">$msg</font>\n},
	  qq{<input class="sb" type="button" name="trylogin" value="Login" title="Login user" onclick="cklogin(document.loginfrm.uname.value);">\n},
	  qq{<input class="logininput" type="text" name="uname" value="" size="12" maxlength="20" onfocus="this.style.background='none'" onChange="this.style.background='none'">\n},
	  qq{<input class="logininput" type="password" name="upass" value="" size="12" maxlength="20" onfocus="this.style.background='none'" onChange="this.style.background='none'" onkeypress="return ckloginKey(event);">\n},
	  qq{</form>\n},
	  qq{</div>\n};
}

#----------------------------------------------------------------------
# Display the logoff link
# input: string
# return: none
#----------------------------------------------------------------------
sub logofflink {
	my ($username) = @_;

	print
	  qq{<div id="loginhead">\n},
	  qq{<form name="loginfrm" action="$ENV{REQUEST_URI}" method="post">\n},
	  qq{<input class="sb" type="submit" name="logoff" value="Logoff ($username)"> &nbsp;\n},
	  qq{</form>\n},
	  qq{</div>\n};
}

#----------------------------------------------------------------------
# Print the page footer
# input: string
# return: none
#----------------------------------------------------------------------
sub pageTail {
	my ($updateFile) = @_;

	my $datetime_string = '';
	if ($updateFile) {
		if ( $updateFile =~ /pm$/i ) {
			
			$updateFile = $ENV{DOCUMENT_ROOT} . "/modperl" . $updateFile;
			# $updateFile = $ENV{GENEXPDB_URL} . "/gdb" . $updateFile;
		} else {
			
			$updateFile = $ENV{DOCUMENT_ROOT} . $updateFile;
		
		}

		$datetime_string = "| updated: " . ctime( stat($updateFile)->mtime );
	}

	print
	  qq{<table width="100%" border="0" cellpadding="0" cellspacing="0">\n},
	  qq{<tr><td class="cpyrght">\n},
qq{Copyright &copy; 2000-2011 The Board of Regents of the University of Oklahoma, All Rights Reserved | <a href="http://www.ou.edu/publicaffairs/WebPolicies/termsofuse.html" target="_blank">Disclaimer</a><br>\n},
	  qq{OU Bioinformatics Core Facility @ Advanced Center for Genome Technology $datetime_string\n},
	  qq{</td></tr>\n},
	  qq{</table>\n},

	  qq{</body>\n}, qq{</html>\n};
}

#----------------------------------------------------------------------
# metalinks
# input: hash - gene annotation record
# return: string
#----------------------------------------------------------------------
sub metalinks {
	my ($dbannotRec) = @_;
	my %dbannot = %$dbannotRec;

	my $asap      = ( $dbannot{asap} )      ? $dbannot{asap}      : $dbannot{locus_tag};
	my $ecogene   = ( $dbannot{ecogene} )   ? $dbannot{ecogene}   : $dbannot{locus_tag};
	my $ecocyc    = ( $dbannot{ecocyc} )    ? $dbannot{ecocyc}    : $ecogene;
	my $gi        = ( $dbannot{gi} )        ? $dbannot{gi}        : $dbannot{locus_tag};
	my $swissprot = ( $dbannot{swissprot} ) ? $dbannot{swissprot} : $dbannot{locus_tag};

	my $metalink = '';

	$metalink .= qq{<select class="small" onChange="eval(this.options[this.selectedIndex].value);">\n};
	$metalink .= qq{<option value="" selected>&nbsp;&nbsp;&nbsp;&nbsp;--------- Select ---------</option>\n};
	$metalink .= qq{<option value="window.open('/genexpdb_v1/seqinfo.php?dna=$dbannot{locus_tag}','DNA','height=720,width=620,resizable=yes,scrollbars=yes,dependent=yes');">dna</option>\n};
	$metalink .=
	  qq{<option value="window.open('/genexpdb_v1/seqinfo.php?protein=$dbannot{locus_tag}','Protein','height=720,width=620,resizable=yes,scrollbars=yes,dependent=yes');">protein</option>\n};
	$metalink .= qq{<option value="window.open('/genexpdb_v1/metainfo.php','Metalinks','height=720,width=620,resizable=yes,scrollbars=yes,dependent=yes');">----- Metalinks Info -----</option>\n};

	$metalink .= qq{<option value="window.open('https://asap.ahabs.wisc.edu/asap/feature_info.php?FeatureID=$asap');">ASAP</option>\n};
	$metalink .= qq{<option value="window.open('http://www.xbase.ac.uk/search/?s=$dbannot{gene}');">xBASE</option>\n};
	$metalink .= qq{<option value="window.open('http://genolist.pasteur.fr/Colibri/genome.cgi?external_query+$dbannot{gene}');">Colibri</option>\n};
	$metalink .= qq{<option value="window.open('http://ecocyc.org/ECOLI/new-image?type=GENE&object=$ecocyc');">EcoCyc</option>\n};
	$metalink .= qq{<option value="window.open('http://www.ecogene.org/geneInfo.php?eg_id=$ecogene');">EcoGene</option>\n};
	$metalink .= qq{<option value="window.open('http://ecoliwiki.net/colipedia/index.php/$dbannot{gene}');">EcoliWiki</option>\n};
	$metalink .= qq{<option value="window.open('http://kr.expasy.org/cgi-bin/nicezyme.pl?$dbannot{ec_number}');">ExPASy</option>\n} if $dbannot{ec_number};
	$metalink .= qq{<option value="window.open('http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nucleotide&val=$gi');">Genbank_RefSeq</option>\n};
	$metalink .= qq{<option value="window.open('http://sal.cs.purdue.edu:8097/GB8/search/info.jsp?id=$dbannot{locus_tag}');">GenoBase</option>\n};
	$metalink .= qq{<option value="window.open('http://amigo.geneontology.org/cgi-bin/amigo/go.cgi?action=query&view=query&query=$dbannot{gene}&search_constraint=gp');">Gene Ontology</option>\n};
	$metalink .= qq{<option value="window.open('http://www.genome.ad.jp/dbget-bin/www_bget?eco:$dbannot{locus_tag}');">Kegg</option>\n};
	$metalink .= qq{<option value="window.open('http://www.genome.jp/kegg-bin/show_pathway?query=$dbannot{gene}&map=eco01100&scale=0.5&show_description=show');">Kegg pathway</option>\n};

	my $ncbi = "http://www.ncbi.nlm.nih.gov/sites/entrez?cmd=search&term=" . $dbannot{gene} . "[gene%20name]%20AND%20Escherichia%20coli%20str.%20K-12%20substr.%20MG1655[organism]&db=gene";
	$metalink .= qq{<option value="window.open('$ncbi');">NCBI Entrez</option>\n};
	$metalink .= qq{<option value="window.open('http://regulondb.cs.purdue.edu/gene?organism=ECK12&term=$dbannot{locus_tag}&format=jsp&type=gene');">RegulonDB</option>\n};
	$metalink .= qq{<option value="window.open('http://www.uniprot.org/uniprot/$swissprot');">UniProt</option>\n};
	$metalink .= qq{<option value="window.open('http://chase.ou.edu/oubcf/mouse/index.php?gene=$dbannot{gene}');">OUMCF Colonization</option>\n};
	$metalink .= qq{</select>\n};

	return $metalink;
}

1;    # return a true value

