#------------------------------------------------------------------------------------------
# FileName    : gdb/heatmap.pm
#
# Description : Display Heatmap
# Author      : jgrissom
# DateCreated : 21 Sep 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package gdb::heatmap;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";

#----------------------------------------------------------------------
# Display Heatmap Info
# input: none
# return: none
#----------------------------------------------------------------------
sub heatmap {
	
	gdb::webUtil::putSessVar( 'acchm',   '' );    #clear
	
	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $legendFile = 'legendBlueYellow.png';
	if ( $parms->{color} == 2 ) {
		$legendFile = 'legendRedGreen.png';
	} elsif ( $parms->{color} == 3 ) {
		$legendFile = 'legendMulti.png';
	}
	my $white = sprintf( "#%02X%02X%02X", 255, 255, 255 );
	my $grey1 = sprintf( "#%02X%02X%02X", 238, 238, 238 );
	my $grey2 = sprintf( "#%02X%02X%02X", 200, 200, 200 );
	my $grey3 = sprintf( "#%02X%02X%02X", 155, 155, 155 );
	my $grey4 = sprintf( "#%02X%02X%02X", 130, 130, 130 );

	my $genomeacc = $gdb::util::gnom{$parms->{genome}}{acc};
	my @newqry  = ckQryLoc( $parms->{currquery}, $genomeacc );
	my $qryCnt  = @newqry;
	my $dispnum = ( $parms->{currqtype} and $parms->{currqtype} =~ /^PearsonCorr/ ) ? $parms->{prows} : $parms->{dnum};
	my $wrap = ( $parms->{currqtype} and $parms->{currqtype} =~ /^PearsonCorr/ ) ? 0 : $parms->{wrap};

	if ( $qryCnt > $parms->{dnum} ) {
		gdb::webUtil::putSessVar( 'fullqry', \@newqry );
		gdb::webUtil::putSessVar( 'parms',   $parms );
		@newqry = @newqry[ 0 .. $dispnum - 1 ];
		$parms->{currquery} = join( ', ', @newqry );
	}
	
	print qq{<script type="text/javascript">statbar('show');</script>\n};
	$gdb::webUtil::r->rflush;
	
	print "<hr>";
	print qq{<div class="small">Genome: <b>$gdb::util::gnom{$parms->{genome}}{lname}</b></div>\n};
	print qq{<div class="small">$parms->{experiment}</div>\n} if $parms->{experiment};
	print qq{<div class="small">$parms->{currqtype}</div>\n}  if $parms->{currqtype};

	if ( $qryCnt > $dispnum ) {
		print qq{<div class="small">Query: ( <a class="exmp" onclick="gm('fullqry');" onmouseover="return overlib('Display full list of results');" onmouseout="return nd();">$qryCnt</a> ) <b>$parms->{currquery}</b></div>\n};
	} else {
		print qq{<div class="small">Query: ( $qryCnt ) <b>$parms->{currquery}</b></div>\n};
	}
	print qq{<div class="hidden" id="fullqry"></div>\n}       if ( $qryCnt > $dispnum );

	$gdb::webUtil::r->rflush;

	my $dbexpInfoRef = gdb::oracle::dbgetExpInfo( );
	my %dbexpInfo = %$dbexpInfoRef;

	#get the experiment count
	my $expCount = 0;
	for my $i ( keys %dbexpInfo ) {
#		next if ($dbexpInfo{$i}{cntlgenome} !~ /$gdb::util::gnom{$parms->{genome}}{acc}/i);
		$expCount++;
	}

	my $qryall      = join( ", ", @newqry );
	my $num_per_row = $expCount;
	if ( $expCount > 120 ) {
		$num_per_row = ( $wrap =~ /1/ ) ? sprintf( "%.0f", ( $expCount / $parms->{hmrows} ) ) : $expCount;
	}

	#setup user genome related
	my %genrel;
	if ($parms->{genrel} =~ /all/) {
		for my $i ( keys %gdb::util::gnom ) {
			$genrel{ $gdb::util::gnom{$i}{acc} } = 1;
		}
	}else{
		my @tmp = split( /~/, $parms->{genrel} );
		foreach my $t1 (@tmp) {
			$genrel{ $gdb::util::gnom{$t1}{acc} } = 1;
		}
	}

	my ( %ltags, %hminfo, %hmaps, %acchm, $rowCnt, $head, $ouid );
	my $hmcnt    = 0;
	my $j=0;
	foreach my $qry (@newqry) {
		my ( $tags, $olt, $ns ) = gdb::oracle::qryNS( $qry, $genomeacc );
		my %tags = %$tags;
		my %olt = %$olt;
		my %ns   = %$ns;
	
		my ( @ltags, $locusTag, $gene, %dispLtag );
	
		if ( ! %tags ) {    #no ltag found in reference genome, but we may have related
			print qq{<pre> $qry <font color="red">No information found!</font></pre>\n};
			if (%ns) {
				print qq{<div class="small">Related (<b>$qry</b>): };
				for my $ltag ( sort { lc($a) cmp lc($b) } keys %ns ) {
					next if (! exists $genrel{ $ns{$ltag} });
					push @ltags, $ltag;
					print qq{<a class="small" onclick="ckqry('$ltag');" onmouseover="this.style.cursor='pointer';return overlib('Query for $gdb::util::gnom{$gdb::util::gnomacc{$ns{$ltag}}}{sname}:$ltag');" onmouseout="return nd();">$ltag</a>&nbsp;&nbsp; };
				}
				print qq{</div>\n};
			}
			next;
		}
		
		for my $ltag ( sort { lc($a) cmp lc($b) } keys %tags ) {
			push @ltags, $ltag;
			$locusTag = $ltag;
			$ltags{$j}{ltag} = $ltag;
			$ltags{$j}{genome} = $tags{$ltag};
			$j++;
		}
		
		my $dbgene = gdb::oracle::dbgetGene($locusTag, $genomeacc);
		$gene = ($dbgene) ? $dbgene : $locusTag; 
	
		if (scalar keys %tags > 1) {
			print qq{<div class="small"> * Multiple locusTags found for <b>$qry</b></div>\n};
			next;
		}
		
		if ( %olt) {
			for my $ltag ( sort { lc($a) cmp lc($b) } keys %olt ) {
				push @ltags, $ltag;
			}
			my $cmb = join( ',', @ltags );
			print qq{<div class="small">Combined/Averaged (<b>$qry</b>): $cmb</div>\n};
		}
		
		if (%ns) {
			print qq{<div class="small">Related (<b>$qry</b>): };
			for my $ltag ( sort { lc($a) cmp lc($b) } keys %ns ) {
				next if (! exists $genrel{ $ns{$ltag} });
				push @ltags, $ltag;
				print qq{<a class="small" onclick="ckqry('$ltag');" onmouseover="this.style.cursor='pointer';return overlib('Query for $gdb::util::gnom{$gdb::util::gnomacc{$ns{$ltag}}}{sname}:$ltag');" onmouseout="return nd();">$ltag</a>&nbsp;&nbsp; };
			}
			print qq{</div>\n};
		}
		
		my $dbHmDataRef = gdb::oracle::dbgetheatmapData( \@ltags );
		my %dbHmData = %$dbHmDataRef;
		
		if ( ! %dbHmData ) {    #no data found
			print qq{<pre> $qry <font color="red">No experiment data found!</font></pre>\n};
			next;
		}
		
		$hminfo{$hmcnt}{gene} = $gene;
		$hminfo{$hmcnt}{ltag} = $locusTag;
		
		$rowCnt = 0;
		$head   = 0;                #False
		$ouid   = 0;
		my $line   = '';
		my ($ratioColor, $ratio);
		for my $i ( sort { $a <=> $b } keys %dbexpInfo ) {
#			next if ($dbexpInfo{$i}{cntlgenome} !~ /$gdb::util::gnom{$parms->{genome}}{acc}/i);
			
			my $dltag = ($dbHmData{$dbexpInfo{$i}{id}}{locustag}) ? $dbHmData{$dbexpInfo{$i}{id}}{locustag} : '';
			$locusTag = ($dltag) ? $dltag : $qry;
			$dispLtag{$locusTag} = 1;
						
			#only show selected accessions
			if ( length( $parms->{accnid} ) > 1 ) {
				next if ( $dbexpInfo{$i}{accnid} and ( index( $parms->{accnid}, $dbexpInfo{$i}{accnid} ) < 0 ) );
			}
			#only show selected experiments
			if ( $parms->{expmtid} ) {
				next if ( $dbexpInfo{$i}{accnid} and ( index( $parms->{expmtid}, $dbexpInfo{$i}{accnid} ) >= 0 ) and ( index( $parms->{expmtid}, $dbexpInfo{$i}{id} ) < 0 ) );
			}
			if ( $parms->{foldck} and !$parms->{dmaccfold} ) {
				next if ( !$dbHmData{$dbexpInfo{$i}{id}}{ratio} );
				my $onlyfoldOK = ( ( $parms->{foldck} ) and ( abs( $dbHmData{$dbexpInfo{$i}{id}}{ratio} ) < ( $dbexpInfo{$i}{stddev} * $parms->{dfold} ) ) );
				next if $onlyfoldOK;
			}
			if ( $parms->{logck} and !$parms->{dmacclog} ) {
				next if ( !$dbHmData{$dbexpInfo{$i}{id}}{ratio} );
				my $onlylogOK = ( ( $parms->{logck} ) and ( abs( $dbHmData{$dbexpInfo{$i}{id}}{ratio} ) < $parms->{dlog} ) );
				next if $onlylogOK;
			}
			my $hm = '&nbsp;';
			
			if ( exists $dbHmData{$dbexpInfo{$i}{id}}{ratio} ) {
				if ( defined $dbHmData{$dbexpInfo{$i}{id}}{ratio} ) {
					my $foldOK = ( ( $parms->{foldck} ) and ( abs( $dbHmData{$dbexpInfo{$i}{id}}{ratio} ) < ( $dbexpInfo{$i}{stddev} * $parms->{dfold} ) ) );
					my $logOK = ( ( $parms->{logck} ) and ( abs( $dbHmData{$dbexpInfo{$i}{id}}{ratio} ) < $parms->{dlog} ) );
					if ( $foldOK and $logOK ) {
						$ratioColor = $grey4;
					} elsif ($foldOK) {
						$ratioColor = $grey3;
					} elsif ($logOK) {
						$ratioColor = $grey2;
					} else {
						my $ratioColorRef;
						if ( $parms->{color} eq 2 ) {
							$ratioColorRef = redGreencolor( $dbHmData{$dbexpInfo{$i}{id}}{ratio} );
						} elsif ( $parms->{color} eq 3 ) {
							$ratioColorRef = multicolor( $dbHmData{$dbexpInfo{$i}{id}}{ratio} );
						} else {
							$ratioColorRef = blueYellowcolor( $dbHmData{$dbexpInfo{$i}{id}}{ratio} );
						}
						$ratioColor = sprintf( "#%02X%02X%02X", @$ratioColorRef );
					}
					$ratio = sprintf( "%05.3f", $dbHmData{$dbexpInfo{$i}{id}}{ratio} );
				} else {
					$ratio      = 'null';    #experiment data exists but is null
					$ratioColor = $grey1;
				}
			} else {
				$ratio      = 'No data';    #Does not exists
				$ratioColor = $white;
				$hm         = '.';
			}
			
			if ( !$head ) {
				$head = 1;                  #true
				$line .= qq{<tr height="18" style="cursor:default;">\n};
			}
			if ( $rowCnt >= $num_per_row ) {
				$line .= qq{</tr><tr height="18" style="vertical-align:top;cursor:default;">\n};
				$rowCnt = 0;
			}
			
			++$ouid;
			my $click = qq{hmclk('$hmcnt','$dbexpInfo{$i}{id}','$gene','$locusTag','$qryall','$dbexpInfo{$i}{accnid}','$dbexpInfo{$i}{accession}');};
			my $dratio = ( $ratio =~ /^-?[\.|\d]*\Z/ and $ratio < 0 ) ? "<font color=red>$ratio</font>" : $ratio;
			my $genome = '';
#			my $genome = $gdb::util::gnom{$gdb::util::gnomacc{$dbexpInfo{$i}{cntlgenome}}}{sname};
			my $title = qq{<b>LocusTag:</b> $dltag<br><b>OUID:</b> $ouid<br><b>Accession:</b> $dbexpInfo{$i}{accession}<br><b>Ratio:</b> $dratio  &nbsp;&nbsp; <b>StdDev:</b> $dbexpInfo{$i}{stddev}  &nbsp;&nbsp; <b>Genome:</b> $genome<br><b>Title:</b> $dbexpInfo{$i}{accname}<br><b>ExpName:</b> $dbexpInfo{$i}{expname}};
			$line .= qq{<td class="tdc" width="8" style="background-color:$ratioColor;" onclick="$click" onmouseover="return overlib('$title',WIDTH,400);" onmouseout="return nd();">$hm</td>};
			
			$dbexpInfo{$i}{flag} ||= 1;    #logical or
			
			$hminfo{$hmcnt}{$i}{color} = $ratioColor;
			$hminfo{$hmcnt}{$i}{click} = $click;
			$hminfo{$hmcnt}{$i}{title} = $title;
			$hminfo{$hmcnt}{$i}{hm}    = $hm;
			
			if ( $hmcnt == 0 ) {

				#save only the first gene heatmap info for displaying in accession list
				$acchm{ $dbexpInfo{$i}{accnid} }{ $ouid }{expid}      = $dbexpInfo{$i}{id};
				$acchm{ $dbexpInfo{$i}{accnid} }{ $ouid }{title}      = ($title) ? $title : '';
				$acchm{ $dbexpInfo{$i}{accnid} }{ $ouid }{ratioColor} = ($ratioColor) ? $ratioColor : '';
				$acchm{ $dbexpInfo{$i}{accnid} }{ $ouid }{click}      = ($click) ? $click : '';
				$acchm{ $dbexpInfo{$i}{accnid} }{ $ouid }{hm}         = ($hm) ? $hm : '';
			}
			$rowCnt++;
		}	#end dbexpInfo
		
		$line .= qq{</tr>\n};
		$hmaps{$hmcnt}{gene} = $gene;
		my @ultag;
		for my $ltag ( sort { lc($a) cmp lc($b) } keys %dispLtag ) {
			push @ultag, $ltag;
		}
		$hmaps{$hmcnt}{info} = join( '<br>', @ultag );
		$hmcnt++;
	}	#end newqry

	if (%hminfo) {    #we have data, display heapmap
		print qq{<div class="small">Exceeds: <b>$parms->{dfold} * StdDev</b></div>\n}              if ( $parms->{foldck} );
		print qq{<div class="small">Greater than absolute value of: <b>$parms->{dlog}</b></div>\n} if ( $parms->{logck} );
		print
		  qq{<table align="center">\n},
		  qq{<tr><td class="hdln2">\n},
		  qq{Heatmap of gene expression ratios from all experiments for your query, displayed colorimetrically.  Mouseover heatmap bars to display experiment information.  Click on heatmap bar to display experiment in: },
		  qq{<span onmouseover="return overlib('Single experiment scatter plot');" onmouseout="return nd();" style="white-space:nowrap"><input class="small" type="radio" name="dopt" value="splot" checked>ScatterPlot </span>},
		  qq{<span onmouseover="return overlib('Multiple experiments line plot');" onmouseout="return nd();" style="white-space:nowrap"><input class="small" type="radio" name="dopt" value="lplot">LinePlot </span>},
	 	  qq{<span onmouseover="return overlib('Display experiment in JBrowse');" onmouseout="return nd();" style="white-space:nowrap"><input class="small" type="radio" name="dopt" value="jbrowse">JBrowse</span>},
		  qq{</td></tr>\n},
		  qq{<tr><td class="tdc"><img alt="" src="$gdb::util::webloc/web/$legendFile" border="0" onmouseover="return overlib('Color legend: Log2 expression ratio of test/control');" onmouseout="return nd();"></td></tr>\n},
		  qq{</table>\n};

	
		$parms->{accnid} = '';
		$parms->{expmtid} = '';
		my $expused = 0;
		for my $accid ( sort { $a <=> $b } keys %acchm ) {
			$parms->{accnid} .= "$accid~";
			for my $ouid ( sort { $a <=> $b } keys %{ $acchm{$accid} } ) {
				$expused++;
				$parms->{expmtid} .= "$acchm{$accid}{$ouid}{expid}~";
			}
		}
		
		gdb::webUtil::putSessVar( 'parms', $parms );
		gdb::webUtil::putSessVar( 'acchm', \%acchm );

		my $pad = ( $wrap =~ /1/ ) ? "1" : "0";
		print qq{<table align="center" cellpadding="$pad" cellspacing="$pad">\n};

		for my $i ( sort { $a <=> $b } keys %hminfo ) {
			print qq{<tr>};

			print qq{<td class="tdl" valign="middle" onmouseover="return overlib('$hmaps{$i}{info}');" onmouseout="return nd();"> $hmaps{$i}{gene}&nbsp;</td>};
			print qq{<td>};
			print qq{<table cellpadding="0"  cellspacing="0">};

			$rowCnt = 0;
			$head   = 0;
			for my $eID ( sort { $a <=> $b } keys %dbexpInfo ) {
				next if ( !$dbexpInfo{$eID}{flag} );    #if flag=0 then this experiment was not used by any genes
				
				if ( !$head ) {
					$head = 1;                       #true
					print qq{<tr height="18" style="cursor:default;">\n};
				}
				if ( $rowCnt >= $num_per_row ) {
					print qq{</tr><tr height="18" style="vertical-align:top;cursor:default;">\n};
					$rowCnt = 0;
				}

				if ( $hminfo{$i}{$eID} ) {
					print qq{<td class="tdc" width="8" style="background-color:$hminfo{$i}{$eID}{color};" onclick="$hminfo{$i}{$eID}{click}" onmouseover="return overlib('$hminfo{$i}{$eID}{title}',WIDTH,400);" onmouseout="return nd();">$hminfo{$i}{$eID}{hm}</td>};
				} else {
					print qq{<td class="tdc" width="8">.</td>};    #experiment used but not by this gene
				}
				$rowCnt++;
			}
			print qq{</tr>};

			print qq{</table>};
			print qq{</td>};

			print qq{</tr>\n};

			print qq{<tr>\n};
			print qq{<td></td>\n};
			print qq{<td>\n};

			##plot
			if ( $gdb::webUtil::frmData{replot} ) {
				( $gdb::webUtil::frmData{id}, $gdb::webUtil::frmData{selGene}, $gdb::webUtil::frmData{nsd} ) = split( /~/, $gdb::webUtil::frmData{replot} );
				$gdb::webUtil::frmData{hmcnt} = $i;
				$gdb::webUtil::frmData{qryall}  = $qryall;
				print qq{<div id="hmplot$i"><div id="pdiv$gdb::webUtil::frmData{id}">\n};
				gdb::plot::scatterPlot();
				print qq{</div></div>\n};
			} else {
				print qq{<div id="hmplot$i"> </div>\n};
			}

			print qq{</td>\n};
			print qq{</tr>\n};
			print qq{<tr><td></td><td><div class="hidden" id="pdata$i"></div></td></tr>\n};
		}
		print qq{</table>\n};

		print qq{<span class="small"><b>Exp:</b> $expused / $expCount</span>\n} if $expused;
	}
	
	print qq{<script type="text/javascript">statbar('hide');</script>\n};
	
	gdb::webUtil::putSessVar( 'qryltag',   \%ltags );
}

#----------------------------------------------------------------------
# Check query to see if location entered
# input: query string
# return: array
#----------------------------------------------------------------------
sub ckQryLoc {
	my ( $query, $genomeacc ) = @_;

	$query =~ s/\,+/ /g;    #replace commas with space
	$query =~ s/\s+/ /g;    #reduce spaces to single
	my @qryVal = split( /\s/, $query );

	my @newqry;

	#we walk thru each element because we might have a location(numeric)
	foreach my $qry (@qryVal) {
		if ( $qry =~ /^[+-]?\d+$/ ) {

			#numeric query
			my $result = gdb::oracle::dbQryGenomeLocation( $qry, $genomeacc );
			my @locVal = split( /,|\s/, $result );
			foreach my $loc (@locVal) {
				push( @newqry, $loc );    #add 1(or 2) genes to newVal
			}
		} else {
			push( @newqry, $qry );
		}
	}
	return @newqry;
}

#----------------------------------------------------------------------
# get blue Yellow color
# input: ratio value
# return: array of RGB color
#----------------------------------------------------------------------
sub blueYellowcolor {
	my ($v) = @_;
	my @color =
	  ( $v >= 0 ) ? ( ( $v < 3.0 ) ? ( 0, ( 255 * $v ) / 3.0, ( 255 * $v ) / 3.0 ) : ( 0, 255, 255 ) ) : ( ( $v > -3.0 ) ? ( ( -255 * $v ) / 3.0, ( -255 * $v ) / 3.0, 0 ) : ( 255, 255, 0 ) );
	return \@color;
}

#----------------------------------------------------------------------
# get red Green color
# input: ratio value
# return: array of RGB color
#----------------------------------------------------------------------
sub redGreencolor {
	my ($v) = @_;
	my @color = ( $v >= 0 ) ? ( ( $v < 3.0 ) ? ( ( 255 * $v ) / 3.0, 0, 0 ) : ( 255, 0, 0 ) ) : ( ( $v > -3.0 ) ? ( 0, ( -255 * $v ) / 3.0, 0 ) : ( 0, 255, 0 ) );
	return \@color;
}

#----------------------------------------------------------------------
# get multi color
# input: ratio value
# return: array of RGB color
#----------------------------------------------------------------------
sub multicolor {
	my ($v) = @_;
	my @color =
	    ( $v >= 0 )
	  ? ( ( $v <= 1.5 ) ? ( ( 255 * $v ) / 1.5, 0, 0 ) : ( ( $v <= 6.0 ) ? ( 255, ( 255 * ( $v - 1.5 ) ) / 4.5, 0 ) : ( 255, 255, 0 ) ) )
	  : ( ( $v > -1.5 ) ? ( 0, ( -255 * $v ) / 1.5, 0 ) : ( ( $v > -6 ) ? ( 0, 255 * ( 6 + $v ) / 4.5, 255 * ( -1.5 - $v ) / 4.5 ) : ( 0, 0, 255 ) ) );
	return \@color;
}

1;    # return a true value
