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
	
	if (value == "") {
		// There are other values in the form
		// it is mandatory that this field is filled
		if (others)
			return false;
		else
			return true;
		// if all the other fields are empty
		// the form will not be serialized
		// so validation should pass
	}
	
	// Value is present
	return true;
}

function marc_validate_retuired_if(value, element, param) {
	var dep_tag = param["tag"];
	var dep_subtag = param["subtag"];
	var valid = true;
	
	// We need at least an occurance of def_tag
	// tag with a valid value. This means we
	// try to get it from the editor and see
	
	var toplevel = $("#marc_editor_panel");
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

function marc_editor_validate_advanced_rule(element_class, rules) {
	for (var rule_name in rules) {
		if (rule_name == "retuired_if") {
			// the dependent rule contains a hash
			// with the tag and subtag
			var rule_contents = rules[rule_name];
			
			for (var tag in rule_contents) {
				$.validator.addClassRules(element_class, { retuired_if: {tag: tag, subtag: rule_contents[tag]} });
			}
			
		} else {
			console.log("Unknown advanced validation type: " + rule_name);
		}
	}
}

function marc_editor_validate_className(tag, subtag) {
	return "validate_" + tag + "_" + subtag;
}

function marc_editor_init_validation(form, validation_conf) {
	
	$(form).validate({
		onfocusout: false,
		onkeyup: false,
		onclick: false,
	});
	
	// Add validator methods
	$.validator.addMethod("presence", marc_validate_presence, "Missing Mandatory Field");
	$.validator.addMethod("retuired_if", marc_validate_retuired_if, 
			$.validator.format("Missing Mandatory Field, because of {0}"));

	for (var key in validation_conf) {
		
		var tag_conf = validation_conf[key]["tags"]
		
		for (var subtag_key in tag_conf) {
			var subtag = tag_conf[subtag_key];
			var element_class = marc_editor_validate_className(key, subtag_key);
			
			if (subtag == "required") {
				// Our own validator is called "presence" to distinguish it
				// from the default "required" validator
				$.validator.addClassRules(element_class, { presence: true });
			} else if (subtag instanceof Object) {
				// More complex dataype
				marc_editor_validate_advanced_rule(element_class, subtag);
			} else {
				console.log("Unknown validation type: " + subtag);
			}
		}
	}
	
}
