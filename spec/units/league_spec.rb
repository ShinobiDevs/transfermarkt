require 'spec_helper'

describe Transfermarkt::League do

  describe "Real League" do
    before(:all) do
      FakeWeb.register_uri(:get, "http://www.transfermarkt.co.uk/jumplist/startseite/wettbewerb/GB1", body: File.read(File.join("spec", "static_htmls", "premier_league_html.html")), status: ["200", "OK"])
      @permier_league = Transfermarkt::League.fetch_clubs_and_uris_by_league_uri("/jumplist/startseite/wettbewerb/GB1")
    end

    describe "#valid_league?" do

      it "should return true for a league page" do
        expect(@permier_league.valid_league?).to eq(true)
      end

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

  describe "A Cup" do
    before(:all) do
      FakeWeb.register_uri(:get, "http://www.transfermarkt.co.uk/mtn8/startseite/pokalwettbewerb/SFAL", body: File.read(File.join("spec", "static_htmls", "cup.html")), status: ["200", "OK"])
      @cup = Transfermarkt::League.fetch_clubs_and_uris_by_league_uri("/mtn8/startseite/pokalwettbewerb/SFAL")
    end

    describe "#valid_league?" do

      it "should return false for a cup page" do
        expect(@cup.valid_league?).to eq(false)
      end

    end

  end

end
