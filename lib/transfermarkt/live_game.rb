module Transfermarkt
  class LiveGame
    include HTTParty

    URL = "http://www.transfermarkt.com/en/livescores-und-livetabellen/uebersicht/livescores.html"

    def self.fetch
      req = self.get(URL, headers: {"User-Agent" => UserAgents.rand()})
      if req.code != 200
        nil
      else
        live_html = Nokogiri::HTML(req.parsed_response)
        home_teams = live_html.xpath('//*[@id="centerbig"]//form//div[2]//table//tr//td[4]/a').collect {|a| a["href"]}
        results = live_html.xpath('//*[@id="centerbig"]//form//div[2]//table//tr//td[6]').collect(&:text).collect(&:strip)
        away_teams = live_html.xpath('//*[@id="centerbig"]//form//div[2]//table//tr//td[8]/a').collect {|a| a["href"]}
        
        result_set = []
        home_teams.each_with_index do |home_team, index|
          result_set << {home: home_team, result: results[index], away: away_teams[index]}
        end

        result_set
      end
    end
  end
end