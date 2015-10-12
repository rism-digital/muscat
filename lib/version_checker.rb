require 'needleman_wunsch_aligner'

# A base class for defining a set of new methods
class MarcAligner < NeedlemanWunschAligner
  
  # A method returning a normalized similarity measurement (0-100) of the best alignment
  def get_alignment_score
    row = @score_matrix.length-1
    col = @score_matrix[0].length-1
    length = [row, col].max
    return 100 if length == 0
    @score_matrix.flatten.max / length
  end
  
  # A method for computing the distance of two strings with low memory footprint
  # Unused
  def levenshtein_distance_low_memory(s1, s2)
    s1len = s1.length;
    s2len = s2.length;
    return s2len if s1len == 0
    return s1line if s2len == 0
    column = Array.new(s1len+1)
  
    for y in 1..s1len
      column[y] = y;
    end
    for x in 1..s2len
      column[0] = x;
      lastdiag = x-1
      for y in 1..s1len
        olddiag = column[y]
        column[y] = min3(column[y] + 1, column[y-1] + 1, lastdiag + (s1[y-1] == s2[x-1] ? 0 : 1));
        lastdiag = olddiag;
      end
    end
    puts column[s1len]
    return(column[s1len]);
  end
  
  # A method for computing the distance of two strings
  # Unused
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
    puts d[m][n]
    d[m][n]
  end
  
  private
  
  def min3(a, b, c)
    ((a) < (b) ? ((a) < (c) ? (a) : (c)) : ((b) < (c) ? (b) : (c)))
  end
  
end

class MarcSubfieldAligner < MarcAligner

  # Get score for the alignment of two MarcNode (field)
  # Aligns the subfields of the to fields
  # For matching subfield.tag compute the levenshtein distance if not identical
  def compute_score(left_el, top_el)
    score = 0
    if !left_el || !top_el || !left_el.tag || !top_el.tag
      score += -100
    elsif left_el.tag == top_el.tag
      # Match on tag
      if left_el.content == top_el.content
        score += 100
      # Make sure we are comparing strings
      elsif !left_el.content.is_a?(String) || !top_el.content.is_a?(String)
        score += 100
      else    
        length = [left_el.content.length, top_el.content.length].max
        if length == 0 
          score += 100
        else 
          #score += 100 / (length) * (length - levenshtein_distance_low_memory(left_el.content, top_el.content ))
          score += 50
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

  # Get score for the alignment of two MarcNote (root)
  # Aligns the fields of the root (record)
  # For matching field.tag get the score from a MarcSubfieldAligner
  def compute_score(left_el, top_el)
    score = 0
    if left_el.tag == top_el.tag
        sub_aligner = MarcSubfieldAligner.new( left_el.children, top_el.children )
        sub_aligner.get_optimal_alignment
        score += sub_aligner.get_alignment_score
    else
      score += -100
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
    # first check the timeout value is 0, which means version for any same
    return true if RISM::VERSION_TIMEOUT == 0
    # then check the last version status
    return true if !object.versions || !object.versions.last || !object.versions.last.whodunnit || !object.versions.last.event
    # then check if we have information about who did it
    return true if !object.last_user_save
    # not the same user
    return true if object.versions.last.whodunnit != object.last_user_save
    # then check if we have information about the event
    return true if !object.last_event_save
    # note the same event
    return true if object.versions.last.event != object.last_event_save
    # we do not timeout versioning for the same user if timeout value is -1
    return false if RISM::VERSION_TIMEOUT == -1
    # otherwise check at the time
    return true if (Time.now - object.versions.last.created_at.to_time) > RISM::VERSION_TIMEOUT
    # else we don't want to save one now
    return false
  end
  
  def self.get_similarity_with_next(id)
    item1, item2 = get_item_and_next(id)
    return 0 if !item1 || !item2

    aligner = MarcFieldAligner.new( item1.marc.all_tags(false), item2.marc.all_tags(false) )
    aligner.get_optimal_alignment
    return aligner.get_alignment_score
  end
  
  def self.get_diff_with_next(id)
    item1, item2 = get_item_and_next(id)
    return nil if !item1 || !item2
  
    aligner = MarcFieldAligner.new( item1.marc.all_tags(false), item2.marc.all_tags(false) )
    alignment = aligner.get_optimal_alignment
    tags = set_tag_diff(alignment[0], alignment[1])
    # sub alignment
    tags.each do |t|
      # insertion or deletion, no need to compare
      next if !t.diff || t.diff.diff_is_deleted
      
      sub_aligner = MarcSubfieldAligner.new( t.diff.all_children, t.all_children )
      sub_alignment = sub_aligner.get_optimal_alignment
      subfields = set_tag_diff(sub_alignment[0], sub_alignment[1])
      
      # replace all the children with the aligned version
      t.children.clear
      subfields.each{ |st| t.children << st }  
    end
  end
  
  private
  
  # A private methdo the reify an object and its next version
  # If the version is the last one, the next one it the current version
  def self.get_item_and_next(id)
    version = PaperTrail::Version.find( id )
    return [nil, nil] if !version
    item1 = version.reify
    
    item2 = nil
    # The version is the last one
    if !version.next
      item2 = version.item_type.singularize.classify.constantize.find(version.item_id)
    else
      item2 = version.next.reify
    end
    
    [item1, item2]
  end
  
  def self.set_tag_diff(tag_list1, tag_list2)
    return tag_list1 if (tag_list1.size != tag_list2.size) 
  
    i=0
    for i in 0..tag_list1.size - 1
      if tag_list2[i] && tag_list2[i].tag
        # set it only if we have a tag in the aligned version (otherwise this is an insertion)
        tag_list2[i].diff = tag_list1[i] if tag_list1[i] && tag_list1[i].tag
      else
        # this is deletion - special case where we create an empty node with the deletion as diff (marked as such)
        tag_list2[i] = MarcNode.new(nil, tag_list1[i].tag)
        tag_list1[i].diff_is_deleted = true
        tag_list2[i].diff = tag_list1[i]
      end
    end    
    tag_list2
  end
  
end
