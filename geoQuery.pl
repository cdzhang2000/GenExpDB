#!/usr/bin/perl
#------------------------------------------------------------------------------------------
# FileName    : geoQuery.pl
#
# Description : Query GEO for search string
# Author      : jgrissom
# DateCreated : 20 Dec 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2011 University of Oklahoma
#------------------------------------------------------------------------------------------
$| = 1;    # dump buffer immediately
use strict;
use warnings FATAL => 'all';

use WWW::Curl::Easy;		#using WWW-Curl-4.15
use XML::Simple;

use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";

#==============================================================================
## Main
#==============================================================================
my $parm = ( $ARGV[0] ) ? $ARGV[0] : '';

if ( $parm !~ /^query/ ) {
	print "\n\tUsage: $0  <query>	
	Query GEO for ORGANISM=Escherichia
	#Query GEO for ORGANISM=Mycobacterium
	\n\n";
	exit(-1);
}

my $curl = WWW::Curl::Easy->new;

$curl->setopt( CURLOPT_HEADER, 0 );                                                                                                                     #no header
$curl->setopt( CURLOPT_URL,    'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&retmax=1&usehistory=y&term=Escherichia[ORGANISM]' );

#$curl->setopt( CURLOPT_URL,    'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&retmax=1&usehistory=y&term=Mycobacterium[ORGANISM]' );

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

	if ( $acc =~ /^GSE/ ) {
		$gse{$acc}{match} = $p2;
		$gse{$acc}{desc}  = $desc;
	}
}

for my $acc ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } keys %gse ) {
	print "$acc\t$gse{$acc}{desc}\t$gse{$acc}{match}\n";
}

print STDERR "\nDone\n";

exit(0);
