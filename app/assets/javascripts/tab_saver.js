
var tab_saver_unload = false;

function unpack_tab_cookie(cookie) {
    let cookie_value = decodeURI(cookie.split("--")[0])
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
});

// Set a flag to know if we
$(window).on('beforeunload', function() {
    tab_saver_unload = true;
    //window.closed 
});