#!/usr/local/bin/perl -w

package GeoContributor;

use strict;
use warnings;

my @mytags = ();    #array
my $dbRec  = ();    #hash

my $recId    = 0;
my $tmpId    = 0;
my $recTable = "";
my $recField = "";
my $recValue = "";

my $orgId = 0;

#==============================================================================
## GeoContributor
#==============================================================================
sub GeoContributor_package {
	my ($hash) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Contributor$/ ) {
			$recTable = $hash->{children}[0]->{node_name};
			$recId    = db::dbgetNextseq();
			if ( $recTable =~ /^Organization$/ ) {
				$orgId = db::dbgetNextseq();
			}
		}

		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				if ( $h1->{node_name} =~ /^Person$/ ) {
					Person_parse($h1);
				}
				if ( $h1->{node_name} =~ /^Organization$/ && $recTable =~ /^Person$/ ) {
					Add_Organization($h1);
				}
				if ( $h1->{node_name} =~ /^Organization$/ && $recTable =~ /^Organization$/ ) {
					if ( exists( $h1->{text} ) ) {
						Organization_parse($h1);
					}
				}
				if ( $recTable =~ /^Person$/ ) {
					if ( $h1->{node_name} =~ /^Email$/ ) {
						$dbRec->{$recId}{$recTable}{email} = main::trimText( $h1->{text} );
					}
					if ( $h1->{node_name} =~ /^Phone$/ ) {
						$dbRec->{$recId}{$recTable}{phone} = main::trimText( $h1->{text} );
					}
					if ( $h1->{node_name} =~ /^Fax$/ ) {
						$dbRec->{$recId}{$recTable}{fax} = main::trimText( $h1->{text} );
					}
					if ( $h1->{node_name} =~ /^Web-Link$/ ) {
						$dbRec->{$recId}{$recTable}{uri} = main::trimText( $h1->{text} );
					}
					if ( $h1->{node_name} =~ /^Address$/ ) {
						Address_Person_parse($h1);
					}
				}
				if ( $recTable =~ /^Organization$/ ) {
					if ( $h1->{node_name} =~ /^Email$|^Phone$|^Web-Link$/ ) {
						if ( exists( $dbRec->{$orgId}{$recTable}{address} ) ) {
							$dbRec->{$orgId}{$recTable}{address} = $dbRec->{$orgId}{$recTable}{address} . "; " . main::trimText( $h1->{text} );
						} else {
							$dbRec->{$orgId}{$recTable}{address} = main::trimText( $h1->{text} );
						}
					}
					if ( $h1->{node_name} =~ /^Address$/ ) {
						Address_Org_parse($h1);
					}
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
			}
		}
	}

#	print STDOUT Data::Dumper->Dump( [$dbRec], ['dbRec'] );

	db::dbWrtrec($dbRec);
	$dbRec = {};
}

sub Person_parse {
	my ( $hash, @mytags ) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				$dbRec->{$recId}{$recTable}{id}  = $recId;
				$dbRec->{$recId}{$recTable}{eid} = main::getEid();
				if ( $h1->{node_name} =~ /^First$/ ) {
					$dbRec->{$recId}{$recTable}{firstname} = main::trimText( $h1->{text} );
				}
				if ( $h1->{node_name} =~ /^Middle$/ ) {
					$dbRec->{$recId}{$recTable}{midinitials} = main::trimText( $h1->{text} );
				}
				if ( $h1->{node_name} =~ /^Last$/ ) {
					$dbRec->{$recId}{$recTable}{lastname} = main::trimText( $h1->{text} );
				}
			}
		}
	}
}

sub Add_Organization {
	my ( $hash, @mytags ) = @_;

	if ( exists( $hash->{text} ) ) {
		$orgId                              = db::dbgetNextseq();
		$dbRec->{$orgId}{Organization}{id}  = $orgId;
		$dbRec->{$orgId}{Organization}{eid} = main::getEid();

		$dbRec->{$recId}{Person}{affiliation_id} = $orgId;

		$dbRec->{$orgId}{identifiable}{id}         = $orgId;
		$dbRec->{$orgId}{identifiable}{eid}        = main::getEid();
		$dbRec->{$orgId}{identifiable}{identifier} = $hash->{text};
	}
}

sub Organization_parse {
	my ( $hash, @mytags ) = @_;

	$dbRec->{$orgId}{Organization}{id}  = $orgId;
	$dbRec->{$orgId}{Organization}{eid} = main::getEid();

	$dbRec->{$orgId}{Organization}{parent_id} = $recId;

	$dbRec->{$orgId}{identifiable}{id}         = $orgId;
	$dbRec->{$orgId}{identifiable}{eid}        = main::getEid();
	$dbRec->{$orgId}{identifiable}{identifier} = $hash->{text};
}

sub Address_Person_parse {
	my ( $hash, @mytags ) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				if ( exists( $dbRec->{$recId}{$recTable}{address} ) ) {
					$dbRec->{$recId}{$recTable}{address} = $dbRec->{$recId}{$recTable}{address} . "; " . main::trimText( $h1->{text} );
				} else {
					$dbRec->{$recId}{$recTable}{address} = main::trimText( $h1->{text} );
				}
			}    
		}
	}
}

sub Address_Org_parse {
	my ( $hash, @mytags ) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				if ( exists( $dbRec->{$orgId}{$recTable}{address} ) ) {
					$dbRec->{$orgId}{$recTable}{address} = $dbRec->{$orgId}{$recTable}{address} . "; " . main::trimText( $h1->{text} );
				} else {
					$dbRec->{$orgId}{$recTable}{address} = main::trimText( $h1->{text} );
				}
			}    
		}
	}
}

1;

#==============================================================================
## end
#==============================================================================
