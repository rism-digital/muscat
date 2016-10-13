Catalogue.paper_trail.disable
Institution.paper_trail.disable
Person.paper_trail.disable

Catalogue.where(marc_source: nil).each {|c| c.scaffold_marc}
Institution.where(marc_source: nil).each {|c| c.scaffold_marc}
Person.where(marc_source: nil).each {|c| c.scaffold_marc}