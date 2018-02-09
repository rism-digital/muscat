RSpec.describe Sru::Query, solr: true do
  before(:each) do
    FactoryBot.create(:manuscript_source)
    Sunspot.index![Source]
  end
  describe "Return all records" do
    context "Simple fulltext search with astersik" do
      it "returns = 1 " do
        query = Sru::Query.new("sources", {:query => "*", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end
 
  describe "#initialize" do
    context "Simple fulltext search" do
      it "returns = 1" do
        query = Sru::Query.new("sources", {:query => "Bach", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end

  describe "#initialize" do
    context "Simple index search with base" do
      it "returns 1" do
        query = Sru::Query.new("sources", {:query => "dc.creator=\"Bach, Johann Sebastian\"", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end

  describe "#initialize" do
    context "Simple index search without base" do
      it "returns 1" do
        query = Sru::Query.new("sources", {:query => "creator=\"Bach, Johann Sebastian\"", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end

  describe "#initialize" do
    context "ID search without base" do
      it "returns = 1" do
        query = Sru::Query.new("sources", {:query => "id=#{Source.last.id}", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end

  describe "#initialize" do
    context "Combined index search with AND" do
      it "returns 1" do
        query = Sru::Query.new("sources", {:query => "name=\"Bach, Johann Sebastian\" and rism.siglum=D-B", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end

  describe "#initialize" do
    #TODO for 2 different sources
    context "Combined index and fulltext search with OR" do
      it "returns 1" do
        query = Sru::Query.new("sources", {:query => "watermark=\"a) W in überkröntem Schild - b) leer (oder nicht erkennbar)\" or \"Freude\"", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end

  describe "#initialize" do
    #context "Index search with dates in different formats with logical AND" do
    #  it "returns = 149" do
    #    query = Sru::Query.new("sources", {:query => "rism.created>2016-12-24 and created<20170102", :operation => "searchRetrieve"})
    #    expect(query.result.total).to be == 149
    #  end
    #end
  end

 describe "#initialize" do
    context "Fulltext search with unphrased term and two terms and logical AND" do
      it "returns > 120" do
        query = Sru::Query.new("sources", {:query => "Bach, Johann Sebastian and Freude", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end

 describe "#initialize" do
    context "Search with keyword in phrase" do
      it "returns = 1" do
        query = Sru::Query.new("sources", {:query => "\"Wahrscheinlich identisch\" and Freude", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end

 describe "#initialize" do
    #context "Search with any operator" do
      #it "returns > 800" do
      #  query = Sru::Query.new("sources", {:query => "name any Friedemann", :operation => "searchRetrieve"})
      #  expect(query.result.total).to be > 800
      #end
    #end
  end
  
  describe "#initialize" do
    #context "Search with mixed truncation" do
    #  it "crazy" do
    #    query = Sru::Query.new("sources", {:query => "creator=\"*\" AND title=*Freude*", :operation => "searchRetrieve"})
    #    expect(query.result.total).to be == 1
    #  end
    #end
  end
  
  #describe "creator=Bach,%20Johann gives syntax error" do
  #  pending
  #end



end
