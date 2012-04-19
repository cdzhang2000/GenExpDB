#!/usr/bin/perl -w

package GeoPlatform;

use strict;
use warnings;

my @mytags = ();    #array
my $dbRec  = ();    #hash

my $recId    = 0;
my $tmpId    = 0;
my $recTable = '';
my $recField = '';
my $recValue = '';

my $extId  = 0;
my $colId  = 0;
my $nvId   = 0;
my $accId  = 0;
my $dataId = 0;

#==============================================================================
## GeoPlatform
#==============================================================================
sub GeoPlatform_package {
	my ($hash) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Platform$/ ) {
			$recId = db::dbgetNextseq();
		}

		if ( $key =~ /^children$/ ) {
			foreach my $h1 (@$val) {
				if ( $h1->{node_name} =~ /^Status$/ ) {
					Status_parse($h1);
				} elsif ( $h1->{node_name} =~ /^Accession$/ ) {
					Accession_parse($h1);
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
				} else {
					if ( $h1->{node_name} =~ /^Title$/ ) {
						$dbRec->{$recId}{physicalarraydesign}{id}  = $recId;
						$dbRec->{$recId}{physicalarraydesign}{eid} = main::getEid();

						$dbRec->{$recId}{arraydesign}{id}  = $recId;
						$dbRec->{$recId}{arraydesign}{eid} = main::getEid();

						$dbRec->{$recId}{identifiable}{name} = main::trimText( $h1->{text} );
					} elsif ( $h1->{node_name} =~ /^Description$/ ) {
						my $descID = db::dbgetNextseq();
						$dbRec->{$descID}{Description}{id}             = $descID;
						$dbRec->{$descID}{Description}{eid}            = main::getEid();
						$dbRec->{$descID}{Description}{text}           = main::trimText( $h1->{text} );
						$dbRec->{$descID}{Description}{describable_id} = $recId;
					} else {
						$nvId                                            = db::dbgetNextseq();
						$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
						$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
						$dbRec->{$nvId}{NameValueType}{name}             = $h1->{node_name};
						$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $h1->{text} );
						$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
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
			}
		}
	}

	#	print STDOUT Data::Dumper->Dump( [$dbRec], ['dbRec'] );

	db::dbWrtrec($dbRec);
	$dbRec  = {};
	@mytags = ();
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
				$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $recValue );
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

sub ContactRef_parse {
	my ( $hash, @mytags ) = @_;

	while ( my ( $key, $val ) = each(%$hash) ) {
		if ( $key =~ /^node_name$/ && $val =~ /^Contact-Ref$/ ) {
			$nvId                                            = db::dbgetNextseq();
			$dbRec->{$nvId}{NameValueType}{id}               = $nvId;
			$dbRec->{$nvId}{NameValueType}{eid}              = main::getEid();
			$dbRec->{$nvId}{NameValueType}{name}             = $hash->{node_name};
			$dbRec->{$nvId}{NameValueType}{value}            = main::trimText( $hash->{text} );        
			$dbRec->{$nvId}{NameValueType}{namevaluetype_id} = $recId;
		}

		if ( $key =~ /^attributes$/ ) {
			while ( my ( $k2, $v2 ) = each(%$val) ) {
				$recField                             = $k2;
				$recValue                             = $v2;
				$dbRec->{$nvId}{NameValueType}{value} = $v2;
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
					$dbRec->{$recId}{arraydesign}{numberoffeatures} = $recValue;
				}
			}
		}
	}
}

1;

#==============================================================================
## end
#==============================================================================
