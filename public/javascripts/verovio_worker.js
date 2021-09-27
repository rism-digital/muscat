/**
 * Create the instance of the Verovio toolkit and provides worker methods
 * It uses the Webassembly (WASM) version
 */

 const verovioServer = 'https://www.verovio.org/javascript/3.6.0';

 /////////////////////////////
 // WASM
 
 self.Module = {
     locateFile: function (s) {
         return `${verovioServer}/${s}`;
     },
     onRuntimeInitialized: function() {
         self.vrvToolkit = new verovio.toolkit();
         //console.log(self.vrvToolkit);
         //console.log(`Verovio (WASM) ${self.vrvToolkit.getVersion()}`); // works!
         postMessage(["loaded", self.vrvToolkit, {}]);
     }
 };
 
 self.importScripts(`${verovioServer}/verovio-toolkit-wasm.js`); 
 self.vrvToolkit = null;
 
 /////////////////////////////
 // Common code
 
 self.addEventListener("message", function (event) {
     
    let messageType = event.data[0];
    let target = event.data[1];
    let params = event.data[2];
     

    if (messageType != "renderMusic") {
        return;
    }
 
    if (!vrvToolkit) {
        postMessage(["error", ticket, {"error": "The verovio-toolkit has not finished loading yet!"}]);
        return;
    }
 
    vrvToolkit.setOptions( params["options"] );
	vrvToolkit.loadData(params["music"]);
	let svg = vrvToolkit.renderToSVG(1, {});

    postMessage([messageType + "-ok", target, svg]);
 
 }, false);