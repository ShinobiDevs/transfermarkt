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
        raise req.code.to_s
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
      competition_uris = ["/wettbewerbe/europa", 
                          "/wettbewerbe/asien",
                          "/wettbewerbe/amerika",
                          "/wettbewerbe/afrika"]
      all_leagues = []
      competition_uris.each do |competition_uri|
        all_leagues << Transfermarkt::League.fetch_competition_leagues(competition_uri)
      end

      all_leagues.flatten
    end

    def self.fetch_competition_leagues(competition_uri)
      puts "Fetching #{competition_uri}"
      req = self.get(competition_uri, headers: {"User-Agent" => UserAgents.rand()})
      league_uris = []
      if req.code != 200
        []
      else
        competition_html = Nokogiri::HTML(req.parsed_response)
        league_uris << competition_html.xpath('//*[@id="yw1"]//table[@class="items"]//tr//td[2]//a').collect {|league| league["href"] }
        
        next_page_link = competition_html.xpath('//*[@id="yw2"]//li[@class="naechste-seite"]//a')[0]
        if next_page_link
          link = next_page_link["href"].split("?").first
          
          page = next_page_link["href"].scan(/page=(\d)/).flatten.first
          league_uris << Transfermarkt::League.fetch_competition_leagues(link + "?page=#{page}")
        else
          league_uris.flatten
        end

        league_uris.flatten
      end
    end
  end
end





