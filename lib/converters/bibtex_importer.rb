module Converters
  class BibtexImporter
    
  def self.bibtex2publication(bibtex_string)
      
      type_map = {
        article: "Article/chapter",
        inbook: "Article/chapter",
        book: "Monograph",
      }

      bib = BibTeX.parse(bibtex_string)

      # Only do the first one
      first_b = bib[0]

      return false if !first_b

      new_marc = MarcPublication.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/publication/default.marc")))
      new_marc.load_source false

      new_marc.each_by_tag("041") {|t2| t2.destroy_yourself}
      new_marc.each_by_tag("100") {|t2| t2.destroy_yourself}
      new_marc.each_by_tag("210") {|t2| t2.destroy_yourself}
      new_marc.each_by_tag("240") {|t2| t2.destroy_yourself}
      new_marc.each_by_tag("260") {|t2| t2.destroy_yourself}
      new_marc.each_by_tag("337") {|t2| t2.destroy_yourself}
      new_marc.each_by_tag("650") {|t2| t2.destroy_yourself}
      new_marc.each_by_tag("651") {|t2| t2.destroy_yourself}
      new_marc.each_by_tag("700") {|t2| t2.destroy_yourself}
      new_marc.each_by_tag("760") {|t2| t2.destroy_yourself}

      if first_b[:author]
        first_b.author.each_with_index do |aa, idx|

          p = Person.where(full_name: aa.to_s).first
          id = p ? p&.id&.to_s : "IMPORT-NEW"
          
          if idx == 0
            t = new_marc.insert("100", a: aa.to_s, "0": id)
          else
            t = new_marc.insert("700", a: aa.to_s, "4": "aut", "0": id)
          end

        end
      end

      if first_b[:editor]
        first_b.editor.each_with_index do |aa|

          p = Person.where(full_name: aa.to_s).first
          id = p ? p&.id&.to_s : "IMPORT-NEW"
          
          new_marc.insert("700", a: aa.to_s, "4": "edt", "0": id)
        end
      end

      new_marc.insert("210", a: first_b.key) if first_b.key

      h240 = type_map.fetch(first_b&.type, nil)
      new_marc.insert("240", a: first_b.title, h: h240) if first_b[:title]

      new_marc.insert("260", a: first_b.fetch(:address, ""), b: first_b.fetch(:publisher, ""), c: first_b.fetch(:year, ""))
      new_marc.insert("300", a: first_b.pages) if first_b[:pages]
      new_marc.insert("760", a: first_b.series) if first_b[:series]
      
      new_marc.insert("020", a: first_b.isbn) if first_b[:isbn]
      new_marc.insert("022", a: first_b.issn) if first_b[:issn]
      new_marc.insert("024", a: first_b.ismn) if first_b[:ismn]

      return new_marc.to_marc.force_encoding("UTF-8")
    end

  end
end