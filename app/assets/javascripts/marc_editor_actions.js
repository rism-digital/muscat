// --- shared helpers (drop-in) ------------------------------------

function marc_editor_block(sidebarMessage) {
  $('#main_content').block({ message: "" });
  $('#sections_sidebar_section').block({ message: sidebarMessage || "Working..." });
}

function marc_editor_unblock() {
  $('#main_content').unblock();
  $('#sections_sidebar_section').unblock();
}

// Preflight now returns a Promise that resolves to:
//   { ok: true }
//   { ok: false, reason: 'warnings' }
//   { ok: false, reason: 'invalid', form_valid, backend_validation }
function marc_editor_preflight($form) {
  const already_warnings = marc_validate_has_warnings();

  marc_validate_hide_warnings();
  marc_validate_reset_warnings();

  $("#validation_errors").hide();

  const form_valid = $form.valid();

  if (marc_validate_has_warnings()) {
    $("#validation_warnings").show();
    marc_validate_show_warnings();

    // valid + NEW warnings -> stop once to let user review, then resubmit
    if (form_valid && !already_warnings) {
      return Promise.resolve({ ok: false, reason: 'warnings' });
    }
  } else {
    $("#validation_warnings").hide();
  }

  // backend validation is async now
  return marc_editor_validate().then(function (backend_validation) {
    if (!form_valid || !backend_validation) {
      $("#validation_errors").show();
      return { ok: false, reason: 'invalid', form_valid, backend_validation };
    }
    return { ok: true };
  });
}

/**
 * Shared AJAX post:
 * - blocks editor
 * - POSTs JSON response
 * - redirects to response.redirect
 * - always unblocks
 * - allows custom error handler
 */
function marc_editor_post_json(opts) {
  marc_editor_block(opts.busyText);

  return $.ajax({
    url: opts.url,
    type: 'post',
    async: true,
    data: opts.data,
    dataType: 'json',
    timeout: opts.timeout || 20000
  })
  .done(function (data) {
    window.onbeforeunload = null;      // better than false
    window.location.assign(data.redirect);
  })
  .fail(function (jqXHR, textStatus, errorThrown) {
    if (typeof opts.onError === 'function') {
      opts.onError(jqXHR, textStatus, errorThrown);
    } else {
      console.log(jqXHR);
      _generic_editor_alert(opts.errorKey || "marc_editor.error_save", jqXHR.status, textStatus, errorThrown);
    }
  })
  .always(function () {
    marc_editor_unblock();
  });
}

// --- rewritten functions (drop-in) --------------------------------

var savedNr = 0;

function _marc_editor_send_form(form_name, rails_model, redirect) {
  marc_editor_holding_warning();

  savedNr++;
  redirect = redirect || false;

  const $form = $('form', "#" + form_name);

  return marc_editor_preflight($form).then(function (pre) {
    if (!pre.ok) {
      if (pre.reason === 'warnings') return;

      // invalid -> allow superuser override on 2nd+ attempt (same behavior as before)
      const superuser = ($('#user_skip_validation').val() == "True");
      let skip = false;
      if (superuser && savedNr >= 2) {
        skip = confirm("The record does not pass validation, are you sure you want to save it?");
      }
      if (!skip) return;
    }

    const json_marc = serialize_marc_editor_form($form);
    const triggers = marc_editor_get_triggers();
    const url = "/admin/" + rails_model + "/marc_editor_save";

    const req_data = {
      marc: JSON.stringify(json_marc),
      id: $('#id').val(),
      lock_version: $('#lock_version').val(),
      record_type: $('#record_type').val(),
      parent_object_id: $('#parent_object_id').val(),
      parent_object_type: $('#parent_object_type').val(),
      record_status: $('#record_status').val(),
      record_owner: $('#record_owner').val(),
      work_catalogue_status: $('#work_catalogue_status').val(),
      triggers: JSON.stringify(triggers),
      redirect: redirect
    };

    if ($('#record_audit').length) {
      req_data.record_audit = $('#record_audit').val();
    }

    return marc_editor_post_json({
      url: url,
      data: req_data,
      busyText: "Saving...",
      errorKey: "marc_editor.error_save",
      onError: function (jqXHR, textStatus, errorThrown) {
        console.log(jqXHR);

        // GND special-case (unchanged behavior)
        if (jqXHR.responseJSON && jqXHR.responseJSON.gnd_error) {
          alert("There was an error saving to GND (" + jqXHR.responseJSON.gnd_message + ")");

          $('.flashes').empty();
          $('<div/>', {
            "class": 'flash flash_error',
            text: "GND Response: " + jqXHR.responseJSON.gnd_message
          }).appendTo('.flashes');

          return; // unblock handled by .always()
        }

        // Optimistic locking conflict (prefer status 409, keep old fallback)
        if (jqXHR.status === 409 || errorThrown === "Conflict") {
          alert("Error saving page: this is a stale version");

          $('.flashes').empty();
          $('<div/>', {
            "class": 'flash flash_error',
            text: 'This page will not be saved: STALE VERSION. Please reload.'
          }).appendTo('.flashes');

          return;
        }

        _generic_editor_alert("marc_editor.error_save", jqXHR.status, textStatus, errorThrown);
      }
    });
  });
}

/*
function _marc_editor_create_pull_request(form_name, rails_model, redirect) {
  const $form = $('form', "#" + form_name);

  const pre = marc_editor_preflight($form);
  console.log(pre);
  if (!pre.ok) return; // warnings or invalid -> stop

  const json_marc = serialize_marc_editor_form($form);
  const url = "/admin/" + rails_model + "/create_pull_request";

  const req_data = {
    marc: JSON.stringify(json_marc),
    id: $('#id').val()
  };

  return marc_editor_post_json({
    url: url,
    data: req_data,
    busyText: "Pulling...",
    errorKey: "marc_editor.error_save"
  });
}
  */
 function _marc_editor_create_pull_request(form_name, rails_model, redirect) {
  const $form = $('form', "#" + form_name);

  return marc_editor_preflight($form).then(function (pre) {
    if (!pre.ok) return; // warnings or invalid -> stop

    const json_marc = serialize_marc_editor_form($form);
    const url = "/admin/" + rails_model + "/create_pull_request";

    const req_data = {
      marc: JSON.stringify(json_marc),
      id: $('#id').val()
    };

    return marc_editor_post_json({
      url: url,
      data: req_data,
      busyText: "Pulling...",
      errorKey: "marc_editor.error_save"
    });
  });
}

function _marc_editor_validate(source_form, destination, rails_model) {
  const form = $('form', "#" + source_form);
  const json_marc = serialize_marc_editor_form(form);
  const url = "/admin/" + rails_model + "/marc_editor_validate";

  // Prefer a data attr if you can add it; fallback to old parsing
  const currentUser =
    $('#current_user').data('user-id') ||
    ($('#current_user').find('a').attr('href') || '').split("/")[3];

  return $.ajax({
    url: url,
    type: 'post',
    dataType: 'json',
    timeout: 60000,
    async: true, // <-- this is now actually async
    data: {
      marc: JSON.stringify(json_marc),
      marc_editor_dest: destination,
      id: $('#id').val(),
      record_type: $('#record_type').val(),
      current_user: currentUser
    }
  })
  .then(
    function (data) {
      // Update UI as before
      const message_box = $("#marc_errors");
      const message = (data && data["status"]) || "";

      if (message.endsWith("[200]")) {
        message_box
          .html(message)
          .removeClass('flash_error')
          .addClass('flash_notice')
          .css('visibility', 'visible');
        return true;
      } else {
        message_box
          .html(message.replace(/\t/g, "&nbsp;").replace(/\n/g, "<br>"))
          .removeClass('flash_notice')
          .addClass('flash_error')
          .css('visibility', 'visible');
        return false;
      }
    },
    function (jqXHR, textStatus, errorThrown) {
      _generic_editor_alert("marc_editor.error_validation", jqXHR.status, textStatus, errorThrown);
      return false;
    }
  );
}