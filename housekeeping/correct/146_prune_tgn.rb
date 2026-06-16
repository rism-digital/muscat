def delete_024_tgn(marc)
  marc["024"].each do |t|
    if t["2"]&.first&.content == "TGN"
      t.destroy_yourself
    end
  end
end


Place.find_each do |p|
  next if p.tgn_id.blank?
  next if p.hierarchy.present?

  delete_024_tgn(p.marc)

  p.paper_trail_event = "Reset TGN id"
  p.save
end