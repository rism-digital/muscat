function marc_editor_config(panel_name) {
  const $root = $("#" + panel_name);
  const raw = $root.attr("data-marc-config");

  if (!raw) throw new Error("Missing data-marc-config on #" + panel_name);

  // Cache parsed config on the element so you don't JSON.parse repeatedly
  let cfg = $root.data("marcConfigParsed");
  if (!cfg) {
    cfg = JSON.parse(raw);
    $root.data("marcConfigParsed", cfg);
  }
  return cfg;
}

// --- shared helpers

function marc_editor_block(sidebarMessage) {
  $('#main_content').block({ message: "" });
  $('#sections_sidebar_section').block({ message: sidebarMessage || "Working..." });
}

function marc_editor_unblock() {
  $('#main_content').unblock();
  $('#sections_sidebar_section').unblock();
}

function marc_editor_ask_pr_message_dialog(opts) {
  opts = opts || {};
  const title = opts.title || "Create Pull Request";
  const label = opts.label || "Message";
  const initial = opts.initial || "";

  return new Promise((resolve) => {
    const id = "pr_message_dialog_runtime";
    let $dlg = $("#" + id);

    // Create/inject once (or recreate if you prefer)
    if (!$dlg.length) {
      $dlg = $(`
        <div id="${id}" style="display:none;">
          <label for="${id}_text" style="display:block; margin-bottom:6px;">${label}</label>
          <textarea id="${id}_text" rows="6" style="width:100%; box-sizing:border-box;"></textarea>
        </div>
      `).appendTo("body");
    }

    const $txt = $("#" + id + "_text");
    $txt.val(initial);

    $dlg.dialog({
      modal: true,
      title: title,
      width: 520,
      closeOnEscape: true,
      buttons: {
        "Create PR": function () {
          const msg = ($txt.val() || "").trim();
          if (!msg) {
            alert("Message required");
            return;
          }
          $(this).dialog("close");
          resolve(msg);
        },
        Cancel: function () {
          $(this).dialog("close");
          resolve(null);
        },

      },
      open: function () {
        // focus textarea when dialog opens
        setTimeout(() => $txt.trigger("focus"), 0);
      },
      close: function () {
        // Destroy the jQuery UI wrapper & remove DOM node (clean!)
        $dlg.dialog("destroy");
        $dlg.remove();
      }
    });
  });
}


// Returns a Promise that resolves to:
//   { ok: true }
//   { ok: false, reason: 'warnings' }
//   { ok: false, reason: 'invalid', form_valid, backend_validation }
function marc_editor_validate_form($form) {
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

function _marc_editor_send_form(panel_name, rails_model, redirect) {
  marc_editor_holding_warning();

  savedNr++;
  redirect = redirect || false;

  const $form = $('form', "#" + panel_name);
  const cfg = marc_editor_config(panel_name);

  console.log(cfg)

  return marc_editor_validate_form($form).then(function (pre) {
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
      url: cfg.endpoints.save,
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

function _marc_editor_create_pull_request(panel_name, rails_model, redirect) {
  const $form = $('form', "#" + panel_name);
  const cfg = marc_editor_config(panel_name);

  return marc_editor_validate_form($form).then(function (pre) {
    if (!pre.ok) return; // warnings or invalid -> stop

    // IMPORTANT: return this promise so the outer chain waits for it
    return marc_editor_ask_pr_message_dialog({ title: "Pull request message" })
      .then(function (message) {
        if (message === null)
          return;

        message = (message || "").trim();
        if (!message) { 
          alert("Message required"); 
          return; 
        }

        const json_marc = serialize_marc_editor_form($form);

        const req_data = {
          marc: JSON.stringify(json_marc),
          id: $('#id').val(),
          message: message,
        };

        return marc_editor_post_json({
          url: cfg.endpoints.pr,
          data: req_data,
          busyText: "Pulling...",
          errorKey: "marc_editor.error_save"
        });
      });
  });
}


function _marc_editor_validate(source_form, destination, rails_model) {
  const form = $('form', "#" + source_form);
  const json_marc = serialize_marc_editor_form(form);

  const cfg = marc_editor_config(source_form);

  return $.ajax({
    url: cfg.endpoints.validate,
    type: 'post',
    dataType: 'json',
    timeout: 60000,
    async: true, // <-- this is now actually async
    data: {
      marc: JSON.stringify(json_marc),
      marc_editor_dest: destination,
      id: $('#id').val(),
      record_type: $('#record_type').val(),
      current_user: cfg.currentUserId
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

function _marc_editor_preview( source_form, destination, rails_model ) {
	var form = $('form', "#" + source_form);
	var json_marc = serialize_marc_editor_form(form);
	
	const cfg = marc_editor_config(source_form)
	
	$.ajax({
		success: function(data) {
			marc_editor_show_panel(destination);
		},
		data: {
			marc: JSON.stringify(json_marc), 
			marc_editor_dest: destination, 
			id: $('#id').val()
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: cfg.endpoints.preview, 
		error: function (jqXHR, textStatus, errorThrown) {
			_generic_editor_alert("marc_editor.error_preview", jqXHR.status, textStatus, errorThrown)
		}
	});
}

function _marc_editor_help( destination, help, title ) {

	var url = "/admin/editor_help_box/" + help

	$.ajax({
		success: function(data) {
			$('#' + destination).html(data)
			marc_editor_show_panel(destination);
		},
		data: {
			title: title,
		},
		dataType: 'html',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			_generic_editor_alert("marc_editor.error_help", jqXHR.status, textStatus, errorThrown)
		}
	});
}

function _marc_editor_version_view( version_id, destination, rails_model ) {	
	const cfg = marc_editor_config("marc_editor_panel");
	$("#" + destination).block({message: ""});
	
	$.ajax({
		success: function(data) {
			//marc_editor_show_panel(destination);
			$("#" + destination).unblock();
		},
		data: {
			marc_editor_dest: destination, 
			version_id: version_id
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: cfg.endpoints.version, 
		error: function (jqXHR, textStatus, errorThrown) {
			_generic_editor_alert("marc_editor.error_version", jqXHR.status, textStatus, errorThrown)
		}
	});
}

function _marc_editor_embedded_holding(destination, rails_model, id ) {	
	url = "/admin/holdings/render_embedded";
	
	$.ajax({
		success: function(data) {
		},
		data: {
			marc_editor_dest: destination,
			object_id: id,
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			_generic_editor_alert("marc_editor.error_holding", jqXHR.status, textStatus, errorThrown)
		}
	});
}

function _marc_editor_summary_view(destination, rails_model, id ) {	
	const cfg = marc_editor_config("marc_editor_panel");
	
	$.ajax({
		success: function(data) {
		},
		data: {
			marc_editor_dest: destination,
			object_id: id
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: cfg.endpoints.summary, 
		error: function (jqXHR, textStatus, errorThrown) {
			_generic_editor_alert("marc_editor.error_summary", jqXHR.status, textStatus, errorThrown)
		}
	});
}

function _marc_editor_version_diff( version_id, destination, rails_model ) {	
	const cfg = marc_editor_config("marc_editor_panel");
	$("#" + destination).block({message: ""});
	
	$.ajax({
		success: function(data) {
			//marc_editor_show_panel(destination);
			$("#" + destination).unblock();
            $(".subfield_diff_content").each(function() {
		        $(this).html( diffString( $(this).children('.diff_old').html(), $(this).children('.diff_new').html() ) );
	        });
            $('#marc_editor_historic_view .panel').each(function(){
                if($(this).find(".version_diff").length == 0){
                    $(this).hide();
                }
            });
            
            
		},
		data: {
			marc_editor_dest: destination, 
			version_id: version_id
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: cfg.endpoints.diff, 
		error: function (jqXHR, textStatus, errorThrown) {
			_generic_editor_alert("marc_editor.error_diff", jqXHR.status, textStatus, errorThrown)
		}
	});
}