module Transfermarkt
  class LiveGame
    include HTTParty

    URL = "http://www.transfermarkt.com/en/livescores-und-livetabellen/uebersicht/livescores.html"

    def self.fetch
      req = self.get(URL, headers: {"User-Agent" => Transfermarkt::USER_AGENT})
      if req.code != 200
        nil
      else
        live_html = Nokogiri::HTML(req.parsed_response)
        puts live_html.xpath('//*[@id="centerbig"]//form//div[2]//table//tr//td[4]').inspect
      end
    end
  end
end

# //*[@id="centerbig"]/form/div[2]/table/tbody/tr[2]/td[4]