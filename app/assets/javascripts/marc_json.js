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

function get_indicator(tag, index) {
	inds = [];
	field = $('#' + tag + '-' + index + '-indicator');
	
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
		a1 = isNumber(a) ? 'z' + a : a;
		b1 = isNumber(b) ? 'z' + b : b;
		
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

function serialize_dt_element( dt, json_marc ) {
	//console.log(this);
	
	var subfields = [];
	var controlfield = {};
	var subfields_unordered = {};
	var tag;
	var index;
	
	// Navigate the single emenets in this tag group
	$('.serialize_marc', dt).each(function() {
		parts = $(this).attr("id").split(":");
		
		// skip ac_marc tags only for display (?)
		if (parts[0] != "marc") {
			return;
		}
		
		// should never change! gust repeated many times
		//XXX-XXX
		tag = parts[1].split("-")[0];
		index = parts[1].split("-")[1];
		// X-XXXX or -XXXX
		// in the first case we get two fields
		// in the second one the first is an
		// empty string, for control tags
		// Keep the whole field for sorted duplicates
		field = parts[2];//.split("-")[0];
		// extract the first part to see if control field
		field_tag = parts[2].split("-")[0]

		if ($(this).val() == null || $(this).val() == "") {
			return;
		}
		
		// Control fields do not have tags, so we
		// put it into a special container
		if (field_tag == "") {
			controlfield[tag] = $(this).val();
		} else {
			// This is a norma subfield, eg. $a
			// needs to be done in two steps?
			//f = {};
			///f[field] = $(this).val();

			//subfields.push(f);
			subfields_unordered[field] = $(this).val();
		}
		
	});
	
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
		
		// Pass indicators only if provided by daya
		// if not passed the backend will fill it
		// with the default value
		indicators = get_indicator(tag, index);
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
function serialize_pe_form( form ) {

	var json_marc = {};
	json_marc["fields"] = [];
	
	// Each group contents contain the <div> for each marc tag
	$(".pe_group_contents", form).each(function (index, elem) {
		a =  $(elem).contents();
		
		// only <div> in here, iterathe tru them
		// and skip hidden ones, which have no contents
		// eache of there contains a dt with the
		// contents of each tag, in the correct order
		// and indexed
		$(elem).children().each(function () {
			if ($(this).css("display") == "none") {
				return;
			}			
			//console.log(this);
			
			// each dt contains the inputs related
			// to one marc tag. dt come in the correct order
			// so each time we get a dt we can create a new
			// marc tag
			$('dt', this).each(function() {
				// Serialize each elem and convert it to json_marc
				serialize_dt_element(this, json_marc);
				
			});
			
		});
		
	});
	
	console.log(JSON.stringify(json_marc));
	return json_marc;
	
}
