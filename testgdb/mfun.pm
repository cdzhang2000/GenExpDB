#------------------------------------------------------------------------------------------
# FileName    : gdb/mfun.pm
#
# Description : Multifun
# Author      : jgrissom
# DateCreated : 19 Aug 2010
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package testgdb::mfun;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

#----------------------------------------------------------------------
# display MultiFun selections
# input: none
# return: none
#----------------------------------------------------------------------
sub displayMultifun {

	my ( $dbMFunSelRef, $midOrderRef ) = testgdb::oracle::dbMFunSel();
	my %dbMFunSel = %$dbMFunSelRef;
	my @midOrder  = @$midOrderRef;

	print
	  qq{<table align="center">},
	  qq{<tr>\n},
	  qq{<td valign="top"><a class="exmp" onclick="smfun('close');" onmouseover="this.style.cursor='pointer';return overlib('click to close');" onmouseout="return nd();">close</a></td>\n},

	  qq{<td>\n},    #MFun start===========
	  qq{<table class="tblb">\n}, qq{<tr>\n}, qq{<td>\n},

	  qq{<table cellpadding="1" cellspacing="1" align="center">\n},
	  qq{<tr>\n},
	  qq{<td align="center">MultiFun Selections</td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td class="tdc"><input class="ebtn" type="button" name="mfunB" value="Submit" onclick="smfun('qry');"></td>\n},
	  qq{</tr>\n},
	  qq{<tr>\n},
	  qq{<td class="tdl">\n};

	for my $mid (@midOrder) {
		if ( $dbMFunSel{top}{$mid}{pid} == 0 ) {
			if ( exists $dbMFunSel{sub}{$mid} ) {
				print
				  qq{<img id="sign$mid" src="$testgdb::util::webloc/web/plus.gif" onclick="expand('$mid');" alt="" onmouseover="this.style.cursor='pointer';return overlib('expand');" onmouseout="return nd();">\n};
			} else {
				print qq{ &nbsp;&nbsp;&nbsp;\n};
			}
			print qq{<input type="checkbox" name="selmfun" value="$dbMFunSel{top}{$mid}{mlevel}">\n};
			print qq{$dbMFunSel{top}{$mid}{mlevel} $dbMFunSel{top}{$mid}{mfunction} <span class="small">($dbMFunSel{top}{$mid}{cnt})</span><br>\n};
			mfunSubLevels( $mid, \%dbMFunSel, \@midOrder );
		}
	}

	print qq{</td>\n}, qq{</tr>\n}, qq{</table>\n},

	  qq{</td>\n}, qq{</tr>\n}, qq{</table>\n}, qq{</td>\n},

	  qq{</tr>\n}, qq{</table>\n};
}

#----------------------------------------------------------------------
# display MultiFun sub levels
# input: string Level key
# return: none
#----------------------------------------------------------------------
sub mfunSubLevels {
	my ( $levelkey, $dbMFunSelRef, $midOrderRef ) = @_;
	my %dbMFunSel = %$dbMFunSelRef;
	my @midOrder  = @$midOrderRef;

	print qq{<div class="hidden" id="$levelkey" style="margin-left:1cm;text-align:left;">\n};
	for my $mid (@midOrder) {
		if ( $levelkey == $dbMFunSel{top}{$mid}{pid} ) {
			if ( exists $dbMFunSel{sub}{$mid} ) {
				print
				  qq{<img id="sign$mid" src="$testgdb::util::webloc/web/plus.gif" onclick="expand('$mid');" alt="" onmouseover="this.style.cursor='pointer';return overlib('expand');" onmouseout="return nd();">\n};
			} else {
				print qq{ &nbsp;&nbsp;&nbsp;\n};
			}
			print qq{<input type="checkbox" name="selmfun" value="$dbMFunSel{top}{$mid}{mlevel}">\n};
			print qq{$dbMFunSel{top}{$mid}{mlevel} $dbMFunSel{top}{$mid}{mfunction} <span class="small">($dbMFunSel{top}{$mid}{cnt})</span><br>\n};
			mfunSubLevels( $mid, \%dbMFunSel, \@midOrder );
		}
	}
	print qq{</div>\n};
}



1;    # return a true value
