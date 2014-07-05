require "transfermarkt/version"

module Transfermarkt
  require 'httparty'
  require 'nokogiri'
  require 'useragents'

  autoload :EntityBase, 'transfermarkt/entity_base'
  autoload :Player, 'transfermarkt/player'
  autoload :Club, 'transfermarkt/club'
  autoload :League, 'transfermarkt/league'
  autoload :LiveGame, 'transfermarkt/live_game'

  USER_AGENT = "Firefox"

  def Transfermarkt.base_uri
    "http://pipeline.bascout.com/"
    #{}"http://transfermarkt.co.uk"
  end

  def self.test_fetch_league
    before = Time.now
    league_uri = "en/primera-division/startseite/wettbewerb_ES1.html"
    league = Transfermarkt::League.fetch_by_league_uri(league_uri)
    after = Time.now

    return {:before => before, :after => after, :league => league}
  end

  def self.test_fetch_club
    club_uri = "/en/maccabi-haifa/startseite/verein_1064.html"
    club = Transfermarkt::Club.fetch_by_club_uri(club_uri)
  end

  def self.test_fetch_player
    uri = "/en/lionel-messi/profil/spieler_28003.html"
    player = Transfermarkt::Player.fetch_by_profile_uri(uri)
  end

  def self.test_fetch_player_performance_data
    uri = "/en/lionel-messi/leistungsdaten/spieler_28003_2012.html"
    data = Transfermarkt::Player.fetch_performance_data(uri)
  end
end

require 'transfermarkt/player'
