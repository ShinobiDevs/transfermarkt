module Transfermarkt
  class Club < Transfermarkt::EntityBase
    attr_accessor :name,
                :country,
                :club_uri,
                :players,
                :player_uris

    def self.fetch_by_club_uri(club_uri, fetch_players = false)
      puts "fetching club #{club_uri}"

      req = self.get("/#{club_uri}", headers: {"User-Agent" => Transfermarkt::USER_AGENT})
      if req.code != 200
        nil
      else
        club_html = Nokogiri::HTML(req.parsed_response)
        options = {}

        options[:club_uri] = club_uri
        options[:name] = club_html.xpath('//*[@class="spielername-profil"]').text.strip
        options[:country] = club_html.xpath('//*[@id="land_select_breadcrumb"]//option[@selected="selected"]').text.strip
        options[:player_uris] = club_html.xpath('//*[@id="yw1"]//table//tr//td[2]//a[contains(@href,"profil")]').collect{|player_html| player_html["href"]}

        puts "found #{options[:player_uris].count} players"
        options[:players] = []

        if fetch_players
          options[:player_uris].each do |player_uri|
            options[:players] << Transfermarkt::Player.fetch_by_profile_uri(player_uri)
          end
        end

        puts "fetched club players for #{options[:name]}"

        self.new(options)
      end
    end
  end
end