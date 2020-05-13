FactoryBot.define do
  factory :holding do
    lib_siglum { "D-B" }
    wf_stage { "published" }
    institutions { [association(:institution)]  }
    marc_source { <<STRING
=852  #\#$aD-B$cMus.ms.Bach P 48, Faszikel 7$eStaatsbibliothek zu Berlin - Preußischer Kulturbesitz, Musikabteilung$x30000655
STRING
    }
  end
  
  factory :foreign_holding, :parent => :holding do
    lib_siglum { "F-Pn" }
    wf_stage { "published" }
    institutions { [association(:foreign_institution)]  }
    marc_source { <<STRING
=852  #\#$aF-Pn$cMs 100$eBibliothèque nationale de France$x30001488
STRING
    }
  end




end
