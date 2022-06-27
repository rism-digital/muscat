var show_gnd_actions = function () {
  var $gnd_table = $("#gnd_table");

  $("#gnd-sidebar").click(function(){
    marc_editor_show_panel("gnd-form");
    $('#gnd-form').children('div.tab_panel').show();
  });

  $gnd_table.on('click', '.data', function() {
    _update_form_gnd($(this).data("gnd"));
    marc_editor_show_panel("marc_editor_panel");
  });

  /**
  * Update form following these rules:
  * if tag in protected fields: only update if new
  * else: add other tags (new and append)
  * never update fields if not new
  */
  function _update_form_gnd(data){
    protected_fields = ['100']
    tags = data["fields"]
    tag = ""
    cnt = 0
    for(t=0; t < tags.length; t++){
      datafield = tags[t]
      if(datafield.tag != tag){
        cnt = 0
        tag = datafield.tag
      }
      else{
        cnt++
      }
      if (!($.inArray(datafield.tag, protected_fields))){
        if (/\/new#$/.test(self.location.href)){
          _update_marc_tag_gnd(datafield.tag, marc_json_get_tags(data, datafield.tag)[cnt])
        }
        else{
          continue
        }
        continue
      }
      if (_size_of_marc_tag_gnd(datafield.tag) == 0){
        _new_marc_tag(datafield.tag, marc_json_get_tags(data, datafield.tag)[cnt])
      }
      else{
        if (_marc_tag_is_empty_gnd(datafield.tag)){
          _update_marc_tag_gnd(datafield.tag, marc_json_get_tags(data, datafield.tag)[cnt])
        }
        else{
          _append_marc_tag_gnd(datafield.tag, marc_json_get_tags(data, datafield.tag)[cnt])
        }
      }
    }
  }

  function search_gnd() {
    $gnd_table.html("");
    var term = $("#gnd_input").val();
    var model = $("#marc_editor_panel").attr("data-editor-model");
      $.ajax({
        type: "GET",
        url: "/admin/"+model+"/gnd.json?gnd_input="+term,
        beforeSend: function() { 
          $('#loader').show();
        },
        complete: function(){
          $('#loader').hide();
        },
        error: function(jqXHR, textStatus, errorThrown) {
          alert(jqXHR.responseText);
        },
        success: function(data){
          var result = (JSON.stringify(data));
          draw_table_gnd(data);
        }
      });
  }

  $("#gnd_button").click(function(){ 
    search_gnd()
  })

  $('#gnd_input').keydown(function (e) {
    var keyCode = e.keyCode || e.which;
    if (keyCode == 13) { 
      search_gnd()
    }
  });

  function draw_table_gnd(data) {
    for (var i = 0; i < data.length; i++) {
      draw_row_gnd(data[i]);
    }
  }

  function draw_row_gnd( rowData )
  {

    var label = rowData["label"];
    var link = rowData["link"];
    var description = rowData["description"];
    var marcData = rowData["marc"];

    locale = $gnd_table.attr( "locale" )
    message = I18n.t("select")

    var row = $( "<tr>" );
    row.append( $( "<td><a target=\"_blank\" href=\"" + link + "\">" + label + "</a></td>" ) );
    for(let i = 0; i < description.length; i++) row.append($("<td>" + description[i] + "</td>"));
    row.append( $( '<td><a class="data" id="gnd_data" href="#" data-gnd=\'' + JSON.stringify( marcData ) + '\'>' + message + '</a></td>' ) );
    row.append( $( "<tr>" ) );
    $gnd_table.append(row); 
  }
};

function _update_marc_tag_gnd(target, data) {
  block = $(".marc_editor_tag_block[data-tag='" + target + "']")
  var model = $("#marc_editor_panel").attr("data-editor-model");
  console.log(data, target)
  for (code in data){
    subfield = block.find(".subfield_entry[data-tag='" + target + "'][data-subfield='" + code + "']").first()
    if (model == "work_nodes" && target == "100" && code == "a") {
      subfield = block.find("input[data-field='" + target + "'][data-subfield='" + code + "']").first()
    }
    subfield.val(data[code]);
    subfield.css("background-color", "#ffffb3");
  }
}

function _new_marc_tag(target, data) {
  field = $(".tag_placeholders[data-tag='"+ target +"']")
  placeholder = field.parents(".tag_group").children(".tag_placeholders_toplevel").children(".tag_placeholders")
  parent_dl = field.parents(".tag_group").children(".marc_editor_tag_block");
  new_dt = placeholder.clone();
  for (code in data){
    subfield = new_dt.find(".subfield_entry[data-tag='" + target + "'][data-subfield='" + code + "'],.serialize_marc[data-tag='" + target + "'][data-subfield='" + code + "'], .marc_editor_hotkey[data-field='" + target + "'][data-subfield='" + code + "']").first()
    subfield.val(data[code]);
    subfield.css("background-color", "#ffffb3"); 
  }
  new_dt.toggleClass('tag_placeholders tag_toplevel_container');
  parent_dl.append(new_dt);
  new_dt.show();
  new_dt.parents(".tag_group").children(".tag_empty_container").hide();
}

function _append_marc_tag_gnd(target, data) {
  block = $(".marc_editor_tag_block[data-tag='" + target + "']")
  placeholder = block.parents(".tag_group").children(".tag_placeholders_toplevel").children(".tag_placeholders");
  new_dt = placeholder.clone()
  for (code in data){
    subfield = new_dt.find(".subfield_entry[data-tag='" + target + "'][data-subfield='" + code + "'],.serialize_marc[data-tag='" + target + "'][data-subfield='" + code + "'], .marc_editor_hotkey[data-field='" + target + "'][data-subfield='" + code + "']").first()
    subfield.val(data[code]);
    subfield.css("background-color", "#ffffb3");
  }
  new_dt.toggleClass('tag_placeholders tag_toplevel_container');
  block.append(new_dt)
  new_dt.show()
}

function _size_of_marc_tag_gnd(tag){
  fields = $(".tag_toplevel_container[data-tag='"+ tag +"']")
  return fields.length
}

function _marc_tag_is_empty_gnd(tag){
  block = $(".marc_editor_tag_block[data-tag='" + tag + "']")
  subfields = block.find("input.subfield_entry[data-tag='" + tag + "']")
  for (var i = 0; i < subfields.length; i++){
    if (subfields[i].value!=""){
      return false
    }
  }
  return true
}

$(document).ready(show_gnd_actions);
