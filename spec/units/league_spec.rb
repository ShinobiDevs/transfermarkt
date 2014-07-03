require 'spec_helper'

describe Transfermarkt::League do
  before(:all) do
    FakeWeb.register_uri(:get, "http://www.transfermarkt.co.uk/jumplist/startseite/wettbewerb/GB1", body: File.read(File.join("spec", "static_htmls", "premier_league_html.html")), status: ["200", "OK"])
    @permier_league = Transfermarkt::League.fetch_clubs_and_uris_by_league_uri("/jumplist/startseite/wettbewerb/GB1")
  end

  describe '#name' do
    it "should be premier league" do
      expect(@permier_league.name).to eq("Premier League")
    end
  end

  describe '#country' do
    it "should be england" do
      expect(@permier_league.country).to eq("England")
    end
  end

  describe "#fetch_clubs_and_uris_by_league_uri" do
    it "should fetch 20 teams" do
      expect(@permier_league.clubs_index.count).to eq(20)
    end
  end
end