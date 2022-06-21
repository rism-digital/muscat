var show_gnd_actions = function () {
  var $gnd_table = $("#gnd_table");

  $("#gnd-sidebar").click(function(){
    marc_editor_show_panel("gnd-form");
    $('#gnd-form').children('div.tab_panel').show();
  });

  $gnd_table.on('click', '.data', function() {
    _update_form($(this).data("gnd"));
    marc_editor_show_panel("marc_editor_panel");
  });

  /**
  * Update form following these rules:
  * if tag in protected fields: only update if new
  * else: add other tags (new and append)
  * never update fields if not new
  */
  function _update_form(data){
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
          _update_marc_tag(datafield.tag, marc_json_get_tags(data, datafield.tag)[cnt])
        }
        else{
          continue
        }
        continue
      }
      if (_size_of_marc_tag(datafield.tag) == 0){
        _new_marc_tag(datafield.tag, marc_json_get_tags(data, datafield.tag)[cnt])
      }
      else{
        if (_marc_tag_is_empty(datafield.tag)){
          _update_marc_tag(datafield.tag, marc_json_get_tags(data, datafield.tag)[cnt])
        }
        else{
          _append_marc_tag(datafield.tag, marc_json_get_tags(data, datafield.tag)[cnt])
        }
      }
    }
  }

  function searchGnd(){
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
          drawTable(data);
        }
      });
  }

  $("#gnd_button").click(function(){ 
    searchGnd()
  })

  $('#gnd_input').keydown(function (e) {
    var keyCode = e.keyCode || e.which;
    if (keyCode == 13) { 
      searchGnd()
    }
  });

  function drawTable(data) {
    for (var i = 0; i < data.length; i++) {
      drawRow(data[i]);
    }
  }

  function drawRow(rowData) {
    locale = $gnd_table.attr("locale")
    message = {"de": "übernehmen", "en": "select", "fr": "choisir", "it": "scegliere"}[locale]
    var id = marc_json_get_tags(rowData, "001")[0].content;
    var tag100 = marc_json_get_tags(rowData, "100")[0]
    var tag24 = marc_json_get_tags(rowData, "024")[1]
    var model = $("#marc_editor_panel").attr("data-editor-model");
    var row = $("<tr />")
    $gnd_table.append(row); 
    row.append($("<td><a target=\"_blank\" href=\"https://d-nb.info/gnd/" + id + "\">" + id + "</a></td>"));
    row.append($("<td>" + tag100["a"] + "</td>"));
    row.append($("<td>" + (tag100["t"] ? tag100["t"] : "") + "</td>"));
    row.append( $( "<td>" + ( tag100["m"] ? tag100["m"] : "" ) + "</td>" ) );
    row.append( $( "<td>" + ( tag100["n"] ? tag100["n"] : "" ) + "</td>" ) );
    row.append($("<td>" + (tag100["tp"] ? tag100["p"] : "") + "</td>"));
    row.append( $( "<td>" + ( tag100["r"] ? tag100["r"] : "" ) + "</td>" ) );
    row.append( $( "<td>" + ( ( typeof ( tag24 ) != 'undefined' ) ? tag24["2"] : "" ) + "</td>" ) );
    row.append($('<td><a class="data" id="gnd_data" href="#" data-gnd=\'' + JSON.stringify(rowData) + '\'>' + message  + '</a></td>'));
  }
};

function _update_marc_tag(target, data) {
  block = $(".marc_editor_tag_block[data-tag='" + target + "']")
  var model = $("#marc_editor_panel").attr("data-editor-model");
  for (code in data){
    subfield = block.find(".subfield_entry[data-tag='" + target + "'][data-subfield='" + code + "']").first()
    if (model == "work_nodes" && target == "100" && code == "a") {
      subfield = $("#100a");
    }
    if (model == "work_nodes" && target == "100" && code == "0") {
      subfield = $("input[data-tag='100'][data-subfield='0']");
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

function _append_marc_tag(target, data) {
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

function _size_of_marc_tag(tag){
  fields = $(".tag_toplevel_container[data-tag='"+ tag +"']")
  return fields.length
}

function _marc_tag_is_empty(tag){
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
