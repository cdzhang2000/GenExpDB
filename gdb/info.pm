#------------------------------------------------------------------------------------------
# FileName    : gdb/info.pm
#
# Description : Info
# Author      : jgrissom
# DateCreated : 28 Sep 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package gdb::info;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

#----------------------------------------------------------------------
# Help
# input: none
# return: none
#----------------------------------------------------------------------
sub help {
	
	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  
	  qq{<table class="tblb" width="1000" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<th class="thc">Gene Expression Database Help (click section for info)</th>\n};
	  
	  	my $hnum;
		$hnum = "hlp1";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">FAQ</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{FAQs...};	  
		print qq{</p></div></td></tr>\n};	  
		print qq{<tr><td class="tdl"><hr></td></tr>\n};	  
	  
		$hnum = "hlp2";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Home</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{Return to home screen and Reset all settings to default.};	  
		print qq{</p></div></td></tr>\n};	  
		$hnum = "hlp3";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Settings</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><pre>};	  
		print qq{
	Preference Settings
	  Save Settings - click to save
	  Genome - Reference Genome sets gene query space according to selected RefSeq annotation.
	  Max number of Genes displayed - Each gene query will produce 1 heatmap. Change default [5] to display fewer or more
	  Wrap - default is to display all experiments in [5] rows
	  No wrap - display all experiments in 1 rows
	  Color scheme - Heatmap default color display is Blue/Yellow
		};	  
		print qq{</pre></div></td></tr>\n};	  
		$hnum = "hlp4";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Info</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
	  	print qq{<tr><td class="tdl"><hr></td></tr>\n};
	  	
		$hnum = "hlp5";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Example</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
		$hnum = "hlp6";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Operon</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
		$hnum = "hlp7";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Regulon</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
		$hnum = "hlp8";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Sigma</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
		$hnum = "hlp9";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Annotation</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
		$hnum = "hlp10";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Experiment</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
		$hnum = "hlp11";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">MultiFun</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
		$hnum = "hlp12";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Query</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
	  	print qq{<tr><td class="tdl"><hr></td></tr>\n};
	  	
		$hnum = "hlp13";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Heatmap</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
	  	print qq{<tr><td class="tdl"><hr></td></tr>\n};
	  	
		$hnum = "hlp14";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Browser</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
	  	print qq{<tr><td class="tdl"><hr></td></tr>\n};
	  	
		$hnum = "hlp15";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Annotation</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
	  	print qq{<tr><td class="tdl"><hr></td></tr>\n};
	  	
		$hnum = "hlp16";
		print qq{<tr><td><a class="hlpa" onclick="sh('$hnum');" onmouseover="return overlib('click to expand/close');" onmouseout="return nd();">Accessions</a></td></tr>\n};
		print qq{<tr><td><div class="hidden" id="$hnum"><p class="hlpb">};	  
		print qq{$hnum help};	  
		print qq{</p></div></td></tr>\n};	  
	  	
	  
	print
	  qq{</table>\n}, 
	  
	  qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# About
# input: none
# return: none
#----------------------------------------------------------------------
sub about {
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );
	
	my $operonDB  = gdb::oracle::dbgetOprnDBdate();
	my $regulonDB = gdb::oracle::dbgetRegDBdate();
	my $sigmaDB   = gdb::oracle::dbgetSigDBdate();
	my $ecocyc    = gdb::oracle::dbgetEcoCycDBdate();

	my @acc;
	for my $i ( sort { $a <=> $b } keys %gdb::util::gnom ) {
		push @acc, $gdb::util::gnom{$i}{acc};
	}
	my $acclist = "'" . join( "','", @acc ) . "'";
	my $genomeRef = gdb::oracle::dbgetGenomeDBdate($acclist);
	my %genome = %$genomeRef;
	
	my $multifun = 'Gretta Serres and Monica Riley, March 2007';

	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  
	  qq{<table class="tblb">\n},
	  qq{<tr>\n},
	  qq{<th class="thc" colspan="2">About OU Gene Expression Database</th>\n},
	  qq{</tr>\n},

	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Version</b></td><td class="tdl">$gdb::webUtil::version</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Project Leader</b></td><td class="tdl"><a href="http://www.ou.edu/cas/botany-micro/faculty/conway.html" target="_blank">Tyrrell Conway</a></td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Curators</b></td><td class="tdl"></td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Collaborators</b></td><td class="tdl"></td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Developers</b></td><td class="tdl"></td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Database</b></td><td class="tdl">Oracle Release 10.2.0.3.0</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Software</b></td><td class="tdl">Apache/2.2.17 mod_perl/2.0.5 Perl/v5.8.5</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Hardware</b></td><td class="tdl">},
	  qq{bioDB	2-Dell PowerEdge 6850, 8 CPU, 3.00HGz, 16GB memory<br>},
	  qq{bioApp	2-Dell PowerEdge 6850, 8 CPU, 3.00HGz, 16GB memory<br>},
	  qq{bioWeb	2-Dell PowerEdge 2950, 8 CPU, 1.60HGz, 8GB memory},
	  qq{</td></tr>\n},
	  qq{</table>\n}, 
	  qq{<br>\n}, 
	  
	  qq{<table class="tblb">\n},
	  qq{<tr>\n},
	  qq{<th class="thc" colspan="2">Source Information</th>\n},
	  qq{</tr>\n},

	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Accessions</b></td><td class="tdl">NCBI Gene Expression Omnibus (<a href="http://www.ncbi.nlm.nih.gov/geo/" target="_blank">GEO</a>)</td></tr>\n};
	  
	  for my $i ( sort { $a <=> $b } keys %gdb::util::gnom ) {
	  	my $accession = $gdb::util::gnom{$i}{acc};
	  	my $annot     = "$genome{$accession}{organism} &nbsp;&nbsp; ($genome{$accession}{sstop}) &nbsp;&nbsp; $genome{$accession}{adate}";
	  	print qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Annotation</b></td><td class="tdl">NCBI Refseq: <a href="http://www.ncbi.nlm.nih.gov/nuccore/$accession" target="_blank">$accession</a> $annot</td></tr>\n};
	  }
	  
	print qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>SynFile</b></td><td class="tdl"><a href="http://ecoliwiki.net/colipedia" target="_blank">EcoliWiki</a></td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>OUGenExp</b></td><td class="tdl">OU Gene Expression Database</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Operon</b></td><td class="tdl">$operonDB</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Regulators</b></td><td class="tdl">$regulonDB</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Sigma</b></td><td class="tdl">$sigmaDB</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Multifun</b></td><td class="tdl">$multifun</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl"><b>Pathway</b></td><td class="tdl">$ecocyc</td></tr>\n},
	  qq{</table>\n}, 
	  
	  qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# Info
# input: none
# return: none
#----------------------------------------------------------------------
sub info {
	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb">\n},
	  qq{<tr>\n},
	  qq{<th class="thc" colspan="2">INFORMATION</th>\n},
	  qq{</tr>\n},

	  qq{<tr>\n}, 
	  qq{<td class="tdl"><a class="mnl" onclick="gm('about');">About GenExpDB</a></td>\n}, 
	  qq{<td class="tdl">GenExpDB information</td>\n}, 
	  qq{</tr>\n},
	  
	  qq{<tr>\n}, 
	  qq{<td class="tdl"><a class="mnl" onclick="gm('platforms');">Platforms</a></td>\n}, 
	  qq{<td class="tdl">Listing of all annotation platforms</td>\n}, 
	  qq{</tr>\n},

	  qq{<tr>\n}, 
	  qq{<td class="tdl"><a class="mnl" onclick="gm('downloadAccessions');">Download data</a></td>\n}, 
	  qq{<td class="tdl">Select Accessions/Experiments for download</td>\n}, 
	  qq{</tr>\n},

	  qq{<tr>\n}, 
	  qq{<td class="tdl"><a class="mnl" onclick="gm('accsamples');">Accession samples</a></td>\n}, 
	  qq{<td class="tdl">Listing of accessions samples</td>\n}, 
	  qq{</tr>\n},

	  qq{<tr>\n}, 
	  qq{<td class="tdl"><a class="mnl" onclick="gm('expsamples');">Samples used in experiments</a></td>\n}, 
	  qq{<td class="tdl">Listing of accessions samples used in experiments</td>\n}, 
	  qq{</tr>\n},

	  qq{<tr>\n}, 
	  qq{<td class="tdl"><a class="mnl" onclick="gm('expgenes');">Genes used in experiments</a></td>\n}, 
	  qq{<td class="tdl">Count of genes/locusTags used in experiments</td>\n}, 
	  qq{</tr>\n},

	  qq{<tr>\n}, 
	  qq{<td class="tdl"><a class="mnl" onclick="gm('stats');">GenExpDB Statistics</a></td>\n}, 
	  qq{<td class="tdl">GenExpDB statistics information</td>\n}, 
	  qq{</tr>\n};
	  
##     if ( $Genexpdb::webUtil::useracclevel > 2 ) {
       print
		qq{<tr>\n}, 
		qq{<td class="tdl"><a class="mnl" onclick="gm('geoupdt');">Geo Update</a></td>\n}, 
		qq{<td class="tdl">Query GEO for new accessions</td>\n}, 
		qq{</tr>\n},
#		qq{<tr>\n}, 
#		qq{<td class="tdl"><a class="mnl" onclick="gm('expanalyze');">Analyze Experiments</a></td>\n}, 
#		qq{<td class="tdl">Select experiments to alalyze</td>\n}, 
#		qq{</tr>\n};
 ##     }
	  
	  qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#--------------------------------------------------------------------
# display GenExpDB Platforms
# input: none
# return: none
#----------------------------------------------------------------------
sub platforms {
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $dbplatformsRef = gdb::oracle::dbplatformInfo();
	my %dbplatforms    = %$dbplatformsRef;

	my $dbpfcntRef = gdb::oracle::dbplatformCounts();
	my %dbpfcnt    = %$dbpfcntRef;

	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb">\n},
	  qq{<tr>\n},
	  qq{<th class="thc" colspan="4">GenExpDB Platforms</th>\n},
	  qq{</tr>\n},

	  qq{<tr class="thc"><td>PLATFORM</td><td>COUNT</td><td>NAME</td><td>TECHNOLOGY TYPE</td></tr>\n};

	my $numPlatforms = 0;

	for my $platform ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } keys %dbplatforms ) {
		my $genome = ($dbplatforms{$platform}{genome}) ? $dbplatforms{$platform}{genome} : '';
		my $cnt = ($dbpfcnt{$platform}) ? $dbpfcnt{$platform} : '';
		$numPlatforms++;
		print qq{<tr bgcolor="#ebf0f2">
			<td class="tdl"><a href="http://www.ncbi.nlm.nih.gov/projects/geo/query/acc.cgi?acc=$platform" target="_blank" onmouseover="return overlib('query this platform in Geo (new window)');" onmouseout="return nd();">$platform</a></td>
			<td class="tdr">$cnt</td>
			<td class="tdl">$dbplatforms{$platform}{name}</td>
			<td class="tdl">$dbplatforms{$platform}{type}</td></tr>\n};
	}
	print qq{<tr><td class="tdl">Recs: <b>$numPlatforms</b></td></tr>\n},
	
	  qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#--------------------------------------------------------------------
# select accessions/experiments to download
# input: none
# return: none
#----------------------------------------------------------------------
sub downloadAccessions {
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $dbAccessionRec = gdb::oracle::dbAccessionsInfo();
	my %dbAccession    = %$dbAccessionRec;

	my $allchecked = ($gdb::webUtil::frmData{aid}) ? 'checked' : '';

	print
	  qq{<a class="exmp" onclick="sh('ginfo');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a>\n},
	  
	  qq{<div class="hidden" id="download"></div>\n},

	  qq{<div style="margin-left:20px;">\n},
	  qq{<h3>GenExpDB Download Data</h3>\n},
	  qq{<input class="ebtn" type="button" name="downloaddata" value="Download" onclick="download();">&nbsp;&nbsp;<span class="small">Select Accessions/Experiments then click download. (multiple Accessions will zipped)</span>\n},

	  qq{<table class="tblb" cellpadding="0" cellspacing="1">\n},

	  qq{<tr>\n},
	  qq{<th class="thc" onmouseover="return overlib('Select/Unselect all');" onmouseout="return nd();"><input id="ckalldlaccid" type="checkbox" name="ckalldlaccid" onclick="ckall(this,'ckdlaccn');" $allchecked></th>\n},
	  qq{<th class="thc">ACCESSION</th>\n},
	  qq{<th class="thc">NAME</th>\n},
	  qq{<th class="thc">STRAIN</th>\n},
	  qq{</tr>\n};

	for my $i ( sort { $a <=> $b } keys %dbAccession ) {
		my $id = $dbAccession{$i}{id};

		my $strain = ($dbAccession{$i}{strain}) ? $dbAccession{$i}{strain} : '';
		my $checked = ( $gdb::webUtil::frmData{aid} =~ /$id/ ) ? 'checked' : '';
		my $title = ( $dbAccession{$i}{title} ) ? $dbAccession{$i}{title} : $dbAccession{$i}{name};
		
		print qq{<tr bgcolor="#ebf0f2">\n},
			qq{<td class="tdc"><input id="ckdlaccn$id" class="small" type="checkbox" name="ckdlaccn" value="$id" onclick="ckfile(this,'ckalldlaccid','ckdlaccn');" $checked></td>\n},

			qq{<td class="tdl">},
			qq{<img id="dlesign$id" src="$gdb::util::webloc/web/plus.gif" onclick="ckdlaccexp($id);" alt="" onmouseover="this.style.cursor='pointer';return overlib('click to display experiments');" onmouseout="return nd();"> },
			qq{$dbAccession{$i}{accession}</td>\n},

			qq{<td class="tdl">$title</td>\n},
			qq{<td class="tdl">$strain</td>\n},
			qq{</tr>\n},

		#hidden  experiments
			qq{<tr><td colspan="10"><div class="hidden" id="dlexp$id"></div></td></tr>\n};
	}
	print qq{</table>\n}, qq{</div>\n};
}

#--------------------------------------------------------------------
# Display dowload experiments
# input: none
# return: none
#----------------------------------------------------------------------
sub showdlexpm {
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );
	
	my ( $dbaccExpmRec, $expm_orderRef ) = gdb::oracle::dbgetAccExpm();    #get all accession experiments so the OUID will be correct
	my %dbaccExpm  = %$dbaccExpmRec;
	my @expm_order = @$expm_orderRef;
	my $ExpmCount  = 0;
	my $hasExp     = 0;
	my $ckaccn = ( $gdb::webUtil::frmData{ckdlaccn} =~ /true/ ) ? 'checked' : '';    #see if accession was checked
	
	print qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="ckdlaccexp($gdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb" align="center">\n};
	  
	for my $id (@expm_order) {
		next if ($dbaccExpm{$id}{cntlgenome} !~ /$gdb::util::gnom{$parms->{genome}}{acc}/i);
		
		if ( $gdb::webUtil::frmData{id} == $dbaccExpm{$id}{expid} ) {
			$ExpmCount++;
			if ( !$hasExp ) {
				$hasExp = 1;
				print qq{<tr>\n},
				qq{<th class="thc" onmouseover="return overlib('Select/Unselect all');" onmouseout="return nd();"><input id="ckalldlexp$dbaccExpm{$id}{expid}" type="checkbox" name="ckalldlid" onclick="ckallexpmt(this,'ckdlaccn','ckdlexpm',$dbaccExpm{$id}{expid});" $ckaccn></th>\n},
				qq{<th class="thc">OUID</th>\n},
				qq{<th class="thc">EXPERIMENT NAME</th>\n},
				qq{<th class="thc">CHANNELS</th>\n},
				qq{<th class="thc">TIME POINT</th>\n},
				qq{<th class="thc">STD_DEV</th>\n},
				qq{<tr>\n};
			}
			
			if ($parms->{expmtid}) {
				#used what was checked, otherwise use value of checkall
				$ckaccn  = ($parms->{expmtid} and ( index( $parms->{expmtid}, $id ) >= 0 )) ? 'checked' : '';
			} 
			
			print qq{<tr bgcolor="#ebf0f2">\n},
			  qq{<td class="tdc"><input id="ckdlexpm$id" class="small" type="checkbox" name="ckdlexpm" value="$gdb::webUtil::frmData{id}:$id" onclick="ckexpmt(this,'ckdlaccn','ckalldlexp','$dbaccExpm{$id}{expid}');" $ckaccn></td>\n},
			  qq{<td class="tdc">$dbaccExpm{$id}{ouid}</td>\n},
			  qq{<td class="tdl">$dbaccExpm{$id}{expname}</td>\n},
			  qq{<td class="tdc">$dbaccExpm{$id}{channels}</td>\n},
			  qq{<td class="tdc">$dbaccExpm{$id}{timepoint}</td>\n},
			  qq{<td class="tdr">$dbaccExpm{$id}{std}</td>\n},
			  qq{</tr>\n};
		}
	}

	if ($hasExp) {
		print qq{<tr><td class="tdl" colspan="3">Recs: <b>$ExpmCount</b></td></tr>\n};
	} else {
		print qq{<tr><td class="tdl"> *** No Experiments! *** </td></tr>\n};
	}
	  
	print qq{</table>\n},
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n};	
}

#--------------------------------------------------------------------
# display all active accessions and all samples info
# input: none
# return: none
#----------------------------------------------------------------------
sub accsamples {
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $dbaccSamplesRef = gdb::oracle::dbaccSamplesInfo();	#all accessions and all samples
	my %accSamples  = %$dbaccSamplesRef;

	my ($dbexpSamplesRef, $expcntRef) = gdb::oracle::dbexpSamplesInfo();	#active accessions experiments and samples used
	my %expSamples = %$dbexpSamplesRef;
	my %expcnt  = %$expcntRef;

	#first pass thru filters strain from active accessions experiments
	my %adata;
	for my $acc ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } keys %expSamples ) {
		for my $samp ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } keys %{$expSamples{$acc}} ) {
			for my $exp ( sort { $a cmp $b } keys %{$expSamples{$acc}{$samp}} ) {
				
				my $expstrain = ($expSamples{$acc}{$samp}{$exp}) ? $expSamples{$acc}{$samp}{$exp} : '';
				next if ($expstrain !~ /$gdb::util::gnom{$parms->{genome}}{acc}/i);
				
				$adata{$acc}{$samp}{$exp} = $expstrain;
			}
		}
	}

	#second pass thru filters all active accessions with or without experiments
	my %bdata;
	my $sampCnt = 0;
	for my $i ( sort { $a <=> $b } keys %accSamples ) {
		if ($adata{$accSamples{$i}{accession}}) {
			$sampCnt++;
			$bdata{$i}{acc}      = $accSamples{$i}{accession};
			$bdata{$i}{title}    = $accSamples{$i}{expname};
			$bdata{$i}{sample}   = $accSamples{$i}{sample};
			$bdata{$i}{sampname} = $accSamples{$i}{sampname};
			$bdata{$i}{used}     = 0;
			
			if ($adata{$accSamples{$i}{accession}}{$accSamples{$i}{sample}}) {
				$bdata{$i}{used}     = 1;	#sample used
			}
		}else{
			#active accessions with no experiments
			my $accstrain = ($accSamples{$i}{strain}) ? $accSamples{$i}{strain} : '';
			$sampCnt++;
			$bdata{$i}{acc}      = $accSamples{$i}{accession};
			$bdata{$i}{title}    = $accSamples{$i}{expname};
			$bdata{$i}{sample}   = $accSamples{$i}{sample};
			$bdata{$i}{sampname} = $accSamples{$i}{sampname};
			$bdata{$i}{used}     = 0;
		}
		
	}

	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb">\n},
	  qq{<tr><th class="thc" colspan="2">GenExpDB Accession Samples</th></tr>\n},
	  qq{<tr>\n},
	  qq{<th class="thc">ACCESSION</th>\n},
	  qq{<th class="thl">TITLE<br>&nbsp;&nbsp;&nbsp; SAMPLE &nbsp;&nbsp;&nbsp; SAMPLE NAME</th>\n},
	  qq{</tr>\n};

	my (%cacc,%ctitle);
	my $acc = '';
	my $totexp = 0;
	my $exptot = 0;
	my $sused = 0;
	my $tsamp = 0;
	my $tused = 0;
	
	for my $i ( sort { $a <=> $b } keys %bdata ) {
		$cacc{$bdata{$i}{acc}}    = 1;
		$sused++ if $bdata{$i}{used};
		
		my $used = ($bdata{$i}{used}) ? '*&nbsp;'	: '&nbsp;&nbsp;';			
		
		if ($acc =~ /$bdata{$i}{acc}/) {
			$tsamp++;
			$tused++ if $bdata{$i}{used};
			print qq{<tr bgcolor="#ebf0f2">\n},
			  qq{<td class="tdl"></td>\n},
			  qq{<td class="tdl">&nbsp;&nbsp;&nbsp;&nbsp; $used $bdata{$i}{sample} &nbsp;&nbsp;&nbsp;&nbsp; $bdata{$i}{sampname}</td>\n},
			  qq{</tr>\n};			
		}else{
			if ( $acc ne '' ) {
				#end of accession, total line
				print qq{<tr bgcolor="#ebf0f2">\n},
				  qq{<td class="tdl"></td>\n},
				  qq{<td class="tdl">&nbsp;&nbsp; <b>Total:</b>&nbsp; Samples: <b>$tsamp</b>&nbsp;&nbsp; *Used: <b>$tused</b>&nbsp;&nbsp; Experiments: <b>$exptot</b></td>\n},
				  qq{</tr>\n},			
				  qq{<tr><th class="thc" colspan="2"></th></tr>\n};	
				  $tsamp = 0;		
				  $tused = 0;		
			}
			$acc = $bdata{$i}{acc};
			$exptot = ($expcnt{$acc}) ? $expcnt{$acc} : 0;
			$totexp += $exptot;
			
			$tsamp++;
			$tused++ if $bdata{$i}{used};
			print qq{<tr bgcolor="#ebf0f2">\n},
			  qq{<td class="tdl">$bdata{$i}{acc}</td>\n},
			  qq{<td class="tdl">$bdata{$i}{title}</td>\n},
			  qq{</tr>\n},		
			  qq{<tr bgcolor="#ebf0f2">\n},
			  qq{<td class="tdl"></td>\n},
			  qq{<td class="tdl">&nbsp;&nbsp;&nbsp;&nbsp; $used $bdata{$i}{sample} &nbsp;&nbsp;&nbsp;&nbsp; $bdata{$i}{sampname}</td>\n},
			  qq{</tr>\n};			
		}
	}
	#last total line
	print qq{<tr bgcolor="#ebf0f2">\n},
	  qq{<td class="tdl"></td>\n},
	  qq{<td class="tdl">&nbsp;&nbsp; <b>Total:</b>&nbsp; Samples: <b>$tsamp</b>&nbsp;&nbsp; *Used: <b>$tused</b>&nbsp;&nbsp; Experiments: <b>0</b></td>\n},
	  qq{</tr>\n},			
	  qq{<tr><th class="thc" colspan="2"></th></tr>\n};	

	my $accCnt = scalar keys %cacc;
	
	print
	  qq{<tr><th class="thl" colspan="2">Accessions: $accCnt &nbsp;&nbsp;&nbsp;&nbsp; Samples: $sampCnt &nbsp;&nbsp;&nbsp;&nbsp; Samples Used: $sused &nbsp;&nbsp;&nbsp;&nbsp; Experminets: $totexp</th></tr>\n},
	  qq{</table>\n},
	  qq{<tr>\n}, 
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td class="tdl"><a style="cursor:pointer;" onclick="window.scrollTo(0,0);">Back To Top</a></td>\n},
	  qq{</tr>\n}, 
	  qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};

}

#--------------------------------------------------------------------
# display all active samples used in experiments
# input: none
# return: none
#----------------------------------------------------------------------
sub expsamples {
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my ($dbexpSamplesRef, $expcntRef) = gdb::oracle::dbexpSamplesInfo();	#active accessions experiments and samples used
	my %expSamples = %$dbexpSamplesRef;
	my %expcnt  = %$expcntRef;

	#first pass thru filters strain
	my %data;
	for my $acc ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } keys %expSamples ) {
		for my $samp ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } keys %{$expSamples{$acc}} ) {
			for my $exp ( sort { $a cmp $b } keys %{$expSamples{$acc}{$samp}} ) {
				
				my $strain = ($expSamples{$acc}{$samp}{$exp}) ? $expSamples{$acc}{$samp}{$exp} : '';
				next if ($strain !~ /$gdb::util::gnom{$parms->{genome}}{acc}/i);
				
				$data{$acc}{$samp}{$exp} = $strain;
			}
		}
	}
	
	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb">\n},
	  qq{<tr><th class="thc" colspan="4">GenExpDB Experiment Samples</th></tr>\n},
	  qq{<tr>\n},
	  qq{<th class="thc">ACCESSION</th>\n},
	  qq{<th class="thc">SAMPLE</th>\n},
	  qq{<th class="thc">EXPNAME</th>\n},
	  qq{<th class="thc">GENOME</th>\n},
	  qq{</tr>\n};

	my $totexp = 0;
	my $exptot = 0;
	my (%cacc,%csamp,%cgen);
	for my $acc ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } keys %data ) {
		$exptot = ($expcnt{$acc}) ? $expcnt{$acc} : 0;
		$totexp += $exptot;
		for my $samp ( sort { substr( $a, 3 ) <=> substr( $b, 3 ) } keys %{$data{$acc}} ) {
			$csamp{$samp}=1;
			for my $exp ( sort { $a cmp $b } keys %{$data{$acc}{$samp}} ) {
				my $genome = $gdb::util::gnom{$gdb::util::gnomacc{$data{$acc}{$samp}{$exp}}}{sname};
				my $accname = ($cacc{$acc}) ? '' : $acc;	#print accession name only once
				$cacc{$acc}=1;
				$cgen{$genome}=1;
				
				print qq{<tr bgcolor="#ebf0f2">\n},
					 qq{<td class="tdl">$accname</td>\n},
					 qq{<td class="tdl">$samp</td>\n},
					 qq{<td class="tdl">$exp</td>\n},
					 qq{<td class="tdl">$genome</td>\n},
					 qq{</tr>\n};
			}
		}
	}

	my $accCnt = scalar keys %cacc;
	my $sampCnt = scalar keys %csamp;
	my $genCnt = scalar keys %cgen;
	
	print
	  qq{<tr><th class="thl" colspan="4">Accessions: $accCnt &nbsp;&nbsp;&nbsp;&nbsp; Samples: $sampCnt &nbsp;&nbsp;&nbsp;&nbsp; Experiments: $totexp &nbsp;&nbsp;&nbsp;&nbsp; Genomes: $genCnt</th></tr>\n},
	  qq{</table>\n},
	  qq{<tr>\n}, 
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td class="tdl"><a style="cursor:pointer;" onclick="window.scrollTo(0,0);">Back To Top</a></td>\n},
	  qq{</tr>\n}, 
	  qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
	
}

#--------------------------------------------------------------------
# display experiment genes / count
# input: none
# return: none
#----------------------------------------------------------------------
sub expgenes {
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $dbexpgenesRef = gdb::oracle::dbexpGenesInfo();

	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table>\n},
	  qq{<tr><th class="thc">GenExpDB Experiment Genes</th></tr>\n},
	  qq{<tr><td class="small">* click column heading to sort.</td></tr>\n},
	  qq{</table>\n},
	  qq{<table  class="sortable" id="expgenes"  cellpadding="1"  cellspacing="1">\n},
	  qq{<tr class="thc"><th>GENE</th><th>LOCUS TAG</th><th>EXPERIMENT COUNT</th></tr>\n};
	  
	my $ltagCnt = 0;
	for my $i ( sort { $a <=> $b } keys %$dbexpgenesRef ) {
		$ltagCnt++;
		print qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="tdc">$dbexpgenesRef->{$i}{gene}</td>\n},
		  qq{<td class="tdc">$dbexpgenesRef->{$i}{locustag}</td>\n},
		  qq{<td class="tdc">$dbexpgenesRef->{$i}{cnt}</td>\n},
		  qq{</tr>\n};
	}
	print
	  qq{<tfoot>\n},
	  qq{<tr class="thc"><td colspan="3">Locus Tags: <b>$ltagCnt</b></td></tr>\n},
	  qq{</tfoot>\n},
	  qq{</table>\n}, 
	  qq{<tr>\n}, 
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td class="tdl"><a style="cursor:pointer;" onclick="window.scrollTo(0,0);">Back To Top</a></td>\n},
	  qq{</tr>\n}, 
	  qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#--------------------------------------------------------------------
# display stats
# input: none
# return: none
#----------------------------------------------------------------------
sub stats {
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $dbstatsRef = gdb::oracle::dbstatsInfo();
	my %dbstats    = %$dbstatsRef;

	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb">\n},
	  qq{<tr>\n},
	  qq{<th class="thc" colspan="2">GenExpDB Statistics</th>\n},
	  qq{</tr>\n},

	  qq{<tr class="thc"><td>CATAGORY</td><td>TOTAL</td></tr>\n},
	
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl">Accessions</td><td class="tdr">$dbstats{accessions}</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl">Experiments</td><td class="tdr">$dbstats{experiments}</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl">Samples</td><td class="tdr">$dbstats{samples}</td></tr>\n},
	  qq{<tr bgcolor="#ebf0f2"><td class="tdl">Platforms</td><td class="tdr">$dbstats{platforms}</td></tr>\n},

	  qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}


1;   # return a true value
