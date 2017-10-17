rel = %w{
pbl
fmo
dpt
dte
scr
prf
prt
edt
asn
oth
}

@editor_profile = EditorConfiguration.get_show_layout Source.first

rel.sort.each do |a|
	puts "#{a} | " + @editor_profile.get_label(a)
end