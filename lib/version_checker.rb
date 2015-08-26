# -*- coding: utf-8 -*-

require 'needleman_wunsch_aligner'

class MarcAligner < NeedlemanWunschAligner
  
  def get_alignment_score
    row = @score_matrix.length-1
    col = @score_matrix[0].length-1
    length = [row, col].max
    return 100 if length == 0
    @score_matrix.flatten.max / length
  end
  
  def levenshtein_distance(s, t)
    m = s.length
    n = t.length
    return m if n == 0
    return n if m == 0
    d = Array.new(m+1) {Array.new(n+1)}

    (0..m).each {|i| d[i][0] = i}
    (0..n).each {|j| d[0][j] = j}
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                    d[i-1][j-1]       # no operation required
                  else
                    [ d[i-1][j]+1,    # deletion
                      d[i][j-1]+1,    # insertion
                      d[i-1][j-1]+1,  # substitution
                    ].min
                  end
      end
    end
    d[m][n]
  end
  
end

class MarcSubfieldAligner < MarcAligner

  # Get score for alignment pair of paragraphs and sentences. Aligner prioritizes
  def compute_score(left_el, top_el)
    score = 0
    if !left_el || !top_el || !left_el.tag || !top_el.tag
      score += -100
    elsif left_el.tag == top_el.tag
      # Match on tag
      if left_el.content == top_el.content
        score += 100
      else
        length = [left_el.content.length, top_el.content.length].max
        if length == 0 
          score += 100
        else 
          score += 100 / (length) * (length - levenshtein_distance(left_el.content, top_el.content ))
        end
      end
    else 
      score += -100
    end
    score
  end

  def default_gap_penalty
    -50
  end

  def gap_indicator
    MarcNode.new(nil)
  end

end

class MarcFieldAligner < MarcAligner

  # Get score for alignment pair of paragraphs and sentences. Aligner prioritizes
  def compute_score(left_el, top_el)
    score = 0
    if left_el.tag == top_el.tag
        sub_aligner = MarcSubfieldAligner.new( left_el.children, top_el.children )
        sub_aligner.get_optimal_alignment
        score += sub_aligner.get_alignment_score
    else #if [left_el, top_el].any? { |e| :paragraph == e[:type] }
      # Difference in type, one is :paragraph. This is more significant
      # than sentences.
      score += -100
      #else
      #raise "Handle this: #{ [left_el, top_el].inspect }"
    end
    score
  end

  def default_gap_penalty
    -10
  end

  def gap_indicator
    MarcNode.new(nil)
  end

end

module VersionChecker
  
  def self.save_version?(object)
    # first check the last version status
    return true if !object.versions || !object.versions.last || !object.versions.last.whodunnit
    # then check if we have information about who did it
    return true if !object.last_user_save
    # not the same user
    return true if object.versions.last.whodunnit != object.last_user_save
    # otherwise check at the time - wait at least one hour (3600 seconds)
    # we might want to make this configurable
    return true if (Time.now - object.versions.last.created_at.to_time) > 3600
    # else we don't want to save one
    return false
  end
  
  def self.get_modification_with_previous(id)
    version = PaperTrail::Version.find( id )
    return 0 if !version
    item1 = version.reify
    
    item2 = nil
    if !version.next
      item2 = version.item_type.singularize.classify.constantize.find(version.item_id)
    else
      item2 = version.next.reify
    end
    
    return 0 if !item1 || !item2
    
    #s1 = Source.find(id1)
    #marc_a = MarcSource.new(s1.marc_source)
    #marc_a.load_source(false)
    
    #s2 = Source.find(id2)
    #marc_b = MarcSource.new(s2.marc_source)
    #marc_b.load_source(false)
  
    #all_tags_a = marc_a.all_tags.map {|t| t.tag}.uniq
    #all_tags_b = marc_b.all_tags.map {|t| t.tag}.uniq
  
    #puts marc_a.all_tags.size
    #puts marc_b.all_tags.size

    aligner = MarcFieldAligner.new( item1.marc.all_tags, item2.marc.all_tags )
    aligner.get_optimal_alignment
    return aligner.get_alignment_score
    #puts "Similarity: #{aligner.get_alignment_score}%"

    #b0 = a[0].map {|t| t.tag}
    #b1 = a[1].map {|t| t.tag}

    #i=0
    #b0.each do |r|
    #  puts "#{b0[i]} #{b1[i]}"
    #  i += 1
    #end
  end
  
    
end
