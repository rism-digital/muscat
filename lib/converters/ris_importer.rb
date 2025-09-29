module Converters
  class RisImporter
    def self.ris2publication(ris_string)
      
      type_map = {
        CHAP: "Article/chapter",
        JOUR: "Article/chapter",
        BOOK: "Monograph",
      }


      ris = RISParser::parse(ris_string)&.first

      return false if !ris

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
      

      authors = ris['AU'].reject(&:nil?).map(&:strip).reject(&:empty?)
      editors = ris['A2'].reject(&:nil?).map(&:strip).reject(&:empty?)

      authors.each_with_index do |aa, idx|

        p = Person.where(full_name: aa.to_s).first
        id = p ? p&.id&.to_s : "IMPORT-NEW"
        
        if idx == 0
          t = new_marc.insert("100", a: aa.to_s, "0": id)
        else
          t = new_marc.insert("700", a: aa.to_s, "4": "aut", "0": id)
        end

      end

      editors.each_with_index do |aa|

        p = Person.where(full_name: aa.to_s).first
        id = p ? p&.id&.to_s : "IMPORT-NEW"
        
        new_marc.insert("700", a: aa.to_s, "4": "edt", "0": id)
      end

      titles = ris['TI'].reject(&:nil?).map(&:strip).reject(&:empty?)
      type = ris['TY'].reject(&:nil?).map(&:strip).reject(&:empty?).first

      add_titles = []
      titles.each_with_index do |tit, idx|
        if idx == 0
          new_marc.insert("240", a: tit, h: type_map[type&.to_sym])
        else
          add_titles << tit
        end
      end

      # All the additional titles
      add_titles += ris['T1'].reject(&:nil?).map(&:strip).reject(&:empty?)
      add_titles += ris['T3'].reject(&:nil?).map(&:strip).reject(&:empty?)
      add_titles += ris['BT'].reject(&:nil?).map(&:strip).reject(&:empty?)

      add_tag = new_marc.insert("730", a: add_titles.shift)
      add_titles.each do |t|
        add_tag.add_at(MarcNode.new(@model, "a", t, nil))
      end

      pub = ris['PB'].reject(&:nil?).map(&:strip).reject(&:empty?)&.first
      year = ris['PY'].reject(&:nil?).map(&:strip).reject(&:empty?)&.first
      place = ris['CY'].reject(&:nil?).map(&:strip).reject(&:empty?)&.first
      
      new_marc.insert("260", a: place, b: pub, c: year)

      extent = ris['NV'].reject(&:nil?).map(&:strip).reject(&:empty?)&.first
      new_marc.insert("300", a: extent) if extent

      urls = ris['UR'].reject(&:nil?).map(&:strip).reject(&:empty?)
      urls.each do |url|
        new_marc.insert("856", u: url, z: "Electronic resource")
      end

      links = ris['LK'].reject(&:nil?).map(&:strip).reject(&:empty?)
      links.each do |url|
        new_marc.insert("856", u: url, z: "Electronic resource")
      end

      serials = ris['SN'].reject(&:nil?).map(&:strip).reject(&:empty?)
      serials.each do |serial|
        
        serial.split(";").each do |s|

          if s&.strip&.gsub(/[^\dXx]/, '').length >= 10
            new_marc.insert("020", a: s&.strip)
          elsif s&.strip&.gsub(/[^\dXx]/, '').length == 8
            new_marc.insert("022", a: s&.strip)
          else
            # just make an isbn
            new_marc.insert("020", a: s&.strip)
          end
        end

      end

      return new_marc.to_marc

    end
  end

  class RISParser
  def self.parse(io)
    records = []
    current = Hash.new { |h, k| h[k] = [] }

    io.each_line do |line|
      line = line&.rstrip
      next if line.nil? || line.empty?

      if line =~ /\AER\s+-/ # EOR
        records << current
        current = Hash.new { |h, k| h[k] = [] }
        next
      end

      if (m = line.match(/\A([A-Z0-9]{2})\s*-\s*(.*)\z/))
        tag = m[1]
        val = m[2]&.strip
        current[tag] << val
      else
        last_tag = current.keys.last
        current[last_tag] << line.strip if last_tag
      end
    end

    records << current unless current.empty?
    records
  end
end
end
