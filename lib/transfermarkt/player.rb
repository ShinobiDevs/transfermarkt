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
      self.market_value = self.market_value.to_s.gsub(".", "").to_i
      self.height = self.height.to_s.gsub(",", "").to_i
    end

    def self.fetch_by_profile_uri(profile_uri = "")
      puts "fetching player profile #{profile_uri}"

      req = self.get("/#{profile_uri}", headers: {"User-Agent" => Transfermarkt::USER_AGENT})
      if req.code != 200
        nil
      else
        profile_html = Nokogiri::HTML(req.parsed_response)
        options = {}

        options[:profile_uri] = profile_uri
        options[:club] = profile_html.xpath('//*[@id="centerbig"]//div[1]//div//table//tr[2]//td//a[1]').text
        options[:full_name] = profile_html.xpath('//*[@id="centerbig"]//div[1]//div//table//tr[1]//td[2]//h1').text.gsub(/[\d]/, "").strip
        options[:picture] = profile_html.xpath('//*[@id="centerbig"]//div[1]//table//tr//td[1]//img')[1]["src"]
        options[:name_in_native_country] = profile_html.xpath("//*[@class='given-name s10']").text

        headers = profile_html.xpath('//*[@id="centerbig"]//div[1]//table//tr//td[2]//table//tr//td[1]').collect(&:text)
        headers = headers.collect {|header| header.downcase.gsub(":", "").gsub(" ", "_").gsub("'s", "").to_sym}

        values = profile_html.xpath('//*[@id="centerbig"]//div[1]//table//tr//td[2]//table//tr//td[2]').collect(&:text)
        values = values.collect {|value| value.strip.match(/[A-Za-z0-9,. -]*/)[0] }

        # get player performance
        options[:performance_data] = {}

        performance_uri = profile_uri.gsub("profil", "leistungsdaten")

        options = Hash[headers.zip(values)].merge(options)

        # If there is a performance data blcok
        if profile_html.xpath('//*[@id="centerbig"]/div[4]/p[3]/a').any?

          perforamnce_types = []
          10.times do |i|
            perforamnce_types << (Time.now.year - i).to_s
          end

          perforamnce_types.each do |type|
            performance_with_type_uri = ""
            if type == "All"
              performance_with_type_uri = performance_uri.gsub(".html", "_gesamt.html")
            else
              performance_with_type_uri = performance_uri.gsub(".html", "_#{type}.html")
            end

            goalkeeper = options[:position] == "Goalkeeper"
            options[:performance_data][type] = self.fetch_performance_data(performance_with_type_uri, goalkeeper) 
          end
        end        
        
        options[:injuries_data] = self.fetch_injuries_data(profile_html)

        puts "fetched player #{options[:full_name]}"

        self.new(options)
      end
    end
  private
    def self.fetch_performance_data(performance_uri, is_goalkeeper = false)
      req = self.get("/#{performance_uri}", headers: {"User-Agent" => Transfermarkt::USER_AGENT})
      if req.code != 200
        nil
      else
        performance_data = []
        performance_html = Nokogiri::HTML(req.parsed_response)
        performance_headers = if is_goalkeeper
          [:competition, :matches, :goals, :own_goals, :assists, :yellow_cards, :second_yellows, :red_cards, :substituted_in, :substituted_out , :goals_conceded, :saves, :minutes]
        else
          [:competition, :matches, :goals, :own_goals, :assists, :yellow_cards, :second_yellows, :red_cards, :substituted_in, :substituted_out, :minutes_per_goal, :minutes]
        end

        performance_html.xpath('//table[@class="standard_tabelle"][1]//tr[position()>1]').each do |competition|
          values = Nokogiri::HTML::DocumentFragment.parse(competition.to_html).search("*//td").collect(&:text)
          if values.first == ""
            values.delete_at 0
          end
          performance_data << Hash[performance_headers.zip(values)]
        end
        performance_data
      end

      return performance_data
    end

    def self.fetch_injuries_data(player_html)
      injury_data = []
      injuries_headers = [:season, :from, :to, :injury]

      player_html.xpath('//*[@id="centerbig"]/div[4]/table[3]//tr[position()>1]').each do |injury_row|
        values = Nokogiri::HTML::DocumentFragment.parse(injury_row.to_html).search("*//td").collect(&:text)
        injury_data << Hash[injuries_headers.zip(values)]
      end
      injury_data
    end
  end
end