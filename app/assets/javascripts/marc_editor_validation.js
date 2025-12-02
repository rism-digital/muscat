var warningList = [];
var hasNewWarnings = false;

const SIMPLE_RULE_MAP = {
	"required": { presence: true },
	"mandatory": { mandatory: true },
	"check_group": { check_group: true },
	"validate_588_siglum": { validate_588_siglum: true },
	"validate_edtf": { validate_edtf: true },
	"validate_031_dups": { validate_031_dups: true },
	"validate_url": { validate_url: true },
}

const PARAMETRIC_RULES = [
	"required_if",
	"begins_with",
	"must_contain",
	"gnd_warn_default"
]

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
		var element = warningList[warn];
		_marc_validate_unhighlight(element, "warning", "");
		
		// If the element is a label and a warning label remove it
		if ($(element).next().is("label") && $(element).next().hasClass("warning")) {
			$(element).next().remove();
		}
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
			console.warn("Tried to higlight a hidden object with no autocomplete.")
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
	var menu_item = $('a[data-scroll-target="' + item_name+ '"]');
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
			console.warn("Tried to un-higlight a hidden object with no autocomplete.")
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
	var menu_item = $('a[data-scroll-target="' + item_name+ '"]');
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

function marc_validate_031_duplicates(value, element, param) {
  const $elem = $(element);
  // This is the current 031 that triggered the event
  const $current031 = $elem.closest('.tag_toplevel_container[data-tag="031"]');

  const get = ($scope, sf) =>
    $scope.find(':input[data-tag="031"][data-subfield="' + sf + '"]')
      .first().val()?.toString().trim() || '';

  // Build tuple for the current 031
  const a = get($current031, 'a');
  const b = get($current031, 'b');
  const c = get($current031, 'c');
  const currentTuple = [a, b, c].join('.');

  // Technically this should not happen,
  // since a required_if should be present
  // We don't want to trap this two times
  if (!(a && b && c)) return true;

  // Collect tuples for all *other* 031 blocks
  const otherTuples = $('.tag_toplevel_container[data-tag="031"]').filter(function () {
    return this !== $current031.get(0); // Skip the current one!
  }).map(function () {
    const $scope = $(this);
    const ta = get($scope, 'a');
    const tb = get($scope, 'b');
    const tc = get($scope, 'c');
    return (ta && tb && tc) ? [ta, tb, tc].join('.') : null;
  }).get().filter(Boolean);

  // We will flah THIS 031 as duplicate
  // When the validation gets to the other(s), it will
  // also flag those.
  const isDuplicate = otherTuples.includes(currentTuple);

  return !isDuplicate;
}

function marc_validate_begins_with(value, element, param) {
	if (!value)
		return true;

	return value.startsWith(param);
}

// #1616 implement a pattern matching
function marc_validate_must_contain(value, element, param) {
	if (!value)
		return true;

	return value.includes(param);
}

// This is for GND to altert users if they touch stuff that should not be touched
function marc_validate_gnd_warn_default(value, element, param) {
	if (!value.includes(param)) {
		marc_validate_add_warnings(element);
		return true;
	}
	return true;
}

function marc_validate_edtf(value, element, param) {
	let result = false;
	
	// We can have empty values!
	if (value == null || value === "")
		return true;

	try {
		const p = edtf(value);
		result = true;
	} catch(err) {}

	return result;
}

// Credit: https://uibakery.io/regex-library/url
function marc_validate_url(value, element, param) {
	var httpRegex = /^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.,;~#?&\/=!$'*\[\]]*)$/;

	if (value === "")
		return true;

	return httpRegex.test(value);
}

function marc_validate_588_siglum(value, element, param) {
	const siglumPattern = /\b[A-Z]{1,3}-[\p{L}\p{M}]+(?=\s|$)/gu;
	if (!value)
		return true;

	return siglumPattern.test(value);
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

	if (value.trim() == "") {
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
			if (validate_level == "warning") {
				marc_validate_add_warnings(element);
	    }
		  return true;
		// if all the other fields are empty
		// the form will not be serialized
		// so validation should pass
	}
	
	// Value is present
	return true;
}

// Mandatory fields differ from the "required" as
// the mandatory ones never should be blank; a source
// cannot saved if the field is blank. a "required" field
// in required ONLY IN THE SAME TAG. I.e. if the whole
// TAG is empty it validates, but will not validate if you
// do not fill the required value. Example is 852 institution:
// you cannot insert Ms. No if you do not insert the sigla.
// But if Sigla AND Ms. No are empty, the form is transmitted
// Mandatory ones on the other hand will fail if the whole
// tag is empty: i.e. 650 needs *always* to be there.
function marc_validate_mandatory(value, element) {
	var validate_level = $(element).data("validate-level");

/*
 * This disabled block of code is used to validate
 * mandatory fields only one. Is part of a bigger
 * task to make mandatory fields work with groups
 */
 /*
	var tag = $(element).data("tag");
	var subfield = $(element).data("subfield");

	t = $(".validate_" + tag + "_" + subfield);

	found = false;
	t.each(function() {
		var elem =  $(this);
		console.log(elem.val());
		var placeholders = $(elem).parents(".tag_placeholders");

		if (placeholders.length == 0) {
			if (elem.val() != "") {
				//console.log(elem.val());
				found = true;
			}
		}

		if (found)
			return false;
	});

	if (found)
		return true;
*/

	if (value.trim() == "") {
			if (validate_level == "warning") {
				marc_validate_add_warnings(element);
				return true;
			} else {
				return false;
			}
		}
	
	// Value is present
	return true;
}

function marc_validate_required_if(value, element, param) {
	// Note! We can validaye just one of the required_if fields
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
	var selector;
	if (dep_subtag == "control") {
		selector = '.serialize_marc[data-tag=' + dep_tag + ']';
	} else {
		selector = '.serialize_marc[data-tag=' + dep_tag + '][data-subfield=' + dep_subtag + ']';
	}

	$(selector, toplevel).each(function() {
		if ($(this).val() != "") {
			// The value of the other field is set
			// it makes the validated field mandatory
			if (value.trim() == "")
				valid = false;
		}
	});

	return valid;
}

// #1622, the first group cannot be "Additional printed material"
function marc_validate_check_group(value, element, param) {

	var my_dt = $(element).parents(".inner_group_dt");

	// Are we the first group in the list?
	if ($(my_dt).is('.toplevel_group_dl .inner_group_dt:first-child')) {
		if (value === "Additional printed material")
			return false;
	}

	return true;
}

function marc_validate_new_creation(value, element) {
	if ($(element).data("check") == true) {
		if (element.checked == false) {
			return false;
		}
	}
	return true;
}

function marc_editor_create_parameters(rule_name, rule_contents) {
	// To make life simpler, required_if configuration passes
	// a hash:
	//  required_if:
    //      "031": "a"
	// Versus this mess here for an array with the same stuff:
	//  required_if:
	//       - "031"
	//       - "a"
	// We can make hashes work easily, but then the
	// error message is messed up since the jquery validation
	// plugin is kinda hardcoded to only get an array of parameters
    // So we accept the hash, and then convert it to an array.
	// We also only consider the FIRST pair, so no cheating like
	// this:
	//  required_if:
    //      "031": "a"
	//      "032": "b"
	// It will not work in any case as it needs a different
	// implementation of the validator
    if (rule_contents instanceof Object) {
    	const entries = Object.entries(rule_contents);

        if (entries.length > 0) {
            // Use only the first key-value pair, the others are ignored
            rule_contents = entries[0];
        } else {
			// Let it die if the configuration in wrong+
            throw new Error(`Please check the configuration for rule ${rule_name}`);
        }
    }

	// Return a neat hash
	return { [rule_name]: rule_contents }
}

function marc_editor_parse_any_of_rule(element_class, rule_name, rule_contents) {
	let combined_rule = {};
	for (const sub_rule_id in rule_contents) {
		let sub_rule = rule_contents[sub_rule_id]

		if (SIMPLE_RULE_MAP[sub_rule]) {
			combined_rule = { ...combined_rule, ...SIMPLE_RULE_MAP[sub_rule] };
		} else if (sub_rule instanceof Object) {
			const sub_rule_name = Object.keys(sub_rule)[0];
			const sub_rule_contents = sub_rule[sub_rule_name]; // This is the parameter to the rule
			const rule_def = marc_editor_create_parameters(sub_rule_name, sub_rule_contents)
			combined_rule = { ...combined_rule, ...rule_def };
		} else {
			console.warn(`Unknown sub-rule ${sub_rule} in ${rule_name}`);
		}
	}
	$.validator.addClassRules(element_class, combined_rule);
}

function marc_editor_parse_validation_rule(element_class, rule_name, rule_contents) {
	if (rule_name === "any_of") {
		marc_editor_parse_any_of_rule(element_class, rule_name, rule_contents)
	} else if (PARAMETRIC_RULES.includes(rule_name)) {
		$.validator.addClassRules(element_class, marc_editor_create_parameters(rule_name, rule_contents));
	} else {
		console.warn(`Unknown advanced validation type: ${rule_name}`);
	}
}

function marc_editor_validate_advanced_rule(element_class, rules) {
	for (const rule_name in rules) {
		const rule_contents = rules[rule_name];
		marc_editor_parse_validation_rule(element_class, rule_name, rule_contents);
	}
}

function add_simple_rules(element_class, rule_name) {
	if (SIMPLE_RULE_MAP[rule_name])
		$.validator.addClassRules(element_class, SIMPLE_RULE_MAP[rule_name]);
	else
		console.warn("Unknown rule " + rule_name)
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
			console.warn("Could not find newly created element");
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
		// When a tag is copied, the placeholder is left there
		// So we have these cases:
		// * placeholder for a mandatory tag:
		//   - if a marc_editor_tag_block exists for that tag (somebody filled it in), skip the placeholder
		//   - if no tag exist, run validation on the placeholder and expand it
		// * placeholder for a mandatory tag in a group
		//   in this case see if the mandatory tag in a marc_editor_tag_block exists also in other groups
		//   and run validation on that or expand the placeholder
		ignore: function(index, element) {
			
			// First see if we are in a placeholder for a group
			var group_placeholders = $(element).parents(".group_placeholders");
			if (group_placeholders.length > 0) {
				// the tab_panel contains all the placeholders + the active groups
				var toplevel = $(element).parents(".tab_panel");
				// Navigate all the groups and find a marc_editor_tag_block with our tag
				// There can be more than one, we just need > 0
				var tags = $(".marc_editor_tag_block[data-tag=" + $(element).data("tag") + "]", toplevel).children();

				// One marc_editor_tag_block exists, so do not expand the placeholder to show an error
				if (tags.length > 0)
					return true;
			}

			// Now see if we are in a placeholder block
			var placeholders = $(element).parents(".tag_placeholders");
			// Placeholders are always after the tag we are validating
			// so we can just jump up to the tag group
			var toplevel = $(element).parents(".tag_group");
			// and down to the marc_editor_tag_block as there is only one
			var tags = $(".marc_editor_tag_block", toplevel).children();

			// We are inside a placeholder, and our neigbour tag_group
			// contains a marc_editor_tag_block, we will run validation there
			// and we can skip this placeholder.
			// In case there is only the placeholder if the tag is mandatory
			// the placeholder will be expanded to show a "missing tag" error
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
			
			// Lastly, skip any inputs created by DIVA
			// which is shown in the Holdings editor
			if ($(element).hasClass("diva-input")) {
				return true;
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
	$.validator.addMethod("mandatory", marc_validate_mandatory, I18n.t("validation.missing_message"));
	$.validator.addMethod("required_if", marc_validate_required_if, 
			$.validator.format(I18n.t("validation.required_if_message")));
	$.validator.addMethod("begins_with", marc_validate_begins_with, 
			$.validator.format(I18n.t("validation.begins_with_message")));
	$.validator.addMethod("check_group", marc_validate_check_group,
			$.validator.format(I18n.t("validation.check_group_message")));
	$.validator.addMethod("must_contain", marc_validate_must_contain,
			$.validator.format(I18n.t("validation.must_contain_message")));
	$.validator.addMethod("validate_588_siglum", marc_validate_588_siglum,
			$.validator.format(I18n.t("validation.validate_588_siglum")));
	$.validator.addMethod("validate_edtf", marc_validate_edtf,
			$.validator.format(I18n.t("validation.validate_edtf")));	
	$.validator.addMethod("validate_031_dups", marc_validate_031_duplicates,
			$.validator.format(I18n.t("validation.validate_031_dups")));

	$.validator.addMethod("gnd_warn_default", marc_validate_gnd_warn_default,
			$.validator.format(I18n.t("validation.gnd_warn_default_message")));

	$.validator.addMethod("validate_url", marc_validate_url,
			$.validator.format(I18n.t("validation.validate_url")));

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
				add_simple_rules(element_class, str_parts[0])
			} else if (subtag instanceof Object) {
				// More complex dataype
				marc_editor_validate_advanced_rule(element_class, subtag);
			} else {
				console.warn("Unknown validation type: " + subtag);
			}
		}
	}
	
}
