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

function marc_editor_init_validation(form, validation_conf) {
	
	$(form).validate({
		// disable automagic callbacks for now
		onfocusout: false,
		onkeyup: false,
		onclick: false,
		ignore: false,
		highlight: function( element, errorClass, validClass ) {
			if ( element.type === "radio" ) {
				this.findByName( element.name ).addClass( errorClass ).removeClass( validClass );
			} else if ( element.type === "hidden" ) {
				// Alert! an autocomplete?
				
				// havigate up to the <li> and down to the autocomplete elem
				toplevel_li = $(element).parents("li");
				ac = $("input[data-autocomplete]", toplevel_li);
				
				if (ac) {
					ac.addClass( errorClass ).removeClass( validClass );
				} else {
					console.log("Tried to higlight a hidden object with no autocomplete.")
				}
				
			} else {
				$( element ).addClass( errorClass ).removeClass( validClass );
			}
		},
		unhighlight: function( element, errorClass, validClass ) {
			if ( element.type === "radio" ) {
				this.findByName( element.name ).removeClass( errorClass ).addClass( validClass );
			} else if ( element.type === "hidden" ) {
				// Alert! an autocomplete?
				
				// havigate up to the <li> and down to the autocomplete elem
				toplevel_li = $(element).parents("li");
				ac = $("input[data-autocomplete]", toplevel_li);
				
				if (ac) {
					ac.removeClass( errorClass ).addClass( validClass );
				} else {
					console.log("Tried to un-higlight a hidden object with no autocomplete.")
				}
				
			} else {
				$( element ).removeClass( errorClass ).addClass( validClass );
			}
		}
	});
	
	// Add validator methods
	$.validator.addMethod("presence", marc_validate_presence, "Missing Mandatory Field");
	$.validator.addMethod("required_if", marc_validate_required_if, 
			$.validator.format("Missing Mandatory Field, because field {0} ${1} is present"));

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
