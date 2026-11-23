# frozen_string_literal: true

# Run with: bin/rails runner housekeeping/fix_standard_titles_from_tsv.rb
require "csv"
require "set"

class StandardTitleTsvFix
  TSV = Rails.root.join("std_title_fix.tsv")
  ID_TAGS = %w[130 240 490 730].freeze
  REQUIRED_COLUMNS = %w[standard_title_id title new_title muscat_parent_source_id].freeze
  LINK_MODELS = [
    SourceStandardTitleRelation,
    WorkStandardTitleRelation,
    InventoryItemStandardTitleRelation
  ].freeze

  def run
    rows = CSV.read(TSV, headers: true, col_sep: "\t", encoding: "bom|utf-8")
    missing_columns = REQUIRED_COLUMNS - rows.headers
    raise "Missing TSV columns: #{missing_columns.join(', ')}" if missing_columns.any?

    changes = rows.each_with_index.filter_map do |row, index|
      values = row.to_h
      next if values["title"] == values["new_title"]

      {
        line: index + 2,
        old_id: Integer(values.fetch("standard_title_id"), 10),
        old_title: values.fetch("title"),
        new_title: values.fetch("new_title"),
        parent_id: Integer(values.fetch("muscat_parent_source_id"), 10)
      }
    end

    @targets = {}
    @old_ids = changes.map { |row| row[:old_id] }.to_set
    @missing = []
    @updated_sources = 0
    @updated_links = 0
    @updated_texts = 0
    @created_titles = 0
    @reattached_sources = 0
    @detached_by_parent = detached_children(changes.map { |row| row[:parent_id] }.to_set)

    changes.group_by { |row| row[:parent_id] }.each do |parent_id, parent_rows|
      update_children(parent_id, parent_rows)
    end

    deleted = 0
    kept = 0
    @old_ids.each do |id|
      old_title = StandardTitle.find_by(id: id)
      next unless old_title

      if SourceStandardTitleRelation.exists?(standard_title_id: id)
        kept += 1
      elsif old_title.destroy
        deleted += 1
      else
        kept += 1 # Work or inventory links can also prevent deletion.
      end
    end

    puts "Skipped #{rows.size - changes.size} unchanged rows."
    puts "Updated #{@updated_sources} child Sources (#{@updated_links} ID links, #{@updated_texts} title texts; #{@reattached_sources} parent links restored)."
    puts "Created #{@created_titles} StandardTitles; deleted #{deleted} old titles; kept #{kept} still referenced."
    @missing.each { |message| warn message }
    warn "#{@missing.size} TSV rows had no remaining old title reference (some may have been updated by the earlier run)." if @missing.any?
  end

  private

  def detached_children(parent_ids)
    children_by_parent = Hash.new { |hash, id| hash[id] = [] }
    Source.where(source_id: nil).where("marc_source LIKE ?", "%=773%").find_each do |source|
      marc = MarcSource.new(source.marc_source, source.record_type)
      marc.load_source(false)
      raw_parent_id = marc.first_occurance("773", "w")&.raw_content.to_s
      next unless raw_parent_id.match?(/\A\d+\z/)

      parent_id = raw_parent_id.to_i
      children_by_parent[parent_id] << source if parent_ids.include?(parent_id)
    end
    children_by_parent
  end

  def update_children(parent_id, rows)
    ActiveRecord::Base.transaction do
      sources = Source.where(source_id: parent_id).to_a + @detached_by_parent[parent_id]
      children = sources.uniq(&:id).map do |source|
        marc = MarcSource.new(source.marc_source, source.record_type)
        marc.load_source(false)
        {
          source: source,
          marc: marc,
          id_tags: marc.by_tags(ID_TAGS),
          text_fields: marc.by_tags(["031"]).flat_map { |tag| tag.fetch_all_by_tag("t") },
          detached: source.source_id.nil?,
          changed: source.source_id.nil?
        }
      end

      # Find all matches in the original MARC before changing any field. This
      # prevents a replacement title from being matched by another TSV row.
      operations = rows.map do |row|
        hits = children.filter_map do |child|
          id_tags = child[:id_tags].select do |tag|
            tag.fetch_all_by_tag("0").any? { |field| field.raw_content.to_s == row[:old_id].to_s }
          end
          text_fields = child[:text_fields].select { |field| field.raw_content == row[:old_title] }
          [child, id_tags, text_fields] if id_tags.any? || text_fields.any?
        end
        [row, hits]
      end

      operations.each do |row, hits|
        if hits.empty?
          @missing << "Line #{row[:line]}: no remaining reference to StandardTitle #{row[:old_id]} under parent Source #{parent_id}"
          next
        end

        target = target_for(row[:new_title])
        hits.each do |child, id_tags, text_fields|
          id_tags.each do |tag|
            tag.fetch_all_by_tag("0").each do |field|
              next unless field.raw_content.to_s == row[:old_id].to_s

              field.content = target.id.to_s
              @updated_links += 1
            end
            tag.fetch_all_by_tag("a").each { |field| field.content = target.title }
          end
          text_fields.each { |field| field.content = target.title }
          @updated_texts += text_fields.size
          child[:changed] = true
        end
      end

      children.each do |child|
        next unless child[:changed]

        source = child[:source]
        # Source#save! derives composer and parent fields from resolved MARC
        # objects. Resolve after editing so the new title IDs are picked up.
        child[:marc].root.resolve_externals
        source.marc = child[:marc]
        source.save!
        @updated_sources += 1
        @reattached_sources += 1 if child[:detached]
      end
    end
  end

  def target_for(title)
    return @targets[title] if @targets.key?(title)

    matches = StandardTitle.where(title: title).select { |candidate| candidate.title == title }
    if matches.empty?
      target = StandardTitle.create!(title: title, wf_stage: :published)
      @created_titles += 1
    else
      ids = matches.map(&:id)
      link_counts = Hash.new(0)
      LINK_MODELS.each do |model|
        model.where(standard_title_id: ids).group(:standard_title_id).count.each do |id, count|
          link_counts[id] += count
        end
      end
      target = matches.max_by { |candidate| [link_counts[candidate.id], -candidate.id] }
      if matches.size > 1
        puts "#{title.inspect}: using StandardTitle #{target.id} (#{link_counts[target.id]} links)"
      end
    end

    @targets[title] = target
  end
end

StandardTitleTsvFix.new.run
