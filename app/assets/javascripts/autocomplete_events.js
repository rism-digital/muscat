// React to the select event
function autocomplete_selct(event, data)	{
  var input = $(event.target); // Get the autocomplete id
		
  // havigate up to the <li> and down to the hidden elem
  var toplevel_li = input.parents("li");
  var hidden = toplevel_li.children(".autocomplete_target")
		
  // the data-field in the hidden tells us which
  // field write in the input value. Default is id
  var field = hidden.data("field")
		
  hidden.addClass("serialize_marc");
  var element_class = marc_editor_validate_className(hidden.data("tag"), hidden.data("subfield"));
  hidden.addClass(element_class);
  hidden.val(data.item[field]);
  hidden.data("status", "selected");
		
  input.removeClass("serialize_marc");
  input.removeClass("new_autocomplete");
		
  // Make the form dirty
  marc_editor_set_dirty();
		
  // Remove the checkbox
  var check_tr = toplevel_li.find(".checkbox_confirmation")
  check_tr.fadeOut("fast");
		
  var check = toplevel_li.find(".creation_checkbox")
  check.data("check", false)
		
  // Set auxiliary data
  var group = input.parents(".tag_content_collapsable");
  $(".autocomplete_extra", group).each(function () {
    $(this).prop('disabled', true);
    $(this).removeClass("autocomplete_extra_enabled");
    var extra_data = $(this).data("autocomplete-extra");
    if (extra_data in data.item) {
      $(this).val(data.item[extra_data])
    } else {
      console.log("Autocomplete extra data: cound not find " + extra_data + " in element.")
    }
  });
}
	
function bind_autocomplete_events() {
  /* Bind to the global railsAutocomplete. event, thrown when someone selects
  from an autocomplete field. It is a delegated method so dynamically added
  forms can handle it
  */
  $("#marc_editor_panel").on('autocompleteopen', function(event, data) {
    input = $(event.target); // Get the autocomplete id
    toplevel_li = input.parents("li");
    hidden = toplevel_li.children(".autocomplete_target")
		
    hidden.data("status", "opened");
  });

  $("#marc_editor_panel").on('autocompletechange', function(event, data) {
    input = $(event.target); // Get the autocomplete id
		
    // havigate up to the <li> and down to the hidden elem
    toplevel_li = input.parents("li");
    hidden = toplevel_li.children(".autocomplete_target")
		
    if (hidden.data("status") != "selected") {
		
      // Are we allowed to create a new?
      if (hidden.data("allow-new") == false) {
        alert("Item cannot create a new element, please select one from the list.");
        input.addClass("error");
        return false;
      }
		
      hidden.val("");
      hidden.removeClass("serialize_marc");
      var element_class = marc_editor_validate_className(hidden.data("tag"), hidden.data("subfield"));
      hidden.removeClass(element_class);
		
      input.addClass("serialize_marc");
      input.addClass("new_autocomplete");
			
      // Make the form dirty
      marc_editor_set_dirty();
			
      // Show the checkbox
      check_tr = toplevel_li.find(".checkbox_confirmation")
      check_tr.fadeIn("fast");
			
      check = toplevel_li.find(".creation_checkbox")
      check.data("check", true)
			
      // Remove auxiliary data and enable
      var group = input.parents(".tag_content_collapsable");
      $(".autocomplete_extra", group).each(function () {
        $(this).prop('disabled', false);
        $(this).addClass("autocomplete_extra_enabled");
        $(this).val("");
      });
			
    }
  });

  $("#marc_editor_panel").on('autocompleteresponse', function(event, data) {
    input = $(event.target); // Get the autocomplete id
    toplevel_li = input.parents("li");
    hidden = toplevel_li.children(".autocomplete_target")
		
    if (data.content.length == 0) {
      hidden.data("status", "nomatch");
    } else {
      // if the first one is _exactly_ the same match, select it!
      if (data.content[0].value == input.val()) {
        autocomplete_selct(event, {item: data.content[0]})
      }
    }
  });

  $("#marc_editor_panel").on('railsAutocomplete.select', 'input.ui-autocomplete-input', autocomplete_selct);
	
}