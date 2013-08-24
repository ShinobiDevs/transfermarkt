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
                :performance_data

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

        headers = profile_html.xpath('//*[@id="centerbig"]//div[1]//table//tr//td[2]//table//tr//td[1]').collect(&:text)
        headers = headers.collect {|header| header.downcase.gsub(":", "").gsub(" ", "_").gsub("'s", "").to_sym}

        values = profile_html.xpath('//*[@id="centerbig"]//div[1]//table//tr//td[2]//table//tr//td[2]').collect(&:text)
        values = values.collect {|value| value.strip.match(/[A-Za-z0-9,. -]*/)[0] }

        # get player performance
        options[:performance_data] = {}

        performance_uri = profile_uri.gsub("profil", "leistungsdaten")
        #perforamnce_types = ["All"]
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
          #options[:performance_data][type] = self.fetch_performance_data(performance_with_type_uri) 
        end
        
        puts "fetched player #{options[:full_name]}"

        self.new(options.merge(Hash[headers.zip(values)]))
      end
    end
  private
    def self.fetch_performance_data(performance_uri)
      req = self.get("/#{performance_uri}", headers: {"User-Agent" => Transfermarkt::USER_AGENT})
      if req.code != 200
        nil
      else
        performance_data = {}
        profile_html = Nokogiri::HTML(req.parsed_response)
      end
    end
  end
end