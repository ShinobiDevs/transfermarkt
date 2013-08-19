require "transfermarkt/version"

module Transfermarkt
  require 'httparty'
  require 'nokogiri'

  autoload :Player, 'transfermarkt/player'

  def Transfermarkt.base_uri
    "http://www.transfermarkt.com/"
  end

end

require 'transfermarkt/player'
