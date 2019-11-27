class RecordSerializer < ActiveModel::Serializer
  attributes :id, :record_type, :marc, :model, :record_status, :record_owner
end
