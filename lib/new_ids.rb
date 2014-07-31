module NewIds

  private

  def generate_new_id
    # Nil if record is new
    # __TEMP__ if id is STRING and record generated from marc editor
    # 0 same as above but for integer ids
    if self.id == nil || self.id == "__TEMP__" || self.id == 0
       last = self.class.name.constantize.maximum(:id)
       self.id = last == nil ? 1 : last + 1
       self.id = [RISM::BASE_NEW_ID, self.id].max
    end
  end

end