  /**
  * Update form following these rules:
  * if tag in protected fields: only update if new
  * else: add other tags (new and append)
  * never update fields if not new
  */
   function _marc_editor_update_from_json(data, protected_fields, allow_multiple = false) {
    let tags = data["fields"];
    let Last_tag = "";
    let index = 0;

    for (t = 0; t < tags.length; t++) {
      datafield = tags[t];

      if (datafield.tag != Last_tag) {
        index = 0
        Last_tag = datafield.tag
      } else {
        index++;
      }

      let current_json_tag = marc_json_get_tags(data, datafield.tag)[index];

      // "protected" fields are the fields that can be overwritten
      // only when creating a record (i.e 100)
      if (protected_fields.includes(datafield.tag)) {
        if (/\/new#$/.test(self.location.href)) {
          _marc_editor_overwrite_tag(datafield.tag, current_json_tag)
        }
      // All the other fields. Is the tag collapsed (no instances of a tag)?
      // If there is already a field overwrite it
      // RZ DO NOT OVERWRITE TAGS ALWAYS APPEND A FRESH ONE
      //} else if (_marc_editor_count_tag(datafield.tag) != 0 && allow_multiple == false) {
        // _marc_editor_overwrite_tag(datafield.tag, current_json_tag)
      } else {
        // if we allow multiples, then we can append the fields
        _marc_editor_create_new_tag(datafield.tag, current_json_tag)
      }
    }
  }

  function _marc_editor_find_tag_element(block, tag, subtag) {
    let filters = [
      ".subfield_entry[data-tag='" + tag + "'][data-subfield='" + subtag + "']",
      "input[data-field='" + tag + "'][data-subfield='" + subtag + "']",
      "input[data-tag='" + tag + "'][data-subfield='" + subtag + "']",
      ".marc_editor_hotkey[data-field='" + tag + "'][data-subfield='" + subtag + "']"
    ].join(",")
  
    return block.find(filters);
  }
  
  // Do we need this?
  function _marc_editor_overwrite_tag(target, data) {
    block = $(".marc_editor_tag_block[data-tag='" + target + "']")
    var model = $("#marc_editor_panel").attr("data-editor-model");
  
    for (code in data){
      let subfield = _marc_editor_find_tag_element(block, target, code).first();
  
      var read_only_input = subfield.siblings('.read_only_input');

      subfield.val(data[code]);
      subfield.css("background-color", "#ffffb3");

      // Special case for read-only values, used for GND stuff
      if (read_only_input.length) {
        read_only_input.val(data[code]);
        read_only_input.css("background-color", "#ffffb3");
      }

    }
  }
  
/* is this ever used??
  function _marc_editor_append_tag(target, data) {
    block = $(".marc_editor_tag_block[data-tag='" + target + "']")
    placeholder = block.parents(".tag_group").children(".tag_placeholders_toplevel").children(".tag_placeholders");
    new_dt = placeholder.clone()
    for (code in data){
      subfield = _marc_editor_find_tag_element(new_dt, target, code);
      
      subfield.val(data[code]);
      subfield.css("background-color", "#ffffb3");
    }
    new_dt.toggleClass('tag_placeholders tag_toplevel_container');
    block.append(new_dt)
    new_dt.show()
  }
  */

  // All this mess is so we can avoid duplicates
  function _marc_editor_normalize_tag_data(data) {
    let normalized = {};

    for (const code in data) {
      normalized[code] = (data[code] === "IMPORT-NEW" ? "" : String(data[code]));
    }

    return normalized;
  }
  
  function _marc_editor_extract_tag_data(block, tag) {
    let extracted = {};

    let fields = block.find([
      ".marc_editor_hotkey[data-field='" + tag + "'][data-subfield]",
      ".marc_editor_hotkey[data-tag='" + tag + "'][data-subfield]",
      "input.subfield_entry[data-tag='" + tag + "'][data-subfield]",
      "input[type='text'][data-field='" + tag + "'][data-subfield]",
      "input[type='text'][data-tag='" + tag + "'][data-subfield]",
      "select[data-field='" + tag + "'][data-subfield]",
      "select[data-tag='" + tag + "'][data-subfield]",
      "textarea[data-field='" + tag + "'][data-subfield]",
      "textarea[data-tag='" + tag + "'][data-subfield]"
    ].join(","));

    fields.each(function () {
      let subtag = $(this).attr("data-subfield");

      // keep first logical field per subtag
      if (!(subtag in extracted)) {
        extracted[subtag] = String($(this).val() || "");
      }
    });

    return extracted;
  }

  function _marc_editor_same_tag_data(a, b) {
    let a_keys = Object.keys(a).sort();
    let b_keys = Object.keys(b).sort();

    if (a_keys.length !== b_keys.length) return false;

    for (let i = 0; i < a_keys.length; i++) {
      if (a_keys[i] !== b_keys[i]) return false;
      if (a[a_keys[i]] !== b[b_keys[i]]) return false;
    }

    return true;
  }

  function _marc_editor_has_exact_duplicate_tag(parent_dl, tag, data) {
    let incoming = _marc_editor_normalize_tag_data(data);
    let existing_blocks = parent_dl.children(".tag_toplevel_container[data-tag='" + tag + "']");

    let found = false;

    existing_blocks.each(function () {
      let existing = _marc_editor_extract_tag_data($(this), tag);

      if (_marc_editor_same_tag_data(existing, incoming)) {
        found = true;
        return false; // break .each()
      }
    });

    return found;
  }
  // end of all the mess to avoid duplicates


  function _marc_editor_create_new_tag(target, data) {
    field = $(".tag_placeholders[data-tag='"+ target +"']")
    placeholder = field.parents(".tag_group").children(".tag_placeholders_toplevel").children(".tag_placeholders")
    parent_dl = field.parents(".tag_group").children(".marc_editor_tag_block");
    
    if (_marc_editor_has_exact_duplicate_tag(parent_dl, target, data)) {
      return;
    }

    new_dt = placeholder.clone();
    for (code in data){
      subfields = _marc_editor_find_tag_element(new_dt, target, code);
      // In some autocompletes we have two fields with the same subfield
      subfields.each(function () {
        var value = data[code] === "IMPORT-NEW" ? "" : data[code];
        $(this).val(value);
        $(this).css("background-color", "#ffffb3");
      });
    }
    new_dt.toggleClass('tag_placeholders tag_toplevel_container');
    parent_dl.append(new_dt);
    new_dt.show();
    new_dt.parents(".tag_group").children(".tag_empty_container").hide();
  }
  
  
  
  function _marc_editor_count_tag(tag) {
    fields = $(".tag_toplevel_container[data-tag='" + tag + "']")
    return fields.length
  }
  
  function _marc_editor_tag_is_empty(tag) {
    block = $(".marc_editor_tag_block[data-tag='" + tag + "']")
    subfields = block.find("input.subfield_entry[data-tag='" + tag + "']")
    for (var i = 0; i < subfields.length; i++) {
      if (subfields[i].value != "") {
        return false
      }
    }
    return true
  }