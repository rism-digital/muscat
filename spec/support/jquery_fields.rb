def set_field(field, value)
  datafield,subfield = field.split("$")

  page.execute_script("$('.validate_#{datafield}_#{subfield}').val('#{value}')")
  selector = "$('*[data-tag=\"#{datafield}\"][data-subfield=\"#{subfield}\"]')"
  page.execute_script("#{selector}.val('#{value}')")
end

def remove_tag(field)
  first(:xpath, "//div[@data-tag='#{field}']//a[@data-header-button='delete']").click
  #Confirm
  first(:xpath, "//div[@class='ui-dialog-buttonset']/button[. = 'OK']").click
end

def open_all_fields
  find_all(:xpath, "//a[@data-header-button='add-from-empty']").each do |e|
    e.click
  end
end
  


