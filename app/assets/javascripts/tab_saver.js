
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
            $('#tab-debug').text("Dup, new id: " + new_tab_id)
            
        }
    };
    
    //console.log("Installed muscat-tabs channel")
}

function unpack_tab_cookie(cookie) {
    let parts = cookie.split("--")

    if (parts.length < 2) {
        return null;
    }

    // Even if there is nothing to split,
    // there is always the first.
    let cookie_value = decodeURI(parts[0])
    let cookie_payload = JSON.parse(atob(cookie_value))

    // In rails 7 we need to extract more...
    let message = JSON.parse(atob(cookie_payload["_rails"]["message"]))

    return message
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
        }
        tab_saver_unload = false;
    }
});


$(window).on('load', function() {
    let new_tab = sessionStorage.getItem("tab-id") === null ? true : false
    let tab_id = get_or_create_tab_id();

    // Copy the cookie with our data in our storage
    if (Cookies.get("tab-store")) {
        let cookie = unpack_tab_cookie(Cookies.get("tab-store"));
        // Could we parse the cookie?
        if (cookie) {
            console.log("Received cookie for " + cookie["tab-id"] + " actual id: " + tab_id)

            // If the cookie is for us or if this is a freshly opened tab
            // save the searches. If we receive data for another tab, it
            // means both were loaded at the same time and the tab-id cookie
            // got overwritten. In this case we do not mix the two requests
            if (cookie["tab-id"] === tab_id || new_tab) {
                sessionStorage.setItem("tab-store", Cookies.get("tab-store"));
            } else {
                console.log("Tab id mismatch, possible race condition? Do not update tab store")
            }
        }
    }

    if (new_tab) {
        $('#tab-debug').text("New tab: " + tab_id)
    }

    tab_saver_select();

    // This installs the deduplicator. If we are a duplicate
    // it will take care of fixing all the relevant parts
    // Run it for last since it can call tab_saver_select();
    setup_deduplication(tab_id)
});

var logout_originator = false;
var open_windows = 0;
var logout_timeout;

function setup_logout_timeout() {
    logout_timeout = setTimeout(function() {
        $.unblockUI
        window.location.href = "/admin/logout"
    }, 1000)
}

function setup_logout_watcher() {
    const id = this.crypto.randomUUID();
    //const logout_channel = new BroadcastChannel('muscat-logout')
    let probe_channel = new BroadcastChannel('muscat-probe-open')

    //logout_channel.onmessage = (event) => {
    //    alert(logout_channel.event);
    //}

    probe_channel.onmessage = (event) => {

        let evt_parts = event.data.split(":") // 0 index is always filled
        //console.log(evt_parts)
        //console.log(id)

        if (evt_parts.lenght < 2) {
            console.log("Malformed message")
            return
        }

        if (evt_parts[1] == id) {
            console.log("Ignore message for myself")
            return
        }

        if (evt_parts[0] == "muscat_window_logout") {
            //var wait = Math.floor(Math.random() * 150);
            //setTimeout(() => console.log(""), wait)
            probe_channel.postMessage("muscat_window_open:" + id)
            return;
        }

        if (evt_parts[0] == "muscat_logged_out") {
            alert(I18n.t("logout.warning"))
            return;
        }

        if (evt_parts[0] === "muscat_window_open" && logout_originator && open_windows == 0) {
            open_windows++;
            if (logout_timeout)
                clearTimeout(logout_timeout);
            
            $.unblockUI()
            var do_logout = confirm(I18n.t("logout.confirm"))
            //var do_logout = confirm("There are open Muscat windows with unsaved changes. Logging out will cause the changes to be lost. Do you want to continue?")
            if (do_logout) {
                probe_channel.postMessage("muscat_logged_out")
                window.location.href = "/admin/logout"
            } else {
                logout_originator = false
            }
        }

    }

    $('[data-logout-link]').on('click', function(e) {
        e.preventDefault();

        $.blockUI({message: "Logging you out"});
        setup_logout_timeout();

        probe_channel.postMessage("muscat_window_logout:" + id);
        logout_originator = true;
        open_windows = 0;
        return false;
    });
}

function show_clipboard_toast() {
    var toast = $('#clipboard-message');

    toast.fadeIn("fast");

    setTimeout(function() {
        toast.fadeOut("slow");
    }, 2000);
}

// is this really the only way to do this??
function get_origin() {
    var protocol = window.location.protocol;
    var hostname = window.location.hostname;
    var port = window.location.port;
    var fullHost = protocol + '//' + hostname;
    if (port) {
        fullHost += ':' + port;
    }
    return fullHost;
}

function setup_clipboard() {
    // Add the Clipboard functions
    var clipboard = new ClipboardJS('.copy_to_clipboard', {
        text: function(trigger) {
            let table_class = $(trigger).data("clipboard-target")
            if ($(table_class).length < 1)
                return;

            let table = $(table_class)[0]
            let rows = table.getElementsByTagName('tr');
            let dataToCopy = '';
        
            for (let i = 0; i < rows.length; i++) {
                let cells = rows[i].getElementsByTagName('td');
                if (cells.length == 0)
                    cells = rows[i].getElementsByTagName('th');
                let rowData = [];
        
                for (let j = 1; j < cells.length - 1; j++) {
                    rowData.push(cells[j].innerText);
                }
        
                // the last cell is the Show/Edit/Delete buttons
                var edit_link = $(cells[cells.length - 1]).find("a.edit_link")
                if (edit_link.length > 0)
                    rowData.push(get_origin() + $(edit_link[0]).attr("href"))

                dataToCopy += rowData.join('\t') + '\n'; // Use tab-delimited format or change as needed
            }
            
            //console.log(dataToCopy)
            return dataToCopy;
        }
    });

    clipboard.on('success', function(e) {
        show_clipboard_toast();
        e.clearSelection();
    });
}

$(document).ready(function() {
    setup_logout_watcher();
    setup_clipboard();

});

// Set a flag to know if we
$(window).on('beforeunload', function() {
    tab_saver_unload = true;
    //window.closed if we need more cleanup?
});
