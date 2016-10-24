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
  
  // 1) When the user stars to type in the AC, it triggers this event and
  // opens the menu. We set a flag into the hidden field to signal we
  // are now using the AC. This is called every time the menu is shown
  // or UPDATED. We set the "opened" status only if it was opened, not
  // updated, as this triggers after the response event, and would erase
  // the eventual "selected" status set
  $("#marc_editor_panel").on('autocompleteopen', function(event, data) {
    var input = $(event.target); // Get the autocomplete id
    var toplevel_li = input.parents("li");
    var hidden = toplevel_li.children(".autocomplete_target")
		
    // undefined means it is the first time ever we open this AC
    // closed menans at some point is was... closed
    if (hidden.data("status") === "undefinded" || hidden.data("closed")) {
      hidden.data("status", "opened");
    }
    
    var menu = input.data("uiAutocomplete").menu
    var $items = $('li', menu.element);
    var item;
    //var startsWith = new RegExp("^" + input.val(), "i");

    for (var i = 0; i < $items.length && !item; i++) {
      text = $items.eq(i).text();
      if (text == input.val()) {
        item = $items.eq(i);
        break;
      }
    }

    if (item) {
      menu.focus(null, item);
    }
    
  });

  // 2) The user types and results come in. If no results are there
  // we set the "status" in the hidden to "nomatch". If there are
  // results, we compare the very first result to the text typed in
  // If they are the same we automatically select this value, by
  // calling autocomplete_select. This sets the "status" value
  // in the hidden to "selected".
  $("#marc_editor_panel").on('autocompleteresponse', function(event, data) {
    var input = $(event.target); // Get the autocomplete id
    var toplevel_li = input.parents("li");
    var hidden = toplevel_li.children(".autocomplete_target")
		
    if (data.content.length == 0) {
      hidden.data("status", "nomatch");
    } else {
      // if the first one is _exactly_ the same match, select it!
      for (var i = 0; i < data.content.length; i++) {
        if (data.content[i].value == input.val()) {
          autocomplete_selct(event, {item: data.content[i]});
          break;
        }
      }
    }
  });

  // 3) This is called if the user select a value from the AC
  // It calls autocomplete_selct() for setting all the fields, and
  // will set the "status" of the hidden to "selected"
  $("#marc_editor_panel").on('railsAutocomplete.select', 'input.ui-autocomplete-input', autocomplete_selct);
  

  // 4) Despite whan the name says, this is triggered only AFTER the user
  // has choosen (or not) a value. Change in the sense "changed value"
  // if the hidden status is not "selected" then we show the confirmation
  // checkbox.
  // It also sets the status data to "closed", to be reset on open
  $("#marc_editor_panel").on('autocompletechange', function(event, data) {
    var input = $(event.target); // Get the autocomplete id
		
    // havigate up to the <li> and down to the hidden elem
    var toplevel_li = input.parents("li");
    var hidden = toplevel_li.children(".autocomplete_target")

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

      // Show the checkbox - but only for real "linked" fields
      // the link-to permit empty values, so in that case do
      // not display the checkbox. In all the others yes
      if (hidden.data("has-links-to") == false ||
         (hidden.data("has-links-to") == true && input.val() != "")) {
        // Show the checkbox
        var check_tr = toplevel_li.find(".checkbox_confirmation")
        check_tr.fadeIn("fast");

        check = toplevel_li.find(".creation_checkbox")
        check.data("check", true)
      }

      // Hide the checkbox if it was previously shown
      // for links_to and empty value
      // This is the case in which the user inserts a new value
      // and the deletes it. We want the check to disappear
      if (hidden.data("has-links-to") == true && input.val() == "") {
        // Remove the checkbox
        var check_tr = toplevel_li.find(".checkbox_confirmation")
        check_tr.fadeOut("fast");
		
        var check = toplevel_li.find(".creation_checkbox")
        check.data("check", false)
      }
      
      
      // Remove auxiliary data and enable
      var group = input.parents(".tag_content_collapsable");
      $(".autocomplete_extra", group).each(function () {
        $(this).prop('disabled', false);
        $(this).addClass("autocomplete_extra_enabled");
        $(this).val("");
      });
    }
    // Update the data to signal closing
    hidden.data("status", "closes");
  });
	
}