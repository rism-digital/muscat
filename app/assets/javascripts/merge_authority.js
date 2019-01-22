//Custom dialog for merging authorities
var merge = function () {
  $('.muscat_merge').click(function(e){
    var selected = $(".selected");
    if (selected.length != 2){
      alert("Please select exactly 2 authorities");
      return;
    }
    var duplicate = selected.find(".inprogress").parent().parent();
    var target = selected.find(".published").parent().parent();
    if (duplicate.length != 1 || target.length != 1){
      alert("Please select exactly 1 published and 1 unpublished authority");
      return;
    }
    var duplicate_id = duplicate.find(".col-rism_id").text();
    var duplicate_size = duplicate.find(".col-quellen");
    var target_id = target.find(".col-rism_id").text();
    var target_size = target.find(".col-quellen");
    var target_new_size = parseInt(target_size.text()) + parseInt(duplicate_size.text());
    e.stopPropagation();  // prevent Rails UJS click event
    e.preventDefault();
    html = "<form id=\"dialog_confirm\" class=\"active_admin_dialog\" title=\"Merge authorities\">" + 
      "<ul>Should <b>" + duplicate_id + "</b> really be merged into <b>" + target_id +
      "</b>?</ul></form>"
    form = $(html).appendTo('body');
    $('body').trigger('modal_dialog:before_open', [form]);
    return form.dialog({
      modal: true,
      open: function(event, ui) {
        return $('body').trigger('modal_dialog:after_open', [form]);
      },
      dialogClass: 'active_admin_dialog',
      buttons: {
        OK: function() {
          $.ajax({
            type: "GET", 
            url: location.protocol + '//' + location.host + location.pathname + "/merge",
            data: {"target": target_id, "duplicate": duplicate_id},
            dataType: "json",
            success: function(response){
              duplicate_size.html("0");
              target_size.html( target_new_size );
              console.log(response);
            },
            error: function(response){
              console.log("ERROR");
            }
          });
          return $(this).dialog('close');
        },
        Cancel: function() {
          return $(this).dialog('close').remove();
        }
      }
    });
  });
}

$(document).ready(merge);
