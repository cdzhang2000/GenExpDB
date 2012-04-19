#------------------------------------------------------------------------------------------
# FileName    : gdb/accessions.pm
#
# Description : Accessions
# Author      : jgrissom
# DateCreated : 1 Sep 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package testgdb::accessions;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use POSIX;
use List::Util qw(sum min max);

use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";

#this is another test

#----------------------------------------------------------------------
# Display Accessions
# input: none
# return: none
#----------------------------------------------------------------------
sub displayAccessions {

	my $parms = testgdb::webUtil::getSessVar( 'parms' );

	if ( $testgdb::webUtil::frmData{ginfo} and $testgdb::webUtil::frmData{ginfo} =~ /^accessions/ ) {
		#ajax call
		$parms->{accessions} = ( $parms->{accessions} ) ? 0 : 1;
		testgdb::webUtil::putSessVar( 'parms', $parms );
		accessions() if ( $parms->{accessions} );
	} else {
		if ( $parms->{accessions} ) {
			print qq{<div class="mn2" style="border-top:1px solid #C3CCD3;"><span onclick="da('accessions');" onmouseover="mm(this,'accessions');" onmouseout="return nd();"><img id="accessionssign" src="$testgdb::util::webloc/web/minus.gif" alt=""> Accessions</span></div>};
			print qq{<div class="showrec" id="accessions">};
			accessions();
			print qq{</div>\n};
		} else {
			print qq{<div class="mn2" style="border-top:1px solid #C3CCD3;"><span onclick="da('accessions');" onmouseover="mm(this,'accessions');" onmouseout="return nd();"><img id="accessionssign" src="$testgdb::util::webloc/web/plus.gif" alt=""> Accessions</span></div>};
			print qq{<div class="hidden" id="accessions"></div>\n};
		}
	}
}

#----------------------------------------------------------------------
# Display Accessions Info
# input: none
# return: none
#----------------------------------------------------------------------
my (%line, $col, $dir );	#used by sort function

sub accessions {

	my $parms        = testgdb::webUtil::getSessVar( 'parms' );

	my $acchmRef = testgdb::webUtil::getSessVar( 'acchm' );
	my %acchm = ();
	%acchm = %$acchmRef		if $acchmRef;

	my $dbAccessionRec = testgdb::oracle::dbAccessionsInfo();
	my %dbAccession    = %$dbAccessionRec;

	my $dbLabOrgRecRef = testgdb::oracle::dbLabOrganization();
	my %dbLabOrgRec    = %$dbLabOrgRecRef;

	my $dbExpmRefRecRef = testgdb::oracle::dbExpmReference();
	my %dbExpmRefRec    = %$dbExpmRefRecRef;

	my $dbExpmDesignRecRef = testgdb::oracle::dbExpmDesign();
	my %dbExpmDesignRec    = %$dbExpmDesignRecRef;

	my $dbPlatformDesignRecRef = testgdb::oracle::dbPlatformDesign();
	my %dbPlatformDesignRec    = %$dbPlatformDesignRecRef;


	if ($testgdb::webUtil::frmData{accsort}) {
		($col, $dir) = split( /:/, $testgdb::webUtil::frmData{accsort} );
	}else{
		($col, $dir) = split( /:/, $parms->{accsort} );
	}
	$col = ($col) ? $col : '';
	$dir = ($dir) ? $dir : 'R';
	$parms->{accsort} = "$col:$dir"  if $col;
	testgdb::webUtil::putSessVar( 'parms', $parms );
	
	my @exp = split(/~/, $parms->{expmtid});
	my %sexp;
	foreach my $tmp (@exp) {
		$sexp{$tmp} = 1;
	}
	
	my $allck = (exists $parms->{accnid}) ? 'checked' : '';

	my $accessionCount = 0;
	my $experimentCount = 0;
	my $totexpcnt = 0;
	my $tmp;
	my $tmpline = '';

	for my $i ( sort { $a <=> $b } keys %dbAccession ) {
		my $id = $dbAccession{$i}{id};

		if ( ( $parms->{experiment} =~ /^Experiment/ ) or $parms->{foldck} or $parms->{logck} ) {
			next if ( index( $parms->{accnid}, $id ) < 0 );
		}

		my $expGenomeRef = testgdb::oracle::dbexpcntbyAcc($id);
		my @expGenome = @$expGenomeRef;
		my $expCnt = 0;
		
		foreach my $genome (@expGenome) {
			#next if ($genome !~ /$testgdb::util::gnom{$parms->{genome}}{acc}/i);
			$expCnt++;
		}

		my $dbcolor = ($id =~ /111111/) ? '#e8e1e9' : '#ebf0f2';
		$line{$i}{tr} = qq{<tr id="accn$id" bgcolor="$dbcolor">\n};
		$accessionCount++;

		#checkbox
		my $checked = $allck;
		if (length($parms->{accnid})>1) {
			$checked  = ( index( $parms->{accnid}, $id ) < 0 ) ? '' : 'checked';
		}
		
		my $disabled = ( $expCnt > 0 ) ? ''        : 'disabled';

		$line{$i}{id} = $id;	#for hidden divs
		$line{$i}{cb} = qq{<td class="tdc"><input id="ckaccn$id" class="small" type="checkbox" name="ckaccn" value="$id" onclick="ckqry('$parms->{currquery}');" $checked $disabled></td>\n};

		#ACCESSION
		$tmpline = '';
		$tmpline .= qq{<td id="acc$id" class="tdl">};
		if ( $expCnt > 0 ) {
			$tmpline .= qq{<img id="esign$id" src="$testgdb::util::webloc/web/plus.gif" onclick="ckaccexp($id);" alt="" onmouseover="this.style.cursor='pointer';return overlib('click to display experiments');" onmouseout="return nd();"> };
		} else {
			$tmpline .= "&nbsp;&nbsp;&nbsp;&nbsp;";
		}
		$tmpline .= qq{<a href="http://www.ncbi.nlm.nih.gov/projects/geo/query/acc.cgi?acc=$dbAccession{$i}{accession}" target="_blank" onmouseover="return overlib('query this accession in Geo (new window)');" onmouseout="return nd();">$dbAccession{$i}{accession}</a>};
		$tmpline .= qq{</td>\n};
		$line{$i}{accession} = $tmpline;

		#Heatmap
		$tmpline = '';
		if ( $acchm{$id} ) {
			$tmpline .= qq{<td class="tdl">\n};
			$tmpline .= qq{<table cellpadding="0" cellspacing="0">\n};
			$tmpline .= qq{<tr height="18" style="cursor:default;">\n};

			my $ic = 0;
			for my $j ( sort { $a <=> $b } keys %{ $acchm{$id} } ) {
				$experimentCount++;
				
				if ( $ic > 20 ) {
					$tmpline .= qq{</tr>\n};
					$tmpline .= qq{<tr height="18" style="cursor:default;">\n};
					$ic = 0;
				}
				$tmpline .= qq{<td class="tdc" width="8" style="background-color:$acchm{$id}{$j}{ratioColor};" onclick="$acchm{$id}{$j}{click} window.scrollTo(0,0);" onmouseover="return overlib('$acchm{$id}{$j}{title}',WIDTH,400);" onmouseout="return nd();">$acchm{$id}{$j}{hm}</td>}
				  if $acchm{$id}{$j};
				$ic++;
			}
			$tmpline .= qq{</tr>\n};
			$tmpline .= qq{</table>\n};
			$tmpline .= qq{</td>\n};
		} else {
			$tmpline .= qq{<td>&nbsp;</td>\n};
		}
		$line{$i}{heatmap} = $tmpline;

		#EXPERIMENT COUNT
		$tmpline = '';
		$totexpcnt += $expCnt;
		if ( keys(%acchm) ) {
			my $disexp = keys %{ $acchm{$id} };
			my $scnt = ($expCnt) ? "$disexp/$expCnt" : 0;
			$tmpline .= qq{<td class="tdr">$scnt</td>\n};
		} else {
			$tmpline .= qq{<td class="tdc">$expCnt</td>\n};
		}
		$line{$i}{exps} = $tmpline;

		#INFO
		$line{$i}{info} = qq{<td class="tdc"><a onclick="accinfo('accinfo',$id);" onmouseover="this.style.cursor='pointer';return overlib('Accession Information');" onmouseout="return nd();">info</a></td>\n};

		#INSTITUTION_[PI]
		$tmpline = '';
		my $institution = ( $dbAccession{$i}{institution} ) ? $dbAccession{$i}{institution} : $dbLabOrgRec{ $dbAccession{$i}{eid} };
		$institution = ( $dbAccession{$i}{pi} ) ? "$institution [<b>$dbAccession{$i}{pi}</b>]" : $institution;
		if ( length($institution) > 70 ) {
			$tmp = substr $institution, 0, 67;
			$tmpline .= qq{<td class="tdl" onmouseover="return overlib('$institution');" onmouseout="return nd();">$tmp<b>...</b></td>\n};
		} else {
			$tmpline .= qq{<td class="tdl">$institution</td>\n};
		}
		$line{$i}{institution} = $tmpline;

		#REFERENCE
		my @pmA;
		@pmA = split( /,/, $dbExpmRefRec{$id} )	if $dbExpmRefRec{$id};			#get geo pubmed
		@pmA = split( /,/, $dbAccession{$i}{pmid} )	if $dbAccession{$i}{pmid};	#get curated pubmed
		@pmA = sort { $a <=> $b } @pmA;
		my $pubmed = join(',', @pmA);
		my $reference = ( $dbAccession{$i}{author} ) ? $dbAccession{$i}{author} . ', et al, ' : '';
		my $pmS = '';
		foreach my $pm (@pmA) {
			$pm =~ s/^\s//g;
			$pm =~ s/\s$//g;
			$pmS .= qq{<a href="http://www.ncbi.nlm.nih.gov/pubmed/$pm" target="_blank" onmouseover="return overlib('query PubMed (new window)');" onmouseout="return nd();">$pm</a>, };
		}
		$pmS =~ s/, $//;
		$reference = ($pubmed) ? $reference . $pmS : $reference;
		$line{$i}{reference} = qq{<td class="tdl">$reference</td>\n};

		#ACCESSION_TITLE
		$tmpline = '';
		my $title = ( $dbAccession{$i}{title} ) ? $dbAccession{$i}{title} : $dbAccession{$i}{name};
		if ( length($title) > 50 ) {
			$tmp = substr $title, 0, 47;
			$tmpline .= qq{<td class="tdl" onmouseover="return overlib('$title');" onmouseout="return nd();">$tmp<b>...</b></td>\n};
		} else {
			$tmpline .= qq{<td class="tdl">$title</td>\n};
		}
		$line{$i}{title} = $tmpline;

		#EXPERIMENT_DESIGN
		$tmpline = '';
		my $cdt    = ( $dbAccession{$i}{designtype} )   ? $dbAccession{$i}{designtype} . ';'   : '';
		my $cts    = ( $dbAccession{$i}{timeseries} )   ? $dbAccession{$i}{timeseries} . ';'   : '';
		my $ctm    = ( $dbAccession{$i}{treatment} )    ? $dbAccession{$i}{treatment} . ';'    : '';
		my $cgc    = ( $dbAccession{$i}{growthcond} )   ? $dbAccession{$i}{growthcond} . ';'   : '';
		my $cmd    = ( $dbAccession{$i}{modification} ) ? $dbAccession{$i}{modification} . ';' : '';
		my $ed     = $cdt . $cts . $ctm . $cgc . $cmd;
		my $dbd    = ( $dbExpmDesignRec{$id} )              ? $dbExpmDesignRec{$id}                    : '';
		my $design = ($ed)                                  ? $ed                                      : $dbd;
		$design =~ s/;$//;

		if ( length($design) > 40 ) {
			$tmp = substr $design, 0, 37;
			$tmpline .= qq{<td class="tdl" onmouseover="return overlib('$design');" onmouseout="return nd();">$tmp<b>...</b></td>\n};
		} else {
			$tmpline .= qq{<td class="tdl">$design</td>\n};
		}
		$line{$i}{experiment} = $tmpline;

		#ARRAY_DESIGN
		$tmpline = '';
		my $curArrDsgn = ( $dbAccession{$i}{arraydesign} )                 ? $dbAccession{$i}{arraydesign}                 : '';
		my $expArrDsgn = ( $dbPlatformDesignRec{ $dbAccession{$i}{eid} }{ad} ) ? $dbPlatformDesignRec{ $dbAccession{$i}{eid} }{ad} : '';
		my $arrDsgn    = ($curArrDsgn)                                         ? $curArrDsgn                                       : $expArrDsgn;
		if ( length($arrDsgn) > 40 ) {
			$tmp = substr $arrDsgn, 0, 37;
			$tmpline .= qq{<td class="tdl" onmouseover="return overlib('$arrDsgn');" onmouseout="return nd();">$tmp<b>...</b></td>\n};
		} else {
			$tmpline .= qq{<td class="tdl">$arrDsgn</td>\n};
		}
		$line{$i}{array} = $tmpline;

		#STRAIN
		my $strain = ( $dbAccession{$i}{strain} ) ? $dbAccession{$i}{strain} : '';
		my $substrain = ( $dbAccession{$i}{substrain} ) ? $dbAccession{$i}{substrain} : '';
		$strain = ($substrain) ? "$strain ($substrain)" : $strain;
		$line{$i}{genome} = qq{<td class="tdl">$strain</td>\n};
		
		
 	   	#czhang GEO matched organism 
        my $organism = ( $dbAccession{$i}{organism} ) ? $dbAccession{$i}{organism} : '';

       	#print "testing <pre>" . Dumper( $organism ) . "</pre>";
         
       	$line{$i}{organism} = qq{<td class="tdl">$organism</td>\n};


		#PLATFORM
		my $pfd  = ( $dbPlatformDesignRec{ $dbAccession{$i}{eid} }{gpl} ) ? $dbPlatformDesignRec{ $dbAccession{$i}{eid} }{gpl} : '';
		my $gplS = '';
		my @gplA = split( /,/, $pfd );
		foreach my $gpl (@gplA) {
			$gplS .= qq{<a href="http://www.ncbi.nlm.nih.gov/projects/geo/query/acc.cgi?acc=$gpl" target="_blank" onmouseover="return overlib('query this platform in Geo (new window)');" onmouseout="return nd();">$gpl</a>, };
		}
		$gplS =~ s/, $//;		
		$line{$i}{platform} = qq{<td class="tdl">$gplS</td>\n};
		
		
		#czhang added MODUSER
        my $moduser = ( $dbAccession{$i}{moduser} ) ? $dbAccession{$i}{moduser} : '';

       	#print "testing <pre>" . Dumper( $moduser ) . "</pre>";
         
       	$line{$i}{moduser} = qq{<td class="tdl">$moduser</td>\n};


	}
	
	my $arrow = ($dir =~ /F/) ? "sortRev" : "sortFor";
	my $accHead = ($col =~ /accession/) ? qq{ACCESSION<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "ACCESSION";
	my $expsHead = ($col =~ /exps/) ? qq{EXPS<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "EXPS";
	my $institutionHead = ($col =~ /institution/) ? qq{INSTITUTION_[PI]<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "INSTITUTION_[PI]";
	my $referenceHead = ($col =~ /reference/) ? qq{REFERENCE<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "REFERENCE";
	my $titleHead = ($col =~ /title/) ? qq{ACCESSION TITLE<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "ACCESSION TITLE";
	my $experimentHead = ($col =~ /experiment/) ? qq{EXPERIMENT DESIGN<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "EXPERIMENT DESIGN";
	my $arrayHead = ($col =~ /array/) ? qq{ARRAY DESIGN<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "ARRAY DESIGN";
	my $genomeHead = ($col =~ /genome/) ? qq{SAMPLE SOURCE<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "SAMPLE SOURCE";
	
	#czhang
	my $organismHead = ($col =~ /organism/) ? qq{ORGANISM<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "ORGANISM";	    
	#print "<pre>" . Dumper( $organismHead ) . "</pre>";
	    
	my $platformHead = ($col =~ /platform/) ? qq{PLATFORM<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "PLATFORM";
	
	#czhang
	my $moduserHead = ($col =~ /moduser/) ? qq{MODUSER<img id="accessionssort" src="$testgdb::util::webloc/web/$arrow.gif" alt="">} : "MODUSER";	    
	#print "<pre>" . Dumper( $organismHead ) . "</pre>";
	
	
	print 
	  qq{<table align="center" cellpadding="0" cellspacing="1">\n},
	  qq{<tr class="thc">\n},
	  qq{<th onmouseover="return overlib('Select/Unselect all');" onmouseout="return nd();"><input id="ckallaccid" type="checkbox" name="ckallaccid" onclick="ckall(this,'ckaccn');" $allck></th>\n},

	  qq{<th><span class="shc" onclick="sm('accession','$dir');" onmouseover="return overlib('GEO Accession ID, click to sort');" onmouseout="return nd();">$accHead</span></th>\n};

	print qq{<th onmouseover="return overlib('Heatmap for gene $parms->{currquery}');" onmouseout="return nd();">HEATMAP</th>\n} if ( keys(%acchm) );
	print
	  qq{<th><span class="shc" onclick="sm('exps','$dir');" onmouseover="return overlib('Experiment counts, click to sort');" onmouseout="return nd();">$expsHead</span></th>\n},
	  qq{<th>INFO</th>\n},
	  qq{<th><span class="shc" onclick="sm('institution','$dir');" onmouseover="return overlib('Institution and PI, click to sort');" onmouseout="return nd();">$institutionHead</span></th>\n},
	  qq{<th><span class="shc" onclick="sm('reference','$dir');" onmouseover="return overlib('Reference, click to sort');" onmouseout="return nd();">$referenceHead</span></th>\n},
	  qq{<th><span class="shc" onclick="sm('title','$dir');" onmouseover="return overlib('Accession title, click to sort');" onmouseout="return nd();">$titleHead</span></th>\n},
	  qq{<th><span class="shc" onclick="sm('experiment','$dir');" onmouseover="return overlib('Experiment design, click to sort');" onmouseout="return nd();">$experimentHead</span></th>\n},
	  qq{<th><span class="shc" onclick="sm('array','$dir');" onmouseover="return overlib('Array design, click to sort');" onmouseout="return nd();">$arrayHead</span></th>\n},
	  qq{<th><span class="shc" onclick="sm('genome','$dir');" onmouseover="return overlib('Genome, click to sort');" onmouseout="return nd();">$genomeHead</span></th>\n},
	  
	  #czhang
	  qq{<th><span class="shc" onclick="sm('organism','$dir');" onmouseover="return overlib('Organism, click to sort');" onmouseout="return nd();">$organismHead</span></th>\n},
	  
	  qq{<th><span class="shc" onclick="sm('platform','$dir');" onmouseover="return overlib('Platform, click to sort');" onmouseout="return nd();">$platformHead</span></th>\n},	
	 
	  #czhang
	  qq{<th><span class="shc" onclick="sm('moduser','$dir');" onmouseover="return overlib('Moduser, click to sort');" onmouseout="return nd();">$moduserHead</span></th>\n},
	 
	  qq{</tr>\n};
	
	
        #print "testing  <pre>" . Dumper( %dbAccession ) . "</pre>";
for my $i ( sort myColsort keys %line ) {
		print 
			$line{$i}{tr},
			$line{$i}{cb},
			$line{$i}{accession};	 
		print $line{$i}{heatmap} if ( keys(%acchm) );		 
		print 
			$line{$i}{exps},			
		 	$line{$i}{info},
		 	$line{$i}{institution},
		 	$line{$i}{reference},
		 	$line{$i}{title},
		 	$line{$i}{experiment},
			$line{$i}{array},
		 	$line{$i}{genome},
		 	
		 	#czhang
		 	$line{$i}{organism},
		 	
		 	$line{$i}{platform},
		 	
		 	#czhang
		 	$line{$i}{moduser},				
		 	
			qq{</tr>\n};
			 		
		#hidden experiments
		#if (index( $parms->{expmtid}, $line{$i}{id} ) >= 0) {	
		if ($sexp{$line{$i}{id}}) {	
			$testgdb::webUtil::frmData{id} = $line{$i}{id};
			$testgdb::webUtil::frmData{ckaccn} = 'true';
			print qq{<tr><td colspan="12"><div class="showrec" id="expmt$line{$i}{id}">};
			accExperiments();
			print qq{</div></td></tr>\n};
		} else {
			print qq{<tr><td colspan="12"><div class="hidden" id="expmt$line{$i}{id}"></div></td></tr>\n};
		}
		#hidden experiments info
		print qq{<tr><td colspan="12"><div class="hidden" id="accinfo$line{$i}{id}"></div></td></tr>\n};
	}	    
	print
		qq{<tr><td class="tdl" colspan="6">Accessions:<b>$accessionCount</b> &nbsp; Experiments:<b>$experimentCount / $totexpcnt</b></td></tr>\n},
		qq{<tr><td class="tdl" colspan="6"><a style="cursor:pointer;" onclick="window.scrollTo(0,0);">Back To Top</a></td></tr>\n},
		qq{</table>\n};
}

#----------------------------------------------------------------------
# Accessions sort (SPECIAL) function
# input: a & b
# return: ?
#----------------------------------------------------------------------
sub myColsort {
	my ($av, $bv);
	if ($col) {
		if ($dir =~ /F/) {
			$av = $line{$a}{$col};
			$bv = $line{$b}{$col};
		}else{
			$av = $line{$b}{$col};
			$bv = $line{$a}{$col};
		}
		
		$av =~ s/<.+?>//g;		#remove all tags
		$av =~ s/^\s+//;		#remove leading spaces
		$av =~ s/\s+$//;		#remove trailing spaces
		$av =~ s/\&nbsp\;//g;	#accession - remove the &nbsp;
		$av =~ s/.*\///g;		#exp - 2/8 - remove 2/
		
		$bv =~ s/<.+?>//g;
		$bv =~ s/^\s+//;
		$bv =~ s/\s+$//;
		$bv =~ s/\&nbsp\;//g;
		$bv =~ s/.*\///g;
		
		if ($col =~ /accession/) {
			substr( lc($av), 3 ) <=> substr( lc($bv), 3 );
		}elsif ($col =~ /platform/) {
			$av =~ s/^GPL|\,.+$//g;
			$bv =~ s/^GPL|\,.+$//g;
			lc($av) <=>  lc($bv);
		}elsif ($col =~ /exps/) {
			lc($av) <=>  lc($bv);
		}else{
			lc($av) cmp  lc($bv);
		}
	}else{
		$a <=> $b;
	}
}

#----------------------------------------------------------------------
# Display accession experiments
# input: none
# return: none
#----------------------------------------------------------------------
sub accExperiments {
	
	my $parms        = testgdb::webUtil::getSessVar( 'parms' );
	
	my $acchmRef = testgdb::webUtil::getSessVar( 'acchm' );
	my %acchm = ();
	%acchm = %$acchmRef		if $acchmRef;
	
	my ( $dbaccExpmRec, $expm_orderRef ) = testgdb::oracle::dbgetAccExpm();    #get all accession experiments so the OUID will be correct
	my %dbaccExpm  = %$dbaccExpmRec;
	my @expm_order = @$expm_orderRef;
	my $ExpmCount  = 0;
	my $hasExp     = 0;
	
	my $ckaccn = ( $testgdb::webUtil::frmData{ckaccn} =~ /true/ ) ? 'checked' : '';    #see if accession was checked
	
	print qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="ckaccexp($testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb" align="center">\n};
	  
	for my $id (@expm_order) {
		if ( $testgdb::webUtil::frmData{id} == $dbaccExpm{$id}{expid} ) {
			next if ($dbaccExpm{$id}{cntlgenome} !~ /$testgdb::util::gnom{$parms->{genome}}{acc}/i);
			
			$ExpmCount++;
			if ( !$hasExp ) {
				$hasExp = 1;
				print qq{<tr>\n},
				qq{<th class="thc" onmouseover="return overlib('Select/Unselect all');" onmouseout="return nd();"><input id="ckallexp$dbaccExpm{$id}{expid}" type="checkbox" name="ckallid" onclick="ckallexpmt(this,'ckaccn','ckexpm',$dbaccExpm{$id}{expid});ckqry('$parms->{currquery}');" $ckaccn></th>\n},
				qq{<th class="thc">OUID</th>\n},
				qq{<th class="thc">EXPERIMENT NAME</th>\n},
				qq{<th class="thc">CHANNELS</th>\n},
				qq{<th class="thc">TIME POINT</th>\n},
				qq{<th class="thc">STD_DEV</th>\n},
				qq{<th class="thc">PLATFORM</th>\n},
				qq{<th class="thc">TEST GENOME</th>\n},
				qq{<th class="thc">CNTL GENOME</th>\n},
				qq{<tr>\n};
			}
			
			if ($parms->{expmtid} and ( index( $parms->{expmtid}, $dbaccExpm{$id}{expid} ) >= 0 ) ) {
				$ckaccn  = ( index( $parms->{expmtid}, $id ) < 0 ) ? '' : 'checked';
			}
			
			my $testgenome = ($dbaccExpm{$id}{testgenome}) ? $testgdb::util::gnom{$testgdb::util::gnomacc{$dbaccExpm{$id}{testgenome}}}{sname} : '';
			my $cntlgenome = ($dbaccExpm{$id}{cntlgenome}) ? $testgdb::util::gnom{$testgdb::util::gnomacc{$dbaccExpm{$id}{cntlgenome}}}{sname} : '';
			
			print qq{<tr bgcolor="#ebf0f2">\n},
			  qq{<td class="tdc"><input id="ckexpm$id" class="small" type="checkbox" name="ckexpm" value="$testgdb::webUtil::frmData{id}:$id" onclick="ckexpmt(this,'ckaccn','ckallexp','$dbaccExpm{$id}{expid}');ckqry('$parms->{currquery}');" $ckaccn></td>\n},
			  qq{<td class="tdc">$dbaccExpm{$id}{ouid}</td>\n},
			  qq{<td class="tdl">$dbaccExpm{$id}{expname}</td>\n},
			  qq{<td class="tdc">$dbaccExpm{$id}{channels}</td>\n},
			  qq{<td class="tdc">$dbaccExpm{$id}{timepoint}</td>\n},
			  qq{<td class="tdr">$dbaccExpm{$id}{std}</td>\n},
			  qq{<td class="tdc">$dbaccExpm{$id}{platform}</td>\n},
			  qq{<td class="tdc">$testgenome</td>\n},
			  qq{<td class="tdc">$cntlgenome</td>\n},
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

#----------------------------------------------------------------------
# Display accession information menu bar
# input: none
# return: none
#----------------------------------------------------------------------
sub accinfo {

	my $row = testgdb::oracle::dbgetAccName( $testgdb::webUtil::frmData{id} );

	print
	  qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="accinfo('accinfo',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},

	  qq{<table class="tblb">\n}, 
	  qq{<tr>\n}, 
	  qq{<th class="thc" colspan="9">$row->{ACCESSION} Accession Information</th>\n}, 
	  qq{</tr>\n},

	  qq{<tr>\n},
	  qq{<td class="tdc">&nbsp; <a onclick="nd();accinfo('providers',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('Provider/Organization information');" onmouseout="return nd();">Providers</a> &nbsp; | &nbsp;</td>\n},
	  qq{<td class="tdc"><a onclick="nd();accinfo('summary',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('Summary information');" onmouseout="return nd();">Summary</a> &nbsp; | &nbsp;</td>\n},
	  qq{<td class="tdc"><a onclick="nd();accinfo('expdesign',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('Experiment Design information');" onmouseout="return nd();">Experiment Design</a> &nbsp; | &nbsp;</td>\n},
	  qq{<td class="tdc"><a onclick="nd();accinfo('arraydesign',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('Array Design information');" onmouseout="return nd();">Array Design</a> &nbsp; | &nbsp;</td>\n},
	  qq{<td class="tdc"><a onclick="nd();accinfo('sampinfo',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('Samples information');" onmouseout="return nd();">Samples</a> &nbsp; | &nbsp;</td>\n},
	  qq{<td class="tdc"><a onclick="nd();accinfo('expinfo',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('Experiments information');" onmouseout="return nd();">GenExpDB Experiments</a> &nbsp; | &nbsp;</td>\n};

	print
	  qq{<td class="tdc"><a onclick="nd();accinfo('curated',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('GenExpDB Curated Info');" onmouseout="return nd();">Curated</a> &nbsp; | &nbsp;</td>\n}
	  if ($testgdb::webUtil::useracclevel and $testgdb::webUtil::useracclevel > 2 );

	print
	  qq{<td class="tdc"><a onclick="nd();accinfo('expdata',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('Experiments Data');" onmouseout="return nd();">Data</a> &nbsp; | &nbsp;</td>\n},
	  qq{<td class="tdc"><a onclick="nd();gm('downloadAccessions',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('Download Experiment Data');" onmouseout="return nd();">Download</a> &nbsp;&nbsp;</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n},
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n},

	#hidden info
	  qq{<div class="hidden" id="providers$testgdb::webUtil::frmData{id}"></div>\n},
	  qq{<div class="hidden" id="summary$testgdb::webUtil::frmData{id}"></div>\n},
	  qq{<div class="hidden" id="expdesign$testgdb::webUtil::frmData{id}"></div>\n},
	  qq{<div class="hidden" id="arraydesign$testgdb::webUtil::frmData{id}"></div>\n},
	  qq{<div class="hidden" id="sampinfo$testgdb::webUtil::frmData{id}"></div>\n},
	  qq{<div class="hidden" id="expinfo$testgdb::webUtil::frmData{id}"></div>\n},
	  qq{<div class="hidden" id="curated$testgdb::webUtil::frmData{id}"></div>\n},
	  qq{<div class="hidden" id="expdata$testgdb::webUtil::frmData{id}"></div>\n};
}

#----------------------------------------------------------------------
# Display providers
# input: none
# return: none
#----------------------------------------------------------------------
sub providers {

	my $dbexpProvidersRef = testgdb::oracle::dbexpProviders( $testgdb::webUtil::frmData{id} );
	my %dbexpProviders    = %$dbexpProvidersRef;

	print qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
qq{<td valign="top"><a class="exmp" onclick="accinfo('providers',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb" align="center">\n},
	  qq{<tr>\n}, qq{<th class="thc" colspan="2">PROVIDERS</th>\n}, qq{</tr>\n},
	  qq{<tr bgcolor="#ebf0f2">\n},
	  qq{<td class="thl">Organization</td>\n},
	  qq{<td class="tdl">$dbexpProviders{organization}</td>\n},
	  qq{</tr>\n},
	  qq{<tr bgcolor="#ebf0f2">\n},
	  qq{<td class="thl">Providers</td>\n},
	  qq{<td class="tdl">$dbexpProviders{providers}</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n},
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n};
}

#----------------------------------------------------------------------
# Display summary
# input: none
# return: none
#----------------------------------------------------------------------
sub summary {

	my $dbexpSummaryRef = testgdb::oracle::dbexpSummary( $testgdb::webUtil::frmData{id} );
	my %dbexpSummary    = %$dbexpSummaryRef;

	print qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
qq{<td valign="top"><a class="exmp" onclick="accinfo('summary',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb" align="center">\n},
	  qq{<tr>\n},
	  qq{<td class="thl" colspan="2">SUMMARY</th>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td colspan="2">\n},

	  qq{<table>\n}, qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="tdl" colspan="2">$dbexpSummary{0}{summary}</td>\n}, qq{</tr>\n}, qq{</table>\n}, qq{<table>\n};
	for my $id ( sort { $a <=> $b } keys %$dbexpSummaryRef ) {
		next if $id == 0;
		for my $name ( keys %{ $dbexpSummaryRef->{$id} } ) {
			print qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="thl">$name</th>\n}, qq{<td class="tdl">$dbexpSummary{$id}{$name}</td>\n}, qq{</tr>\n};
		}
	}
	print
	  qq{</table>\n},
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n},
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n};
}

#----------------------------------------------------------------------
# Display expdesign
# input: none
# return: none
#----------------------------------------------------------------------
sub expdesign {

	my $dbexpDesignRef = testgdb::oracle::dbexpDesign( $testgdb::webUtil::frmData{id} );
	my %dbexpDesign    = %$dbexpDesignRef;

	print qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
qq{<td valign="top"><a class="exmp" onclick="accinfo('expdesign',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb" align="center">\n},
	  qq{<tr>\n}, qq{<th class="thc" colspan="2">EXPERIMENT DESIGN</th>\n}, qq{</tr>\n};
	for my $id ( sort keys %dbexpDesign ) {
		print qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="thl">$id</td>\n}, qq{<td class="tdl">$dbexpDesign{$id}</td>\n}, qq{</tr>\n};
	}
	print qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# Display arraydesign
# input: none
# return: none
#----------------------------------------------------------------------
sub arraydesign {

	my $dbarrayDesignRef = testgdb::oracle::dbarrayDesign( $testgdb::webUtil::frmData{id} );
	my %dbarrayDesign    = %$dbarrayDesignRef;
	my $adCnt            = scalar keys %dbarrayDesign;

	my $i = 0;
	print qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
qq{<td valign="top"><a class="exmp" onclick="accinfo('arraydesign',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb" align="center">\n},
	  qq{<tr>\n}, qq{<th class="thc" colspan="2">ARRAY DESIGN</th>\n}, qq{</tr>\n};
	for my $gpl ( sort keys %dbarrayDesign ) {
		print qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="thl">$gpl</td>\n},
		  qq{<td class="tdl">$dbarrayDesign{$gpl}{platform}</td>\n},
		  qq{</tr>\n},
		  qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="thl">Number of Features</td>\n},
		  qq{<td class="tdl">$dbarrayDesign{$gpl}{numf}</td>\n},
		  qq{</tr>\n},
		  qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="thl">Description</td>\n},
		  qq{<td class="tdl">$dbarrayDesign{$gpl}{desc}</td>\n},
		  qq{</tr>\n};
		for my $name ( sort keys %{ $dbarrayDesignRef->{$gpl}{parm} } ) {
			print qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="thl">$name</td>\n}, qq{<td class="tdl">$dbarrayDesign{$gpl}{parm}{$name}</td>\n}, qq{</tr>\n},;
		}
		$i++;
		if ( $adCnt > $i ) {
			print qq{<tr bgcolor="#ebf0f2">\n}, qq{<td colspan="2"><hr></td>\n}, qq{</tr>\n},;
		}
	}
	print qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# Display sampinfo
# input: none
# return: none
#----------------------------------------------------------------------
sub sampinfo {

	my $dbsampInfoRef = testgdb::oracle::dbsampInfo( $testgdb::webUtil::frmData{id} );
	my %dbsampInfo    = %$dbsampInfoRef;
	my $sampCnt       = scalar keys %dbsampInfo;

	my $numcols = 3;
	my $numrows = ceil( $sampCnt / $numcols );
	my $col     = 0;
	my $row     = 0;
	my %colsamp;
	for my $i ( sort { $a <=> $b } keys %dbsampInfo ) {
		$colsamp{$col}{$row} = $i;
		$col++;
		if ( $col >= $numrows ) {
			$col = 0;
			$row++;
		}
	}

	my $hcols = scalar keys %{ $colsamp{0} } if %{ $colsamp{0} };
	my $spancol = $hcols * 5;

	print qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
qq{<td valign="top"><a class="exmp" onclick="accinfo('sampinfo',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb" align="center">\n},
	  qq{<tr>\n}, qq{<th class="thc" colspan="$spancol">SAMPLES</th>\n}, qq{</tr>\n},
	  qq{<tr>\n};
	for ( my $i = 0 ; $i < $hcols ; $i++ ) {
		print qq{<th class="thc">ID</th>\n}, qq{<th class="thc">PLATFORM</th>\n}, qq{<th class="thc">SAMPLE NAME</th>\n}, qq{<th class="thc">RAW DATA</th>\n}, qq{<th width="3"></th>\n};
	}
	print qq{</tr>\n};
	my $i = 0;
	for my $col ( sort { $a <=> $b } keys %colsamp ) {
		print qq{<tr>\n};
		for my $row ( sort { $a <=> $b } keys %{ $colsamp{$col} } ) {
			print
qq{<td class="tdc" bgcolor="#ebf0f2"><a onclick="nd();sampdetail('sampdetail$i$testgdb::webUtil::frmData{id}','$dbsampInfo{$colsamp{$col}{$row}}{bioassays_id}');" onmouseover="this.style.cursor='pointer';return overlib('Sample details');" onmouseout="return nd();">$dbsampInfo{$colsamp{$col}{$row}}{samid}</a></td>\n},
			  qq{<td class="tdc" bgcolor="#ebf0f2">$dbsampInfo{$colsamp{$col}{$row}}{gpl}</td>\n},
			  qq{<td class="tdl" bgcolor="#ebf0f2">$dbsampInfo{$colsamp{$col}{$row}}{samname}</td>\n},
qq{<td class="tdc" bgcolor="#ebf0f2"><a onclick="window.open('$ENV{REQUEST_URI}?ajax=accinfo&accinfo=viewRawData&view=$dbsampInfo{$colsamp{$col}{$row}}{fname}&accession=$dbsampInfo{$colsamp{$col}{$row}}{accession}&sname=$dbsampInfo{$colsamp{$col}{$row}}{samid}&id=$dbsampInfo{$colsamp{$col}{$row}}{bioassays_id}', '_blank')" onmouseover="this.style.cursor='pointer';return overlib('View raw data (new window)');" onmouseout="return nd();">view</a></td>\n},
			  qq{<td width="3"></td>\n};
		}
		print qq{</tr>\n};

		print qq{<tr><td colspan="$spancol"><div class="hidden" id="sampdetail$i$testgdb::webUtil::frmData{id}"></div></td></tr>\n};
		$i++;
	}
	print qq{<tr><td class="tdl">Recs: <b>$sampCnt</b></td></tr>\n};

	print qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# Display Sample Info
# input: none
# return: none
#----------------------------------------------------------------------
sub sampdetail {

	my ( $sampIDname, $dbsampDetailRef ) = testgdb::oracle::dbsampDetail( $testgdb::webUtil::frmData{sampID} );
	my %dbsampDetail         = %$dbsampDetailRef;
	my $dbsampDescriptionRef = testgdb::oracle::dbsampDescription( $testgdb::webUtil::frmData{sampID} );
	my %dbsampDescription    = %$dbsampDescriptionRef;

	print qq{<table cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="sh('$testgdb::webUtil::frmData{id}');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},

	  qq{<table class="tblb">\n}, qq{<tr>\n}, qq{<th class="thc" colspan="3">$sampIDname &nbsp;SAMPLE DETAILS</th>\n}, qq{</tr>\n};

	for my $name ( sort keys %dbsampDetail ) {
		print qq{<tr>\n}, qq{<th class="thl">$name</th>\n};
		for my $channel ( sort keys %{ $dbsampDetail{$name} } ) {
			print qq{<td class="tdl" bgcolor="#ebf0f2">$dbsampDetail{$name}{$channel}</td>\n};
		}
		print qq{</tr>\n};
	}

	print qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};

}

#----------------------------------------------------------------------
# Display Sample raw data in new window
# input: none
# return: none
#----------------------------------------------------------------------
sub viewRawData {

	my $opened = open( FILE, "$testgdb::util::datapath/$testgdb::webUtil::frmData{accession}/$testgdb::webUtil::frmData{view}" );

	print qq{<html><head><title>$testgdb::webUtil::frmData{sname} Raw Data</title>\n},
	  qq{<script type="text/javascript" src="/web/js/overlib/Mini/overlib_mini.js"></script><!-- overLIB (c) Erik Bosrup -->\n},
	  qq{<link rel="stylesheet" type="text/css" href="/web/css/main.css">\n},
	  qq{</head><body>\n};

	if ($opened) {
		my @data = <FILE>;
		close(FILE);
		my $rec     = @data;
		my $dispnum = 30;
		my $full    = ( $testgdb::webUtil::frmData{full} ) ? 1 : 0;

		my ($labelRef) = testgdb::oracle::dbsampFilehead( $testgdb::webUtil::frmData{id} );
		my %label = %$labelRef;

		print qq{<pre>\n}, qq{Accession: <b>$testgdb::webUtil::frmData{accession}</b>\tSample: <b>$testgdb::webUtil::frmData{sname}</b>\n}, qq{Rows: <b>$rec</b>};

		if ($full) {
			print qq{\n};
		} else {
			print qq{\t**Displaying $dispnum rows\t},
qq{<input class="ebtn" type="button" value="View full table" onclick="window.location.href='$testgdb::util::url/?ajax=accinfo&accinfo=viewRawData&view=$testgdb::webUtil::frmData{view}&accession=$testgdb::webUtil::frmData{accession}&sname=$testgdb::webUtil::frmData{sname}&id=$testgdb::webUtil::frmData{id}&full=1'">\n};
		}

		print qq{</pre>\n}, qq{<table class="sortable" cellpadding="1"  cellspacing="1">\n}, qq{<tr class="thc">\n}, qq{<th>COL</th>\n}, qq{<th>LABEL</th>\n}, qq{<th>DESCRIPTION</th>\n}, qq{</tr>\n};

		my ( @col, @desc ) = ();
		for my $pos ( sort { $a <=> $b } keys %label ) {
			my $cname = '';
			my $cdesc = '';
			for my $name ( sort { $b cmp $a } keys %{ $label{$pos} } ) {
				$cname = $label{$pos}{$name} if $name =~ /name/;
				$cdesc = $label{$pos}{$name} if $name =~ /description/;
			}
			push @col,  $cname;
			push @desc, $cdesc;
			print qq{<tr bgcolor="#EBF0F2">\n}, qq{<td class="tdc">$pos</td>\n}, qq{<td class="tdl">$cname</td>\n}, qq{<td class="tdl">$cdesc</td>\n}, qq{</tr>\n};
		}
		print qq{</table>\n}, qq{<br>\n}, qq{<table class="sortable" cellpadding="1"  cellspacing="1">\n}, qq{<tr class="thc">\n};
		my $i = 0;
		foreach my $head (@col) {
			my $desc = ( $desc[$i] ) ? qq{onmouseover="this.style.cursor='pointer';return overlib('$desc[$i]');" onmouseout="return nd();"} : '';
			print qq{<th $desc>$head</th>\n};
			$i++;
		}
		print qq{</tr>\n};

		$i = 1;
		foreach my $line (@data) {
			chop($line);
			my @rawline = split( /\t/, $line );

			print qq{<tr bgcolor="#EBF0F2">\n};
			#we have x-num columns, but we may not have data for each column, so cycle thru each column
			for my $j (0 .. $#col ) {
				my $cv = ($rawline[$j]) ? $rawline[$j] : '';
				my $lr = ( $j == 0 ) ? 'tdl' : 'tdr';
				print qq{<td class="$lr">$cv</td>\n};
			}
			print qq{</tr>\n};
			$i++;
			last if ( !$full and $i > $dispnum );
		}
	} else {
		print qq{\n\t<font color="red">ERROR: Problem with Sample file!!</font>  Please contact system administrator.\n};    #could not open file
	}
	print qq{</body></html>\n};
}

#----------------------------------------------------------------------
# Display expinfo
# input: status
# return: none
#----------------------------------------------------------------------
sub expinfo {
	my ( $status ) = @_;

	my $parms        = testgdb::webUtil::getSessVar( 'parms' );

	my ( $dbExpmRef, $expmorderRef ) = testgdb::oracle::dbgetExpmInfo();    #all experiments, needed for ouid
	my %dbExpm = %$dbExpmRef;

	my $expid        = $testgdb::webUtil::frmData{id};
	
	my $dbexpInfoRef = testgdb::oracle::dbexpInfo($expid);
	my %dbexpInfo    = %$dbexpInfoRef;
	my $expCnt       = scalar keys %dbexpInfo;

	print qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
qq{<td valign="top"><a class="exmp" onclick="accinfo('expinfo',$testgdb::webUtil::frmData{id});" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n}, qq{<th class="thc" colspan="2">GENEXPDB EXPERIMENTS</th>\n}, qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td>\n};

	print qq{<table cellspacing="1" cellpadding="1">\n};
	print qq{<tr><td class="tdc" colspan="3"><input class="ebtn" type="button" value="Update" onclick="updexperiment($expid,this.form)"></td><td class="small">$status</td></tr>\n}
	  if ( $expCnt > 0 and $testgdb::webUtil::useracclevel > 2 );
	  
	print qq{<tr bgcolor="#ebf0f2">\n}, qq{<th class="thc">OUID</th>\n};
	print qq{<th class="thc">DELETE</th>\n} if ( $testgdb::webUtil::useracclevel > 2 );
	print qq{<th class="thc">ORDER</th>\n}  if ( $testgdb::webUtil::useracclevel > 2 );
	print qq{<th class="thc">EXPERIMENT NAME</th>\n},
	  qq{<th class="thc">SAMPLES</th>\n},
	  qq{<th class="thc">TIMEPOINT</th>\n},
	  qq{<th class="thc">CHANNELS</th>\n},
	  qq{<th class="thc">TEST COL</th>\n},
	  qq{<th class="thc">TEST BKGD</th>\n},
	  qq{<th class="thc">CNTL COL</th>\n},
	  qq{<th class="thc">CNTL BKGD</th>\n},
	  qq{<th class="thc">LOG</th>\n},
	  qq{<th class="thc">NORM</th>\n},
	  qq{<th class="thc">ANTILOG</th>\n},
	  qq{<th class="thc">RMA DATA</th>\n},
	  qq{<th class="thc">STDDEV</th>\n},
	  qq{<th class="thc">PLATFORM</th>\n},
	  qq{<th class="thc">TESTGENOME</th>\n},
	  qq{<th class="thc">CNTLGENOME</th>\n};

	if ( $testgdb::webUtil::useracclevel > 2 ) {
		print qq{<th class="thc">ADDUSER</th>\n}, qq{<th class="thc">ADDDATE</th>\n}, qq{<th class="thc">MODUSER</th>\n}, qq{<th class="thc">MODDATE</th>\n};
	}
	print qq{</tr>\n};

	for my $id ( sort { $a <=> $b } keys %dbexpInfo ) {
		my $expmID = $dbexpInfo{$id}{id};
		
		#next if ($dbexpInfo{$id}{cntlgenome} !~ /$testgdb::util::gnom{$parms->{genome}}{acc}/i);

		my $dbcolumnNameRef = testgdb::oracle::dbcolumnName( $dbexpInfo{$id}{samples} );    #get all columns for this sample
		my %dbcolumnName    = %$dbcolumnNameRef;

		my $testcolumn    = ( $dbcolumnName{ $dbexpInfo{$id}{testcolumn} } )    ? $dbcolumnName{ $dbexpInfo{$id}{testcolumn} }    : '';
		my $testbkgd      = ( $dbcolumnName{ $dbexpInfo{$id}{testbkgd} } )      ? $dbcolumnName{ $dbexpInfo{$id}{testbkgd} }      : '';
		my $testgenome    = ($dbexpInfo{$id}{testgenome}) ? $testgdb::util::gnom{$testgdb::util::gnomacc{$dbexpInfo{$id}{testgenome}}}{sname} : '';
		my $controlcolumn = ( $dbcolumnName{ $dbexpInfo{$id}{controlcolumn} } ) ? $dbcolumnName{ $dbexpInfo{$id}{controlcolumn} } : '';
		my $cntlbkgd      = ( $dbcolumnName{ $dbexpInfo{$id}{cntlbkgd} } )      ? $dbcolumnName{ $dbexpInfo{$id}{cntlbkgd} }      : '';
		my $cntlgenome    = ($dbexpInfo{$id}{cntlgenome}) ? $testgdb::util::gnom{$testgdb::util::gnomacc{$dbexpInfo{$id}{cntlgenome}}}{sname} : '';

		print qq{<tr bgcolor="#ebf0f2">\n}, qq{<td class="tdc">$dbExpm{$expmID}{ouid}</td>\n};
		print qq{<td class="tdc"><input type="checkbox" name="deleteExp$expid$expmID" value="1"></td>\n}                                                          if ( $testgdb::webUtil::useracclevel > 2 );
		print qq{<td class="tdc"><input class="tdr" type="text" size="3" maxlength="3" name="chgexporder$expid$expmID" value="$dbexpInfo{$id}{exporder}"></td>\n} if ( $testgdb::webUtil::useracclevel > 2 );

		if ( $testgdb::webUtil::useracclevel > 2 ) {
			print qq{<td class="tdl"><input class="tdl" type="text" size="80" maxlength="250" name="chgExpName$expid$expmID" value="$dbexpInfo{$id}{expname}"></td>\n};
		} else {
			print qq{<td class="tdl">$dbexpInfo{$id}{expname}</td>\n};
		}

		print qq{<td class="tdl">$dbexpInfo{$id}{samples}</td>\n};

		if ( $testgdb::webUtil::useracclevel > 2 ) {
			print qq{<td class="tdc"><input class="tdr" type="text" size="5" maxlength="9" name="chgtimepoint$expid$expmID" value="$dbexpInfo{$id}{timepoint}"></td>\n};
		} else {
			print qq{<td class="tdc">$dbexpInfo{$id}{timepoint}</td>\n};
		}

		print qq{<td class="tdc">$dbexpInfo{$id}{channels}</td>\n},
		  qq{<td class="tdc">$testcolumn</td>\n},
		  qq{<td class="tdc">$testbkgd</td>\n},
		  qq{<td class="tdc">$controlcolumn</td>\n},
		  qq{<td class="tdc">$cntlbkgd</td>\n},
		  qq{<td class="tdc">$dbexpInfo{$id}{logarithm}</td>\n},
		  qq{<td class="tdc">$dbexpInfo{$id}{normalize}</td>\n},
		  qq{<td class="tdc">$dbexpInfo{$id}{antilog}</td>\n},
		  qq{<td class="tdc">$dbexpInfo{$id}{userma}</td>\n},
		  qq{<td class="tdr">$dbexpInfo{$id}{expstddev}</td>\n},
		  qq{<td class="tdr">$dbexpInfo{$id}{platform}</td>\n},
		  qq{<td class="tdc">$testgenome</td>\n},
		  qq{<td class="tdc">$cntlgenome</td>\n};
		if ( $testgdb::webUtil::useracclevel > 2 ) {
			print qq{<td class="tdc">$dbexpInfo{$id}{adduser}</td>\n},
			  qq{<td class="tdl">$dbexpInfo{$id}{adate}</td>\n},
			  qq{<td class="tdc">$dbexpInfo{$id}{moduser}</td>\n},
			  qq{<td class="tdl">$dbexpInfo{$id}{mdate}</td>\n};
		}
		print qq{</tr>\n};
	}
	print qq{<tr><td class="tdl" colspan="3">Recs: <b>$expCnt</b></td></tr>\n};
	print qq{<tr><td class="tdc" colspan="3"><input class="ebtn" type="button" value="Update" onclick="updexperiment($expid,this.form)"></td></tr>\n} if ( $expCnt > 0 and $testgdb::webUtil::useracclevel > 2 );
	print qq{</table>\n};

	print
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n},
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n};
}

#----------------------------------------------------------------------
# Display update experiment
# input: none
# return: none
#----------------------------------------------------------------------
sub updexperiment {

	my $dbexpInfoRef = testgdb::oracle::dbexpInfo( $testgdb::webUtil::frmData{id} );
	my %dbexpInfo    = %$dbexpInfoRef;

	$testgdb::webUtil::frmData{en} =~ s/\x2B/\+/g;    #these were changed to get thru html post
	$testgdb::webUtil::frmData{en} =~ s/\x3D/\=/g;

	my @delexp    = split( /\|\~\|/, $testgdb::webUtil::frmData{ed} );
	my @exporder  = split( /\|\~\|/, $testgdb::webUtil::frmData{eo} );
	my @expname   = split( /\|\~\|/, $testgdb::webUtil::frmData{en} );
	my @exptimept = split( /\|\~\|/, $testgdb::webUtil::frmData{et} );

	my @allchg;
	for my $id ( sort { $a <=> $b } keys %dbexpInfo ) {
		if ( $delexp[$id] =~ /true/ ) {
			push @allchg, "delete from pexp where id=$dbexpInfo{$id}{id}";
			push @allchg, "delete from pdata where pexp_id=$dbexpInfo{$id}{id}";
		} else {
			my $change = "";
			$dbexpInfo{$id}{exporder} = '' if !$dbexpInfo{$id}{exporder};
			$exporder[$id] = '' if !$exporder[$id];
			my $neword = ( $exporder[$id] ) ? $exporder[$id] : "''";
			$change .= "exporder=$neword," if $dbexpInfo{$id}{exporder} ne $exporder[$id];

			$dbexpInfo{$id}{expname} = '' if !$dbexpInfo{$id}{expname};
			$expname[$id] = '' if !$expname[$id];
			$change .= "expname='$expname[$id]'," if $dbexpInfo{$id}{expname} ne $expname[$id];

			$dbexpInfo{$id}{timepoint} = '' if !$dbexpInfo{$id}{timepoint};
			$exptimept[$id] = '' if !$exptimept[$id];
			my $newtp = ( $exptimept[$id] ) ? $exptimept[$id] : "''";
			$change .= "timepoint=$newtp," if $dbexpInfo{$id}{timepoint} ne $exptimept[$id];

			push @allchg, "update pexp set $change moddate=sysdate,moduser='$testgdb::webUtil::username' where id=$dbexpInfo{$id}{id}" if $change;
		}
	}

	my $status;
	if (@allchg) {
		my $rc = testgdb::oracle::dbupdateExpInfo( \@allchg );
		$status = ($rc) ? qq{<font color="red">* * * Error updating!! * * *</font>} : qq{<font color="green">* * * Change successfull. * * *</font>};
	} else {
		$status = qq{<font color="red">* * * No changes made! * * *</font>};
	}

	expinfo( $status );    #redraw expinfo
}

#----------------------------------------------------------------------
# Display curated
# input: status
# return: none
#----------------------------------------------------------------------
sub curated {
	my ( $status ) = @_;

	my $id               = $testgdb::webUtil::frmData{id};
	my $dbcuratedInfoRef = testgdb::oracle::dbcuratedInfo($id);
	my %dbcuratedInfo    = %$dbcuratedInfoRef;

	my $dbexpDesignRef    = testgdb::oracle::dbexpDesign($id);                       #exp design
	my %dbexpDesign       = %$dbexpDesignRef;
	my $dbexpProvidersRef = testgdb::oracle::dbexpProviders($id);                    #org and provider
	my %dbexpProviders    = %$dbexpProvidersRef;
	my $dbExpmRefRecRef   = testgdb::oracle::dbExpmReference();                      #pubmed
	my %dbExpmRefRec      = %$dbExpmRefRecRef;
	my $pubmed            = ( $dbExpmRefRec{$id} ) ? $dbExpmRefRec{$id} : '';

	my $added =
	  ( $dbcuratedInfo{mdate} )
	  ? "<b>Added:</b> $dbcuratedInfo{adate} by $dbcuratedInfo{adduser} &nbsp;&nbsp; <b>Modified:</b> $dbcuratedInfo{mdate} by $dbcuratedInfo{moduser}"
	  : "<b>Added:</b> $dbcuratedInfo{adate} by $dbcuratedInfo{adduser}";

	print qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="accinfo('curated',$id);" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},
	  qq{<td>\n},
	  qq{<table class="tblb" align="center">\n},
	  qq{<tr>\n}, qq{<th class="thc" colspan="3">CURATED</th>\n}, qq{</tr>\n},

	  qq{<tr><td></td>\n},                                   qq{<td class="tdl" colspan="2">$added</td></tr>\n},
	  qq{<tr><td class="small">$status</td>\n},              qq{<td class="thc">CURATED INFO</td>\n}, qq{<td class="thc">DATABASE INFO</td></tr>\n},
	  qq{<tr><td class="tdl">Principle Investigator</td>\n}, qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="pi$id" value="$dbcuratedInfo{pi}"></td>\n},
	  qq{<td class="tdl">$dbexpProviders{providers}</td></tr>\n},
	  qq{<tr><td class="tdl">Institution</td>\n},
	  qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="institution$id" value="$dbcuratedInfo{institution}"></td>\n},
	  qq{<td class="tdl">$dbexpProviders{organization}</td></tr>\n},
	  qq{<tr><td class="tdl">First Author</td>\n}, qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="author$id" value="$dbcuratedInfo{author}"></td>\n},
	  qq{<td></td></tr>\n},
	  qq{<tr><td class="tdl">PubMed ID</td>\n}, qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="pmid$id" value="$dbcuratedInfo{pmid}"></td>\n},
	  qq{<td class="tdl">$pubmed</td></tr>\n},
	  qq{<tr><td class="tdl">Experiment Title</td>\n}, qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="title$id" value="$dbcuratedInfo{title}"></td>\n},
	  qq{<td class="tdl">$dbcuratedInfo{dbtitle}</td></tr>\n},
	  qq{<tr><td class="tdl">Design Type</td>\n},
	  qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="designtype$id" value="$dbcuratedInfo{designtype}"></td>\n},
	  qq{<td class="tdl">$dbexpDesign{Contributor_Desc}</td></tr>\n},
	  qq{<tr><td class="tdl"> &nbsp;&nbsp; Design Type-Time series</td>\n},
	  qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="timeseries$id" value="$dbcuratedInfo{timeseries}"></td>\n},
	  qq{<td class="tdl">$dbexpDesign{Time_Series}</td></tr>\n},
	  qq{<tr><td class="tdl"> &nbsp;&nbsp; Design Type-Treatment</td>\n},
	  qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="treatment$id" value="$dbcuratedInfo{treatment}"></td>\n},
	  qq{<td class="tdl">$dbexpDesign{Treatment}</td></tr>\n},
	  qq{<tr><td class="tdl"> &nbsp;&nbsp; Design Type-Growth conditions</td>\n},
	  qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="growthcond$id" value="$dbcuratedInfo{growthcond}"></td>\n},
	  qq{<td class="tdl">$dbexpDesign{Growth_Conditions}</td></tr>\n},
	  qq{<tr><td class="tdl"> &nbsp;&nbsp; Design Type-Genetic modifications</td>\n},
	  qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="modification$id" value="$dbcuratedInfo{modification}"></td>\n},
	  qq{<td class="tdl">$dbexpDesign{Genetic_Modifications}</td></tr>\n},
	  qq{<tr><td class="tdl">Array Design</td>\n},
	  qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="arraydesign$id" value="$dbcuratedInfo{arraydesign}"></td>\n}, qq{<td></td></tr>\n},
	  qq{<tr><td class="tdl">Strain</td>\n}, qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="strain$id" value="$dbcuratedInfo{strain}"></td>\n},
	  qq{<td></td></tr>\n},
	  qq{<tr><td class="tdl">Sub-Strain</td>\n}, qq{<td class="tdl"><input class="small" type="text" size="100" maxlength="250" name="substrain$id" value="$dbcuratedInfo{substrain}"></td>\n},
	  qq{<td></td></tr>\n},
	  qq{<tr><td class="tdl" valign="top">Infomation</td>\n}, qq{<td class="tdl"><textarea class="small" name="info$id" rows="5" cols="98">$dbcuratedInfo{info}</textarea></td>\n},
	  qq{<td></td></tr>\n},
	  qq{<tr><td class="tdc"><input class="ebtn" type="button" value="Update" onclick="updcurated($id)"></td></tr>\n},

	  qq{</table>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# Display update curated
# input: none
# return: none
#----------------------------------------------------------------------
sub updcurated {

	my $dbcuratedInfoRef = testgdb::oracle::dbcuratedInfo( $testgdb::webUtil::frmData{id} );
	my %dbcuratedInfo    = %$dbcuratedInfoRef;

	my $dbexpDesignRef = testgdb::oracle::dbexpDesign( $testgdb::webUtil::frmData{id} );
	my %dbexpDesign    = %$dbexpDesignRef;

	my (
		$pi,         $institution,  $author,      $pmid,         $title,       $designtype, $timeseries, $treatment,
		$growthcond, $modification, $arraydesign, $strain,     $substrain,  $info
	) = split( /\|\~\|/, $testgdb::webUtil::frmData{parms} );

	my $change = '';
	$change .= "pi='$pi',"                     if ( $dbcuratedInfo{pi}           ne $pi );
	$change .= "institution='$institution',"   if ( $dbcuratedInfo{institution}  ne $institution );
	$change .= "author='$author',"             if ( $dbcuratedInfo{author}       ne $author );
	$change .= "pmid='$pmid',"                 if ( $dbcuratedInfo{pmid}         ne $pmid );
	$change .= "title='$title',"               if ( $dbcuratedInfo{title}        ne $title );
	$change .= "designtype='$designtype',"     if ( $dbcuratedInfo{designtype}   ne $designtype );
	$change .= "timeseries='$timeseries',"     if ( $dbcuratedInfo{timeseries}   ne $timeseries );
	$change .= "treatment='$treatment',"       if ( $dbcuratedInfo{treatment}    ne $treatment );
	$change .= "growthcond='$growthcond',"     if ( $dbcuratedInfo{growthcond}   ne $growthcond );
	$change .= "modification='$modification'," if ( $dbcuratedInfo{modification} ne $modification );
	$change .= "arraydesign='$arraydesign',"   if ( $dbcuratedInfo{arraydesign}  ne $arraydesign );
	$change .= "strain='$strain',"             if ( $dbcuratedInfo{strain}       ne $strain );
	$change .= "substrain='$substrain',"       if ( $dbcuratedInfo{substrain}    ne $substrain );

	$dbcuratedInfo{info} =~ s/\r//g;    #remove all carriage returns
	$info =~ s/\r//g;

	$change .= "info='$info'," if ( $dbcuratedInfo{info} ne $info );

	my $status;
	if ($change) {
		my $rc = testgdb::oracle::dbupdatecuratedInfo("update curated set $change moddate=sysdate,moduser='$testgdb::webUtil::username' where expid=$testgdb::webUtil::frmData{id}");
		$status = ($rc) ? qq{<font color="red">* * * Error updating!! * * *</font>} : qq{<font color="green">* * * Change successfull. * * *</font>};
	} else {
		$status = qq{<font color="red">* * * No changes made! * * *</font>};
	}

	curated($status );    #redraw curated
}

#----------------------------------------------------------------------
# Display expdata
# input: none
# return: none
#----------------------------------------------------------------------
sub expdata {

	my $selid         = $testgdb::webUtil::frmData{id};
	my $dbsampInfoRef = testgdb::oracle::dbsampInfo($selid);
	my %dbsampInfo    = %$dbsampInfoRef;

	my $dbchannelCountsRef = testgdb::oracle::dbchannelCounts();
	my %dbchannelCounts    = %$dbchannelCountsRef;

	my $dbcolumnPosNameRef = testgdb::oracle::dbcolumnPosName($selid);
	my %dbcolumnPosName    = %$dbcolumnPosNameRef;

	my ( %c1data, %c2data, $numchannel, $chgNumchan );
	for my $i ( sort { $a <=> $b } keys %dbsampInfo ) {
		$numchannel = $dbchannelCounts{ $dbsampInfo{$i}{bioassays_id} };
		
		$numchannel = $testgdb::webUtil::frmData{newchan} if $testgdb::webUtil::frmData{newchan};	#changed default channel
		
		if ( $numchannel == 1 ) {
			$chgNumchan = qq{&nbsp;&nbsp;&nbsp;(<a class="exmp" onclick="chgchn('2','$selid');" onmouseover="this.style.cursor='pointer';return overlib('Create experiment as a 2-channel');" onmouseout="return nd();">Run as 2-channel</a>)};
			$c1data{ $dbsampInfo{$i}{samid} }{bioassays_id} = $dbsampInfo{$i}{bioassays_id};
			$c1data{ $dbsampInfo{$i}{samid} }{accession}    = $dbsampInfo{$i}{accession};
			$c1data{ $dbsampInfo{$i}{samid} }{name}         = $dbsampInfo{$i}{samname};
			$c1data{ $dbsampInfo{$i}{samid} }{fname}        = $dbsampInfo{$i}{fname};
			$c1data{ $dbsampInfo{$i}{samid} }{gpl}          = $dbsampInfo{$i}{gpl};
		} elsif ( $numchannel == 2 ) {
			$chgNumchan = qq{&nbsp;&nbsp;&nbsp;(<a class="exmp" onclick="chgchn('1','$selid');" onmouseover="this.style.cursor='pointer';return overlib('Create experiment as a 1-channel');" onmouseout="return nd();">Run as 1-channel</a>)};
			$c2data{ $dbsampInfo{$i}{samid} }{bioassays_id} = $dbsampInfo{$i}{bioassays_id};
			$c2data{ $dbsampInfo{$i}{samid} }{accession}    = $dbsampInfo{$i}{accession};
			$c2data{ $dbsampInfo{$i}{samid} }{name}         = $dbsampInfo{$i}{samname};
			$c2data{ $dbsampInfo{$i}{samid} }{fname}        = $dbsampInfo{$i}{fname};
			$c2data{ $dbsampInfo{$i}{samid} }{gpl}          = $dbsampInfo{$i}{gpl};
		} else {
			print "Unknown sample channel!!";
			return;
		}
	}

	my $machk = '';
	my $mbchk = 'checked';
	my $xychk = '';

	print qq{<table align="center" cellpadding="1" cellspacing="1">\n},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="accinfo('expdata',$selid);" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},

	  qq{<td>\n},
	  qq{<table class="tblb" align="center">\n},
	  qq{<tr><th class="thc" colspan="2">DATA</th></tr>\n},
	  qq{<tr><td class="tdl"><b>PLOT INFORMATION</b> ($numchannel channel) $chgNumchan</td></tr>\n},
	  qq{<tr><td class="tdl">\n},
qq{<b>Data Process:</b> <input type="checkbox" id="log$selid" value="1">Log(base2) &nbsp; <input type="checkbox" id="normalize$selid" value="1">Normalize(loess) &nbsp; <input type="checkbox" id="antilog$selid" value="1">Convert Anti-Log10\n},
qq{ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>Plot Type:</b> <input type="radio" id="plotma$selid" name="ptype" value="maplot" $machk>M/A &nbsp; <input type="radio" id="plotmb$selid" name="ptype" value="mbplot" $mbchk>M/Loc &nbsp; <input type="radio" id="plotxy$selid" name="ptype" value="xyplot" $xychk>X/Y\n};

	if (%c1data) {
		my @RMAfiles = <$testgdb::util::datapath/$dbsampInfo{0}{accession}/*.RMA>;    #see if we have RMA files
		if (@RMAfiles) {
			print qq{ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="checkbox" id="userma$selid" value="1">Use RMA data\n};
		}

		print qq{</td>\n}, qq{<td class="tdr">\n}, qq{ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input class="ebtn" type="button" value="Plot" onclick="selPlot1($selid)">\n}, qq{</td></tr>\n},

		  qq{<tr>\n}, qq{<td colspan="2">\n},

		  qq{<table>\n},
		  qq{<tr>\n},
		  qq{<th class="thc" onmouseover="this.style.cursor='pointer';return overlib('Select Test Sample(s) (multiples will be averaged)');" onmouseout="return nd();">TEST</th>\n},
		  qq{<th class="thc" onmouseover="this.style.cursor='pointer';return overlib('Select Control Sample(s) (multiples will be averaged)');" onmouseout="return nd();">CONTROL</th>\n},
#		  qq{<th class="thc" onmouseover="this.style.cursor='pointer';return overlib('Select Test Sample(s) (multiples will be averaged)');" onmouseout="return nd();" colspan="2">TEST</th>\n},
#		  qq{<th class="thc" onmouseover="this.style.cursor='pointer';return overlib('Select Control Sample(s) (multiples will be averaged)');" onmouseout="return nd();" colspan="2">CONTROL</th>\n},
		  qq{<th class="thc" rowspan="2">DATA VALUE</th>\n},
		  qq{</tr>\n},
		  qq{<tr>\n},
		  qq{<th class="thc" onmouseover="this.style.cursor='pointer';return overlib('Select Test Sample(s) (multiples will be averaged)');" onmouseout="return nd();">SAMPLES</th>\n},
#		  qq{<th class="thc" onmouseover="this.style.cursor='pointer';return overlib('Select Test Genome');" onmouseout="return nd();">GENOME</th>\n},
		  qq{<th class="thc" onmouseover="this.style.cursor='pointer';return overlib('Select Control Sample(s) (multiples will be averaged)');" onmouseout="return nd();">SAMPLES</th>\n},
#		  qq{<th class="thc" onmouseover="this.style.cursor='pointer';return overlib('Select Control Genome');" onmouseout="return nd();">GENOME</th>\n},
		  qq{<th class="thc"></th>\n},
		  qq{</tr>\n};

		#test
		my $selsize = ( ( keys %c1data ) > 8 ) ? 8 : ( keys %c1data );
		print qq{<tr>\n}, qq{<td>\n}, qq{<select class="small" id="testname$selid" size="$selsize" MULTIPLE>\n};


	
		for my $samid (sort { lc $c1data{$a}{name} cmp lc $c1data{$b}{name} || $c1data{$a}{name} cmp $c1data{$b}{name} } keys %c1data){ # sort sample list by sample name 
#		for my $samid (sort {$c1data{$a} cmp $c1data{$b} } keys %c1data){ # sort sample list by sample name 
#		for my $samid ( sort keys %c1data ) {
			print qq{<option value="$c1data{$samid}{bioassays_id}">$samid &nbsp; $c1data{$samid}{name}</option>\n};
		}
		print qq{</select>\n}, qq{</td>\n},

		#test genome
#		  qq{<td>\n}, qq{<select class="small" id="testgenome$selid" size="$selsize" onChange="selgenome('cntlgenome$selid',this.selectedIndex)">\n};
#		for my $i ( sort { $a <=> $b } keys %testgdb::util::gnom ) {
#			print qq{<option value="$testgdb::util::gnom{$i}{acc}">$testgdb::util::gnom{$i}{sname}</option>\n};
#		}
#		print qq{</select>\n}, qq{</td>\n},

		  #control
		  qq{<td>\n}, qq{<select class="small" id="cntlname$selid" size="$selsize" MULTIPLE>\n};
		  
		for my $samid (sort { lc $c1data{$a}{name} cmp lc $c1data{$b}{name} || $c1data{$a}{name} cmp $c1data{$b}{name} } keys %c1data){ # sort sample list by sample name 
		  
#		for my $samid (sort {$c1data{$a} cmp $c1data{$b} } keys %c1data){ # sort sample list by sample name 
#		for my $samid ( sort keys %c1data ) {
			print qq{<option value="$c1data{$samid}{bioassays_id}">$samid &nbsp; $c1data{$samid}{name}</option>\n};
		}
		print qq{</select>\n}, qq{</td>\n},

		#control genome
#		  qq{<td>\n}, qq{<select class="small" id="cntlgenome$selid" size="$selsize" onChange="selgenome('testgenome$selid',this.selectedIndex)">\n};
#		for my $i ( sort { $a <=> $b } keys %testgdb::util::gnom ) {
#			print qq{<option value="$testgdb::util::gnom{$i}{acc}">$testgdb::util::gnom{$i}{sname}</option>\n};
#		}
#		print qq{</select>\n}, qq{</td>\n},

		#datacol
		  qq{<td valign="top">\n}, qq{<select class="small" id="datacol$selid">\n}, qq{<option value="">select data column</option>\n};
		for my $pos ( sort { $a <=> $b } keys %{ $dbcolumnPosName{ $dbsampInfo{0}{bioassays_id} } } ) {
			next if $pos == 1;    #1 is ID_REF
			print qq{<option value="$pos">$dbcolumnPosName{$dbsampInfo{0}{bioassays_id}}{$pos}</option>\n};
		}
		print qq{</select>\n}, qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
	}
	if (%c2data) {
		print qq{</td>\n}, qq{<td class="tdr">\n}, qq{<input class="ebtn" type="button" value="Plot" onclick="selPlot2($selid)">\n}, qq{</td></tr>\n},

		  qq{<tr>\n}, qq{<td colspan="2">\n},

		  qq{<table>\n},
		  qq{<tr>\n},
		  qq{<th class="thc" rowspan="2" onmouseover="this.style.cursor='pointer';return overlib('Select Sample(s) (multiples will be averaged)');" onmouseout="return nd();">SAMPLES</th>\n},
#		  qq{<th class="thc" rowspan="2" onmouseover="this.style.cursor='pointer';return overlib('Select Genome');" onmouseout="return nd();">GENOME</th>\n},
		  qq{<th class="thc" colspan="2">TEST</th>\n},
		  qq{<th class="thc" colspan="2">CONTROL</th>\n},
		  qq{</tr>\n},
		  qq{<tr>\n},
		  qq{<th class="thc">DATA VALUE</th>\n},
		  qq{<th class="thc">BACKGROUND SUB</th>\n},
		  qq{<th class="thc">DATA VALUE</th>\n},
		  qq{<th class="thc">BACKGROUND SUB</th>\n},
		  qq{</tr>\n};
		my $selsize = ( ( keys %c2data ) > 8 ) ? 8 : ( keys %c2data );
		print qq{<tr>\n}, qq{<td>\n}, qq{<select class="small" id="sampname$selid" size="$selsize" MULTIPLE>\n};
	

		for my $samid (sort { lc $c2data{$a}{name} cmp lc $c2data{$b}{name} || $c2data{$a}{name} cmp $c2data{$b}{name} } keys %c2data){ # sort sample list by sample name 	
#		for my $samid (sort {$c2data{$a} cmp $c2data{$b} } keys %c2data){ # sort sample list by sample name 
           	
		##for my $samid ( sort keys (%c2data) ) {  ##sort by key
			print qq{<option value="$c2data{$samid}{bioassays_id}">$samid &nbsp; $c2data{$samid}{name}</option>\n};
		}
		print qq{</select>\n}, qq{</td>\n},
		
		
		#genome list of 1 channel
#		qq{<td>\n}, qq{<select class="small" id="cntlgenome$selid" size="$selsize">\n};
#		for my $i ( sort { $a <=> $b } keys %testgdb::util::gnom ) {
#			print qq{<option value="$testgdb::util::gnom{$i}{acc}">$testgdb::util::gnom{$i}{sname}</option>\n};
#		}
#		print qq{</select>\n}, qq{</td>\n},

		  #testcol
		  qq{<td valign="top">\n}, qq{<select class="small" id="testcol$selid">\n}, qq{<option value="">select test data column</option>\n};
		for my $pos ( sort { $a <=> $b } keys %{ $dbcolumnPosName{ $dbsampInfo{0}{bioassays_id} } } ) {
			next if $pos == 1;    #1 is ID_REF
			print qq{<option value="$pos">$dbcolumnPosName{$dbsampInfo{0}{bioassays_id}}{$pos}</option>\n};
		}
		print qq{</select>\n}, qq{</td>\n},

		  #testbkgd
		  qq{<td valign="top">\n}, qq{<select class="small" id="testbkgd$selid">\n}, qq{<option value="">-- none --</option>\n};
		for my $pos ( sort { $a <=> $b } keys %{ $dbcolumnPosName{ $dbsampInfo{0}{bioassays_id} } } ) {
			next if $pos == 1;    #1 is ID_REF
			print qq{<option value="$pos">$dbcolumnPosName{$dbsampInfo{0}{bioassays_id}}{$pos}</option>\n};
		}
		print qq{</select>\n}, qq{</td>\n},

		  #cntlcol
		  qq{<td valign="top">\n}, qq{<select class="small" id="cntlcol$selid">\n}, qq{<option value="">select control data column</option>\n};
		for my $pos ( sort { $a <=> $b } keys %{ $dbcolumnPosName{ $dbsampInfo{0}{bioassays_id} } } ) {
			next if $pos == 1;    #1 is ID_REF
			print qq{<option value="$pos">$dbcolumnPosName{$dbsampInfo{0}{bioassays_id}}{$pos}</option>\n};
		}
		print qq{</select>\n}, qq{</td>\n},

		  #cntlbkgd
		  qq{<td valign="top">\n}, qq{<select class="small" id="cntlbkgd$selid">\n}, qq{<option value="">-- none --</option>\n};
		for my $pos ( sort { $a <=> $b } keys %{ $dbcolumnPosName{ $dbsampInfo{0}{bioassays_id} } } ) {
			next if $pos == 1;    #1 is ID_REF
			print qq{<option value="$pos">$dbcolumnPosName{$dbsampInfo{0}{bioassays_id}}{$pos}</option>\n};
		}
		print qq{</select>\n}, qq{</td>\n},

		  qq{</tr>\n}, qq{</table>\n};
	}

	print
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{<tr><td><div class="hidden" id="selPlot$selid"></div></td></tr>\n},
	  qq{</table>\n},

	  qq{</td>\n}, qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# Display channel 1 plot
# input: none
# return: none
#----------------------------------------------------------------------
sub sel1Plot {

	my $dbsampInfoRef = testgdb::oracle::dbsampInfo( $testgdb::webUtil::frmData{id} );
	my %dbsampInfo    = %$dbsampInfoRef;

	my $testgenomeacc = '';
	my $cntlgenomeacc = '';
#	my $testgenomeacc = $testgdb::webUtil::frmData{testgenome};
#	my $cntlgenomeacc = $testgdb::webUtil::frmData{cntlgenome};

	#split selected test samples and put into hash
	my @testArr = split( /\,/, $testgdb::webUtil::frmData{testname} );
	my %testsamp;
	for my $sname (@testArr) {
		$testsamp{$sname} = 1;
	}

	#split selected control samples and put into hash
	my @cntlArr = split( /\,/, $testgdb::webUtil::frmData{cntlname} );
	my %cntlsamp;
	for my $sname (@cntlArr) {
		$cntlsamp{$sname} = 1;
	}

	my %testsample = ();
	my %cntlsample = ();
	my %pfcnt = ();
	my $platform = '';

	#get test sample info
	for my $id ( sort { $a <=> $b } keys %dbsampInfo ) {
		if ( exists $testsamp{ $dbsampInfo{$id}{bioassays_id} } ) {
			$testsample{ $dbsampInfo{$id}{bioassays_id} }{accession} = $dbsampInfo{$id}{accession};
			$testsample{ $dbsampInfo{$id}{bioassays_id} }{sampid}    = $dbsampInfo{$id}{samid};
			$testsample{ $dbsampInfo{$id}{bioassays_id} }{fname}     = $dbsampInfo{$id}{fname};
			$pfcnt{ $dbsampInfo{$id}{gpl} }                          = 1;
			$platform                                                = $dbsampInfo{$id}{gpl};
		}
	}

	#get control sample info
	for my $id ( sort { $a <=> $b } keys %dbsampInfo ) {
		if ( exists $cntlsamp{ $dbsampInfo{$id}{bioassays_id} } ) {
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
	
#	my $testGenLtagsRef = testgdb::oracle::dbgenomeLtags($testgenomeacc);
#	my %testGenomeLtags = %$testGenLtagsRef;

#	my $cntlGenLtagsRef = testgdb::oracle::dbgenomeLtags($cntlgenomeacc);
#	my %cntlGenomeLtags = %$cntlGenLtagsRef;


	my $dbplatformAnnotRef = testgdb::oracle::dbplatformAnnot($platform);
	my %dbplatformAnnot    = %$dbplatformAnnotRef;
	if ( !%dbplatformAnnot ) {
		print qq{<font color="red">No Platform available!  Please contact administrator.</font>};
		return;
	}

	my $log       = ( $testgdb::webUtil::frmData{log}       =~ /true/i ) ? 1 : 0;
	my $normalize = ( $testgdb::webUtil::frmData{normalize} =~ /true/i ) ? 1 : 0;
	my $antilog   = ( $testgdb::webUtil::frmData{antilog}   =~ /true/i ) ? 1 : 0;
	my $userma    = ( $testgdb::webUtil::frmData{userma}    =~ /true/i ) ? 1 : 0;
	my $plottype = ( $testgdb::webUtil::frmData{plottype} ) ? $testgdb::webUtil::frmData{plottype}    : '';
	my $datacol  = ( $testgdb::webUtil::frmData{datacol} )  ? $testgdb::webUtil::frmData{datacol} - 1 : '';    #subtract 1 because file is 0-based
	$datacol = 1 if $userma;

	my %savExpInfo = ();

	$savExpInfo{expid}     = $testgdb::webUtil::frmData{id};
	$savExpInfo{channels}  = 1;
	$savExpInfo{logarithm} = $log;
	$savExpInfo{normalize} = $normalize;
	$savExpInfo{antilog}   = $antilog;
	$savExpInfo{userma}    = $userma;
	$savExpInfo{plottype}  = $plottype;
	$savExpInfo{datacol}   = $datacol;
	$savExpInfo{platform}  = $platform;
	$savExpInfo{testgenome}  = '';
	$savExpInfo{cntlgenome}  = '';
#	$savExpInfo{testgenome}  = $testgenomeacc;
#	$savExpInfo{cntlgenome}  = $cntlgenomeacc;

	my $platformCnt;
	my %pfids = ();
	my %testSource = ();
	my %avgTestArr = ();
	my %cntlSource = ();
	my %avgCntlArr = ();
	my %corrData = ();
	my @maxval = ();
	my @testSampname = ();
	my @cntlSampname = ();
	for my $bioassays_id ( sort keys %testsample ) {

		#get channel source name for each sample
		my $dbchannelSourceRef = testgdb::oracle::dbchannelSource($bioassays_id);
		my @dbchannelSource    = @$dbchannelSourceRef;
		$testSource{ $dbchannelSource[0] } = $dbchannelSource[0] if $dbchannelSource[0];

		my $testfile =
		  ($userma)
		  ? "$testgdb::util::datapath/$testsample{$bioassays_id}{accession}/$testsample{$bioassays_id}{sampid}.RMA"
		  : "$testgdb::util::datapath/$testsample{$bioassays_id}{accession}/$testsample{$bioassays_id}{fname}";
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
			#if (exists $dbplatformAnnot{ $id }) {
			#	for my $ltag ( keys %{ $dbplatformAnnot{ $id } } ) {
			#		$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_000913/) and ($ltag =~ /^b/i);		#genome is MG1655 only want B-numbers
			#		$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_002655/) and ($ltag =~ /^z/i);		#genome is EDL933 only want Z-numbers
			#		$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_002695/) and ($ltag =~ /^e/i);		#genome is Sakai only want Ecs-numbers
			#		$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_004431/) and ($ltag =~ /^c/i);		#genome is CFT073 only want c-numbers
			#		$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_007946/) and ($ltag =~ /^u/i);		#genome is UTI89 only want UTI89-numbers

			#		$id_ref .= ":$ltag"	if ($testgenomeacc =~ /NC_003317|NC_003318/) and ($ltag =~ /^bme/i);		#genome is Brucella M16 only want M16-numbers
			#	}
			#}
			
			$id_ref=($dbplatformAnnot{ $id }) ? $dbplatformAnnot{ $id } : '';
			
			
			next if ! $id_ref;
			$id_ref =~ s/^://;	#remove leading ':'

			$dataVal = ( $datacol and defined $lineArr[$datacol] ) ? $lineArr[$datacol] : '';
			$dataVal =~ s/null|n\/a//gi;
			$dataVal =~ s/\,//g;	#remove ','
			
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
#		for my $ltag ( keys %testGenomeLtags ) {
#			if ( ! exists $ckltag{$ltag}) {
#				$pcnt++;
#				$pfids{$pcnt}{ltag} = $ltag;
#				$pfids{$pcnt}{dataVal} = '';
#			}
#		}
		
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
		$corrData{ $testsample{$bioassays_id}{sampid} } = \@testcorr;
	}    #end test samples

	for my $bioassays_id ( sort keys %cntlsample ) {

		#get channel source name for each sample
		my $dbchannelSourceRef = testgdb::oracle::dbchannelSource($bioassays_id);
		my @dbchannelSource    = @$dbchannelSourceRef;
		$cntlSource{ $dbchannelSource[0] } = $dbchannelSource[0] if $dbchannelSource[0];

		my $cntlfile =
		  ($userma)
		  ? "$testgdb::util::datapath/$cntlsample{$bioassays_id}{accession}/$cntlsample{$bioassays_id}{sampid}.RMA"
		  : "$testgdb::util::datapath/$cntlsample{$bioassays_id}{accession}/$cntlsample{$bioassays_id}{fname}";
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

		#	if (exists $dbplatformAnnot{ $id }) {
		#		for my $ltag ( keys %{ $dbplatformAnnot{ $id } } ) {
		#			$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_000913/) and ($ltag =~ /^b/i);		#genome is MG1655 only want B-numbers
		#			$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_002655/) and ($ltag =~ /^z/i);		#genome is EDL933 only want Z-numbers
		#			$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_002695/) and ($ltag =~ /^e/i);		#genome is Sakai only want Ecs-numbers
		#			$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_004431/) and ($ltag =~ /^c/i);		#genome is CFT073 only want c-numbers
		#			$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_007946/) and ($ltag =~ /^u/i);		#genome is UTI89 only want UTI89-numbers
		#		}
		#	}



			$id_ref=($dbplatformAnnot{ $id } ) ? $dbplatformAnnot{ $id } : '';
			
			

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
#		for my $ltag ( keys %cntlGenomeLtags ) {
#			if ( ! exists $ckltag{$ltag}) {
#				$pcnt++;
#				$pfids{$pcnt}{ltag} = $ltag;
#				$pfids{$pcnt}{dataVal} = '';
#			}
#		}
		
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
		$corrData{ $cntlsample{$bioassays_id}{sampid} } = \@cntlcorr;
	}    #end control samples

	print "<hr>";

	my $needtoLog = ( max(@maxval) > 24 ) ? 1 : 0;
	if ( !$log and $needtoLog ) {
		print qq{<font color="red">Data does not seem to be Log values? (maximum value > 24)</font>\n};
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

	my $ltagCnt    = 0;
	my $novalueCnt = 0;
	my %plotTestdata = ();
	my %plotCntldata = ();
	my @stddata = ();
	for my $id_ref ( sort keys %cntldataArr ) {

		#save all data
		$plotTestdata{$id_ref} = ( $testdataArr{$id_ref} ne '' ) ? sprintf( "%.3f", $testdataArr{$id_ref} ) : $testdataArr{$id_ref};
		$plotCntldata{$id_ref} = ( $cntldataArr{$id_ref} ne '' ) ? sprintf( "%.3f", $cntldataArr{$id_ref} ) : $cntldataArr{$id_ref};
	}

	my $dataFilename = writeDataToFile( $cntlgenomeacc, \%plotTestdata, \%plotCntldata );

	%plotTestdata = ();
	%plotCntldata = ();
	for my $id_ref ( sort keys %cntldataArr ) {

		$ltagCnt++ if ( $cntldataArr{$id_ref} ne '' );
		$novalueCnt++ if ( $cntldataArr{$id_ref} eq '' );

		push @stddata, $cntldataArr{$id_ref} if ( $cntldataArr{$id_ref} ne '' );    #stddata used for stddev

		$plotTestdata{$id_ref} = ( $testdataArr{$id_ref} ne '' ) ? sprintf( "%.3f", $testdataArr{$id_ref} ) : $testdataArr{$id_ref};
		$plotCntldata{$id_ref} = ( $cntldataArr{$id_ref} ne '' ) ? sprintf( "%.3f", $cntldataArr{$id_ref} ) : $cntldataArr{$id_ref};
	}

	my $stddev = sprintf( "%.3f", testgdb::plot::stat_stdev( \@stddata ) );
	my $mean   = sprintf( "%.3f", sum(@stddata) / $ltagCnt );
	my $min    = sprintf( "%.3f", min(@stddata) );
	my $max    = sprintf( "%.3f", max(@stddata) );
	my $tot    = $ltagCnt + $novalueCnt;
	@testSampname = sort(@testSampname);
	@cntlSampname = sort(@cntlSampname);
	my $avgTestsname = join( ', ', @testSampname );
	my $avgCntlsname = join( ', ', @cntlSampname );

	$savExpInfo{samples} = join( ',', @testSampname ) . "/" . join( ',', @cntlSampname );
	$savExpInfo{expstddev} = $stddev;

	print qq{<table align="center" cellpadding="1"  cellspacing="1">\n},
	  qq{<tr><th class="thc" colspan="8">Test($avgTestsname) / Control($avgCntlsname) </th></tr>\n},
#	  qq{<tr><th class="thc" colspan="8">Test($avgTestsname) - $testgdb::util::gnom{$testgdb::util::gnomacc{$savExpInfo{testgenome}}}{sname} / Control($avgCntlsname) - $testgdb::util::gnom{$testgdb::util::gnomacc{$savExpInfo{cntlgenome}}}{sname}</th></tr>\n},
	  qq{<tr>},
	  qq{<th class="thc">DATA</th>},
	  qq{<th class="thc">NO DATA</th>},
	  qq{<th class="thc">TOTAL</th>},
	  qq{<th class="thc">PLATFORM</th>},
	  qq{<th class="thc">STDDEV</th>},
	  qq{<th class="thc">MEAN</th>},
	  qq{<th class="thc">MIN</th>},
	  qq{<th class="thc">MAX</th>},
	  qq{</tr>},
	  qq{<tr bgcolor="#EBF0F2">},
	  qq{<td class="tdc">$ltagCnt</td>\n},
	  qq{<td class="tdc">$novalueCnt</td>\n},
	  qq{<td class="tdc">$tot</td>\n},
	  qq{<td class="tdc">$platformCnt</td>\n},
	  qq{<td class="tdc">$stddev</td>\n},
	  qq{<td class="tdc">$mean</td>\n},
	  qq{<td class="tdc">$min</td>\n},
	  qq{<td class="tdc">$max</td>\n},
	  qq{</tr>};

	if ( $platformCnt != $tot ) {
		print qq{<tr><td class="tdc" colspan="8"><font color="red">\tCounts are not equal!</font></td></tr>\n};
	}

	my ( $plotFile, $pmap ) = testgdb::plot::createExpPlot( $plottype, $stddev, $cntlgenomeacc, \%plotTestdata, \%plotCntldata );
	print qq{<tr><td class="tdc" colspan="8"><img alt="" src="/tmpimage/$plotFile" border="1" usemap="#$testgdb::webUtil::frmData{id}"></td></tr>}, qq{<map name="$testgdb::webUtil::frmData{id}">$pmap</map>\n},
	  qq{<tr><td class="tdc" colspan="8">\n},
qq{<input class="ebtn" type="button" value="View data" onclick="window.open('$ENV{REQUEST_URI}?ajax=accinfo&accinfo=viewPlotData&fname=$dataFilename&samp=Test($avgTestsname) / Control($avgCntlsname)','_blank')" onmouseover="this.style.cursor='pointer';return overlib('View data (new window)');" onmouseout="return nd();">\n},
qq{<input class="ebtn" type="button" value="Download data" onclick="window.open('$testgdb::util::urlpath/download.pl?type=plotdata&fname=$dataFilename&samp=Test($avgTestsname) / Control($avgCntlsname)','_blank')" onmouseover="this.style.cursor='pointer';return overlib('Download data');" onmouseout="return nd();">\n},
	  qq{</td></tr>\n},
	  qq{</table>\n};

	SampleCorrelation( \%corrData );

	if ( $testgdb::webUtil::useracclevel > 2 ) {

		#save experiment
		my $testexpname = '';
		for my $desc ( sort keys %testSource ) {
			$testexpname .= $testSource{$desc} . ';';
		}
		$testexpname =~ s/\;$//;
		my $cntlexpname = '';
		for my $desc ( sort keys %cntlSource ) {
			$cntlexpname .= $cntlSource{$desc} . ';';
		}
		$cntlexpname =~ s/\;$//;
		my $expname = "$testexpname / $cntlexpname";

		print qq{<br>},
		  qq{<table align="center" cellpadding="1"  cellspacing="1">\n},
		  qq{<tr>},
		  qq{<td class="tdr"><b>ExpName:</b></td>},
		  qq{<td><input class="small" type="text" size="112" maxlength="250" id="expname$testgdb::webUtil::frmData{id}" value="$expname"></td>},
qq{<td onmouseover="this.style.cursor='pointer';return overlib('Swap ExpName conditions. (Test / Control)');" onmouseout="return nd();"><input class="ebtn" type="button" value="Swap Conditions" onclick="swapcond($testgdb::webUtil::frmData{id})"></td>},
		  qq{</tr>},
		  qq{<tr>},
		  qq{<td class="tdr" valign="top"><b>Infomation:</b></td>\n},
		  qq{<td class="tdl"><textarea class="small" id="info$testgdb::webUtil::frmData{id}" rows="3" cols="110"></textarea></td>},
		  qq{</tr>},
		  qq{<tr>},
		  qq{<td></td>\n},
		  qq{<td><input class="ebtn" type="button" value="Save Experiment" onclick="savExptoDB(event,$testgdb::webUtil::frmData{id},$testgdb::webUtil::frmData{id})"></td>\n},
		  qq{</tr>},
		  qq{</table>};

		$savExpInfo{dataFilename} = $dataFilename;
		testgdb::webUtil::putSessVar( 'savExpInfo', \%savExpInfo );
	}
}

#----------------------------------------------------------------------
# Display Sample Correlation
# input: hash
# return: none
#----------------------------------------------------------------------
sub SampleCorrelation {
	my ($corrDataRef) = @_;
	my %corrData = %$corrDataRef;

	print qq{<table align="center" cellpadding="1"  cellspacing="1">\n}, qq{<tr>}, qq{<th class="thc">CORRELATION</th>};

	for my $samp1 ( sort keys %corrData ) {
		print qq{<th class="thc">$samp1</th>};
	}
	print qq{</tr>};

	for my $samp1 ( sort keys %corrData ) {
		print qq{<tr bgcolor="#EBF0F2">}, qq{<th class="thl">$samp1</th>};

		for my $samp2 ( sort keys %corrData ) {
			my $corr = testgdb::plot::stat_correlation( $corrData{$samp1}, $corrData{$samp2} );
			$corr = sprintf( "%.3f", $corr );
			if ( $corr > 0.9 ) {
				if ( $corr > 0.99 ) {
					print qq{<td class="tdc"><font color="red">$corr</font></td>};
				} else {
					print qq{<td class="tdc"><font color="green">$corr</font></td>};
				}
			} elsif ( $corr > 0.8 and $corr < 0.9 ) {
				print qq{<td class="tdc">$corr</td>};
			} else {
				print qq{<td class="tdc"><font color="gray">$corr</font></td>};
			}
		}
		print qq{</tr>};
	}
	print qq{</table>};
}

#----------------------------------------------------------------------
# Display channel 2 plot
# input: none
# return: none
#----------------------------------------------------------------------
sub sel2Plot {

	my $dbsampInfoRef = testgdb::oracle::dbsampInfo( $testgdb::webUtil::frmData{id} );
	my %dbsampInfo    = %$dbsampInfoRef;
	
#	my $cntlgenomeacc = $testgdb::webUtil::frmData{cntlgenome};
	my $cntlgenomeacc = '';

	#split selected samples and put into hash
	my @samples = split( /\,/, $testgdb::webUtil::frmData{sampname} );
	my %samp;
	for my $sname (@samples) {
		$samp{$sname} = 1;
	}

	#get sample info
	my ( %sample, %pfcnt ) = ();
	my $platform = '';
	for my $id ( sort { $a <=> $b } keys %dbsampInfo ) {
		if ( exists $samp{ $dbsampInfo{$id}{bioassays_id} } ) {
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
	
#	my $genomeLtagsRef = testgdb::oracle::dbgenomeLtags($cntlgenomeacc);
#	my %genomeLtags = %$genomeLtagsRef;
	
	my $dbplatformAnnotRef = testgdb::oracle::dbplatformAnnot($platform);
	my %dbplatformAnnot    = %$dbplatformAnnotRef;
	if ( !%dbplatformAnnot ) {
		print qq{<font color="red">No Platform available!  Please contact administrator.</font>};
		return;
	}

	my $log       = ( $testgdb::webUtil::frmData{log}       =~ /true/i ) ? 1 : 0;
	my $normalize = ( $testgdb::webUtil::frmData{normalize} =~ /true/i ) ? 1 : 0;
	my $antilog   = ( $testgdb::webUtil::frmData{antilog}   =~ /true/i ) ? 1 : 0;
	my $plottype = ( $testgdb::webUtil::frmData{plottype} ) ? $testgdb::webUtil::frmData{plottype}     : '';
	my $testcol  = ( $testgdb::webUtil::frmData{testcol} )  ? $testgdb::webUtil::frmData{testcol} - 1  : '';    #subtract 1 because file is 0-based
	my $testbkgd = ( $testgdb::webUtil::frmData{testbkgd} ) ? $testgdb::webUtil::frmData{testbkgd} - 1 : '';
	my $cntlcol  = ( $testgdb::webUtil::frmData{cntlcol} )  ? $testgdb::webUtil::frmData{cntlcol} - 1  : '';
	my $cntlbkgd = ( $testgdb::webUtil::frmData{cntlbkgd} ) ? $testgdb::webUtil::frmData{cntlbkgd} - 1 : '';

	if ( !$testcol and $plottype =~ /maplot|xyplot/ ) {
		print qq{<font color="red">Test data required for M/A or X/Y plots!</font>};
		return;
	}

	my %savExpInfo = ();

	$savExpInfo{expid}         = $testgdb::webUtil::frmData{id};
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
	$savExpInfo{cntlgenome}    = '';

	my $platformCnt;
	my %pfids = ();
	my %avgTestArr = ();
	my %avgCntlArr = ();
	my @sampname = ();
	my %chanSource = ();
	for my $bioassays_id ( sort keys %sample ) {
		print "<hr>";

		#get channel source name for each sample
		my $dbchannelSourceRef = testgdb::oracle::dbchannelSource($bioassays_id);
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
		my ( %testdata, %cntldata, @maxval, %plotTestdata, %plotCntldata, @stddata ) = ();

		open( FILE, "$testgdb::util::datapath/$sample{$bioassays_id}{accession}/$sample{$bioassays_id}{fname}" );
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
			#if (exists $dbplatformAnnot{ $id }) {
			#	for my $ltag ( keys %{ $dbplatformAnnot{ $id } } ) {
			#		$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_000913/) and ($ltag =~ /^b/i);		#genome is MG1655 only want B-numbers
			#		$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_002655/) and ($ltag =~ /^z/i);		#genome is EDL933 only want Z-numbers
			#		$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_002695/) and ($ltag =~ /^e/i);		#genome is Sakai only want Ecs-numbers
			#		$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_004431/) and ($ltag =~ /^c/i);		#genome is CFT073 only want c-numbers
			#		$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_007946/) and ($ltag =~ /^u/i);		#genome is UTI89 only want UTI89-numbers

			#		$id_ref .= ":$ltag"	if ($cntlgenomeacc =~ /NC_003317|NC_003318/) and ($ltag =~ /^bme/i);		#genome is Brucella M16 only want Brucella M16-numbers
			#	}
			#}
			$id_ref=($dbplatformAnnot{ $id }) ? $dbplatformAnnot{ $id } : '';

			next if ! $id_ref;
			$id_ref =~ s/^://;	#remove leading ':'
			
			$testVal = ( $testcol and defined $lineArr[$testcol] ) ? $lineArr[$testcol] : '';
			$cntlVal = ( $cntlcol and defined $lineArr[$cntlcol] ) ? $lineArr[$cntlcol] : '';
			$testVal =~ s/null|n\/a//gi;	#remove null or 'n/a'
			$cntlVal =~ s/null|n\/a//gi;
			$testVal =~ s/\,//g;	#remove ','
			$cntlVal =~ s/\,//g;	#remove ','
			
			#background subtraction
			$testbkgdVal = ( $testbkgd and $lineArr[$testbkgd] ) ? $lineArr[$testbkgd] : '';
			$cntlbkgdVal = ( $cntlbkgd and $lineArr[$cntlbkgd] ) ? $lineArr[$cntlbkgd] : '';
			$testbkgdVal =~ s/null|n\/a//gi;
			$cntlbkgdVal =~ s/null|n\/a//gi;
			$testbkgdVal =~ s/\,//g;	#remove ','
			$cntlbkgdVal =~ s/\,//g;	#remove ','
			
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
			print qq{<font color="red">Configuration returned no data!</font>\n};
			return;
		}

		my $pcnt = scalar keys %pfids;
		#check ckltag and add all genome ltags not in sample
#		for my $ltag ( keys %genomeLtags ) {
#			if ( ! exists $ckltag{$ltag}) {
#				$pcnt++;
#				$pfids{$pcnt}{ltag} = $ltag;
#				$pfids{$pcnt}{testVal} = '';
#				$pfids{$pcnt}{cntlVal} = '';
#				$pfids{$pcnt}{testbkgdVal} = '';
#				$pfids{$pcnt}{cntlbkgdVal} = '';
#			}
#		}
		
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
			print qq{<font color="red">Configuration returned no data!</font>\n};
			return;
		}

		my $needtoLog = ( max(@maxval) > 24 ) ? 1 : 0;
		if ( !$log and $needtoLog ) {
			print qq{<font color="red">Data does not seem to be Log values? (maximum value > 24)</font>\n};
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

		my $dataFilename = writeDataToFile( $cntlgenomeacc, \%plotTestdata, \%plotCntldata );

		push @sampname, $sample{$bioassays_id}{sampid};
		my $stddev = sprintf( "%.3f", testgdb::plot::stat_stdev( \@stddata ) );
		my $mean   = sprintf( "%.3f", sum(@stddata) / $ltagCnt );
		my $min    = sprintf( "%.3f", min(@stddata) );
		my $max    = sprintf( "%.3f", max(@stddata) );
		my $tot    = $ltagCnt + $novalueCnt;

		print qq{<table align="center" cellpadding="1"  cellspacing="1">\n},
		  qq{<tr><th class="thc" colspan="8">$sample{$bioassays_id}{sampid}</th></tr>\n},
#		  qq{<tr><th class="thc" colspan="8">$sample{$bioassays_id}{sampid} - $testgdb::util::gnom{$testgdb::util::gnomacc{$savExpInfo{cntlgenome}}}{sname}</th></tr>\n},
		  qq{<tr>},
		  qq{<th class="thc">DATA</th>},
		  qq{<th class="thc">NO DATA</th>},
		  qq{<th class="thc">TOTAL</th>},
		  qq{<th class="thc">PLATFORM</th>},
		  qq{<th class="thc">STDDEV</th>},
		  qq{<th class="thc">MEAN</th>},
		  qq{<th class="thc">MIN</th>},
		  qq{<th class="thc">MAX</th>},
		  qq{</tr>},
		  qq{<tr bgcolor="#EBF0F2">},
		  qq{<td class="tdc">$ltagCnt</td>\n},
		  qq{<td class="tdc">$novalueCnt</td>\n},
		  qq{<td class="tdc">$tot</td>\n},
		  qq{<td class="tdc">$platformCnt</td>\n},
		  qq{<td class="tdc">$stddev</td>\n},
		  qq{<td class="tdc">$mean</td>\n},
		  qq{<td class="tdc">$min</td>\n},
		  qq{<td class="tdc">$max</td>\n},
		  qq{</tr>};

		if ( $platformCnt != $tot ) {
			print qq{<tr><td class="tdc" colspan="8"><font color="red">\tCounts are not equal!</font></td></tr>\n};
		}

		my ( $plotFile, $pmap ) = testgdb::plot::createExpPlot( $plottype, $stddev, $cntlgenomeacc, \%plotTestdata, \%plotCntldata );
		print qq{<tr><td class="tdc" colspan="8"><img alt="" src="/tmpimage/$plotFile" border="1" usemap="#$bioassays_id"></td></tr>}, qq{<map name="$bioassays_id">$pmap</map>\n},

		  qq{<tr><td class="tdc" colspan="8">\n},
qq{<input class="ebtn" type="button" value="View data" onclick="window.open('$ENV{REQUEST_URI}?ajax=accinfo&accinfo=viewPlotData&fname=$dataFilename&samp=$sample{$bioassays_id}{sampid}','_blank')" onmouseover="this.style.cursor='pointer';return overlib('View data (new window)');" onmouseout="return nd();">\n},
qq{<input class="ebtn" type="button" value="Download data" onclick="window.open('$testgdb::util::urlpath/download.pl?type=plotdata&fname=$dataFilename&samp=$sample{$bioassays_id}{sampid}','_blank')" onmouseover="this.style.cursor='pointer';return overlib('Download data');" onmouseout="return nd();">\n},
		  qq{</td></tr>\n},
		  qq{</table>\n};

		if ( ( scalar keys %sample ) == 1 and $testgdb::webUtil::useracclevel > 2 ) {

			#save 1 sample experiment
			@sampname = sort(@sampname);
			$savExpInfo{samples} = join( ',', @sampname );
			$savExpInfo{expstddev} = $stddev;
			savExp( $testgdb::webUtil::frmData{id}, $bioassays_id, $dataFilename, \%chanSource, \%savExpInfo );
		}
	}    #end of all samples

	#average all samples
	if ( ( scalar keys %sample ) > 1 ) {
		my $ltagCnt    = 0;
		my $novalueCnt = 0;
		my %plotTestdata = ();
		my %plotCntldata = ();
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

		print qq{<hr size="10" noshade>\n};

		my $dataFilename = writeDataToFile( $cntlgenomeacc, \%plotTestdata, \%plotCntldata );

		my $stddev = sprintf( "%.3f", testgdb::plot::stat_stdev( \@stddata ) );
		my $mean   = sprintf( "%.3f", sum(@stddata) / $ltagCnt );
		my $min    = sprintf( "%.3f", min(@stddata) );
		my $max    = sprintf( "%.3f", max(@stddata) );
		my $tot    = $ltagCnt + $novalueCnt;
		my $avgsname = join( ', ', @sampname );

		print qq{<table align="center" cellpadding="1"  cellspacing="1">\n},
		  qq{<tr><th class="thc" colspan="8">Average ($avgsname)</th></tr>\n},
#		  qq{<tr><th class="thc" colspan="8">Average ($avgsname) - $testgdb::util::gnom{$testgdb::util::gnomacc{$savExpInfo{cntlgenome}}}{sname}</th></tr>\n},
		  qq{<tr>},
		  qq{<th class="thc">DATA</th>},
		  qq{<th class="thc">NO DATA</th>},
		  qq{<th class="thc">TOTAL</th>},
		  qq{<th class="thc">PLATFORM</th>},
		  qq{<th class="thc">STDDEV</th>},
		  qq{<th class="thc">MEAN</th>},
		  qq{<th class="thc">MIN</th>},
		  qq{<th class="thc">MAX</th>},
		  qq{</tr>},
		  qq{<tr bgcolor="#EBF0F2">},
		  qq{<td class="tdc">$ltagCnt</td>\n},
		  qq{<td class="tdc">$novalueCnt</td>\n},
		  qq{<td class="tdc">$tot</td>\n},
		  qq{<td class="tdc">$platformCnt</td>\n},
		  qq{<td class="tdc">$stddev</td>\n},
		  qq{<td class="tdc">$mean</td>\n},
		  qq{<td class="tdc">$min</td>\n},
		  qq{<td class="tdc">$max</td>\n},
		  qq{</tr>};

		if ( $platformCnt != $tot ) {
			print qq{<tr><td class="tdc" colspan="8"><font color="red">\tCounts are not equal!</font></td></tr>\n};
		}

		my ( $plotFile, $pmap ) = testgdb::plot::createExpPlot( $plottype, $stddev, $cntlgenomeacc, \%plotTestdata, \%plotCntldata );
		print qq{<tr><td class="tdc" colspan="8"><img alt="" src="/tmpimage/$plotFile" border="1" usemap="#$testgdb::webUtil::frmData{id}"></td></tr>}, qq{<map name="$testgdb::webUtil::frmData{id}">$pmap</map>\n},

		  qq{<tr><td class="tdc" colspan="8">\n},
qq{<input class="ebtn" type="button" value="View data" onclick="window.open('$ENV{REQUEST_URI}?ajax=accinfo&accinfo=viewPlotData&fname=$dataFilename&samp=Average ($avgsname)','_blank')" onmouseover="this.style.cursor='pointer';return overlib('View data (new window)');" onmouseout="return nd();">\n},
qq{<input class="ebtn" type="button" value="Download data" onclick="window.open('$testgdb::util::urlpath/download.pl?type=plotdata&fname=$dataFilename&samp=Average ($avgsname)','_blank')" onmouseover="this.style.cursor='pointer';return overlib('Download data');" onmouseout="return nd();">\n},
		  qq{</td></tr>\n},
		  qq{</table>\n};

		if ( $testgdb::webUtil::useracclevel > 2 ) {
			#save Avg experiment
			@sampname = sort(@sampname);
			$savExpInfo{samples} = join( ',', @sampname );
			$savExpInfo{expstddev} = $stddev;
			savExp( $testgdb::webUtil::frmData{id}, $testgdb::webUtil::frmData{id}, $dataFilename, \%chanSource, \%savExpInfo );
		}
	} #end average
}

#----------------------------------------------------------------------
# writeDataToFile
# input: filename, test hashref, cntl hashref
# return: none
#----------------------------------------------------------------------
sub writeDataToFile {
	my ( $genomeacc, $plotTestdataRef, $plotCntldataRef ) = @_;
	my %plotTestdata = %$plotTestdataRef;
	my %plotCntldata = %$plotCntldataRef;

	my $geneLocRef = testgdb::oracle::dbgetGeneLoc($genomeacc);	#genome gene and start
	my %geneLoc    = %$geneLocRef;
	
	my $fpath        = "/run/shm/";
	my $dataFilename = "pdata" . int( rand(100000) );
	while ( -e "$fpath$dataFilename" ) {
		$dataFilename = "pdata" . int( rand(100000) );
	}

	open( DOUT, ">/run/shm/$dataFilename" );
	print DOUT "GENE\tLTAG\tAVERAGE\tRATIO\n";
	for my $id_ref ( sort keys %plotCntldata ) {
		my $gene = $id_ref;
		print DOUT "$gene\t$id_ref\t$plotTestdata{$id_ref}\t$plotCntldata{$id_ref}\n";
	}
	close DOUT;
	
	return $dataFilename;
}

#----------------------------------------------------------------------
# writeDataToFile
# input: filename, test hashref, cntl hashref
# return: none
#----------------------------------------------------------------------
sub xxx_Save___writeDataToFile {
	my ( $genomeacc, $plotTestdataRef, $plotCntldataRef ) = @_;
	my %plotTestdata = %$plotTestdataRef;
	my %plotCntldata = %$plotCntldataRef;

	my $geneLocRef = testgdb::oracle::dbgetGeneLoc($genomeacc);	#genome gene and start
	my %geneLoc    = %$geneLocRef;
	
	my $NSgeneLocRef = testgdb::oracle::dbgetNSgeneLoc($genomeacc);
	my %NSgeneLoc    = %$NSgeneLocRef;

	my $fpath        = "/run/shm/";
	my $dataFilename = "pdata" . int( rand(100000) );
	while ( -e "$fpath$dataFilename" ) {
		$dataFilename = "pdata" . int( rand(100000) );
	}

	open( DOUT, ">/run/shm/$dataFilename" );
	print DOUT "GENE\tLTAG\tAVERAGE\tRATIO\n";
	for my $id_ref ( sort keys %plotCntldata ) {
		my $gene = $id_ref;
		if ( exists $geneLoc{$id_ref} ) {
			$gene = $geneLoc{$id_ref}{gene}	if $geneLoc{$id_ref}{gene};
		} else {
			if (exists $NSgeneLoc{$id_ref}) {
				$gene = $geneLoc{$NSgeneLoc{$id_ref}}{gene}	if $geneLoc{$NSgeneLoc{$id_ref}}{gene};
			}
		}
		print DOUT "$gene\t$id_ref\t$plotTestdata{$id_ref}\t$plotCntldata{$id_ref}\n";
	}
	close DOUT;
	
	return $dataFilename;
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

	my $fileid     = "/run/shm/loess" . int( rand(100000) );
	my $filedataIn = $fileid . ".in";
	while ( -e $filedataIn ) {
		$fileid     = "/run/shm/loess" . int( rand(100000) );
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

	#my $cmd    = "/usr/local/bin/R CMD BATCH --no-save $fileR $filelog";

	my $cmd    = "/usr/bin/R CMD BATCH --no-save $fileR $filelog";
	my $result = `$cmd 2>&1`;                                              #-- capture STDERR as well as STDOUT

	return $filedataOut;
}

#----------------------------------------------------------------------
# Display Plot data in new window
# input: none
# return: none
#----------------------------------------------------------------------
sub viewPlotData {

	print qq{<html><head><title>$testgdb::webUtil::frmData{samp} Plot Data</title>\n},
	  qq{<link rel="stylesheet" type="text/css" href="/web/css/main.css">\n},
	  qq{<script type="text/javascript" src="/web/js/sorttable2.js"></script>\n},
	  qq{</head><body>\n};

	my $opened = open( FILE, "/run/shm/$testgdb::webUtil::frmData{fname}" );
	if ($opened) {
		my @data = <FILE>;
		close(FILE);

		my $rec = @data;
		$rec--;    #do not count heading
		print qq{<pre>\n},
		  qq{<b>$testgdb::webUtil::frmData{samp}</b>\n},
		  qq{Data Recs: <b>$rec</b>\n},
		  
		  qq{\nLABELS\n},
		  qq{GENE\tName\n},
		  qq{LTAG\tLocus_Tag\n},
		  qq{Ratio (M)\tTest/Control\n},
		  qq{Average (A)\t0.5*(Test+Control)\n},
		  qq{Test Int\tTest Intensity\n},
		  qq{Cntl Int\tControl Intensity\n\n},
		  
		  qq{<span class="small">* click column heading to sort.</span>\n},
		  qq{</pre>\n},
		  qq{<table class="sortable" cellpadding="1"  cellspacing="1">\n};

		my ( $gene, $ltag, $test, $cntl ) = split( /\t/, $data[0] );
		shift(@data);
		print 
		  qq{<tr class="thc">\n}, 
		  qq{<th>$gene</th>\n}, 
		  qq{<th>$ltag</th>\n}, 
		  qq{<th class="sorttable_numeric">$cntl (M)</th>\n}, 
		  qq{<th class="sorttable_numeric">$test (A)</th>\n}, 
		  qq{<th class="sorttable_numeric">Test Int</th>\n}, 
		  qq{<th class="sorttable_numeric">Cntl Int</th>\n}, 
		  qq{</tr>\n};

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
			
			print 
			  qq{<tr bgcolor="#EBF0F2">\n}, 
			  qq{<td class="tdl">$gene</td>\n}, 
			  qq{<td class="tdl">$ltag</td>\n}, 
			  qq{<td class="tdr">$cntl</td>\n}, 
			  qq{<td class="tdr">$test</td>\n}, 
			  qq{<td class="tdr">$testint</td>\n}, 
			  qq{<td class="tdr">$cntlint</td>\n}, 
			  qq{</tr>\n};
		}
		print qq{</table>\n};
	}
	print qq{</body></html>\n};
}

#----------------------------------------------------------------------
# Prompt to Save Experiment
# input: hash
# return: none
#----------------------------------------------------------------------
sub savExp {
	my ( $selid, $inputid, $dataFilename, $chanSourceRef, $savExpInfoRef ) = @_;
	my %chanSource = %$chanSourceRef;
	my %savExpInfo = %$savExpInfoRef;

	my $expname = '';
	for my $chan ( sort keys %chanSource ) {
		for my $desc ( keys %{ $chanSource{$chan} } ) {
			$expname .= $chanSource{$chan}{$desc} . ';';
		}
		$expname =~ s/\;$//;
		$expname .= ' / ';
	}
	$expname =~ s/ \/ $//;
	print qq{<table align="center" cellpadding="1"  cellspacing="1">\n},
	  qq{<tr>},
	  qq{<td class="tdr"><b>ExpName:</b></td>},
	  qq{<td><input class="small" type="text" size="112" maxlength="250" id="expname$inputid" value="$expname"></td>},
qq{<td onmouseover="this.style.cursor='pointer';return overlib('Swap ExpName conditions. (Chan1 / Chan2)');" onmouseout="return nd();"><input class="ebtn" type="button" value="Swap Conditions" onclick="swapcond($inputid)"></td>},
	  qq{</tr>},
	  qq{<tr>},
	  qq{<td class="tdr" valign="top"><b>Infomation:</b></td>\n},
	  qq{<td class="tdl"><textarea class="small" id="info$inputid" rows="3" cols="110"></textarea></td>},
	  qq{</tr>},
	  qq{<tr>},
	  qq{<td></td>\n},
	  qq{<td><input class="ebtn" type="button" value="Save Experiment" onclick="savExptoDB(event,$selid,$inputid)"></td>\n},
	  qq{</tr>},
	  qq{</table>};

	$savExpInfo{dataFilename} = $dataFilename;
	testgdb::webUtil::putSessVar( 'savExpInfo', \%savExpInfo );
}

#----------------------------------------------------------------------
# Save Experiment to database
# input: none
# return: none
#----------------------------------------------------------------------
sub savExptoDB {

	my $savExpInfoRef = testgdb::webUtil::getSessVar( 'savExpInfo' );

	my $rc = testgdb::oracle::dbsaveExptoDB($savExpInfoRef);
	if ($rc) {
		print qq{<font color="green">* * * Experiment added successfull. * * *</font>};
	}else{
		print qq{<font color="red">* * * Error adding experiment!! * * *</font>};
	}

	testgdb::webUtil::putSessVar( 'savExpInfo', '' );    #empty after save
}


1;                                                   # return a true value

