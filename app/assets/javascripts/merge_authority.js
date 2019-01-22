//Custom dialog with merge
var merge = function () {
  $('.muscat_merge').click(function(e){
    var selected = $(".selected");
    if (selected.length != 2){
      alert("Please select two records");
      return;
    }
    var duplicate = selected.find(".inprogress").parent().parent()[0];
    var target = selected.find(".published").parent().parent()[0];
    if (typeof duplicate=='undefined' ||typeof target=='undefined'){
      alert("Please select exactly one published and one unpublished record");
      return;
    }
    e.stopPropagation();  // prevent Rails UJS click event
    e.preventDefault();
    html = "<form id=\"dialog_confirm\" class=\"active_admin_dialog\" title=\"Merge authorities\">" + 
      "<ul>Should " + duplicate.id + " really be merged into " + target.id +
      "</ul></form>"
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
          callback($(this).serializeObject());
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
