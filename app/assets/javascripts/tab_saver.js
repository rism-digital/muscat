
var tab_saver_unload = false;

function tab_saver_select() {
    if (!sessionStorage.getItem("tab-id")) {
        // We don't really need the full uuid
        sessionStorage.setItem("tab-id", this.crypto.randomUUID().substring(0, 8));
    }

    let tab_id = sessionStorage.getItem("tab-id");
    Cookies.set("tab-id", tab_id);
    // Get the search data back from our storage
    Cookies.set("tab-store", sessionStorage.getItem("tab-store"))
    console.log("Set tab to " + tab_id)
    console.log("Set tab data " + sessionStorage.getItem("tab-store"))
}


$(document).on('visibilitychange', function() {
    if (!document.hidden) {
        tab_saver_select();
    } else {
        // document.hidden == true is set every time
        // there is a request. Here we are only interested
        // when the tab is actually hidden
        if (!tab_saver_unload) {
            console.log("Unset tab to " + sessionStorage.getItem("tab-id"))
            Cookies.remove("tab-id");
            Cookies.remove("tab-store");
        }
        tab_saver_unload = false;
    }
});


$(window).on('load', function() {
    console.log("loading page")
    console.log(document.cookie);
    console.log(Cookies.get("tab-store"))

    // Copy the cookie with our data in our storage
    if (Cookies.get("tab-store"))
        sessionStorage.setItem("tab-store", Cookies.get("tab-store"));

    tab_saver_select();
});

// Set a flag to know if we
$(window).on('beforeunload', function() {
    tab_saver_unload = true;
    console.log(window.closed)
    alert("osdfdf")
});

$(document).ready(function() {
    console.log("docu ready")
    console.log(document.cookie);
});
