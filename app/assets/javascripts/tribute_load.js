/*
 Use the tribute module to display a menu when you write @
 in the comment box. Needs to be bound to the comment box id
 https://github.com/zurb/tribute
*/

var tribute_load = function () {

  if ($("#active_admin_comment_body").length == 0) {
    // Nope, this page does not have a comment box
    return;
  }
  
  var tribute = new Tribute({
    lookup: 'name',
    fillAttr: 'id',
    
    values: function (text, cb) {
      $.ajax({
        success: function(data) {
          //console.log(data);
          cb(data);
        },
        dataType: 'json',
        timeout: 20000,
        type: 'post',
        url: "/admin/users/list"
      });
    }
  })
	
  tribute.attach($("#active_admin_comment_body"));

};

$(document).ready(tribute_load);
// Fix for turbolinks: it will not call againg document.ready
$(document).on('page:load', tribute_load);
