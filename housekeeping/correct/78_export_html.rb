
@item = Work.find(41329)
@item.marc.load_source true
@editor_profile = EditorConfiguration.get_show_layout @item

#ActionView::Base.assign({editor_profile: @editor_profile})
#ApplicationController.render :partial => "marc/show", locals: {:@editor_profile => @editor_profile}

html = ApplicationController.render(:partial => "marc/show", assigns: {:item => @item, :editor_profile => @editor_profile})

File.open("work41329.html", "w") { |file| file.write(html) }