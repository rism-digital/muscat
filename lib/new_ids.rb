module NewIds

  private

  def generate_new_id
    if self.id == nil || self.id == "__TEMP__"
       last = self.class.name.constantize.maximum(:id)
       self.id = last == nil ? 1 : last + 1
       self.id = [RISM::BASE_NEW_ID, self.id].max
    end
  end

end