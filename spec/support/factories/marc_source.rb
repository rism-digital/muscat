FactoryBot.define do
  factory :marc_source do
    marc "{\"fields\":[{\"001\":\"__TEMP__\"},{\"035\":{\"subfields\":[{\"a\":\"A 1262\"}]}},{\"040\":{\"subfields\":[{\"a\":\"DE-633\"}]}},{\"100\":{\"subfields\":[{\"d\":\"1549-1624\"},{\"0\":\"2539\"}]}},{\"240\":{\"subfields\":[{\"m\":\"4 V\"},{\"0\":\"3905618\"}]}},{\"245\":{\"subfields\":[{\"a\":\"Sacrae cantiones, vulgo motecta, paribus vocibus cantandae ... quatuor vocum.\"}]}},{\"260\":{\"subfields\":[{\"c\":\"1581\"},{\"8\":\"01\"}]}},{\"300\":{\"subfields\":[{\"a\":\"part(s)\"},{\"8\":\"01\"}]}},{\"510\":{\"subfields\":[{\"a\":\"RISM A/I\"},{\"c\":\"A 1262\"}]}},{\"593\":{\"subfields\":[{\"a\":\"print\"},{\"8\":\"01\"}]}},{\"597\":{\"subfields\":[{\"a\":\"Brescia, Vincenzo Sabbio\"}]}},{\"710\":{\"subfields\":[{\"0\":\"40009582\"},{\"4\":\"pbl\"}]}},{\"852\":{\"subfields\":[{\"x\":\"30000655\"}]}}]}"
  end

  factory :foreign_marc_source, parent: :marc_source do
    marc "{\"fields\":[{\"001\":\"__TEMP__\"},{\"035\":{\"subfields\":[{\"a\":\"A 1262\"}]}},{\"040\":{\"subfields\":[{\"a\":\"DE-633\"}]}},{\"100\":{\"subfields\":[{\"d\":\"1549-1624\"},{\"0\":\"2539\"}]}},{\"240\":{\"subfields\":[{\"m\":\"4 V\"},{\"0\":\"3905618\"}]}},{\"245\":{\"subfields\":[{\"a\":\"Sacrae cantiones, vulgo motecta, paribus vocibus cantandae ... quatuor vocum.\"}]}},{\"260\":{\"subfields\":[{\"c\":\"1581\"},{\"8\":\"01\"}]}},{\"300\":{\"subfields\":[{\"a\":\"part(s)\"},{\"8\":\"01\"}]}},{\"510\":{\"subfields\":[{\"a\":\"RISM A/I\"},{\"c\":\"A 1262\"}]}},{\"593\":{\"subfields\":[{\"a\":\"print\"},{\"8\":\"01\"}]}},{\"597\":{\"subfields\":[{\"a\":\"Brescia, Vincenzo Sabbio\"}]}},{\"710\":{\"subfields\":[{\"0\":\"40009582\"},{\"4\":\"pbl\"}]}},{\"852\":{\"subfields\":[{\"x\":\"30001488\"}]}}]}"
  end
end
 
