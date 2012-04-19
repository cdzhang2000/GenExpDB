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
package testgdb::main;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw(OK DECLINED HTTP_UNAUTHORIZED);

use Time::Elapse;

use testgdb::accessions;
use testgdb::annotation;
use testgdb::browser;
use testgdb::geoupdate;
use testgdb::heatmap;
use testgdb::info;
use testgdb::mfun;
use testgdb::oracle;
use testgdb::plot;
use testgdb::util;
use testgdb::webUtil;

#----------------------------------------------------------------------
# GenExpDB Main handler entry
#----------------------------------------------------------------------
sub handler {
	$testgdb::webUtil::r = shift;
	$testgdb::webUtil::r->content_type('text/html');

	Time::Elapse->lapse( my $now );   # start timer

	testgdb::webUtil::getPOSTdata();
	testgdb::webUtil::createSession();

	testgdb::util::initDefaults();

	if ( $testgdb::webUtil::frmData{ajax} ) {           #ajax calls
		testgdb::util::ajax();
		return Apache2::Const::OK;
	}

	my $retval = testgdb::webUtil::pageHead();
	return Apache2::Const::OK if ( $retval < 0 );

	testgdb::util::mainMain();

	printf( "<font size=1>%s sec</font><br>", substr( $now, 3 ) );
	testgdb::webUtil::pageTail("/testgdb/main.pm");

	return Apache2::Const::OK;
}

1;    # return a true value
