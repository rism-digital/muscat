# app/services/wikidata/connector.rb
# Orchestrates fetching and parsing into one hash.
#
# Usage:
#   Wikidata::Connector.get_person("Q1387014")

require_relative "client"
require_relative "parsers/base"
require_relative "parsers/person_core"
require_relative "parsers/date_to_rism"
require_relative "parsers/identifiers"
require_relative "parsers/place_qid"

module Wikidata
  class Connector

  class RecordInRISM < StandardError; end

    def self.get_person(qid, format: :marc, skip_in_rism: false, lang: "en", include_all_place_aliases: false)
      client = Client.new
      #begin
        person_item = client.get_item(qid)
      #rescue
      #end

      core = Parsers::PersonCore.extract(person_item, lang: lang)
      ids  = Parsers::Identifiers.extract(person_item)

      out = core.merge(
        identifiers: ids
      )

      date_hash = Parsers::DateToRism.get_dates(person_item)
      out[:wikidata_dates] = date_hash
      out[:life_dates_100_d] = Parsers::DateToRism.wikidata2rism(date_hash)

      # resolve occupations
      out[:occupations] = resolve_qid_labels(out[:occupation_qids], client: client, lang: lang)

      # Resolve places
      out[:place_of_birth] = resolve_place_hash(out[:place_of_birth_qid], lang: lang) if out[:place_of_birth_qid]
      out[:place_of_death] = resolve_place_hash(out[:place_of_death_qid], lang: lang) if out[:place_of_death_qid]

      out[:residences] = Array(out[:residences_qids]).map do |pqid|
        resolve_place_hash(pqid, lang: lang)
      end

      out[:work_locations] = Array(out[:work_locations_qids]).map do |pqid|
        resolve_place_hash(pqid, lang: lang)
      end

      # resolve the family name
      out[:family_name] = resolve_external_qid(out[:family_name_qid], lang) if out[:family_name_qid]
      out[:given_name] = resolve_external_qid(out[:given_name_qid], lang) if out[:given_name_qid]

      return wikidata2marc(out, format, skip_in_rism)
    end

    def self.wikidata2marc(data, format, skip_in_rism)

      # Make sure this person does not already exist in Muscat
      if data.dig(:identifiers, "rism").present? && skip_in_rism == false
        id = data[:identifiers]["rism"]&.first&.gsub("people/", "")
        pres = Person.where(id: id)
        p = pres.first
        raise(RecordInRISM, "#{p.full_name} (#{p.id})") if p
      end

      new_marc = MarcPerson.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/person/default.marc")))
      new_marc.load_source false

      new_marc.by_tags("100").each {|t2| t2.destroy_yourself}

      if data[:given_name].present? && data[:family_name].present?
        name = "#{data[:family_name]}, #{data[:given_name]}"
      else
        name = data[:label]
      end

      new_marc.add_tag_with_subfields("100", a: name, d: data[:life_dates_100_d])

      if data[:gender]
        new_marc.by_tags("375").each {|t2| t2.destroy_yourself}
        new_marc.add_tag_with_subfields("375", a: data[:gender])
      end

      new_marc.add_tag_with_subfields("024", a: data[:qid], "2": "WKP")

      data[:identifiers].each do |type, ids|
        next if type == "rism" #wha??
        ids.each do |id|
          new_marc.add_tag_with_subfields("024", a: id, "2": type)
        end
      end

      new_marc.by_tags("400").each {|t2| t2.destroy_yourself}  if data[:occupations].any?
      data[:aliases].each do |alternate|
        new_marc.add_tag_with_subfields("400", a: alternate, j: "xx")
      end

      new_marc.by_tags("550").each {|t2| t2.destroy_yourself}  if data[:occupations].any?
      data[:occupations].each do |item|
        new_marc.add_tag_with_subfields("550", a: item[:name]&.titleize)
      end

      if data.dig(:place_of_birth, :name).present?
        new_marc.add_tag_with_subfields("551", a: data.dig(:place_of_birth, :name), "i": "go", "0": find_muscat_place(data[:place_of_birth]))
      end

      if data.dig(:place_of_death, :name).present?
        new_marc.add_tag_with_subfields("551", a: data.dig(:place_of_death, :name), "i": "so", "0": find_muscat_place(data[:place_of_death]))
      end

      ## Create the 678 date
      from = Date.iso8601(data.dig(:wikidata_dates, :date_b)) rescue nil
      to = Date.iso8601(data.dig(:wikidata_dates, :date_d)) rescue nil

      dates = [from&.strftime('%d.%m.%Y'), to&.strftime('%d.%m.%Y')].compact.join('-')
      if from || to
        new_marc.by_tags("678").each {|t2| t2.destroy_yourself}
        new_marc.add_tag_with_subfields("678", a: dates)
      end

      if format == :marc
        return new_marc.to_marc.force_encoding("UTF-8")
      else
        return new_marc.to_json
      end
    end

    def self.find_muscat_place(wikidata_place)
      p = nil
      if wikidata_place.dig(:getty_tgn)
        p = Place.where(tgn_id: wikidata_place.dig(:getty_tgn))
        return p.first.id if p.first
      end

      p = Place.where(name: wikidata_place[:name])
      return p.first.id if p.first
      
      "IMPORT-NEW"
    end

    # --- internal helpers ---

    def self.resolve_external_qid(qid, lang)
      client = Client.new
      item_json = client.get_item(qid)

      return Parsers::Base.label(item_json, lang: lang)
    end

    # Fetch place item, parse base place fields, then enrich with:
    # - resolved country (name)
    def self.resolve_place_hash(place_qid, lang:)
      client = Client.new
      place_item = client.get_item(place_qid)
      place = Parsers::PlaceQid.extract_place(place_item, lang: lang)

      # Country resolution
      if (country_qid = place.delete(:country_qid))
        country_item = client.get_item(country_qid)
        place[:country] = {
          qid: country_qid,
          name: Parsers::Base.label(country_item, lang: lang),
          # Do we need alt spellings for this?
          #aliases_en: Parsers::Base.aliases(country_item, lang: lang)
        }
      end

      place
    rescue => e
      # Don't fail whole person if a single place fails.
      { qid: place_qid, error: e.message }
    end

    # Resolve a list of Q-ids to an array of hashes:
    # [{ qid: "Q36834", name_en: "composer" }, ...]
    def self.resolve_qid_labels(qids, client:, lang:)
      Array(qids).map do |qid|
        item = client.get_item(qid)
        { qid: qid, name: Parsers::Base.label(item, lang: lang) || qid }
      rescue => e
        { qid: qid, error: e.message }
      end
    end

    private_class_method :resolve_qid_labels
    private_class_method :resolve_place_hash

  end
end