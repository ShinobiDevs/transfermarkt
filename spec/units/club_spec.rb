require 'spec_helper'

describe Transfermarkt::Club do
  before(:all) do
    #FakeWeb.register_uri(:get, "www.transfermarkt.co.uk/maccabi-haifa/startseite/verein/1064", body: File.read(File.join("spec", "static_htmls", "maccabi_haifa_page.html")), status: ["200", "OK"])
    @haifa = Transfermarkt::Club.fetch_by_club_uri("/maccabi-haifa/startseite/verein/1064")
  end

  it "should be the right team" do
    expect(@haifa.name).to eq("Maccabi Haifa")
  end

  it "should find 25 players" do
    expect(@haifa.player_uris.size).to eq(25)
  end

  it "should be in Israel" do
    expect(@haifa.country).to eq("Israel")
  end
end