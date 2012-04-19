#!/usr/bin/perl
#
# Program Name: getAccessions.pl
#    Usage: getAccessions.pl [GSE_accession | addPending]
#      FTP GSE accession (or all addPending from curated) from GEO
#      create directory in accessions (error if already present)
#      unzip/untar .tgz file

#
#  9 Dec 2010...jeg
# 14 Jan 2011 add addPending...jeg
#==============================================================================

$| = 1;    # dump buffer immediately
use strict;
use warnings FATAL => 'all';

use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";

#
# needed if you use addPending
#
use DBI;
our ( $dbh, $sth, $sql, $row );



#=============================================================================
 my $user="genexpdb";
 my $passwd="vb1g3n3xpdb";
 my $host="genexpdb.ccrlikknzibd.us-east-1.rds.amazonaws.com";
 my $sid="GENEXPDB";
 my $database_name="GENEXPDB";
 my $port="3306";


$dbh = DBI->connect("dbi:Oracle:host=$host;port=3306;sid=$sid", $user, $passwd, {RaiseError => 1}) or die "$DBI::errstr";

## Main
#==============================================================================

my $parm = ( $ARGV[0] ) ? $ARGV[0] : '';

my @gse;

if ( $parm =~ /^addPending$/i ) {
	my $gseRef = dbgdbCurated();
	@gse = @$gseRef;
} elsif ( $parm =~ /^GSE[0-9]+$/i ) {
	push @gse, $parm;
} else {
	print "\n\tUsage: $0 <GSE_accession | addPending>\n
	\tFTP GSE accession (or all addPending from curated) from GEO
	\tcreate directory in accessions (error if already present)
	\tunzip/untar .tgz file\n\n";
	exit(-1);
}

my $cwd    = "/var/www/modperl";      #program lives here

#my $cwd    = ".";      				#program lives here
my $accdir = "$cwd/accessions";    	#accessions directory created here

for my $id (@gse) {
	chdir($accdir) or die "Cannot change to directory $accdir $!";

	if ( -d $id ) {
		print STDERR "\tERROR: directory $id already exist!\n";
		next;
	}

	# wget will create the directory $gse
	#  -nH = -no-host-directories (ftp.ncbi.nih.gov)
	#  --cut-dirs=5 = (pub/geo/DATA/MINiML/$geotype)

	my $cmd = "wget -nH --cut-dirs=5  -r ftp://ftp.ncbi.nih.gov/pub/geo/DATA/MINiML/by_series/$id/";
	system($cmd);

	if ( -d $id ) {
		chdir("./$id") or die "Cannot change to directory ./$id $!";
		system("tar -xvzf GSE*.tgz");
		chdir($cwd) or die "Cannot change to directory $cwd $!";
	} else {

		#directory does not exist, must of had problems?
		print "\n\tERROR: problem ftping $id!\n\n";
	}
}

print STDERR "\nDone\n";
exit(0);

#----------------------------------------------------------------------
# get Curated addPending
# input: none
# return: hash
# download all GSE files which are glagged with addPending= 2
#----------------------------------------------------------------------
sub dbgdbCurated {

	$sql = qq{ select accession from curated where status=2 order by to_number(substr(accession,4)) };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ($accession);
	$sth->bind_columns( \$accession );
	my @gse;
	while ( $row = $sth->fetchrow_arrayref ) {
		push @gse, $accession;
	}
	$sth->finish;

	return ( \@gse );
}
