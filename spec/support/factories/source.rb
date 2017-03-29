FactoryGirl.define do
  factory :source do
    record_type 2
    std_title "Il trionfo di Camilla regina de Volsci - Excerpts;..."
    composer "Bononcini, Giovanni"
    title "Non son paga d'esser vaga"
    shelf_mark "Add. 14186"
    language "Unknown"
    lib_siglum "GB-Lbl"
    wf_stage "published"
    #wf_owner 1
    marc_source <<STRING
=001  806154267
=031  #\#$a1$b1$c1$dVivace$gF-4$mbc$o6/8$p{,8A'6DxC8D}{,8A'6DxC8D}/{,8A6bBA8B}{8B6AG8A}/$rd$u32414757
=031  #\#$a1$b1$c2$dVivace$gC-1$mS$o6/8$p=8/'8A{''6DxC8D}'8A''{6DxC8D}/'8A{6bBA8B}8BA-/$rd$tNon son paga d'esser vaga$u32414758
=041  #\#$aita
=100  1\#$aBononcini, Giovanni$d1670-1747$jAscertained$020000426
=240  10$aIl trionfo di Camilla regina de Volsci$kExcerpts$mS, strings, bc$03942594
=245  10$aNon son paga d'esser vaga
=260  #\#$c1700-1800$801
=300  #\#$ascore: f.6v-8v$801
=500  #\#$a[S.l.], [s.n.], 18th century
=500  #\#$aVivace-Ritornello
=593  #\#$aManuscript copy$801
=594  #\#$bS$c1
=594  #\#$bvl$c2
=594  #\#$bvla$c1
=594  #\#$bbc$c1
=650  00$aOperas$025160
=650  00$aArias (voc.)$025224
=700  1\#$aStampiglia, Silvio$d1664-1725$jAscertained$020000669$4lyr
=852  #\#$aGB-Lbl$cAdd. 14186$eThe British Library$x30001581
STRING
  end
end
#=001  806154267\n=031  ##$a1$b1$c1$dVivace$gF-4$mbc$o6/8$p{,8A'6DxC8D}{,8A'6DxC8D}/{,8A6bBA8B}{8B6AG8A}/$rd$u32414757\n=031  ##$a1$b1$c2$dVivace$gC-1$mS$o6/8$p=8/'8A{''6DxC8D}'8A''{6DxC8D}/'8A{6bBA8B}8BA-/$rd$tNon son paga d'esser vaga$u32414758\n=041  ##$aita\n=100  1#$aBononcini, Giovanni$d1670-1747$jAscertained$020000426\n=240  10$aIl trionfo di Camilla regina de Volsci$kExcerpts$mS, strings, bc$03942594\n=245  10$aNon son paga d'esser vaga\n=260  ##$c1700-1800$801\n=300  ##$ascore: f.6v-8v$801\n=500  ##$a[S.l.], [s.n.], 18th century\n=500  ##$aVivace-Ritornello\n=593  ##$aManuscript copy$801\n=594  ##$bS$c1\n=594  ##$bvl$c2\n=594  ##$bvla$c1\n=594  ##$bbc$c1\n=650  00$aOperas$025160\n=650  00$aArias (voc.)$025224\n=700  1#$aStampiglia, Silvio$d1664-1725$jAscertained$020000669$4lyr\n=852  ##$aGB-Lbl$cAdd. 14186$eThe British Library$x30001581\n 
