module ActiveRecordValidation

  def validates_parent_id
    parent = marc.get_parent
    if parent && parent.id && self.id == parent.id
      errors.add(:base, "validates_parent_id")
    end
  end

end
