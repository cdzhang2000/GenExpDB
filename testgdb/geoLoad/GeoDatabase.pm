#!/usr/bin/perl -w

package GeoDatabase;

use strict;
use warnings;

my @mytags = ();    #array
my $dbRec  = ();    #hash

my $recId    = 0;
my $tmpId    = 0;
my $recTable = "";
my $recField = "";
my $recValue = "";

my $conId = 0;

#==============================================================================
## GeoDatabase
#==============================================================================
sub GeoDatabase_package {
	my ($hash) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Database$/ ) {
			$recId = db::dbgetNextseq();
			$conId = db::dbgetNextseq();
		}

		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				$dbRec->{$recId}{contacts_database}{eid}         = main::getEid();
				$dbRec->{$recId}{contacts_database}{contacts_id} = $conId;
				$dbRec->{$recId}{contacts_database}{database_id} = $recId;

				$dbRec->{$conId}{contact}{id}  = $conId;
				$dbRec->{$conId}{contact}{eid} = main::getEid();

				if ( $h1->{node_name} =~ /^Name$/ ) {    
					$dbRec->{$conId}{contact}{name} = main::trimText( $h1->{text} );
				}
				if ( $h1->{node_name} =~ /^Public-ID$/ ) {
					$dbRec->{$conId}{contact}{category} = "Public-ID";
					$dbRec->{$conId}{contact}{value}    = main::trimText( $h1->{text} );
				}
				if ( $h1->{node_name} =~ /^Organization$/ ) {
					$dbRec->{$conId}{contact}{organization} = main::trimText( $h1->{text} );
				}
				if ( $h1->{node_name} =~ /^Web-Link$/ ) {
					$dbRec->{$conId}{contact}{uri} = main::trimText( $h1->{text} );
				}
				if ( $h1->{node_name} =~ /^Email$/ ) {
					$dbRec->{$conId}{contact}{email} = main::trimText( $h1->{text} );
				}
			}
		}

		if ( $key =~ /^attributes$/ ) {
			while ( my ( $k2, $v2 ) = each(%$val) ) {
				$recField                                  = $k2;
				$recValue                                  = $v2;
				$dbRec->{$recId}{identifiable}{id}         = $recId;
				$dbRec->{$recId}{identifiable}{eid}        = main::getEid();
				$dbRec->{$recId}{identifiable}{identifier} = $recValue;
				$dbRec->{$recId}{identifiable}{name}       = $recField;

				$dbRec->{$recId}{database}{id}  = $recId;
				$dbRec->{$recId}{database}{eid} = main::getEid();

			}
		}
	}

	#	print STDOUT Data::Dumper->Dump( [$dbRec], ['dbRec'] );

	db::dbWrtrec($dbRec);
	$dbRec = {};
}

1;

#==============================================================================
## end
#==============================================================================
