#!/usr/bin/perl -w

package GeoSeries;

use strict;
use warnings;

my @mytags = ();    #array
my $dbRec  = ();    #hash

my $recId    = 0;
my $tmpId    = 0;
my $recTable = "";
my $recField = "";
my $recValue = "";

my $nvId  = 0;
my $accId = 0;

my $descID = 0;
my $bibrID = 0;
my $expdID = 0;
my $onID   = 0;
my $arrId  = 0;

#==============================================================================
## GeoSeries
#==============================================================================
sub GeoSeries_package {
	my ($gse, $hash) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Series$/ ) {
			$recId = db::dbgetNextseq();
		}

		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				if ( $h1->{node_name} =~ /^Status$/ ) {
					Status_parse($h1);

				} elsif ( $h1->{node_name} =~ /^Title$/ ) {
					$dbRec->{$recId}{Experiment}{id}  = $recId;
					$dbRec->{$recId}{Experiment}{eid} = main::getEid();

					$dbRec->{$recId}{identifiable}{name} = main::trimText( $h1->{text} );

				} elsif ( $h1->{node_name} =~ /^Pubmed-ID$/ ) {
					$bibrID                                                = db::dbgetNextseq();
					$dbRec->{$bibrID}{BibliographicReference}{id}          = $bibrID;
					$dbRec->{$bibrID}{BibliographicReference}{eid}         = main::getEid();
					$dbRec->{$bibrID}{BibliographicReference}{publication} = $h1->{node_name};

					$nvId                                            = db::dbgetNextseq();
					$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
					$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
					$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
					$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $h1->{text} );
					$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $bibrID;

				} elsif ( $h1->{node_name} =~ /^Summary$/ ) {
					$descID                                        = db::dbgetNextseq();
					$dbRec->{$descID}{Description}{id}             = $descID;
					$dbRec->{$descID}{Description}{eid}            = main::getEid();
					$dbRec->{$descID}{Description}{text}           = main::trimText( $h1->{text} );
					$dbRec->{$descID}{Description}{describable_id} = $recId;

					if ( exists( $dbRec->{$bibrID}{BibliographicReference} ) ) {
						$dbRec->{$bibrID}{BibliographicReference}{description_id} = $descID;
					}

				} elsif ( $h1->{node_name} =~ /^Overall-Design$/ ) {
					$nvId                                            = db::dbgetNextseq();
					$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
					$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
					$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
					$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $h1->{text} );
					$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;

				} elsif ( $h1->{node_name} =~ /^Type$/ ) {
					$expdID                                            = db::dbgetNextseq();
					$dbRec->{$expdID}{ExperimentDesign}{id}            = $expdID;
					$dbRec->{$expdID}{ExperimentDesign}{eid}           = main::getEid();
					$dbRec->{$expdID}{ExperimentDesign}{experiment_id} = $recId;

					$onID                                    = db::dbgetNextseq();
					$dbRec->{$onID}{OntologyEntry}{id}       = $onID;
					$dbRec->{$onID}{OntologyEntry}{eid}      = main::getEid();
					$dbRec->{$onID}{OntologyEntry}{value}    = main::trimText( $h1->{text} );
					$dbRec->{$onID}{OntologyEntry}{category} = "ExperimentDesignType";

					$dbRec->{$onID}{types_experimentdesign}{eid}                 = main::getEid();
					$dbRec->{$onID}{types_experimentdesign}{types_id}            = $onID;
					$dbRec->{$onID}{types_experimentdesign}{experimentdesign_id} = $expdID;

				} elsif ( $h1->{node_name} =~ /^Contributor-Ref$|^Contact-Ref$/ ) {
					$tmpId = db::dbEidIdentexist( main::getEid(), $h1->{attributes}{ref} );
					$arrId++;
					$dbRec->{$arrId}{providers_experiment}{eid}           = main::getEid();
					$dbRec->{$arrId}{providers_experiment}{providers_id}  = $tmpId;
					$dbRec->{$arrId}{providers_experiment}{experiment_id} = $recId;

				} elsif ( $h1->{node_name} =~ /^Sample-Ref$/ ) {
					$tmpId = db::dbEidIdentexist( main::getEid(), $h1->{attributes}{ref} );
					$arrId++;
					$dbRec->{$arrId}{bioassays_experiment}{eid}           = main::getEid();
					$dbRec->{$arrId}{bioassays_experiment}{bioassays_id}  = $tmpId;
					$dbRec->{$arrId}{bioassays_experiment}{experiment_id} = $recId;
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
			}
		}
	}

	#	print STDOUT Data::Dumper->Dump( [$dbRec], ['dbRec'] );

	db::dbWrtrec($dbRec);
					
	db::updCuratedexpid($gse, $recId);
					
	$dbRec = {};
}

sub Status_parse {
	my ( $hash, @mytags ) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				$nvId                                            = db::dbgetNextseq();
				$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
				$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
				$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
				$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $h1->{text} );
				$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
			}
		}

		if ( $key =~ /^attributes$/ ) {
			while ( my ( $k2, $v2 ) = each(%$val) ) {
				$recField = $k2;
				$recValue = $v2;

				$nvId                                            = db::dbgetNextseq();
				$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
				$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
				$dbRec->{$nvId}{NameValueType}{name}             = $recField;
				$dbRec->{$nvId}{NameValueType}{value}            = main::trimText($recValue);
				$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
			}
		}
	}
}

sub Accession_parse {
	my ( $hash, @mytags ) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Accession$/ ) {
			$accId                                                = db::dbgetNextseq();
			$dbRec->{$accId}{DatabaseEntry}{id}                   = $accId;
			$dbRec->{$accId}{DatabaseEntry}{eid}                  = main::getEid();
			$dbRec->{$accId}{DatabaseEntry}{ $hash->{node_name} } = main::trimText( $hash->{text} );
			$dbRec->{$accId}{DatabaseEntry}{description_id}       = $recId;
		}

		if ( $key =~ /^attributes$/ ) {
			while ( my ( $k2, $v2 ) = each(%$val) ) {
				$recField = $k2;
				$recValue = $v2;
				$tmpId    = db::dbEidIdentexist( main::getEid(), $recValue );

				$dbRec->{$accId}{DatabaseEntry}{database_id} = $tmpId;
			}
		}
	}
}

1;

#==============================================================================
## end
#==============================================================================
