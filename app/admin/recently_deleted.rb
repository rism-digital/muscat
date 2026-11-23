ActiveAdmin.register_page "Recently Deleted" do
  TYPES = %w[Source Institution Person Place Work WorkNode Holding InventoryItem Publication].freeze
  RANGES = { "day" => 1.day, "week" => 1.week, "month" => 1.month }.freeze

  menu parent: "admin_menu", label: "Recently deleted",
       if: proc { current_user.has_role?(:admin) }

  controller do
    before_action do
      raise CanCan::AccessDenied unless current_user.has_role?(:admin)
    end

    def index
      @range = RANGES.key?(params[:range]) ? params[:range] : "week"
      @type = TYPES.include?(params[:type]) ? params[:type] : "Source"
      @versions = PaperTrail::Version.where(event: "destroy", item_type: @type)
        .where("created_at >= ?", RANGES.fetch(@range).ago)
        .order(created_at: :desc, id: :desc)
        .page(params[:page]).per(25)

      if params[:version_id].present?
        @version = PaperTrail::Version.find_by!(id: params[:version_id], event: "destroy", item_type: TYPES)
        @deleted_item = @version.reify
      end
    end
  end

  content title: "Recently deleted" do
    if controller.instance_variable_get(:@version)
      version = controller.instance_variable_get(:@version)
      item = controller.instance_variable_get(:@deleted_item)

      para do
        link_to "← Back to recently deleted", admin_recently_deleted_path(range: params[:range], type: params[:type])
      end
      panel "#{version.item_type} ##{version.item_id}" do
        attributes_table_for version do
          row("Deleted at") { |v| l(v.created_at, format: :long) }
          row("Deleted by") { |v| v.whodunnit.presence || "System" }
        end
      end

      if item
        panel "Properties" do
          attributes_table_for item do
            item.attributes.except("marc_source").each_key do |key|
              row(key.humanize) { |record| record.attributes[key].to_s }
            end
          end
        end

        panel "MARC21" do
          if item.marc_source.present?
            begin
              marc = item.marc.to_marc_external(
                created_at: item.created_at, updated_at: item.updated_at,
                holdings: false, sanitize: true
              )
            rescue StandardError
              marc = ERB::Util.html_escape(item.marc_source)
            end
            formatted_marc = marc.gsub(/(=\d{3})  /, '<br><span class="marc_tag">\1</span>&nbsp;&nbsp;')
              .gsub(/(\$.)/, '<span class="marc_subfield">\1</span>')
            div class: "marc21" do
              text_node formatted_marc.html_safe
            end
          else
            para "No MARC data was saved in this version."
          end
        end
      else
        para "The saved record could not be reconstructed."
      end
    else
      range = controller.instance_variable_get(:@range)
      type = controller.instance_variable_get(:@type)
      versions = controller.instance_variable_get(:@versions)

      panel "Filters" do
        form action: admin_recently_deleted_path, method: :get do
          label "Deleted within", for: "range"
          select id: "range", name: "range" do
            [["1 day", "day"], ["1 week", "week"], ["1 month", "month"]].each do |label, value|
              option label, value: value, selected: (range == value)
            end
          end
          label "Type", for: "type"
          select id: "type", name: "type" do
            TYPES.each do |name|
              option name.underscore.humanize, value: name, selected: (type == name)
            end
          end
          input type: "submit", value: "Show"
        end
      end

      paginated_collection(versions, download_links: false) do
        table_for collection do
          column("Item") do |version|
            link_to "#{version.item_type} ##{version.item_id}",
              admin_recently_deleted_path(version_id: version.id, range: range, type: type)
          end
          column("Deleted by") { |version| version.whodunnit.presence || "System" }
          column("Deleted at") { |version| l(version.created_at, format: :long) }
        end
      end
    end
  end
end
