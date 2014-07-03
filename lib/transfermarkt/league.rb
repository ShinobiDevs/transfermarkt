module Transfermarkt
  class League < Transfermarkt::EntityBase
    attr_accessor :name,
                :country,
                :league_uri,
                :clubs,
                :clubs_index
                :club_uris

    def self.fetch_clubs_and_uris_by_league_uri(league_uri)
      req = self.get("/#{league_uri}", headers: {"User-Agent" => ::UserAgents.rand()})
      if req.code != 200
        nil
      else
        league_html = Nokogiri::HTML(req.parsed_response)
        options = {}

        options[:league_uri] = league_uri
        options[:name] = league_html.xpath('//select[@id="wettbewerb_select_breadcrumb"]//option[@selected="selected"]')[0].text
        options[:country] = league_html.xpath('//select[@id="land_select_breadcrumb"]//option[@selected="selected"]').text

        club_uris = league_html.xpath('//*[@id="yw1"]//table//tr//td[2]//a[1]').collect{|player_html| player_html["href"]}
        club_names = league_html.xpath('//*[@id="yw1"]//table//tr//td[2]//a[1]').collect{|player_html| player_html.text }

        clubs = Hash[club_names.zip(club_uris)]
        
        options[:clubs_index] = clubs
        self.new(options)
      end
    end

    def self.fetch_by_league_uri(league_uri, fetch_clubs = false)
      puts "fetching league #{league_uri}"

      req = self.get("/#{league_uri}", headers: {"User-Agent" => Useragents.rand()})
      if req.code != 200
        nil
      else
        league_html = Nokogiri::HTML(req.parsed_response)
        options = {}

        options[:league_uri] = league_uri
        options[:name] = league_html.xpath('//select[@id="wettbewerb_select_breadcrumb"]//option[@selected="selected"]')[0].text
        options[:country] = league_html.xpath('//select[@id="land_select_breadcrumb"]//option[@selected="selected"]').text

        options[:club_uris] = league_html.xpath('//*[@id="yw1"]//table//tr//td[2]//a[1]').collect{|player_html| player_html["href"]}

        puts "Found #{options[:club_uris].count} clubs"
        options[:clubs] = []

        if fetch_clubs
          options[:club_uris].each do |club_uri|
            options[:clubs] << Transfermarkt::Club.fetch_by_club_uri(club_uri, fetch_clubs)
          end
        end

        puts "fetched league clubs for #{options[:name]}"

        self.new(options)
      end
    end

    def self.fetch_league_uris
      root_uri = "/en/ligat-haal/startseite/wettbewerb_ISR1.html"
      req = self.get("/#{root_uri}", headers: {"User-Agent" => UserAgents.rand()})
      if req.code != 200
        nil
      else
        root_html = Nokogiri::HTML(req.parsed_response)
        league_uris = root_html.xpath('//*[@id="yw1"]//table//tr//td[2]//a[1]').collect{|player_html| player_html["href"]}
      end
    end
  end
end