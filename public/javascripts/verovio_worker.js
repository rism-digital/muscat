/**
 * Create the instance of the Verovio toolkit and provides worker methods
 * It uses the Webassembly (WASM) version
 */

 const verovioServer = 'https://www.verovio.org/javascript/5.7.0';

 /////////////////////////////
 // WASM

 self.importScripts(`${verovioServer}/verovio-toolkit-wasm.js`); 
 self.vrvToolkit = null;

 self.verovio.module.onRuntimeInitialized = function() {
     self.vrvToolkit = new verovio.toolkit();
     console.log(`Verovio (WASM) ${self.vrvToolkit.getVersion()}`);
     self.postMessage(["loaded", false, {}]);
 }
 
 /////////////////////////////
 // Common code
 
 self.addEventListener("message", function (event) {
     
    let messageType = event.data[0];
    let target = event.data[1];
    let params = event.data[2];
     
    if (!vrvToolkit) {
        self.postMessage(["error", target, {"error": "The verovio-toolkit has not finished loading yet!"}]);
        return;
    }

    if (messageType == "renderMusic") {
        self.vrvToolkit.setOptions( params["options"] );
        self.vrvToolkit.loadData(params["music"]);
        let svg = vrvToolkit.renderToSVG(1, {});
    
        self.postMessage([messageType + "-ok", target, svg]);
    } else if (messageType == "validatePAE") {
        let validation = self.vrvToolkit.validatePAE(params["music"]);

        self.postMessage([messageType + "-ok", target, validation]);

    } else if (messageType == "renderMEI") {
        self.vrvToolkit.setOptions( params["options"] );
        let svg = self.vrvToolkit.renderData(params["music"], {});
        self.postMessage([messageType + "-ok", target, svg]);
    } else {
        self.postMessage(["unrecognized-" + messageType]);
    }

 

 
 }, false);
