
var tab_saver_unload = false;

// When a tab is loaded, it broadcasts its UUID in the
// muscat-tabs BroadcastChannel. If this UUID is unique,
// nothing will happen, but if there is a duplicate, i.e.
// the user duplicated a tab, it will receive an "exist" event,
// like 37fce78a-exists. In this case it generates a new UUID.
// This function also listens on muscat-tabs, in case
// a duplicate is made of this current tab
function setup_deduplication(tab_id) {
    const broadcast = new BroadcastChannel('muscat-tabs')

    broadcast.postMessage(tab_id);

    broadcast.onmessage = (event) => {
        if (event.data === tab_id) {
            broadcast.postMessage(tab_id + "-exists");
            console.log("Received poke from possible duplicate " + tab_id);
        }
        if (event.data === tab_id + "-exists") {
            // We are a dup tag, regenerate the UUID
            sessionStorage.removeItem("tab-id")
            let new_tab_id = get_or_create_tab_id();
            console.log("Duplicate id " + tab_id + ", new id: " + new_tab_id);
            // "select" the tab to apply changes
            tab_saver_select();
            $('#tab-debug').text("New id: " + new_tab_id)
            
        }
    };
    
    console.log("Installed muscat-tabs channel")
}

function unpack_tab_cookie(cookie) {
    let cookie_value = decodeURI(cookie.split("--")[0])
    console.log(atob(cookie_value))
    let cookie_payload = JSON.parse(atob(cookie_value))

    return cookie_payload
}

function get_or_create_tab_id() {
    let tab_id = this.crypto.randomUUID().substring(0, 8)
    if (!sessionStorage.getItem("tab-id")) {
        // We don't really need the full uuid
        sessionStorage.setItem("tab-id", tab_id);
    } else {
        tab_id = sessionStorage.getItem("tab-id");
    }

    return tab_id;
}

function tab_saver_select() {
    let tab_id = get_or_create_tab_id()

    Cookies.set("tab-id", tab_id);
    // Get the search data back from our storage
    Cookies.set("tab-store", sessionStorage.getItem("tab-store"))
    console.log("Set tab to " + tab_id)
}


$(document).on('visibilitychange', function() {
    if (!document.hidden) {
        tab_saver_select();
    } else {
        // document.hidden == true is set every time
        // there is a request. Here we are only interested
        // when the tab is actually hidden
        if (!tab_saver_unload) {
            console.log("Unset tab from " + get_or_create_tab_id())
            //Cookies.remove("tab-id");
            //Cookies.remove("tab-store");
        }
        tab_saver_unload = false;
    }
});


$(window).on('load', function() {
    let tab_id = get_or_create_tab_id();

    // Copy the cookie with our data in our storage
    if (Cookies.get("tab-store")) {
        let cookie = unpack_tab_cookie(Cookies.get("tab-store"));
        console.log("Received cookie for " + cookie["tab-id"] + " actual id: " + tab_id)

        if (cookie["tab-id"] == tab_id) {
            sessionStorage.setItem("tab-store", Cookies.get("tab-store"));
        } else {
            console.log("Tab id mismatch, possible race condition? Do not update tab store")
        }
    }

    tab_saver_select();

    // This installs the deduplicator. If we are a duplicate
    // it will take care of fixing all the relevant parts
    // Run it for last since it can call tab_saver_select();
    setup_deduplication(tab_id)
});

// Set a flag to know if we
$(window).on('beforeunload', function() {
    tab_saver_unload = true;
    //window.closed 
});
