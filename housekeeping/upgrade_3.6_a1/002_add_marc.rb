PaperTrail.request.disable_model(Catalogue)
PaperTrail.request.disable_model(Institution)
PaperTrail.request.disable_model(Person)

Catalogue.where(marc_source: nil).each {|c| c.scaffold_marc}
Institution.where(marc_source: nil).each {|c| c.scaffold_marc}
Person.where(marc_source: nil).each {|c| c.scaffold_marc}