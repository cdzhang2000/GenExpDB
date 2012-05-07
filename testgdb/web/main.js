/*
 * GenExpDB javascript
*/
var rec = xmlhttp = '';
function cklogin(un) {
	if(un == '') return;
	document.loginfrm.submit();
}
function ckloginKey(e) {
	var keyPressed;
	if (document.all) {
		keyPressed = e.keyCode;	//IE
	} else {
		keyPressed = e.which;
	}
	if (keyPressed == 13) { 
		document.loginfrm.submit();
	} 
}
function statbar(id) {
	var rec = document.getElementById('stat');
	if (id == 'show') {
		rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	}else{
		rec.innerHTML = '';
	}
}
function sh(id) {
	//show/hide the div
	document.getElementById(id).className = (document.getElementById(id).className=='hidden') ? 'showrec' : 'hidden';
}
function ckqry(qry) {
	//query
	var qry = qry.replace(/^\s+|\s+$|\"+|\'+/g, '');
	if(!qry) {
		document.mainFrm.query.value='';
		return;
	}
	document.mainFrm.query.value=qry;
	document.mainFrm.submit();
}
function gm(id,aid) {
	//menu
	if (id=='home') {
		document.mainFrm.gmid.name='reset';
		document.mainFrm.reset.value='reset';
		document.mainFrm.submit();
	}else{
		aid = (aid) ? aid : '';
		rec = document.getElementById('ginfo');
		rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
		sendRequest('/testgdb/', 'ajax=ginfo&ginfo='+id+'&aid='+aid);
		rec.className = 'showrec';
		if (id=='expgenes') {
			setTimeout("sorttable.makeSortable(document.getElementById('expgenes'))",20000);
		}
	}
}
function sm(col,dir) {
		dir=(dir=='F')?'R':'F';
		document.mainFrm.gmid.name='accsort';
		document.mainFrm.accsort.value=col+':'+dir;
		document.mainFrm.submit();
}
function smfun(id) {
	//multifun
	rec = document.getElementById('mfun');
	if (id == 'open') {
		rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
		sendRequest('/testgdb/', 'ajax=mfun&mfun=open');
		rec.className = 'showrec';
	}else if (id == 'close') {
		document.getElementById('mfunck').checked=false;
		rec.className = 'hidden';
	}else if (id == 'qry') {
		document.getElementById('mfunck').checked=false;
		document.mainFrm.submit();
	}
}
function expand(id) {
	// (+/-) 
	var element = document.getElementById(id);
	var sign = document.getElementById('sign'+id);
	if (element.className == 'hidden') {
		sign.src = '/modperl/testgdb/web/minus.gif';
		sign.title = 'Collapse';
		element.className = 'showrec';
	}else{
		sign.src = '/modperl/testgdb/web/plus.gif';
		sign.title = 'Expand';
		element.className = 'hidden';
	}
}
function mm(elem,id) {
	b=document.getElementById(id+'sign');
	elem.style.cursor='pointer';
	msg = (b.src.search("minus")<0) ? 'display' : 'hide';
	id=id.charAt(0).toUpperCase() + id.slice(1);
	overlib('Click to '+msg+' '+id);
}
function da(id) {
	//show/hide browser/annot/accessions
	rec = document.getElementById(id);
	var esign = document.getElementById(id+'sign');
	if (rec.className == 'hidden') {
		rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
		esign.src = '/modperl/testgdb/web/minus.gif';
		sendRequest('/testgdb/', 'ajax=ginfo&ginfo='+id);
		rec.className = 'showrec';
	}else{
		esign.src = '/modperl/testgdb/web/plus.gif';
		sendRequest('/testgdb/', 'ajax=ginfo&ginfo='+id);
		rec.className = 'hidden';
	}
}
//== download accessions ============================================================
function ckfile(elem,allid,fileid) {
	//select/unselect file
	if (elem.checked) {
		document.getElementById(allid).checked = elem.checked;
	}else{
		var eck=false,frm=elem.form;
		for(i=0;i<frm.length;i++) {
			if (frm[i].name == fileid && frm[i].checked) {
				eck = true;
			}
		}
		document.getElementById(allid).checked = eck;
	}
}
function ckdlaccexp(id) {
	//show/hide download accession experiments
	rec = document.getElementById('dlexp'+id);
	var esign=document.getElementById('dlesign'+id),ckdlaccn=document.getElementById('ckdlaccn'+id);
	if (rec.className == 'hidden') {
		esign.src = '/modperl/testgdb/web/minus.gif';
		rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
		sendRequest('/testgdb/', 'ajax=ginfo&ginfo=showdlexpm&id='+id+'&ckdlaccn='+document.getElementById('ckdlaccn'+id).checked);
		rec.className = 'showrec';
	}else{
		esign.src = '/modperl/testgdb/web/plus.gif';
		rec.className = 'hidden';
	}	
}
function download() {
	var ckdlaccn='',ckdlexpm='';
	for (var i=0; i < document.mainFrm.ckdlaccn.length; i++) {
		if (document.mainFrm.ckdlaccn[i].checked) {
			ckdlaccn = ckdlaccn + document.mainFrm.ckdlaccn[i].value + ',';
		}
	}
	if (document.mainFrm.ckdlexpm) {
		for (var i=0; i < document.mainFrm.ckdlexpm.length; i++) {
			if (document.mainFrm.ckdlexpm[i].checked) {
				ckdlexpm = ckdlexpm + document.mainFrm.ckdlexpm[i].value + ',';
			}
		}	
	}	
	window.open('/modperl/testgdb/download.pl?type=accessions&ckdlaccn='+ckdlaccn+'&ckdlexpm='+ckdlexpm);
}
//===================================================================================
function ckall(elem,id) {
	//select/unselect all
	var frm=elem.form;
	for(i=0;i<frm.length;i++) {
		if (frm[i].name == id) {
			frm[i].checked = elem.checked;
		}
	}
}
function ckallexpmt(elem,aid,eid,accnid) {
	//select/unselect all experiments and accession
	document.getElementById(aid+accnid).checked = elem.checked;
	ckall(elem,eid);
}
function ckexpmt(elem,aid,eid,accnid) {
	//select/unselect experiments
	if (elem.checked) {
		document.getElementById(aid+accnid).checked = elem.checked;
		document.getElementById(eid+accnid).checked = elem.checked;
	}else{
		//TODO - elem false(unchecked)
		//need to check if other experiments checked
		var eck=false,frm=elem.form;
		for(i=0;i<frm.length;i++) {
			if (frm[i].name == 'ckexpm' && frm[i].checked) {
				eck = true;
			}
		}
		document.getElementById(aid+accnid).checked = eck;
		document.getElementById(eid+accnid).checked = eck;
	}
}
function ckaccexp(id) {
	//show/hide accession experiments
	rec = document.getElementById('expmt'+id);
	var esign=document.getElementById('esign'+id),ckaccn=document.getElementById('ckaccn'+id);
	if (rec.className == 'hidden') {
		esign.src = '/modperl/testgdb/web/minus.gif';
		rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
		sendRequest('/testgdb/', 'ajax=accinfo&accinfo=showexpm&id='+id+'&ckaccn='+ckaccn.checked);
		rec.className = 'showrec';
	}else{
		esign.src = '/modperl/testgdb/web/plus.gif';
		rec.className = 'hidden';
	}	
}
function hmclk(hmcnt,expmID,gene,ltag,qryall,accnid,accession,nsd) {
	//heatmap click function
	for (var i=0; i < document.mainFrm.dopt.length; i++) {
		if (document.mainFrm.dopt[i].checked) {
			if(document.mainFrm.dopt[i].value == 'splot' || document.mainFrm.dopt[i].value == 'lplot') {
				var ai = document.getElementById('accn'+accnid);
				if (ai) {
					ai.setAttribute('bgcolor','#e8e1e9');
				}
				var ni = document.getElementById('hmplot'+hmcnt);
				rec = document.createElement('div');
				var divIdName = 'pdiv'+expmID;
				rec.setAttribute('id',divIdName);
				rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
				sendRequest('/testgdb/', 'ajax=plot&plot='+document.mainFrm.dopt[i].value+'&hmcnt='+hmcnt+'&id='+expmID+'&gene='+gene+'&selGene='+ltag+'&qryall='+qryall+'&nsd='+nsd);
				ni.appendChild(rec);	
			}else if(document.mainFrm.dopt[i].value == 'jbrowse') {
				window.open('http://genexpdb.ou.edu/modperl/testgdb/jb_exps/jbrowse.pl?acc='+accession+'_'+expmID);
			}		   
		}
	}
}
function rmdiv(parent,child,accnid) {
	var ai = document.getElementById('accn'+accnid);
	if (ai) {
		ai.setAttribute('bgcolor','#ebf0f2');
	}
	var d = document.getElementById(parent);
	var olddiv = document.getElementById(child);
	d.removeChild(olddiv);
}
function replot(expid,gene,nsd) {
	document.mainFrm.query.value=gene;
	document.getElementById('gmid').name = 'replot';
	document.mainFrm.replot.value=expid+'~'+gene+'~'+nsd;
	document.mainFrm.submit();
}
function pdata(hmcnt,expid) {
	//view plot data
	rec = document.getElementById('pdata'+hmcnt);
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=plot&plot=pdata&hmcnt='+hmcnt+'&expid='+expid);
	rec.className = 'showrec';
}
function supp(type,val,ltag) {
	//get supplement info
	rec = document.getElementById('supp'+ltag);
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=supp&supp='+type+'&sval='+val+'&ltag='+ltag);
	rec.className = 'showrec';
}
function accinfo(type,id) {
	//display accession information
	rec = document.getElementById(type+id);
	if (rec.className == 'hidden') {
		rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
		sendRequest('/testgdb/', 'ajax=accinfo&accinfo='+type+'&id='+id);
		rec.className = 'showrec';
	}else{
		rec.className = 'hidden';
	}
}
function chgchn(chan,id) {
	rec = document.getElementById('expdata'+id);
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=accinfo&accinfo=expdata&id='+id+'&newchan='+chan);
	rec.className = 'showrec';
}
function sampdetail(id,sampID) {
	rec = document.getElementById(id);
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=accinfo&accinfo=sampdetail&id='+id+'&sampID='+sampID);
	rec.className = 'showrec';
}
function updcurated(id) {
	var p='';
	p += document.mainFrm['pi'+id].value + '|~|';
	p += document.mainFrm['institution'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['author'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['pmid'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['title'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['designtype'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['timeseries'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['treatment'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['growthcond'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['modification'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['arraydesign'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['strain'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['substrain'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['info'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	rec = document.getElementById('curated'+id);
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=accinfo&accinfo=updcurated&id='+id+'&parms='+p);
}
function updexperiment(id,form) {
	//update pexp experiment
	var ed=eo=en=et='';
	for(i=0;i<form.length;i++) {
		if (form[i].name.indexOf('deleteExp'+id)!=-1) {
			ed += form[i].checked + '|~|';
		}
		if (form[i].name.indexOf('chgexporder'+id)!=-1) {
			eo += form[i].value.replace(/^\s+|\s+$/g,'') + '|~|';
		}
		if (form[i].name.indexOf('chgExpName'+id)!=-1) {
			tmp = form[i].value.replace(/^\s+|\s+$/g,'');
			if (tmp == '') {
				alert('Experiment Name must not be blank!!');
				document.mainFrm.reset();
				return false;
			}
			tmp = tmp.replace(/\+/g,'%2B');		//replace to get thru html post
			tmp = tmp.replace(/\=/g,'%3D');
			en += tmp + '|~|';
		}
		if (form[i].name.indexOf('chgtimepoint'+id)!=-1) {
			et += form[i].value.replace(/^\s+|\s+$/g,'') + '|~|';
		}
	}
	rec = document.getElementById('expinfo'+id);
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=accinfo&accinfo=updexperiment&id='+id+'&ed='+ed+'&eo='+eo+'&en='+en+'&et='+et);
}
function selPlot1(id) {
	//plot channel 1
	var log=document.getElementById('log'+id).checked;
	var normalize=document.getElementById('normalize'+id).checked;
	var antilog=document.getElementById('antilog'+id).checked;
	var userma=(document.getElementById('userma'+id)) ? document.getElementById('userma'+id).checked : 0;
	var plottype,datacol='';
	if (document.getElementById('plotma'+id).checked) {plottype=document.getElementById('plotma'+id).value};
	if (document.getElementById('plotmb'+id).checked) {plottype=document.getElementById('plotmb'+id).value};
	if (document.getElementById('plotxy'+id).checked) {plottype=document.getElementById('plotxy'+id).value};
	var testnameArr=new Array(),cntlnameArr=new Array();
	var count=0;
	for (i=0; i<document.getElementById('testname'+id).options.length; i++) {
    	if (document.getElementById('testname'+id).options[i].selected) {
      		testnameArr[count]=document.getElementById('testname'+id).options[i].value;
      		count++;
		}
	}
//	var testgenome=document.getElementById('testgenome'+id).value;
	var count=0;
	for (i=0; i<document.getElementById('cntlname'+id).options.length; i++) {
    	if (document.getElementById('cntlname'+id).options[i].selected) {
      		cntlnameArr[count]=document.getElementById('cntlname'+id).options[i].value;
      		count++;
		}
	}
//	var cntlgenome=document.getElementById('cntlgenome'+id).value;
	for (i=0; i<document.getElementById('datacol'+id).options.length; i++) {
    	if (document.getElementById('datacol'+id).options[i].selected) {
      		datacol=document.getElementById('datacol'+id).options[i].value;
		}
	}
	if (userma) {datacol=1;}
	if (datacol.length <1) {alert('Data Value must be selected!');return false;}
	if (testnameArr.length <1) {alert('At least 1 Test sample must be selected!');return false;}
//	if (testgenome.length <1) {alert('Test Genome must be selected!');return false;}
	if (cntlnameArr.length <1) {alert('At least 1 Control sample must be selected!');return false;}
//	if (cntlgenome.length <1) {alert('Control Genome must be selected!');return false;}
	
	var testgenome='';
	var cntlgenome='';
	rec = document.getElementById('selPlot'+id);
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=accinfo&accinfo=sel1Plot&id='+id+'&log='+log+'&normalize='+normalize+'&antilog='+antilog+'&userma='+userma+'&plottype='+plottype+'&testname='+testnameArr+'&testgenome='+testgenome+'&cntlname='+cntlnameArr+'&cntlgenome='+cntlgenome+'&datacol='+datacol);
	rec.className = 'showrec';
}
function selgenome(id,idx) {
	//select genome if not selected
	if (document.getElementById(id).selectedIndex < 0) {
		document.getElementById(id).selectedIndex = idx;
	}
}
function selPlot2(id) {
	//plot channel 2
	var log=document.getElementById('log'+id).checked;
	var normalize=document.getElementById('normalize'+id).checked;
	var antilog=document.getElementById('antilog'+id).checked;
	var plottype,testcol,testbkgd,cntlcol,cntlbkgd='';
	if (document.getElementById('plotma'+id).checked) {plottype=document.getElementById('plotma'+id).value};
	if (document.getElementById('plotmb'+id).checked) {plottype=document.getElementById('plotmb'+id).value};
	if (document.getElementById('plotxy'+id).checked) {plottype=document.getElementById('plotxy'+id).value};
	var sampnameArr=new Array();
	var count=0;
	for (i=0; i<document.getElementById('sampname'+id).options.length; i++) {
    	if (document.getElementById('sampname'+id).options[i].selected) {
      		sampnameArr[count]=document.getElementById('sampname'+id).options[i].value;
      		count++;
		}
	}
	var cntlgenome='';
//	var cntlgenome=document.getElementById('cntlgenome'+id).value;
	for (i=0; i<document.getElementById('testcol'+id).options.length; i++) {
    	if (document.getElementById('testcol'+id).options[i].selected) {
      		testcol=document.getElementById('testcol'+id).options[i].value;
		}
	}
	for (i=0; i<document.getElementById('testbkgd'+id).options.length; i++) {
    	if (document.getElementById('testbkgd'+id).options[i].selected) {
      		testbkgd=document.getElementById('testbkgd'+id).options[i].value;
		}
	}
	for (i=0; i<document.getElementById('cntlcol'+id).options.length; i++) {
    	if (document.getElementById('cntlcol'+id).options[i].selected) {
      		cntlcol=document.getElementById('cntlcol'+id).options[i].value;
		}
	}
	for (i=0; i<document.getElementById('cntlbkgd'+id).options.length; i++) {
    	if (document.getElementById('cntlbkgd'+id).options[i].selected) {
      		cntlbkgd=document.getElementById('cntlbkgd'+id).options[i].value;
		}
	}
	if (sampnameArr.length <1) {alert('At least 1 sample must be selected!');return false;}
//	if (cntlgenome.length <1) {alert('Genome must be selected!');return false;}
	if (normalize && testcol.length <1) {alert('Test Value must be selected!');return false;}
	if (cntlcol.length <1) {alert('Control Value must be selected!');return false;}
	rec = document.getElementById('selPlot'+id);
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=accinfo&accinfo=sel2Plot&id='+id+'&log='+log+'&normalize='+normalize+'&antilog='+antilog+'&plottype='+plottype+'&sampname='+sampnameArr+'&cntlgenome='+cntlgenome+'&testcol='+testcol+'&testbkgd='+testbkgd+'&cntlcol='+cntlcol+'&cntlbkgd='+cntlbkgd);
	rec.className = 'showrec';
}
function swapcond(id) {
	//swap expname conditions
	var expnameArr=document.getElementById('expname'+id).value.split(' / ');
	document.getElementById('expname'+id).value = expnameArr[1]+' / '+expnameArr[0];
}
function findPos(obj) {
	var curtop = 0;
	if (obj.offsetParent) {
		do {
			curtop += obj.offsetTop;
		} while (obj = obj.offsetParent);
	return curtop;
	}
}
function savExptoDB(event,selid,inputid) {
	//save experiment
	var ny=findPos(document.getElementById('selPlot'+selid));
	window.scrollTo(0,ny-500);
	
	var expname=document.getElementById('expname'+inputid).value.replace(/^\s+|\s+$/g,'');
	if (expname.length <1) {alert('ExpName required!');return false;}
	var info=document.getElementById('info'+inputid).value.replace(/^\s+|\s+$/g,'');
	rec = document.getElementById('selPlot'+selid);
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=accinfo&accinfo=savExptoDB&expname='+expname+'&info='+info);
	rec.className = 'showrec';
}
//GeoUpdate-----------------------------------------------------------------------------
function geo() {
	//geoupdate
	rec = document.getElementById('ginfo');
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=geoupdt&geoupdt=update');
	rec.className = 'showrec';
}
function geoEdit(id) {
	rec = document.getElementById(id);
	var esign=document.getElementById('esign'+id);
	if (rec.className == 'hidden') {
		esign.src = '/modperl/testgdb/web/minus.gif';
		rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
		sendRequest('/testgdb/', 'ajax=geoupdt&geoupdt=geoedit&acc='+id);
		rec.className = 'showrec';
	}else{
		esign.src = '/modperl/testgdb/web/plus.gif';
		rec.className = 'hidden';
	}	
}
function geoSave(id) {
	var p='';
	p += document.mainFrm['curStatus'+id].value + '|~|';
	p += document.mainFrm['curPmid'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['curStrain'+id].value + '|~|';
	p += document.mainFrm['curSubStrain'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	p += document.mainFrm['curInfo'+id].value.replace(/^\s+|\s+$/g,'') + '|~|';
	rec = document.getElementById('ginfo');
	rec.innerHTML = '<div align="center"><img src="/modperl/testgdb/web/running.gif" alt=""></div>';
	sendRequest('/testgdb/', 'ajax=geoupdt&geoupdt=geosave&acc='+id+'&parms='+p);
}
//ajax functions-----------------------------------------------------------------------------
function sendRequest(url,parms) {
	xmlhttp=null;
	if (window.XMLHttpRequest){
 		xmlhttp=new XMLHttpRequest();
 	}else if (window.ActiveXObject){
  		xmlhttp=new ActiveXObject('Msxml2.XMLHTTP');
 	}else if (window.ActiveXObject){
  		xmlhttp=new ActiveXObject('Msxml3.XMLHTTP');
 	}else if (window.ActiveXObject){
  		xmlhttp=new ActiveXObject('Microsoft.XMLHTTP');
  	}
  	if (xmlhttp!=null){
  		xmlhttp.onreadystatechange=stateChange;
		xmlhttp.open('POST', url, true);
		xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
		xmlhttp.send(parms);
	}else{
  		alert('Your browser does not support XMLHTTP.');
  	}
}
function stateChange(){
	if (xmlhttp.readyState==4){
  		if (xmlhttp.status==200){
			rec.innerHTML = '';
			rec.innerHTML = xmlhttp.responseText;
   		}else{
    		alert('Problem retrieving data'+xmlhttp.statusText);
    	}
  	}
}