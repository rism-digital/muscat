var saxonLoaded = false;
var globalStore = {};

function marc_transform(id) {
	
	$.when(
		$.get("/catalog/" + id + ".marcxml", function(xml) {
			globalStore.marc = xml;
		}),
		
		$.get("/xml/marc2mei.xsl", function(xml) {
			globalStore.stylesheet = xml;
		})
		
	).then(
	// All ok
	function(){
		alert("all done!");
	},
	// Error
	function(){
		//alert("Darn!");
	});
}

var onSaxonLoad = function() {
	saxonLoaded = true;
	return;
}

function dosax(id) {
	vrvToolkit = new verovio.toolkit();
	
	file = "/catalog/402000797.marcxml";
    xsl = Saxon.requestXML("/xml/marc2mei.xsl");
    xml = Saxon.requestXML( file );
    proc = Saxon.newXSLT20Processor(xsl);
	xmldoc = proc.transformToDocument(xml);
	
	/*
    xsl = Saxon.requestXML("/xml/rism-mei2html.xsl");
    xml = Saxon.parseXML( globalStore.mei );
    proc = Saxon.newXSLT20Processor(xsl);
	pepo = proc.transformToDocument(xml);
	globalStore.html = Saxon.serializeXML( pepo);
	*/
	incip = xmldoc.getElementsByTagName("incip");
	for (index = 0; index < incip.length; ++index) {
		incipcode = incip[index].childNodes[0];
		clef = incipcode.getAttribute("clef");
		key = incipcode.getAttribute("key");
		meter = incipcode.getAttribute("meter");
		
		
		
		pae = "@start:pae-file\n";
		pae = pae + "@clef:" + clef + "\n";
		pae = pae + "@keysig:" + key + "\n";
		pae = pae + "@key:\n";
		pae = pae + "@timesig:" + meter + "\n";
		pae = pae + "@data: " + incipcode.textContent + "\n";
		pae = pae + "@end:pae-file\n";
		
		options = JSON.stringify({
					inputFormat: 'pae',
					//pageHeight: 250,
					pageWidth: 1024 / 0.4,
					spacingStaff: 1,
					border: 10,
					scale: 40,
					ignoreLayout: 0,
					adjustPageHeight: 1
				});
				
		vrvToolkit.setOptions( options );
		vrvToolkit.loadData(pae + "\n" );
		svg = vrvToolkit.renderPage(1, "");
		console.log(svg);
	}
	
	
	globalStore.mei = Saxon.serializeXML(xmldoc);
	
	$("#mei-output").html(globalStore.mei);
	
	var blob = new Blob([globalStore.mei], {type: "text/xml"});
	saveAs(blob, id + ".mei");
	
}