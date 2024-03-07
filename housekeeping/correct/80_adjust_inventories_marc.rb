count = 0

Source.where('id > 1001274011').find_in_batches do |batch|
  
  batch.each do |s|

    s.marc.load_source false

    s.marc.by_tags("003").each {|t| t.destroy_yourself}

    # prevent Marc import conlicts
    s.marc.each_by_tag('650') do |t|
      t.fetch_all_by_tag('0').each {|t2| t2.destroy_yourself}
    end

    s.marc.each_by_tag('852') do |t|
      t.fetch_all_by_tag('0').each {|t2| t2.destroy_yourself}
    end

    s.marc.import
    s.save

    count += 1
  end

end

ap 'Saved ' + count.to_s + ' Sources'



# all = []
# #pb = ProgressBar.new(Source.all.count)
# Source.find_in_batches do |batch|

#   batch.each do |s|
		
#     s.marc.load_source false # non carica i collegamenti esterni

    
#     # distruggi tag di un certo tipo
#     # s.marc.by_tags("856").each {|t2| t2.destroy_yourself}

#     s.marc.each_by_tag("700") do |t|
#       tgs = t.fetch_all_by_tag("4")
#       puts "700\t#{s.id}\t#{tgs.count}\t#{tgs}" if tgs.count > 1
#     end

#     s.marc.each_by_tag("710") do |t|
#       tgs = t.fetch_all_by_tag("4")
#       puts "710\t#{s.id}\t#{tgs.count}\t#{tgs}" if tgs.count > 1
#     end


#     # modificare contenuto sotto tag
#     s.marc.each_by_tag("710") do |t|
#       tgs = t.fetch_all_by_tag("4") # array di sottotag
      
#       tgs.first.content # leggo
#       tgs.first.content = 'value' # scrivo
#     end


#     #pb.increment!

#     # salvare la source (senza pippe)
#     #s.suppress_reindex
#     #s.suppress_recreate
#     #s.suppress_update_77x
#     #s.save

#   end

# end

# #puts all.sort.uniq




# # istanzio le definizioni dei tag
# mc = MarcConfigCache.get_configuration("source")

# # aggiungo un tag
# w774 = MarcNode.new("source", "774", "", mc.get_default_indicator("774"))

# # aggiungo sottotag
# w774.add_at(MarcNode.new("source", "w", id.to_s, nil), 0 )

# # ordino alfabeticamente i sottotag
# w774.sort_alphabetically

# # aggiungere il tag al MARC
# parent_manuscript.marc.root.add_at(w774, parent_manuscript.marc.get_insert_position("774") )