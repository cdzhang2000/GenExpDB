#------------------------------------------------------------------------------------------
# FileName    : download.pl
#
# Description : Download data
# Author      : jgrissom
# DateCreated : 28 Apr 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw(OK DECLINED HTTP_UNAUTHORIZED);

use gdb::oracle;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";

my $r = shift;
my @pairs = split( /&/, $r->args() );    # Get the name and value for each form input

my %frmData;
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

if ($frmData{type} =~ /accessions/) {
	downloaddata( \%frmData );
}
if ($frmData{type} =~ /plotdata/) {
	downloadplotdata( \%frmData );
}

return Apache2::Const::OK;

#--------------------------------------------------------------------
# download data 	from Main
# input: id, hash
# return: none
#----------------------------------------------------------------------
sub downloaddata {
	my ($frmDataRef) = @_;
	my %frmData = %$frmDataRef;

	my ($dbExpmRecRef) = gdb::oracle::dbgetDownloadInfo();
	my %dbExpmRec = %$dbExpmRecRef;

	my ( @acc, @exp, %downloadid );

	@exp = split( /,/, $frmData{ckdlexpm} ) if $frmData{ckdlexpm};
	for my $id (@exp) {
		my ( $accid, $expid ) = split( /:/, $id );
		$downloadid{$accid}{$expid} = 'exp';    #experiments selected
	}

	@acc = split( /,/, $frmData{ckdlaccn} ) if $frmData{ckdlaccn};
	for my $accid (@acc) {
		next if exists $downloadid{$accid};     #we already have this accid from the experiment selection

		for my $i ( sort { $a <=> $b } keys %dbExpmRec ) {
			$downloadid{$accid}{ $dbExpmRec{$i}{id} } = 'acc' if ( $accid =~ /$dbExpmRec{$i}{expid}/ );    #accession selected, get all experiments
		}
	}

	my %accinfo;
	for my $i ( sort { $a <=> $b } keys %dbExpmRec ) {
		my $accid = $dbExpmRec{$i}{expid};
		my $expid = $dbExpmRec{$i}{id};

		if ( exists $downloadid{$accid} ) {
			next if !$downloadid{$accid}{$expid};

			$accinfo{$i}{id}        = $dbExpmRec{$i}{id};
			$accinfo{$i}{expid}     = $dbExpmRec{$i}{expid};
			$accinfo{$i}{accession} = $dbExpmRec{$i}{accession};
			$accinfo{$i}{expname}   = $dbExpmRec{$i}{expname};
			$accinfo{$i}{name}      = $dbExpmRec{$i}{name};
			$accinfo{$i}{std}       = $dbExpmRec{$i}{std};

			$accinfo{$i}{timepoint} = $dbExpmRec{$i}{timepoint};
			$accinfo{$i}{channels}  = $dbExpmRec{$i}{channels};
			$accinfo{$i}{logarithm} = $dbExpmRec{$i}{logarithm};
			$accinfo{$i}{normalize} = $dbExpmRec{$i}{normalize};
			$accinfo{$i}{userma}    = $dbExpmRec{$i}{userma};

			$accinfo{$i}{samples} = $dbExpmRec{$i}{samples};

			my $dbcolumnNameRef = gdb::oracle::dbcolumnName( $dbExpmRec{$i}{samples} );    #get all columns for this sample
			my %dbcolumnName    = %$dbcolumnNameRef;

			my $testcolumn    = ( $dbcolumnName{ $dbExpmRec{$i}{testcolumn} } )    ? $dbcolumnName{ $dbExpmRec{$i}{testcolumn} }    : '';
			my $testbkgd      = ( $dbcolumnName{ $dbExpmRec{$i}{testbkgd} } )      ? $dbcolumnName{ $dbExpmRec{$i}{testbkgd} }      : '';
			my $controlcolumn = ( $dbcolumnName{ $dbExpmRec{$i}{controlcolumn} } ) ? $dbcolumnName{ $dbExpmRec{$i}{controlcolumn} } : '';
			my $cntlbkgd      = ( $dbcolumnName{ $dbExpmRec{$i}{cntlbkgd} } )      ? $dbcolumnName{ $dbExpmRec{$i}{cntlbkgd} }      : '';

			$accinfo{$i}{testcolumn}    = $testcolumn;
			$accinfo{$i}{testbkgd}      = $testbkgd;
			$accinfo{$i}{controlcolumn} = $controlcolumn;
			$accinfo{$i}{cntlbkgd}      = $cntlbkgd;
		}
	}

	my ( %acc, @accOrd, %exp, @exoOrd, %data, $filename );
	my $sacc = 0;
	for my $i ( sort { $a <=> $b } keys %accinfo ) {
		$acc{ $accinfo{$i}{expid} }{accession} = $accinfo{$i}{accession};
		$filename                              = $accinfo{$i}{accession} . '.txt';
		$acc{ $accinfo{$i}{expid} }{name}      = $accinfo{$i}{name};
		$acc{ $accinfo{$i}{expid} }{std}       = $accinfo{$i}{std};

		if ( $sacc != $accinfo{$i}{expid} ) {
			$sacc = $accinfo{$i}{expid};
			push @accOrd, $accinfo{$i}{expid};
		}

		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{ouid}          = $i + 1;                        #start OUID at 1
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{expname}       = $accinfo{$i}{expname};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{std}           = $accinfo{$i}{std};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{samples}       = $accinfo{$i}{samples};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{timepoint}     = $accinfo{$i}{timepoint};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{channels}      = $accinfo{$i}{channels};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{testcolumn}    = $accinfo{$i}{testcolumn};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{testbkgd}      = $accinfo{$i}{testbkgd};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{controlcolumn} = $accinfo{$i}{controlcolumn};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{cntlbkgd}      = $accinfo{$i}{cntlbkgd};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{logarithm}     = $accinfo{$i}{logarithm};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{normalize}     = $accinfo{$i}{normalize};
		$exp{ $accinfo{$i}{expid} }{ $accinfo{$i}{id} }{userma}        = $accinfo{$i}{userma};
		push @exoOrd, "$accinfo{$i}{expid}:$accinfo{$i}{id}";

		my ($dbdlexpDataRef) = gdb::oracle::dbdlexpData( $accinfo{$i}{id} );
		my %dbdlexpData = %$dbdlexpDataRef;

		for my $j ( sort { $a <=> $b } keys %dbdlexpData ) {
			$data{ $accinfo{$i}{expid} }{ $dbdlexpData{$j}{locustag} }{gene} = $dbdlexpData{$j}{gene};
			$data{ $accinfo{$i}{expid} }{ $dbdlexpData{$j}{locustag} }{ $accinfo{$i}{id} }{pavg}   = (defined $dbdlexpData{$j}{pavg}) ? $dbdlexpData{$j}{pavg} : '';
			$data{ $accinfo{$i}{expid} }{ $dbdlexpData{$j}{locustag} }{ $accinfo{$i}{id} }{pratio} = (defined $dbdlexpData{$j}{pratio}) ? $dbdlexpData{$j}{pratio} : '';
		}
	}
	my $accCnt = keys %acc;    #number of accessions selected

	my ( $dlfile, @zipfiles );

	if ( $accCnt == 1 ) {

		#one accession
		$dlfile = '';
		foreach my $expid (@accOrd) {
			$dlfile .= "ACCESSION\t$acc{$expid}{accession}\n";
			$dlfile .= "TITLE\t$acc{$expid}{name}\n\n";
			
			$dlfile .= "EXP\tNAME\tSTDDEV\tSAMPLES\tTIMEPOINT\tCHANNELS\tTEST COL\tTEST BKGD\tCNTL COL\tCNTL BKGD\tLOG\tNORM\tRMA DATA\n";
			foreach my $tmp (@exoOrd) {
				my ( $eid, $id ) = split( /:/, $tmp );
				if ( $eid == $expid ) {
					$dlfile .= "$exp{$expid}{$id}{ouid}\t$exp{$expid}{$id}{expname}\t$exp{$expid}{$id}{std}";
					$dlfile .= "\t$exp{$expid}{$id}{samples}\t$exp{$expid}{$id}{timepoint}\t$exp{$expid}{$id}{channels}\t$exp{$expid}{$id}{testcolumn}";
					$dlfile .= "\t$exp{$expid}{$id}{testbkgd}\t$exp{$expid}{$id}{controlcolumn}\t$exp{$expid}{$id}{cntlbkgd}\t$exp{$expid}{$id}{logarithm}";
					$dlfile .= "\t$exp{$expid}{$id}{normalize}\t$exp{$expid}{$id}{userma}";
					$dlfile .= "\n";
				}
			}

			$dlfile .= "\nLABELS\n";
			$dlfile .= "LOCUSTAG\tLocus_Tag\n";
			$dlfile .= "GENE\tName\n";
			$dlfile .= "EXP_num_M\tRatio of Test/Control\n";
			$dlfile .= "EXP_num_A\tAverage=0.5*(Test+Control)\n";
			$dlfile .= "EXP_num_TestInt\tTest Intensity\n";
			$dlfile .= "EXP_num_CntlInt\tControl Intensity\n\n";
			
			$dlfile .= "LOCUSTAG\tGENE";
			foreach my $tmp (@exoOrd) {
				my ( $eid, $id ) = split( /:/, $tmp );
				if ( $eid == $expid ) {
					$dlfile .= "\tEXP_$exp{$expid}{$id}{ouid}_M\tEXP_$exp{$expid}{$id}{ouid}_A\tEXP_$exp{$expid}{$id}{ouid}_TestInt\tEXP_$exp{$expid}{$id}{ouid}_CntlInt";
				}
			}
			$dlfile .= "\n";

			for my $ltag ( sort keys %{ $data{$expid} } ) {
				$dlfile .= "$ltag\t$data{$expid}{$ltag}{gene}";
				foreach my $tmp (@exoOrd) {
					my ( $eid, $id ) = split( /:/, $tmp );
					if ( $eid == $expid ) {
						my $ratio = ( defined $data{$expid}{$ltag}{$id}{pratio} ) ?  $data{$expid}{$ltag}{$id}{pratio} : '';
						$ratio    = sprintf( "%.3f", $ratio )	if $ratio;
						my $avg = ( defined $data{$expid}{$ltag}{$id}{pavg} ) ?  $data{$expid}{$ltag}{$id}{pavg} : '';
						$avg    = sprintf( "%.3f", $avg )	if $avg;
						my $testint = '';
						my $cntlint = '';
						if ($ratio and $avg) {
							$testint = 2 ** ($avg + ($ratio/2));
							$cntlint = 2 ** ($avg - ($ratio/2));
							$testint    = sprintf( "%.3f", $testint )	if $testint;
							$cntlint    = sprintf( "%.3f", $cntlint )	if $cntlint;
						}
						$dlfile .= "\t$ratio\t$avg\t$testint\t$cntlint";
					}
				}
				$dlfile .= "\n";
			}
		}

		my $size = length $dlfile;

		print "Content-Type:application/force-download\n";
		print "Content-Disposition:attachment;filename=$filename\n";
		print "Content-Transfer-Encoding:binary\n";
		print "Accept-Ranges:bytes\n";
		print "Cache-control:private\n";
		print "Pragma:private\n";
		print "Expires:Mon, 26 Jul 1997 05:00:00 GMT\n";
		print "Content-Length:$size\n";
		print "\n";

		print $dlfile;    # send download file

	} else {
		my $zip = Archive::Zip->new();

		foreach my $expid (@accOrd) {
			$dlfile = '';

			$dlfile .= "ACCESSION\t$acc{$expid}{accession}\n";
			$dlfile .= "TITLE\t$acc{$expid}{name}\n\n";

			$dlfile .= "EXP\tNAME\tSTDDEV\tSAMPLES\tTIMEPOINT\tCHANNELS\tTEST COL\tTEST BKGD\tCNTL COL\tCNTL BKGD\tLOG\tNORM\tRMA DATA\n";
			foreach my $tmp (@exoOrd) {
				my ( $eid, $id ) = split( /:/, $tmp );
				if ( $eid == $expid ) {
					$dlfile .= "$exp{$expid}{$id}{ouid}\t$exp{$expid}{$id}{expname}\t$exp{$expid}{$id}{std}";
					$dlfile .= "\t$exp{$expid}{$id}{samples}\t$exp{$expid}{$id}{timepoint}\t$exp{$expid}{$id}{channels}\t$exp{$expid}{$id}{testcolumn}";
					$dlfile .= "\t$exp{$expid}{$id}{testbkgd}\t$exp{$expid}{$id}{controlcolumn}\t$exp{$expid}{$id}{cntlbkgd}\t$exp{$expid}{$id}{logarithm}";
					$dlfile .= "\t$exp{$expid}{$id}{normalize}\t$exp{$expid}{$id}{userma}";
					$dlfile .= "\n";
				}
			}

			$dlfile .= "\nLABELS\n";
			$dlfile .= "LOCUSTAG\tLocus_Tag\n";
			$dlfile .= "GENE\tName\n";
			$dlfile .= "EXP_num_M\tRatio of Test/Control\n";
			$dlfile .= "EXP_num_A\tAverage=0.5*(Test+Control)\n";
			$dlfile .= "EXP_num_TestInt\tTest Intensity\n";
			$dlfile .= "EXP_num_CntlInt\tControl Intensity\n\n";
			
			$dlfile .= "LOCUSTAG\tGENE";
			foreach my $tmp (@exoOrd) {
				my ( $eid, $id ) = split( /:/, $tmp );
				if ( $eid == $expid ) {
					$dlfile .= "\tEXP_$exp{$expid}{$id}{ouid}_M\tEXP_$exp{$expid}{$id}{ouid}_A\tEXP_$exp{$expid}{$id}{ouid}_TestInt\tEXP_$exp{$expid}{$id}{ouid}_CntlInt";
				}
			}
			$dlfile .= "\n";

			for my $ltag ( sort keys %{ $data{$expid} } ) {
				$dlfile .= "$ltag\t$data{$expid}{$ltag}{gene}";
				foreach my $tmp (@exoOrd) {
					my ( $eid, $id ) = split( /:/, $tmp );
					if ( $eid == $expid ) {
						my $ratio = ( defined $data{$expid}{$ltag}{$id}{pratio} ) ?  $data{$expid}{$ltag}{$id}{pratio} : '';
						$ratio    = sprintf( "%.3f", $ratio )	if $ratio;
						my $avg = ( defined $data{$expid}{$ltag}{$id}{pavg} ) ?  $data{$expid}{$ltag}{$id}{pavg} : '';
						$avg    = sprintf( "%.3f", $avg )	if $avg;
						my $testint = '';
						my $cntlint = '';
						if ($ratio and $avg) {
							$testint = 2 ** ($avg + ($ratio/2));
							$cntlint = 2 ** ($avg - ($ratio/2));
							$testint    = sprintf( "%.3f", $testint )	if $testint;
							$cntlint    = sprintf( "%.3f", $cntlint )	if $cntlint;
						}
						$dlfile .= "\t$ratio\t$avg\t$testint\t$cntlint";
					}
				}
				$dlfile .= "\n";
			}

			my $fname = "$acc{$expid}{accession}.txt";
			my $string_member = $zip->addString( $dlfile, $fname );
			$string_member->desiredCompressionMethod(COMPRESSION_DEFLATED);
		}

		unless ( $zip->writeToFileNamed('/dev/shm/OUGenExpDB.zip') == AZ_OK ) {
			die 'write error';
		}

		my $filesize = -s '/dev/shm/OUGenExpDB.zip';

		print "Content-Type:application/force-download\n";
		print "Content-Disposition:attachment;filename=OUGenExpDB.zip\n";
		print "Content-Transfer-Encoding:binary\n";
		print "Accept-Ranges:bytes\n";
		print "Cache-control:private\n";
		print "Pragma:private\n";
		print "Expires:Mon, 26 Jul 1997 05:00:00 GMT\n";
		print "Content-Length:$filesize\n";
		print "\n";

		open( FILE, "/dev/shm/OUGenExpDB.zip" );
		binmode FILE;
		print while <FILE>;
		close(FILE);
	}
}

#--------------------------------------------------------------------
# download new experiment plot data
# input: id, hash
# return: none
#----------------------------------------------------------------------
sub downloadplotdata {
	my ($frmDataRef) = @_;
	my %frmData = %$frmDataRef;

	my $opened = open( FILE, "/dev/shm/$frmData{fname}" );
	my @data = <FILE>;
	close(FILE);

	my $rec = @data;
	$rec--;    #do not count heading
	
	my $fpath        = "/dev/shm/";
	my $dataFilename = "ndwnload" . int( rand(100000) );
	while ( -e "$fpath$dataFilename" ) {
		$dataFilename = "ndwnload" . int( rand(100000) );
	}

	open( DOUT, ">/dev/shm/$dataFilename" );
	print DOUT "$frmData{samp}\nData Recs: $rec\n";
	
	print DOUT "\nLABELS\n";
	print DOUT "GENE\tName\n";
	print DOUT "LTAG\tLocus_Tag\n";
	print DOUT "Ratio (M)\tTest/Control\n";
	print DOUT "Average (A)\t0.5*(Test+Control)\n";
	print DOUT "Test Int\tTest Intensity\n";
	print DOUT "Cntl Int\tControl Intensity\n";
	print DOUT "\n";
	
	my ( $gene, $ltag, $test, $cntl ) = split( /\t/, $data[0] );
	shift(@data);
	
	$cntl =~ s/\s$//;
	print DOUT "$gene\t$ltag\t$cntl (M)\t$test (A)\tTest Int\tCntl Int\n";

	@data = sort { uc($a) cmp uc($b) } @data;    #sort with case-insensitively
	foreach my $line (@data) {
		chop($line);
		my ( $gene, $ltag, $test, $cntl ) = split( /\t/, $line );
		my $testint = '';
		my $cntlint = '';
		if ($cntl and $test) {
			$testint = 2 ** ($test + ($cntl/2));
			$cntlint = 2 ** ($test - ($cntl/2));
			$testint    = sprintf( "%.3f", $testint )	if $testint;
			$cntlint    = sprintf( "%.3f", $cntlint )	if $cntlint;
		}
		print DOUT "$gene\t$ltag\t$cntl\t$test\t$testint\t$cntlint\n";
	}
	close DOUT;

	my $filesize = -s "/dev/shm/$dataFilename";

	$frmData{samp} =~ s/\s+//g;
	$frmData{samp} =~ s/\,/\_/g;
	$frmData{samp} =~ s/\//\_/g;
	$frmData{samp} =~ s/\(+/\_/g;
	$frmData{samp} =~ s/\)+//g;

	print "Content-Type:application/force-download\n";
	print "Content-Disposition:attachment;filename=$frmData{samp}.txt\n";
	print "Content-Transfer-Encoding:binary\n";
	print "Accept-Ranges:bytes\n";
	print "Cache-control:private\n";
	print "Pragma:private\n";
	print "Expires:Mon, 26 Jul 1997 05:00:00 GMT\n";
	print "Content-Length:$filesize\n";
	print "\n";

	open( FILE, "/dev/shm/$dataFilename" );
	binmode FILE;
	print while <FILE>;
	close(FILE);

}
