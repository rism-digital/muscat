/**
 * Create the instance of the Verovio toolkit and provides worker methods
 * It uses the Webassembly (WASM) version
 */

 const verovioServer = 'https://www.verovio.org/javascript/3.7.0';

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
     
    if (!vrvToolkit) {
        postMessage(["error", ticket, {"error": "The verovio-toolkit has not finished loading yet!"}]);
        return;
    }

    if (messageType == "renderMusic") {
        vrvToolkit.setOptions( params["options"] );
        vrvToolkit.loadData(params["music"]);
        let svg = vrvToolkit.renderToSVG(1, {});
    
        let highlights = [];
        let messages = []
        let validation = vrvToolkit.validatePAE(params["music"]);
        //console.log("Validate", validation);
        if (validation.hasOwnProperty("clef")) {
            messages.push(validation["clef"]["text"]);
        }
        if (validation.hasOwnProperty("keysig")) {
            messages.push(validation["keysig"]["text"]);
        }
        if (validation.hasOwnProperty("timesig")) {
            messages.push(validation["timesig"]["text"]);
        }
        if (validation.hasOwnProperty("data")) {
            let data = validation["data"];
            //console.log(data);
            for (var i = 0; i < data.length; i++) {
                messages.push(data[i]["column"] + ": " + data[i]["text"]);
                let j = data[i]["column"];
                if (j > 0) highlights.push([j - 1, j]);
            }
        }

        postMessage([messageType + "-ok", target, svg, messages, highlights]);
    } else if (messageType == "renderMEI") {
        vrvToolkit.setOptions( params["options"] );
        let svg = vrvToolkit.renderData(params["music"], {});
        postMessage([messageType + "-ok", target, svg]);
    } else {
        postMessage(["unrecognized-" + messageType]);
    }

 

 
 }, false);