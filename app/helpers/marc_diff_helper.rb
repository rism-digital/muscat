module MarcDiffHelper
  def marc_diff_rows(tags, editor_profile)
    tags.flat_map do |aligned_tag|
      tag = aligned_tag.diff&.diff_is_deleted ? aligned_tag.diff : aligned_tag
      leaves = tag.has_children? ? tag.children : [tag]
      leaves.filter_map do |aligned_subfield|
        subfield = aligned_subfield.diff&.diff_is_deleted ? aligned_subfield.diff : aligned_subfield
        deleted = tag.diff_is_deleted || subfield.diff_is_deleted
        old_value = subfield.diff ? subfield.diff.content.to_s : (deleted ? subfield.content.to_s : "")
        new_value = deleted ? "" : subfield.content.to_s
        next if old_value == new_value

        whole_field = !tag.has_children?
        code = whole_field ? tag.tag : "#{tag.tag}$#{subfield.tag}"
        label = if whole_field
          editor_profile.has_label?(tag.tag) ? editor_profile.get_label(tag.tag) : ""
        else
          editor_profile.has_sub_label?(tag.tag, subfield.tag) ? editor_profile.get_sub_label(tag.tag, subfield.tag) : ""
        end
        # Escape values before applying the existing word diff formatter. Only
        # its insertion/deletion markup is trusted HTML.
        html = Differ.diff_by_word(ERB::Util.html_escape(new_value), ERB::Util.html_escape(old_value)).format_as(:html)
        { label: label, code: code, html: html }
      end
    end
  end
end
