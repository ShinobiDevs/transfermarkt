require 'spec_helper'

describe Transfermarkt::Player do
  before(:all) do
    FakeWeb.register_uri(:get, "http://www.transfermarkt.co.uk/lionel-messi/profil/spieler/28003", body: File.read(File.join("spec", "static_htmls", "messi_player_page.html")), status: ["200", "OK"])
    @messi = Transfermarkt::Player.fetch_by_profile_uri("/lionel-messi/profil/spieler/28003")
  end

  it "should fetch a player details successfully" do
  
    expect(@messi.full_name).to eq("Lionel Messi")
    expect(@messi.name_in_native_country).to eq("Lionel Andrés Messi Cuccitini")
    expect(@messi.nationality).to eq(["Argentina", "Spain"])
    expect(@messi.date_of_birth).to eq("Jun 24, 1987")
    expect(@messi.age).to eq(27)
    expect(@messi.foot).to eq("left")
    expect(@messi.height).to eq(169)
    expect(@messi.club).to eq("FC Barcelona")
    expect(@messi.market_value).to eq(105_600_000)
    expect(@messi.position).to eq("Striker - Centre Forward")
  end
end