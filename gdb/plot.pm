#------------------------------------------------------------------------------------------
# FileName    : gdb/plot.pm
#
# Description : Plot utils
# Author      : jgrissom
# DateCreated : 9 Mar 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package gdb::plot;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use GD;
use List::Util qw(sum min max);
use POSIX;

#----------------------------------------------------------------------
# display scatter plot
# input: none
# return: none
#----------------------------------------------------------------------
sub scatterPlot {

	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $hmcnt   = ( exists $gdb::webUtil::frmData{hmcnt} )   ? $gdb::webUtil::frmData{hmcnt}  : 0;
	my $expid   = ( $gdb::webUtil::frmData{id} )      ? $gdb::webUtil::frmData{id}      : 0;
	my $gene    = ( $gdb::webUtil::frmData{gene} )    ? $gdb::webUtil::frmData{gene}    : '';
	my $selGene = ( $gdb::webUtil::frmData{selGene} ) ? $gdb::webUtil::frmData{selGene} : '';
	my $qryall  = ( $gdb::webUtil::frmData{qryall} )  ? $gdb::webUtil::frmData{qryall}  : '';
	my $nsd     = ( $gdb::webUtil::frmData{nsd} =~ /undefined/ ) ? 2 : $gdb::webUtil::frmData{nsd};
	
	my ( $dbExpmRecRef ) = gdb::oracle::dbgetExpmPlotInfo();    #get all experiment info
	my %dbExpmRec = %$dbExpmRecRef;

	my ( $accnid, $accession, $expname, $std, $platform );
	for my $i ( keys %dbExpmRec ) {
		if ( $dbExpmRec{$i}{id} == $expid ) {
			$accnid    = $dbExpmRec{$i}{expid};
			$accession = $dbExpmRec{$i}{accession};
			$expname   = $dbExpmRec{$i}{expname};
			$std       = $dbExpmRec{$i}{std};
			$platform  = $dbExpmRec{$i}{platform};
		}
	}
	my $stdDev2 = $nsd * $std;

	my ( $plotFile, $pmap, $upregRef, $dnregRef, $datacnt ) = createScatterPlot( $expid, $gene, $selGene, $std, $nsd, $platform );
	my %upreg = %$upregRef;
	my $upcnt = keys %$upregRef;
	my %dnreg = %$dnregRef;
	my $dncnt = keys %$dnregRef;
	
	my $pos = ( $parms->{wrap} == 1 ) ? 'center' : 'left';
	print
	  qq{<hr>\n},
	  qq{<table class="small" align="$pos">\n},
	  qq{<tr><td class="tdl"><a class="exmp" onclick="rmdiv('hmplot$hmcnt','pdiv$expid','$accnid');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td></tr>\n},
	  qq{<tr><td class="tdc">$accession</td></tr>\n},
	  qq{<tr><td class="tdc">$expname</td></tr>\n},
	  qq{<tr><td class="tdc">Data Count: $datacnt</td></tr>\n},
	  qq{<tr>\n},
	  qq{<td class="tdc"><img alt="" src="/tmpimage/$plotFile" border="1" usemap="#$expid$selGene"></td>\n},
	  qq{</tr>\n},

	  qq{<tr>\n},

	  qq{<td class="tdl">\n}, 
	  qq{<select class="small" onChange="replot('$expid',this.options[this.selectedIndex].value,document.mainFrm.nsd.value);" onmouseover="return overlib('Up regulated, sorted by ratio');" onmouseout="return nd();">\n}, 
	  qq{<option value="" selected>UpReg($upcnt)</option>\n};

	for my $ratio ( sort { lc($b) cmp lc($a) } keys %upreg ) {
		print qq{<option value="$upreg{$ratio}{ltag}">$upreg{$ratio}{gene}</option>\n};
	}
	
	print
	  qq{</select>\n},

	  qq{&nbsp;&nbsp;&nbsp; <select class="small" onChange="replot('$expid',this.options[this.selectedIndex].value,document.mainFrm.nsd.value);" onmouseover="return overlib('Down regulated, sorted by ratio');" onmouseout="return nd();">\n}, 
	  qq{<option value="" selected>DnReg($dncnt)</option>\n};

	for my $ratio ( sort { lc($a) cmp lc($b) } keys %dnreg ) {
		print qq{<option value="$dnreg{$ratio}{ltag}">$dnreg{$ratio}{gene}</option>\n};
	}

	print
	  qq{</select>\n},

	  qq{&nbsp;&nbsp;&nbsp; Green line = StdDev(sum of ratio) ($std) * }, qq{<input class="nsd" type="text" size="3" maxlength="3" name="nsd" value="$nsd"> = $stdDev2 },
	  qq{&nbsp;&nbsp;&nbsp; <input class="ebtn" type="button" name="chgstddev" value="Change StdDev" onclick="hmclk('$hmcnt','$expid','$gene','$selGene','$qryall','$accnid','',document.mainFrm.nsd.value);" onmouseover="return overlib('Enter new value and click to change StdDev green line');" onmouseout="return nd();">},
	  qq{&nbsp;&nbsp;&nbsp; <input class="ebtn" type="button" name="viewpdata" value="View Data" onclick="pdata('$hmcnt','$expid','$selGene');" onmouseover="return overlib('View plot data');" onmouseout="return nd();">},
	  qq{</td>\n},
	  qq{</tr>\n},
	  qq{</table>\n}, 
	  qq{<map name="$expid$selGene">$pmap</map>\n}, 
	  
	  qq{<br/>\n};
}

#----------------------------------------------------------------------
# display scatter plot data
# input: hash ref-expid and gene
# return: none
#----------------------------------------------------------------------
sub viewpdata {

	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $hmcnt   = ( exists $gdb::webUtil::frmData{hmcnt} )   ? $gdb::webUtil::frmData{hmcnt}  : 0;
	my $expid = ( $gdb::webUtil::frmData{expid} ) ? $gdb::webUtil::frmData{expid}      : 0;

	my $dbPlotDataRef = gdb::oracle::dbgetSPlotData($expid);    #get the plot data
	my %dbPlotData    = %$dbPlotDataRef;
	my $datacnt   = keys %dbPlotData;

	my $pos = ( $parms->{wrap} == 1 ) ? 'center' : 'left';
	print
	  qq{<hr>\n},
	  qq{<table align="$pos">\n},
	  qq{<tr><td class="tdl"><a class="exmp" onclick="sh('pdata$hmcnt');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td></tr>\n},
	
	  qq{<tr>\n},
	  qq{<td colspan="3"><input class="ebtn" type="submit" name="qrypdata" value="Query Selected"></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td colspan="3">PLOT DATA COUNT: <b>$datacnt</b></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<th class="thc" onmouseover="return overlib('Select/Unselect');" onmouseout="return nd();"><input id="ckallid" type="checkbox" name="ckallid" onclick="ckall(this,'ckannot');"></th>\n},
	  qq{<th class="thc">GENE</th>\n},
	  qq{<th class="thc">LOCUSTAG</th>\n},
	  qq{<th class="thc">RATIO</th>\n},
	  qq{</tr>\n};

	foreach my $id ( sort keys %dbPlotData ) {
		print
		  qq{<tr bgcolor="#ebf0f2">\n},
		  qq{<td class="tdc"><input class="small" type="checkbox" name="ckannot" value="$id"></td>\n},
		  qq{<td class="tdl">$dbPlotData{$id}{gene}</td>\n},
		  qq{<td class="tdc"><a onclick="replot('$expid','$id',document.mainFrm.nsd.value);" onmouseover="this.style.cursor='pointer';return overlib('Query $id');" onmouseout="return nd();">$id</a></td>\n},
		  qq{<td class="tdr">$dbPlotData{$id}{ratio}</td>\n},
		  qq{</tr>\n};
	}

	print
	  qq{<tr>\n},
	  qq{<td colspan="3">Recs: <b>$datacnt</b></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td colspan="3"><input class="ebtn" type="submit" name="qrypdata" value="Query Selected"></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td colspan="3"><a style="cursor:pointer;" onclick="window.scrollTo(0,0);">Back To Top</a></td>\n},
	  qq{</tr>\n},
	  qq{</table>\n},
	  qq{<br/>\n};
}

#----------------------------------------------------------------------
# display line plot
# input: id and selGene
# return: none
#----------------------------------------------------------------------
sub linePlot {

	my $parms = gdb::webUtil::getSessVar( 'parms' );

	my $hmcnt   = ( exists $gdb::webUtil::frmData{hmcnt} )   ? $gdb::webUtil::frmData{hmcnt}  : 0;
	my $expid   = ( $gdb::webUtil::frmData{id} )      ? $gdb::webUtil::frmData{id}      : 0;
	my $gene    = ( $gdb::webUtil::frmData{gene} )    ? $gdb::webUtil::frmData{gene}    : '';
	my $selGene = ( $gdb::webUtil::frmData{selGene} ) ? $gdb::webUtil::frmData{selGene} : '';
	my $qryall  = ( $gdb::webUtil::frmData{qryall} )  ? $gdb::webUtil::frmData{qryall}  : '';
	
	my ( $dbExpmRecRef ) = gdb::oracle::dbgetExpmPlotInfo();    #get all experiment info
	my %dbExpmRec = %$dbExpmRecRef;

	my ( $accessionID, $accession, $expname, $std );
	for my $i ( keys %dbExpmRec ) {
		if ( $dbExpmRec{$i}{id} == $expid ) {
			$accessionID = $dbExpmRec{$i}{expid};
			$accession = $dbExpmRec{$i}{accession};
			$std       = $dbExpmRec{$i}{std};
		}
	}

	my ( $plotFile, $pmap, $numExps ) = createLinePlot( $gdb::util::gnom{$parms->{genome}}{acc}, $accessionID, $selGene, $qryall, $std );

	my $pos = ( $parms->{wrap} == 1 ) ? 'center' : 'left';
	
	if ($plotFile) {
		print
		  qq{<hr>\n},
		  qq{<table class="small" align="$pos">\n},
		  qq{<tr><td class="tdl"><a class="exmp" onclick="sh('hmplot$hmcnt');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td></tr>\n},
		  qq{<tr><td class="tdc">$accession - $numExps Experiments</td></tr>\n},
		  qq{<tr>\n},
		  qq{<td class="tdc"><img alt="" src="/tmpimage/$plotFile" border="1" usemap="#$expid$selGene"></td>\n},
		  qq{</tr>\n},
		  qq{</table>\n}, 
		  qq{<map name="$expid$selGene">$pmap</map>\n};
	}else{
		print
		  qq{<hr>\n},
		  qq{<table class="small" align="$pos">\n},
		  qq{<tr><td class="tdl"><a class="exmp" onclick="sh('hmplot$hmcnt');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td></tr>\n},
		  qq{<tr><td class="tdc">$accession has only $numExps Experiment</td></tr>\n},
		  qq{</table>\n}, 
	}
	  
	  qq{<br/>\n};
}

#----------------------------------------------------------------------
# createExpPlot
# input: plot type, plotdata
# return: none
#----------------------------------------------------------------------
sub createExpPlot {
	my ( $plottype, $stddev, $genomeacc, $plotTestdataRef, $plotCntldataRef ) = @_;
	my %plotTestdata = %$plotTestdataRef;
	my %plotCntldata = %$plotCntldataRef;
	
	my $geneLocRef = gdb::oracle::dbgetGeneLoc($genomeacc);	#genome gene and start
	my %geneLoc    = %$geneLocRef;
	
	my $NSgeneLocRef = gdb::oracle::dbgetNSgeneLoc($genomeacc);
	my %NSgeneLoc    = %$NSgeneLocRef;

	my %plotData = ();
	my @Xdata = ();
	my @Ydata = ();
	for my $id_ref ( keys %plotCntldata ) {
		
		my $testVal = ( $plotTestdata{$id_ref} ne '' ) ? $plotTestdata{$id_ref} : '';
		my $cntlVal = ( $plotCntldata{$id_ref} ne '' ) ? $plotCntldata{$id_ref} : '';

		if ($plottype =~ /maplot|xyplot/ and ($testVal eq '' or $cntlVal eq '')) {
			next;	#skip both X and Y if X OR Y empty
		}

		my $gene = '';
		my $gLoc = '';

		if ( exists $geneLoc{$id_ref} ) {
			$gene = $geneLoc{$id_ref}{gene};
			$gLoc = $geneLoc{$id_ref}{start};
		} else {
			if (exists $NSgeneLoc{$id_ref}) {
				$gene = $geneLoc{$NSgeneLoc{$id_ref}}{gene};
				$gLoc = $geneLoc{$NSgeneLoc{$id_ref}}{start};
			}else{
				$gene = $id_ref;
				$gLoc = $id_ref;
				$gLoc =~ s/[A-Za-z]|\(//g;
				$gLoc = substr($gLoc, 0, 4);	#we may have multiple genes separated by ':'
			}
		}
		
		$plotData{$id_ref}{gLoc}  = $gLoc;
		$plotData{$id_ref}{ltag}  = $id_ref;
		$plotData{$id_ref}{gene}  = $gene;
		$plotData{$id_ref}{test}  = $testVal if ( $testVal );
		$plotData{$id_ref}{ratio} = $cntlVal if ( $cntlVal );
		
		my $xdval = ($plottype =~ /mbplot/) ? $gLoc : $testVal;
		
		push @Xdata, $xdval;
		push @Ydata, $cntlVal if (  $cntlVal ne '' );
	}

	#--find min/max X value(bNum or A)
	my $minX = $Xdata[0];
	$minX = $_ < $minX ? $_ : $minX foreach (@Xdata);
	my $maxX = $Xdata[0];
	$maxX = $_ > $maxX ? $_ : $maxX foreach (@Xdata);

	#--find min/max Y value(ratio)
	my $minY = $Ydata[0];
	$minY = $_ < $minY ? $_ : $minY foreach (@Ydata);
	my $maxY = $Ydata[0];
	$maxY = $_ > $maxY ? $_ : $maxY foreach (@Ydata);

	my $x_size = 750;
	my $y_size = 400;

	my $im = new GD::Image( $x_size, $y_size );

	my $white      = $im->colorAllocate( 255, 255, 255 );
	my $black      = $im->colorAllocate( 0,   0,   0 );
	my $red        = $im->colorAllocate( 255, 0,   0 );
	my $blue       = $im->colorAllocate( 0,   0,   255 );
	my $green      = $im->colorAllocate( 0,   255, 0 );
	my $grid_color = $im->colorAllocate( 230, 230, 230 );

	my $left_margin   = 40;
	my $right_margin  = 30;
	my $top_margin    = 20;
	my $bottom_margin = 35;

	my $grace = ( $maxY - $minY ) * 0.01;
	$minY -= $grace;
	$maxY += $grace;

	if ( $maxY == $minY ) {
		$maxY *= 1.01;
		$minY *= 0.99;
	}
	if ( $maxX == $minX ) {
		$maxX++;
	}
	if ( $maxY == $minY ) {
		$maxY++;
	}

	my $xoff   = $left_margin;
	my $yoff   = $top_margin;
	my $width  = $x_size - $left_margin - $right_margin;
	my $height = $y_size - $top_margin - $bottom_margin;

	##--Y-axis
	my @ticks = get_ticks( $minY, $maxY );
	my $step = ceil( scalar(@ticks) / ( ( $y_size - $top_margin - $bottom_margin ) / 25 ) );

	for ( my $i = 0 ; $i < scalar(@ticks) ; $i += 1 ) {
		my $y = $ticks[$i];
		my $yt = $yoff + $height - ( ( $y * 1.0 - $minY ) / ( $maxY - $minY ) * $height );

		my $yst;
		if ( !( $i % $step ) ) {
			if ( $y == 0 ) {
				$yst = 0;
			} elsif ( abs($y) < 1 ) {
				$yst = sprintf( "%.2f", $y );
			} elsif ( !( $y % 1000000 ) ) {
				$yst = sprintf( "%sM", $y / 1000000 );
			} elsif ( !( $y % 1000 ) ) {
				$yst = sprintf( "%sk", $y / 1000 );
			} else {
				$yst = $y;
			}
			$im->string( gdSmallFont, $left_margin - 3 - length($yst) * 6, $yt - 7, $yst, $black );
			$im->line( $left_margin - 3, $yt, $left_margin, $yt, $black );
		} else {
			$im->line( $left_margin - 1, $yt, $left_margin, $yt, $black );
		}

		$im->line( $left_margin + 1, $yt, $x_size - $right_margin, $yt, $grid_color );
	}

	##--X-axis
	@ticks = get_ticks( $minX, $maxX );
	$step = ceil( scalar(@ticks) / ( ( $x_size - $left_margin - $right_margin ) / 70 ) );

	for ( my $i = 0 ; $i < scalar(@ticks) ; $i += 1 ) {
		my $x = floor( $ticks[$i] );
		my $xt = $xoff + ( $x - $minX ) / ( $maxX - $minX ) * $width;

		if ( ( $i % $step ) == 0 ) {
			$im->string( gdSmallFont, $xt - ( length($x) * 6 / 2 ), $y_size - $bottom_margin + 5, $x, $black );
			$im->line( $xt, $y_size - $bottom_margin, $xt, $y_size - $bottom_margin + 3, $black );
		} else {
			$im->line( $xt, $y_size - $bottom_margin, $xt, $y_size - $bottom_margin + 1, $black );
		}
		$im->line( $xt, $top_margin, $xt, $y_size - $bottom_margin - 1, $grid_color );
	}

	my ($xlabel,$ylabel);
	##--Frame
	$im->line( $left_margin, $top_margin, $left_margin, $y_size - $bottom_margin + 3, $black );
	$im->line( $left_margin - 3, $y_size - $bottom_margin, $x_size - $right_margin, $y_size - $bottom_margin, $black );
	##--X-label
	$xlabel = 'Genome Location' if $plottype =~ /mbplot/;
	$xlabel = 'A' if $plottype =~ /maplot/;
	$xlabel = 'X-Test' if $plottype =~ /xyplot/;
	$im->string( gdSmallFont, $x_size / 2 - ( length($xlabel) * 6 ) / 2, $y_size - 20, $xlabel, $black );
	##--Y-label
	$ylabel = 'Ratio' if $plottype =~ /mbplot/;
	$ylabel = 'M' if $plottype =~ /maplot/;
	$ylabel = 'Y-Control' if $plottype =~ /xyplot/;
	$im->stringUp( gdSmallFont, 5, $y_size / 2 + ( length($ylabel) * 6 ) / 2, $ylabel, $black );

	##--Plot Data
	my $pmap = '';
	foreach my $ltag ( keys %plotData ) {
		next if ( !exists $plotData{$ltag}{ratio} );
			
		my $xval = ($plottype =~ /mbplot/) ? $plotData{$ltag}{gLoc} : $plotData{$ltag}{test};
		
		my $xt = $xoff + ( $xval - $minX ) / ( $maxX - $minX ) * $width;
		my $yt = $yoff + $height - ( ( ( $plotData{$ltag}{ratio} ) * 1.0 - $minY ) / ( $maxY - $minY ) * $height );

		my $gene = ( $plotData{$ltag}{gene} ) ? $plotData{$ltag}{gene} : $plotData{$ltag}{ltag};
		my $dmsg = qq{Gene: <b>$gene</b> ($plotData{$ltag}{ltag})<br>Value: <b>$plotData{$ltag}{ratio}</b>};
		$im->arc( $xt, $yt, 2, 2, 0, 360, $blue );
		$pmap .= qq{<area shape=circle coords="$xt,$yt,2" onMouseover="return overlib('$dmsg');" onMouseout="return nd();">};
	}

	##--STD lines
	if ($stddev and  $plottype !~ /xyplot/) {

		#(+) line
		my $ystd = $yoff + $height - ( ( $stddev * 1.0 - $minY ) / ( $maxY - $minY ) * $height );
		$im->line( $left_margin + 1, $ystd, $x_size - $right_margin, $ystd, $green );

		#(-) line
		$ystd = $yoff + $height - ( ( $stddev * -1.0 - $minY ) / ( $maxY - $minY ) * $height );
		$im->line( $left_margin + 1, $ystd, $x_size - $right_margin, $ystd, $green ) if ($ystd < ($y_size - $bottom_margin));
	}

	my $plotFile = tmpFile();
	while ( -e $plotFile ) {
		$plotFile = tmpFile();
	}

	open( PNGOUT, ">/run/shm/$plotFile" );
	binmode PNGOUT;
	print PNGOUT $im->png;
	close PNGOUT;
	return ( $plotFile, $pmap );	
}

#----------------------------------------------------------------------
# create scatter plot
# input: id and selGene
# return: ref to png, map
#----------------------------------------------------------------------
sub createScatterPlot {
	my ( $id, $gene, $selGene, $std, $nsd, $genomeacc ) = @_;

	my $pmap = '';

	my $geneLocRef = gdb::oracle::dbgetGeneLoc($genomeacc);	#genome gene and start
	my %geneLoc    = %$geneLocRef;
	
	my $NSgeneLocRef = gdb::oracle::dbgetNSgeneLoc($genomeacc);
	my %NSgeneLoc    = %$NSgeneLocRef;

	my $dbPlotDataRef = gdb::oracle::dbgetSPlotData($id);    #get the plot data
	my %dbPlotData    = %$dbPlotDataRef;

	my $stdDev2 = $nsd * $std;

	my ( %plotData, $gLoc, @Xdata, @Ydata, %upreg, %dnreg );
	foreach my $id ( keys %dbPlotData ) {
		
		my $gLoc = '';
		if ( exists $geneLoc{$id} ) {
			$gLoc = $geneLoc{$id}{start};
		} else {
			if (exists $NSgeneLoc{$id}) {
				$gLoc = $geneLoc{$NSgeneLoc{$id}}{start};
			}else{
				$gLoc = $id;
				$gLoc =~ s/[A-Z]+//gi;
			}
		}
		
		$plotData{$gLoc}{ltag}  = $id;
		$plotData{$gLoc}{gene}  = $dbPlotData{$id}{gene};
		$plotData{$gLoc}{ratio} = $dbPlotData{$id}{ratio} if ( $dbPlotData{$id}{ratio} );

		push @Xdata, $gLoc if ($gLoc);
		push @Ydata, $dbPlotData{$id}{ratio} if ( exists $dbPlotData{$id}{ratio} );

		if ( $dbPlotData{$id}{ratio} and ( $dbPlotData{$id}{ratio} > $stdDev2 ) ) {
			$upreg{ $dbPlotData{$id}{ratio} . $id }{ltag} = $id;
			$upreg{ $dbPlotData{$id}{ratio} . $id }{gene} = $dbPlotData{$id}{gene};
		}
		if ( $dbPlotData{$id}{ratio} and ( $dbPlotData{$id}{ratio} < ( $stdDev2 * -1.0 ) ) ) {
			$dnreg{ $dbPlotData{$id}{ratio} . $id }{ltag} = $id;
			$dnreg{ $dbPlotData{$id}{ratio} . $id }{gene} = $dbPlotData{$id}{gene};
		}
	}

	my $datacnt = @Ydata;

	#--find min/max X value(bNum)
	my $minX = $Xdata[0];
	$minX = $_ < $minX ? $_ : $minX foreach (@Xdata);
	my $maxX = $Xdata[0];
	$maxX = $_ > $maxX ? $_ : $maxX foreach (@Xdata);

	#--find min/max Y value(ratio)
	my $minY = $Ydata[0];
	$minY = $_ < $minY ? $_ : $minY foreach (@Ydata);
	my $maxY = $Ydata[0];
	$maxY = $_ > $maxY ? $_ : $maxY foreach (@Ydata);

	my $x_size = 750;
	my $y_size = 400;

	my $im = new GD::Image( $x_size, $y_size );

	my $white      = $im->colorAllocate( 255, 255, 255 );
	my $black      = $im->colorAllocate( 0,   0,   0 );
	my $red        = $im->colorAllocate( 255, 0,   0 );
	my $blue       = $im->colorAllocate( 0,   0,   255 );
	my $green      = $im->colorAllocate( 0,   255, 0 );
	my $grid_color = $im->colorAllocate( 230, 230, 230 );

	my $left_margin   = 40;
	my $right_margin  = 30;
	my $top_margin    = 20;
	my $bottom_margin = 35;

	my $grace = ( $maxY - $minY ) * 0.01;
	$minY -= $grace;
	$maxY += $grace;

	if ( $maxY == $minY ) {
		$maxY *= 1.01;
		$minY *= 0.99;
	}
	if ( $maxX == $minX ) {
		$maxX++;
	}
	if ( $maxY == $minY ) {
		$maxY++;
	}

	my $xoff   = $left_margin;
	my $yoff   = $top_margin;
	my $width  = $x_size - $left_margin - $right_margin;
	my $height = $y_size - $top_margin - $bottom_margin;

	##--Y-axis
	my @ticks = get_ticks( $minY, $maxY );
	my $step = ceil( scalar(@ticks) / ( ( $y_size - $top_margin - $bottom_margin ) / 25 ) );

	for ( my $i = 0 ; $i < scalar(@ticks) ; $i += 1 ) {
		my $y = $ticks[$i];
		my $yt = $yoff + $height - ( ( $y * 1.0 - $minY ) / ( $maxY - $minY ) * $height );

		my $yst;
		if ( !( $i % $step ) ) {
			if ( $y == 0 ) {
				$yst = 0;
			} elsif ( abs($y) < 1 ) {
				$yst = sprintf( "%.2f", $y );
			} elsif ( !( $y % 1000000 ) ) {
				$yst = sprintf( "%sM", $y / 1000000 );
			} elsif ( !( $y % 1000 ) ) {
				$yst = sprintf( "%sk", $y / 1000 );
			} else {
				$yst = $y;
			}
			$im->string( gdSmallFont, $left_margin - 3 - length($yst) * 6, $yt - 7, $yst, $black );
			$im->line( $left_margin - 3, $yt, $left_margin, $yt, $black );
		} else {
			$im->line( $left_margin - 1, $yt, $left_margin, $yt, $black );
		}

		$im->line( $left_margin + 1, $yt, $x_size - $right_margin, $yt, $grid_color );
	}

	##--X-axis
	@ticks = get_ticks( $minX, $maxX );
	$step = ceil( scalar(@ticks) / ( ( $x_size - $left_margin - $right_margin ) / 70 ) );

	for ( my $i = 0 ; $i < scalar(@ticks) ; $i += 1 ) {
		my $x = floor( $ticks[$i] );
		my $xt = $xoff + ( $x - $minX ) / ( $maxX - $minX ) * $width;

		if ( ( $i % $step ) == 0 ) {
			$im->string( gdSmallFont, $xt - ( length($x) * 6 / 2 ), $y_size - $bottom_margin + 5, $x, $black );
			$im->line( $xt, $y_size - $bottom_margin, $xt, $y_size - $bottom_margin + 3, $black );
		} else {
			$im->line( $xt, $y_size - $bottom_margin, $xt, $y_size - $bottom_margin + 1, $black );
		}
		$im->line( $xt, $top_margin, $xt, $y_size - $bottom_margin - 1, $grid_color );
	}

	##--Frame
	$im->line( $left_margin, $top_margin, $left_margin, $y_size - $bottom_margin + 3, $black );
	$im->line( $left_margin - 3, $y_size - $bottom_margin, $x_size - $right_margin, $y_size - $bottom_margin, $black );
	##--X-label
	my $xlabel = 'Genome Location';
	$im->string( gdSmallFont, $x_size / 2 - ( length($xlabel) * 6 ) / 2, $y_size - 20, $xlabel, $black );
	##--Y-label
	my $ylabel = 'Ratio';
	$im->stringUp( gdSmallFont, 5, $y_size / 2 + ( length($ylabel) * 6 ) / 2, $ylabel, $black );

	##--Plot Data
	foreach my $tmp2 ( sort { $a <=> $b } keys %plotData ) {
		next if ( !exists $plotData{$tmp2}{ratio} );

		my $xt = $xoff + ( $tmp2 - $minX ) / ( $maxX - $minX ) * $width;
		my $yt = $yoff + $height - ( ( ( $plotData{$tmp2}{ratio} ) * 1.0 - $minY ) / ( $maxY - $minY ) * $height );

		my $gene = ( $plotData{$tmp2}{gene} ) ? $plotData{$tmp2}{gene} : $plotData{$tmp2}{ltag};
		my $dmsg = qq{Gene: <b>$gene</b> ($plotData{$tmp2}{ltag})<br>Value: <b>$plotData{$tmp2}{ratio}</b>};
		if ( $selGene eq $plotData{$tmp2}{ltag} ) {
			$im->filledEllipse( $xt, $yt, 10, 10, $red );
			$pmap .= qq{<area shape=circle coords="$xt,$yt,8" onMouseover="return overlib('$dmsg');" onMouseout="return nd();">};
		} else {
			$im->arc( $xt, $yt, 2, 2, 0, 360, $blue );
			$pmap .= qq{<area shape=circle coords="$xt,$yt,2" onMouseover="return overlib('$dmsg');" onMouseout="return nd();" onclick="replot('$id','$plotData{$tmp2}{ltag}',document.mainFrm.nsd.value);">};
		}
	}

	##--STD lines
	if ($std) {

		#(+) line
		my $ystd = $yoff + $height - ( ( $stdDev2 * 1.0 - $minY ) / ( $maxY - $minY ) * $height );
		$im->line( $left_margin + 1, $ystd, $x_size - $right_margin, $ystd, $green );

		#(-) line
		$ystd = $yoff + $height - ( ( $stdDev2 * -1.0 - $minY ) / ( $maxY - $minY ) * $height );
		$im->line( $left_margin + 1, $ystd, $x_size - $right_margin, $ystd, $green );
	}

	my $plotFile = tmpFile();
	while ( -e $plotFile ) {
		$plotFile = tmpFile();
	}

	open( PNGOUT, ">/run/shm/$plotFile" );
	binmode PNGOUT;
	print PNGOUT $im->png;
	close PNGOUT;

	return ( $plotFile, $pmap, \%upreg, \%dnreg, $datacnt );
}

#----------------------------------------------------------------------
# create line plot
# input: id and selGene
# return: ref to png, map
#----------------------------------------------------------------------
sub createLinePlot {

	my $parms = gdb::webUtil::getSessVar( 'parms' );

	#experiment selected, plot gene for all experiment in that accession
	my ( $genomeacc, $id, $selGene, $qryall, $std ) = @_;
	
	my $pmap = '';

	my @newVal = gdb::heatmap::ckQryLoc($qryall, $genomeacc);
	
	my (%geneNames, %qryLtag);
	foreach my $qry (@newVal) {
		my ($geneRef, $ltagRef);	
		if ($genomeacc =~ /MG1655/) {
			( $geneRef, $ltagRef ) = gdb::oracle::dbQueryNamespace($qry);
		}else{
			( $geneRef, $ltagRef ) = gdb::oracle::dbQryGenomeLtags( $qry, $genomeacc );
		}
		my @ltags = @$ltagRef;
		
		$geneNames{@$geneRef[0]} = 1;
		
		for my $lt (@ltags) {
			$qryLtag{$lt} = @$geneRef[0];
		}
	}
	my @geneNames = sort keys %geneNames;
	
	my $dbPlotDataRef = gdb::oracle::dbgetLPlotAllData($id);      #get all line plot data
	my %dbPlotData    = %$dbPlotDataRef;

	my ( $dbaccExpmRec, $expm_orderRef ) = gdb::oracle::dbgetAccExpm();    #get all accession experiments
	my %dbaccExpm  = %$dbaccExpmRec;
	my @expm_order = @$expm_orderRef;

	my ( @Xdata, @Ydata );
	for my $id (@expm_order) {
		next if ($dbaccExpm{$id}{cntlgenome} !~ /$gdb::util::gnom{$parms->{genome}}{acc}/i);
		next if ( !exists $dbPlotData{$id} );
		my $ouid = $dbaccExpm{$id}{ouid};

		push @Xdata, $ouid if ($ouid);

		for my $ltag ( keys %{ $dbPlotData{$id} } ) {
			push @Ydata, $dbPlotData{$id}{$ltag}{ratio} if ( $dbPlotData{$id}{$ltag}{ratio} );
		}
	}
	
	my $numExps = @Xdata;
	if ($numExps < 2) {
		return ( '', '', $numExps );
	}

	#--find min/max X value(bNum)
	my $minX = $Xdata[0];
	$minX = $_ < $minX ? $_ : $minX foreach (@Xdata);
	my $maxX = $Xdata[0];
	$maxX = $_ > $maxX ? $_ : $maxX foreach (@Xdata);

	#--find min/max Y value(ratio)
	my $minY = $Ydata[0];
	$minY = $_ < $minY ? $_ : $minY foreach (@Ydata);
	my $maxY = $Ydata[0];
	$maxY = $_ > $maxY ? $_ : $maxY foreach (@Ydata);

	my $x_size = 750;
	my $y_size = 400;

	my $im = new GD::Image( $x_size, $y_size );

	my $white      = $im->colorAllocate( 255, 255, 255 );
	my $black      = $im->colorAllocate( 0,   0,   0 );
	my $gray       = $im->colorAllocate( 190, 190, 190 );
	my $grid_color = $im->colorAllocate( 230, 230, 230 );

	#red,blue,green,orange,skyBlue,violet,chocolate,darkBlue,darkMagenta,fuchsia,aquamarine,mediumPurple,purple,brown,cornflowerBlue
	my @labelColors = (
		[ 255, 0,   0 ],
		[ 0,   0,   255 ],
		[ 0,   255, 0 ],
		[ 255, 165, 0 ],
		[ 0,   191, 255 ],
		[ 238, 130, 238 ],
		[ 210, 105, 30 ],
		[ 0,   0,   139 ],
		[ 139, 0,   139 ],
		[ 255, 0,   255 ],
		[ 102, 205, 170 ],
		[ 147, 112, 219 ],
		[ 128, 0,   128 ],
		[ 160, 82,  45 ],
		[ 100, 149, 237 ]
	);

	my $left_margin   = 40;
	my $right_margin  = 30;
	my $top_margin    = 20;
	my $bottom_margin = 35;

	my $grace = ( $maxY - $minY ) * 0.01;
	$minY -= $grace;
	$maxY += $grace;

	if ( $maxY == $minY ) {
		$maxY *= 1.01;
		$minY *= 0.99;
	}
	if ( $maxX == $minX ) {
		$maxX++;
	}
	if ( $maxY == $minY ) {
		$maxY++;
	}

	my $xoff   = $left_margin;
	my $yoff   = $top_margin;
	my $width  = $x_size - $left_margin - $right_margin;
	my $height = $y_size - $top_margin - $bottom_margin;

	##--Y-axis
	my @ticks = get_ticks( $minY, $maxY );
	my $step = ceil( scalar(@ticks) / ( ( $y_size - $top_margin - $bottom_margin ) / 25 ) );

	for ( my $i = 0 ; $i < scalar(@ticks) ; $i += 1 ) {
		my $y = $ticks[$i];
		my $yt = $yoff + $height - ( ( $y * 1.0 - $minY ) / ( $maxY - $minY ) * $height );

		my $yst;
		if ( !( $i % $step ) ) {
			if ( $y == 0 ) {
				$yst = 0;
			}
			elsif ( abs($y) < 1 ) {
				$yst = sprintf( "%.2f", $y );
			}
			elsif ( !( $y % 1000000 ) ) {
				$yst = sprintf( "%sM", $y / 1000000 );
			}
			elsif ( !( $y % 1000 ) ) {
				$yst = sprintf( "%sk", $y / 1000 );
			}
			else {
				$yst = $y;
			}
			$im->string( gdSmallFont, $left_margin - 3 - length($yst) * 6, $yt - 7, $yst, $black );
			$im->line( $left_margin - 3, $yt, $left_margin, $yt, $black );
		}
		else {
			$im->line( $left_margin - 1, $yt, $left_margin, $yt, $black );
		}

		$im->line( $left_margin + 1, $yt, $x_size - $right_margin, $yt, $grid_color );
	}

	##--X-axis
	@ticks = get_ticks( $minX, $maxX );
	$step = ceil( scalar(@ticks) / ( ( $x_size - $left_margin - $right_margin ) / 70 ) );

	for ( my $i = 0 ; $i < scalar(@ticks) ; $i += 1 ) {
		my $x = floor( $ticks[$i] );
		my $xt = $xoff + ( $x - $minX ) / ( $maxX - $minX ) * $width;

		if ( ( $i % $step ) == 0 ) {
			$im->string( gdSmallFont, $xt - ( length($x) * 6 / 2 ), $y_size - $bottom_margin + 5, $x, $black );
			$im->line( $xt, $y_size - $bottom_margin, $xt, $y_size - $bottom_margin + 3, $black );
		}
		else {
			$im->line( $xt, $y_size - $bottom_margin, $xt, $y_size - $bottom_margin + 1, $black );
		}
		$im->line( $xt, $top_margin, $xt, $y_size - $bottom_margin - 1, $grid_color );
	}

	##--Frame
	$im->line( $left_margin, $top_margin, $left_margin, $y_size - $bottom_margin + 3, $black );
	$im->line( $left_margin - 3, $y_size - $bottom_margin, $x_size - $right_margin, $y_size - $bottom_margin, $black );
	##--X-label
	my $xlabel = 'Experiment OUID';
	$im->string( gdSmallFont, $x_size / 2 - ( length($xlabel) * 6 ) / 2, $y_size - 20, $xlabel, $black );
	##--Y-label
	my $ylabel = 'Ratio';
	$im->stringUp( gdSmallFont, 5, $y_size / 2 + ( length($ylabel) * 6 ) / 2, $ylabel, $black );

	##--Plot Data
	my ( $xt, $yt, $sav_xt, %sav_yt, %geneLabel, $i );
	$i = 0;
	foreach (@geneNames) {
		#set color index
		$geneLabel{$_} = $im->colorAllocate( $labelColors[$i][0], $labelColors[$i][1], $labelColors[$i][2] );
		$i++;
		$i %= 15;
	}

	for my $id (@expm_order) {
		next if ( !$dbPlotData{$id} );
		my $ouid = $dbaccExpm{$id}{ouid};

		$xt = $xoff + ( $ouid - $minX ) / ( $maxX - $minX ) * $width;

		my %selGeneLine;

		for my $ltag ( keys %{ $dbPlotData{$id} } ) {
			next if ( !exists $dbPlotData{$id}{$ltag}{ratio} || $dbPlotData{$id}{$ltag}{ratio} eq '' );

			my $gene = ( $dbPlotData{$id}{$ltag}{gene} ) ? $dbPlotData{$id}{$ltag}{gene} : $ltag;
			my $dmsg = qq{OUID: <b>$ouid</b><br>Gene: <b>$gene</b> ($ltag)<br>Value: <b>$dbPlotData{$id}{$ltag}{ratio}</b>};

			$yt = $yoff + $height - ( ( ( $dbPlotData{$id}{$ltag}{ratio} ) * 1.0 - $minY ) / ( $maxY - $minY ) * $height );

			if ( abs( $dbPlotData{$id}{$ltag}{ratio} ) >= ( 2 * $dbaccExpm{$id}{std} ) ) {
				$pmap .= qq{<area shape=circle coords="$xt,$yt,2" onMouseover="return overlib('$dmsg');" onMouseout="return nd();">};
			}

			if ( $sav_yt{$ltag} ) {
				if ( $qryLtag{$ltag} ) {

					#save the selected gene(s) coord so we can draw it last
					$selGeneLine{$ltag}{color} = $geneLabel{ $qryLtag{$ltag} } if ( !defined $selGeneLine{$ltag}{color} );
					$selGeneLine{$ltag}{x1}    = $sav_xt;
					$selGeneLine{$ltag}{y1}    = $sav_yt{$ltag};
					$selGeneLine{$ltag}{x2}    = $xt;
					$selGeneLine{$ltag}{y2}    = $yt;
					$pmap .= qq{<area shape=circle coords="$xt,$yt,2" onMouseover="return overlib('$dmsg');" onMouseout="return nd();">};
				}
				else {
					$im->line( $sav_xt, $sav_yt{$ltag}, $xt, $yt, $gray );
				}
			}
			$sav_yt{$ltag} = $yt;
		}
		$sav_xt = $xt;

		#draw selected gene line(s)
		for my $ltag ( keys %selGeneLine ) {
			$im->line( $selGeneLine{$ltag}{x1}, $selGeneLine{$ltag}{y1}, $selGeneLine{$ltag}{x2}, $selGeneLine{$ltag}{y2}, $selGeneLine{$ltag}{color} );
		}
	}

	my $xm = 0;
	my $ym = 20;
	for my $gene (@geneNames) {
		#draw color gene label(s)
		$im->string( gdSmallFont, $left_margin + $xm, $top_margin - $ym, $gene, $geneLabel{$gene} );
		$xm += 30;
		if ( $xm > 660 ) {
			#next line after 23 genes
			$xm = 0;
			$ym = 10;
		}
	}

	##-zero line
	my $ystd = $yoff + $height - ( ( 0 - $minY ) / ( $maxY - $minY ) * $height );
	$im->line( $left_margin + 1, $ystd, $x_size - $right_margin, $ystd, $black );

	my $plotFile = tmpFile();
	while ( -e $plotFile ) {
		$plotFile = tmpFile();
	}

	open( PNGOUT, ">/run/shm/$plotFile" );
	binmode PNGOUT;
	print PNGOUT $im->png;
	close PNGOUT;

	return ( $plotFile, $pmap, $numExps );
}

#----------------------------------------------------------------------
# compute tick marks
# input: min/max value
# return: array
#----------------------------------------------------------------------
sub get_ticks {
	my ( $min, $max ) = @_;

	my ( $diff, $even, $start, $elem, $i );
	my @ticks = ();

	$diff = abs( $max - $min );

	if ( $diff > 5000 ) {
		$even = pow( 10, floor( log10( $diff / 2 ) ) );
	} elsif ( $diff > 500 ) {
		$even = 100;
	} elsif ( $diff > 50 ) {
		$even = 10;
	} elsif ( $diff > 25 ) {
		$even = 2;
	} elsif ( $diff > 5 ) {
		$even = 1;
	} else {
		$even = .1;
	}

	if ( $min < 0 ) {
		my $f1 = -( floor( $min * 100 ) );
		my $f2 = -( $f1 % ( $even * 100 ) );
		$start = floor( $min * 100 ) + $even * 100 - ($f2) - $even * 100;
	} else {
		$start = floor( $min * 100 + $even * 100 - ( floor( $min * 100 ) % ( $even * 100 ) ) );
	}

	for ( $elem = $start, $i = 0 ; $elem < $max * 100 ; $elem += int( floor( $even * 100 ) ), $i++ ) {
		$ticks[$i] = $elem / 100;
		if ( $i > 1000 ) {
			return @ticks;
		}
	}
	return @ticks;
}

#----------------------------------------------------------------------
# stat_stdev - calculates sample standard deviation
# input: data array
# return: float
#----------------------------------------------------------------------
sub stat_stdev {
	my ( $dataRef ) = @_;	
	my @data = @$dataRef;
	
	return 0 if ! @data;
	
	my $n = @data;
	my $mean = sum(@data)/$n;
	my $sum = 0;
	foreach my $val (@data) {
		$sum += pow(($val - $mean), 2);
	}	
	return sqrt($sum / ($n - 1));
}

#----------------------------------------------------------------------
# stat_correlation - calculates correlation coefficient
# input: data arrays
# return: float
#----------------------------------------------------------------------
sub stat_correlation {
	my ( $data1Ref, $data2Ref ) = @_;	
	my @data1 = @$data1Ref;
	my @data2 = @$data2Ref;
	
	my $cnt1 = @data1;	#count
	my $cnt2 = @data2;
	my $n = min ($cnt1, $cnt2);
	
	my $mean_x = sum(@data1)/$cnt1;
	my $mean_y = sum(@data2)/$cnt2;
	
	my $SS_x = 0;
	foreach my $val_x (@data1) {
		$SS_x += pow (($val_x - $mean_x), 2);
	}	
	
	my $SS_y = 0;
	foreach my $val_y (@data2) {
		$SS_y += pow (($val_y - $mean_y), 2);
	}	

	my $SS_xy = 0;
	for (my $i = 0; $i < $n; $i++) {
		$SS_xy += ($data1[$i] - $mean_x) * ($data2[$i] - $mean_y);
	}

	my $results = $SS_xy / sqrt ($SS_x * $SS_y);
	return $results;
}

#----------------------------------------------------------------------
# create tmpfile
# input: none
# return: string
#----------------------------------------------------------------------
sub tmpFile {
	my $rn      = int( rand(10000) );
	my $tmpFile = 'plot' . $rn . '.png';
	return $tmpFile;
}

1;    # return a true value
