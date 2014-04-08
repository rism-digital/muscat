# put this in e.g. app/assets/javascripts/admin/index-filters.coffee
# and include this in app/assets/javascripts/active_admin.js
 
$ ->
 
  # Extend the clear-filters button to clear saved filters
  $('.clear_filters_btn').click (evt) ->
    # This will send a synchronous post with clear_filters set to true -
    # our AA FilterSaver controller extension looks for this parameter to
    # know when to clear session-stored filters for a resource - and then
    # the default AA clear-filters button behavior will issue a get request
    # to actually re-render the page.
    $.ajax this.href, {
      async: false,
      data: { clear_filters: true },
      type: 'POST'
    }