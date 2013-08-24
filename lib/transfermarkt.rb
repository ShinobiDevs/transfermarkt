require "transfermarkt/version"

module Transfermarkt
  require 'httparty'
  require 'nokogiri'

  autoload :EntityBase, 'transfermarkt/entity_base'
  autoload :Player, 'transfermarkt/player'
  autoload :Club, 'transfermarkt/club'
  autoload :League, 'transfermarkt/league'

  USER_AGENT = "Firefox"

  def Transfermarkt.base_uri
    "http://www.transfermarkt.com/"
  end

  def self.test_fetch_league
    before = Time.now
    league_uri = "en/primera-division/startseite/wettbewerb_ES1.html"
    league = Transfermarkt::League.fetch_by_league_uri(league_uri)
    after = Time.now

    return {:before => before, :after => after, :league => league}
  end
end

require 'transfermarkt/player'
