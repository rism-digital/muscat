  /**
  * Update form following these rules:
  * if tag in protected fields: only update if new
  * else: add other tags (new and append)
  * never update fields if not new
  */
   function _marc_editor_update_from_json(data, protected_fields) {
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
      if (!($.inArray(datafield.tag, protected_fields))) {
        if (/\/new#$/.test(self.location.href)) {
          _marc_editor_overwrite_tag(datafield.tag, current_json_tag)
        }
      // All the other fields. Is the tag collapsed (no instances of a tag)?
      } else if (_marc_editor_count_tag(datafield.tag) == 0) {
        // Create a new tag from the placeholders
        _marc_editor_create_new_tag(datafield.tag, current_json_tag)
      } else {
        _marc_editor_overwrite_tag(datafield.tag, current_json_tag)
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
  
    return block.find(filters).first();
  }
  
  function _marc_editor_overwrite_tag(target, data) {
    block = $(".marc_editor_tag_block[data-tag='" + target + "']")
    var model = $("#marc_editor_panel").attr("data-editor-model");
  
    for (code in data){
      let subfield = _marc_editor_find_tag_element(block, target, code);
  
      subfield.val(data[code]);
      subfield.css("background-color", "#ffffb3");
    }
  }
  
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
  
  function _marc_editor_create_new_tag(target, data) {
    field = $(".tag_placeholders[data-tag='"+ target +"']")
    placeholder = field.parents(".tag_group").children(".tag_placeholders_toplevel").children(".tag_placeholders")
    parent_dl = field.parents(".tag_group").children(".marc_editor_tag_block");
    new_dt = placeholder.clone();
    for (code in data){
      subfield = _marc_editor_find_tag_element(new_dt, target, code);
      subfield.val(data[code]);
      subfield.css("background-color", "#ffffb3"); 
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