class AddNullToPlaces < ActiveRecord::Migration[7.1]
  def self.up    
    execute("UPDATE places SET district = NULL where district = ''")
    execute("UPDATE places SET country = NULL where country = ''")
    execute("UPDATE places SET notes = NULL where notes = ''")
    execute("UPDATE places SET alternate_terms = NULL where alternate_terms = ''")
    execute("UPDATE places SET topic = NULL where topic = ''")
    execute("UPDATE places SET sub_topic = NULL where sub_topic = ''")
    execute("UPDATE places SET viaf = NULL where viaf = ''")
    execute("UPDATE places SET gnd = NULL where gnd = ''")
  end
end
