class FillCorporateNameInInstitutions < ActiveRecord::Migration[5.2]
  def change
    execute('UPDATE `institutions` SET corporate_name=full_name;')
  end
end
