describe Sru::Query do
  
  describe "#initialize" do
    context "Simple fulltext search" do
      it "returns > 20000" do
        query = Sru::Query.new("sources", {:query => "Bach", :operation => "searchRetrieve"})
        expect(query.result.total).to be > 20000
      end
    end
  end

  describe "#initialize" do
    context "Simple index search with base" do
      it "returns ~ 104" do
        query = Sru::Query.new("sources", {:query => "dc.creator=Bach", :operation => "searchRetrieve"})
        expect(query.result.total).to be_within(100).of(200)
      end
    end
  end

  describe "#initialize" do
    context "Simple index search without base" do
      it "returns ~ 104" do
        query = Sru::Query.new("sources", {:query => "creator=Bach", :operation => "searchRetrieve"})
        expect(query.result.total).to be_within(100).of(200)
      end
    end
  end

  describe "#initialize" do
    context "ID search without base" do
      it "returns = 1" do
        query = Sru::Query.new("sources", {:query => "id=469285100", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end

  describe "#initialize" do
    context "Combined index search with AND" do
      it "returns > 10000" do
        query = Sru::Query.new("sources", {:query => "name=Bach and rism.siglum=D-Dl", :operation => "searchRetrieve"})
        expect(query.result.total).to be > 300
      end
    end
  end

  describe "#initialize" do
    context "Combined index and fulltext search with OR" do
      it "returns ~ 140" do
        query = Sru::Query.new("sources", {:query => "watermark=bach or \"Musikalisches Opfer\"", :operation => "searchRetrieve"})
        expect(query.result.total).to be_within(130).of(200)
      end
    end
  end

  describe "#initialize" do
    context "Index search with dates in different formats with logical AND" do
      it "returns = 149" do
        query = Sru::Query.new("sources", {:query => "rism.created>2016-12-24 and created<20170102", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 149
      end
    end
  end

 describe "#initialize" do
    context "Fulltext search with unphrased term and two terms and logical AND" do
      it "returns > 230" do
        query = Sru::Query.new("sources", {:query => "Bach, Johann Sebastian and Masses", :operation => "searchRetrieve"})
        expect(query.result.total).to be > 230
      end
    end
  end

 describe "#initialize" do
    context "Search with keyword in phrase" do
      it "returns = 1" do
        query = Sru::Query.new("sources", {:query => "\"foliation and many\" and words", :operation => "searchRetrieve"})
        expect(query.result.total).to be == 1
      end
    end
  end

 describe "#initialize" do
    context "Search with any operator" do
      it "returns > 800" do
        query = Sru::Query.new("sources", {:query => "name any Friedemann", :operation => "searchRetrieve"})
        expect(query.result.total).to be > 800
      end
    end
  end

  describe SruController, :type => :controller do
    render_views
    context "Default action should return the explain page"
      it "returns the explain page" do
        get "service"
        doc = Nokogiri::XML(response.body)
        namespace="http://explain.z3950.org/dtd/2.0/" 
        hostinfo = doc.xpath("//ns:serverInfo/ns:host", "ns" => namespace).first.content
        expect(hostinfo).to be == "rism.info"
      end
  end

  describe SruController, :type => :controller do
    render_views
    context "MaximumRecords should be limited to 100"
      it "returns the error page with limitiation" do
        get "service", {:query => 'Bach', :operation => "searchRetrieve", :maximumRecords => 200}
        doc = Nokogiri::XML(response.body)
        diag = "http://www.loc.gov/zing/srw/diagnostic/"
        max = doc.xpath("//diag:message", "diag" => diag).first.content
        expect(max).to match(/MaximumRecords is limited/)
      end
  end

end
