/**
 * Update form following these rules:
 * - if tag is protected: only overwrite when we are on a "new" page
 * - otherwise:
 *   - overwrite existing tag if multiples are not allowed
 *   - append a new tag if multiples are allowed or tag does not exist
 *
 * Refactor notes:
 * - We no longer call marc_json_get_tags(...)
 * - We no longer track Last_tag / index
 * - We pass each field object directly to the called functions
 */
function _marc_editor_update_from_json(data, protected_fields, allow_multiple = false) {
  let fields = data["fields"] || [];
  let is_new_page = $("body").hasClass("new");

  fields.forEach(function(field_data) {
    // Skip malformed entries
    if (!field_data || !field_data.tag) {
      return;
    }

    // Skip empty fields:
    // - empty controlfield => no content
    // - empty datafield => no subfields
    if (_marc_editor_field_is_empty(field_data)) {
      return;
    }

    // Protected fields may only be overwritten on "new"
    if (protected_fields.includes(field_data.tag)) {
      if (is_new_page) {
        _marc_editor_overwrite_tag(field_data);
      }
      return;
    }

    // Non-protected fields:
    // overwrite if a tag already exists and multiples are not allowed,
    // otherwise create a fresh one
    if (_marc_editor_count_tag(field_data.tag) !== 0 && allow_multiple === false) {
      _marc_editor_overwrite_tag(field_data);
    } else {
      _marc_editor_create_new_tag(field_data);
    }
  });
}


/**
 * Leave this function unchanged, per request.
 * It finds matching inputs/selects/etc for a given tag + subfield code.
 */
function _marc_editor_find_tag_element(block, tag, subtag) {
  let filters = [
    ".subfield_entry[data-tag='" + tag + "'][data-subfield='" + subtag + "']",
    "input[data-field='" + tag + "'][data-subfield='" + subtag + "']",
    "input[data-tag='" + tag + "'][data-subfield='" + subtag + "']",
    ".marc_editor_hotkey[data-field='" + tag + "'][data-subfield='" + subtag + "']"
  ].join(",")

  return block.find(filters);
}


/**
 * Helper: decide whether an incoming field has any meaningful content.
 *
 * - controlfield: must have content
 * - datafield: must have at least one subfield
 */
function _marc_editor_field_is_empty(field_data) {
  if (field_data.type === "controlfield") {
    return !field_data.content;
  }

  if (field_data.type === "datafield") {
    return !field_data.subfields || field_data.subfields.length === 0;
  }

  return true;
}


/**
 * Helper: write one value into all matching DOM elements.
 *
 * Why:
 * - some autocomplete widgets have more than one element for the same logical subfield
 * - some inputs also have a sibling .read_only_input mirror that must be kept in sync
 */
function _marc_editor_write_value(target_block, tag, code, raw_value) {
  let value = raw_value === "IMPORT-NEW" ? "" : raw_value;
  let subfields = _marc_editor_find_tag_element(target_block, tag, code);

  subfields.each(function() {
    let subfield = $(this);
    let read_only_input = subfield.siblings(".read_only_input");

    subfield.val(value);
    subfield.css("background-color", "#ffffb3");

    // Special case for mirrored read-only widgets
    if (read_only_input.length) {
      read_only_input.val(value);
      read_only_input.css("background-color", "#ffffb3");
    }
  });
}


/**
 * Overwrite an existing tag block using the incoming MARC field object directly.
 *
 * Refactor notes:
 * - old version expected a flattened object like { a: "...", 2: "WKP" }
 * - new version accepts the real field object
 */
function _marc_editor_overwrite_tag(field_data) {
  let target = field_data.tag;
  let block = $(".marc_editor_tag_block[data-tag='" + target + "']");

  // Controlfields use a synthetic subfield key "value"
  // because the editor lookup function always expects a subfield code.
  if (field_data.type === "controlfield") {
    _marc_editor_write_value(block, target, "value", field_data.content);
    return;
  }

  // Datafields: write each subfield from the incoming MARC field
  (field_data.subfields || []).forEach(function(subfield_data) {
    _marc_editor_write_value(block, target, subfield_data.code, subfield_data.content);
  });
}


/**
 * Normalize an incoming field object into a comparable plain object.
 *
 * Example:
 *   datafield 024 with subfields a=Q1234, 2=WKP
 * becomes:
 *   { a: "Q1234", 2: "WKP" }
 *
 * This is only used for duplicate detection.
 *
 * Important:
 * - if the same subfield code appears multiple times, later values overwrite earlier ones
 * - that matches the old behavior of the codebase
 */
function _marc_editor_normalize_field_data(field_data) {
  let normalized = {};

  if (field_data.type === "controlfield") {
    normalized["value"] = field_data.content === "IMPORT-NEW" ? "" : String(field_data.content || "");
    return normalized;
  }

  (field_data.subfields || []).forEach(function(subfield_data) {
    normalized[subfield_data.code] =
      subfield_data.content === "IMPORT-NEW" ? "" : String(subfield_data.content || "");
  });

  return normalized;
}


/**
 * Read the current values from an already-rendered tag block in the DOM
 * and flatten them into a plain comparable object.
 *
 * This is used to compare an incoming field against existing rendered tags
 * so we can avoid creating exact duplicates.
 */
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

  fields.each(function() {
    let subtag = $(this).attr("data-subfield");

    // Keep first logical field per subtag
    if (!(subtag in extracted)) {
      extracted[subtag] = String($(this).val() || "");
    }
  });

  return extracted;
}


/**
 * Compare two flattened tag-data objects.
 *
 * They are considered identical only if:
 * - they have the exact same set of subfield keys
 * - each key has the exact same value
 *
 * So if one has more/fewer subtags, they are different.
 */
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


/**
 * Check whether the incoming field would be an exact duplicate
 * of an already-rendered tag block.
 *
 * Refactor notes:
 * - old version accepted a flattened object
 * - new version accepts the real field object and normalizes it here
 */
function _marc_editor_has_exact_duplicate_tag(parent_dl, field_data) {
  let tag = field_data.tag;
  let incoming = _marc_editor_normalize_field_data(field_data);
  let existing_blocks = parent_dl.children(".tag_toplevel_container[data-tag='" + tag + "']");

  let found = false;

  existing_blocks.each(function() {
    let existing = _marc_editor_extract_tag_data($(this), tag);

    if (_marc_editor_same_tag_data(existing, incoming)) {
      found = true;
      return false; // break .each()
    }
  });

  return found;
}


/**
 * Create a new rendered tag block from the incoming MARC field object.
 *
 * Refactor notes:
 * - old version expected flattened data
 * - new version accepts the real field object
 * - duplicate detection still happens before cloning/appending
 */
function _marc_editor_create_new_tag(field_data) {
  let target = field_data.tag;
  let field = $(".tag_placeholders[data-tag='" + target + "']");
  let placeholder = field.parents(".tag_group").children(".tag_placeholders_toplevel").children(".tag_placeholders");
  let parent_dl = field.parents(".tag_group").children(".marc_editor_tag_block");

  // Avoid creating exact duplicates
  if (_marc_editor_has_exact_duplicate_tag(parent_dl, field_data)) {
    return;
  }

  let new_dt = placeholder.clone();

  if (field_data.type === "controlfield") {
    _marc_editor_write_value(new_dt, target, "value", field_data.content);
  } else {
    (field_data.subfields || []).forEach(function(subfield_data) {
      _marc_editor_write_value(new_dt, target, subfield_data.code, subfield_data.content);
    });
  }

  new_dt.toggleClass("tag_placeholders tag_toplevel_container");
  parent_dl.append(new_dt);
  new_dt.show();
  new_dt.parents(".tag_group").children(".tag_empty_container").hide();
}


/**
 * Count how many rendered top-level tags for this MARC tag currently exist.
 */
function _marc_editor_count_tag(tag) {
  let fields = $(".tag_toplevel_container[data-tag='" + tag + "']");
  return fields.length;
}


/**
 * Check whether a rendered tag block is empty in the editor.
 *
 * Left mostly unchanged.
 */
function _marc_editor_tag_is_empty(tag) {
  let block = $(".marc_editor_tag_block[data-tag='" + tag + "']");
  let subfields = block.find("input.subfield_entry[data-tag='" + tag + "']");

  for (let i = 0; i < subfields.length; i++) {
    if (subfields[i].value !== "") {
      return false;
    }
  }

  return true;
}