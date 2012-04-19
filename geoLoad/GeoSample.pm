#!/usr/bin/perl -w

package GeoSample;

use strict;
use warnings;

my @mytags = ();    #array
my $dbRec  = ();    #hash

my $recId    = 0;
my $tmpId    = 0;
my $recTable = "";
my $recField = "";
my $recValue = "";

my $onId  = 0;
my $nvId  = 0;
my $accId = 0;

my $chanId = 0;
my $labeId = 0;
my $procId = 0;

my $extId = 0;
my $colId = 0;

my $protRec = ();    #save to check for dups

#==============================================================================
## GeoSample
#==============================================================================
sub GeoSample_package {
	my ($hash) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Sample$/ ) {
			$recId = db::dbgetNextseq();
		}

		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				if ( $h1->{node_name} =~ /^Status$/ ) {
					Status_parse($h1);

				} elsif ( $h1->{node_name} =~ /^Title$/ ) {
					$dbRec->{$recId}{PhysicalBioAssay}{id}  = $recId;
					$dbRec->{$recId}{PhysicalBioAssay}{eid} = main::getEid();

					$dbRec->{$recId}{identifiable}{name} = main::trimText( $h1->{text} );

				} elsif ( $h1->{node_name} =~ /^Accession$/ ) {
					Accession_parse($h1);

				} elsif ( $h1->{node_name} =~ /^Type$/ ) {
					$nvId                                            = db::dbgetNextseq();
					$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
					$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
					$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
					$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $h1->{text} );
					$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;

				} elsif ( $h1->{node_name} =~ /^Channel-Count$/ ) {
					$nvId                                            = db::dbgetNextseq();
					$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
					$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
					$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
					$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $h1->{text} );
					$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;

				} elsif ( $h1->{node_name} =~ /^Channel$/ ) {
					Channel_parse($h1);

				} elsif ( $h1->{node_name} =~ /Protocol/ ) {
					if ( !exists( $protRec->{ $h1->{node_name} }{ main::trimText( $h1->{text} ) } ) ) {
						$protRec->{ $h1->{node_name} }{ main::trimText( $h1->{text} ) } = "protocol";

						$procId                           = db::dbgetNextseq();
						$dbRec->{$procId}{Protocol}{id}   = $procId;
						$dbRec->{$procId}{Protocol}{eid}  = main::getEid();
						$dbRec->{$procId}{Protocol}{text} = main::trimText( $h1->{text} );

						$dbRec->{$procId}{identifiable}{id}         = $procId;
						$dbRec->{$procId}{identifiable}{eid}        = main::getEid();
						$dbRec->{$procId}{identifiable}{identifier} = $h1->{node_name};

						$nvId                                            = db::dbgetNextseq();
						$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
						$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
						$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
						$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $h1->{text} );
						$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
					}

				} elsif ( $h1->{node_name} =~ /^Description$/ ) {
					my $descript = main::trimText( $h1->{text} );
					if ( length($descript) < 4000 ) {
						$nvId                                            = db::dbgetNextseq();
						$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
						$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
						$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
						$dbRec->{$nvId}{NameValueType}{value}            = $descript;
						$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
					} else {
						my $desc1 = substr( $descript, 0, 4000 );
						my $desc2 = substr( $descript, 4000 );
						$nvId                                            = db::dbgetNextseq();
						$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
						$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
						$dbRec->{$nvId}{NameValueType}{name}             = "Description_1";
						$dbRec->{$nvId}{NameValueType}{value}            = $desc1;
						$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
						$nvId                                            = db::dbgetNextseq();
						$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
						$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
						$dbRec->{$nvId}{NameValueType}{name}             = "Description_2";
						$dbRec->{$nvId}{NameValueType}{value}            = $desc2;
						$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
					}

				} elsif ( $h1->{node_name} =~ /^Data-Processing$/ ) {
					$nvId                                            = db::dbgetNextseq();
					$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
					$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
					$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
					$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $h1->{text} );
					$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;

				} elsif ( $h1->{node_name} =~ /^Platform-Ref$/ ) {
					PlatformRef_parse($h1);

				} elsif ( $h1->{node_name} =~ /^Contact-Ref$/ ) {
					ContactRef_parse($h1);

				} elsif ( $h1->{node_name} =~ /^Supplementary-Data$/ ) {
					SupplementaryData_parse($h1);

				} elsif ( $h1->{node_name} =~ /^Data-Table$/ ) {
					$extId                                 = db::dbgetNextseq();
					$dbRec->{$extId}{extendable}{id}       = $extId;
					$dbRec->{$extId}{extendable}{eid}      = main::getEid();
					$dbRec->{$extId}{extendable}{label_id} = $recId;
					DataTable_parse($h1);
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

sub Channel_parse {
	my ( $hash, @mytags ) = @_;

	$chanId                         = db::dbgetNextseq();
	$dbRec->{$chanId}{Channel}{id}  = $chanId;
	$dbRec->{$chanId}{Channel}{eid} = main::getEid();

	$dbRec->{$chanId}{identifiable}{id}         = $chanId;
	$dbRec->{$chanId}{identifiable}{eid}        = main::getEid();
	$dbRec->{$chanId}{identifiable}{identifier} = "position";
	$dbRec->{$chanId}{identifiable}{name}       = $hash->{attributes}{position};

	$dbRec->{$chanId}{channels_bioassay}{eid}         = main::getEid();
	$dbRec->{$chanId}{channels_bioassay}{bioassay_id} = $recId;
	$dbRec->{$chanId}{channels_bioassay}{channels_id} = $chanId;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				$nvId                                            = db::dbgetNextseq();
				$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
				$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
				$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
				$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $h1->{text} );
				$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $chanId;

				if ( $h1->{node_name} =~ /Protocol/ ) {
					if ( !exists( $protRec->{ $h1->{node_name} }{ main::trimText( $h1->{text} ) } ) ) {
						$protRec->{ $h1->{node_name} }{ main::trimText( $h1->{text} ) } = "protocol";

						$procId                           = db::dbgetNextseq();
						$dbRec->{$procId}{Protocol}{id}   = $procId;
						$dbRec->{$procId}{Protocol}{eid}  = main::getEid();
						$dbRec->{$procId}{Protocol}{text} = main::trimText( $h1->{text} );

						$dbRec->{$procId}{identifiable}{id}         = $procId;
						$dbRec->{$procId}{identifiable}{eid}        = main::getEid();
						$dbRec->{$procId}{identifiable}{identifier} = $h1->{node_name};
					}
				}
			}
		}
	}
}

sub PlatformRef_parse {
	my ( $hash, @mytags ) = @_;

	my $refname = "";
	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Platform-Ref$/ ) {
			$refname = "Platform-Ref";
		}
		if ( $key =~ /^attributes$/ ) {
			while ( my ( $k2, $v2 ) = each(%$val) ) {
				$recField = $k2;
				$recValue = $v2;

				$nvId                                            = db::dbgetNextseq();
				$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
				$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
				$dbRec->{$nvId}{NameValueType}{name}             = $refname;
				$dbRec->{$nvId}{NameValueType}{value}            = main::trimText($recValue);
				$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
			}
		}
	}
}

sub ContactRef_parse {
	my ( $hash, @mytags ) = @_;

	my $refname = "";
	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Contact-Ref$/ ) {
			$refname = "Contact-Ref";
		}
		if ( $key =~ /^attributes$/ ) {
			while ( my ( $k2, $v2 ) = each(%$val) ) {
				$recField = $k2;
				$recValue = $v2;

				$nvId                                            = db::dbgetNextseq();
				$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
				$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
				$dbRec->{$nvId}{NameValueType}{name}             = $refname;
				$dbRec->{$nvId}{NameValueType}{value}            = main::trimText($recValue);
				$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
			}
		}
	}
}

sub SupplementaryData_parse {
	my ( $hash, @mytags ) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Supplementary-Data$/ ) {
			$nvId                                            = db::dbgetNextseq();
			$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
			$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
			$dbRec->{$nvId}{NameValueType}{name}             = $val;
			$dbRec->{$nvId}{NameValueType}{value}            = "Type:" . $hash->{attributes}{type} . "; " . main::trimText( $hash->{text} );
			$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
		}
	}
}

sub DataTable_parse {
	my ( $hash, @mytags ) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				if ( $h1->{node_name} =~ /^Column$/ ) {
					Column_parse($h1);
				} elsif ( $h1->{node_name} =~ /^External-Data$/ ) {
					ExternalData($h1);
				}
			}
		}
	}
}

sub Column_parse {
	my ( $hash, @mytags ) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Column$/ ) {
			$colId = db::dbgetNextseq();
		}

		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				$nvId                                            = db::dbgetNextseq();
				$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
				$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
				$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
				$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $h1->{text} );
				$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $colId;
			}
		}

		if ( $key =~ /^attributes$/ ) {
			while ( my ( $k2, $v2 ) = each(%$val) ) {
				$recField                                         = $k2;
				$recValue                                         = $v2;
				$dbRec->{$colId}{NameValueType}{id}               = $colId;
				$dbRec->{$colId}{NameValueType}{eid}              = main::getEid();
				$dbRec->{$colId}{NameValueType}{name}             = $recField;
				$dbRec->{$colId}{NameValueType}{value}            = $recValue;
				$dbRec->{$colId}{NameValueType}{namevaluetype_id} = $extId;
			}
		}
	}
}

sub ExternalData {
	my ( $hash, @mytags ) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^External-Data$/ ) {
			my @filename = split( /\//, main::trimText( $hash->{text} ) );
			$nvId                                         = db::dbgetNextseq();
			$dbRec->{$nvId}{NameValueType}{id}            = $nvId;
			$dbRec->{$nvId}{NameValueType}{eid}           = main::getEid();
			$dbRec->{$nvId}{NameValueType}{name}          = $hash->{node_name};
			$dbRec->{$nvId}{NameValueType}{value}         = $filename[-1];
			$dbRec->{$nvId}{NameValueType}{extendable_id} = $extId;
		}

		if ( $key =~ /^attributes$/ ) {
			while ( my ( $k2, $v2 ) = each(%$val) ) {
				$recField = $k2;
				$recValue = $v2;
				if ( $recField =~ /^rows$/ ) {

					#					$dbRec->{$recId}{arraydesign}{numberoffeatures} = $recValue;
				}
			}
		}
	}
}

1;

#==============================================================================
## end
#==============================================================================
