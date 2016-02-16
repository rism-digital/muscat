// This is the simplest validator
// It checks that a value is present
// but only in partially filled forms
function marc_validate_presence(value, element) {
	var others = false;
	
	// havigate up to the <li> and down to the hidden elem
	toplevel = $(element).parents(".tag_toplevel_container");
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

function marc_editor_init_validation(form, validation_conf) {
	
	$(form).validate({
		onfocusout: false,
		onkeyup: false,
		onclick: false,
	});
	
	// Add validator methods
	$.validator.addMethod("Presence", marc_validate_presence, "Missing Mandatory Field");

	for (var key in validation_conf) {
		
		var tag_conf = validation_conf[key]["tags"]
		
		for (var subtag_key in tag_conf) {
			subtag = tag_conf[subtag_key];
			
			element_class = "validate_" + key + "_" + subtag_key;
			
			$.validator.addClassRules(element_class, { Presence: true });
		}
	}
	
}
