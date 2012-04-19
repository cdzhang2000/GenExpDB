#------------------------------------------------------------------------------------------
# FileName    : gdb/geoupdate.pm
#
# Description : Search GEO and compare against GenExpDB accessions
# Author      : jgrissom
# DateCreated : 20 Dec 2010
# Version     : 2.0
# Modified    : 29 Apr 2011 - reworked curl parse
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package testgdb::geoupdate;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use WWW::Curl::Easy;
use XML::Simple;

use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";

our %statType  = ( 1, "New",  2, "addPending", 3, "Active", 4, "Hold",    5, "Disabled" );
our %statColor = ( 1, "blue", 2, "purple",     3, "green",  4, "#d4a017", 5, "red" );

#----------------------------------------------------------------------
# geoUpdate Main
# input: none
# return: none
#----------------------------------------------------------------------
sub geoUpdateMain {

	my $curatedRef = testgdb::oracle::dbgetCurated();
	displayCurated($curatedRef) if %{$curatedRef};

}

#----------------------------------------------------------------------
# display Curated
# input: hash
# return: none
#----------------------------------------------------------------------
sub displayCurated {
	my ( $curatedRef, $curacc ) = @_;
	my %curated = %$curatedRef;

	my %statcnt;
	for my $acc ( keys %curated ) {
		$statcnt{ $curated{$acc}{status} }++;
	}
	my $gsenum = scalar keys %curated;
	my $cnt    = qq{GeoGSE: <b>$gsenum</b>};

	for my $i ( sort keys %statType ) {
		my $tot = ( $statcnt{$i} ) ? $statcnt{$i} : 0;
		$cnt .= qq{&nbsp;&nbsp;&nbsp;&nbsp; <font color="$statColor{$i}">$statType{$i}</font>: <b>$tot</b>};
	}

	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb">\n},
	  qq{<tr>\n},
	  qq{<th class="thc">GEO ACCESSION UPDATE</th>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
qq{<td class="tdl">&nbsp;&nbsp;&nbsp;<input class="ebtn" type="button" name="testcntl" value="Fetch/Update GEO accessions" onclick="geo();" onmouseover="return overlib('Retrieve new GEO accessions');" onmouseout="return nd();">\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td class="tdl">\n},

	  qq{<div class="stt">\n};

	print qq{<table align="center" cellpadding="0" cellspacing="1">\n};
	print qq{<tr>\n};
	print qq{<td class="tdl" colspan="5">$cnt</td>\n};
	print qq{</tr>\n};
	print qq{<tr>\n};
	print qq{<th class="thc">ACCESSION</th>\n};
	print qq{<th class="thc">STATUS</th>\n};
	print qq{<th class="thc">INFO</th>\n};
	print qq{<th class="thc">DESC</th>\n};
	#print qq{<th class="thc">QUERY MATCH (Escherichia[ORGANISM])</th>\n};
	
	print qq{<th class="thc">QUERY MATCH (Brucella[ORGANISM])</th>\n};
	print qq{</tr>\n};

	for my $acc ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } keys %curated ) {
		my $bgc = ( $curacc and $curacc =~ /$acc/ ) ? "#e8e1e9" : "#ebf0f2";
		print qq{<tr bgcolor="$bgc">\n};

		print qq{<td class="tdl">};
		print qq{<img id="esign$acc" src="$testgdb::util::webloc/web/plus.gif" onclick="geoEdit('$acc');" alt="" onmouseover="this.style.cursor='pointer';return overlib('click to edit record');" onmouseout="return nd();">\n};
		print qq{&nbsp;&nbsp; <a href="http://www.ncbi.nlm.nih.gov/projects/geo/query/acc.cgi?acc=$acc" target="_blank">$acc</a>};
		print qq{</td>\n};

		print qq{<td class="tdl"><font color="$statColor{ $curated{$acc}{status} }">$statType{ $curated{$acc}{status} }</font></td>\n};

		my $tmpinfo = ( $curated{$acc}{info} ) ? $curated{$acc}{info} : '';
		my $info = qq{<td class="tdl">$tmpinfo</td>\n};
		if ( length($tmpinfo) > 70 ) {
			$tmpinfo = substr $curated{$acc}{info}, 0, 67;
			$info = qq{<td class="tdl">$tmpinfo <font color="red"><b>>>></b></font></td>\n};
		}
		print $info;

		my $geodesc = ($curated{$acc}{geodesc}) ? $curated{$acc}{geodesc} : '';
		
		print qq{<td class="tdl">$geodesc</td>\n};

		my $tmpgeomatch = ( $curated{$acc}{geomatch} ) ? $curated{$acc}{geomatch} : '';
		my $geomatch = qq{<td class="tdl">$tmpgeomatch</td>\n};
		if ( length($tmpgeomatch) > 70 ) {
			$tmpgeomatch = substr $curated{$acc}{geomatch}, 0, 67;
			$geomatch = qq{<td class="tdl" onmouseover="return overlib('$curated{$acc}{geomatch}');" onmouseout="return nd();">$tmpgeomatch <font color="red"><b>>>></b></font></td>\n};
		}
		print $geomatch;
		print qq{</tr>\n};

		#hidden info
		print qq{<tr><td colspan="5"><div class="hidden" id="$acc"></div></td></tr>\n};

	}
	print qq{</table>\n};

	print
	  qq{</div>\n},

	  qq{</td>\n}, qq{</tr>\n},

	  qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# edit geo rec
# input: hash
# return: none
#----------------------------------------------------------------------
sub editGeoRec {

	my $acc        = $testgdb::webUtil::frmData{acc};
	my $curatedRef = testgdb::oracle::dbgetCurated($acc);
	my %curated    = %$curatedRef;

	my $status    = $curated{$acc}{status};
	my $pmid      = ( $curated{$acc}{pmid} ) ? $curated{$acc}{pmid} : '';
	my $strain    = ( $curated{$acc}{strain} ) ? $curated{$acc}{strain} : '';
	my $substrain = ( $curated{$acc}{substrain} ) ? $curated{$acc}{substrain} : '';
	my $info      = ( $curated{$acc}{info} ) ? $curated{$acc}{info} : '';
	my $adddate   = ( $curated{$acc}{adddate} ) ? $curated{$acc}{adddate} : '';
	my $adduser   = ( $curated{$acc}{adduser} ) ? $curated{$acc}{adduser} : '';
	my $moddate   = ( $curated{$acc}{moddate} ) ? "$curated{$acc}{moddate} by " : '';
	my $moduser   = ( $curated{$acc}{moduser} ) ? $curated{$acc}{moduser} : '';

	my %statInfo = (
		1 => [ 1, 2, 4, 5 ],
		2 => [ 2, 4, 5 ],
		3 => [ 3, 4, 5 ],
		4 => [ 4, 2, 5 ],
		5 => [ 5, 2, 4 ]
	);

	print qq{<table cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
qq{<td valign="top"><a class="exmp" onclick="geoEdit('$testgdb::webUtil::frmData{acc}');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb" align="center" cellpadding="1" cellspacing="1">\n};

	print
	  qq{<tr bgcolor="#ebf0f2">\n},
	  qq{<td class="tdl"><b>Status:</b></td>\n},
	  qq{<td class="tdl">},
	  qq{<select class="small" name="curStatus$acc">};

	my @stat = @{ $statInfo{$status} };

	foreach my $type (@stat) {
		my $sel = ( $type =~ /$status/ ) ? 'selected' : '';

		print qq{<option value="$type" $sel>$statType{$type}</option>\n};
	}

	print
	  qq{</select>\n},
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="tdl"><b>PubMed:</b></td>\n},     qq{<td class="tdl"><input class="small" type="text" name="curPmid$acc" value="$pmid"></td>\n},           qq{</tr>\n},
	  qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="tdl"><b>Strain:</b></td>\n},     qq{<td class="tdl"><input class="small" type="text" name="curStrain$acc" value="$strain"></td>\n},       qq{</tr>\n},
	  qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="tdl"><b>Sub-Strain:</b></td>\n}, qq{<td class="tdl"><input class="small" type="text" name="curSubStrain$acc" value="$substrain"></td>\n}, qq{</tr>\n},
	  qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="tdl"><b>Info:</b></td>\n},     qq{<td class="tdl"><textarea class="small" name="curInfo$acc" rows="5" cols="80">$info</textarea></td>\n}, qq{</tr>\n},
	  qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="tdl"><b>Added:</b></td>\n},    qq{<td class="tdl">$adddate by $adduser</td>\n},                                                           qq{</tr>\n},
	  qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="tdl"><b>Modified:</b></td>\n}, qq{<td class="tdl">$moddate $moduser</td>\n},                                                              qq{</tr>\n},
	  qq{<tr>\n}, qq{<td class="tdc" colspan="2"><input class="ebtn" type="button" value="Save" onclick="geoSave('$acc');"></td>\n}, qq{</tr>\n},
	  qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# save edit geo rec
# input: hash
# return: none
#----------------------------------------------------------------------
sub saveGeoRec {

	my $acc        = $testgdb::webUtil::frmData{acc};
	my $curatedRef = testgdb::oracle::dbgetCurated($acc);
	my %curated    = %$curatedRef;
	my $username     = testgdb::webUtil::getSessVar( 'username' );

	my $status    = $curated{$acc}{status};
	my $pmid      = ( $curated{$acc}{pmid} ) ? $curated{$acc}{pmid} : '';
	my $strain    = ( $curated{$acc}{strain} ) ? $curated{$acc}{strain} : '';
	my $substrain = ( $curated{$acc}{substrain} ) ? $curated{$acc}{substrain} : '';
	my $info      = ( $curated{$acc}{info} ) ? $curated{$acc}{info} : '';

	my ( $inpStatus, $inpPmid, $inpStrain, $inpSubStrain, $inpInfo ) = split( /\|\~\|/, $testgdb::webUtil::frmData{parms} );

	$inpPmid      = ($inpPmid)      ? $inpPmid      : '';
	$inpStrain    = ($inpStrain)    ? $inpStrain    : '';
	$inpSubStrain = ($inpSubStrain) ? $inpSubStrain : '';
	$inpInfo      = ($inpInfo)      ? $inpInfo      : '';

	my %chg;
	if ( $status !~ /^$inpStatus$/ ) {
		$chg{$acc}{status} = $inpStatus;
	}
	if ( $pmid !~ /^$inpPmid$/ ) {
		$chg{$acc}{pmid} = $inpPmid;
	}
	if ( $strain !~ /^$inpStrain$/ ) {
		$chg{$acc}{strain} = $inpStrain;
	}
	if ( $substrain !~ /^$inpSubStrain$/ ) {
		$chg{$acc}{substrain} = $inpSubStrain;
	}
	if ( $info !~ /^$inpInfo$/ ) {
		$chg{$acc}{info} = $inpInfo;
	}

	if ( !%chg ) {
		print qq{<font color="blue">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;No changes made for $acc</font>\n};
	} else {
		my @data = ($username);

		my $sql = "update curated set moddate=sysdate,moduser=?";
		while ( my ( $acc, $val ) = each(%chg) ) {
			while ( my ( $f2, $v2 ) = each(%$val) ) {
				$sql .= ",$f2=?";
				push @data, $v2;
			}
		}
		$sql .= " where accession=?";
		push @data, $acc;

		my $rc = testgdb::oracle::dbsavegeoEdit( $sql, \@data );

		if ( $rc =~ /1/ ) {
			print qq{<font color="green">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Update successful for $acc</font>\n};
		} else {
			print qq{<font color="red">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Error updating $acc !</font>\n};
		}
	}
	$curatedRef = testgdb::oracle::dbgetCurated();
	displayCurated($curatedRef, $acc) if %{$curatedRef};
}

#----------------------------------------------------------------------
# esearch/efetch from Geo
# input: none
# return: none
#----------------------------------------------------------------------
sub geoFetch {
	my $curl = WWW::Curl::Easy->new;

	$curl->setopt( CURLOPT_HEADER, 0 );                                                                                                                     #no header
	#$curl->setopt( CURLOPT_URL,    'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&retmax=1&usehistory=y&term=Escherichia[ORGANISM]' );

	$curl->setopt( CURLOPT_URL,    'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&retmax=1&usehistory=y&term=Brucella[ORGANISM]' );
	my $esearch;
	$curl->setopt( CURLOPT_WRITEDATA, \$esearch );

	my $retcode = $curl->perform;                                                                                                                           # Starts the Search request

	if ( $retcode != 0 ) {
		print( "Search error: $retcode " . $curl->strerror($retcode) . " " . $curl->errbuf . "<br>" );
	}

	my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
	if ( $response_code !~ /200/ ) {
		print("Search error: response_code not 200<br>");
	}
	my $xml = XMLin($esearch);

	##Fetch
	$curl->setopt( CURLOPT_URL, "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gds&retmode=html&report=brief&query_key=$xml->{QueryKey}&WebEnv=$xml->{WebEnv}" );
	my $efetch;
	$curl->setopt( CURLOPT_WRITEDATA, \$efetch );

	$retcode = $curl->perform;    # Starts the Fetch request

	if ( $retcode != 0 ) {
		print( "Fetch error: $retcode " . $curl->strerror($retcode) . " " . $curl->errbuf . "<br>" );
	}

	$response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
	if ( $response_code !~ /200/ ) {
		print("Fetch error: response_code not 200<br>");
	}

	$efetch =~ s/\n/~/g;
	my @data = split( /~~(\d+):/, $efetch );

	my %gse;

	shift(@data);    #html header line in hex
	foreach my $rec (@data) {
		chomp $rec;
		$rec =~ s/~//g;
		$rec =~ s/^\s+//;
		$rec =~ s/\s+$//;
		next if !$rec;
		next if ( $rec =~ /^[+-]?\d+$/ );    #number

		my ( $acc, $rest ) = split( /record:/, $rec );
		$acc =~ s/^\s+|\s+$//;

		my ( $p1, $p2, $p3 ) = split( /(\[Es.+?\])/, $rest );
		$p1 =~ s/^\s+// if $p1;
		$p1 =~ s/\s+$// if $p1;
		$p2 =~ s/^\s+// if $p2;
		$p2 =~ s/\s+$// if $p2;
		$p3 =~ s/^\s+// if $p3;
		$p3 =~ s/\s+$// if $p3;

		$p1 = ($p1) ? $p1 : '';
		$p2 = ($p2) ? $p2 : '';
		$p3 = ($p3) ? $p3 : '';

		$p2 =~ s/\[|\]//g;

		my $desc = ($p1) ? $p1 : $p3;

	 	if (length($desc) >= 4000){
		$desc = substr($desc, 0, 3009) ;
		}
		if ( $acc =~ /^GSE/ ) {
			$gse{$acc}{match} = $p2;
			$gse{$acc}{desc}  = $desc;
		}
	}

	#update if we have new accessions
	my $numadded = testgdb::oracle::dbputgeoUpdate( \%gse ) if %gse;

	print "&nbsp;&nbsp;&nbsp; Number added: $numadded<br>";
	geoUpdateMain();

}

1;    # return a true value
