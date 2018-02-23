def set_field(field, value)
  datafield,subfield = field.split("$")

  page.execute_script("$('.validate_#{datafield}_#{subfield}').val('#{value}')")
  selector = "$('*[data-tag=\"#{datafield}\"][data-subfield=\"#{subfield}\"]')"
  page.execute_script("#{selector}.val('#{value}')")
end

def remove_field(field)
  datafield,subfield = field.split("$")
  page.execute_script("$('.validate_#{datafield}_#{subfield}').val('')")
  selector = "$('*[data-tag=\"#{datafield}\"][data-subfield=\"#{subfield}\"]')"
  page.execute_script("#{selector}.val('')")
end


def open_all_fields
  find_all(:xpath, "//a[@data-header-button='add-from-empty']").each do |e|
    e.click
  end
end
  


