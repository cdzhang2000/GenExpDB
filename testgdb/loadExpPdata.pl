#!/usr/bin/perl
#------------------------------------------------------------------------------------------
# FileName    : loadExpPdata.pl
#
# Description : (re)load experiment data
#				save will copy all of the experiments in the PEXP table to a txt file
#				
#				load will read the saved txt file and reload all of the experiments
#					step 1 - will read experiment info
#					step 2 - create the experiment and data
#					step 3 - delete existing PEXP experiment record and PDATA records
#					step 4 = save experiment to PEXP and data to PDATA
#
# Author      : jgrissom
# DateCreated : 23 Jun 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
$| = 1;    # dump buffer immediately
use strict;
use warnings FATAL => 'all';

use lib qw(/usr/local/apache2/htdocs/modperl);

use Genexpdb::oracle;
use Genexpdb::plot;


use DBI;

use POSIX;
use List::Util qw(sum min max);

use Data::Dumper;    # print Dumper( %frmData );

our $fileLoc = "/usr/local/apache2/htdocs/modperl/Genexpdb";

our ( $dbh, $sth, $sql, $row );
our ( $ousql, $ousth );
$dbh = DBI->connect( 'dbi:Oracle:oubcf', 'gdb', 'gdb_bioweb', { PrintError => 1, RaiseError => 1, AutoCommit => 1 } );

#----------------------------------------------------------------------
# Main
#----------------------------------------------------------------------

my $parm = ( $ARGV[0] ) ? $ARGV[0] : '';

if ( $parm =~ /^save/ ) {
	savepexp();
} elsif ( $parm =~ /^load/ ) {
	loadpexp();
} else {
	print "\n\tUsage: $0  <save>|<load>
	
	save - save PEXP table (Accession experiments parameters) to pexpParms.txt
	load - reload experiments from pexpParms.txt
	\n\n";
	exit(-1);
}

print STDERR "All Done.\n";
exit;

#----------------------------------------------------------------------
# save PEXP table to txt file
# input: none
# return: hash ref
#----------------------------------------------------------------------
sub savepexp {

	$sql = qq{ select id, expname,accession,samples,channels,testcolumn,testbkgd,controlcolumn,cntlbkgd,logarithm,normalize,antilog,userma,plottype,info,timepoint,exporder,platform,testgenome,cntlgenome from pexp order by to_number(substr(accession,4)),exporder,timepoint,samples };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my (
		$id, $expname, $accession, $samples,  $channels, $testcolumn, $testbkgd, $controlcolumn, $cntlbkgd,   $logarithm, $normalize,
		$antilog, $userma,    $plottype, $info,     $timepoint,  $exporder, $platform,      $testgenome, $cntlgenome
	);

	$sth->bind_columns(
		\$id, \$expname, \$accession, \$samples,  \$channels, \$testcolumn, \$testbkgd, \$controlcolumn, \$cntlbkgd,   \$logarithm, \$normalize,
		\$antilog, \$userma,    \$plottype, \$info,     \$timepoint,  \$exporder, \$platform,      \$testgenome, \$cntlgenome
	);

	open( PEXPPARMS, ">$fileLoc/pexpParms.txt" );

	my %accCnts;
	while ( $row = $sth->fetchrow_arrayref ) {
		$id       = ($id)       ? $id       : '';
		$expname       = ($expname)       ? $expname       : '';
		$accession     = ($accession)     ? $accession     : '';
		$samples       = ($samples)       ? $samples       : '';
		$channels      = ($channels)      ? $channels      : '';
		$testcolumn    = ($testcolumn)    ? $testcolumn    : '';
		$testbkgd      = ($testbkgd)      ? $testbkgd      : '';
		$controlcolumn = ($controlcolumn) ? $controlcolumn : '';
		$cntlbkgd      = ($cntlbkgd)      ? $cntlbkgd      : '';
		$logarithm     = ($logarithm)     ? $logarithm     : 0;
		$normalize     = ($normalize)     ? $normalize     : 0;
		$antilog       = ($antilog)       ? $antilog       : 0;
		$userma        = ($userma)        ? $userma        : 0;
		$plottype      = ($plottype)      ? $plottype      : '';
		$info          = ($info)          ? $info          : '';
		$timepoint     = ($timepoint)     ? $timepoint     : '';
		$exporder      = ($exporder)      ? $exporder      : '';
		$platform      = ($platform)      ? $platform      : '';
		$testgenome    = ($testgenome)    ? $testgenome    : '';
		$cntlgenome    = ($cntlgenome)    ? $cntlgenome    : '';

		$accCnts{$accession}++;
		print PEXPPARMS "$id\t$expname\t$accession\t$samples\t$channels\t$testcolumn\t$testbkgd\t$controlcolumn\t$cntlbkgd\t$logarithm\t$normalize\t$antilog\t$userma\t$plottype\t$info\t$timepoint\t$exporder\t$platform\t$testgenome\t$cntlgenome\n";
	}
	close(PEXPPARMS);

	my $accCnt = scalar keys %accCnts;
	my $expCnt = 0;

	open( PEXPINFO, ">$fileLoc/pexpInfo.txt" );
	print PEXPINFO "ACCESSION\tEXP COUNT\n";
	for my $accession ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } keys %accCnts ) {
		$expCnt += $accCnts{$accession};
		print PEXPINFO "$accession\t$accCnts{$accession}\n";
	}

	print PEXPINFO "Accessions: $accCnt\tExperiments: $expCnt\n";
	close(PEXPINFO);

	print STDERR "PEXP table saved to pexpParms.txt\n";
	print STDERR "PEXP info saved to pexpInfo.txt\n";
}

#----------------------------------------------------------------------
# load exp.txt file
# input: none
# return: hash ref
#----------------------------------------------------------------------
sub loadpexp {

	if ( !-e "$fileLoc/pexpParms.txt" ) {
		print "\nFile pexpParms.txt not found!!";
		print "\t\t[run loadExpPdata.pl save  to create pexpParms.txt]\n\n";
		return;
	}

	open( PEXPPARMS, "$fileLoc/pexpParms.txt" );
	my @pexpfile = <PEXPPARMS>;
	close(PEXPPARMS);

	my %exp;
	my $i = 0;
	for my $line (@pexpfile) {
		chomp($line);
		my (
			$id, $expname, $accession, $samples,  $channels, $testcolumn, $testbkgd, $controlcolumn, $cntlbkgd,   $logarithm, $normalize,
			$antilog, $userma,    $plottype, $info,     $timepoint,  $exporder, $platform,      $testgenome, $cntlgenome
		) = split( /\t/, $line );

		$exp{$i}{id}       = ($id)       ? $id       : '';
		$exp{$i}{expname}       = ($expname)       ? $expname       : '';
		$exp{$i}{accession}     = ($accession)     ? $accession     : '';
		$exp{$i}{samples}       = ($samples)       ? $samples       : '';
		$exp{$i}{channels}      = ($channels)      ? $channels      : '';
		$exp{$i}{testcolumn}    = ($testcolumn)    ? $testcolumn    : '';
		$exp{$i}{testbkgd}      = ($testbkgd)      ? $testbkgd      : '';
		$exp{$i}{controlcolumn} = ($controlcolumn) ? $controlcolumn : '';
		$exp{$i}{cntlbkgd}      = ($cntlbkgd)      ? $cntlbkgd      : '';
		$exp{$i}{logarithm}     = ($logarithm)     ? $logarithm     : 0;
		$exp{$i}{normalize}     = ($normalize)     ? $normalize     : 0;
		$exp{$i}{antilog}       = ($antilog)       ? $antilog       : 0;
		$exp{$i}{userma}        = ($userma)        ? $userma        : 0;
		$exp{$i}{plottype}      = ($plottype)      ? $plottype      : '';
		$exp{$i}{info}          = ($info)          ? $info          : '';
		$exp{$i}{timepoint}     = ($timepoint)     ? $timepoint     : '';
		$exp{$i}{exporder}      = ($exporder)      ? $exporder      : '';
		$exp{$i}{platform}      = ($platform)      ? $platform      : '';
		$exp{$i}{testgenome}    = ($testgenome)    ? $testgenome    : '';
		$exp{$i}{cntlgenome}    = ($cntlgenome)    ? $cntlgenome    : '';
		$i++;
	}

	for my $i ( sort { $a <=> $b } keys %exp ) {
		print "$exp{$i}{accession}\t$exp{$i}{expname}...";
		if ( $exp{$i}{channels} == 1 ) {
			c1data( $exp{$i} );
		} elsif ( $exp{$i}{channels} == 2 ) {
			c2data( $exp{$i} );
		}
		print "done.\n";
	}

}

#----------------------------------------------------------------------
# get ids by accession name
# input: accession
# return: id strings
#----------------------------------------------------------------------
sub getExpids {
	my ($accession) = @_;

	$sql = qq{ select a.id, a.eid from identifiable a, experiment b where a.identifier=? and a.id=b.id };
	$sth = $dbh->prepare($sql);
	$sth->execute($accession);

	my ( $id, $eid );
	$sth->bind_columns( \$id, \$eid );

	my %accCnts;
	while ( $row = $sth->fetchrow_arrayref ) {
		$id  = ($id)  ? $id  : '';
		$eid = ($eid) ? $eid : '';
	}

	return ( $id, $eid );
}

#----------------------------------------------------------------------
# load 1-channel experiment
# input: none
# return: hash ref
#----------------------------------------------------------------------
sub c1data {
	my ($expRef) = @_;
	my %exp = %$expRef;

	$exp{id}       = ( $exp{id} )        ? $exp{id}       : '';
	$exp{expname}       = ( $exp{expname} )        ? $exp{expname}       : '';
	$exp{accession}     = ( $exp{accession} )     ? $exp{accession}     : '';
	$exp{samples}       = ( $exp{samples} )       ? $exp{samples}       : '';
	$exp{channels}      = ( $exp{channels} )      ? $exp{channels}      : '';
	$exp{testcolumn}    = ( $exp{testcolumn} )    ? $exp{testcolumn}    : '';
	$exp{testbkgd}      = ( $exp{testbkgd} )      ? $exp{testbkgd}      : '';
	$exp{controlcolumn} = ( $exp{controlcolumn} ) ? $exp{controlcolumn} : '';
	$exp{cntlbkgd}      = ( $exp{cntlbkgd} )      ? $exp{cntlbkgd}      : '';
	$exp{logarithm}     = ( $exp{logarithm} )     ? $exp{logarithm}     : 0;
	$exp{normalize}     = ( $exp{normalize} )     ? $exp{normalize}     : 0;
	$exp{antilog}       = ( $exp{antilog} )       ? $exp{antilog}       : 0;
	$exp{userma}        = ( $exp{userma} )        ? $exp{userma}        : 0;
	$exp{plottype}      = ( $exp{plottype} )      ? $exp{plottype}      : '';
	$exp{info}          = ( $exp{info} )          ? $exp{info}          : '';
	$exp{timepoint}     = ( $exp{timepoint} )     ? $exp{timepoint}     : '';
	$exp{exporder}      = ( $exp{exporder} )      ? $exp{exporder}      : '';
	$exp{platform}      = ( $exp{platform} )      ? $exp{platform}      : '';
	$exp{testgenome}    = ( $exp{testgenome} )    ? $exp{testgenome}    : '';
	$exp{cntlgenome}    = ( $exp{cntlgenome} )    ? $exp{cntlgenome}    : '';
	
	my ( $expid, $eid ) = getExpids( $exp{accession} );

	my $dbsampInfoRef = Genexpdb::oracle::dbsampInfo($expid);
	my %dbsampInfo    = %$dbsampInfoRef;

	my $testgenomeacc = $exp{testgenome};
	my $cntlgenomeacc = $exp{cntlgenome};

	#split samples and put into hash
	my ($testsmp, $cntlsmp) = split( /\//, $exp{samples} );
	
	#split selected test samples and put into hash
	my @testArr = split( /\,/, $testsmp );
	my %testsamp;
	for my $sname (@testArr) {
		$testsamp{$sname} = 1;
	}

	#split selected control samples and put into hash
	my @cntlArr = split( /\,/, $cntlsmp );
	my %cntlsamp;
	for my $sname (@cntlArr) {
		$cntlsamp{$sname} = 1;
	}

	my %testsample = ();
	my %cntlsample = ();
	my %pfcnt      = ();
	my $platform   = '';

	#get test sample info
	for my $id ( sort { $a <=> $b } keys %dbsampInfo ) {
		if ( exists $testsamp{ $dbsampInfo{$id}{samid} } ) {
			$testsample{ $dbsampInfo{$id}{bioassays_id} }{accession} = $dbsampInfo{$id}{accession};
			$testsample{ $dbsampInfo{$id}{bioassays_id} }{sampid}    = $dbsampInfo{$id}{samid};
			$testsample{ $dbsampInfo{$id}{bioassays_id} }{fname}     = $dbsampInfo{$id}{fname};
			$pfcnt{ $dbsampInfo{$id}{gpl} }                          = 1;
			$platform                                                = $dbsampInfo{$id}{gpl};
		}
	}

	#get control sample info
	for my $id ( sort { $a <=> $b } keys %dbsampInfo ) {
		if ( exists $cntlsamp{ $dbsampInfo{$id}{samid} } ) {
			$cntlsample{ $dbsampInfo{$id}{bioassays_id} }{accession} = $dbsampInfo{$id}{accession};
			$cntlsample{ $dbsampInfo{$id}{bioassays_id} }{sampid}    = $dbsampInfo{$id}{samid};
			$cntlsample{ $dbsampInfo{$id}{bioassays_id} }{fname}     = $dbsampInfo{$id}{fname};
			$pfcnt{ $dbsampInfo{$id}{gpl} }                          = 1;
			$platform                                                = $dbsampInfo{$id}{gpl};
		}
	}

	if ( keys(%pfcnt) > 1 ) {
		print qq{<font color="red">Samples have different platforms!</font>};
		return;
	}
	
	my $testGenLtagsRef = Genexpdb::oracle::dbgenomeLtags($testgenomeacc);
	my %testGenomeLtags = %$testGenLtagsRef;

	my $cntlGenLtagsRef = Genexpdb::oracle::dbgenomeLtags($cntlgenomeacc);
	my %cntlGenomeLtags = %$cntlGenLtagsRef;

	my $dbplatformAnnotRef = Genexpdb::oracle::dbplatformAnnot($platform);
	my %dbplatformAnnot    = %$dbplatformAnnotRef;
	if ( !%dbplatformAnnot ) {
		print "No Platform available!  Please contact administrator\n";
		return;
	}

	my $log       = $exp{logarithm};
	my $normalize = $exp{normalize};
	my $antilog   = $exp{antilog};
	my $userma    = $exp{userma};
	my $plottype = $exp{plottype};
	my $datacol  = $exp{controlcolumn};
	$datacol = 1 if $userma;

	my %savExpInfo = ();

	$savExpInfo{expid}     = $expid;
	$savExpInfo{channels}  = 1;
	$savExpInfo{logarithm} = $log;
	$savExpInfo{normalize} = $normalize;
	$savExpInfo{antilog}   = $antilog;
	$savExpInfo{userma}    = $userma;
	$savExpInfo{plottype}  = $plottype;
	$savExpInfo{datacol}   = $datacol;
	$savExpInfo{platform}  = $platform;
	$savExpInfo{testgenome}  = $testgenomeacc;
	$savExpInfo{cntlgenome}  = $cntlgenomeacc;

	my $platformCnt;
	my %pfids = ();
	my %testSource = ();
	my %avgTestArr = ();
	my %cntlSource = ();
	my %avgCntlArr = ();
	my @maxval = ();
	my @testSampname = ();
	my @cntlSampname = ();
	
	for my $bioassays_id ( sort keys %testsample ) {
		
		#get channel source name for each sample
		my $dbchannelSourceRef = Genexpdb::oracle::dbchannelSource($bioassays_id);
		my @dbchannelSource    = @$dbchannelSourceRef;
		$testSource{ $dbchannelSource[0] } = $dbchannelSource[0] if $dbchannelSource[0];

		my $testfile =
		  ($userma)
		  ? "/genexpdb/geo/accessions/$testsample{$bioassays_id}{accession}/$testsample{$bioassays_id}{sampid}.RMA"
		  : "/genexpdb/geo/accessions/$testsample{$bioassays_id}{accession}/$testsample{$bioassays_id}{fname}";
		my $opened = open( FILE, $testfile );
		if ( !$opened ) {
			print qq{<font color="red">Cannot open Test sample file $testsample{$bioassays_id}{sampid} !!</font>};
			return;
		}
		my @data = <FILE>;
		close(FILE);

		$savExpInfo{accession} = $testsample{$bioassays_id}{accession};
		push @testSampname, $testsample{$bioassays_id}{sampid};

		my ( $dataVal, $testVal ) = (undef,undef);
		my (%testdata) = ();

		$platformCnt = 0;

		%pfids = ();
		my %ckltag = ();
		my $i = 1;
		foreach my $line (@data) {
			chop($line);
			my @lineArr = split( /\t/, $line );
			my $id = $lineArr[0];
			$id =~ s/^\s+//;
			$id =~ s/\s+$//;
			$id = lc($id);
			
			my $id_ref = '';
			if (exists $dbplatformAnnot{ $id }) {
				for my $ltag ( keys %{ $dbplatformAnnot{ $id } } ) {
					$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_000913/) and ($ltag =~ /^b/i);		#genome is MG1655 only want B-numbers
					$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_002655/) and ($ltag =~ /^z/i);		#genome is EDL933 only want Z-numbers
					$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_002695/) and ($ltag =~ /^e/i);		#genome is Sakai only want Ecs-numbers
					$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_004431/) and ($ltag =~ /^c/i);		#genome is CFT073 only want c-numbers
					$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_007946/) and ($ltag =~ /^u/i);		#genome is UTI89 only want UTI89-numbers
				}
			}
			next if ! $id_ref;
			$id_ref =~ s/^://;	#remove leading ':'

			$dataVal = ( $datacol and defined $lineArr[$datacol] ) ? $lineArr[$datacol] : '';
			$dataVal =~ s/null|n\/a//gi;
			
			if ($dataVal =~ /e/i) {		#data in scientific notation	(GSE5333)
				$dataVal =~ s/\-/+/;	#change sign
				$dataVal = sprintf("%.3f", $dataVal);
			}
			
			$pfids{$i}{ltag}    = $id_ref;
			$pfids{$i}{dataVal} = $dataVal;
			$i++;
			$platformCnt++;
			
			my @gtags = split(":", $id_ref); #split multiple ltags per id so we can check against genome ltags
			foreach my $gt (@gtags) {
				$ckltag{$gt} = 1;			#ckltag will contain all ltags from the sample	
			}
		}
		if ( ! %pfids ) {
			print qq{<font color="red">Configuration returned no data!</font>\n};
			return;
		}

		my $pcnt = scalar keys %pfids;
		#check ckltag and add all Test genome ltags not in sample
		for my $ltag ( keys %testGenomeLtags ) {
			if ( ! exists $ckltag{$ltag}) {
				$pcnt++;
				$pfids{$pcnt}{ltag} = $ltag;
				$pfids{$pcnt}{dataVal} = '';
			}
		}
		
		#we have all ltags and values
		for my $i ( sort { $a <=> $b } keys %pfids ) {	
			my $id_ref = $pfids{$i}{ltag};	
			
			next if ($id_ref =~ /:/ and $platform =~ /GPL7714/);		#Tiling platform, skip multiple ltags per id_ref
		
			$dataVal = ( $pfids{$i}{dataVal} ) ? $pfids{$i}{dataVal} : '';
			
			if ($antilog) {
				#antilog - convert log 10 to base number, log10(num)=val  antilog== 10^val = num
				$dataVal = ( $dataVal ne '' ) ? pow( 10, $dataVal ) : $dataVal;
			}
			push @maxval, $dataVal if $dataVal ne '';
			
			#average duplicate test spots
			if ( defined $testdata{$id_ref} ) {
				if ( $dataVal ne '' ) {
					$testdata{$id_ref}{cnt}++;
					$testdata{$id_ref}{val} = ( $testdata{$id_ref}{val} ) ? $testdata{$id_ref}{val} + $dataVal : $dataVal;
				}
			} else {
				$testdata{$id_ref}{cnt} = ( $dataVal ne '' ) ? 1 : 0;
				$testdata{$id_ref}{val} = $dataVal;
			}
		}

		my @testcorr = ();
		for my $id_ref ( sort keys %testdata ) {
			$testVal = ( $testdata{$id_ref}{cnt} == 0 ) ? $testdata{$id_ref}{val} : ( $testdata{$id_ref}{val} / $testdata{$id_ref}{cnt} ) if %testdata;
			push @testcorr, $testVal	if ( $testVal ne '' );

			#average test replicates
			if ( defined $avgTestArr{$id_ref} ) {
				if ( $testVal ne '' ) {
					$avgTestArr{$id_ref}{cnt}++;
					$avgTestArr{$id_ref}{val} = ( $avgTestArr{$id_ref}{val} ) ? $avgTestArr{$id_ref}{val} + $testVal : $testVal;
				}
			} else {
				$avgTestArr{$id_ref}{cnt} = ( $testVal ne '' ) ? 1 : 0;
				$avgTestArr{$id_ref}{val} = $testVal;
			}
		}
	}    #end test samples

	for my $bioassays_id ( sort keys %cntlsample ) {

		#get channel source name for each sample
		my $dbchannelSourceRef = Genexpdb::oracle::dbchannelSource($bioassays_id);
		my @dbchannelSource    = @$dbchannelSourceRef;
		$cntlSource{ $dbchannelSource[0] } = $dbchannelSource[0] if $dbchannelSource[0];

		my $cntlfile =
		  ($userma)
		  ? "/genexpdb/geo/accessions/$cntlsample{$bioassays_id}{accession}/$cntlsample{$bioassays_id}{sampid}.RMA"
		  : "/genexpdb/geo/accessions/$cntlsample{$bioassays_id}{accession}/$cntlsample{$bioassays_id}{fname}";
		my $opened = open( FILE, $cntlfile );
		if ( !$opened ) {
			print qq{<font color="red">Cannot open Control sample file $cntlsample{$bioassays_id}{sampid} !!</font>};
			return;
		}
		my @data = <FILE>;
		close(FILE);

		$savExpInfo{accession} = $cntlsample{$bioassays_id}{accession};
		push @cntlSampname, $cntlsample{$bioassays_id}{sampid};

		my $dataVal  = '';
		my $cntlVal  = '';
		my %cntldata = ();
		$platformCnt = 0;
		
		%pfids = ();
		my %ckltag = ();
		my $i = 1;
		foreach my $line (@data) {
			chop($line);
			my @lineArr = split( /\t/, $line );
			my $id = $lineArr[0];
			$id =~ s/^\s+//;
			$id =~ s/\s+$//;
			$id = lc($id);

			my $id_ref = '';
			if (exists $dbplatformAnnot{ $id }) {
				for my $ltag ( keys %{ $dbplatformAnnot{ $id } } ) {
					$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_000913/) and ($ltag =~ /^b/i);		#genome is MG1655 only want B-numbers
					$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_002655/) and ($ltag =~ /^z/i);		#genome is EDL933 only want Z-numbers
					$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_002695/) and ($ltag =~ /^e/i);		#genome is Sakai only want Ecs-numbers
					$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_004431/) and ($ltag =~ /^c/i);		#genome is CFT073 only want c-numbers
					$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_007946/) and ($ltag =~ /^u/i);		#genome is UTI89 only want UTI89-numbers
				}
			}
			next if ! $id_ref;
			$id_ref =~ s/^://;	#remove leading ':'
			
			$dataVal = ( $datacol and defined $lineArr[$datacol] ) ? $lineArr[$datacol] : '';
			$dataVal =~ s/null|n\/a//gi;

			if ($dataVal =~ /e/i) {		#data in scientific notation
				$dataVal =~ s/\-/+/;	#change sign
				$dataVal = sprintf("%.3f", $dataVal);
			}
			
			$pfids{$i}{ltag}    = $id_ref;
			$pfids{$i}{dataVal} = $dataVal;
			$i++;
			$platformCnt++;
			
			my @gtags = split(":", $id_ref); #split multiple ltags per id so we can check against genome ltags
			foreach my $gt (@gtags) {
				$ckltag{$gt} = 1;			#ckltag will contain all ltags from the sample	
			}
		}
		if ( ! %pfids ) {
			print qq{<font color="red">Configuration returned no data!</font>\n};
			return;
		}

		my $pcnt = scalar keys %pfids;
		#check ckltag and add all genome Cntl ltags not in sample
		for my $ltag ( keys %cntlGenomeLtags ) {
			if ( ! exists $ckltag{$ltag}) {
				$pcnt++;
				$pfids{$pcnt}{ltag} = $ltag;
				$pfids{$pcnt}{dataVal} = '';
			}
		}
		
		#we have all ltags and values
		for my $i ( sort { $a <=> $b } keys %pfids ) {	
			my $id_ref = $pfids{$i}{ltag};		
		
			next if ($id_ref =~ /:/ and $platform =~ /GPL7714/);		#Tiling platform, skip multiple ltags per id_ref

			$dataVal = ( $pfids{$i}{dataVal} ) ? $pfids{$i}{dataVal} : '';
		
			if ($antilog) {
				#antilog - convert log 10 to base number, log10(num)=val  antilog== 10^val = num
				$dataVal = ( $dataVal ne '' ) ? pow( 10, $dataVal ) : $dataVal;
			}
			push @maxval, $dataVal if $dataVal ne '';

			#average duplicate test spots
			if ( defined $cntldata{$id_ref} ) {
				if ( $dataVal ne '' ) {
					$cntldata{$id_ref}{cnt}++;
					$cntldata{$id_ref}{val} = ( $cntldata{$id_ref}{val} ) ? $cntldata{$id_ref}{val} + $dataVal : $dataVal;
				}
			} else {
				$cntldata{$id_ref}{cnt} = ( $dataVal ne '' ) ? 1 : 0;
				$cntldata{$id_ref}{val} = $dataVal;
			}
		}

		my @cntlcorr = ();
		for my $id_ref ( sort keys %cntldata ) {
			$cntlVal = ( $cntldata{$id_ref}{cnt} == 0 ) ? $cntldata{$id_ref}{val} : ( $cntldata{$id_ref}{val} / $cntldata{$id_ref}{cnt} ) if %cntldata;
			push @cntlcorr, $cntlVal	if ( $cntlVal ne '' );

			#average test replicates
			if ( defined $avgCntlArr{$id_ref} ) {
				if ( $cntlVal ne '' ) {
					$avgCntlArr{$id_ref}{cnt}++;
					$avgCntlArr{$id_ref}{val} = ( $avgCntlArr{$id_ref}{val} ) ? $avgCntlArr{$id_ref}{val} + $cntlVal : $cntlVal;
				}
			} else {
				$avgCntlArr{$id_ref}{cnt} = ( $cntlVal ne '' ) ? 1 : 0;
				$avgCntlArr{$id_ref}{val} = $cntlVal;
			}
		}
	}    #end control samples

	my $needtoLog = ( max(@maxval) > 24 ) ? 1 : 0;
	if ( !$log and $needtoLog ) {
		print "Data does not seem to be Log values? (maximum value > 24)\n";
	}

	#average samples
	my $A = '';
	my $M = '';
	my %testdataArr = ();
	my %cntldataArr = ();
	for my $id_ref ( sort keys %avgCntlArr ) {
		my $testVal = ( $avgTestArr{$id_ref}{cnt} == 0 ) ? $avgTestArr{$id_ref}{val} : ( $avgTestArr{$id_ref}{val} / $avgTestArr{$id_ref}{cnt} ) if %avgTestArr;
		my $cntlVal = ( $avgCntlArr{$id_ref}{cnt} == 0 ) ? $avgCntlArr{$id_ref}{val} : ( $avgCntlArr{$id_ref}{val} / $avgCntlArr{$id_ref}{cnt} ) if %avgCntlArr;

		if ($log) {
			$testVal = ( $testVal and $testVal > 0 ) ? ( log($testVal) / log(2) ) : '';
			$cntlVal = ( $cntlVal and $cntlVal > 0 ) ? ( log($cntlVal) / log(2) ) : '';
		}

		if ( $plottype !~ /xyplot/ ) {
			if ( $normalize and ( ( $testVal and $testVal <= 0 ) or ( $cntlVal and $cntlVal <= 0 ) ) ) {
				$testVal = '';
				$cntlVal = '';
			}

			$A = ( $testVal and $cntlVal ) ? ( 0.5 * ( $testVal + $cntlVal ) ) : '';    # A(x-axis)

			if ( !$log and $needtoLog ) {
				$testVal = ( $testVal and $testVal > 0 ) ? $testVal                : '';
				$cntlVal = ( $cntlVal and $cntlVal > 0 ) ? $cntlVal                : '';
				$M       = ( $testVal and $cntlVal )     ? ( $testVal / $cntlVal ) : '';    # M(y-axis)
			} else {
				$M = ( $testVal and $cntlVal ) ? ( $testVal - $cntlVal ) : $cntlVal;        # M(y-axis)
			}
			$testVal = $A;
			$cntlVal = $M;
		}

		if ($normalize) {
			$testdataArr{$id_ref} = ( defined $testVal ) ? $testVal : 'NA';
			$cntldataArr{$id_ref} = ( defined $cntlVal ) ? $cntlVal : 'NA';
		} else {
			$testdataArr{$id_ref} = $testVal;
			$cntldataArr{$id_ref} = $cntlVal;
		}
	}

	if ($normalize) {    # run R-loess
		my $loessfilename = loess( $savExpInfo{accession}, \%testdataArr, \%cntldataArr );
		if ( -e $loessfilename ) {
			open( FILE, $loessfilename );
			my @fdata = <FILE>;
			close(FILE);

			%testdataArr = ();
			%cntldataArr = ();
			for my $rec (@fdata) {
				chop($rec);
				$rec =~ s/\"//g;
				my ( undef, $id_ref, $test, undef, $Mnorm ) = split( /\t/, $rec );
				$testdataArr{$id_ref} = ( $test  =~ /NA/ ) ? '' : $test;    #loess returns 'NA'
				$cntldataArr{$id_ref} = ( $Mnorm =~ /NA/ ) ? '' : $Mnorm;
			}
		} else {
			print qq{<font color="red">Problems running normalize!</font>\n};
			return;
		}
	}

	my %plotTestdata = ();
	my %plotCntldata = ();
	my @stddata = ();
	for my $id_ref ( sort keys %cntldataArr ) {

		#save all data
		$plotTestdata{$id_ref} = ( $testdataArr{$id_ref} ne '' ) ? sprintf( "%.3f", $testdataArr{$id_ref} ) : $testdataArr{$id_ref};
		$plotCntldata{$id_ref} = ( $cntldataArr{$id_ref} ne '' ) ? sprintf( "%.3f", $cntldataArr{$id_ref} ) : $cntldataArr{$id_ref};

		push @stddata, $cntldataArr{$id_ref} if ( $cntldataArr{$id_ref} ne '' );    #stddata used for stddev
	}
	my $stddev = sprintf( "%.3f", Genexpdb::plot::stat_stdev( \@stddata ) );
		
	##================================================================================================================================

	if ( ! delExistingExpm($exp{id}) ) {
		# we need to delete the existing Experiment PEXP rec and PDATA recs before we add new ones.
		return 0;		
	}

	#save info to pexp
	$sql = qq{ insert into pexp (id,eid,expname,expid,accession,samples,channels,testcolumn,testbkgd,controlcolumn,cntlbkgd,logarithm,normalize,antilog,userma,plottype,info,timepoint,expstddev,exporder,platform,testgenome,cntlgenome,adddate,adduser) values ( ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,sysdate,? ) };
	$sth = $dbh->prepare($sql);

	my $pexp_id = Genexpdb::oracle::dbgetPdataNextSeq();
	
	if ( !$pexp_id or !$eid ) {
		print "Cannot get experiment IDs.\n";
		return 0;
	}	

	if ( ! $sth->execute( $pexp_id,$eid,$exp{expname},$expid,$savExpInfo{accession},$exp{samples},$exp{channels},$exp{testcolumn},$exp{testbkgd},$exp{controlcolumn},$exp{cntlbkgd},$exp{logarithm},$exp{normalize},$exp{antilog},$exp{userma},$exp{plottype},$exp{info},$exp{timepoint},$stddev,$exp{exporder},$exp{platform},$exp{testgenome},$exp{cntlgenome},'system' ) ) {
		print "Cannot insert experiment data.\n";
		return 0;
	}	
						
	#print qq{$pexp_id,$eid,$exp{expname},$expid,$savExpInfo{accession},$exp{samples},$exp{channels},$exp{testcolumn},$exp{testbkgd},$exp{controlcolumn},$exp{cntlbkgd},$exp{logarithm},$exp{normalize},$exp{antilog},$exp{userma},$exp{plottype},$exp{info},$exp{timepoint},$exp{exporder},$stddev,$exp{platform},$exp{testgenome},$exp{cntlgenome},'system'\n};


	#save data to pdata
	my $sqldata = qq{ insert into pdata (id, eid, pexp_id, pavg, pratio, locustag, multid ) values ( ?, ?, ?, ?, ?, ?, ? ) };
	my $sthdata = $dbh->prepare($sqldata);

	my $geneLocRef = Genexpdb::oracle::dbgetGeneLoc($cntlgenomeacc);	#genome gene and start
	my %geneLoc    = %$geneLocRef;
	
	my $NSgeneLocRef = Genexpdb::oracle::dbgetNSgeneLoc($cntlgenomeacc);
	my %NSgeneLoc    = %$NSgeneLocRef;

	for my $id_ref ( sort keys %plotCntldata ) {
		my @ltags = split( /\:/, $id_ref );	#split locustags
		
		my $parent = 0;
		foreach my $ltag (@ltags) {
			$ltag =~ s/^\s+//;
			$ltag =~ s/\s+$//;

			my $gene = $ltag;
			if ( exists $geneLoc{$ltag} ) {
				$gene = $geneLoc{$ltag}{gene}	if $geneLoc{$ltag}{gene};
			} else {
				if (exists $NSgeneLoc{$ltag}) {
					$gene = $geneLoc{$NSgeneLoc{$ltag}}{gene}	if $geneLoc{$NSgeneLoc{$ltag}}{gene};
				}
			}

			my $pdata_id = Genexpdb::oracle::dbgetPdataNextSeq();
	
			if ( !$pdata_id ) {
				print "Cannot get pData ID.\n";
				return 0;
			}
			if (!$parent) {
				$parent = $pdata_id;	#if we only have 1 ltag then id=multid, if multiple ltags then multid = parentID
			}
			if ( !$sthdata->execute($pdata_id, $eid, $pexp_id, $plotTestdata{$id_ref}, $plotCntldata{$id_ref}, $ltag, $parent ) ) {
				print "Cannot insert data.\n";
				return 0;
			}
		
			#print "$pdata_id\t$eid\t$pexp_id\t$plotTestdata{$id_ref}\t$plotCntldata{$id_ref}\t$ltag\t$parent\n";
			#print "$gene\t$ltag\t$plotTestdata{$id_ref}\t$plotCntldata{$id_ref}\n";
		}

	}
		
}

#----------------------------------------------------------------------
# load 2-channel experiment
# input: none
# return: hash ref
#----------------------------------------------------------------------
sub c2data {
	my ($expRef) = @_;
	my %exp = %$expRef;

	$exp{id}       		= ( $exp{id} )        		? $exp{id}       : '';
	$exp{expname}       = ( $exp{expname} )        ? $exp{expname}       : '';
	$exp{accession}     = ( $exp{accession} )     ? $exp{accession}     : '';
	$exp{samples}       = ( $exp{samples} )       ? $exp{samples}       : '';
	$exp{channels}      = ( $exp{channels} )      ? $exp{channels}      : '';
	$exp{testcolumn}    = ( $exp{testcolumn} )    ? $exp{testcolumn}    : '';
	$exp{testbkgd}      = ( $exp{testbkgd} )      ? $exp{testbkgd}      : '';
	$exp{controlcolumn} = ( $exp{controlcolumn} ) ? $exp{controlcolumn} : '';
	$exp{cntlbkgd}      = ( $exp{cntlbkgd} )      ? $exp{cntlbkgd}      : '';
	$exp{logarithm}     = ( $exp{logarithm} )     ? $exp{logarithm}     : 0;
	$exp{normalize}     = ( $exp{normalize} )     ? $exp{normalize}     : 0;
	$exp{antilog}       = ( $exp{antilog} )       ? $exp{antilog}       : 0;
	$exp{userma}        = ( $exp{userma} )        ? $exp{userma}        : 0;
	$exp{plottype}      = ( $exp{plottype} )      ? $exp{plottype}      : '';
	$exp{info}          = ( $exp{info} )          ? $exp{info}          : '';
	$exp{timepoint}     = ( $exp{timepoint} )     ? $exp{timepoint}     : '';
	$exp{exporder}      = ( $exp{exporder} )      ? $exp{exporder}      : '';
	$exp{platform}      = ( $exp{platform} )      ? $exp{platform}      : '';
	$exp{testgenome}    = ( $exp{testgenome} )    ? $exp{testgenome}    : '';
	$exp{cntlgenome}    = ( $exp{cntlgenome} )    ? $exp{cntlgenome}    : '';
	
	my ( $expid, $eid ) = getExpids( $exp{accession} );

	my $dbsampInfoRef = Genexpdb::oracle::dbsampInfo($expid);
	my %dbsampInfo    = %$dbsampInfoRef;

	my $cntlgenomeacc = $exp{cntlgenome};

	#split selected samples and put into hash
	my @samples = split( /\,/, $exp{samples} );
	my %samp;
	for my $sname (@samples) {
		$samp{$sname} = 1;
	}

	#get sample info
	my ( %sample, %pfcnt ) = ();
	my $platform = '';
	for my $id ( sort { $a <=> $b } keys %dbsampInfo ) {
		if ( exists $samp{ $dbsampInfo{$id}{samid} } ) {
			$sample{ $dbsampInfo{$id}{bioassays_id} }{accession} = $dbsampInfo{$id}{accession};
			$sample{ $dbsampInfo{$id}{bioassays_id} }{sampid}    = $dbsampInfo{$id}{samid};
			$sample{ $dbsampInfo{$id}{bioassays_id} }{fname}     = $dbsampInfo{$id}{fname};
			$pfcnt{ $dbsampInfo{$id}{gpl} }                      = 1;
			$platform                                            = $dbsampInfo{$id}{gpl};
		}
	}
	if ( keys(%pfcnt) > 1 ) {
		print qq{<font color="red">Samples have different platforms!</font>};
		return;
	}
	
	my $genomeLtagsRef = Genexpdb::oracle::dbgenomeLtags($cntlgenomeacc);
	my %genomeLtags = %$genomeLtagsRef;
	
	my $dbplatformAnnotRef = Genexpdb::oracle::dbplatformAnnot($platform);
	my %dbplatformAnnot    = %$dbplatformAnnotRef;
	if ( !%dbplatformAnnot ) {
		print qq{No Platform available!  Please contact administrator.\n};
		return;
	}

	my $log       = $exp{logarithm};
	my $normalize = $exp{normalize};
	my $antilog   = $exp{antilog};
	my $plottype = $exp{plottype};
	my $testcol  = $exp{testcolumn};
	my $testbkgd = $exp{testbkgd};
	my $cntlcol  = $exp{controlcolumn};
	my $cntlbkgd = $exp{cntlbkgd};

	my %savExpInfo = ();

	$savExpInfo{expid}         = $expid;
	$savExpInfo{channels}      = 2;
	$savExpInfo{logarithm}     = $log;
	$savExpInfo{normalize}     = $normalize;
	$savExpInfo{antilog}       = $antilog;
	$savExpInfo{plottype}      = $plottype;
	$savExpInfo{testcolumn}    = $testcol;
	$savExpInfo{testbkgd}      = $testbkgd;
	$savExpInfo{controlcolumn} = $cntlcol;
	$savExpInfo{cntlbkgd}      = $cntlbkgd;
	$savExpInfo{platform}      = $platform;
	$savExpInfo{testgenome}    = '';
	$savExpInfo{cntlgenome}    = $cntlgenomeacc;

	my $platformCnt;
	my %pfids = ();
	my %avgTestArr = ();
	my %avgCntlArr = ();
	my @sampname = ();
	my %chanSource = ();
	my $stddev = '';

	my %plotTestdata = ();
	my %plotCntldata = ();
	for my $bioassays_id ( sort keys %sample ) {

		#get channel source name for each sample
		my $dbchannelSourceRef = Genexpdb::oracle::dbchannelSource($bioassays_id);
		my @dbchannelSource    = @$dbchannelSourceRef;
		$chanSource{1}{ $dbchannelSource[0] } = $dbchannelSource[0] if $dbchannelSource[0];
		
		if ($dbchannelSource[1]) {
			#2-channel running as 2-channel
			$chanSource{2}{ $dbchannelSource[1] } = $dbchannelSource[1];
		}else{
			#1-channel running as 2-channel, use first channel for both
			$chanSource{2}{ $dbchannelSource[0] } = $dbchannelSource[0] if $dbchannelSource[0];
		}

		my ( $testVal, $cntlVal, $testbkgdVal, $cntlbkgdVal ) = undef;
		my ( %testdata, %cntldata, @maxval, @stddata ) = ();
		%plotTestdata = ();
		%plotCntldata = ();

		open( FILE, "/genexpdb/geo/accessions/$sample{$bioassays_id}{accession}/$sample{$bioassays_id}{fname}" );
		my @data = <FILE>;
		close(FILE);

		$savExpInfo{accession} = $sample{$bioassays_id}{accession};
	
		$platformCnt = 0;

		%pfids = ();
		my %ckltag = ();
		my $i = 1;
		foreach my $line (@data) {
			chop($line);
			my @lineArr = split( /\t/, $line );
			my $id = $lineArr[0];
			$id =~ s/^\s+//;
			$id =~ s/\s+$//;
			$id = lc($id);

			my $id_ref = '';
			if (exists $dbplatformAnnot{ $id }) {
				for my $ltag ( keys %{ $dbplatformAnnot{ $id } } ) {
					$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_000913/) and ($ltag =~ /^b/i);		#genome is MG1655 only want B-numbers
					$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_002655/) and ($ltag =~ /^z/i);		#genome is EDL933 only want Z-numbers
					$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_002695/) and ($ltag =~ /^e/i);		#genome is Sakai only want Ecs-numbers
					$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_004431/) and ($ltag =~ /^c/i);		#genome is CFT073 only want c-numbers
					$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_007946/) and ($ltag =~ /^u/i);		#genome is UTI89 only want UTI89-numbers
				}
			}
			next if ! $id_ref;
			$id_ref =~ s/^://;	#remove leading ':'
			
			$testVal = ( $testcol and defined $lineArr[$testcol] ) ? $lineArr[$testcol] : '';
			$cntlVal = ( $cntlcol and defined $lineArr[$cntlcol] ) ? $lineArr[$cntlcol] : '';
			$testVal =~ s/null|n\/a//gi;	#remove null or 'n/a'
			$cntlVal =~ s/null|n\/a//gi;
			
			#background subtraction
			$testbkgdVal = ( $testbkgd and $lineArr[$testbkgd] ) ? $lineArr[$testbkgd] : '';
			$cntlbkgdVal = ( $cntlbkgd and $lineArr[$cntlbkgd] ) ? $lineArr[$cntlbkgd] : '';
			$testbkgdVal =~ s/null|n\/a//gi;
			$cntlbkgdVal =~ s/null|n\/a//gi;
			
			$pfids{$i}{ltag}    = $id_ref;
			$pfids{$i}{testVal} = $testVal;
			$pfids{$i}{cntlVal} = $cntlVal;
			$pfids{$i}{testbkgdVal} = $testbkgdVal;
			$pfids{$i}{cntlbkgdVal} = $cntlbkgdVal;
			$i++;
			$platformCnt++;
			
			my @gtags = split(":", $id_ref); #split multiple ltags per id so we can check against genome ltags
			foreach my $gt (@gtags) {
				$ckltag{$gt} = 1;			#ckltag will contain all ltags from the sample	
			}
		}
		
		if ( ! %pfids ) {
			print qq{Configuration returned no data!\n};
			return;
		}

		my $pcnt = scalar keys %pfids;
		#check ckltag and add all genome ltags not in sample
		for my $ltag ( keys %genomeLtags ) {
			if ( ! exists $ckltag{$ltag}) {
				$pcnt++;
				$pfids{$pcnt}{ltag} = $ltag;
				$pfids{$pcnt}{testVal} = '';
				$pfids{$pcnt}{cntlVal} = '';
				$pfids{$pcnt}{testbkgdVal} = '';
				$pfids{$pcnt}{cntlbkgdVal} = '';
			}
		}
		
		#we have all ltags and values
		for my $i ( sort { $a <=> $b } keys %pfids ) {	
			my $id_ref = $pfids{$i}{ltag};

			next if ($id_ref =~ /:/ and $platform =~ /GPL7714/);		#Tiling platform, skip multiple ltags per id_ref

			$testVal = ( $pfids{$i}{testVal} ) ? $pfids{$i}{testVal} : '';
			$cntlVal = ( $pfids{$i}{cntlVal} ) ? $pfids{$i}{cntlVal} : '';

			if ($antilog) {
				#antilog - convert log 10 to base number, log10(num)=val  antilog== 10^val = num
				$testVal = ( $testVal ne '' ) ? pow( 10, $testVal ) : $testVal;
				$cntlVal = ( $cntlVal ne '' ) ? pow( 10, $cntlVal ) : $cntlVal;
			}

			#background subtraction
			$testbkgdVal = ( $pfids{$i}{testbkgdVal} ) ? $pfids{$i}{testbkgdVal} : '';
			$cntlbkgdVal = ( $pfids{$i}{cntlbkgdVal} ) ? $pfids{$i}{cntlbkgdVal} : '';

			$testVal -= $testbkgdVal if ( $testVal ne '' and $testbkgdVal ne '' );
			$cntlVal -= $cntlbkgdVal if ( $cntlVal ne '' and $cntlbkgdVal ne '' );

			push @maxval, $testVal if $testVal ne '';
			push @maxval, $cntlVal if $cntlVal ne '';

			#average duplicate test spots
			if ( defined $testdata{$id_ref} ) {
				if ( $testVal ne '' ) {
					$testdata{$id_ref}{cnt}++;
					$testdata{$id_ref}{val} = ( $testdata{$id_ref}{val} ) ? $testdata{$id_ref}{val} + $testVal : $testVal;
				}
			} else {
				$testdata{$id_ref}{cnt} = ( $testVal ne '' ) ? 1 : 0;
				$testdata{$id_ref}{val} = $testVal;
			}

			#average duplicate control spots
			if ( defined $cntldata{$id_ref} ) {
				if ( $cntlVal ne '' ) {
					$cntldata{$id_ref}{cnt}++;
					$cntldata{$id_ref}{val} = ( $cntldata{$id_ref}{val} ) ? $cntldata{$id_ref}{val} + $cntlVal : $cntlVal;
				}
			} else {
				$cntldata{$id_ref}{cnt} = ( $cntlVal ne '' ) ? 1 : 0;
				$cntldata{$id_ref}{val} = $cntlVal;
			}
		}
		if ( ! %cntldata ) {
			print qq{Configuration returned no data!\n};
			return;
		}

		my $needtoLog = ( max(@maxval) > 24 ) ? 1 : 0;
		if ( !$log and $needtoLog ) {
			print qq{Data does not seem to be Log values? (maximum value > 24)\n};
			return if ( !$testcol );
		}

		my $A = '';
		my $M = '';
		my %testdataArr = ();
		my %cntldataArr = ();
		for my $id_ref ( sort keys %cntldata ) {

			$testVal = ( $testdata{$id_ref}{cnt} == 0 ) ? $testdata{$id_ref}{val} : ( $testdata{$id_ref}{val} / $testdata{$id_ref}{cnt} ) if %testdata;
			$cntlVal = ( $cntldata{$id_ref}{cnt} == 0 ) ? $cntldata{$id_ref}{val} : ( $cntldata{$id_ref}{val} / $cntldata{$id_ref}{cnt} ) if %cntldata;

			if ($log) {
				$testVal = ( $testVal and $testVal > 0 ) ? ( log($testVal) / log(2) ) : '' if %testdata;
				$cntlVal = ( $cntlVal and $cntlVal > 0 ) ? ( log($cntlVal) / log(2) ) : '' if %cntldata;
			}
			if ( $plottype !~ /xyplot/ ) {
				if ( $normalize and ( ( $testVal and $testVal <= 0 ) or ( $cntlVal and $cntlVal <= 0 ) ) ) {
					$testVal = '';
					$cntlVal = '';
				}

				$A = ( $testVal and $cntlVal ) ? ( 0.5 * ( $testVal + $cntlVal ) ) : '';    # A(x-axis)

				if ( !$log and $needtoLog ) {
					$testVal = ( $testVal and $testVal > 0 ) ? $testVal                : '';
					$cntlVal = ( $cntlVal and $cntlVal > 0 ) ? $cntlVal                : '';
					$M       = ( $testVal and $cntlVal )     ? ( $testVal / $cntlVal ) : '';    # M(y-axis)
				} else {
					$M = ( $testVal and $cntlVal ) ? ( $testVal - $cntlVal ) : $cntlVal;        # M(y-axis)
				}
				$testVal = $A;
				$cntlVal = $M;
			}

			if ($normalize) {
				$testdataArr{$id_ref} = ( defined $testVal ) ? $testVal : 'NA';
				$cntldataArr{$id_ref} = ( defined $cntlVal ) ? $cntlVal : 'NA';
			} else {
				$testdataArr{$id_ref} = $testVal;
				$cntldataArr{$id_ref} = $cntlVal;
			}
		}

		if ($normalize) {    # run R-loess
			my $loessfilename = loess( $sample{$bioassays_id}{accession}, \%testdataArr, \%cntldataArr );
			if ( -e $loessfilename ) {
				open( FILE, $loessfilename );
				my @fdata = <FILE>;
				close(FILE);

				%testdataArr = ();
				%cntldataArr = ();
				for my $rec (@fdata) {
					chop($rec);
					$rec =~ s/\"//g;
					my ( undef, $id_ref, $test, undef, $Mnorm ) = split( /\t/, $rec );
					$testdataArr{$id_ref} = ( $test  =~ /NA/ ) ? '' : $test;    #loess returns 'NA'
					$cntldataArr{$id_ref} = ( $Mnorm =~ /NA/ ) ? '' : $Mnorm;
				}
			} else {
				print qq{<font color="red">Problems running normalize!</font>\n};
				return;
			}
		}

		my $ltagCnt    = 0;
		my $novalueCnt = 0;
		for my $id_ref ( sort keys %cntldataArr ) {

			#1 or more samples have been selected.  We will plot each sample and save values so we can average the final combined plot

			$ltagCnt++ if ( $cntldataArr{$id_ref} ne '' );
			$novalueCnt++ if ( $cntldataArr{$id_ref} eq '' );

			push @stddata, $cntldataArr{$id_ref} if ( $cntldataArr{$id_ref} ne '' );    #stddata used for stddev

			$plotTestdata{$id_ref} = ( $testdataArr{$id_ref} ne '' ) ? sprintf( "%.3f", $testdataArr{$id_ref} ) : $testdataArr{$id_ref};
			$plotCntldata{$id_ref} = ( $cntldataArr{$id_ref} ne '' ) ? sprintf( "%.3f", $cntldataArr{$id_ref} ) : $cntldataArr{$id_ref};

			#average test samples
			if ( defined $avgTestArr{$id_ref} ) {
				if ( $testdataArr{$id_ref} ne '' ) {
					$avgTestArr{$id_ref}{cnt}++;
					$avgTestArr{$id_ref}{val} = ( $avgTestArr{$id_ref}{val} ) ? $avgTestArr{$id_ref}{val} + $testdataArr{$id_ref} : $testdataArr{$id_ref};
				}
			} else {
				$avgTestArr{$id_ref}{cnt} = ( $testdataArr{$id_ref} ne '' ) ? 1 : 0;
				$avgTestArr{$id_ref}{val} = $testdataArr{$id_ref};
			}

			#average control samples
			if ( defined $avgCntlArr{$id_ref} ) {
				if ( $cntldataArr{$id_ref} ne '' ) {
					$avgCntlArr{$id_ref}{cnt}++;
					$avgCntlArr{$id_ref}{val} = ( $avgCntlArr{$id_ref}{val} ) ? $avgCntlArr{$id_ref}{val} + $cntldataArr{$id_ref} : $cntldataArr{$id_ref};
				}
			} else {
				$avgCntlArr{$id_ref}{cnt} = ( $cntldataArr{$id_ref} ne '' ) ? 1 : 0;
				$avgCntlArr{$id_ref}{val} = $cntldataArr{$id_ref};
			}
		}

		$stddev = sprintf( "%.3f", Genexpdb::plot::stat_stdev( \@stddata ) );

	}    #end of all samples



	#average all samples
	if ( ( scalar keys %sample ) > 1 ) {
		my $ltagCnt    = 0;
		my $novalueCnt = 0;
		%plotTestdata = ();
		%plotCntldata = ();
		my @stddata = ();
		for my $id_ref ( sort keys %avgCntlArr ) {
			my $testVal = ( $avgTestArr{$id_ref}{cnt} == 0 ) ? $avgTestArr{$id_ref}{val} : ( $avgTestArr{$id_ref}{val} / $avgTestArr{$id_ref}{cnt} ) if %avgTestArr;
			my $cntlVal = ( $avgCntlArr{$id_ref}{cnt} == 0 ) ? $avgCntlArr{$id_ref}{val} : ( $avgCntlArr{$id_ref}{val} / $avgCntlArr{$id_ref}{cnt} ) if %avgCntlArr;

			$testVal = ( $testVal ne '' ) ? sprintf( "%.3f", $testVal ) : $testVal;
			$cntlVal = ( $cntlVal ne '' ) ? sprintf( "%.3f", $cntlVal ) : $cntlVal;

			$ltagCnt++ if ( $cntlVal ne '' );
			$novalueCnt++ if ( $cntlVal eq '' );

			push @stddata, $cntlVal if ( $cntlVal ne '' );    #stddata used for stddev

			$plotTestdata{$id_ref} = $testVal;
			$plotCntldata{$id_ref} = $cntlVal;
		}

		$stddev = sprintf( "%.3f", Genexpdb::plot::stat_stdev( \@stddata ) );

	} #end average

	
	##================================================================================================================================

	if ( ! delExistingExpm($exp{id}) ) {
		# we need to delete the existing Experiment PEXP rec and PDATA recs before we add new ones.
		return 0;		
	}
	
	#save info to pexp
	$sql = qq{ insert into pexp (id,eid,expname,expid,accession,samples,channels,testcolumn,testbkgd,controlcolumn,cntlbkgd,logarithm,normalize,antilog,userma,plottype,info,timepoint,expstddev,exporder,platform,testgenome,cntlgenome,adddate,adduser) values ( ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,sysdate,? ) };
	$sth = $dbh->prepare($sql);

	my $pexp_id = Genexpdb::oracle::dbgetPdataNextSeq();
	
	if ( !$pexp_id or !$eid ) {
		print "Cannot get experiment IDs.\n";
		return 0;
	}	

	if ( ! $sth->execute( $pexp_id,$eid,$exp{expname},$expid,$savExpInfo{accession},$exp{samples},$exp{channels},$exp{testcolumn},$exp{testbkgd},$exp{controlcolumn},$exp{cntlbkgd},$exp{logarithm},$exp{normalize},$exp{antilog},$exp{userma},$exp{plottype},$exp{info},$exp{timepoint},$stddev,$exp{exporder},$exp{platform},$exp{testgenome},$exp{cntlgenome},'system' ) ) {
		print "Cannot insert experiment data.\n";
		return 0;
	}
	
#	print qq{$pexp_id,$eid,$exp{expname},$expid,$savExpInfo{accession},$exp{samples},$exp{channels},$exp{testcolumn},$exp{testbkgd},$exp{controlcolumn},$exp{cntlbkgd},$exp{logarithm},$exp{normalize},$exp{antilog},$exp{userma},$exp{plottype},$exp{info},$exp{timepoint},$exp{exporder},$stddev,$exp{platform},$exp{testgenome},$exp{cntlgenome},'system'\n};

	#save data to pdata
	my $sqldata = qq{ insert into pdata (id, eid, pexp_id, pavg, pratio, locustag, multid ) values ( ?, ?, ?, ?, ?, ?, ? ) };
	my $sthdata = $dbh->prepare($sqldata);

	my $geneLocRef = Genexpdb::oracle::dbgetGeneLoc($cntlgenomeacc);	#genome gene and start
	my %geneLoc    = %$geneLocRef;
	
	my $NSgeneLocRef = Genexpdb::oracle::dbgetNSgeneLoc($cntlgenomeacc);
	my %NSgeneLoc    = %$NSgeneLocRef;

	for my $id_ref ( sort keys %plotCntldata ) {
		my @ltags = split( /\:/, $id_ref );	#split locustags
		
		my $parent = 0;
		foreach my $ltag (@ltags) {
			$ltag =~ s/^\s+//;
			$ltag =~ s/\s+$//;

			my $gene = $ltag;
			if ( exists $geneLoc{$ltag} ) {
				$gene = $geneLoc{$ltag}{gene}	if $geneLoc{$ltag}{gene};
			} else {
				if (exists $NSgeneLoc{$ltag}) {
					$gene = $geneLoc{$NSgeneLoc{$ltag}}{gene}	if $geneLoc{$NSgeneLoc{$ltag}}{gene};
				}
			}

			my $pdata_id = Genexpdb::oracle::dbgetPdataNextSeq();
	
			if ( !$pdata_id ) {
				print "Cannot get pData ID.\n";
				return 0;
			}
			if (!$parent) {
				$parent = $pdata_id;	#if we only have 1 ltag then id=multid, if multiple ltags then multid = parentID
			}
			if ( !$sthdata->execute($pdata_id, $eid, $pexp_id, $plotTestdata{$id_ref}, $plotCntldata{$id_ref}, $ltag, $parent ) ) {
				print "Cannot insert data.\n";
				return 0;
			}
		
			#print "$pdata_id\t$eid\t$pexp_id\t$plotTestdata{$id_ref}\t$plotCntldata{$id_ref}\t$ltag\t$parent\n";
			#print "$gene\t$ltag\t$plotTestdata{$id_ref}\t$plotCntldata{$id_ref}\n";
		}

	}
	
}

#----------------------------------------------------------------------
# delete existing Experiment PEXP rec and PDATA recs
# input: id
# return: int
#----------------------------------------------------------------------
sub delExistingExpm {
	my ($id) = @_;
	
	
	$sql = qq{ delete from pexp where id=? };
	$sth = $dbh->prepare($sql);
	if ( !$sth->execute($id ) ) {
		print "Problem deleteing existing PEXP record.\n";
		return 0;
	}
	
	my $sqldata = qq{ delete from pdata where pexp_id=? };
	my $sthdata = $dbh->prepare($sqldata);
	if ( !$sthdata->execute($id ) ) {
		print "Problem deleteing existing PDATA records.\n";
		return 0;
	}
	
	return 1;
	
}

#----------------------------------------------------------------------
# loess
# input: $accession, $testdataArrRef, $cntldataArrRef
# return: string filename
#----------------------------------------------------------------------
sub loess {
	my ( $accession, $testdataArrRef, $cntldataArrRef ) = @_;
	my %testdataArr = %$testdataArrRef;
	my %cntldataArr = %$cntldataArrRef;

	my $fileid     = "/dev/shm/loess" . int( rand(100000) );
	my $filedataIn = $fileid . ".in";
	while ( -e $filedataIn ) {
		$fileid     = "/dev/shm/loess" . int( rand(100000) );
		$filedataIn = $fileid . ".in";
	}
	my $fileR       = $fileid . ".R";
	my $filelog     = $fileid . ".log";
	my $filedataOut = $fileid . ".out";

	open( DATAIN, ">$filedataIn" );
	for my $id_ref ( sort keys %cntldataArr ) {
		print DATAIN "$id_ref\t$testdataArr{$id_ref}\t$cntldataArr{$id_ref}\n";
	}
	close DATAIN;

	open( RSCPT, ">$fileR" );
	print RSCPT qq{data <- read.table("$filedataIn", header=FALSE, sep="\t")\n};
	print RSCPT qq{attach(data)\n};
	print RSCPT qq{ltag <- as.character(V1);\n};
	print RSCPT qq{test <- V2;\n};
	print RSCPT qq{cntl <- V3;\n};
	print RSCPT qq{Mnorm <- residuals(loess(cntl~test,span=0.45,na.action=na.exclude,degree=1,family="symmetric",trace.hat="approximate",iterations=2,surface="direct"))\n};
	print RSCPT qq{output <- cbind(ltag, test, cntl, Mnorm);\n};
	print RSCPT qq{write.table(output, file="$filedataOut", sep="\t", col.names=FALSE);\n};
	close RSCPT;

	my $cmd    = "/usr/local/bin/R CMD BATCH --no-save $fileR $filelog";
	my $result = `$cmd 2>&1`;                                              #-- capture STDERR as well as STDOUT

	return $filedataOut;
}

