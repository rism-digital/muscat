def diffize(id, marc1, marc2)
  
  lines1 = marc1.split("\n")
  lines2 = marc2.split("\n")

  diffs = Diff::LCS.sdiff(lines1, lines2)

  diffs.each do |diff|
  case diff.action
  #when '='
  #  return false
  when '!'
      #puts "Line #{diff.old_position + 1} changed:"
      puts "#{id} ORIG #{diff.old_element}"
      puts "#{id} NEW  #{diff.new_element}"
  when '-'
      # Line was removed
      puts "#{id} REMOVED #{diff.old_position + 1}: #{diff.old_element}"
  when '+'
      # Line was added
      puts "#{id} ADDED   #{diff.new_position + 1}: #{diff.new_element}"
  end
  end

end

model = Work
save = false

model.find_in_batches do |batch|

  batch.each do |w|
    marc1 = w.marc_source
    marc2 = w.marc_source.each_line.uniq.join
    diffize(w.id, marc1, marc2)
    w.marc_source = marc2
    #puts w.marc_source
    w.marc.load_source(false)
    w.marc.import
    w.save if marc1 != marc2 && save
    
  end
end

=begin
=001  26125
=031  ##$a1$b1$c1$dPraeludium. III. [in pencil, by later hand:] BWV 852.$gC-1$mclav$nbBEA$oc$p2-''bD+/6{DCbDE}{DC'BA}2''F+/6{FDEF}{EDC'B}2''A+/6{AFGA}{GFED}2G/$rE|b
=031  ##$a1$b2$c1$gC-1$mclav$nbBEA$oc$p6{'BGFG}{EAGA}8{''C'B}-6{nAF}/8{''ED}4Ct6{'B''FD'B}{A''FD'A}/8{G''AGF}6{ECDE}4F+/$rE|b$zFuga III. â 3.
=040  ##$aDE-633$bger$cDE-633
=100  1#$aBach, Johann Sebastian$d1685-1750$02539
=130  10$aPreludes and Fugues$mclav$03901586
=380  00$aPreludes$025204
=380  00$aFugues (inst.)$025187
=380  00$aKeyboard pieces$03000134
=430  0#$aDas wohltemperierte Klavier$03901587
=430  0#$aThe Well-Tempered Clavier$03943952
=430  0#$aDas wohltemperierte Klavier I$03965815
=430  0#$aThe Well-Tempered Clavier I$04137914
=430  0#$aDas wohltemperierte Klavier$03901587
=430  0#$aThe Well-Tempered Clavier I$04137914
=667  ##$aTitle imported from 702002237
=667  ##$aIncipits imported from 702002237
=690  ##$aBWV$n852$011


=001  26125
=031  ##$a1$b1$c1$dPraeludium. III. [in pencil, by later hand:] BWV 852.$gC-1$mclav$nbBEA$oc$p2-''bD+/6{DCbDE}{DC'BA}2''F+/6{FDEF}{EDC'B}2''A+/6{AFGA}{GFED}2G/$rE|b
=031  ##$a1$b2$c1$gC-1$mclav$nbBEA$oc$p6{'BGFG}{EAGA}8{''C'B}-6{nAF}/8{''ED}4Ct6{'B''FD'B}{A''FD'A}/8{G''AGF}6{ECDE}4F+/$rE|b$zFuga III. â 3.
=040  ##$aDE-633$bger$cDE-633
=100  1#$aBach, Johann Sebastian$d1685-1750$02539
=130  10$aPreludes and Fugues$mclav$03901586
=380  00$aPreludes$025204
=380  00$aFugues (inst.)$025187
=380  00$aKeyboard pieces$03000134
=430  0#$aDas wohltemperierte Klavier$03901587
=430  0#$aThe Well-Tempered Clavier$03943952
=430  0#$aDas wohltemperierte Klavier I$03965815
=430  0#$aThe Well-Tempered Clavier I$04137914
=667  ##$aTitle imported from 702002237
=667  ##$aIncipits imported from 702002237
=690  ##$aBWV$n852$011
=end