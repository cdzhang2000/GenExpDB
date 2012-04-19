#------------------------------------------------------------------------------------------
# FileName    : gdb/main.pm
#
# Description : Main
# Author      : jgrissom
# DateCreated : 22 Apr 2011
# Version     : 2.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
package gdb::main;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw(OK DECLINED HTTP_UNAUTHORIZED);

use Time::Elapse;

use gdb::accessions;
use gdb::annotation;
use gdb::browser;
use gdb::geoupdate;
use gdb::heatmap;
use gdb::info;
use gdb::mfun;
use gdb::oracle;
use gdb::plot;
use gdb::util;
use gdb::webUtil;

#----------------------------------------------------------------------
# GenExpDB Main handler entry
#----------------------------------------------------------------------
sub handler {
	$gdb::webUtil::r = shift;
	$gdb::webUtil::r->content_type('text/html');

	Time::Elapse->lapse( my $now );   # start timer

	gdb::webUtil::getPOSTdata();
	gdb::webUtil::createSession();

	gdb::util::initDefaults();

	if ( $gdb::webUtil::frmData{ajax} ) {           #ajax calls
		gdb::util::ajax();
		return Apache2::Const::OK;
	}

	my $retval = gdb::webUtil::pageHead();
	return Apache2::Const::OK if ( $retval < 0 );

	gdb::util::mainMain();

	printf( "<font size=1>%s sec</font><br>", substr( $now, 3 ) );
	gdb::webUtil::pageTail("/gdb/main.pm");

	return Apache2::Const::OK;
}

1;    # return a true value
