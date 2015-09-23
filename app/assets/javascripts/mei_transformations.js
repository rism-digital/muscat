var saxonLoaded = false;
var globalMeiOutput = null;
var globalMeiOutputDocument = null;
var globalXslFile = null;
var globalIncipitStrings = [];

var onSaxonLoad = function () {
    saxonLoaded = true;
};

function parseXMLString(input) {
    var xmlDoc;

    if (window.DOMParser) {
        parser = new DOMParser();
        xmlDoc = parser.parseFromString(input,"text/xml");
    } else { // code for IE
        xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
        xmlDoc.async = false;
        xmlDoc.loadXML(input);
    }
    return xmlDoc;
}

function translateIncipCode(incip, out_format) {

    for (var index = 0; index < incip.length; ++index) {
        var incipcode = incip[index].getElementsByTagName('incipCode')[0]; //childNodes[0];

        if (incipcode === null) {
            continue;
        }

        var pae = "@start:pae-file\n";
        pae = pae + "@data: " + incipcode.textContent + "\n";
        pae = pae + "@end:pae-file\n";

        globalIncipitStrings.push(pae);

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
        var outXml;
        if (out_format === "svg")
            outXml = vrvToolkit.renderPage(1, "");
        else
            outXml = vrvToolkit.getMEI(1, 1);

        var xmlInsert = parseXMLString(outXml);

        incip[index].removeChild(incipcode);
        incip[index].appendChild(xmlInsert.firstChild);
    }
}

function typesetIncipits(incip, out_format) {

    for (var index = 0; index < incip.length; ++index) {
        //incipcode = incip[index].childNodes[0];//getElementsByTagName('score')[0];

        var in_data, incipcode;

        if (out_format === "pae") {
            incipcode = incip[index].getElementsByTagName('incipCode')[0]; //childNodes[0];

            if (incipcode === null) {
                continue;
            }

            var pae = "@start:pae-file\n";
            pae = pae + "@data: " + incipcode.textContent + "\n";
            pae = pae + "@end:pae-file\n";
            in_data = pae;
        } else {
            incipcode = incip[index].getElementsByTagName('score')[0];

            if (incipcode == null) {
                continue;
            }

            //var meiDocType = document.implementation.createDocumentType ("fruit", "SYSTEM", "<!ENTITY tf 'tropical fruit'>");
            var containerDoc = document.implementation.createDocument("http://www.music-encoding.org/ns/mei", "mei", null);
            var music = document.createElement('music');
            var body = document.createElement('body');
            var mdiv = document.createElement('mdiv');

            containerDoc.documentElement.appendChild(music).appendChild(body).appendChild(mdiv).appendChild(incipcode);
            var oSerializer = new XMLSerializer();
            in_data = oSerializer.serializeToString(containerDoc);
        }

        var options = JSON.stringify({
                    inputFormat: out_format,
                    //pageHeight: 250,
                    pageWidth: 1024 / 0.4,
                    spacingStaff: 1,
                    border: 10,
                    scale: 40,
                    ignoreLayout: 0,
                    adjustPageHeight: 1
                });

        vrvToolkit.setOptions( options );
        vrvToolkit.loadData(in_data + "\n" );

        var outXml = vrvToolkit.renderPage(1, "");

        $("#mei-html-output").append(outXml);
    }
}

function executeTransformation(id) {
    if (!vrvToolkit)
        vrvToolkit = new verovio.toolkit();
    var xsl, proc, xmldoc, out_format;

    var file = "/catalog/" + id + ".marcxml";
    if (globalXslFile == null)
        xsl = Saxon.requestXML("/xml/marc2mei.xsl");
    else
        xsl = globalXslFile;

    xml = Saxon.requestXML( file );
    proc = Saxon.newXSLT20Processor(xsl);
    xmldoc = proc.transformToDocument(xml);

    out_format = $("#mei-output-format").val();

    if (out_format != "pae") {
        incip = xmldoc.getElementsByTagName("incip");
        // This call modifies the DOM
        translateIncipCode(incip, out_format);
    }

    var globalMeiOutputDocument = xmldoc;
    var globalMeiOutput = Saxon.serializeXML(xmldoc);

}

function showMEIPreview() {

    $("#mei-html-output").html("");
    var xsl, proc, docu, xmldoc, out_format, incip;

    xsl = Saxon.requestXML("/xml/rism-mei2html.xsl");

    proc = Saxon.newXSLT20Processor(xsl);
    // Use the xsl:result-document magic
    docu = parseXMLString(globalMeiOutput);
    xmldoc = proc.updateHTMLDocument(docu);

    out_format = $("#mei-output-format").val();
    incip = docu.getElementsByTagName("incip");
    typesetIncipits(incip, out_format);

}

function previewMeiFile(id) {

    $("#mei-preview-text").hide();

    if (globalMeiOutput == null) {
        executeTransformation(id);
    }

    showMEIPreview();
    var meiOutputEl = $('#mei-output');

    meiOutputEl.show();
    $("#mei-html-output").show();
    meiOutputEl.text(vkbeautify.xml(globalMeiOutput));
    meiOutputEl.removeClass("prettyprinted");
    prettyPrint();
}

function downloadMeiFile(id) {
    if (globalMeiOutput == null) {
        executeTransformation(id)
    }

    previewMeiFile(id);

    var blob = new Blob([globalMeiOutput], {type: "text/xml"});
    saveAs(blob, id + ".xml");
}

function setRegenerateMei() {
    globalMeiOutput = null;
    globalMeiOutputDocument = null;
    globalIncipitStrings = [];
}

function setUseDefaultStylesheet() {
    globalXslFile = null;
    setRegenerateMei();
    $("#mei-select-file").prop("disabled", "disabled");
}

function setUseCustomStylesheet() {

    $("#mei-select-file").prop("disabled", "");

    fileCount = $("#mei-select-file").prop("files").length;
    if (fileCount == 0) {
         $("#mei-select-file").click();
         setRegenerateMei();
    }
}

function readSingleFile(evt) {
    //Retrieve the first (and only!) File from the FileList object
    var f = evt.target.files[0];

    if (f) {
        var r = new FileReader();
        r.onload = function(e) {
            content = e.target.result;
            globalXslFile = parseXMLString(content);
            setRegenerateMei();
        };

        r.readAsText(f);
    } else {
        alert("Failed to load file");
    }
}
