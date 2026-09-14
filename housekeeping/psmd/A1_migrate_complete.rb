require_relative 'legacy_file.rb'

legacy = LegacyFile.new("housekeeping/psmd/psmd.yml")
@people_map = YAML.load_file("housekeeping/psmd/psmd_people.yml")
@institution_map = YAML.load_file("housekeeping/psmd/psmd_institutions.yml")

the_short_list = %w[
3710
3714
3820
337
3815
1222
3814
3573
2000
2000
3631
1378
3721
2563
3557
3765
3688
3644
3719
3723
3725
3726
3728
3744
3743
871
1220
1257
1298
2552
3698
3698
3699
3699
3707
3711
3712
3724
3724
3741
3742
3821
794
864
1798
2014
2014
3737
3739
3713
3745
3746
3748
3749
3751
3643
3708
3720
3717
3717
3136
1221
3802
]

#ap legacy.all(:manuscripts).first

def copy_from_source_marc(source, dest)
  copy_map = [
    {
      from: "040",
      to: "040",
      subfields: { "b" => "b" }
    },
    {
      from: "100",
      to: "100",
      subfields: {"a" => "a", "d" => "d", "0" => "0" },
      map: @people_map
    },
    {
      from: "240",
      to: "730",
      subfields: {"a" => "a" }
    },
    {
      from: "245",
      to: "245",
      subfields: {"a" => "a" }
    }, 
    {
      from: "246",
      to: "246",
      subfields: {"a" => "a" }
    }, 
    {
      from: "260",
      to: "260",
      subfields: {"a" => "a", "b" => "b", "c" => "c", "e" => "e", "f" => "f" }
    }, 
    {
      from: "300",
      to: "300",
      subfields: {"a" => "a", "b" => "b", "c" => "c" }
    }, 
    {
      from: "340",
      to: "340",
      subfields: {"d" => "d" }
    },
    {
      from: "500",
      to: "500",
      subfields: {"d" => "d" }
    }, 
    {
      from: "505",
      to: "505",
      subfields: {"d" => "d" }
    }, 
    {
      from: "596",
      to: "596",
      subfields: {"a" => "a" }
    }, 
    {
      from: "599",
      to: "599",
      subfields: {"a" => "a" }
    }, 
    {
      from: "650",
      to: "650",
      subfields: {"a" => "a" }
    }, 
    {
      from: "690",
      to: "690",
      subfields: {"a" => "a", "n" => "n" }
    }, 
    {
      from: "691",
      to: "691",
      subfields: { "a" => "a", "n" => "n" }
    },
    {
      from: "700",
      to: "700",
      subfields: { "a" => "a", "4" => "4", "0" => "0" },
      map: @people_map
    }, 
    {
      from: "710",
      to: "710",
      subfields: {"a" => "a", "4" => "4", "0" => "0" },
      map: @institution_map
    }, 
  ]

  destroyed = {}

  copy_map.each do |rule|
    source[rule[:from]].each do |source_tag|
      values = {}

      rule[:subfields].each do |source_sf, dest_sf|
        source_tag[source_sf].each do |subfield|
          kill = false

          if source_sf == "0" && rule.include?(:map)
            if rule[:map].include?(subfield.content.to_s)
              subfield.content = rule[:map][subfield.content]
            else
              puts "#{source_tag.tag} ID not mapped #{subfield.content}".red
              puts source_tag
              subfield.destroy_yourself
              kill = true
            end
          end

          (values[dest_sf.to_sym] ||= []) << subfield.content if !kill
        end
      end

      next if values.empty?

      unless destroyed[rule[:to]]
        dest[rule[:to]].each(&:destroy_yourself) unless dest[rule[:to]].empty?
        destroyed[rule[:to]] = true
      end

      dest.add_tag_with_subfields(rule[:to], **values)
    end
  end

end

#default_file_name = EditorConfiguration.get_source_default_file("edition")
#default_file = ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/source/#{default_file_name}.marc")
#def_marc = File.read(default_file)

the_short_list.each do |m|
  
  ms = legacy.find(:manuscripts, m)

  old = MarcSource.new(ms["source"], 8)
  old.load_source false

  new = MarcSource.new("=001 __TEMP__", 8)
  new.reset_to_new

  copy_from_source_marc(old, new)
  new.import

  source = Source.new
  source.user = User.find(74)
  source.marc = new
  source.record_type = 8

  source.save
  puts "PSMD #{m} to #{source.id}"

end