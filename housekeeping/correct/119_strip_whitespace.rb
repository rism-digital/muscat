# I'm going to programmer purgatory
if !StandardTitle.respond_to? :referring_relations
  module ThroughAssociations
    extend ActiveSupport::Concern
    class_methods do
      def referring_relations
        StandardTitle.reflect_on_all_associations(:has_many)
        .select { |ref| ref.options[:through].present? }
        .map(&:name).select { |n| n.to_s.include?("referring") }
      end
    end
  
  end
end

cnt = 0
StandardTitle.all.each do |st|
  
  new_title = st.title.strip
  new_notes = st.notes&.strip
  new_at = st.alternate_terms&.strip
  new_topic = st.sub_topic&.strip

  if st.title != new_title || new_notes != st.notes ||
     new_at != st.alternate_terms || new_topic != st.sub_topic
    
    old_title = st.title
    st.title = new_title
    st.notes = new_notes if st.notes 
    st.alternate_terms = new_at if st.alternate_terms
    st.sub_topic = new_topic if st.sub_topic

    

    cnt += 1
    st.save

    StandardTitle.referring_relations.each {|rel| Delayed::Job.enqueue(SaveItemsJob.new(st.id, st.class, rel)) } if old_title != new_title
  end

end

puts "saved #{cnt} titles"

cnt = 0
StandardTerm.all.each do |st|
  
  new_term = st.term.strip
  new_notes = st.notes&.strip
  new_at = st.alternate_terms&.strip
  new_topic = st.sub_topic&.strip

  if st.term != new_term || new_notes != st.notes ||
     new_at != st.alternate_terms || new_topic != st.sub_topic
    
    old_term = st.term

    st.term = new_term
    st.notes = new_notes if st.notes 
    st.alternate_terms = new_at if st.alternate_terms
    st.sub_topic = new_topic if st.sub_topic

    st.save

    cnt += 1
    StandardTerm.referring_relations.each {|rel| Delayed::Job.enqueue(SaveItemsJob.new(st.id, st.class, rel)) } if old_term != new_term
  end

end

puts "saved #{cnt} terms"