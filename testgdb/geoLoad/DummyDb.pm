#!/usr/bin/perl -w

package DummyDb;

use strict;
use warnings;

### use DBI;
### my ( $dbh, $sth, $sql, $row );
### $dbh = DBI->connect( 'dbi:Oracle:oubcf', 'user', 'pass', { PrintError => 1, RaiseError => 1, AutoCommit => 1 } );

#==============================================================================
## db package
#==============================================================================
package db;

# get next sequence number
sub dbgetNextseq {
#	$sql = qq{ select id_seq.nextval from dual };
#	$sth = $dbh->prepare($sql);
#	$sth->execute or die "Cannot get next sequence: " . $DBI::errstr . "\n";
#	my $seqID = $sth->fetchrow_array;
#	$sth->finish;
#	if ($seqID) {
#		return $seqID;
#	}
#	else {
		return -1;
#	}
}

# see if we have this database identifier by eid
sub dbEidIdentexist {
#	my ( $eid, $identifier ) = @_;
#
#	$sql = qq{ select id from Identifiable where eid = ? and identifier = ? };
#	$sth = $dbh->prepare($sql);
#	$sth->bind_param( 1, $eid ) or die $sth->errstr;
#	$sth->bind_param( 2, $identifier ) or die $sth->errstr;
#	$sth->execute or die "Error identifier exist: " . $DBI::errstr . "\n";
#	my $id = $sth->fetchrow_array;
#	$sth->finish;
#	
#	if ($id) {
#		return $id;
#	}
#	else {
		return -1;
#	}
}

# write db record
sub dbWrtrec {
	my ($dbRec) = @_;

	while ( my ( $rn, $val ) = each(%$dbRec) ) {
		while ( my ( $table, $v2 ) = each(%$val) ) {

			my @fields = ();
			my @binds  = ();
			my @data   = ();

			while ( my ( $k3, $v3 ) = each(%$v2) ) {

				push( @fields, $k3 );

				if ( $v3 =~ /^sysdate$/ ) {
					push( @binds, "sysdate" );
				}
				else {
					push( @binds, "?" );
					push( @data,  $v3 );
				}
			}

			my $fields = join( ', ', @fields );
			my $binds  = join( ', ', @binds );
			my $data   = join( ', ', @data );

			#insert rec into db
			
			print "$fields\n";
			print "$binds\n";
			print "$data\n\n";
			
#			$sql = qq{ insert into $table ( $fields ) values ( $binds ) };
#			$sth = $dbh->prepare($sql);
#			$sth->execute(@data) or die "Error insert record: " . $DBI::errstr . "\n";
		}
	}
#	$sth->finish;
}

#----------------------------------------------------------------------
# get Curated addPending
# input: none
# return: hash
#----------------------------------------------------------------------
sub dbgdbCurated {

#	$sql = qq{ select accession from curated where status=2 order by to_number(substr(accession,4)) };
#	$sth = $dbh->prepare($sql);
#	$sth->execute();
#
#	my ($accession);
#	$sth->bind_columns( \$accession );

	my @gse;
#	while ( $row = $sth->fetchrow_arrayref ) {
#		push @gse, $accession;
#	}
#	$sth->finish;

	return ( \@gse );
}

#----------------------------------------------------------------------
# Update Curated 
# input: eid,expid
# return: none
#----------------------------------------------------------------------
sub dbUpdateCurated {
	my ( $eid, $gse ) = @_;

#	$sql = qq{ update curated set eid = ?, status=3, moddate=sysdate, moduser='jgrissom' where accession = ? };
#	$sth = $dbh->prepare($sql);
#	$sth->execute($eid, $gse) or die "Error insert record: " . $DBI::errstr . "\n";
}

#----------------------------------------------------------------------
# Update Curated expid ($recId from GeoSeries)
# input: eid,expid
# return: none
#----------------------------------------------------------------------
sub updCuratedexpid {
	my ( $gse, $recId ) = @_;

#	$sql = qq{ update curated set expid = ? where accession = ? };
#	$sth = $dbh->prepare($sql);
#	$sth->execute( $recId, $gse ) or die "Error insert record: " . $DBI::errstr . "\n";
}


1;

#==============================================================================
## end
#==============================================================================

