module Transfermarkt
  class Player < Transfermarkt::EntityBase
    attr_accessor :profile_uri,
                :age,
                :date_of_birth, 
                :full_name,
                :name_in_native_country,
                :foot,
                :height,
                :picture,
                :club,
                :market_value, 
                :nationality, 
                :position,
                :performance_data,
                :injuries_data

    def initialize(options = {})
      super

      encoding_options = {
        :invalid           => :replace,  # Replace invalid byte sequences
        :undef             => :replace,  # Replace anything not defined in ASCII
        :replace           => '',        # Use a blank for those replacements
        :universal_newline => true       # Always break lines with \n
      }
      self.age = self.age.to_i
      self.market_value = self.market_value.to_s.gsub(",", "").to_i
      self.height = self.height.to_s.gsub(",", "").to_i
      self.nationality = self.nationality.to_s.encode(Encoding.find('ASCII'), encoding_options).split("\n").collect(&:strip)
    end

    def self.fetch_by_profile_uri(profile_uri = "")
      puts "fetching player profile #{profile_uri}"

      req = self.get("/#{profile_uri}", headers: {"User-Agent" => UserAgents.rand()})
      if req.code != 200
        nil
      else
        profile_html = Nokogiri::HTML(req.parsed_response)
        options = {}

        options[:profile_uri] = profile_uri

        # //*[@id="main"]/div[7]/div/div/div[2]/div[2]/div[2]/table/tbody/tr[2]/td/a
        options[:club] = profile_html.xpath('//*[@id="main"]//div[7]//table//tr[2]//td//a').text
        options[:position] = profile_html.xpath('//*[@id="main"]//div[7]//table[1]//tr[3]//td[1]')[1].text.strip
        options[:full_name] = profile_html.xpath('//*[@class="spielername-profil"]').text.gsub(/[\d]/, "").strip

        options[:picture] = profile_html.xpath('//*[@id="main"]//div[7]//div//div//div[2]//div[1]//img')[0]["src"]
        options[:name_in_native_country] = profile_html.xpath('//*[@id="main"]//div[9]//div[1]//div[2]//div[2]//div[1]//div//table//tr[1]//td[1]')[0].text

        options[:market_value] = profile_html.xpath('//*[@id="main"]//div[7]//div//div//div[2]//div[3]//span//a').text.gsub(",", ".")
        
        if options[:market_value].include?("Mil")
           options[:market_value] = options[:market_value].to_f * 1_000_000
        else
          options[:market_value] = options[:market_value].to_f * 100_000
        end
        info_values = profile_html.xpath('//*[@id="main"]//div[9]//div[1]//div[2]//div[2]//div[1]//div//table//tr//td').collect(&:text).collect(&:strip)
        info_headers = [:name_in_native_country, :date_of_birth, :place_of_birth, :age, :height, :nationality, :position, :foot]

        
        player_info = Hash[info_headers.zip(info_values.slice(0..info_headers.size))]
        
        # get player performance
        options[:performance_data] = {}

        performance_uri = profile_uri.gsub("profil", "leistungsdaten") + "/saison/"

        years = (Time.now.year - 6..Time.now.year - 1).to_a

        years.each do |year|
          goalkeeper = options[:position] == "Goalkeeper"
          options[:performance_data][year.to_s] = self.fetch_performance_data(performance_uri + year.to_s, goalkeeper) 
        end

        # Get injury data
        
        injury_uri = profile_uri.gsub("profil", "verletzungen")

        options[:injuries_data] = self.fetch_injuries_data(injury_uri)

        puts "fetched player #{options[:full_name]}"

        self.new(player_info.merge(options))
      end
    end
  private
    def self.fetch_performance_data(performance_uri, is_goalkeeper = false)
      puts "Fetching Performance page for #{performance_uri}"
      req = self.get("/#{performance_uri}", headers: {"User-Agent" => UserAgents.rand()})
      if req.code != 200
        nil
      else
        performance_data = []
        performance_html = Nokogiri::HTML(req.parsed_response)
        performance_headers = if is_goalkeeper
          [:competition, :matches, :goals, :own_goals, :assists, :yellow_cards, :second_yellows, :red_cards, :substituted_in, :substituted_out , :goals_conceded, :saves, :minutes]
        else
          [:competition, :matches, :goals, :assists, :yellow_cards, :second_yellows, :red_cards, :minutes]
        end

        performance_html.xpath('//*[@id="yw2"]//table//tr[position()>1]').each do |competition|
          values = Nokogiri::HTML::DocumentFragment.parse(competition.to_html).search("*//td").collect(&:text)
          if values.first == ""
            values.delete_at 0
          end
          competition_performance = Hash[performance_headers.zip(values)]
          competition_performance[:minutes] = competition_performance[:minutes].gsub(".", "").to_i 
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
        puts injury_data.inspect
        injury_data
      end
    end
  end
end