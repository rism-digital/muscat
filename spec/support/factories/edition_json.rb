FactoryBot.define do
  
  factory :edition_json, class: OpenStruct do

    marc { "{\"fields\":[{\"001\":\"__TEMP__\"},{\"040\":{\"subfields\":[{\"a\":\"DE-633\"}]}},{\"240\":{\"subfields\":[{\"m\":\"coro\"},{\"0\":\"3905618\"}]}},{\"245\":{\"subfields\":[{\"a\":\"[without title]\"}]}},{\"260\":{\"subfields\":[{\"c\":\"1780\"},{\"8\":\"01\"}]}},{\"300\":{\"subfields\":[{\"a\":\"score\"},{\"8\":\"01\"}]}},{\"593\":{\"subfields\":[{\"a\":\"Print\"},{\"8\":\"01\"}]}},{\"594\":{\"subfields\":[{\"b\":\"Coro\"}]}},{\"650\":{\"subfields\":[{\"0\":\"25240\"}]}},{\"980\":{\"subfields\":[{\"a\":\"RISM\"},{\"c\":\"examined\"}]}}]}" }

    lock_version { 0 }
    record_type { 8 }
    record_status { "published" }
    record_owner { 86 }
    triggers { Hash.new } 
    redirect { true }

  end
end
 
