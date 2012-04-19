#------------------------------------------------------------------------------------------
# FileName    : gdb/oracle.pm
#
# Description : Oracle database
# Author      : jgrissom
# DateCreated : 19 Aug 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package gdb::oracle;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use DBI;
use POSIX;    #floor


my $user="genexpdb";
 my $passwd="vb1g3n3xpdb";
 my $host="genexpdb.ccrlikknzibd.us-east-1.rds.amazonaws.com";
 my $sid="GENEXPDB";
 my $database_name="GENEXPDB";
 my $port="3306";

my ( $dbh, $sth, $sql, $row );

$dbh = DBI->connect("dbi:Oracle:host=$host;port=3306;sid=$sid", $user, $passwd, {RaiseError => 1}) or die "$DBI::errstr";


#----------------------------------------------------------------------
# get curated Accession info by ID
# input: int - accession ID
# return: hash
#----------------------------------------------------------------------
sub dbgetAccName {
	my ($accid) = @_;

	$sql = qq{ select * from curated where expid = ? };
	$sth = $dbh->prepare($sql);
	$sth->execute($accid);

	$row = $sth->fetchrow_hashref();
	$sth->finish;

	return ($row);
}

#----------------------------------------------------------------------
# Display MultiFun selections
# input: none
# return: hash ref
#----------------------------------------------------------------------
sub dbMFunSel {
	my %dbMFunSel;    #hash
	my ( $mid, $pid, $mlevel, $mfunction, @midOrder );

	$sql = qq{ select mid, pid, mlevel, mfunction from sup_mfun_levels order by mid };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	$sth->bind_columns( \$mid, \$pid, \$mlevel, \$mfunction );
	while ( $row = $sth->fetchrow_arrayref ) {
		push @midOrder, $mid;

		$dbMFunSel{top}{$mid}{pid}       = $pid;
		$dbMFunSel{top}{$mid}{mlevel}    = $mlevel;
		$dbMFunSel{top}{$mid}{mfunction} = $mfunction;

		if ( exists $dbMFunSel{sub}{$pid} ) {
			$dbMFunSel{sub}{$pid}++;
		} else {
			$dbMFunSel{sub}{$pid} = 1;
		}
	}
	$sth->finish;

	my ($cnt);

	$sql = qq{ select count(unique bnum) cnt from sup_mfun_bnum where blevel like ? || '%' };
	$sth = $dbh->prepare($sql);

	for my $mid (@midOrder) {
		$sth->execute( $dbMFunSel{top}{$mid}{mlevel} );
		$dbMFunSel{top}{$mid}{cnt} = $sth->fetchrow_array;
	}
	$sth->finish;

	return ( \%dbMFunSel, \@midOrder );
}

#----------------------------------------------------------------------
# query selected multiFun
# input: string mlevels
# return: ref to multiFun ltags
#----------------------------------------------------------------------
sub dbmfunQry {
	my ($selmfun) = @_;

	my @mlevels = split( /~/, $selmfun );

	my ( $mfunDesc, $mfunction, $bnum, $gene, %mfun, %mfunGene, @multiFun );

	#query for the level function
	$sql      = qq{ select mfunction from sup_mfun_levels where mlevel = ?};
	$sth      = $dbh->prepare($sql);
	$mfunDesc = '';
	for my $mlevel (@mlevels) {
		$sth->execute($mlevel);
		$sth->bind_columns( \$mfunction );
		$mfunDesc .= "$mlevel:";
		while ( $row = $sth->fetchrow_arrayref ) {
			$mfunDesc .= "$mfunction";
		}
		$mfunDesc .= ", ";
	}
	$mfunDesc =~ s/, $//;    #remove trailing comma
	$sth->finish;

	#query multifun
	$sql = qq{ select unique substr(bnum,1,5) bnum from sup_mfun_bnum where REGEXP_LIKE(blevel,  '^' || ?) order by bnum};
	$sth = $dbh->prepare($sql);
	for my $mlevel (@mlevels) {
		$sth->execute($mlevel);
		$sth->bind_columns( \$bnum );
		while ( $row = $sth->fetchrow_arrayref ) {
			$mfun{$bnum} = 1;
		}
	}
	$sth->finish;

	#see if we can find a gene name for the multifun bnum
	$sql = qq{ select unique gene from genome where accession='NC_000913' and locus_tag = ?};
	$sth = $dbh->prepare($sql);
	for $bnum ( keys %mfun ) {
		$mfunGene{$bnum} = $bnum;    #use bnum as gene in case we do not find a gene

		$sth->execute($bnum);
		$sth->bind_columns( \$gene );
		while ( $row = $sth->fetchrow_arrayref ) {
			$mfunGene{$bnum} = $gene;
		}
	}
	$sth->finish;

	for my $bnum ( sort keys %mfunGene ) {
		push @multiFun, $mfunGene{$bnum};
	}

	return ( $mfunDesc, \@multiFun );
}

#----------------------------------------------------------------------
# get Pearson Corr
# input: none
# return: ref to pearsonCorr data
#----------------------------------------------------------------------
sub dbpearsonCorr {
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );
	
	my $pcorrgene = $gdb::webUtil::frmData{pcorrgene};
	my $genomeacc = $gdb::util::gnom{$parms->{genome}}{acc};
	
	my @newqry  = gdb::heatmap::ckQryLoc( $pcorrgene, $genomeacc );	#we do this in case we get a number as a query?
	$pcorrgene = $newqry[0];
	
	my ( $geneRef, $ltagRef ) = dbQryGenomeLtags( $pcorrgene, $genomeacc ); #pearson need a locusTag
	my @ltag      = @$ltagRef;
	my $pcorrltag = $ltag[0];
 
	my $acchmRef = gdb::webUtil::getSessVar( 'acchm' );
	my %acchm = ();
	%acchm = %$acchmRef if $acchmRef;

	my @expids;
	for my $accid ( keys %acchm ) {
		next if ( $accid =~ /gene/ );                            #we do not want the queryed gene

		for my $i ( keys %{ $acchm{$accid} } ) {
			push @expids, $acchm{$accid}{$i}{expid};
		}
	}
	my $numExps = @expids;                                       # num of selected experiments
	my $limitNum = floor( ( $numExps * 75 ) / 100 );             #use 75% of the number of experiments selected as the Min number of Experiments cutoff

	#drop table expid_temp;
	#CREATE GLOBAL TEMPORARY TABLE expid_temp (
	#  expid  number
	#) ON COMMIT PRESERVE ROWS;
	#load the experiments selected into temp table
	my $sql = qq{ insert into expid_temp values ( ? ) };
	my $sth = $dbh->prepare($sql);
	foreach my $id (@expids) {
		$sth->execute($id);
	}
	$sth->finish;

	#calulate pearson on the selected ltag(s) and only for the selected experiments
	#when we select all experiments we use (a.id=a.multid) to give us only 1 ratio for multiple ltags 
	$sql = qq{ select unique b.gene, locustag, pcorr, cnt
		from
		(select b.locustag, round(corr(a.pratio, b.pratio),3) pcorr, count(*) cnt
			from 
			(select pexp_id, round(avg(pratio), 3) pratio from pdata a, expid_temp b where locustag in ( select * from THE ( select cast( str2tbl( ? ) as mytableType ) from dual ) ) and a.pexp_id=b.expid  group by pexp_id) a,
			(select pexp_id, locustag, pratio from pdata a, expid_temp b where (a.id=a.multid) and a.pexp_id=b.expid and pratio is not null) b 
				where a.pexp_id=b.pexp_id
				and b.locustag is not null
				group by b.locustag) a, genome b
		where pcorr is not null and cnt > ?
		and a.locustag=b.locus_tag(+)
		order by pcorr desc, locustag     };
	$sth = $dbh->prepare($sql);

	my ( $gene, $locustag, $pcorr, $cnt, %dbPCorrData, @pcorr_order );

	$sth->execute( $pcorrltag, $limitNum );
	$sth->bind_columns( \$gene, \$locustag, \$pcorr, \$cnt );
	while ( $row = $sth->fetchrow_arrayref ) {
		$gene = ($gene) ? $gene : $locustag;
		push @pcorr_order, $gene;    #keep the pcorr order

		$dbPCorrData{$gene}{pcorr} = ( defined $pcorr ) ? $pcorr : '';
		$dbPCorrData{$gene}{cnt}   = ( defined $cnt )   ? $cnt   : '';
	}
	$sth->finish;
	
	return ( \%dbPCorrData, \@pcorr_order );
}

#----------------------------------------------------------------------
# get Accessions info
# input: none
# return: hasfRef
#----------------------------------------------------------------------
sub dbAccessionsInfo {

	#$sql =qq{ select a.id, a.eid, b.identifier, b.name, c.institution, c.pi, c.author, c.pmid, c.title, c.designtype, c.timeseries, c.treatment, c.growthcond, c.modification, c.arraydesign, c.strain, c.substrain from experiment a, identifiable b, curated c where a.id=b.id(+) and (a.id=c.expid and c.status=3) order by to_number(substr(b.identifier,4)) };
	
	#czhang
	$sql =qq{ select a.id, a.eid, b.identifier, b.name, c.institution, c.pi, c.author, c.pmid, c.title, c.designtype, c.timeseries, c.treatment, c.growthcond, c.modification, c.arraydesign, c.strain, c.substrain, c.GEOMATCH organism from experiment a, identifiable b, curated c where a.id=b.id(+) and (a.id=c.expid and c.status=3) order by to_number(substr(b.identifier,4)) };
	
	
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my %dbAccessionRec;
	
	#my ( $id, $eid, $identifier, $name, $institution, $pi, $author, $pmid, $title, $designtype, $timeseries, $treatment, $growthcond, $modification, $arraydesign, $strain, $substrain);

	#czhang
	my ( $id, $eid, $identifier, $name, $institution, $pi, $author, $pmid, $title, $designtype, $timeseries, $treatment, $growthcond, $modification, $arraydesign, $strain, $substrain, $organism );

	my $i = 1;
	
	$sth->bind_columns(
		\$id,         \$eid,        \$identifier, \$name,       \$institution,  \$pi,          \$author, \$pmid, \$title,
		\$designtype, \$timeseries, \$treatment,  \$growthcond, \$modification, \$arraydesign, \$strain, \$substrain, \$organism
	);

	while ( $row = $sth->fetchrow_arrayref ) {
		$dbAccessionRec{$i}{id}           = ($id)           ? $id           : '';
		$dbAccessionRec{$i}{eid}          = ($eid)          ? $eid          : '';
		$dbAccessionRec{$i}{accession}    = ($identifier)   ? $identifier   : '';
		$dbAccessionRec{$i}{name}         = ($name)         ? $name         : '';
		$dbAccessionRec{$i}{institution}  = ($institution)  ? $institution  : '';
		$dbAccessionRec{$i}{pi}           = ($pi)           ? $pi           : '';
		$dbAccessionRec{$i}{author}       = ($author)       ? $author       : '';
		$dbAccessionRec{$i}{pmid}         = ($pmid)         ? $pmid         : '';
		$dbAccessionRec{$i}{title}        = ($title)        ? $title        : '';
		$dbAccessionRec{$i}{designtype}   = ($designtype)   ? $designtype   : '';
		$dbAccessionRec{$i}{timeseries}   = ($timeseries)   ? $timeseries   : '';
		$dbAccessionRec{$i}{treatment}    = ($treatment)    ? $treatment    : '';
		$dbAccessionRec{$i}{growthcond}   = ($growthcond)   ? $growthcond   : '';
		$dbAccessionRec{$i}{modification} = ($modification) ? $modification : '';
		$dbAccessionRec{$i}{arraydesign}  = ($arraydesign)  ? $arraydesign  : '';
		$dbAccessionRec{$i}{strain}       = ($strain)       ? $strain       : '';
		$dbAccessionRec{$i}{substrain}    = ($substrain)    ? $substrain    : '';
		
		#czhang
		$dbAccessionRec{$i}{organism}    = ($organism)    ?  $organism    : '';
		
		$i++;
	}
	$sth->finish;

	return ( \%dbAccessionRec );
}

#----------------------------------------------------------------------
# get Lab Organization
# input: none
# return: hash ref
#----------------------------------------------------------------------
sub dbLabOrganization {

	my %dbLabOrgRec;    #hash

	$sql = qq{ select a.eid, b.identifier from organization a, identifiable b where a.id=b.id };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $eid, $identifier );

	$sth->bind_columns( \$eid, \$identifier );
	while ( $row = $sth->fetchrow_arrayref ) {
		next if ( $identifier =~ /^Affy|^Sigma|^MWG/ );
		$dbLabOrgRec{$eid} = $identifier;
	}
	$sth->finish;

	return \%dbLabOrgRec;
}

#----------------------------------------------------------------------
# get Experiment reference
# input: none
# return: hash ref
#----------------------------------------------------------------------
sub dbExpmReference {

	my %dbExpmRefRec;    #hash

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg

	$sql =
qq{ select a.id,c.publication,d.name,d.value from experiment a, description b, bibliographicreference c, namevaluetype d where a.id=b.describable_id and b.eid=c.eid and c.id=d.namevaluetype_id(+) and c.publication is not null };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $id, $publication, $name, $value );

	$sth->bind_columns( \$id, \$publication, \$name, \$value );
	while ( $row = $sth->fetchrow_arrayref ) {
		next if ( $value =~ /PubMed/ );
		if ( exists $dbExpmRefRec{$id} ) {
			if ( $value !~ /^$dbExpmRefRec{$id}/ ) {
				$dbExpmRefRec{$id} .= ',' . $value;
			}
		} else {
			$dbExpmRefRec{$id} = $value;
		}
	}
	$sth->finish;

	return \%dbExpmRefRec;
}

#----------------------------------------------------------------------
# get Experiment design
# input: none
# return: hash ref
#----------------------------------------------------------------------
sub dbExpmDesign {

	my %dbExpmDesignRec;    #hash

	$sql = qq{ select a.experiment_id ,c.value from experimentdesign a, types_experimentdesign b, ontologyentry c where a.id=b.experimentdesign_id and b.types_id=c.id };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $experiment_id, $value );

	$sth->bind_columns( \$experiment_id, \$value );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbExpmDesignRec{$experiment_id} = $value;
	}
	$sth->finish;

	return \%dbExpmDesignRec;
}

#----------------------------------------------------------------------
# get Experiment platform design
# input: none
# return: hash ref
#----------------------------------------------------------------------
sub dbPlatformDesign {

	my %dbPlatformDesignRec;    #hash

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg

	$sql = qq{ select a.eid, b.value, c.identifier, c.name from physicalarraydesign a, namevaluetype b, identifiable c where a.id=b.namevaluetype_id(+) and b.name='Manufacturer' and a.id=c.id };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $eid, $value, $identifier, $name );

	$sth->bind_columns( \$eid, \$value, \$identifier, \$name );
	while ( $row = $sth->fetchrow_arrayref ) {

		my $ad = ($value) ? $value : $name;
		$dbPlatformDesignRec{$eid}{ad} = $ad;

		if ( exists $dbPlatformDesignRec{$eid}{gpl} ) {
			$dbPlatformDesignRec{$eid}{gpl} .= ',' . $identifier;
		} else {
			$dbPlatformDesignRec{$eid}{gpl} = $identifier;
		}
	}
	$sth->finish;

	return \%dbPlatformDesignRec;
}

#----------------------------------------------------------------------
# Accession experiments by genome
# input: accessionID
# return: array ref
#----------------------------------------------------------------------
sub dbexpcntbyAcc {
	my ($accnid) = @_;

	$sql = qq{ select b.cntlgenome from curated a, pexp b where (a.expid = ? and a.status=3) and a.expid=b.expid };
	$sth = $dbh->prepare($sql);
	$sth->execute($accnid);

	my ($cntlgenome, @expGenome);

	$sth->bind_columns( \$cntlgenome );
	while ( $row = $sth->fetchrow_arrayref ) {
		push @expGenome, $cntlgenome;
	}

	return ( \@expGenome );
}

### Accession Information
#----------------------------------------------------------------------
# Accession Providers and Organization
# input: string ID
# return: array ref
#----------------------------------------------------------------------
sub dbexpProviders {
	my ($id) = @_;

	#organization
	$sql = qq{ select unique c.identifier org from experiment a, organization b, identifiable c where a.id = ? and a.eid = b.eid and b.id = c.id };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ( $org, @orgArr );
	$sth->bind_columns( \$org );
	while ( $row = $sth->fetchrow_arrayref ) {
		push @orgArr, $org;
	}
	$sth->finish;
	my $organization = join( ', ', @orgArr );

	#providers
	$sql =
qq{ select unique b.lastname, substr(b.firstname,0,1) || substr(b.midinitials,0,1) firstinitial from providers_experiment a, person b where a.experiment_id = ? and a.providers_id=b.id order by b.lastname };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ( $lastname, $firstinitial, @provArr );
	$sth->bind_columns( \$lastname, \$firstinitial );
	while ( $row = $sth->fetchrow_arrayref ) {
		push @provArr, $lastname . ' ' . $firstinitial;
	}
	$sth->finish;
	my $providers = join( ', ', @provArr );

	my %dbexpProviders;
	$dbexpProviders{organization} = ($organization) ? $organization : '';
	$dbexpProviders{providers}    = ($providers)    ? $providers    : '';

	return ( \%dbexpProviders );
}

#----------------------------------------------------------------------
# Accession Summary, protocol
# input: string ID
# return: array ref
#----------------------------------------------------------------------
sub dbexpSummary {
	my ($id) = @_;

	my %dbexpSummary;

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg

	#summary-description
	$sql = qq{ select text from description where describable_id = ? };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ($text);
	$sth->bind_columns( \$text );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbexpSummary{0}{summary} = $text;
	}
	$sth->finish;

	#property set
	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg
	
	$sql = qq{ select name, value from namevaluetype where namevaluetype_id = ? order by id };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ( $name, $value );
	my $i = 1;
	$sth->bind_columns( \$name, \$value );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbexpSummary{ $i++ }{$name} = ($value) ? $value : '';
	}
	$sth->finish;

	#protocol
	$sql = qq{ select b.text, c.identifier from experiment a, protocol b, identifiable c where a.id = ? and a.eid = b.eid and b.id = c.id order by b.id };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ($identifier);
	$sth->bind_columns( \$text, \$identifier );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbexpSummary{ $i++ }{$identifier} = ($text) ? $text : '';
	}
	$sth->finish;

	return ( \%dbexpSummary );
}

#----------------------------------------------------------------------
# Accession Experiment Design
# input: string ID
# return: array ref
#----------------------------------------------------------------------
sub dbexpDesign {
	my ($id) = @_;

	$sql = qq{ select c.value from experimentdesign a, types_experimentdesign b, ontologyentry c where a.experiment_id = ? and a.id=b.experimentdesign_id and b.types_id=c.id  };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ( $value, %dbexpDesign );
	$sth->bind_columns( \$value );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbexpDesign{Contributor_Desc} = ($value) ? $value : '';
	}
	$sth->finish;
	$dbexpDesign{Contributor_Desc} = ( $dbexpDesign{Contributor_Desc} ) ? $dbexpDesign{Contributor_Desc} : '';    #if exp has no recs from this query

	#curated table
	$sql = qq{ select d.designtype, d.timeseries, d.treatment, d.growthcond, d.modification from curated d where d.expid = ? };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ( $designtype, $timeseries, $treatment, $growthcond, $modification );
	$sth->bind_columns( \$designtype, \$timeseries, \$treatment, \$growthcond, \$modification );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbexpDesign{Type}                  = ($designtype)   ? $designtype   : '';
		$dbexpDesign{Time_Series}           = ($timeseries)   ? $timeseries   : '';
		$dbexpDesign{Treatment}             = ($treatment)    ? $treatment    : '';
		$dbexpDesign{Growth_Conditions}     = ($growthcond)   ? $growthcond   : '';
		$dbexpDesign{Genetic_Modifications} = ($modification) ? $modification : '';
	}
	$sth->finish;

	return ( \%dbexpDesign );
}

#----------------------------------------------------------------------
# Accession Physical Array Design
# input: string ID
# return: array ref
#----------------------------------------------------------------------
sub dbarrayDesign {
	my ($id) = @_;

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg

	$sql =
qq{ select b.numberoffeatures, c.identifier, c.name, e.text, f.name vname, f.value from experiment a, arraydesign b, identifiable c, physicalarraydesign d, description e, namevaluetype f where a.id = ? and a.eid=b.eid and b.id=c.id and b.id=d.id and d.id= e.describable_id(+) and b.id=f.namevaluetype_id order by c.identifier };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ( $numberoffeatures, $identifier, $name, $text, $vname, $value, %dbarrayDesign );
	$sth->bind_columns( \$numberoffeatures, \$identifier, \$name, \$text, \$vname, \$value );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbarrayDesign{$identifier}{platform}     = ($name)             ? $name             : '';
		$dbarrayDesign{$identifier}{desc}         = ($text)             ? $text             : '';
		$dbarrayDesign{$identifier}{numf}         = ($numberoffeatures) ? $numberoffeatures : '';
		$dbarrayDesign{$identifier}{parm}{$vname} = ($value)            ? $value            : '';
	}
	$sth->finish;

	return ( \%dbarrayDesign );
}

#----------------------------------------------------------------------
# Accession Experiment Samples
# input: string ID
# return: hash ref
#----------------------------------------------------------------------
sub dbsampInfo {
	my ($id) = @_;

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg

	my %dbsampInfo;
	my $i = 0;
	#my $vals = $dbh->selectall_arrayref( q{ select a.bioassays_id, b.identifier accession, c.identifier samid, c.name samname, e.value fname, f.value gpl from bioassays_experiment a, identifiable b, identifiable c, extendable d, namevaluetype e, namevaluetype f where a.experiment_id = ? and a.experiment_id= b.id and a.bioassays_id=c.id and a.bioassays_id = d.label_id(+) and d.id=e.extendable_id(+) and (a.bioassays_id= f.namevaluetype_id and lower(f.name)='platform-ref') order by c.identifier }, undef, $id );
	my $vals = $dbh->selectall_arrayref( q{ select a.bioassays_id, b.identifier accession, c.identifier samid, c.name samname, e.value fname, f.value gpl from bioassays_experiment a, identifiable b, identifiable c, extendable d, namevaluetype e, namevaluetype f where a.experiment_id = ? and a.experiment_id= b.id and a.bioassays_id=c.id and a.bioassays_id = d.label_id(+) and d.id=e.extendable_id(+) and (a.bioassays_id= f.namevaluetype_id and lower(f.name)='platform-ref') order by samname }, undef, $id );
	
	foreach my $val (@$vals) {
		my ($bioassays_id, $accession, $samid, $samname, $fname, $gpl) = @$val;
		$dbsampInfo{$i}{bioassays_id} = ($bioassays_id) ? $bioassays_id : '';
		$dbsampInfo{$i}{accession}    = ($accession)    ? $accession    : '';
		$dbsampInfo{$i}{samid}        = ($samid)        ? $samid        : '';
		$dbsampInfo{$i}{samname}      = ($samname)      ? $samname      : '';
		$dbsampInfo{$i}{fname}        = ($fname)        ? $fname        : '';
		$dbsampInfo{$i}{gpl}          = ($gpl)          ? $gpl          : '';
		$i++;
	}
	return ( \%dbsampInfo );	
}

#----------------------------------------------------------------------
# Experiment Samples Details
# input: string ID
# return: array ref
#----------------------------------------------------------------------
sub dbsampDetail {
	my ($id) = @_;

	$sql =
qq{ select b.name channel, c.name, c.value, d.identifier sampIDname from channels_bioassay a, identifiable b, namevaluetype c, identifiable d where a.bioassay_id = ? and a.channels_id= b.id(+) and a.channels_id= c.namevaluetype_id and a.bioassay_id=d.id order by a.channels_id };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ( $channel, $name, $value, $sampIDname, %dbsampDetail );
	$sth->bind_columns( \$channel, \$name, \$value, \$sampIDname );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbsampDetail{Channel}{$channel} = $channel;
		$dbsampDetail{$name}{$channel} = ($value) ? $value : '';
	}
	$sth->finish;

	return ( $sampIDname, \%dbsampDetail );
}

#----------------------------------------------------------------------
# Experiment Samples Description
# input: string ID
# return: array ref
#----------------------------------------------------------------------
sub dbsampDescription {
	my ($id) = @_;

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg
	
	$sql = qq{ select a.name, a.value from namevaluetype a where a.namevaluetype_id = ? };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ( $name, $value, %dbsampDescription );
	$sth->bind_columns( \$name, \$value );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbsampDescription{$name} = ($value) ? $value : '';
	}
	$sth->finish;

	return ( \%dbsampDescription );
}

#----------------------------------------------------------------------
# Get Sample File Columns Names/Descriptions
# input: string bioassays_id
# return: array ref
#----------------------------------------------------------------------
sub dbsampFilehead {
	my ($id) = @_;

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg

	$sql = qq{ select a.value pos, lower(b.name) name, b.value from namevaluetype a,namevaluetype b, datasets c where a.namevaluetype_id = (select id from extendable where label_id = ? ) and a.id=b.namevaluetype_id(+) and a.eid=c.eid };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);

	my ( $pos, $name, $value, %label );
	$sth->bind_columns( \$pos, \$name, \$value );
	while ( $row = $sth->fetchrow_arrayref ) {
		$label{$pos}{$name} = ($value) ? $value : '';
	}
	$sth->finish;

	return ( \%label );
}

#----------------------------------------------------------------------
# get experiment ID info
# input: none
# return: hasfRef
#----------------------------------------------------------------------
sub dbgetExpmInfo {
	
	$sth = $dbh->prepare(q{ select a.id from pexp a, curated b  where a.expid=b.expid and b.status=3 order by to_number(substr(a.accession,4)), a.exporder, a.timepoint, a.samples });
	$sth->execute();

	my ( $id, %dbExpmRec, @expmorder );
	my $i = 0;
	$sth->bind_columns( \$id );
	while ( $row = $sth->fetchrow_arrayref ) {
		push( @expmorder, $id );
		$dbExpmRec{$id}{flag} = 0;
		$dbExpmRec{$id}{ouid} = ++$i;
	}

	return ( \%dbExpmRec, \@expmorder );
}

#----------------------------------------------------------------------
# Accession Experiment Information
# input: string ID
# return: array ref
#----------------------------------------------------------------------
sub dbexpInfo {
	my ($expid) = @_;

	$sql =
qq{ select id, expname, samples, timepoint, channels, testcolumn, testbkgd, controlcolumn, cntlbkgd, logarithm, normalize, antilog, userma, expstddev, exporder, platform, testgenome, cntlgenome, adduser, moduser,to_char(adddate, 'mm/dd/yy HH:MIam') as adate, to_char(moddate, 'mm/dd/yy HH:MIam') as mdate from pexp where expid = ? order by exporder, timepoint, samples };
	$sth = $dbh->prepare($sql);
	$sth->execute($expid);

	my $i = 0;
	my (
		$id,        $expname, $samples,   $timepoint, $channels, $testcolumn, $testbkgd, $controlcolumn, $cntlbkgd, $logarithm,
		$normalize, $antilog, $userma,  $expstddev, $exporder,  $platform, $testgenome, $cntlgenome, $adduser,    $moduser,  $adate,         $mdate,    %dbexpInfo
	);
	$sth->bind_columns(
		\$id,        \$expname, \$samples,   \$timepoint, \$channels, \$testcolumn, \$testbkgd, \$controlcolumn, \$cntlbkgd, \$logarithm,
		\$normalize, \$antilog, \$userma,  \$expstddev, \$exporder,  \$platform, \$testgenome, \$cntlgenome, \$adduser,    \$moduser,  \$adate,         \$mdate
	);
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbexpInfo{$i}{id}            = ($id);
		$dbexpInfo{$i}{expname}       = ($expname) ? $expname : '';
		$dbexpInfo{$i}{samples}       = ($samples) ? $samples : '';
		$dbexpInfo{$i}{timepoint}     = ($timepoint) ? $timepoint : '';
		$dbexpInfo{$i}{channels}      = ($channels) ? $channels : '';
		$dbexpInfo{$i}{testcolumn}    = ($testcolumn) ? $testcolumn : '';
		$dbexpInfo{$i}{testbkgd}      = ($testbkgd) ? $testbkgd : '';
		$dbexpInfo{$i}{controlcolumn} = ($controlcolumn) ? $controlcolumn : '';
		$dbexpInfo{$i}{cntlbkgd}      = ($cntlbkgd) ? $cntlbkgd : '';
		$dbexpInfo{$i}{logarithm}     = ($logarithm) ? 'Yes' : '';
		$dbexpInfo{$i}{normalize}     = ($normalize) ? 'Yes' : '';
		$dbexpInfo{$i}{antilog}       = ($antilog) ? 'Yes' : '';
		$dbexpInfo{$i}{userma}        = ($userma) ? "Yes" : '';
		$dbexpInfo{$i}{expstddev}     = ($expstddev) ? sprintf( "%05.3f", $expstddev ) : '';
		$dbexpInfo{$i}{exporder}      = ($exporder) ? $exporder : '';
		$dbexpInfo{$i}{platform}      = ($platform) ? $platform : '';
		$dbexpInfo{$i}{testgenome}      = ($testgenome) ? $testgenome : '';
		$dbexpInfo{$i}{cntlgenome}      = ($cntlgenome) ? $cntlgenome : '';
		$dbexpInfo{$i}{adduser}       = ($adduser) ? $adduser : '';
		$dbexpInfo{$i}{moduser}       = ($moduser) ? $moduser : '';
		$dbexpInfo{$i}{adate}         = ($adate) ? $adate : '';
		$dbexpInfo{$i}{mdate}         = ($mdate) ? $mdate : '';
		$i++;
	}
	$sth->finish;

	return ( \%dbexpInfo );
}

#----------------------------------------------------------------------
# Return Sample column label by sample name
# input: string SampleID, column
# return: string label
#----------------------------------------------------------------------
sub dbcolumnName {
	my ($sample) = @_;

	my @sampArr = split( /\,|\//, $sample );    #we may have one or more sample, but we only need the first one to look up the column name

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg

	$sql =
qq{ select c.value pos, d.value name from identifiable a, extendable b, namevaluetype c, namevaluetype d where a.identifier = ? and a.id = b.label_id and b.id = c.namevaluetype_id and c.id = d.namevaluetype_id and d.name = 'Name' };
	$sth = $dbh->prepare($sql);
	$sth->execute( $sampArr[0] );

	my ( $pos, $name, %dbcolumnName );
	$sth->bind_columns( \$pos, \$name );
	while ( $row = $sth->fetchrow_arrayref ) {
		my $sampPos = $pos;                 #column number entered when experiment created started with 1(instead of 0)
		--$sampPos;
		$dbcolumnName{$sampPos} = ($name) ? $name : '';
	}
	$sth->finish;

	return ( \%dbcolumnName );
}

#----------------------------------------------------------------------
# Download Experiment Data by expID
# input: expID
# return: array ref
#----------------------------------------------------------------------
sub dbdlexpData {
	my ($pexp_id) = @_;

	my $nsGeneLtagRef = dbgetGeneLtags();
	my %nsGeneLtag = %$nsGeneLtagRef;

	$sql = qq{ select pavg, pratio, locustag from pdata where pexp_id=? order by locustag};
	$sth = $dbh->prepare($sql);
	$sth->execute($pexp_id);

	my ( $pavg, $pratio, $locustag, %dbdlexpData );
	my $i = 0;

	$sth->bind_columns( \$pavg, \$pratio, \$locustag );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbdlexpData{$i}{locustag} = $locustag;
		
		if (exists $nsGeneLtag{$locustag}) {
			$dbdlexpData{$i}{gene} = $nsGeneLtag{$locustag};
		}else{
			$dbdlexpData{$i}{gene} = $locustag;
		}
		
		$dbdlexpData{$i}{pavg}   = (defined $pavg) ? $pavg : '';
		$dbdlexpData{$i}{pratio} = (defined $pratio) ? $pratio : '';
		$i++;
	}
	$sth->finish;
	
	return ( \%dbdlexpData );
}

#----------------------------------------------------------------------
# Update Experiment Information
# input: array
# return: int
#----------------------------------------------------------------------
sub dbupdateExpInfo {
	my ($allchgRef) = @_;
	my @allchg = @$allchgRef;

	my $status = 0;
	foreach my $sql (@allchg) {
		$sth = $dbh->prepare($sql);
		if ( !$sth->execute() ) {
			$status = 1;
		}
	}
	return $status;
}

#----------------------------------------------------------------------
# Curated Information
# input: string ID
# return: array ref
#----------------------------------------------------------------------
sub dbcuratedInfo {
	my ($id) = @_;

	$sql = qq{ select b.name dbtitle, a.expid,a.accession,a.status,a.institution,a.pi,a.author,a.pmid,a.title,a.designtype,a.timeseries,
				a.treatment,a.growthcond,a.modification,a.arraydesign,a.strain,a.substrain,a.info,a.adduser,a.moduser,
				to_char(a.adddate, 'mm/dd/yy HH:MIam') as adate, to_char(a.moddate, 'mm/dd/yy HH:MIam') as mdate 
				from curated a, identifiable b
				where a.expid = ? and a.expid=b.id };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);
	my %curatedInfo;
	my (
		$dbtitle,   $expid,      $accession,    $status,      $institution, $pi,        $author, $pmid,    $title,   $designtype, $timeseries,
		$treatment, $growthcond, $modification, $arraydesign, $strain,      $substrain, $info,   $adduser, $moduser, $adate,      $mdate
	);
	$sth->bind_columns(
		\$dbtitle,   \$expid,      \$accession,    \$status,      \$institution, \$pi,        \$author, \$pmid,    \$title,   \$designtype, \$timeseries,
		\$treatment, \$growthcond, \$modification, \$arraydesign, \$strain,      \$substrain, \$info,   \$adduser, \$moduser, \$adate,      \$mdate
	);

	while ( $row = $sth->fetchrow_arrayref ) {
		$curatedInfo{dbtitle}      = ($dbtitle)      ? $dbtitle      : '';
		$curatedInfo{expid}        = ($expid)        ? $expid        : '';
		$curatedInfo{accession}    = ($accession)    ? $accession    : '';
		$curatedInfo{status}       = ($status)       ? $status       : '';
		$curatedInfo{institution}  = ($institution)  ? $institution  : '';
		$curatedInfo{pi}           = ($pi)           ? $pi           : '';
		$curatedInfo{author}       = ($author)       ? $author       : '';
		$curatedInfo{pmid}         = ($pmid)         ? $pmid         : '';
		$curatedInfo{title}        = ($title)        ? $title        : '';
		$curatedInfo{designtype}   = ($designtype)   ? $designtype   : '';
		$curatedInfo{timeseries}   = ($timeseries)   ? $timeseries   : '';
		$curatedInfo{treatment}    = ($treatment)    ? $treatment    : '';
		$curatedInfo{growthcond}   = ($growthcond)   ? $growthcond   : '';
		$curatedInfo{modification} = ($modification) ? $modification : '';
		$curatedInfo{arraydesign}  = ($arraydesign)  ? $arraydesign  : '';
		$curatedInfo{strain}       = ($strain)       ? $strain       : '';
		$curatedInfo{substrain}    = ($substrain)    ? $substrain    : '';
		$curatedInfo{info}         = ($info)         ? $info         : '';
		$curatedInfo{adduser}      = ($adduser)      ? $adduser      : '';
		$curatedInfo{moduser}      = ($moduser)      ? $moduser      : '';
		$curatedInfo{adate}        = ($adate)        ? $adate        : '';
		$curatedInfo{mdate}        = ($mdate)        ? $mdate        : '';
	}
	$sth->finish;

	return ( \%curatedInfo );
}

#----------------------------------------------------------------------
# Update Curated Information
# input: string ID
# return: int
#----------------------------------------------------------------------
sub dbupdatecuratedInfo {
	my ($sql) = @_;

	$sth = $dbh->prepare($sql);
	if ( $sth->execute() ) {
		return 0;
	} else {
		return 1;
	}
}

#----------------------------------------------------------------------
# Sample channel counts
# input: none
# return: hash
#----------------------------------------------------------------------
sub dbchannelCounts {

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg

	$sql = qq{ select value, namevaluetype_id from namevaluetype where name='Channel-Count' };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $value, $namevaluetype_id, %dbchannelCounts );
	$sth->bind_columns( \$value, \$namevaluetype_id );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbchannelCounts{$namevaluetype_id} = ($value) ? $value : '';
	}
	$sth->finish;

	return ( \%dbchannelCounts );
}

#----------------------------------------------------------------------
# Return All Sample column pos/name by experimentID
# input: int experimentID
# return: hash
#----------------------------------------------------------------------
sub dbcolumnPosName {
	my ($experimentID) = @_;

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg
	
	$sql =
qq{ select b.id bioassay_id, d.value pos, e.value cname from bioassays_experiment a, identifiable b, extendable c, namevaluetype d, namevaluetype e where a.experiment_id=? and b.id = c.label_id and c.id = d.namevaluetype_id and d.id = e.namevaluetype_id and e.name = 'Name' and b.id=a.bioassays_id };
	$sth = $dbh->prepare($sql);
	$sth->execute($experimentID);

	my ( $bioassay_id, $pos, $cname, %dbcolumnPosName );
	$sth->bind_columns( \$bioassay_id, \$pos, \$cname );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbcolumnPosName{$bioassay_id}{$pos} = ($cname) ? $cname : '';
	}
	$sth->finish;

	return ( \%dbcolumnPosName );
}

#----------------------------------------------------------------------
# Platform annotation by platformID(GPL)
# input: string ID
# return: hash ref
#----------------------------------------------------------------------
sub dbplatformAnnot {
	my ($platformID) = @_;

	my %dbplatformAnnot;
	my $vals = $dbh->selectall_arrayref( q{ select id_ref,locustag from platformannot where platform=? }, undef, $platformID );
	foreach my $val (@$vals) {
		my ($id_ref, $locustag) = @$val;
		$dbplatformAnnot{ lc($id_ref) } = $locustag;
	}
	return ( \%dbplatformAnnot );
}

#----------------------------------------------------------------------
# Platform annotation by platformID(GPL)
# input: string ID
# return: hash ref
#----------------------------------------------------------------------
sub xxx_dbplatformAnnot {
	my ($platformID) = @_;

	my %dbplatformAnnot;
	my $vals = $dbh->selectall_arrayref( q{ select id_ref,locustag from platformannot where platform=? }, undef, $platformID );
	foreach my $val (@$vals) {
		my ($id_ref, $locustag) = @$val;
		$dbplatformAnnot{ lc($id_ref) }{$locustag}++;
	}
	return ( \%dbplatformAnnot );
}

#----------------------------------------------------------------------
# Genome locusTags by accession
# input: string ID
# return: hash ref
#----------------------------------------------------------------------
sub dbgenomeLtags {
	my ($genomeacc) = @_;

	my %genomeLtags;
	my $vals = $dbh->selectall_arrayref( q{ select unique locus_tag from genome where accession=? and locus_tag is not null }, undef, $genomeacc );
	foreach my $val (@$vals) {
		my ($locus_tag) = @$val;
		$genomeLtags{ lc($locus_tag) } = 1;
	}
	return ( \%genomeLtags );
}

#----------------------------------------------------------------------
# get channel source
# input: string ID
# return: hash ref
#----------------------------------------------------------------------
sub dbchannelSource {
	my ($id) = @_;

	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg
	
	my @dbchannelSource;
	my $vals = $dbh->selectall_arrayref( q{ select b.value from channels_bioassay a, namevaluetype b where a.bioassay_id = ? and a.channels_id = b.namevaluetype_id and name = 'Source' order by b.id }, undef, $id );
	foreach my $val (@$vals) {
		my ($value) = @$val;
		push @dbchannelSource, $value;
	}
	return ( \@dbchannelSource );	
}

#----------------------------------------------------------------------
# get experiment plot info
# input: none
# return: hasfRef
#----------------------------------------------------------------------
sub dbgetExpmPlotInfo {

	$sql =
qq{ select a.id, a.expid, a.accession, a.expname, a.expstddev, a.platform, b.name, c.title from pexp a, identifiable b, curated c where a.expid=b.id and a.expid= c.expid order by to_number(substr(a.accession,4)), a.exporder, a.timepoint, a.samples }
	  ;
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my %dbExpmRec;    #hash
	my ( $id, $expid, $accession, $expname, $expstddev, $platform, $name, $title );

	my $i = 1;
	$sth->bind_columns( \$id, \$expid, \$accession, \$expname, \$expstddev, \$platform, \$name, \$title );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbExpmRec{$i}{id}        = ($id)        ? $id        : '';
		$dbExpmRec{$i}{expid}     = ($expid)     ? $expid     : '';
		$dbExpmRec{$i}{accession} = ($accession) ? $accession : '';
		$dbExpmRec{$i}{expname}   = ($expname)   ? $expname   : '';
		$dbExpmRec{$i}{name}      = ($title)     ? $title     : $name;
		$dbExpmRec{$i}{std} = ($expstddev) ? sprintf( "%05.3f", $expstddev ) : '';
		$dbExpmRec{$i}{platform} = ($platform) ? $platform : '';
		$i++;
	}
	$sth->finish;

	return ( \%dbExpmRec );
}

#----------------------------------------------------------------------
# get experiment scatter Plot data
# input: experiment ID
# return: ref to plot data
#----------------------------------------------------------------------
sub dbgetSPlotData {
	my ($pexp_id) = @_;

	my $nsGeneLtagRef = dbgetGeneLtags();
	my %nsGeneLtag = %$nsGeneLtagRef;

	#skip both null ratio and no locustag.
	$sql = qq{ select pratio, locustag from pdata where pexp_id=? and pratio is not null };
	$sth = $dbh->prepare($sql);

	my ( $pratio, $locustag, $value, %dbPlotData );

	$sth->execute($pexp_id);

	$sth->bind_columns( \$pratio, \$locustag );
	while ( $row = $sth->fetchrow_arrayref ) {

		if (exists $nsGeneLtag{$locustag}) {
			$dbPlotData{$locustag}{gene} = $nsGeneLtag{$locustag};
		}else{
			$dbPlotData{$locustag}{gene} = $locustag;
		}
		
		$dbPlotData{$locustag}{ratio} = ( defined $pratio ) ? $pratio : '';
	}
	$sth->finish;

	return \%dbPlotData;
}

#----------------------------------------------------------------------
# get ALL genes and locustags from ns_data 
# input: none
# return: hash
#----------------------------------------------------------------------
sub dbgetGeneLtags {

	$sql = qq{ select unique b.name, b.ltag from ns_data a, ns_data b  where  a.ltag=b.ltag and b.type='gene' };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ($name, $ltag, %nsGeneLtag);
	$sth->bind_columns( \$name, \$ltag );
	while ( $row = $sth->fetchrow_arrayref ) {
		$nsGeneLtag{lc($ltag)} = $name;
	}
	$sth->finish;

	return \%nsGeneLtag;
}

#----------------------------------------------------------------------
# get gene from ns_data 
# input: locustag
# return: gene
#----------------------------------------------------------------------
sub dbgetGene {
	my ($ltag, $genome) = @_;

	$sql = qq{ select unique b.name from ns_data a, ns_data b  where lower(a.name)=lower(?) and a.ltag=b.ltag and b.type='gene' and b.genome=? };
	$sth = $dbh->prepare($sql);
	$sth->execute($ltag, $genome);

	my ($name, $gene);
	$sth->bind_columns( \$name );
	while ( $row = $sth->fetchrow_arrayref ) {
		$gene = $name;
	}
	$sth->finish;

	return $gene;
}

#----------------------------------------------------------------------
# get genome gene and location
# input: platform
# return: ref to genome location
#----------------------------------------------------------------------
sub dbgetGeneLoc {
	my ($genome) = @_;

	$sql = qq{ select unique locus_tag, gene, sstart from genome where accession=? and locus_tag is not null order by to_number(sstart)};
	$sth = $dbh->prepare($sql);
	$sth->execute($genome);

	my ( $locus_tag, $gene, $sstart, %geneLoc );
	$sth->bind_columns( \$locus_tag, \$gene, \$sstart );
	my $i=1;
	while ( $row = $sth->fetchrow_arrayref ) {
		$geneLoc{$locus_tag}{gene} = $gene;
		$geneLoc{$locus_tag}{start} = $i++;
	}
	$sth->finish;

	return \%geneLoc;
}

#----------------------------------------------------------------------
# get namespace info by genome
# input: none
# return: hasfRef
#----------------------------------------------------------------------
sub dbgetNSgeneLoc {
	my ($genome) = @_;
	
	$sql = qq{ select unique ltag, name from ns_data where genome=? and type in ('locustag','old_locus_tag') };
	$sth = $dbh->prepare($sql);
	$sth->execute($genome);

	my ( $ltag, $name, %NSgeneLoc );

	$sth->bind_columns( \$ltag, \$name );
	while ( $row = $sth->fetchrow_arrayref ) {
		$NSgeneLoc{$name} = $ltag;
	}
	$sth->finish;

	return ( \%NSgeneLoc );
}

#----------------------------------------------------------------------
# get namespace info
# input: string qry
# return: hasfRef
#----------------------------------------------------------------------
sub dbgetNSinfo {
	my ($query) = @_;

	my ( $ltag, $name, $genome, $type, %glt, %nogene, %ns );

	#query name
	$sql = qq{ select ltag, genome, type from ns_data where lower(name)=lower(?) };
	$sth = $dbh->prepare($sql);
	$sth->execute($query);

	$sth->bind_columns( \$ltag, \$genome, \$type );
	while ( $row = $sth->fetchrow_arrayref ) {
			$glt{$genome}{$ltag} = $type;
	}
	$sth->finish;

	#query all ltags returned from query name
	$sql = qq{ select ltag, name, genome, type from ns_data where ltag = ? };
	$sth = $dbh->prepare($sql);

	for my $ggenome ( keys %glt ) {
		for my $gltag ( keys %{ $glt{$ggenome} } ) {
			$sth->execute( $gltag );
			$sth->bind_columns( \$ltag, \$name, \$genome, \$type );
			while ( $row = $sth->fetchrow_arrayref ) {
				$ns{$genome}{$ltag}{$name} = $type;
			}
		}
	}
	$sth->finish;

	return ( \%ns );
}

#----------------------------------------------------------------------
# query namespace
# input: string
# return: string - gene, ltag
#----------------------------------------------------------------------
sub dbQueryNamespace {
	my ($query) = @_;

	$sql = qq{ select nstype, nsid from k12namespace where lower(REGEXP_REPLACE(namespace, '\\(obsolete\\)', '')) = lower(?) };
	$sth = $dbh->prepare($sql);
	$sth->execute($query);

	my ( $nstype, $nsid, @searchID, @other );

	$sth->bind_columns( \$nstype, \$nsid );
	while ( $row = $sth->fetchrow_arrayref ) {
		if ( $nstype =~ /NC_000913:gene|NC_000913:locusTag/ ) {
			push( @searchID, $nsid );
		} else {
			push( @other, $nsid );
		}
	}
	$sth->finish;

	@searchID = @other if !@searchID;    #if we do not have a NC_000913:gene or NC_000913:locusTag then use other

	my ( @genes, @ltags );

	if (@searchID) {
		my $nsids = join( ',', @searchID );
		$sql =
		  qq{ select unique namespace, nstype from k12namespace where nsid in ($nsids) and (nstype = 'NC_000913:gene' or REGEXP_LIKE(lower(namespace), '(^b[0-9]{4})' )) order by nstype, namespace };
		$sth = $dbh->prepare($sql);
		$sth->execute();

		my ( $namespace );
		$sth->bind_columns( \$namespace, \$nstype );
		while ( $row = $sth->fetchrow_arrayref ) {
			if ( $nstype =~ /NC_000913:gene/ ) {
				push( @genes, $namespace );
			} else {
				$namespace =~ s/\(obsolete\)//;
				push( @ltags, $namespace );
			}
		}
		$sth->finish;
	}
	return ( \@genes, \@ltags );
}

#----------------------------------------------------------------------
# get experiment line Plot all data
# input: accession ID
# return: ref to plot data
#----------------------------------------------------------------------
sub dbgetLPlotAllData {
	my ($expid) = @_;

	my $nsGeneLtagRef = dbgetGeneLtags();
	my %nsGeneLtag = %$nsGeneLtagRef;

	$sql = qq{ select a.id, b.pratio, b.locustag from pexp a, pdata b where a.expid=? and a.id=b.pexp_id and b.pratio is not null };
	$sth = $dbh->prepare($sql);

	my ( $id, $pratio, $locustag, %dbPlotData );

	$sth->execute($expid);

	$sth->bind_columns( \$id, \$pratio, \$locustag );
	while ( $row = $sth->fetchrow_arrayref ) {

		$dbPlotData{$id}{$locustag}{locustag} = $locustag;
		
		if (exists $nsGeneLtag{$locustag}) {
			$dbPlotData{$id}{$locustag}{gene} = $nsGeneLtag{$locustag};
		}else{
			$dbPlotData{$id}{$locustag}{gene} = $locustag;
		}
		
		$dbPlotData{$id}{$locustag}{ratio}    = ($pratio) ? $pratio : '';
	}
	$sth->finish;

	return \%dbPlotData;
}

#----------------------------------------------------------------------
# get accession experiments
# input: none
# return: hasfRef to Experment Info, array of ID order
#----------------------------------------------------------------------
sub dbgetAccExpm {

	# we get ALL experiments so the OUID will be correct

	$sql = qq{ select a.id, a.expid, a.expname, a.channels, a.timepoint, a.expstddev, a.platform, a.testgenome, a.cntlgenome from pexp a order by to_number(substr(a.accession,4)), a.exporder, a.timepoint, a.samples };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my %dbaccExpmRec;    #hash
	my ( $id, $ouid, $expid, $expname, $channels, $timepoint, $expstddev, $platform, $testgenome, $cntlgenome );
	my @expm_order;
	$sth->bind_columns( \$id, \$expid, \$expname, \$channels, \$timepoint, \$expstddev, \$platform, \$testgenome, \$cntlgenome );
	while ( $row = $sth->fetchrow_arrayref ) {
		push @expm_order, $id;    #keep the experiment sort order

		$dbaccExpmRec{$id}{ouid}      = ++$ouid;
		$dbaccExpmRec{$id}{expid}     = ($expid) ? $expid : '';
		$dbaccExpmRec{$id}{expname}   = ($expname) ? $expname : '';
		$dbaccExpmRec{$id}{channels}  = ($channels) ? $channels : '';
		$dbaccExpmRec{$id}{timepoint} = ($timepoint) ? $timepoint : '';
		$dbaccExpmRec{$id}{std}       = ($expstddev) ? sprintf( "%05.3f", $expstddev ) : '';
		$dbaccExpmRec{$id}{platform} = ($platform) ? $platform : '';
		$dbaccExpmRec{$id}{testgenome} = ($testgenome) ? $testgenome : '';
		$dbaccExpmRec{$id}{cntlgenome} = ($cntlgenome) ? $cntlgenome : '';
	}
	$sth->finish;

	return ( \%dbaccExpmRec, \@expm_order );
}

#----------------------------------------------------------------------
# Get Download Accession/Experiment Info
# input: none
# return: array ref
#----------------------------------------------------------------------
sub dbgetDownloadInfo {
	$sql =
qq{ select a.id, a.expid, a.accession, a.expname, a.expstddev, a.samples, a.timepoint, a.channels, a.testcolumn, a.testbkgd, a.controlcolumn, a.cntlbkgd, a.logarithm, a.normalize, a.userma, b.name, c.title from pexp a, identifiable b, curated c where a.expid=b.id and a.expid= c.expid order by to_number(substr(a.accession,4)), a.exporder, a.timepoint, a.samples };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my $i = 0;
	my ( $id, $expid, $accession, $expname, $expstddev, $samples, $timepoint, $channels, $testcolumn, $testbkgd, $controlcolumn, $cntlbkgd, $logarithm, $normalize, $userma, $name, $title,
		%dbExpmRec );
	$sth->bind_columns(
		\$id,       \$expid,         \$accession, \$expname,   \$expstddev, \$samples, \$timepoint, \$channels, \$testcolumn,
		\$testbkgd, \$controlcolumn, \$cntlbkgd,  \$logarithm, \$normalize, \$userma,  \$name,      \$title
	);
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbExpmRec{$i}{id}        = ($id)        ? $id        : '';
		$dbExpmRec{$i}{expid}     = ($expid)     ? $expid     : '';
		$dbExpmRec{$i}{accession} = ($accession) ? $accession : '';
		$dbExpmRec{$i}{expname}   = ($expname)   ? $expname   : '';
		$dbExpmRec{$i}{name}      = ($title)     ? $title     : $name;
		$dbExpmRec{$i}{std}           = ($expstddev)     ? sprintf( "%05.3f", $expstddev ) : '';
		$dbExpmRec{$i}{samples}       = ($samples)       ? $samples                        : '';
		$dbExpmRec{$i}{timepoint}     = ($timepoint)     ? $timepoint                      : '';
		$dbExpmRec{$i}{channels}      = ($channels)      ? $channels                       : '';
		$dbExpmRec{$i}{testcolumn}    = ($testcolumn)    ? $testcolumn                     : '';
		$dbExpmRec{$i}{testbkgd}      = ($testbkgd)      ? $testbkgd                       : '';
		$dbExpmRec{$i}{controlcolumn} = ($controlcolumn) ? $controlcolumn                  : '';
		$dbExpmRec{$i}{cntlbkgd}      = ($cntlbkgd)      ? $cntlbkgd                       : '';
		$dbExpmRec{$i}{logarithm}     = ($logarithm)     ? 'Yes'                           : '';
		$dbExpmRec{$i}{normalize}     = ($normalize)     ? 'Yes'                           : '';
		$dbExpmRec{$i}{userma}        = ($userma)        ? "Yes"                           : '';
		$i++;
	}
	$sth->finish;

	return ( \%dbExpmRec );
}

#----------------------------------------------------------------------
# get next Pdata sequence number
# input: none
# return: hasfRef
#----------------------------------------------------------------------
sub dbgetPdataNextSeq {

	$sql = qq{ select pdata_seq.nextval seqID from dual };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my $seqID = 0;
	$sth->bind_columns( \$seqID );
	$row = $sth->fetchrow_arrayref;
	$sth->finish;

	return ($seqID);
}

#----------------------------------------------------------------------
# get experiment EID
# input: int - experiment ID
# return: int - EID
#----------------------------------------------------------------------
sub dbgetExpEID {
	my ($expid) = @_;

	$sql = qq{ select eid from experiment where id = ? };
	$sth = $dbh->prepare($sql);
	$sth->execute($expid);

	my $eid = 0;
	$sth->bind_columns( \$eid );
	$row = $sth->fetchrow_arrayref;
	$sth->finish;

	return ($eid);
}

#----------------------------------------------------------------------
# Save new experiment
# input: array
# return: int
#----------------------------------------------------------------------
sub dbsaveExptoDB {
	my ( $savExpInfoRef ) = @_;
	my %savExpInfo = %$savExpInfoRef;

	my $pexp_id = dbgetPdataNextSeq();
	my $expEID  = dbgetExpEID( $savExpInfo{expid} );
	if ( !$pexp_id or !$expEID ) {
		print "Cannot get experiment IDs.<br>";
		return 0;
	}

	#save info to pexp
	$sql = qq{ insert into pexp (id,eid,expname,expid,accession,samples,channels,testcolumn,testbkgd,controlcolumn,cntlbkgd,logarithm,normalize,antilog,userma,plottype,info,expstddev,platform,testgenome,cntlgenome,adddate,adduser) values ( ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,sysdate,? ) };
	$sth = $dbh->prepare($sql);

	my $testcolumn = ( $savExpInfo{testcolumn} ) ? $savExpInfo{testcolumn} : '';
	my $testbkgd = ( $savExpInfo{testbkgd} ) ? $savExpInfo{testbkgd} : '';

	my $controlcolumn = '';
	$controlcolumn = ( $savExpInfo{datacol} )       ? $savExpInfo{datacol}       : '' if ( $savExpInfo{channels} =~ /1/ );
	$controlcolumn = ( $savExpInfo{controlcolumn} ) ? $savExpInfo{controlcolumn} : '' if ( $savExpInfo{channels} =~ /2/ );
	my $cntlbkgd = ( $savExpInfo{cntlbkgd} ) ? $savExpInfo{cntlbkgd} : '';

	my $logarithm = ( $savExpInfo{logarithm} ) ? $savExpInfo{logarithm} : 0;
	my $normalize = ( $savExpInfo{normalize} ) ? $savExpInfo{normalize} : 0;
	my $antilog = ( $savExpInfo{antilog} ) ? $savExpInfo{antilog} : 0;
	my $userma = ( $savExpInfo{userma} ) ? $savExpInfo{userma} : 0;

	if ( !$sth->execute($pexp_id,$expEID,$gdb::webUtil::frmData{expname},$savExpInfo{expid},$savExpInfo{accession},$savExpInfo{samples},$savExpInfo{channels},$testcolumn,$testbkgd,$controlcolumn,$cntlbkgd,$logarithm,$normalize,$antilog,$userma,$savExpInfo{plottype},$gdb::webUtil::frmData{info},$savExpInfo{expstddev},$savExpInfo{platform},$savExpInfo{testgenome},$savExpInfo{cntlgenome},$gdb::webUtil::username) ) {
		print "Cannot insert experiment data.<br>";
		return 0;
	}
	$sth->finish;

	#get data file
	my $opened = open( FILE, "/run/shm/$savExpInfo{dataFilename}" );
	if ( !$opened ) {
		print "Cannot open datafile.<br>";
		return 0;
	}
	my @data = <FILE>;
	close(FILE);
	shift(@data);    #remove heading line

	#save data to pdata
	my $sqldata = qq{ insert into pdata (id, eid, pexp_id, pavg, pratio, locustag, multid ) values ( ?, ?, ?, ?, ?, ?, ? ) };
	my $sthdata = $dbh->prepare($sqldata);

	foreach my $line (@data) {
		chop($line);
		my ( $gene, $ltag, $test, $cntl ) = split( /\t/, $line );
		my @ltags = split( /\:/, $ltag );	#split locustags
		
		my $parent = 0;
		foreach my $lt (@ltags) {
			$lt =~ s/^\s+//;
			$lt =~ s/\s+$//;
	
			my $pdata_id = dbgetPdataNextSeq();
			if ( !$pdata_id ) {
				print "Cannot get pData ID.<br>";
				return 0;
			}
			if (!$parent) {
				$parent = $pdata_id;	#if we only have 1 ltag then id=multid, if multiple ltags then multid = parentID
			}
			if ( !$sthdata->execute($pdata_id, $expEID, $pexp_id, $test, $cntl, $lt, $parent ) ) {
				print "Cannot insert data.<br>";
				return 0;
			}
		}
	}
	$sthdata->finish;
	
	return $pexp_id;

}

#----------------------------------------------------------------------
# get Genome annotation Info
# input: query, genome
# return: lTag(s)
#----------------------------------------------------------------------
sub dbannotInfo {
	my ( $ltag, $genomeacc ) = @_;

	$sql =
qq{ select gene,locus_tag,feature,sstart,sstop,orientation,join,gi,swissprot,ecogene,ecocyc,geneid,asap,synonyms,ec_number,function,note,old_locus_tag,product,protein_id from genome where (accession=?) and (lower(locus_tag)=lower(?)) };
	$sth = $dbh->prepare($sql);
	$sth->execute( $genomeacc, $ltag );

	my (
		$gene,   $locus_tag, $feature,  $sstart,    $sstop,    $orientation, $join,          $gi,      $swissprot,  $ecogene, $ecocyc,
		$geneid, $asap,      $synonyms, $ec_number, $function, $note,        $old_locus_tag, $product, $protein_id, %dbannot
	);
	$sth->bind_columns(
		\$gene,   \$locus_tag, \$feature, \$sstart,   \$sstop,     \$orientation, \$join, \$gi,            \$swissprot, \$ecogene,
		\$ecocyc, \$geneid,    \$asap,    \$synonyms, \$ec_number, \$function,    \$note, \$old_locus_tag, \$product,   \$protein_id
	);
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbannot{gene}          = checkDups( $gene,          $dbannot{gene} );
		$dbannot{locus_tag}     = checkDups( $locus_tag,     $dbannot{locus_tag} );
		$dbannot{feature}       = checkDups( $feature,       $dbannot{feature} );
		$dbannot{sstart}        = checkDups( $sstart,        $dbannot{sstart} );
		$dbannot{sstop}         = checkDups( $sstop,         $dbannot{sstop} );
		$dbannot{orientation}   = checkDups( $orientation,   $dbannot{orientation} );
		$dbannot{join}          = checkDups( $join,          $dbannot{join} );
		$dbannot{gi}            = checkDups( $gi,            $dbannot{gi} );
		$dbannot{swissprot}     = checkDups( $swissprot,     $dbannot{swissprot} );
		$dbannot{ecogene}       = checkDups( $ecogene,       $dbannot{ecogene} );
		$dbannot{ecocyc}        = checkDups( $ecocyc,        $dbannot{ecocyc} );
		$dbannot{geneid}        = checkDups( $geneid,        $dbannot{geneid} );
		$dbannot{asap}          = checkDups( $asap,          $dbannot{asap} );
		$dbannot{synonyms}      = checkDups( $synonyms,      $dbannot{synonyms} );
		$dbannot{ec_number}     = checkDups( $ec_number,     $dbannot{ec_number} );
		$dbannot{function}      = checkDups( $function,      $dbannot{function} );
		$dbannot{note}          = checkDups( $note,          $dbannot{note} );
		$dbannot{old_locus_tag} = checkDups( $old_locus_tag, $dbannot{old_locus_tag} );
		$dbannot{product}       = checkDups( $product,       $dbannot{product} );
		$dbannot{protein_id}    = checkDups( $protein_id,    $dbannot{protein_id} );
	}
	$sth->finish;

	return ( \%dbannot );
}

#----------------------------------------------------------------------
# check to ses if we have dups
# input: field1, field2
# return: lTag(s)
#----------------------------------------------------------------------
sub checkDups {
	my ( $tmp1, $tmp2 ) = @_;

	$tmp1 = ($tmp1) ? $tmp1 : '';

	if ($tmp2) {
		if ( $tmp1 =~ /$tmp2/ ) {
			return $tmp1;
		} else {
			return $tmp2 . "," . $tmp1;
		}
	} else {
		return $tmp1;
	}
}

#----------------------------------------------------------------------
# get Genome annotation LocusTags
# input: query, genome
# return: lTag(s)
#----------------------------------------------------------------------
sub dbQryGenomeLtags {
	my ( $query, $genomeacc ) = @_;

	$sql = qq{ select unique gene, locus_tag from genome where (accession=?) and (lower(gene)=lower(?) or lower(locus_tag)=lower(?)) };
	$sth = $dbh->prepare($sql);
	$sth->execute( $genomeacc, $query, $query );

	my ( $gene, $locus_tag, @genes, @ltags );
	my $i = 0;
	$sth->bind_columns( \$gene, \$locus_tag );
	while ( $row = $sth->fetchrow_arrayref ) {
		push( @genes, $gene );
		push( @ltags, $locus_tag );
	}
	$sth->finish;

	return ( \@genes, \@ltags );
}

#----------------------------------------------------------------------
# get Genome annotation start/stop
# input: query, genome
# return: hash
#----------------------------------------------------------------------
sub dbgetAnnotStartStop {
	my ($genomeacc) = @_;

	$sql = qq{ select sstart, sstop from genome where accession=? and feature='source' and sstart='1' };
	$sth = $dbh->prepare($sql);
	$sth->execute($genomeacc);

	my ( $sstart, $sstop );
	$sth->bind_columns( \$sstart, \$sstop );
	$row = $sth->fetchrow_arrayref;
	$sth->finish;

	return ( $sstart, $sstop );
}

#----------------------------------------------------------------------
# get Genome annotation gene start/stop
# input: query, genome
# return: hash
#----------------------------------------------------------------------
sub dbgetStartStop {
	my ( $query, $genomeacc ) = @_;

	$sql = qq{ select unique sstart, sstop from genome where (accession=?) and (lower(gene)=lower(?) or lower(locus_tag)=lower(?)) };
	$sth = $dbh->prepare($sql);
	$sth->execute( $genomeacc, $query, $query );

	my ( $sstart, $sstop, %data );
	$sth->bind_columns( \$sstart, \$sstop );
	while ( $row = $sth->fetchrow_arrayref ) {
		$data{$query}{start} = $sstart;
		$data{$query}{stop}  = $sstop;
	}
	$sth->finish;

	return ( \%data );
}

#----------------------------------------------------------------------
# call procedure to query genes by genome location
# input: query
# return: lTag(s)
#----------------------------------------------------------------------
sub dbQryGenomeLocation {
	my ( $query, $genomeacc ) = @_;
	my $result;

	$sth = $dbh->prepare(q{BEGIN GENOME_LOCQRY( :qry, :acc, :results ); END;});

	$sth->bind_param( ":qry", $query );
	$sth->bind_param( ":acc", $genomeacc );
	$sth->bind_param_inout( ":results", \$result, 1 );

	$sth->execute();
	$sth->finish;

	return $result;
}

#----------------------------------------------------------------------
# get experiment info
# input: none
# return: hash
#----------------------------------------------------------------------
sub dbgetExpInfo {

	$sth = $dbh->prepare(q{ select a.id, a.expid, a.accession, a.expname, a.expstddev, a.cntlgenome, b.name, c.title from pexp a, identifiable b, curated c where a.expid=b.id and a.expid= c.expid and c.status=3 order by to_number(substr(a.accession,4)), a.exporder, a.timepoint, a.samples });
	$sth->execute();

	my ( %dbexpInfo );
	my ( $id, $expid, $accession, $expname, $expstddev, $cntlgenome, $name, $title );
	my $i=1;
	$sth->bind_columns( \$id, \$expid, \$accession, \$expname, \$expstddev, \$cntlgenome, \$name, \$title );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbexpInfo{$i}{id}        = $id;
		$dbexpInfo{$i}{accnid}    = $expid;
		$dbexpInfo{$i}{accession} = $accession;
		$dbexpInfo{$i}{expname}   = $expname;
		$dbexpInfo{$i}{stddev}    = $expstddev;
		$dbexpInfo{$i}{cntlgenome} = $cntlgenome;
		$dbexpInfo{$i}{accname}   = ($title) ? $title : $name;
		$dbexpInfo{$i}{flag}      = 0;
		$i++;
	}
	return ( \%dbexpInfo );	
}

#----------------------------------------------------------------------
# get experiment data by locustag(s)
# input: hash{gene}=array of ltags
# return: ref to experiment data
#----------------------------------------------------------------------
sub dbgetheatmapData {
	my ($ltagRef) = @_;
	
	my ( %dbHmData );

	my $lTagstring = join( ",", @$ltagRef);

	$sth = $dbh->prepare(q{ select pexp_id, pratio, locustag from pdata where lower(locustag) in ( select * from THE ( select cast( str2tbl( lower(?) ) as mytableType ) from dual ) ) });
	$sth->execute($lTagstring);
	
	my ( $pexp_id, $pratio, $locustag );
	$sth->bind_columns( \$pexp_id, \$pratio, \$locustag );
	while ( $row = $sth->fetchrow_arrayref ) {
		if (exists $dbHmData{$pexp_id}{ratio}) {
			$dbHmData{$pexp_id}{locustag} = $locustag;
			if ($pratio and $dbHmData{$pexp_id}{ratio}) {
				$dbHmData{$pexp_id}{ratio} = ($dbHmData{$pexp_id}{ratio} + $pratio) / 2;
			}
		}else{
			$dbHmData{$pexp_id}{locustag} = $locustag;
			$dbHmData{$pexp_id}{ratio}    = $pratio;
		}
	}

	return ( \%dbHmData );	

}

#----------------------------------------------------------------------
# get experiment data by locustag(s)
# input: hash{gene}=array of ltags
# return: ref to experiment data
#----------------------------------------------------------------------
sub xxdbgetheatmapData {
	my ($ltagRef) = @_;
	
	my ( %dbHmData );

	my $lTagstring = join( ",", @$ltagRef);

	$sth = $dbh->prepare(q{ select pexp_id, round(avg(pratio), 3) pratio, locustag from pdata where lower(locustag) in ( select * from THE ( select cast( str2tbl( lower(?) ) as mytableType ) from dual ) ) group by pexp_id, locustag });
	$sth->execute($lTagstring);
	
	my ( $pexp_id, $pratio, $locustag );
	$sth->bind_columns( \$pexp_id, \$pratio, \$locustag );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbHmData{$pexp_id}{locustag} = ($pratio) ? $locustag : '';
		$dbHmData{$pexp_id}{ratio}    = $pratio;
	}

	return ( \%dbHmData );	

}

#----------------------------------------------------------------------
# get operon
# input: string ltag
# return: string
#----------------------------------------------------------------------
sub dbgetoperon {
	my ($ltag) = @_;

	$sql = qq{ select operon from sup_operon where lower(locustag) = lower(?) };
	$sth = $dbh->prepare($sql);
	$sth->execute($ltag);
	my $operon = $sth->fetchrow_array;
	$sth->finish;

	return $operon;
}

#----------------------------------------------------------------------
# get regulators
# input: string ltag
# return: hasfRef
#----------------------------------------------------------------------
sub dbgetregulators {
	my ($ltag) = @_;

	$sql = qq{ select regulatorgene, effect from sup_regulon where lower(targetlocustag) = lower(?) order by regulatorgene };
	$sth = $dbh->prepare($sql);
	$sth->execute($ltag);

	my %dbregulatorsRec;
	my ( $regulatorgene, $effect );

	my $i = 0;
	$sth->bind_columns( \$regulatorgene, \$effect );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbregulatorsRec{$i}{gene}   = ($regulatorgene) ? $regulatorgene : '';
		$dbregulatorsRec{$i}{effect} = ($effect)        ? $effect        : '';
		$i++;
	}
	$sth->finish;

	return ( \%dbregulatorsRec );
}

#----------------------------------------------------------------------
# get sigma
# input: string ltag
# return: hasfRef
#----------------------------------------------------------------------
sub dbgetsigma {
	my ($ltag) = @_;

	$sql = qq{ select sigmagene from sup_sigma where lower(targetlocustag) = lower(?) order by sigmagene };
	$sth = $dbh->prepare($sql);
	$sth->execute($ltag);

	my %dbsigmaRec;
	my ($sigmagene);

	my $i = 0;
	$sth->bind_columns( \$sigmagene );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbsigmaRec{$i} = $sigmagene;
		$i++;
	}
	$sth->finish;

	return ( \%dbsigmaRec );
}

#----------------------------------------------------------------------
# get mfunLevels
# input: string ltag
# return: hasfRef
#----------------------------------------------------------------------
sub dbgetmfunLevels {
	my ($ltag) = @_;

	$sql = qq{ select a.blevel,b.mfunction from sup_mfun_bnum a, sup_mfun_levels b where lower(bnum) = lower(?) and a.mid=b.mid order by blevel };
	$sth = $dbh->prepare($sql);
	$sth->execute($ltag);

	my %dbmfunLevelsRec;
	my ( $blevel, $mfunction );

	my $i = 0;
	$sth->bind_columns( \$blevel, \$mfunction );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbmfunLevelsRec{$i}{level}    = $blevel;
		$dbmfunLevelsRec{$i}{function} = $mfunction;
		$i++;
	}
	$sth->finish;

	return ( \%dbmfunLevelsRec );
}

#----------------------------------------------------------------------
# get pathways
# input: string ltag
# return: hasfRef
#----------------------------------------------------------------------
sub dbgetpathways {
	my ($ltag) = @_;

	$sql = qq{ select b.uniqueid, b.name from sup_pwgenes a, sup_pathways b where lower(a.gene) = lower(?) and a.sup_pathways_id = b.id };
	$sth = $dbh->prepare($sql);
	$sth->execute($ltag);

	my %dbpathwaysRec;
	my ( $uniqueid, $name );

	my $i = 0;
	$sth->bind_columns( \$uniqueid, \$name );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbpathwaysRec{$i}{uniqueid} = $uniqueid;
		$dbpathwaysRec{$i}{name}     = $name;
		$i++;
	}
	$sth->finish;

	return ( \%dbpathwaysRec );
}

#----------------------------------------------------------------------
# get genes in operon
# input: string operon
# return: string
#----------------------------------------------------------------------
sub dbgetgenesInOperon {
	my ($operon) = @_;

	$sql = qq{ select gene, locustag, direction from sup_operon where lower(operon) = lower(?) order by gene };
	$sth = $dbh->prepare($sql);
	$sth->execute($operon);

	my %dboperonRec;
	my ( $gene, $locustag, $direction );

	my $i = 0;
	$sth->bind_columns( \$gene, \$locustag, \$direction );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dboperonRec{$i}{gene}      = ($gene)      ? $gene      : '';
		$dboperonRec{$i}{locustag}  = ($locustag)  ? $locustag  : '';
		$dboperonRec{$i}{direction} = ($direction) ? $direction : '';
		$i++;
	}
	$sth->finish;

	return ( \%dboperonRec );
}

#----------------------------------------------------------------------
# get genes in regulon
# input: string gene
# return: string
#----------------------------------------------------------------------
sub dbgetgenesInRegulon {
	my ($regulon) = @_;

	$sql = qq{ select targetgene, targetlocustag, effect, evidence from sup_regulon where lower(regulatorgene) = lower(?) order by targetgene };
	$sth = $dbh->prepare($sql);
	$sth->execute($regulon);

	my %dbregulonRec;
	my ( $targetgene, $targetlocustag, $effect, $evidence );

	my $i = 0;
	$sth->bind_columns( \$targetgene, \$targetlocustag, \$effect, \$evidence );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbregulonRec{$i}{gene}     = ($targetgene)     ? $targetgene     : '';
		$dbregulonRec{$i}{locustag} = ($targetlocustag) ? $targetlocustag : '';
		$dbregulonRec{$i}{effect}   = ($effect)         ? $effect         : '';
		$dbregulonRec{$i}{evidence} = ($evidence)       ? $evidence       : '';
		$i++;
	}
	$sth->finish;

	return ( \%dbregulonRec );
}

#----------------------------------------------------------------------
# get genes in sigma
# input: string gene
# return: string
#----------------------------------------------------------------------
sub dbgetgenesInSigma {
	my ($sigma) = @_;

	$sql = qq{ select unique targetgene, targetlocustag from sup_sigma where lower(sigmagene) = lower(?) order by targetgene };
	$sth = $dbh->prepare($sql);
	$sth->execute($sigma);

	my %dbsigmaRec;
	my ( $targetgene, $targetlocustag );

	my $i = 0;
	$sth->bind_columns( \$targetgene, \$targetlocustag );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbsigmaRec{$i}{gene}      = ($targetgene)     ? $targetgene     : '';
		$dbsigmaRec{$i}{locustag}  = ($targetlocustag) ? $targetlocustag : '';
		$i++;
	}
	$sth->finish;

	return ( \%dbsigmaRec );
}

#----------------------------------------------------------------------
# get genes in multifun
# input: string mfun
# return: string
#----------------------------------------------------------------------
sub dbgetgenesinMfun {
	my ($mfun) = @_;

	$sql = qq{ select a.bnum, b.mfunction from sup_mfun_bnum a, sup_mfun_levels b where REGEXP_LIKE( blevel, '^' || lower(?) ) and a.mid= b.mid order by bnum };
	$sth = $dbh->prepare($sql);
	$sth->execute($mfun);

	my %dbmfunRec;
	my ( $bnum, $mfunction );

	my $i = 0;
	$sth->bind_columns( \$bnum, \$mfunction );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbmfunRec{$i}{locustag}  = ($bnum)      ? $bnum      : '';
		$dbmfunRec{$i}{mfunction} = ($mfunction) ? $mfunction : '';
		$i++;
	}
	$sth->finish;

	return ( \%dbmfunRec );
}

#----------------------------------------------------------------------
# get genes in pathway
# input: string pway
# return: string
#----------------------------------------------------------------------
sub dbgetgenesinPway {
	my ($pway) = @_;

	$sql = qq{ select a.name,b.gene from sup_pathways a, sup_pwgenes b where lower(a.uniqueid) = lower(?) and a.id=b.sup_pathways_id  };
	$sth = $dbh->prepare($sql);
	$sth->execute($pway);

	my %dbpwayRec;
	my ( $name, $gene );

	$sth->bind_columns( \$name, \$gene );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbpwayRec{$gene} = $name;
	}
	$sth->finish;

	return ( \%dbpwayRec );
}

#----------------------------------------------------------------------
# query by Operon
# input: string query
# return: array ref
#----------------------------------------------------------------------
sub dbqryOperon {
	my ($query) = @_;

	$sql =
qq{ select unique b.gene, b.locustag from sup_operon a, sup_operon b where (lower(a.operon) = lower(?) or lower(a.gene) = lower(?) or lower(a.locustag) = lower(?)) and a.operon=b.operon order by b.locustag };
	$sth = $dbh->prepare($sql);
	$sth->execute( $query, $query, $query );

	my ( $gene, $locustag, @operon );
	$sth->bind_columns( \$gene, \$locustag );
	while ( $row = $sth->fetchrow_arrayref ) {
		push @operon, $gene;
	}
	$sth->finish;

	@operon = sort(@operon);

	return ( \@operon );
}

#----------------------------------------------------------------------
# query by Regulon
# input: string query
# return: array ref
#----------------------------------------------------------------------
sub dbqryRegulon {
	my ($query) = @_;

	$sql = qq{ select targetgene from sup_regulon where lower(regulatorgene) = lower(?) or lower(regulatorlocustag) = lower(?) order by targetlocustag };
	$sth = $dbh->prepare($sql);
	$sth->execute( $query, $query );

	my ( $targetgene, @regulon );
	$sth->bind_columns( \$targetgene );
	while ( $row = $sth->fetchrow_arrayref ) {
		push @regulon, $targetgene;
	}
	$sth->finish;

	@regulon = sort(@regulon);

	return ( \@regulon );
}

#----------------------------------------------------------------------
# query by Sigma
# input: string query
# return: array ref
#----------------------------------------------------------------------
sub dbqrySigma {
	my ($query) = @_;

	$sql = qq{ select targetgene from sup_sigma where lower(sigmagene) = lower(?) order by targetlocustag };
	$sth = $dbh->prepare($sql);
	$sth->execute($query);

	my ( $targetgene, @sigma );
	$sth->bind_columns( \$targetgene );
	while ( $row = $sth->fetchrow_arrayref ) {
		push @sigma, $targetgene;
	}
	$sth->finish;

	@sigma = sort(@sigma);

	return ( \@sigma );
}

#----------------------------------------------------------------------
# query by Annotation
# input: string query
# return: array ref
#----------------------------------------------------------------------
sub dbqryAnnot {
	my ($query) = @_;

	$sql =
qq{ select unique gene, locus_tag from genome where accession='NC_000913' and  ( REGEXP_LIKE(product, ?, 'i') or REGEXP_LIKE(function, ?, 'i') or REGEXP_LIKE(note, ?, 'i')) and gene is not null order by locus_tag };
	$sth = $dbh->prepare($sql);
	$sth->execute( $query, $query, $query );

	my ( $gene, $locus_tag, @annot );
	$sth->bind_columns( \$gene, \$locus_tag );
	while ( $row = $sth->fetchrow_arrayref ) {
		push @annot, $gene;
	}
	$sth->finish;

	@annot = sort(@annot);

	return ( \@annot );
}

#----------------------------------------------------------------------
# query by Experiment
# input: string query
# return: array ref
#----------------------------------------------------------------------
sub dbqryExperiment {
	my ($query) = @_;

	$sql = qq{ select expid 
				from experiment a, identifiable b, curated c 
				where a.id=b.id(+) 
				and (a.id=c.expid and c.status=3) 
				and ( REGEXP_LIKE(name, ?, 'i') 
				or REGEXP_LIKE(accession, ?, 'i') 
				or REGEXP_LIKE(institution, ?, 'i') 
				or REGEXP_LIKE(pi, ?, 'i')  
				or REGEXP_LIKE(author, ?, 'i') 
				or REGEXP_LIKE(title, ?, 'i') 
				or REGEXP_LIKE(designtype, ?, 'i') 
				or REGEXP_LIKE(timeseries, ?, 'i') 
				or REGEXP_LIKE(treatment, ?, 'i') 
				or REGEXP_LIKE(growthcond, ?, 'i') 
				or REGEXP_LIKE(modification, ?, 'i') 
				or REGEXP_LIKE(arraydesign, ?, 'i') 
				or REGEXP_LIKE(strain, ?, 'i') ) };
	$sth = $dbh->prepare($sql);
	$sth->execute( $query, $query, $query, $query, $query, $query, $query, $query, $query, $query, $query, $query, $query );

	my ( $expid, @expId );
	$sth->bind_columns( \$expid );
	while ( $row = $sth->fetchrow_arrayref ) {
		push @expId, $expid;
	}
	$sth->finish;

	return ( \@expId );
}

#----------------------------------------------------------------------
# GenExpDB Statistics
# input: none
# return: array ref
#----------------------------------------------------------------------
sub dbstatsInfo {

	my %dbstats;
	
	#get accession count
	$sql = qq{ select strain from curated where status=3 };
	$sth = $dbh->prepare($sql);
	$sth->execute();
	my $strain;
	$sth->bind_columns( \$strain );
	my $i=0;
	while ( $row = $sth->fetchrow_arrayref ) {
		$strain = ($strain) ? $strain : '';
		$i++;
	}
	$dbstats{accessions} = $i;

	#get experiment count
	$sql = qq{ select a.cntlgenome from pexp a, curated b where b.status=3 and a.expid=b.expid };
	$sth = $dbh->prepare($sql);
	$sth->execute();
	my $cntlgenome;
	$sth->bind_columns( \$cntlgenome );
	$i=0;
	while ( $row = $sth->fetchrow_arrayref ) {
		$cntlgenome = ($cntlgenome) ? $cntlgenome : '';
		$i++;
	}
	$dbstats{experiments} = $i;

	#get sample count
	$sql = qq{ select b.strain from bioassays_experiment a, curated b where b.status=3 and a.experiment_id=b.expid };
	$sth = $dbh->prepare($sql);
	$sth->execute();
	$sth->bind_columns( \$strain );
	$i=0;
	while ( $row = $sth->fetchrow_arrayref ) {
		$strain = ($strain) ? $strain : '';
		$i++;
	}
	$dbstats{samples} = $i;

	#get platform count
	$sql = qq{ select a.platform,a.cntlgenome from pexp a, curated b where b.status=3 and a.expid=b.expid };
	$sth = $dbh->prepare($sql);
	$sth->execute();
	my $platform;
	$sth->bind_columns( \$platform, \$cntlgenome );
	my %pfcnt;
	while ( $row = $sth->fetchrow_arrayref ) {
		$platform = ($platform) ? $platform : '';
		$cntlgenome = ($cntlgenome) ? $cntlgenome : '';
		$pfcnt{$platform} = 1;
	}
	$dbstats{platforms} = scalar keys %pfcnt;
	
	return \%dbstats;	
}

#----------------------------------------------------------------------
# get OperonDB version and date
# input: none
# return: string
#----------------------------------------------------------------------
sub dbgetOprnDBdate {
	$sql = qq{ select unique info from sup_operon };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $info, $OprnDBdate );

	$sth->bind_columns( \$info );
	while ( $row = $sth->fetchrow_arrayref ) {
		$OprnDBdate = $info;
	}
	$sth->finish;

	return ($OprnDBdate);
}

#----------------------------------------------------------------------
# get RegulonDB version and date
# input: none
# return: string
#----------------------------------------------------------------------
sub dbgetRegDBdate {
	$sql = qq{ select unique info from sup_regulon };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $info, $RegDBdate );

	$sth->bind_columns( \$info );
	while ( $row = $sth->fetchrow_arrayref ) {
		$RegDBdate .= $info . "<br>";
	}
	$sth->finish;

	return ($RegDBdate);
}

#----------------------------------------------------------------------
# get SigmaDB version and date
# input: none
# return: string
#----------------------------------------------------------------------
sub dbgetSigDBdate {
	$sql = qq{ select unique info from sup_sigma };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $info, $SigDBdate );

	$sth->bind_columns( \$info );
	while ( $row = $sth->fetchrow_arrayref ) {
		$SigDBdate = $info;
	}
	$sth->finish;

	return ($SigDBdate);
}

#----------------------------------------------------------------------
# get EcoCyc version and date
# input: none
# return: string
#----------------------------------------------------------------------
sub dbgetEcoCycDBdate {
	$sql = qq{ select unique info from sup_pathways };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $info, $EcoCycDBdate );

	$sth->bind_columns( \$info );
	while ( $row = $sth->fetchrow_arrayref ) {
		$EcoCycDBdate = $info;
	}
	$sth->finish;

	return ($EcoCycDBdate);
}

#----------------------------------------------------------------------
# get Genome version and date
# input: accessions
# return: string
#----------------------------------------------------------------------
sub dbgetGenomeDBdate {
	my ($acclist) = @_;

	$sql = qq{ select accession,adate,organism,sstop from genome where feature='source' and sstart='1' and accession in ( $acclist ) };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $accession, $adate, $organism, $sstop, %GenomeDBdate );

	$sth->bind_columns( \$accession, \$adate, \$organism, \$sstop );
	while ( $row = $sth->fetchrow_arrayref ) {
		$GenomeDBdate{$accession}{organism} = $organism;
		$GenomeDBdate{$accession}{sstop}    = $sstop;
		$GenomeDBdate{$accession}{adate}    = $adate;
	}
	$sth->finish;

	return ( \%GenomeDBdate );
}

#----------------------------------------------------------------------
# GenExpDB Platform Info
# input: none
# return: array ref
#----------------------------------------------------------------------
sub dbplatformInfo {

	#ist pass get all accessions platforms info
	$dbh->{LongReadLen} = 2 * 1024 * 1024;    #2 meg
	
	$sql = qq{ select c.identifier, c.name, d.value from curated a, physicalarraydesign b, identifiable c, namevaluetype d where a.status=3 and a.eid=b.eid and b.id=c.id and b.id=d.namevaluetype_id and d.name='Technology' };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $identifier, $name, $value, %dbplatforms );

	$sth->bind_columns( \$identifier, \$name, \$value );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbplatforms{$identifier}{name} = $name;
		$dbplatforms{$identifier}{type} = $value;
	}

	#2nd pass add experiment genomes
	$sql = qq{ select platform, cntlgenome from pexp };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $platform, $cntlgenome );

	$sth->bind_columns( \$platform, \$cntlgenome );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbplatforms{$platform}{genome} = $cntlgenome;
	}

	return \%dbplatforms;
}

#----------------------------------------------------------------------
# GenExpDB Platforms counts
# input: none
# return: array ref
#----------------------------------------------------------------------
sub dbplatformCounts {

	#get platforms counts
	$sql = qq{ select platform, count(*) cnt from platformannot group by platform };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $platform, $cnt, %dbpfcnt );

	$sth->bind_columns( \$platform, \$cnt );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbpfcnt{$platform} = $cnt;
	}
	$sth->finish;

	return \%dbpfcnt;
}

#----------------------------------------------------------------------
# GenExpDB Accession Samples Info
# input: none
# return: array ref
#----------------------------------------------------------------------
sub dbaccSamplesInfo {
	$sql = qq{ select b.identifier accession, b.name expname, c.identifier sample, c.name sampname, d.strain 
				from bioassays_experiment a, identifiable b, identifiable c, curated d 
				where a.experiment_id=b.id and a.bioassays_id=c.id and a.experiment_id=d.expid and d.status=3 
				order by to_number(substr(b.identifier,4)), to_number(substr(c.identifier,4)) };
	$sth = $dbh->prepare($sql);
	$sth->execute();
	
	my ( $accession, $expname, $sample, $sampname, $strain, %dbaccSamples );

	$sth->bind_columns( \$accession, \$expname, \$sample, \$sampname, \$strain );
	my $i=0;
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbaccSamples{$i}{accession} = $accession;
		$dbaccSamples{$i}{expname}   = $expname;
		$dbaccSamples{$i}{sample}    = $sample;
		$dbaccSamples{$i}{sampname}  = $sampname;
		$dbaccSamples{$i}{strain}    = $strain;
		$i++;
	}
	$sth->finish;
	
	return ( \%dbaccSamples );	
}

#----------------------------------------------------------------------
# GenExpDB Experiment Samples Info
# input: none
# return: array ref
#----------------------------------------------------------------------
sub dbexpSamplesInfo {

	#get all active samples
	$sql = qq{ select b.accession, b.expname, b.samples, b.cntlgenome from curated a, pexp b where a.status=3 and a.expid=b.expid };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $accession, $expname, $samples, $cntlgenome, %dbexpSamples, %expcnt );

	$sth->bind_columns( \$accession, \$expname, \$samples, \$cntlgenome );
	while ( $row = $sth->fetchrow_arrayref ) {
		$expcnt{$accession}++;		#number of experiments per accessions
		my @tmp = split( /\,|\//, $samples );
		for my $samp (@tmp) {
			$dbexpSamples{$accession}{$samp}{$expname} = $cntlgenome;
		}
	}
	$sth->finish;

	return ( \%dbexpSamples, \%expcnt );
}

#----------------------------------------------------------------------
# GenExpDB Experiment Data Genes
# input: none
# return: array ref
#----------------------------------------------------------------------
sub dbexpGenesInfo {

	my $nsGeneLtagRef = dbgetGeneLtags();
	my %nsGeneLtag = %$nsGeneLtagRef;

	#get all experiment data genes
	$sql = qq{ select c.locustag, count(*) cnt from  curated a, pexp b, pdata c where (a.status=3 and a.expid=b.expid(+)) and b.id=c.pexp_id group by c.locustag order by c.locustag };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $locustag, $cnt, %dbexpGenes );
	my $i = 0;

	$sth->bind_columns( \$locustag, \$cnt );
	while ( $row = $sth->fetchrow_arrayref ) {
		$dbexpGenes{$i}{locustag} = $locustag;
		$dbexpGenes{$i}{cnt}      = $cnt;
		
		$dbexpGenes{$i}{gene} = '';
		if (exists $nsGeneLtag{$locustag}) {
			$dbexpGenes{$i}{gene} = $nsGeneLtag{$locustag};
		}
		
		$i++;
	}
	$sth->finish;

	return ( \%dbexpGenes );
}

#----------------------------------------------------------------------
# JBrowse info
# input: id
# return: hash
#----------------------------------------------------------------------
sub dbjbrowseInfo {
	my ($id) = @_;

	my %exp;
	$sql = qq{ select accession, cntlgenome from pexp where id=? };
	$sth = $dbh->prepare($sql);
	$sth->execute($id);
	my $accession = '';
	my $cntlgenome = '';
	$sth->bind_columns( \$accession, \$cntlgenome );
	$row = $sth->fetchrow_arrayref;
	return ($accession, $cntlgenome);
}

#----------------------------------------------------------------------
# Query nameSpace
# input: qry, genome
# return: hash
#----------------------------------------------------------------------
sub qryNS {
	my ( $query, $genome ) = @_;
	$query = lc($query);

	#search ns_data for query
	$sth = $dbh->prepare(q{ select a.ltag altag,a.name aname,a.genome agenome,a.type atype,b.ltag bltag,b.name bname,b.genome bgenome,b.type btype from ns_data a, ns_data b where lower(a.name)=lower(?) and a.ltag=b.ltag });
	$sth->execute($query);

	my ( %gene, %ltag, %olt, %ns );
	my ( $altag, $aname, $agenome, $atype, $bltag, $bname, $bgenome, $btype );
	$sth->bind_columns( \$altag, \$aname, \$agenome, \$atype, \$bltag, \$bname, \$bgenome, \$btype );
	while ( $row = $sth->fetchrow_arrayref ) {
	
		$gene{ lc($aname) }{$agenome}{$altag} = 1 if ( $atype =~ /gene|synonym/ );
		$ltag{ lc($aname) }{$agenome}{$altag} = 1 if ( $atype =~ /locustag/ );
		$olt{ lc($aname) }{$agenome}{$altag} = 1 if ( $atype =~ /old_locus_tag/ );
		
		$gene{ lc($bname) }{$bgenome}{$bltag} = 1 if ( $btype =~ /gene|synonym/ );
		$ltag{ lc($bname) }{$bgenome}{$bltag} = 1 if ( $btype =~ /locustag/ );
		$olt{ lc($bname) }{$bgenome}{$bltag} = 1 if ( $btype =~ /old_locus_tag/ );
	}

	my %tags;
	if ( $gene{$query} ) {
		for my $ltag ( sort { lc($a) cmp lc($b) } keys %{ $gene{$query}{$genome} } ) {
			$tags{$ltag} = $genome;
		}
	} elsif ( $ltag{$query} ) {
		for my $ltag ( sort { lc($a) cmp lc($b) } keys %{ $ltag{$query}{$genome} } ) {
			$tags{$ltag} = $genome;
		}
	} elsif ( $olt{$query} ) {
		for my $ltag ( sort { lc($a) cmp lc($b) } keys %{ $olt{$query}{$genome} } ) {
			$tags{$ltag} = $genome;
		}
	}

	#we did not find ltag by gene,ltag - see if we find it in other
	if ( !%tags ) {
		for my $aname ( sort { lc($a) cmp lc($b) } keys %ltag ) {
			for my $agenome ( sort { lc($a) cmp lc($b) } keys %{ $ltag{$aname} } ) {
				if ( $query =~ $aname ) {
					for my $ltag ( sort { lc($a) cmp lc($b) } keys %{ $ltag{$aname}{$agenome} } ) {
						$tags{$ltag} = $agenome;
					}
				}
			}
		}
	}

	#still no ltag found
	if ( !%tags ) {
		if (($genome =~ /NC_000913/) and ($query =~ /^b/i)) {$tags{$query} = $genome;}
		if (($genome =~ /NC_002655/) and ($query =~ /^z/i)) {$tags{$query} = $genome;}
		if (($genome =~ /NC_002695/) and ($query =~ /^e/i)) {$tags{$query} = $genome;}
		if (($genome =~ /NC_004431/) and ($query =~ /^c/i)) {$tags{$query} = $genome;}
		if (($genome =~ /NC_007946/) and ($query =~ /^u/i)) {$tags{$query} = $genome;}
		if (($genome =~ /NC_013716/) and ($query =~ /^r/i)) {$tags{$query} = $genome;}
		if (($genome =~ /NC_003197/) and ($query =~ /^s/i)) {$tags{$query} = $genome;}
		if (($genome =~ /NC_004631/) and ($query =~ /^t/i)) {$tags{$query} = $genome;}
		if (($genome =~ /NC_002505/) and ($query =~ /^(vc)+[0-9]{4}/i)) {$tags{$query} = $genome;}
		if (($genome =~ /NC_002506/) and ($query =~ /^vca/i)) {$tags{$query} = $genome;}
	}

	#find related
	my @atags = keys %tags;
	if ( ( scalar @atags ) < 2 ) {	#we found only 1 (or none) ltag
		my $rel = ( $atags[0] ) ? $atags[0] : $query;    #use ltag (if we have one), if not use query
		
		$sth = $dbh->prepare(q{ select a.ltag altag,a.name aname,a.genome agenome,a.type atype,b.ltag bltag,b.name bname,b.genome bgenome,b.type btype from ns_data a, ns_data b where lower(a.name)=lower(?) and a.ltag=b.ltag });
		$sth->execute($rel);
	
		my ( $altag, $aname, $agenome, $atype, $bltag, $bname, $bgenome, $btype );
		$sth->bind_columns( \$altag, \$aname, \$agenome, \$atype, \$bltag, \$bname, \$bgenome, \$btype );
		while ( $row = $sth->fetchrow_arrayref ) {
			next if ($atags[0] and $atags[0] =~ /$altag/);
			next if ($atags[0] and $atags[0] =~ /$bltag/);

			
			if ( $altag =~ /^(b|z|ecs|c|uti89_c|stm|t|vca|vc|rod_2)+[0-9]{4}/i ) {
				$ns{$altag} = $agenome;
			}
			if ( $bltag =~ /^(b|z|ecs|c|uti89_c|stm|t|vca|vc|rod_2)+[0-9]{4}/i ) {
				$ns{$bltag} = $bgenome;
			}
			if ( $bname =~ /^(b|z|ecs|c|uti89_c|stm|t|vca|vc|rod_2)+[0-9]{4}/i ) {
				my @ml = split( /\,/, $bname );
				for my $sl (@ml) {
					$sl =~ s/^\s+//;
					$sl =~ s/\s+$//;
					next if ( !$sl );
					next if ($atags[0] and $atags[0] =~ /$sl/);
					$ns{$sl} = $bgenome;
				}
			}	
		}
	}
	
	return ( \%tags, \%olt, \%ns );
}

###GeoUpdate
#----------------------------------------------------------------------
# get Curated table
# input: none
# return: hash
#----------------------------------------------------------------------
sub dbgetCurated {
	my ($acc) = @_;

	if ($acc) {
		$sql = qq{ select accession, status, pmid, strain, substrain, info, geodesc, geomatch, adddate, adduser, moddate, moduser from curated where accession = ? };
		$sth = $dbh->prepare($sql);
		$sth->execute($acc);
	} else {
		$sql = qq{ select accession, status, pmid, strain, substrain, info, geodesc, geomatch, adddate, adduser, moddate, moduser from curated };
		$sth = $dbh->prepare($sql);
		$sth->execute();
	}

	my ( $accession, $status, $pmid, $strain, $substrain, $info, $geodesc, $geomatch, $adddate, $adduser, $moddate, $moduser, %curated );
	$sth->bind_columns( \$accession, \$status, \$pmid, \$strain, \$substrain, \$info, \$geodesc, \$geomatch, \$adddate, \$adduser, \$moddate, \$moduser );
	while ( $row = $sth->fetchrow_arrayref ) {
		$curated{$accession}{status}    = $status;
		$curated{$accession}{pmid}      = $pmid;
		$curated{$accession}{strain}    = $strain;
		$curated{$accession}{substrain} = $substrain;
		$curated{$accession}{info}      = $info;
		$curated{$accession}{geodesc}   = $geodesc;
		$curated{$accession}{geomatch}  = $geomatch;
		$curated{$accession}{adddate}   = $adddate;
		$curated{$accession}{adduser}   = $adduser;
		$curated{$accession}{moddate}   = $moddate;
		$curated{$accession}{moduser}   = $moduser;
	}
	$sth->finish;

	return ( \%curated );
}

#----------------------------------------------------------------------
# insert geoUpdate
# input: hash
# return: none
#----------------------------------------------------------------------
sub dbputgeoUpdate {
	my ( $gseRef ) = @_;
	my %gse = %$gseRef;

	my $username     = gdb::webUtil::getSessVar( 'username' );
	
	#we need to get all accessions we now have in the curated table
	$sql = qq{ select id, accession from curated };
	$sth = $dbh->prepare($sql);
	$sth->execute();

	my ( $id, $accession, %currAcc );
	$sth->bind_columns( \$id, \$accession );
	while ( $row = $sth->fetchrow_arrayref ) {
		$currAcc{$accession} = $id;
	}

	#add record if we do not have it...
	$sql = qq{ insert into curated (id, accession, geodesc, geomatch, status, adddate, adduser)  values ( id_seq.nextval, ?, ?, ?, 1, sysdate, ? ) };
	$sth = $dbh->prepare($sql);

	my $numadded = 0;
	for my $acc ( keys %gse ) {
		if ( !$currAcc{$acc} ) {
			$numadded++;
			$sth->execute( $acc, $gse{$acc}{desc}, $gse{$acc}{match}, $username );
		}
	}

	return $numadded;
}

#----------------------------------------------------------------------
# save Geo edit
# input: hash
# return: none
#----------------------------------------------------------------------
sub dbsavegeoEdit {
	my ( $sql, $dataRef ) = @_;
	my @data = @$dataRef;
	
	my $rc = 0;
	$sth = $dbh->prepare($sql);
	if ( $sth->execute(@data) ) {
		$rc = 1;
	} else {
		$rc = -1;	#error
	}
	
	return $rc;
}

1;    # return a true value
