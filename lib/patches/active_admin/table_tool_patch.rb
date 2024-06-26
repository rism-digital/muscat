module ActiveAdmin
    module Views
        module Pages
  
            class Index < Base
                alias_method :build_table_tools_original, :build_table_tools

                def _muscat_copy_to_clipboard
                    ul do
                        div class: "icon-button" do
                            span :class => "icon-copy copy_to_clipboard", :data => {"clipboard-target": ".index_table"} do
                            end
                            #link_to("Copy table to clipboard", "#", :class => "muscat_icon_link muscat_icon_link_cancel copy_to_clipboard", :data => {"clipboard-target": ".index_table"})
                        end
                    end
                end

                def build_table_tools
                    table class: "muscat_index_header" do
                        tr do
                            td do
                                build_table_tools_original
                            end
                            td do
                                _muscat_copy_to_clipboard
                            end
                        end
                    end    
                end

            end
        end
    end
end
