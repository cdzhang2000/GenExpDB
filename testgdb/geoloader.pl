#!/usr/bin/perl
#------------------------------------------------------------------------------------------
# FileName    : geoloader.pl
#
# Description : Load Geo Mage-ML xml files into oracle table
#
# Author      : jgrissom
# DateCreated : 5 Mar 2008
# Version     : 1.0
# Modified    : 10 Dec 2010 moved to bioweb
#               18 Jan 2011 fixed xml xerces loading
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
#
# IF ERROR:
#      MESSAGE: An exception occurred! Type:UTFDataFormatException, Message:invalid byte 1 () of a 1-byte sequence.
#
#	try changing encoding from UTF-8 to ISO-8859-1 in family.xml
# 
#------------------------------------------------------------------------------------------
package main;

$| = 1;    # dump buffer immediately
use strict;
use warnings FATAL => 'all';

use XML::Xerces;
use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";

##
# uncomment ### whene you get your database setup
#				and remove DummyDb
##

use OracleDb;
#use DummyDb;

use GeoContributor;
use GeoDatabase;
use GeoPlatform;
use GeoSample;
use GeoSeries;

#==============================================================================
## Main
#==============================================================================
my $parm = ( $ARGV[0] ) ? $ARGV[0] : '';

my @gse;

if ( $parm =~ /^addPending$/i ) {
	my $gseRef = db::dbgdbCurated();	#get all addPending
	@gse = @$gseRef;
} elsif ( $parm =~ /^GSE[0-9]+$/i ) {
	push @gse, $parm;
} else {
	print "\n\tUsage: $0 [GSE_accession | addPending]\n
	\tLoad Geo Accession Mage-ML xml files into oracle table
	\t\tGSE_accession - load this accession
	\t\taddPending - load all addPending from curated table.\n";
	exit(-1);
}

#my $dataDir = "/genexpdb/geo/accessions/";

my $dataDir = "../accessions/";

my %expm;

for my $id (@gse) {

	#change into upper case
	$id = uc($id); 
	
	#check if the directory exists
	if ( !-d $dataDir . $id ) {
		print STDERR "\tERROR: accession $id has not been downloaded from GEO!\n";
		next;
	}
	my $xmlFile = $dataDir . $id ."/$id" . "_family.xml";
	#check if the XXXX_family.xml file exists
	if ( !-f $xmlFile ) {
		print STDERR "\tERROR: accession $id XML not found!\n";
		next;
	}
	#add the file name into the array expm
	$expm{$id} = $xmlFile;
}

my $eid   = 0;
my $hash  = ();    #hash
my $dbRec = ();    #hash

my $tmpIdent       = ();
my $tmpIdentcnt    = 0;
my $tmpTblIdent    = ();
my $tmpTblIdentcnt = 0;

my $ds_type   = '';
my $ds_name   = '';

my $level = 0;     #prtLevels

XML::Xerces::XMLPlatformUtils::Initialize();

my $DOM           = XML::Xerces::XercesDOMParser->new();
my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
$DOM->setErrorHandler($ERROR_HANDLER);
$DOM->setValidationScheme($XML::Xerces::AbstractDOMParser::Val_Auto);

#parse each experiment
while ( my ( $gse, $filename ) = each(%expm) ) {

	$dbRec     = {};

	print STDOUT "load $gse...";
	$DOM->parse($filename);

	print STDOUT "getDocument...";
	my $doc = $DOM->getDocument();

	print STDOUT "getDocumentElement...";
	my $root = $doc->getDocumentElement();

	print STDOUT "hash...";
	my $hash = node2hash($root);

	#	prtLevels($hash);

	print STDOUT "dataset...";
	
	my $dirpart = $dataDir . $gse ."/";
	$filename =~ s/$dirpart//;           #set $filename with empty string

	$eid                                     = db::dbgetNextseq();  #get EID sequence number from the oracle sequence
	
	$dbRec->{$eid}{datasets}{eid}            = $eid;

	$dbRec->{$eid}{datasets}{type}           = "Geo";
	$dbRec->{$eid}{datasets}{type_id}        = $gse;
	$dbRec->{$eid}{datasets}{filename}       = $filename;
	$dbRec->{$eid}{datasets}{adddate}        = "sysdate";
	$dbRec->{$eid}{Identifiable}{id}         = $eid;
	$dbRec->{$eid}{Identifiable}{eid}        = $eid;
	$dbRec->{$eid}{Identifiable}{identifier} = $gse;
	db::dbWrtrec($dbRec);
	
	#update curated
	db::dbUpdateCurated($eid, $gse);

	print STDOUT "GeoParse...";
	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				if ( $h1->{node_name} =~ /^Contributor$/ ) {
					GeoContributor::GeoContributor_package($h1);
				}
				if ( $h1->{node_name} =~ /^Database$/ ) {
					GeoDatabase::GeoDatabase_package($h1);
				}
				if ( $h1->{node_name} =~ /^Platform$/ ) {
					GeoPlatform::GeoPlatform_package($h1);
				}
				if ( $h1->{node_name} =~ /^Sample$/ ) {
					GeoSample::GeoSample_package($h1);
				}
				if ( $h1->{node_name} =~ /^Series$/ ) {
					GeoSeries::GeoSeries_package($gse, $h1);
				}
			}
		}
	}

	#	print STDOUT Data::Dumper->Dump( [$hash], ['hash'] );
	print STDOUT "ok\n";
}

#
## All done
#

print STDOUT "Done\n";

XML::Xerces::XMLPlatformUtils::Terminate();
exit(0);

#==============================================================================
## main-subroutines
#==============================================================================

sub prtLevels {
	my $hash   = shift;
	my $indent = '  ' x ++$level;

	#print $indent . $hash->{"node_name"} . "\n";

	while ( my ( $key, $value ) = each(%$hash) ) {
		if ( $key eq "node_name" ) {
			if ( $level < 3 ) {
				print "${indent} $level $value\n";
			}
		} elsif ( ref($value) eq 'ARRAY' ) {
			foreach my $h2 (@$value) {
				prtLevels($h2);
			}
		} elsif ( ref($value) eq 'HASH' ) {
			prtLevels($value);
		}
	}
	$level--;
}

sub getEid {
	return $eid;
}

sub saveTmpID {
	my ( $table, $whereFld, $whereVal, $eid, $field, $value ) = @_;

	$tmpIdentcnt++;
	$tmpIdent->{$tmpIdentcnt}{table}    = $table;
	$tmpIdent->{$tmpIdentcnt}{whereFld} = $whereFld;
	$tmpIdent->{$tmpIdentcnt}{whereVal} = $whereVal;
	$tmpIdent->{$tmpIdentcnt}{eid}      = $eid;
	$tmpIdent->{$tmpIdentcnt}{field}    = $field;
	$tmpIdent->{$tmpIdentcnt}{value}    = $value;
}

sub saveTmpTabID {
	my ( $addtable, $table, $whereFld, $whereVal, $eid, $field, $value ) = @_;

	$tmpTblIdentcnt++;
	$tmpTblIdent->{$tmpTblIdentcnt}{addtable} = $addtable;
	$tmpTblIdent->{$tmpTblIdentcnt}{table}    = $table;
	$tmpTblIdent->{$tmpTblIdentcnt}{whereFld} = $whereFld;
	$tmpTblIdent->{$tmpTblIdentcnt}{whereVal} = $whereVal;
	$tmpTblIdent->{$tmpTblIdentcnt}{eid}      = $eid;
	$tmpTblIdent->{$tmpTblIdentcnt}{field}    = $field;
	$tmpTblIdent->{$tmpTblIdentcnt}{value}    = $value;
}

sub trimText {
	my ($text) = @_;

	if ($text) {
		#s/^\s+//; #remove leading spaces
		$text =~ s/^\s+//;
		#s/\s+$//; #remove trailing spaces
		$text =~ s/\s+$//;
		#remove multiple newline	
		$text =~ s/\n+/\; /g;
	} else {
		$text = '';
	}

	return $text;
}

sub node2hash {
	my $node   = shift;
	my $mydata = {};

	$mydata->{node_name} = $node->getNodeName();
	if ( $node->hasAttributes() ) {
		my %attrs = $node->getAttributes();
		$mydata->{attributes} = \%attrs;
	}

	# insert code to handle children
	if ( $node->hasChildNodes() ) {
		my $text;
		$text = "";
		foreach my $child ( $node->getChildNodes ) {
			push( @{ $mydata->{children} }, node2hash($child) ) if $child->isa('XML::Xerces::DOMElement');
			$text .= $child->getNodeValue() if $child->isa('XML::Xerces::DOMText');
		}

		#Just like =~, except negated. With matching, returns true if it DOESN'T match.
		$mydata->{text} = $text if $text !~ /^\s*$/;
	}
	return $mydata;
}

sub errLog {
	my ($message) = @_;

	open( XMLLOG, '>>xmlErr.log' );
	print XMLLOG "$message\n";
	close(XMLLOG);
}

#==============================================================================
## db MyNodeFilter
#==============================================================================
package MyNodeFilter;
use strict;
use vars qw( @ISA );
@ISA = qw( XML::Xerces::PerlNodeFilter );

sub acceptNode {
	my ( $self, $node ) = @_;
	return $XML::Xerces::DOMNodeFilter::FILTER_ACCEPT;
}

#==============================================================================
## end
#==============================================================================
