#------------------------------------------------------------------------------------------
# FileName    : gdb/browser.pm
#
# Description : Browser
# Author      : jgrissom
# DateCreated : 1 Sep 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package testgdb::browser;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

#----------------------------------------------------------------------
# Display Browser
# input: none
# return: none
#----------------------------------------------------------------------
sub displayBrowser {

	my $qryltagRef = testgdb::webUtil::getSessVar( 'qryltag' );
	return if !$qryltagRef->{0};

	my $parms = testgdb::webUtil::getSessVar( 'parms' );

	return if !$parms->{currquery};

	if ( $testgdb::webUtil::frmData{ginfo} and $testgdb::webUtil::frmData{ginfo} =~ /^browser/ ) {

		#ajax call
		$parms->{browser} = ( $parms->{browser} ) ? 0 : 1;
		testgdb::webUtil::putSessVar( 'parms', $parms );
		browser() if ( $parms->{browser} );
	} else {
		if ( $parms->{browser} ) {
			print qq{<div class="mn2" style="border-top:1px solid #C3CCD3;"><span onclick="da('browser');" onmouseover="mm(this,'browser');" onmouseout="return nd();"><img id="browsersign" src="$testgdb::util::webloc/web/minus.gif" alt=""> Browser</span> &nbsp;&nbsp;&nbsp;<span class="sm10">( powered by <a href="http://gmod.org/wiki/JBrowse" target="_blank"">JBrowse</a> )</span></div>};
			print qq{<div class="showrec" id="browser">};
			browser();
			print qq{</div>\n};
		} else {
			print qq{<div class="mn2" style="border-top:1px solid #C3CCD3;"><span onclick="da('browser');" onmouseover="mm(this,'browser');" onmouseout="return nd();"><img id="browsersign" src="$testgdb::util::webloc/web/plus.gif" alt=""> Browser</span> &nbsp;&nbsp;&nbsp;<span class="sm10">( powered by <a href="http://gmod.org/wiki/JBrowse" target="_blank"">JBrowse</a> )</span></div>};
			print qq{<div class="hidden" id="browser"></div>\n};
		}
	}
}

#----------------------------------------------------------------------
# Display browser
# input: none
# return: none
#----------------------------------------------------------------------
sub browser {
	
	my $qryltagRef = testgdb::webUtil::getSessVar( 'qryltag' );
	my $ltag = $qryltagRef->{0}{ltag};
	my $genomeacc = $qryltagRef->{0}{genome};
	
	my ( $astart, $astop ) = testgdb::oracle::dbgetAnnotStartStop( $genomeacc );

	my $dbQryGenomeLtagsRef = testgdb::oracle::dbgetStartStop( $ltag, $genomeacc );
	my %data = %$dbQryGenomeLtagsRef;

	return if ! %data;
	
	my $genome = $testgdb::util::gnom{$testgdb::util::gnomacc{$genomeacc}}{sname};
	my $start  = $data{$ltag}{start} - 3000;
	$start = ($start < $astart) ? $astart : $start;
	
	my $stop   = $data{$ltag}{stop} + 3000;
	$stop = ($stop >= $astop) ? $astop : $stop;
	
	my $loc    = "$genome:$start..$stop";

	print
	  qq{<iframe src ="$testgdb::util::urlpath/jbdata/jbrowse.pl?loc=$loc" width="100%" height="180" frameborder="0">\n},
	  qq{<p>Your browser does not support iframes.</p>\n},
	  qq{</iframe>\n};
}

1;   # return a true value
