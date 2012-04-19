#------------------------------------------------------------------------------------------
# FileName    : gdb/annotation.pm
#
# Description : Annotation
# Author      : jgrissom
# DateCreated : 22 Sep 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package testgdb::annotation;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

#----------------------------------------------------------------------
# Display Annotation
# input: none
# return: none
#----------------------------------------------------------------------
sub displayAnnotation {

	my $qryltagRef = testgdb::webUtil::getSessVar( 'qryltag' );
	return if !$qryltagRef->{0};

	my $parms = testgdb::webUtil::getSessVar( 'parms' );
	
	return if ! $parms->{currquery};
	
	if ( $testgdb::webUtil::frmData{ginfo} and $testgdb::webUtil::frmData{ginfo} =~ /^annotation/ ) {
		#ajax call
		$parms->{annotation} = ( $parms->{annotation} ) ? 0 : 1;
		testgdb::webUtil::putSessVar( 'parms', $parms );
		annotation() if ( $parms->{annotation} );
	} else {
		if ( $parms->{annotation} ) {
			print qq{<div class="mn2" style="border-top:1px solid #C3CCD3;"><span onclick="da('annotation');" onmouseover="mm(this,'annotation');" onmouseout="return nd();"><img id="annotationsign" src="$testgdb::util::webloc/web/minus.gif" alt=""> Annotation</span></div>};
			print qq{<div class="showrec" id="annotation">};
			annotation();
			print qq{</div>\n};
		} else {
			print qq{<div class="mn2" style="border-top:1px solid #C3CCD3;"><span onclick="da('annotation');" onmouseover="mm(this,'annotation');" onmouseout="return nd();"><img id="annotationsign" src="$testgdb::util::webloc/web/plus.gif" alt=""> Annotation</span></div>};
			print qq{<div class="hidden" id="annotation"></div>\n};
		}
	}
}

#----------------------------------------------------------------------
# Display annotation Info
# input: none
# return: none
#----------------------------------------------------------------------
sub annotation {

	my $qryltagRef = testgdb::webUtil::getSessVar( 'qryltag' );
	my %qryltag = %$qryltagRef;
	
	for my $i ( sort { $a <=> $b } keys %qryltag ) {
		my $ltag = $qryltag{$i}{ltag};
		my $genomeacc = $qryltag{$i}{genome};
		
		my $dbannotRec = testgdb::oracle::dbannotInfo($ltag, $genomeacc);
		my %dbannot    = %$dbannotRec;

		next if ( !$dbannot{locus_tag} );    #ltag not found
		
		my $operon = testgdb::oracle::dbgetoperon( $dbannot{locus_tag} );

		my $dbregulatorsRec = testgdb::oracle::dbgetregulators( $dbannot{locus_tag} );
		my %dbregulators    = %$dbregulatorsRec;

		my $dbsigmaRec = testgdb::oracle::dbgetsigma( $dbannot{locus_tag} );
		my %dbsigma    = %$dbsigmaRec;

		my $dbmfunLevelsRec = testgdb::oracle::dbgetmfunLevels( $dbannot{locus_tag} );
		my %dbmfunLevels    = %$dbmfunLevelsRec;

		my $dbpathwaysRec = testgdb::oracle::dbgetpathways( $dbannot{gene} );
		my %dbpathways    = %$dbpathwaysRec;

		my $metalink = testgdb::webUtil::metalinks($dbannotRec);
		
		print
		  qq{<table>\n},
		  qq{<tr>\n}, qq{<th class="thc">META LINKS</th>\n}, qq{<th class="thc">GENE</th>\n}, qq{<th class="thc">LOCUS</th>\n}, qq{<th class="thc">FEATURE</th>\n};
		print qq{<th class="thc">SYNONYMS</th>\n}     if $dbannot{synonyms};
		print qq{<th class="thc">OLD LOCUSTAG</th>\n} if $dbannot{old_locus_tag};
		print qq{<th class="thc">LEFT END</th>\n};
		print qq{<th class="thc">JOIN</th>\n} if $dbannot{join};
		print
		  qq{<th class="thc">RIGHT END</th>\n},
		  qq{<th class="thc">LEN</th>\n},
		  qq{<th class="thc" onmouseover="return overlib('Direction:<br>cw=Clockwise<br>ccw=CounterClockwise');" onmouseout="return nd();">DIR</th>\n};
		print qq{<th class="thc">OPERON</th>\n}       if $operon;
		print qq{<th class="thc">REGULATED BY</th>\n} if $dbregulators{0}{gene};
		print qq{<th class="thc">SIGMA</th>\n}        if $dbsigma{0};
		print qq{<th class="thc">MULTIFUN</th>\n}     if $dbmfunLevels{0}{level};
		print qq{<th class="thc">PATHWAY</th>\n}      if $dbpathways{0}{uniqueid};
		print qq{<th class="thc">PRODUCT</th>\n}      if $dbannot{product};
		print qq{<th class="thc">FUNCTION</th>\n}     if $dbannot{function};
		print qq{<th class="thc">NOTE</th>\n}         if $dbannot{note};

		my @ts1 = split( /,/, $dbannot{sstart} );
		my @ts2 = split( /,/, $dbannot{sstop} );
		my $len = ($ts2[0] - $ts1[0]) + 1;
		if ($ts1[1]) {
			my $ln2 = ($ts2[1] - $ts1[1]) + 1;
			$len = "$len,$ln2";
		}
		
		print
		  qq{</tr>\n},
		  qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="tdc">$metalink</td>\n},

		  qq{<td class="tdc">$dbannot{gene}</td>\n}, 
		  qq{<td class="tdc"><a onclick="ckqry('$dbannot{locus_tag}');" onmouseover="this.style.cursor='pointer';return overlib('Query $dbannot{locus_tag}');" onmouseout="return nd();">$dbannot{locus_tag}</a></td>\n}, 
		  qq{<td class="tdc">$dbannot{feature}</td>\n};
		print qq{<td class="tdc">$dbannot{synonyms}</td>\n}      if $dbannot{synonyms};
		print qq{<td class="tdc">$dbannot{old_locus_tag}</td>\n} if $dbannot{old_locus_tag};
		
		print qq{<td class="tdc">$dbannot{sstart}</td>\n};
		print qq{<td class="tdc">$dbannot{join}</td>\n} if $dbannot{join};
		print qq{<td class="tdc">$dbannot{sstop}</td>\n},
			qq{<td class="tdc">$len</td>\n},
		  qq{<td class="tdc" onmouseover="return overlib('Direction:<br>cw=Clockwise<br>ccw=CounterClockwise');" onmouseout="return nd();">$dbannot{orientation}</td>\n};

		print qq{<td class="tdc"><a onclick="supp('operon','$operon','$ltag');" onmouseover="this.style.cursor='pointer';return overlib('Display genes for the operon $operon');" onmouseout="return nd();">$operon</a></td>\n}  if $operon;

		if ( $dbregulators{0}{gene} ) {
			my $reg = '';
			for my $i ( sort { $a <=> $b } keys %dbregulators ) {
				$reg .= qq{<a onclick="supp('regs','$dbregulators{$i}{gene}','$ltag');" onmouseover="this.style.cursor='pointer';return overlib('Display genes regulated by $dbregulators{$i}{gene}');" onmouseout="return nd();">$dbregulators{$i}{gene}</a>$dbregulators{$i}{effect}, };
			}
			$reg =~ s/\, $//;    #remove trailing ', '
			print qq{<td class="tdc">$reg</td>\n};
		}
		if ( $dbsigma{0} ) {
			my $sigma = '';
			for my $i ( sort { $a <=> $b } keys %dbsigma ) {
				$sigma .= qq{<a onclick="supp('sigma','$dbsigma{$i}','$ltag');" onmouseover="this.style.cursor='pointer';return overlib('Display Sigma genes regulated by $dbsigma{$i}');" onmouseout="return nd();">$dbsigma{$i}</a>, };
			}
			$sigma =~ s/\, $//;
			print qq{<td class="tdc">$sigma</td>\n};
		}
		if ( $dbmfunLevels{0}{level} ) {
			my $mfun = '';
			for my $i ( sort { $a <=> $b } keys %dbmfunLevels ) {
				$mfun .= qq{<a onclick="supp('mfun','$dbmfunLevels{$i}{level}','$ltag');" onmouseover="this.style.cursor='pointer';return overlib('$dbmfunLevels{$i}{function}');" onmouseout="return nd();">$dbmfunLevels{$i}{level}</a>, };
			}
			$mfun =~ s/\, $//;
			print qq{<td class="tdc">$mfun</td>\n};
		}
		if ( $dbpathways{0}{uniqueid} ) {
			my $pway = '';
			for my $i ( sort { $a <=> $b } keys %dbpathways ) {
				$pway .= qq{<a onclick="supp('pway','$dbpathways{$i}{uniqueid}','$ltag');" onmouseover="this.style.cursor='pointer';return overlib('$dbpathways{$i}{name}');" onmouseout="return nd();">$dbpathways{$i}{uniqueid}</a>, };
			}
			$pway =~ s/\, $//;
			print qq{<td class="tdc">$pway</td>\n};
		}
		print qq{<td class="tdl">$dbannot{product}</td>\n}  if $dbannot{product};
		print qq{<td class="tdl">$dbannot{function}</td>\n} if $dbannot{function};
		print qq{<td class="tdl">$dbannot{note}</td>\n}     if $dbannot{note};
		print qq{</tr>\n}, qq{</table>\n};

		#hidden ajax divs
		print qq{<div class="hidden" id="supp$ltag"></div>\n};		
		
	}
}

#----------------------------------------------------------------------
# Display genes in Operon
# input: none
# return: none
#----------------------------------------------------------------------
sub genesInOperon {

	my $dboperonRec = testgdb::oracle::dbgetgenesInOperon( $testgdb::webUtil::frmData{sval} );
	my %dboperon    = %$dboperonRec;
	my $size        = scalar keys %dboperon;

	print qq{<hr>\n}, qq{<a class="exmp" onclick="sh('supp$testgdb::webUtil::frmData{ltag}');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a>\n},

	  qq{<div style="margin-left:20px;">\n},

	  qq{<input type="hidden" name="annottype" value="Annotation-Operon">\n},
	  qq{<input type="hidden" name="annotqry" value="$testgdb::webUtil::frmData{sval}">\n},
	  qq{<table>\n},
	  qq{<tr>\n},
	  qq{<td colspan="4"><input class="ebtn" type="submit" name="qryannot" value="Query Selected"></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td colspan="4">Operon: $testgdb::webUtil::frmData{sval} ($size genes)</td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
qq{<th class="thc" onmouseover="return overlib('Select/Unselect all');" onmouseout="return nd();"><input id="ckallid" type="checkbox" name="ckallid" onclick="ckall(this,'qrySelected');"></th>\n},
	  qq{<th class="thc">GENE</th>\n},
	  qq{<th class="thc">LOCUSTAG</th>\n},
	  qq{<th class="thc">DIRECTION</th>\n},
	  qq{</tr>\n};

	for my $i ( sort { $a <=> $b } keys %dboperon ) {
		print
		  qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="tdc"><input class="small" type="checkbox" name="qrySelected" value="$dboperon{$i}{gene}"></td>\n},
		  qq{<td class="tdc">$dboperon{$i}{gene}</td>\n},
qq{<td class="tdc"><a onclick="ckqry('$dboperon{$i}{locustag}');" onmouseover="this.style.cursor='pointer';return overlib('Query $dboperon{$i}{locustag}');" onmouseout="return nd();">$dboperon{$i}{locustag}</a></td>\n},
		  qq{<td class="tdc">$dboperon{$i}{direction}</td>\n},
		  qq{</tr>\n};
	}

	print
	  qq{</table>\n},
	  qq{<span class="small">Recs: <b>$size</b></span>\n},
	  qq{</div>\n},
	  qq{<br/>\n};
}

#----------------------------------------------------------------------
# Display genes in regulon
# input: none
# return: none
#----------------------------------------------------------------------
sub genesInRegulon {

	my $dbregulonRec = testgdb::oracle::dbgetgenesInRegulon( $testgdb::webUtil::frmData{sval} );
	my %dbregulon    = %$dbregulonRec;
	my $size         = scalar keys %dbregulon;

	print qq{<hr>\n}, qq{<a class="exmp" onclick="sh('supp$testgdb::webUtil::frmData{ltag}');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a>\n},

	  qq{<div style="margin-left:20px;">\n},

	  qq{<input type="hidden" name="annottype" value="Annotation-Regulon">\n},
	  qq{<input type="hidden" name="annotqry" value="$testgdb::webUtil::frmData{sval}">\n},
	  qq{<table>\n},
	  qq{<tr>\n},
	  qq{<td colspan="4"><input class="ebtn" type="submit" name="qryannot" value="Query Selected"></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td colspan="4">Regulon: $testgdb::webUtil::frmData{sval} ($size genes)</td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
qq{<th class="thc" onmouseover="return overlib('Select/Unselect all');" onmouseout="return nd();"><input id="ckallid" type="checkbox" name="ckallid" onclick="ckall(this,'qrySelected');"></th>\n},
	  qq{<th class="thc">GENE</th>\n},
	  qq{<th class="thc">LOCUSTAG</th>\n},
	  qq{<th class="thc">EVIDENCE</th>\n},
	  qq{</tr>\n};

	for my $i ( sort { $a <=> $b } keys %dbregulon ) {
		print
		  qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="tdc"><input class="small" type="checkbox" name="qrySelected" value="$dbregulon{$i}{gene}"></td>\n},
		  qq{<td class="tdl">$dbregulon{$i}{gene}$dbregulon{$i}{effect}</td>\n},
qq{<td class="tdc"><a onclick="ckqry('$dbregulon{$i}{locustag}');" onmouseover="this.style.cursor='pointer';return overlib('Query $dbregulon{$i}{locustag}');" onmouseout="return nd();">$dbregulon{$i}{locustag}</a></td>\n},
		  qq{<td class="tdl">$dbregulon{$i}{evidence}</td>\n},
		  qq{</tr>\n};
	}

	print
	  qq{</table>\n},
	  qq{<span class="small">Recs: <b>$size</b></span>\n},
	  qq{</div>\n},
	  qq{<br/>\n};
}

#----------------------------------------------------------------------
# Display genes in sigma
# input: none
# return: none
#----------------------------------------------------------------------
sub genesInSigma {

	my $dbsigmaRec = testgdb::oracle::dbgetgenesInSigma( $testgdb::webUtil::frmData{sval} );
	my %dbsigma    = %$dbsigmaRec;
	my $size       = scalar keys %dbsigma;

	print qq{<hr>\n}, qq{<a class="exmp" onclick="sh('supp$testgdb::webUtil::frmData{ltag}');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a>\n},

	  qq{<div style="margin-left:20px;">\n},

	  qq{<input type="hidden" name="annottype" value="Annotation-Sigma">\n},
	  qq{<input type="hidden" name="annotqry" value="$testgdb::webUtil::frmData{sval}">\n},
	  qq{<table>\n},
	  qq{<tr>\n},
	  qq{<td colspan="4"><input class="ebtn" type="submit" name="qryannot" value="Query Selected"></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td colspan="4">Sigma: $testgdb::webUtil::frmData{sval} ($size genes)</td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
qq{<th class="thc" onmouseover="return overlib('Select/Unselect all');" onmouseout="return nd();"><input id="ckallid" type="checkbox" name="ckallid" onclick="ckall(this,'qrySelected');"></th>\n},
	  qq{<th class="thc">GENE</th>\n},
	  qq{<th class="thc">LOCUSTAG</th>\n},
	  qq{</tr>\n};

	for my $i ( sort { $a <=> $b } keys %dbsigma ) {
		print
		  qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="tdc"><input class="small" type="checkbox" name="qrySelected" value="$dbsigma{$i}{gene}"></td>\n},
		  qq{<td class="tdl">$dbsigma{$i}{gene}</td>\n},
qq{<td class="tdc"><a onclick="ckqry('$dbsigma{$i}{locustag}');" onmouseover="this.style.cursor='pointer';return overlib('Query $dbsigma{$i}{locustag}');" onmouseout="return nd();">$dbsigma{$i}{locustag}</a></td>\n},
		  qq{</tr>\n};
	}

	print
	  qq{</table>\n},
	  qq{<span class="small">Recs: <b>$size</b></span>\n},
	  qq{</div>\n},
	  qq{<br/>\n};
}

#----------------------------------------------------------------------
# Display genes in multifun
# input: none
# return: none
#----------------------------------------------------------------------
sub genesInMfun {

	my $dbmfunRec = testgdb::oracle::dbgetgenesinMfun( $testgdb::webUtil::frmData{sval} );
	my %dbmfun    = %$dbmfunRec;
	my $size      = scalar keys %dbmfun;

	print qq{<hr>\n}, qq{<a class="exmp" onclick="sh('supp$testgdb::webUtil::frmData{ltag}');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a>\n},

	  qq{<div style="margin-left:20px;">\n},

	  qq{<input type="hidden" name="annottype" value="Annotation-MultiFun">\n},
	  qq{<input type="hidden" name="annotqry" value="$testgdb::webUtil::frmData{sval}">\n},
	  qq{<table>\n},
	  qq{<tr>\n},
	  qq{<td colspan="3"><input class="ebtn" type="submit" name="qryannot" value="Query Selected"></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td colspan="3">Multifun: $testgdb::webUtil::frmData{sval} ($size genes)</td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
qq{<th class="thc" onmouseover="return overlib('Select/Unselect all');" onmouseout="return nd();"><input id="ckallid" type="checkbox" name="ckallid" onclick="ckall(this,'qrySelected');"></th>\n},
	  qq{<th class="thc">LOCUSTAG</th>\n},
	  qq{<th class="thc">FUNCTION</th>\n},
	  qq{</tr>\n};

	for my $i ( sort { $a <=> $b } keys %dbmfun ) {
		print
		  qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="tdc"><input class="small" type="checkbox" name="qrySelected" value="$dbmfun{$i}{locustag}"></td>\n},
qq{<td class="tdc"><a onclick="ckqry('$dbmfun{$i}{locustag}');" onmouseover="this.style.cursor='pointer';return overlib('Query $dbmfun{$i}{locustag}');" onmouseout="return nd();">$dbmfun{$i}{locustag}</a></td>\n},
		  qq{<td class="tdl">$dbmfun{$i}{mfunction}</td>\n},
		  qq{</tr>\n};
	}

	print
	  qq{</table>\n},
	  qq{<span class="small">Recs: <b>$size</b></span>\n},
	  qq{</div>\n},
	  qq{<br/>\n};
}

#----------------------------------------------------------------------
# Display genes in pathway
# input: none
# return: none
#----------------------------------------------------------------------
sub genesInPway {

	my $dbpwayRec = testgdb::oracle::dbgetgenesinPway( $testgdb::webUtil::frmData{sval} );
	my %dbpway    = %$dbpwayRec;
	my $size      = scalar keys %dbpway;

	print qq{<hr>\n}, qq{<a class="exmp" onclick="sh('supp$testgdb::webUtil::frmData{ltag}');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a>\n},

	  qq{<div style="margin-left:20px;">\n},

	  qq{<input type="hidden" name="annottype" value="Annotation-Pathway">\n},
	  qq{<input type="hidden" name="annotqry" value="$testgdb::webUtil::frmData{sval}">\n},
	  qq{<table>\n},
	  qq{<tr>\n},
	  qq{<td colspan="3"><input class="ebtn" type="submit" name="qryannot" value="Query Selected"></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td colspan="3">Pathway: $testgdb::webUtil::frmData{sval} ($size genes)</td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
qq{<th class="thc" onmouseover="return overlib('Select/Unselect all');" onmouseout="return nd();"><input id="ckallid" type="checkbox" name="ckallid" onclick="ckall(this,'qrySelected');"></th>\n},
	  qq{<th class="thc">GENE</th>\n},
	  qq{<th class="thc">NAME</th>\n},
	  qq{</tr>\n};

	for my $gene ( sort keys %dbpway ) {
		print
		  qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="tdc"><input class="small" type="checkbox" name="qrySelected" value="$gene"></td>\n},
		  qq{<td class="tdl"><a onclick="ckqry('$gene');" onmouseover="this.style.cursor='pointer';return overlib('Query $gene');" onmouseout="return nd();">$gene</a></td>\n},
		  qq{<td class="tdl">$dbpway{$gene}</td>\n},
		  qq{</tr>\n};
	}

	print
	  qq{</table>\n},
	  qq{<span class="small">Recs: <b>$size</b></span>\n},
	  qq{</div>\n},
	  qq{<br/>\n};
}

#----------------------------------------------------------------------
# Display Full query
# input: none
# return: none
#----------------------------------------------------------------------
sub displayFullqry {

	my $fullqryRef = testgdb::webUtil::getSessVar( 'fullqry' );
	my @fullqry = @$fullqryRef;
	my $cnt = @fullqry;
	
	print qq{<a class="exmp" onclick="sh('ginfo');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a>\n},

	  qq{<div style="margin-left:20px;">\n},

	  qq{<input type="hidden" name="annottype" value="Full List">\n},
	  qq{<input type="hidden" name="annotqry" value="Full List">\n},
	  qq{<table>\n},
	  qq{<tr>\n},
	  qq{<td colspan="4"><input class="ebtn" type="submit" name="qryannot" value="Query Selected"></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td colspan="4">Full List: ($cnt genes)</td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<th class="thc" onmouseover="return overlib('Select/Unselect all');" onmouseout="return nd();"><input id="ckallid" type="checkbox" name="ckallid" onclick="ckall(this,'qrySelected');"></th>\n},
	  qq{<th class="thc">GENE</th>\n},
	  qq{</tr>\n};

	for my $gene (@fullqry) {
		$gene =~ s/\s+//g;
		my $checked =  '' ;
		print
		  qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="tdc"><input class="small" type="checkbox" name="qrySelected" value="$gene" $checked></td>\n},
		  qq{<td class="tdc">$gene</td>\n},
		  qq{</tr>\n};
	}

	print
	  qq{</table>\n},
	  qq{<span class="small">Recs: <b>$cnt</b></span>\n},
	  qq{</div>\n},
	  qq{<br/>\n};	

}


1;                                                   # return a true value
