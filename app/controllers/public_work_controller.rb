include Triggers
require 'sunspot_extensions.rb'
require 'will_paginate'
class PublicWorkController < ApplicationController
  include BlacklightRangeLimit::ControllerOverride
  include BlacklightAdvancedSearch::Controller
  include Blacklight::Catalog

  DEFAULT_FACET_LIMIT = 20

  def show
    input_id = params[:id]
    begin
      @item = @work = Work.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_root_path, :flash => {:error => "#{I18n.t(:error_not_found)} (Work #{params[:id]})"}
      return
    end
    @editor_profile = EditorConfiguration.get_show_layout @work
    # @prev_item, @next_item, @prev_page, @next_page = Work.near_items_as_ransack(params, @work)
    # @prev_item, @next_item, @prev_page, @next_page = Work.near_items_as_ransack(params, @work)
    @works = Work.where(wf_stage: 1).order('title ASC')
    puts "Works"
    all_works = []
    @works.each do |each_work|
      all_works << each_work.id;
    end

    work_index = all_works.find_index(input_id.to_i).to_i

    if all_works[work_index+1].nil?
      @next_item = nil
    else
      @next_item = all_works[work_index+1]
    end
    if all_works[work_index-1].nil?
      @prev_item = nil
    else
      if work_index == 0
        @prev_item = nil
      else
        @prev_item = all_works[work_index-1]
      end
    end

    puts "Work index"
    puts work_index
    puts "Prev Page"
    puts @prev_item
    puts "Next Page"
    puts @next_item


    @jobs = @work.delayed_jobs
    @is_selection_mode = false;

    @query = "select * from sources_to_works where work_id=" + @work.id.to_s;
    @all_works = Work.find_by_sql(@query);

    @all_sources = []
    @all_works.each do |each_work|
      @sources_dict = {};
      each_source = Source.find(each_work.source_id);
      @sources_dict['id'] = each_source.id;
      @sources_dict['composer'] = each_source.composer;
      @sources_dict['std_title'] = each_source.std_title;
      @sources_dict['title'] = each_source.title;
      @sources_dict['lib_siglum'] = each_source.lib_siglum;
      @sources_dict['shelf_mark'] = each_source.shelf_mark;
      @all_sources << @sources_dict;
    end

  end

  def index
    @count = 0
    @results, @hits = Work.ransack(params[:q])
    @results_count = Work.where(wf_stage: 1).count
    @works = Work.where(wf_stage: 1).order('title ASC').paginate(:page => params[:page], :per_page => 30)
    @total_on_this_page =  @works.total_count

    if params[:page]
      @page_number = params[:page]
    else
      @page_number = 1
    end
    @starting_document_number = ((@page_number.to_i-1) * 30) + 1
    @ending_document_number  = @starting_document_number + @total_on_this_page -1

    @no_of_sources = {}

    @works.each_with_index do |each_work, i|
      @query = "select count(*) from sources_to_works where work_id = '" + each_work.id.to_s + "'";
      @sources_count = Work.count_by_sql(@query);
      @no_of_sources[each_work.id.to_i] = @sources_count;
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @works }
      format.json { render json: @starting_document_number }
      format.json { render json: @ending_document_number }
      format.js
    end
  end
end
