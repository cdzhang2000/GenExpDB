#------------------------------------------------------------------------------------------
# FileName    : gdb/util.pm
#
# Description : Util
# Author      : jgrissom
# DateCreated : 24 Feb 2010
# Version     : 4.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package gdb::util;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

our $ServerName = "http://ec2-23-21-233-38.compute-1.amazonaws.com";
our $url        = "$ServerName/gdb";
our $webloc     = "/modperl/gdb";
our $urlpath    = "$ServerName$webloc";
#our $datapath   = "/genexpdb/geo/accessions";

our $datapath   = "/var/www/modperl/accessions";

our %gnom = (
	1  => { 'acc' => 'NC_000913', 'lname' => 'E. coli MG1655',           'sname' => 'MG1655' },
	2  => { 'acc' => 'NC_002655', 'lname' => 'E. coli EDL933 (O157:H7)', 'sname' => 'EDL933' },
	3  => { 'acc' => 'NC_002695', 'lname' => 'E. coli Sakai (O157:H7)',  'sname' => 'Sakai' },
	4  => { 'acc' => 'NC_004431', 'lname' => 'E. coli CFT073',           'sname' => 'CFT073' },
	5  => { 'acc' => 'NC_007946', 'lname' => 'E. coli UTI89',            'sname' => 'UTI89' },
	6  => { 'acc' => 'NC_003317', 'lname' => 'Brucella melitensis bv. 1 str. 16M, Chrom I',   'sname' => 'Brucella 16M Chrom I' },	
	7  => { 'acc' => 'NC_003318', 'lname' => 'Brucella melitensis bv. 1 str. 16M, Chrom II',   'sname' => 'Brucella 16M Chrom II' },
	8  => { 'acc' => 'NC_008769', 'lname' => 'Mycobacterium bovis BCG str. Pasteur 1173P2',   'sname' => 'Mycobacterium, 1173P2' },
	9  => { 'acc' => 'NC_008596', 'lname' => 'Mycobacterium smegmatis str. MC2 155',   'sname' => 'Mycobacterium, MC2 155' },
	10  => { 'acc' => 'NC_002677', 'lname' => 'Mycobacterium leprae TN',   'sname' => 'Mycobacterium leprae TN' },
	11  => { 'acc' => 'NC_000962', 'lname' => 'Mycobacterium tuberculosis H37Rv',   'sname' => 'Mycobacterium, H37Rv' },
	12  => { 'acc' => 'NC_002755', 'lname' => 'Mycobacterium tuberculosis CDC1551',   'sname' => 'Mycobacterium, CDC1551' }
);
our %gnomacc = ( "NC_000913", 1, "NC_002655", 2, "NC_002695", 3, "NC_004431", 4, "NC_007946", 5, "NC_003317",6, "NC_003318", 7);

#----------------------------------------------------------------------
# Main
# input: none
# return: none
#----------------------------------------------------------------------
sub mainMain {

	print qq{<form class="ftop" name="mainFrm" action="$url" method="POST">\n};
	heading();
	print qq{<div id="stat"></div>\n};

	if ( $gdb::webUtil::frmData{reset} ) {
		resetForm();
	}
	$gdb::webUtil::r->rflush;

	saveSettings() if ( $gdb::webUtil::frmData{savesettings} );

	saveCkaccn();

	siggenes() if ( $gdb::webUtil::frmData{siggenes} );

	if ( $gdb::webUtil::frmData{pcorr} ) {
		print qq{<script type="text/javascript">statbar('show');</script>\n};
		pcorr();
	} elsif ( $gdb::webUtil::frmData{selmfun} ) {
		mfun();
	} elsif ( $gdb::webUtil::frmData{qryannot} ) {
		qryannot();
	} else {
		query();
	}

	my $qryltagRef = gdb::webUtil::getSessVar( 'qryltag' );
	if ( $qryltagRef and $qryltagRef->{0} ) {
		gdb::browser::displayBrowser();
		gdb::annotation::displayAnnotation();
	}

	gdb::accessions::displayAccessions();

	print qq{</form>\n};
	print qq{<script type="text/javascript">document.mainFrm.query.focus();</script>\n};
}

#----------------------------------------------------------------------
# ajax call display info
# input: 
# return: none
#----------------------------------------------------------------------
sub ajax {
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	if ( $gdb::webUtil::frmData{ginfo} ) {
		settings()                     if ( $gdb::webUtil::frmData{ginfo} =~ /^settings/ );
		gdb::info::help()          if ( $gdb::webUtil::frmData{ginfo} =~ /^help/ );
		gdb::info::info()          if ( $gdb::webUtil::frmData{ginfo} =~ /^info/ );
		gdb::info::about()	    if ( $gdb::webUtil::frmData{ginfo} =~ /^about/ );
		gdb::info::platforms() if ( $gdb::webUtil::frmData{ginfo} =~ /^platforms/ );
		gdb::info::downloadAccessions( ) if ( $gdb::webUtil::frmData{ginfo} =~ /^downloadAccessions/ );
		gdb::info::showdlexpm() if ( $gdb::webUtil::frmData{ginfo} =~ /^showdlexpm/ );
		gdb::info::accsamples() if ( $gdb::webUtil::frmData{ginfo} =~ /^accsamples/ );
		gdb::info::expsamples() if ( $gdb::webUtil::frmData{ginfo} =~ /^expsamples/ );
		gdb::info::expgenes()   if ( $gdb::webUtil::frmData{ginfo} =~ /^expgenes/ );
		gdb::info::stats()      if ( $gdb::webUtil::frmData{ginfo} =~ /^stats/ );
		gdb::geoupdate::geoUpdateMain()      if ( $gdb::webUtil::frmData{ginfo} =~ /^geoupdt/ );

		gdb::browser::displayBrowser() if ( $gdb::webUtil::frmData{ginfo} =~ /^browser/ );
		gdb::annotation::displayAnnotation() if ( $gdb::webUtil::frmData{ginfo} =~ /^annotation/ );
		gdb::accessions::displayAccessions() if ( $gdb::webUtil::frmData{ginfo} =~ /^accessions/ );
		gdb::annotation::displayFullqry() if ( $gdb::webUtil::frmData{ginfo} =~ /^fullqry/ );
	}

	if ( $gdb::webUtil::frmData{geoupdt} ) {
		gdb::geoupdate::geoFetch()      if ( $gdb::webUtil::frmData{geoupdt} =~ /^update/ );
		gdb::geoupdate::editGeoRec()    if ( $gdb::webUtil::frmData{geoupdt} =~ /^geoedit/ );
		gdb::geoupdate::saveGeoRec()    if ( $gdb::webUtil::frmData{geoupdt} =~ /^geosave/ );
	}
	
	if ( $gdb::webUtil::frmData{supp} ) {
		gdb::annotation::genesInOperon() if ( $gdb::webUtil::frmData{supp} =~ /^operon/ );
		gdb::annotation::genesInRegulon() if ( $gdb::webUtil::frmData{supp} =~ /^regs/ );
		gdb::annotation::genesInSigma() if ( $gdb::webUtil::frmData{supp} =~ /^sigma/ );
		gdb::annotation::genesInMfun() if ( $gdb::webUtil::frmData{supp} =~ /^mfun/ );
		gdb::annotation::genesInPway() if ( $gdb::webUtil::frmData{supp} =~ /^pway/ );
	}

	if ( $gdb::webUtil::frmData{plot} ) {
		gdb::plot::scatterPlot() if ( $gdb::webUtil::frmData{plot} =~ /^splot/ );
		gdb::plot::linePlot() if ( $gdb::webUtil::frmData{plot} =~ /^lplot/ );
		gdb::plot::viewpdata() if ( $gdb::webUtil::frmData{plot} =~ /^pdata/ );
	}

	if ( $gdb::webUtil::frmData{accinfo} ) {
		gdb::accessions::accinfo() if ( $gdb::webUtil::frmData{accinfo} =~ /^accinfo/ );
		gdb::accessions::providers() if ( $gdb::webUtil::frmData{accinfo} =~ /^providers/ );
		gdb::accessions::summary() if ( $gdb::webUtil::frmData{accinfo} =~ /^summary/ );
		gdb::accessions::expdesign() if ( $gdb::webUtil::frmData{accinfo} =~ /^expdesign/ );
		gdb::accessions::arraydesign() if ( $gdb::webUtil::frmData{accinfo} =~ /^arraydesign/ );
		gdb::accessions::sampinfo() if ( $gdb::webUtil::frmData{accinfo} =~ /^sampinfo/ );
		gdb::accessions::sampdetail() if ( $gdb::webUtil::frmData{accinfo} =~ /^sampdetail/ );
		gdb::accessions::viewRawData() if ( $gdb::webUtil::frmData{accinfo} =~ /^viewRawData/ );
		gdb::accessions::expinfo('' ) if ( $gdb::webUtil::frmData{accinfo} =~ /^expinfo/ );
		gdb::accessions::updexperiment() if ( $gdb::webUtil::frmData{accinfo} =~ /^updexperiment/ );
		gdb::accessions::curated('' ) if ( $gdb::webUtil::frmData{accinfo} =~ /^curated/ );
		gdb::accessions::updcurated() if ( $gdb::webUtil::frmData{accinfo} =~ /^updcurated/ );
		gdb::accessions::expdata() if ( $gdb::webUtil::frmData{accinfo} =~ /^expdata/ );
		gdb::accessions::sel1Plot() if ( $gdb::webUtil::frmData{accinfo} =~ /^sel1Plot/ );
		gdb::accessions::sel2Plot() if ( $gdb::webUtil::frmData{accinfo} =~ /^sel2Plot/ );
		gdb::accessions::savExptoDB() if ( $gdb::webUtil::frmData{accinfo} =~ /^savExptoDB/ );
		gdb::accessions::viewPlotData() if ( $gdb::webUtil::frmData{accinfo} =~ /^viewPlotData/ );
		gdb::accessions::downloadAccessions() if ( $gdb::webUtil::frmData{accinfo} =~ /^downloadAccessions/ );
		gdb::accessions::accExperiments() if ( $gdb::webUtil::frmData{accinfo} =~ /^showexpm/ );
	}

	if ( $gdb::webUtil::frmData{mfun} ) {
		gdb::mfun::displayMultifun() if ( $gdb::webUtil::frmData{mfun} =~ /^open/ );
		if ( $gdb::webUtil::frmData{mfun} =~ /^qry/ ) {
			my ( $mfunQry, $qtypeRef ) = gdb::oracle::dbmfunQry( $gdb::webUtil::frmData{selmfun} );
			if (@$qtypeRef) {
				$parms->{lastquery} = $parms->{currquery};
				$parms->{lastqtype} = $parms->{currqtype};
				$parms->{currquery} = join( ', ', @$qtypeRef );
				$parms->{currqtype} = "MultiFun: $mfunQry";
				gdb::webUtil::putSessVar( 'parms', $parms );
			} else {
				print qq{<hr><div>MultiFun: <b>$mfunQry</b><font color="red"> no genes found!</font></div><br>\n};
			}
		}
	}

}

#----------------------------------------------------------------------
# Reset form
# input: none
# return: none
#----------------------------------------------------------------------
sub resetForm {
	gdb::webUtil::putSessVar( 'parms',      defaultParms() );
	gdb::webUtil::putSessVar( 'fullqry',    '' );
	gdb::webUtil::putSessVar( 'acchm',      '' );
	gdb::webUtil::putSessVar( 'savExpInfo', '' );
	gdb::webUtil::putSessVar( 'qryltag',    '' );
	%gdb::webUtil::frmData = ();
}

#----------------------------------------------------------------------
# initialize defaults
# input: none
# return: none
#----------------------------------------------------------------------
sub initDefaults {
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	if ( !$parms ) {
		gdb::webUtil::putSessVar( 'parms', defaultParms() );
	}
}

#----------------------------------------------------------------------
# Default Parms
# input: none
# return: hash
#----------------------------------------------------------------------
sub defaultParms {
	my %parms;
	
	$parms{genome}     = 1;      		#default public is 1=MG1655
	$parms{genrel}     = 'all';      	#related default public is all
	$parms{accnid}     = 0;     		#accessions checked
	$parms{expmtid}    = 0;     		#experiments checked
	$parms{wrap}       = 1;
	$parms{hmrows}     = 5;
	$parms{color}      = 1;
	$parms{dnum}       = 5;
	$parms{foldck}     = 0;
	$parms{dmaccfold}  = 0;
	$parms{dfold}      = 2;
	$parms{sigfold}    = 2;
	$parms{logck}      = 0;
	$parms{dmacclog}   = 0;
	$parms{dlog}       = 2;
	$parms{browser}    = 1;
	$parms{annotation} = 1;
	$parms{accessions} = 0;
	$parms{prows}      = 5;      		# pearson
	$parms{pdir}       = 1;
	$parms{lastquery}  = '';
	$parms{lastqtype}  = '';
	$parms{currquery}  = '';
	$parms{currqtype}  = '';
	$parms{experiment} = '';
	$parms{accsort}    = '';

	return \%parms;
}

#----------------------------------------------------------------------
# Heading
# input: none
# return: none
#----------------------------------------------------------------------
sub heading {

	print
	  qq{<div>\n},
	  qq{<a class="mnl" onclick="gm('home');" onmouseover="return overlib('Home / resets all settings and queries');" onmouseout="return nd();">Home</a>\n},
	  qq{<a class="mnl" onclick="gm('settings');" onmouseover="return overlib('Settings and analysis tools');" onmouseout="return nd();">Settings</a>\n},
	  qq{<a class="mnl" onclick="gm('info');" onmouseover="return overlib('Info / stats');" onmouseout="return nd();">Info</a>\n},
	  qq{<a class="mnl" onclick="gm('help');" onmouseover="return overlib('Help');" onmouseout="return nd();">Help</a>\n},
	  qq{</div>\n},

	  qq{<table align="center">\n},

	  qq{<tr>\n}, qq{<td class="hdln1">Welcome to the <em>E. coli</em> Gene Expression Database (GenExpDB)</td>\n}, qq{</tr>\n},

	  qq{<tr>\n}, qq{<td class="hdln2"><font color="red">Instructions:</font>&nbsp;&nbsp;Search by gene, locus or location (multiple entries separated by comma or space).</td>\n}, qq{</tr>\n},

	  qq{<tr>\n},
	  qq{<td class="hdln2"><font color="red">*To start:</font>&nbsp;&nbsp; enter query or select <font color="red">Example: </font>\n},
	  qq{<a class="exmp" onclick="ckqry('edd');" onmouseover="return overlib('Query for gene edd');" onmouseout="return nd();">edd</a> &bull; \n},
	  qq{<a class="exmp" onclick="ckqry('b3517');" onmouseover="return overlib('Query for locusTag b3517');" onmouseout="return nd();">b3517</a> &bull; \n},
	  qq{<a class="exmp" onclick="ckqry('laca,lacy,lacz');" onmouseover="return overlib('Query multiple genes');" onmouseout="return nd();">laca,lacy,lacz</a> &bull; \n},
	  qq{<a class="exmp" onclick="ckqry('416366');" onmouseover="return overlib('Query by genome location');" onmouseout="return nd();">416366 (location)</a>\n},

	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td class="hdln2"><font color="red">Search by: </font> \n},
qq{<span onmouseover="return overlib('Query returns all genes in operon');" onmouseout="return nd();"><input type="radio" id="operon" name="qtype" value="Operon" ondblclick="this.checked=false">Operon</span>\n},
qq{<span onmouseover="return overlib('Query by transcription factor gene, returns all target genes');" onmouseout="return nd();"><input type="radio" id="regulon" name="qtype" value="Regulon" ondblclick="this.checked=false">Regulon</span>\n},
qq{<span onmouseover="return overlib('Query by sigma factor gene, returns all target genes');" onmouseout="return nd();"><input type="radio" id="sigma" name="qtype" value="Sigma" ondblclick="this.checked=false">Sigma</span>\n},
qq{<span onmouseover="return overlib('Query genome annotation metadata');" onmouseout="return nd();"><input type="radio" id="annotqtype" name="qtype" value="Annotation" ondblclick="this.checked=false">Annotation</span>\n},
qq{<span onmouseover="return overlib('Query accession metadata');" onmouseout="return nd();"><input type="radio" id="experiment" name="qtype" value="Experiment" ondblclick="this.checked=false">Experiment</span>\n},
qq{<span onmouseover="return overlib('Query using MultiFunctions selections');" onmouseout="return nd();"><input type="radio" id="mfunck" value="MultiFun" onclick="smfun('open');">MultiFun</span>\n},
	  qq{</td>\n},
	  qq{</tr>\n},

	  qq{<tr>\n},
	  qq{<td class="tdc">\n},
	  qq{<input type="text" size="60" maxlength="1000" id="query" name="query" value="">\n},
	  qq{<input class="ebtn" type="button" value="Query" onclick="ckqry(document.getElementById('query').value);">\n},
	  qq{</td>\n},
	  qq{</tr>\n},
	  
	  qq{<tr>\n}, 
	  qq{<td class="hdln2">Reference Genome set to Ecoli MG1655.  Click }, 
	  qq{<a class="mnl" onclick="gm('settings');" onmouseover="return overlib('Settings and analysis tools');" onmouseout="return nd();">Settings</a>},
	  qq{to change annotation.</td>\n}, 
	  qq{</tr>\n},
	  
	  qq{</table>\n},
	  qq{<div class="hidden" id="ginfo" style="border-top:1px solid #C3CCD3;"></div>\n},
	  qq{<div class="hidden" id="mfun" style="border-top:1px solid #C3CCD3;"></div>\n},
	  qq{<input type="hidden" id="gmid" name="gmid" value="">\n};
}

#----------------------------------------------------------------------
# Settings
# input: none
# return: none
#----------------------------------------------------------------------
sub settings {
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $selwrap   = ( $parms->{wrap}      =~ /1/ ) ? 'checked' : '';
	my $selnowrap = ( $parms->{wrap}      =~ /2/ ) ? 'checked' : '';
	my $selblue   = ( $parms->{color}     =~ /1/ ) ? 'checked' : '';
	my $selred    = ( $parms->{color}     =~ /2/ ) ? 'checked' : '';
	my $selmulti  = ( $parms->{color}     =~ /3/ ) ? 'checked' : '';
	my $foldck    = ( $parms->{foldck}    =~ /1/ ) ? 'checked' : '';
	my $dmaccfold = ( $parms->{dmaccfold} =~ /1/ ) ? 'checked' : '';
	my $logck     = ( $parms->{logck}     =~ /1/ ) ? 'checked' : '';
	my $dmacclog  = ( $parms->{dmacclog}  =~ /1/ ) ? 'checked' : '';
	my $ptopck    = ( $parms->{pdir}      =~ /1/ ) ? 'checked' : '';
	my $pbotck    = ( $parms->{pdir}      =~ /2/ ) ? 'checked' : '';

	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('ginfo')" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb">\n},
	  qq{<tr>\n},
	  qq{<th class="thc">Preference Settings</th>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td class="tdl">&nbsp;&nbsp;&nbsp;<input class="ebtn" type="submit" name="savesettings" value="Save Settings"></td>\n},
	  qq{</tr>\n},

	  qq{<tr>\n}, qq{<td class="tdl">\n};

	#genome
	print
	  qq{<div class="stt">\n},
	  qq{<table width="100%" cellspacing="0" cellpadding="0" border="0">\n},
	  qq{<tr>\n},
	  qq{<td width="200" nowrap="">&nbsp;&nbsp;&nbsp;<b>Genome</b></td>\n},
	  qq{<td>},
	  qq{<table>},
	  qq{<tr><td class="tdc">Reference</td><td class="tdc">Related</td></tr>};

	my @gnom = split(/~/, $parms->{genrel});
	my %gnmck;
	foreach my $tmp (@gnom) {
		$gnmck{$tmp} = 'checked';
	}
	for my $i ( sort { $a <=> $b } keys %gnom ) {
		my $grsel;
		if ($parms->{genrel} =~ /all/) {
			$grsel = 'checked';
		}else{
			$grsel = ($gnmck{$i}) ? $gnmck{$i} : '';
		}
		
		my $gsel = '';
		if ( $parms->{genome} =~ /$i/ ) {
			$gsel = 'checked';
			$grsel = 'checked';		#check related with reference
		}

		print qq{<tr>\n};
		print qq{<td class="tdc"><input type="radio" id="genome$i" name="genome" value="$i" $gsel></td>\n};
		print qq{<td class="tdc"><input type="checkbox" id="genrel$i" name="genrel" value="$i" $grsel></td>\n};
		print qq{<td class="tdl">$gnom{$i}{lname}</td>\n};
		print qq{</tr>\n};
	}
	print
	  qq{</table>},
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n},
	  qq{</div>\n};

	print
	  qq{<div class="stt">\n},
	  qq{<table width="100%" cellspacing="0" cellpadding="0" border="0">\n},
	  qq{<tr>\n},
	  qq{<td width="200" nowrap="">&nbsp;&nbsp;&nbsp;<b>Heatmap Display Options</b></td>\n},
	  qq{<td>},
	  qq{<br/><input class="nsd" type="text" size="3" maxlength="3" id="dnum" name="dnum" value="$parms->{dnum}"> Max number of Genes (Heatmaps) displayed<br/><br/>\n},
	  qq{<input type="radio" id="wrap1" name="wrap" value="1" $selwrap>Wrap in <input class="nsd" type="text" size="2" maxlength="2" id="hmrows" name="hmrows" value="$parms->{hmrows}">rows},
	  qq{<br/><input type="radio" id="wrap2" name="wrap" value="2" $selnowrap>No wrap<br/><br/>\n},
	  qq{<input type="radio" id="color1" name="color" value="1" $selblue>&nbsp;&nbsp;<img alt="" src="$gdb::util::webloc/web/legendBlueYellow.png" border="0">&nbsp;&nbsp; Blue/Yellow<br/>\n},
	  qq{<input type="radio" id="color2" name="color" value="2" $selred>&nbsp;&nbsp;<img alt="" src="$gdb::util::webloc/web/legendRedGreen.png" border="0">&nbsp;&nbsp; Red/Green<br/>\n},
	  qq{<input type="radio" id="color3" name="color" value="3" $selmulti>&nbsp;&nbsp;<img alt="" src="$gdb::util::webloc/web/legendMulti.png" border="0">&nbsp;&nbsp; Multi<br/><br/>\n},
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n},
	  qq{</div>\n},

	  qq{<div class="stt">\n},
	  qq{<table width="100%" cellspacing="0" cellpadding="0" border="0">\n},
	  qq{<tr>\n},
	  qq{<td width="200" nowrap="">&nbsp;&nbsp;&nbsp;<b>Data Mining</b></td>\n},
	  qq{<td>},
	  qq{<table>\n},
	  qq{<tr height="40px">\n},
	  qq{<td width="700px">},
	  qq{<input type="checkbox" id="foldck" name="foldck" value="1" $foldck>},
	  qq{Filter results where value exceeds },
	  qq{<input class="nsd" type="text" size="4" maxlength="4" id="dfold" name="dfold" value="$parms->{dfold}">},
	  qq{ * StdDev of the mean of the ratios<br/>\n},
	  qq{</td>\n},
	  qq{<td><input type="checkbox" id="dmaccfold" name="dmaccfold" value="1" $dmaccfold>Display all accessions</td>\n},
	  qq{</tr>\n},
	  qq{<tr height="40px">\n},
	  qq{<td>},
	  qq{<input type="checkbox" id="logck" name="logck" value="1" $logck>},
	  qq{Filter ratios greater than absolute value of },
	  qq{<input class="nsd" type="text" size="4" maxlength="4" id="dlog" name="dlog" value="$parms->{dlog}">},
	  qq{</td>\n},
	  qq{<td><input type="checkbox" id="dmacclog" name="dmacclog" value="1" $dmacclog>Display all accessions</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n},
	  qq{</div>\n};

	if ( $parms->{currquery} ) {

		#pearson
		my $savgene = $parms->{currquery};
		$savgene =~ s/\*+//g;    #remove the '*'
		my @genes = split( /,/, $savgene );
		my $genescnt = @genes;
		print
		  qq{<hr><br/>},
qq{<input class="ebtn" type="submit" name="pcorr" value="Pearson Correlation" onmouseover="return overlib('Calculate Pearson Correlation for selected gene');" onmouseout="return nd();">  for gene  };
		if ( $genescnt == 1 ) {
			print qq{<input type="text" size="8" maxlength="8" name="pcorrgene" value="$genes[0]" style="text-align:right;">};
		} else {
			print qq{<select name="pcorrgene">\n};
			for my $gene (@genes) {
				print qq{<option value="$gene"><b>$gene</b></option>\n};
			}
			print qq{</select>\n};
			print qq{ (select gene)\n};
		}
		print qq{ &nbsp;&nbsp;&nbsp; Display <input type="radio" name="pdir" value="1" $ptopck>};
		print qq{Top&nbsp; /<input type="radio" name="pdir" value="2" $pbotck>Bottom &nbsp;&nbsp;};
		print qq{<input class="nsd" type="text" size="2" maxlength="2" id="prows" name="prows" value="$parms->{prows}"> genes};
		print qq{<br/><br/>\n};

		#Regulated genes
		print
		  qq{<hr><br/>},
		  qq{ <input type="checkbox" id="siggenes" name="siggenes" value="1">},
		  qq{List significantly regulated genes &nbsp;&nbsp;&nbsp; (List genes from all experiments where &nbsp; (DownReg)ratio &nbsp; < &nbsp; },
		  qq{<input class="nsd" type="text" size="4" maxlength="4" id="sigfold" name="sigfold" value="$parms->{sigfold}">},
		  qq{ * StdDev &nbsp; >= &nbsp; ratio(UpReg))},
		  qq{<br/><br/>\n};
	}

	print
	  qq{</td>\n}, qq{</tr>\n},

	  qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# save checked accessions from parsing web page
# input: none
# return: none
#----------------------------------------------------------------------
sub saveCkaccn {

	if ( $gdb::webUtil::frmData{ckaccn} ) {
		my $parms = gdb::webUtil::getSessVar( 'parms' );
		$parms->{accnid} = $gdb::webUtil::frmData{ckaccn};

		$parms->{expmtid} = $gdb::webUtil::frmData{ckexpm} if ( $gdb::webUtil::frmData{ckexpm} );
		gdb::webUtil::putSessVar( 'parms', $parms );
	}
}

#----------------------------------------------------------------------
# Save Settings
# input: none
# return: none
#----------------------------------------------------------------------
sub saveSettings {

	my $parms = gdb::webUtil::getSessVar( 'parms' );

	$parms->{genome}     = ( $gdb::webUtil::frmData{genome} )     ? $gdb::webUtil::frmData{genome}     : $parms->{genome};
	$parms->{genrel}     = $parms->{genome} if ! $gdb::webUtil::frmData{genrel};	#if no related set to reference
	$parms->{genrel}     = ( $gdb::webUtil::frmData{genrel} )     ? $gdb::webUtil::frmData{genrel}     : $parms->{genrel};
	$parms->{wrap}       = ( $gdb::webUtil::frmData{wrap} )       ? $gdb::webUtil::frmData{wrap}       : $parms->{wrap};
	$parms->{hmrows}     = ( $gdb::webUtil::frmData{hmrows} )     ? $gdb::webUtil::frmData{hmrows}     : $parms->{hmrows};
	$parms->{color}      = ( $gdb::webUtil::frmData{color} )      ? $gdb::webUtil::frmData{color}      : $parms->{color};
	$parms->{dnum}       = ( $gdb::webUtil::frmData{dnum} )       ? $gdb::webUtil::frmData{dnum}       : $parms->{dnum};
	$parms->{foldck}     = ( $gdb::webUtil::frmData{foldck} )     ? 1                    : 0;
	$parms->{dmaccfold}  = ( $gdb::webUtil::frmData{dmaccfold} )  ? 1                    : 0;
	$parms->{dfold}      = ( $gdb::webUtil::frmData{dfold} )      ? $gdb::webUtil::frmData{dfold}      : $parms->{dfold};
	$parms->{sigfold}    = ( $gdb::webUtil::frmData{sigfold} )    ? $gdb::webUtil::frmData{sigfold}    : $parms->{sigfold};
	$parms->{logck}      = ( $gdb::webUtil::frmData{logck} )      ? 1                    : 0;
	$parms->{dmacclog}   = ( $gdb::webUtil::frmData{dmacclog} )   ? 1                    : 0;
	$parms->{dlog}       = ( $gdb::webUtil::frmData{dlog} )       ? $gdb::webUtil::frmData{dlog}       : $parms->{dlog};
	$parms->{browser}    = ( $gdb::webUtil::frmData{browser} )    ? $gdb::webUtil::frmData{browser}    : $parms->{browser};
	$parms->{annotation} = ( $gdb::webUtil::frmData{annotation} ) ? $gdb::webUtil::frmData{annotation} : $parms->{annotation};
	$parms->{accessions} = ( $gdb::webUtil::frmData{accessions} ) ? $gdb::webUtil::frmData{accessions} : $parms->{accessions};
	$parms->{prows}      = ( $gdb::webUtil::frmData{prows} )      ? $gdb::webUtil::frmData{prows}      : $parms->{prows};
	$parms->{pdir}       = ( $gdb::webUtil::frmData{pdir} )       ? $gdb::webUtil::frmData{pdir}       : $parms->{pdir};

	$parms->{currquery} = ( $parms->{currquery} ) ? $parms->{currquery} : $parms->{lastquery};

	gdb::webUtil::putSessVar( 'parms', $parms );

}

#----------------------------------------------------------------------
# Query
# input: none
# return: none
#----------------------------------------------------------------------
sub query {

	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $rc = 0;
	if ( $gdb::webUtil::frmData{query} ) {
		$parms->{lastquery} = ( $parms->{currquery} ) ? $parms->{currquery} : '';
		$parms->{lastqtype} = ( $parms->{currqtype} ) ? $parms->{currqtype} : '';
		$parms->{currquery} = ( $gdb::webUtil::frmData{query} )     ? $gdb::webUtil::frmData{query}     : '';
		$parms->{currqtype} = ( $gdb::webUtil::frmData{qtype} )     ? $gdb::webUtil::frmData{qtype}     : '';

		$rc = 1;
		if ( $gdb::webUtil::frmData{qtype} ) {
			my $genomeacc = $gnom{ $parms->{genome} }{acc};

			my @newqry = gdb::heatmap::ckQryLoc( $parms->{currquery}, $genomeacc );
			my $qry = ( $gdb::webUtil::frmData{qtype} =~ /^Annotation|^Experiment/ ) ? $gdb::webUtil::frmData{query} : $newqry[0];

			my $qtypeRef = '';
			$qtypeRef = gdb::oracle::dbqryOperon($qry)     if ( $gdb::webUtil::frmData{qtype} =~ /^Operon/ );
			$qtypeRef = gdb::oracle::dbqryRegulon($qry)    if ( $gdb::webUtil::frmData{qtype} =~ /^Regulon/ );
			$qtypeRef = gdb::oracle::dbqrySigma($qry)      if ( $gdb::webUtil::frmData{qtype} =~ /^Sigma/ );
			$qtypeRef = gdb::oracle::dbqryAnnot($qry)      if ( $gdb::webUtil::frmData{qtype} =~ /^Annotation/ );
			$qtypeRef = gdb::oracle::dbqryExperiment($qry) if ( $gdb::webUtil::frmData{qtype} =~ /^Experiment/ );

			if (@$qtypeRef) {
				if ( $gdb::webUtil::frmData{qtype} =~ /^Experiment/ ) {
					$parms->{currquery}  = $parms->{lastquery};
					$parms->{accnid}     = join( ', ', @$qtypeRef );        #experiment IDs
					$parms->{currqtype}  = "";
					$parms->{experiment} = "Experiment: [ <b>$qry</b> ]";
				} else {
					$parms->{currquery} = join( ', ', @$qtypeRef );
					$parms->{currqtype} = "$gdb::webUtil::frmData{qtype}: [ <b>$qry</b> ]";
				}
			} else {
				$rc = 0;
				$parms->{currquery} = '';
				print "<pre>";
				print "Genome: $gnom{$parms->{genome}}{lname}\n";
				print "$parms->{currqtype}\n\n";
				print qq{<font color="red">No genes found!</font>\n};
				print "</pre>";
			}
		}
		gdb::webUtil::putSessVar( 'parms', $parms );
	} else {
		$rc = 1 if $parms->{currquery};
	}

	gdb::heatmap::heatmap(  ) if $rc;

}

#----------------------------------------------------------------------
# Multifun query
# input: none
# return: none
#----------------------------------------------------------------------
sub mfun {
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $rc = 0;
	my ( $mfunQry, $qtypeRef ) = gdb::oracle::dbmfunQry( $gdb::webUtil::frmData{selmfun} );
	if (@$qtypeRef) {
		$parms->{lastquery} = $parms->{currquery};
		$parms->{lastqtype} = $parms->{currqtype};
		$parms->{currquery} = join( ', ', @$qtypeRef );
		$parms->{currqtype} = "MultiFun: $mfunQry";
		$rc                 = 1;
	} else {
		$parms->{currquery} = '';
		print "<pre>";
		print "Genome: $gnom{$parms->{genome}}{lname}\n";
		print "Type: MultiFun: $mfunQry\n\n";
		print qq{<font color="red">No genes found!</font>\n};
		print "</pre>";
	}
	gdb::webUtil::putSessVar( 'parms', $parms );
	gdb::heatmap::heatmap() if $rc;
}

#----------------------------------------------------------------------
# Pearson Correlation
# input: none
# return: none
#----------------------------------------------------------------------
sub pcorr {

	my $parms = gdb::webUtil::getSessVar( 'parms' );

	$parms->{pdir}  = $gdb::webUtil::frmData{pdir}  if $gdb::webUtil::frmData{pdir};
	$parms->{prows} = $gdb::webUtil::frmData{prows} if $gdb::webUtil::frmData{prows};

	print qq{<script type="text/javascript">statbar('show');</script>\n};
	$gdb::webUtil::r->rflush;

	my $rc = 0;
	my ( $dbPCorrDataRef, $pcorr_orderRef ) = gdb::oracle::dbpearsonCorr();
	if (@$pcorr_orderRef) {
		$parms->{lastquery} = $parms->{currquery};
		$parms->{lastqtype} = $parms->{currqtype};
		my $dir   = ( $parms->{pdir} =~ /1/ )   ? "Top"            : "Bottom";
		my @pcorr = ( $dir           =~ /Top/ ) ? @$pcorr_orderRef : ( reverse(@$pcorr_orderRef) );
		$parms->{currquery} = join( ', ', @pcorr );
		$parms->{currqtype} = "PearsonCorr: [ $gdb::webUtil::frmData{pcorrgene} ] $dir";
		$rc                 = 1;
	} else {
		$parms->{currquery} = '';
		print "<pre>";
		print "Genome: $gnom{$parms->{genome}}{lname}\n";
		print "Type: PearsonCorr: $gdb::webUtil::frmData{pcorrgene}\n\n";
		print qq{<font color="red">No correlations found!</font>\n};
		print "</pre>";
	}
	gdb::webUtil::putSessVar( 'parms', $parms );
	gdb::heatmap::heatmap() if $rc;
}

#----------------------------------------------------------------------
# Annotation supplement query
# input: none
# return: none
#----------------------------------------------------------------------
sub qryannot {

	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $rc = 0;
	if ( $gdb::webUtil::frmData{qrySelected} ) {
		my @newqry = split( /~/, $gdb::webUtil::frmData{qrySelected} );
		$parms->{lastquery} = $parms->{currquery};
		$parms->{lastqtype} = $parms->{currqtype};
		$parms->{currquery} = join( ', ', @newqry );
		$parms->{currqtype} = $gdb::webUtil::frmData{annottype};
		$rc                 = 1;
	} else {
		$parms->{currquery} = '';
		print "<pre>";
		print "Genome: $gnom{$parms->{genome}}{lname}\n";
		print "Type: $gdb::webUtil::frmData{annottype}\n\n";
		print qq{<font color="red">No genes found!</font>\n};
		print "</pre>";
	}
	gdb::webUtil::putSessVar( 'parms', $parms );
	gdb::heatmap::heatmap() if $rc;
}

#----------------------------------------------------------------------
# List Significantly regulated genes
# input: none
# return: none
#----------------------------------------------------------------------
sub siggenes {

	my $parms = gdb::webUtil::getSessVar( 'parms' );
}

1;    # return a true value
