var warningList = [];
var hasNewWarnings = false;

function marc_validate_has_warnings() {
	return hasNewWarnings;
}

function marc_validate_reset_warnings() {
	warningList = [];
	hasNewWarnings = false;
}

function marc_validate_force_evaluate_warnings() {
	hasNewWarnings = false;
}

function marc_validate_add_warnings(element) {
	hasNewWarnings = true;
	warningList.push(element);
}

function marc_validate_hide_warnings() {
	for (var warn in warningList) {
		_marc_validate_unhighlight(warningList[warn], "warning", "nice");
	}
}

function marc_validate_show_warnings() {
	for (var warn in warningList) {
		var element = warningList[warn];
		_marc_validate_highlight(element, "warning", "");
		
		var label = $( "<label>" )
		.attr( "id", element.name + "-warning" )
		.addClass("warning")
		.html(I18n.t("validation.warning_message"));
		
		label.insertAfter( element );
	}
}

function _marc_validate_highlight( element, errorClass, validClass ) {
	
	// See if this is in a placeholder.
	// If it is, create a new tag and add the error
	// to that tag, not the hidden placelohder
	element = marc_editor_validate_expand_placeholder(element);
	
	if ( element.type === "radio" ) {
		this.findByName( element.name ).addClass( errorClass ).removeClass( validClass );
	} else if ( element.type === "hidden" ) {
		// Alert! an autocomplete?
		
		// havigate up to the <li> and down to the autocomplete elem
		var toplevel_li = $(element).parents("li");
		var ac = $("input[data-autocomplete]", toplevel_li);
		
		if (ac) {
			ac.addClass( errorClass ).removeClass( validClass );
		} else {
			console.log("Tried to higlight a hidden object with no autocomplete.")
		}
	} else if ( element.type === "checkbox" ) {
		var label = $("#" + element.name + "-label");
		label.addClass(errorClass).removeClass( validClass );
	} else {
		$( element ).addClass( errorClass ).removeClass( validClass );
	}
	
	// Open up the group if it was collapsed
	var group = $(element).parents(".tag_content_collapsable");
	if ($(group).css("display") == "none") {
		var toplevel = $(element).parents(".tag_container");
		var button = $("a[data-header-button='toggle']", toplevel);
		tag_header_toggle($(button));
	}
	
	// Highlight the group in the sidebar
	var panel = $(element).parents(".tab_panel");
	var item_name = panel.attr("name");
	var menu_item = $("a[data-scroll-target=" + item_name+ "]");
	menu_item.addClass(errorClass);
	
	// Keep a reference of the error'd items
	// in the sidebar element. We use this to
	// unhighlight it after
	var errors = menu_item.data("error-counter");
	if (errors == undefined) {
		errors = [];
	}
	
	if ($.inArray(element.name, errors) == -1)
		errors.push(element.name);
	
	menu_item.data("error-counter", errors);
}

function _marc_validate_unhighlight( element, errorClass, validClass ) {
	if ( element.type === "radio" ) {
		this.findByName( element.name ).removeClass( errorClass ).addClass( validClass );
	} else if ( element.type === "hidden" ) {
		// Alert! an autocomplete?
		
		// havigate up to the <li> and down to the autocomplete elem
		var toplevel_li = $(element).parents("li");
		var ac = $("input[data-autocomplete]", toplevel_li);
		
		if (ac) {
			ac.removeClass( errorClass ).addClass( validClass );
		} else {
			console.log("Tried to un-higlight a hidden object with no autocomplete.")
		}
	} else if ( element.type === "checkbox" ) {
		var label = $("#" + element.name + "-label");
		label.addClass(validClass).removeClass( errorClass );
	} else {
		
		$( element ).removeClass( errorClass ).addClass( validClass );
	}

	// unHighlight the group in the sidebar
	// The sidebar element contains a data elem
	// with a list of the items with errors in that
	// group. If the items are validated and valid
	// we remove them from this list. When no
	// items remain, we can remove the error
	// class from the sidebar group
	var panel = $(element).parents(".tab_panel");
	var item_name = panel.attr("name");
	var menu_item = $("a[data-scroll-target=" + item_name+ "]");
	var errors = menu_item.data("error-counter");
	if (errors != undefined) {
		
		if (!$(element).hasClass(errorClass) && $.inArray(element.name, errors) >= 0) {
			errors.splice( $.inArray(element.name, errors), 1 );
			menu_item.data("error-counter", errors);
		}
		
		if (errors.length == 0)
			menu_item.removeClass(errorClass);
	}
}

// This is the simplest validator
// It checks that a value is present
// but only in partially filled forms
function marc_validate_presence(value, element) {
	var others = false;
		
	// havigate up to the <li> and down to the hidden elem
	var toplevel = $(element).parents(".tag_toplevel_container");
	$('.serialize_marc', toplevel).each(function() {
		if ($(this).val()) {
			others = true;
		}
	});
	
	var validate_level = $(element).data("validate-level");
	
	if (value == "") {
		// There are other values in the form
		// it is mandatory that this field is filled
		if (others) {
			if (validate_level == "warning") {
				marc_validate_add_warnings(element);
				return true;
			}
			return false;
		}
		else
			return true;
		// if all the other fields are empty
		// the form will not be serialized
		// so validation should pass
	}
	
	// Value is present
	return true;
}

function marc_validate_required_if(value, element, param) {
	var dep_tag = param[0];
	var dep_subtag = param[1];
	var valid = true;
	var tag = $(element).data("tag");
	var toplevel;
	
	// We need at least an occurance of def_tag
	// tag with a valid value. This means we
	// try to get it from the editor and see
	
	// There is a catch: if it is the same tag
	// as us, search inside this tag, else
	// find the first one in the whole tree
	if (tag == dep_tag) {
		toplevel = $(element).parents(".tag_toplevel_container");
	} else {
		toplevel = $("#marc_editor_panel");
	}
	
	// .serialize_marc selects all fields,
	// even if they are in a placeholder.
	// This permits us to show the missing fields
	// in hidden tags that are entirely missing
	// from the editing page at the moment of
	// verification.
	$('.serialize_marc[data-tag=' + dep_tag + '][data-subfield=' + dep_subtag + ']', toplevel).each(function() {
		if ($(this).val() != "") {
			// The value of the other field is set
			// it makes the validated field mandatory
			if (value == "")
				valid = false;
		}
	});

	return valid;
}

function marc_validate_new_creation(value, element) {
	if ($(element).data("check") == true) {
		if (element.checked == false) {
			return false;
		}
	}
	return true;
}

function marc_editor_validate_advanced_rule(element_class, rules) {
	for (var rule_name in rules) {
		if (rule_name == "required_if") {
			// the dependent rule contains a hash
			// with the tag and subtag
			var rule_contents = rules[rule_name];
			
			for (var tag in rule_contents) {
				$.validator.addClassRules(element_class, { required_if: [ tag, rule_contents[tag]] });
			}
			
		} else {
			console.log("Unknown advanced validation type: " + rule_name);
		}
	}
}

function marc_editor_validate_className(tag, subtag) {
	return "validate_" + tag + "_" + subtag;
}

function marc_editor_validate_expand_placeholder(element) {
	// Are we in a placeholder?	
	var placeholders = $(element).parents(".tag_placeholders");
	
	var toplevel = $(element).parents(".tag_group");
	var tags = $(".marc_editor_tag_block", toplevel).children();
	
	// We are in a placeholder and there are no shown tags
	if (placeholders.length > 0 && tags.length == 0) {
		new_dt = tag_header_add_from_empty($(element));
		
		new_elements = $("[data-subfield=" + $(element).data("subfield") + "]", new_dt);

		if (new_elements.length > 0) {
			return new_elements[0];
		} else {
			console.log("Could not find newly created element");
			return element;
		}
		
	} else {
		return element;
	}
}

function marc_editor_init_validation(form, validation_conf) {
	
	$(form).validate({
		// disable automagic callbacks for now
		onfocusout: false,
		onkeyup: false,
		onclick: false,
		// Skip validation in placeholders
		// ONLY if there are shown tags
		ignore: function(index, element) {
			var placeholders = $(element).parents(".tag_placeholders");
	
			var toplevel = $(element).parents(".tag_group");
			var tags = $(".marc_editor_tag_block", toplevel).children();
			
			// Was found in a placeholder, but regular tags
			// are already there, skip
			if (placeholders.length > 0 && tags.length > 0) {
				return true;
			}
			
			// Other case: in tags that can be edited or new
			// we have a duplicate entry that is not shown
			// a .tag_containter data-function [new, edit]
			// if we are in such container and hidden, skip
			var containers = $(element).parents(".tag_container");
			if (containers.length > 0) {
				var cont = containers[0];
				if ($(cont).data("function") != undefined) {
					if ($(cont).css('display') == "none") {
						console.log("Skip hidden element with data-function " + $(cont).data("function"));
						return true;
					}

				}
			}
			
			return false;
		},
		highlight: function( element, errorClass, validClass ) {
			_marc_validate_highlight(element, errorClass, validClass);
		},
		unhighlight: function( element, errorClass, validClass ) {
			_marc_validate_unhighlight(element, errorClass, validClass);
		},
		errorPlacement: function(error, element) {
			// Autocomplete: if the input is a hidden type
			if (element.is(':input') && element.prop("type") == "hidden") {
				// Show the message under the textbox
				// in autocompletes it is always after the hidden field
				error.insertAfter( element.next() );
			} else {
				error.insertAfter( element );
			}
		}
	});
	
	// Add validator methods
	$.validator.addMethod("presence", marc_validate_presence, I18n.t("validation.missing_message"));
	$.validator.addMethod("required_if", marc_validate_required_if, 
			$.validator.format("Missing Mandatory Field, because field {0} ${1} is present"));

	// New creation: this is not configurable, it is used to make sure the
	// "confirm create new" checkbox is selected for new items
	$.validator.addMethod("new_creation", marc_validate_new_creation, "");
	$.validator.addClassRules("creation_checkbox", { new_creation: true });

	for (var key in validation_conf) {
		
		var tag_conf = validation_conf[key]["tags"]
		
		for (var subtag_key in tag_conf) {
			var subtag = tag_conf[subtag_key];
			var element_class = marc_editor_validate_className(key, subtag_key);
			
			if (typeof subtag === "string") {
				var str_parts = subtag.split(",");
				// by convention: required, warning
				// the rule name is always the first
				var rule_name = str_parts[0];
				if (rule_name == "required") {
					// Our own validator is called "presence" to distinguish it
					// from the default "required" validator
					$.validator.addClassRules(element_class, { presence: true });
				}
			} else if (subtag instanceof Object) {
				// More complex dataype
				marc_editor_validate_advanced_rule(element_class, subtag);
			} else {
				console.log("Unknown validation type: " + subtag);
			}
		}
	}
	
}
