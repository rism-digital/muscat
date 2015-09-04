class String
  def numeric?
    Float(self) != nil rescue false
  end
end

Source.where("id > 410000001").each do |s|
  marc = s.marc
  modified = false

  marc.each_by_tag("740") do |t|
    a = t.fetch_first_by_tag("a")
    if a.content.numeric?
      puts "NUM #{a.content}"
      # Ops ops ops!

      title = StandardTitle.find(a.content)
      puts title.title
      a.content = title.title

      modified = true

    end
  end

  s.save if modified

end
