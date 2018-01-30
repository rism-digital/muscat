// SIMILE is not used anymore (and messes with jQuery!) so it was removed 
// TimeplotLoader.load(GeoTemCoLoader.urlPrefix + 'lib/', GeoTemCoLoader.loadScripts);

// ..but we still need (and use) the following defines, that where copied from there
/* string.js */
String.prototype.trim=function(){return this.replace(/^\s+|\s+$/g,"");
};
String.prototype.startsWith=function(A){return this.length>=A.length&&this.substr(0,A.length)==A;
};
String.prototype.endsWith=function(A){return this.length>=A.length&&this.substr(this.length-A.length)==A;
};
String.substitute=function(B,D){var A="";
var F=0;
while(F<B.length-1){var C=B.indexOf("%",F);
if(C<0||C==B.length-1){break;
}else{if(C>F&&B.charAt(C-1)=="\\"){A+=B.substring(F,C-1)+"%";
F=C+1;
}else{var E=parseInt(B.charAt(C+1));
if(isNaN(E)||E>=D.length){A+=B.substring(F,C+2);
}else{A+=B.substring(F,C)+D[E].toString();
}F=C+2;
}}}if(F<B.length){A+=B.substring(F);
}return A;
};

/* date-time.js */
SimileAjax=new Object();
SimileAjax.DateTime=new Object();
SimileAjax.DateTime.MILLISECOND=0;
SimileAjax.DateTime.SECOND=1;
SimileAjax.DateTime.MINUTE=2;
SimileAjax.DateTime.HOUR=3;
SimileAjax.DateTime.DAY=4;
SimileAjax.DateTime.WEEK=5;
SimileAjax.DateTime.MONTH=6;
SimileAjax.DateTime.YEAR=7;
SimileAjax.DateTime.DECADE=8;
SimileAjax.DateTime.CENTURY=9;
SimileAjax.DateTime.MILLENNIUM=10;
SimileAjax.DateTime.EPOCH=-1;
SimileAjax.DateTime.ERA=-2;

SimileAjax.includeCssFile = function(doc, url) {
	var link = doc.createElement("link");
	link.setAttribute("rel", "stylesheet");
	link.setAttribute("type", "text/css");
	link.setAttribute("href", url);
	doc.getElementsByTagName("head")[0].appendChild(link);
};