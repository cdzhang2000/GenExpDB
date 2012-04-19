#------------------------------------------------------------------------------------------
# FileName    : jbrowse.pl
#
# Description : Genexpdb jbrowse
# Author      : jgrissom
# DateCreated : 18 Apr 2011
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw(OK DECLINED HTTP_UNAUTHORIZED);

#use Genexpdb::util;
#use Genexpdb::webUtil;

use gdb::util;
use gdb::webUtil;


#----------------------------------------------------------------------
# jbrowse Main entry
#----------------------------------------------------------------------
$gdb::webUtil::r = shift;
$gdb::webUtil::r->content_type('text/html');
gdb::webUtil::getPOSTdata();

print qq{
	<link rel="stylesheet" type="text/css" href="/web/jbrowse-1.2.1/jslib/dijit/themes/tundra/tundra.css"></link>
    <link rel="stylesheet" type="text/css" href="/web/jbrowse-1.2.1/jslib/dojo/resources/dojo.css"></link>
    <link rel="stylesheet" type="text/css" href="/web/jbrowse-1.2.1/genome.css"></link>
   
    <script type="text/javascript" src="/web/jbrowse-1.2.1/jslib/dojo/dojo.js" djConfig="isDebug: false"></script>
    <script type="text/javascript" src="/web/jbrowse-1.2.1/jslib/dojo/jbrowse_dojo.js"></script>
    <script type="text/javascript" src="/web/jbrowse-1.2.1/jbrowse.js"></script>

    <script type="text/javascript" src="$gdb::util::webloc/jbdata/data/refSeqs.js"></script>
    <script type="text/javascript" src="$gdb::util::webloc/jbdata/data/trackInfo.js"></script>

        <script type="text/javascript">
    /* <![CDATA[ */
           var queryParams = dojo.queryToObject(window.location.search.slice(1));
           var bookmarkCallback = function(brwsr) {
               return window.location.protocol 
               			+ "//" + window.location.host 
               			+ window.location.pathname 
               			+ "?loc=" + brwsr.visibleRegion() 
               			+ "&tracks=" + brwsr.visibleTracks();
           }
           var b = new Browser({
                                   containerID: "GenomeBrowser",
                                   browserRoot:"/web/jbrowse-1.2.1/",
                                   refSeqs: refSeqs,
                                   trackData: trackInfo,
                                   defaultTracks: "DNA,gene",
                                   location: queryParams.loc,
                                   tracks: queryParams.tracks,
                                   dataRoot: "$gdb::util::webloc/jbdata/data/"
                               });
    /* ]]> */
    </script>
    
    <div id="GenomeBrowser" style="height: 88%; width: 100%; padding: 0; border: 0;"></div>
};

return Apache2::Const::OK;
