module Transfermarkt
  class Player < Transfermarkt::EntityBase
    attr_accessor :profile_uri,
                :age,
                :date_of_birth,
                :full_name,
                :name_in_native_country,
                :complete_name,
                :foot,
                :height,
                :picture,
                :club,
                :market_value,
                :nationality,
                :position,
                :performance_data,
                :injuries_data,
                :player_agent

    def initialize(options = {})
      super

      encoding_options = {
        :invalid           => :replace,  # Replace invalid byte sequences
        :undef             => :replace,  # Replace anything not defined in ASCII
        :replace           => '',        # Use a blank for those replacements
        :UNIVERSAL_NEWLINE_DECORATOR => true       # Always break lines with \n
      }
      self.age = self.age.to_i
      #self.market_value = #self.market_value.to_s.gsub(",", "").to_i
      self.height = self.height.to_s.gsub(",", "").to_i
      self.nationality = self.nationality.to_s.encode(Encoding.find('ASCII'), encoding_options).split("\t").collect(&:strip)
      if self.date_of_birth.present?
        self.age = Date.today.year - Date.parse(self.date_of_birth).year
      end
    end

    def valid_player?
      if club.nil? or club.empty?
        false
      else
        true
      end
    end

    def self.search(player_name)
      req = self.get("/schnellsuche/ergebnis/schnellsuche", query: {query: player_name, x: 0, y:0})
      if req.code != 200
        nil
      else
        profile_html = Nokogiri::HTML(req.parsed_response)
        results = {}

        link = profile_html.css(".spielprofil_tooltip")[0]["href"]
        self.fetch_by_profile_uri(link)
      end
    end

    def self.fetch_by_profile_uri(profile_uri = "")
      req = self.get("/#{profile_uri}", headers: {"User-Agent" => UserAgents.rand()})
      if req.code != 200
        nil
      else
        #byebug
        profile_html = Nokogiri::HTML(req.parsed_response)
        options = {}

        # puts "**** Parsing player #{profile_uri}"

        options[:profile_uri] = profile_uri

        # //*[@id="main"]/div[7]/div/div/div[2]/div[2]/div[2]/table/tbody/tr[2]/td/a
        club = profile_html.css(".hauptpunkt > a:nth-child(1)").text

        unless club.empty?
          options[:club] = profile_html.css(".hauptpunkt > a:nth-child(1)").text

          # options[:position] = profile_html.xpath('//*[@id="main"]//div[7]//table[1]//tr[3]//td[1]')[1].text.strip
          options[:full_name] = profile_html.css(".dataName > h1:nth-child(2)").text

          options[:picture] = "https:" + profile_html.css(".dataBild > img:nth-child(1)").first["src"]
          #profile_html.xpath('//*[@id="main"]//div[7]//div//div//div[2]//div[1]//img')[0]["src"]

          # options[:name_in_native_country] = profile_html.xpath('//*[@id="main"]//div[9]//div[1]//div[2]//div[2]//div[1]//div//table//tr[1]//td[1]')[0].text

          options[:market_value] = profile_html.css(".dataMarktwert > a:nth-child(1)").text.split(" ").first

          agent = profile_html.css("div.dataDaten:nth-child(2) > p:nth-child(4) > span:nth-child(2) > a:nth-child(1)").text

          # if options[:market_value].include?("Mil")
          #    options[:market_value] = options[:market_value].to_f * 1_000_000
          # else
          #   options[:market_value] = options[:market_value].to_f * 100_000
          # end

          options[:name_in_native_country] = options[:full_name]
          options[:complete_name] = options[:full_name]

          player_info = profile_html.css("table.auflistung").search("tr")

          player_info.each do |info_row|
            header = info_row.search('th')[0].text.strip
            if header == "Name in home country:"
              options[:name_in_native_country] = info_row.search('td')[0].text.strip
              # puts options
            elsif header == "Date of birth:"
              options[:date_of_birth] = info_row.search('td')[0].text.strip
              # puts options
            elsif header == "Place of birth:"
              options[:place_of_birth] = info_row.search('td')[0].text.strip
              # puts options
            # elsif header == "Age:"
            #   options[:age] = info_row.search('td')[0].text.strip
            #   # puts options
            elsif header == "Height:"
              options[:height] = info_row.search('td')[0].text.strip
              # puts options
            elsif header == "Nationality:"
              options[:nationality] = info_row.search('td')[0].text.strip
              # puts options
            elsif header == "Position:"
              options[:position] = info_row.search('td')[0].text.strip
              # puts options
            elsif header == "Foot:"
              options[:foot] = info_row.search('td')[0].text.strip
              # puts options
            elsif header == "Complete name:"
              options[:complete_name] = info_row.search('td')[0].text.strip
              # puts options
            end
          end

          # get player performance
          # options[:performance_data] = {}
          #
          # performance_uri = profile_uri.gsub("profil", "leistungsdaten") + "/saison/"
          #
          # years = (Time.now.year - 6..Time.now.year).to_a
          # years.each do |year|
          #   goalkeeper = options[:position] == "Goalkeeper"
          #   options[:performance_data][year.to_s] = self.fetch_performance_data(performance_uri + year.to_s, goalkeeper)
          # end
          #
          # # Get injury data
          #
          # injury_uri = profile_uri.gsub("profil", "verletzungen")
          #
          # options[:injuries_data] = self.fetch_injuries_data(injury_uri)
        end

        self.new(options)
      end
    end
  private
    def self.fetch_performance_data(performance_uri, is_goalkeeper = false)
      req = self.get("/#{performance_uri}", headers: {"User-Agent" => UserAgents.rand()})
      if req.code != 200
        nil
      else
        performance_data = []
        performance_html = Nokogiri::HTML(req.parsed_response)
        performance_headers = if is_goalkeeper
          [:competition, :blank, :appearances, :goals, :yellow_cards, :second_yellows, :red_cards, :goals_conceded, :games_without_conceded_goals, :minutes]
        else
          [:competition, :blank, :appearances, :goals, :assists, :yellow_cards, :second_yellows, :red_cards, :minutes]
        end
        # performance_html.xpath('//*[@id="yw2"]//table//tbody//tr[position()>0]').each do |competition|
        #   values = Nokogiri::HTML::DocumentFragment.parse(competition.to_html).search("*//td").collect(&:text)
        #   if values.first == ""
        #     values.delete_at 0
        #   end
        #   competition_performance = Hash[performance_headers.zip(values)]
        #   competition_performance[:minutes] = competition_performance[:minutes].gsub(".", "").to_i
        #   performance_data << competition_performance
        # end
        performance_html.xpath('//*[@id="yw2"]//table//tfoot//tr[position()>0]').each do |competition|
          values = Nokogiri::HTML::DocumentFragment.parse(competition.to_html).search("*//td").collect(&:text)
          if values.first == ""
            values.delete_at 0
          end
          competition_performance = Hash[performance_headers.zip(values)]
          competition_performance[:minutes] = competition_performance[:minutes].gsub(".", "").to_i
          competition_performance.delete(:blank)
          performance_data << competition_performance
        end
      end
      return performance_data
    end

    def self.fetch_injuries_data(injury_uri)
      req = self.get("/#{injury_uri}", headers: {"User-Agent" => UserAgents.rand()})
      if req.code != 200
        []
      else
        injury_data = []
        player_html = Nokogiri::HTML(req.parsed_response)
        injuries_headers = [:season, :injury, :from, :to, :days_out, :games_missed]

        player_html.xpath('//*[@id="yw1"]//table//tr[position()>1]').each do |injury_row|
          values = Nokogiri::HTML::DocumentFragment.parse(injury_row.to_html).search("*//td").collect(&:text)
          injury_details = Hash[injuries_headers.zip(values)]
          injury_details[:days_out] = injury_details[:days_out].strip.to_i
          injury_details[:games_missed] = injury_details[:games_missed].strip.to_i
          injury_data << injury_details
        end
        injury_data
      end
    end
  end
end
