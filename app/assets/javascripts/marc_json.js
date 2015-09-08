/* EXAMPLE JSON MARC
{
    "leader":"01471cjm a2200349 a 4500",
    "fields":
    [
        {
            "001":"5674874"
        },
        {
            "035":
            {
                "subfields":
                [
                    {
                        "9":"(DLC)   93707283"
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
*/

function isNumber(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}

// How can not javascript have this??
function zeroPad(n, length) {
    var str = n.toString();
    while (str.length < length)
        str = "0" + str;
    return str;
}

function get_indicator(field) {
	inds = [];
	//field = $('#' + tag + '-' + index + '-indicator');
	
	if (field.length) {
		// split the two char indicator
		inds.push(field.val()[0]);
		inds.push(field.val()[1]);
	}
	
	// return indicator if found or [] if not
	return inds;
}

function add_ordered(tag, marc_tag, json_marc) {
	// add it to the fields array, ordering the fields
	if (json_marc["fields"].length == 0) {
		json_marc["fields"].push(marc_tag);
	} else {
		// This is pretty inefficent, but it is just
		// a very quick'n dirty test
		
		for (var i = 0; i < json_marc["fields"].length; i++) { 
		    field = json_marc["fields"][i];
			
			// Get the key for field			
			for (var field_num in field) break;
			
			// Tag was already populated, but in case it can be
			// extracted from marc_tag
			if (tag < field_num) {
				json_marc["fields"].splice(i, 0, marc_tag);
				break;
			}
			
			if (i == json_marc["fields"].length - 1) {
				json_marc["fields"].push(marc_tag);
				break;
			}
		}
	}
}

function order_subfields(fields) {
	var keys = [];
	var ordered_fields = [];
	
	// convert the keys to array
	for (var key in fields) keys.push(key);
	
	keys.sort(function(a, b) {
		a1 = isNumber(a.split("-")[0]) ? 'z' + a : a;
		b1 = isNumber(b.split("-")[0]) ? 'z' + b : b;
		
		// is there a better way to do this
		// on strings?
		if (a1 > b1)
			return 1;
		if (a1 < b1)
			return -1;
		
		return 0;
	});
	
	// copy to array of hashes for subfields
	for (var i = 0; i < keys.length; i++) { // it seems I cannot iterate on an array?
		key = keys[i];
		f = {};
		// At this point, split the
		// XX-XXXX field and keep
		// only the first part
		key_tag = key.split("-")[0]
		f[key_tag] = fields[key];
		ordered_fields.push(f);
	}
	
	return ordered_fields;
}

function serialize_element( element, tag, json_marc ) {
	//console.log(this);
	
	var subfields = [];
	var controlfield = {};
	var subfields_unordered = {};
	var indicators = [];
	var tag_indexes = {};
	
	// Navigate the single elements in this tag group
	$('.serialize_marc', element).each(function() {
		// X-XXXX or -XXXX
		// in the first case we get two fields
		// in the second one the first is an
		// empty string, for control tags
		// Keep the whole field for sorted duplicates
		field = new String($(this).data("subfield"));
		//index = $(this).data("subfield-iterator");
		if (!tag_indexes.hasOwnProperty(field)) {
			tag_indexes[field] = 0;
		} else {
			tag_indexes[field]++;
		}
		
		// Indicators are special fields that have the
		// data-indicator=true tag
		is_indicator = $(this).data("indicator");

		if ($(this).val() == null || $(this).val() == "") {
			return;
		}
		
		// Check if this is a checkbox and it is checked
		// The value we put into thet marc field correponds
		// to the 'value' of the input. Obviously if it is
		// not checked we do not want to serielize it
		input_type = $(this).attr('type');
		if (input_type != null && input_type == "checkbox") {
			if (!$(this).is(":checked"))
				return;
		}
		
		// Control fields and indicators do not have tags, so we
		// put it into a special container
		if (field == null || field == "" || field == "undefined") {
			// if it has data-indicator parse the indicator
			if (is_indicator == true) {
				indicators = get_indicator($(this));
			} else {
				controlfield[tag] = $(this).val();	
			}
		} else {
			// This is a normal subfield, eg. $a
			// Also replace the newlines if any with spaces
			// it is also doublecheked in the marc_node
			
			// the index has to be zero padded for ordering
			padded_index = zeroPad(tag_indexes[field], 3);
			subfields_unordered[field + "-" +  padded_index] = $(this).val().replace('\n', " ");
		}
		
	});
	
	// Sometimes JavaScript leaves me speachless
	// so JS does not have real hashes, but only
	// objects with properties. This means there
	// is no built in way to count the properties
	// of an object. To see if these two objs
	// have any propertyes, I have to use this
	// trick: get the first element and see if
	// it is null or not. Pretty bruteforce but
	// it seems the accepted way to do this
	for (var f1 in subfields_unordered) break;
	for (var f2 in controlfield) break;
	
	// If both subfields_unordered and controlfield
	// are empty it means the user added to subtags
	// to a tag. Just skip it completely.
	// f1 and f2 come from the above two fors and
	// point to the first property in the object,
	// if it is not empty.
	if (!f1 && !f2) {
		return;
	}
	
	// Place the leader in the correct spot
	if (tag == "000") {
		leader = controlfield["000"];
		json_marc["leader"] = leader;
		// Nothing more to go, go on with the
		// other fields
		return;
	}
	
	subfields = order_subfields(subfields_unordered);
	
	// Build the JSON marc tag
	marc_tag = {};
	// subfields are an array of objects
	if (subfields.length > 0) {
		marc_tag[tag] = {};
		marc_tag[tag]["subfields"] = subfields;
		
		// Pass indicators only if provided by data tag
		// if not passed the backend will fill it
		// with the default value
		if (indicators.length > 0) {
			marc_tag[tag]["ind1"] = indicators[0];
			marc_tag[tag]["ind2"] = indicators[1];
		}
	} else {
		// control fields are only one object/hash
		marc_tag = controlfield;
	}
					
	// Push into the final marc hash
	add_ordered(tag, marc_tag, json_marc);
}


/* Serialize the pe form to marc-json */
function serialize_marc_editor_form( form ) {

	var json_marc = {};
	json_marc["fields"] = [];
	
	// Each group contents contain the <div> for each marc tag
	//$(".marc_editor_group_contents", form).each(function (index, elem) {
		//a =  $(elem).contents();
		
		// only <div> in here, iterathe tru them
		// and skip hidden ones, which have no contents
		// eache of there contains a dt with the
		// contents of each tag, in the correct order
		// and indexed
		$(".tag_group", form).each(function () {
			if ($(this).css("display") == "none") {
				return;
			}
			// Go into the toplevel container dt
			// This way we skip placeholders
			$(".tag_toplevel_container", this).each(function() {
				// each dt contains the inputs related
				// to one marc tag. dt come in the correct order
				// so each time we get a dt we can create a new
				// marc tag
				$('.tag_container', this).each(function() {
					marc_tag = $(this).data("tag");
				
					// Serialize each elem and convert it to json_marc
					// If it is hidden skip it, it is used for
					// new items
					if ($(this).css("display") == "none") {
						return;
					}
				
					serialize_element(this, marc_tag, json_marc);
				
				});
			})
		});
		
		//});
	
	console.log(JSON.stringify(json_marc));
	return json_marc;
	
}
