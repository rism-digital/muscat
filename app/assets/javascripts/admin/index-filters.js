// put this in e.g. app/assets/javascripts/admin/index-filters.coffee
// and include this in app/assets/javascripts/active_admin.js
 
// These functions used to be bound linke this:
//$(indexFiltersOnLoad);
//$(document).on("ready page:load", indexFiltersOnLoad);
// But since changes in AA 2.0 we ned to use document.on directly

// The AA part of this is implemented in filters.es6 as AA 2.0
// This function is called after and patches the address query

var filters_clear = function() {
    window.location.search = 'clear_filters=true'
};

var embedded_filters_clear = function() {
  // Do the same but for searching in embedded lists
  window.location.search = 'clear_embedded_filters=true'
}

$(document).on('click', '.clear_filters_btn', filters_clear);
$(document).on('click', '.embedded_search_btn', embedded_filters_clear);