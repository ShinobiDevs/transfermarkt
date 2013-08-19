module Transfermarkt
  class Player
    include HTTParty

    base_uri Transfermarkt.base_uri

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
                :position

    def initialize(options = {})
      options.each_pair do |key, value|
        self.send("#{key}=", value) if self.respond_to?("#{key}=")

        self.market_value = self.market_value.to_s.gsub(".", "").to_i
        self.height = self.height.to_s.gsub(",", "").to_i
      end
    end

    def self.find_by_profile_uri(profile_uri = "")
      req = self.get("/#{profile_uri}", headers: {"User-Agent" => "Firefox"})
      if req.code != 200
        nil
      else
        profile_html = Nokogiri::HTML(req.parsed_response)
        options = {}
        options[:club] = profile_html.xpath('//*[@id="centerbig"]//div[1]//div//table//tr[2]//td//a[1]').text
        options[:full_name] = profile_html.xpath('//*[@id="centerbig"]//div[1]//div//table//tr[1]//td[2]//h1').text.match(/[A-Za-z ]{1,100}/)[0].strip
        options[:picture] = profile_html.xpath('//*[@id="centerbig"]//div[1]//table//tr//td[1]//img')[1]["src"]

        headers = profile_html.xpath('//*[@id="centerbig"]//div[1]//table//tr//td[2]//table//tr//td[1]').collect(&:text)
        headers = headers.collect {|header| header.downcase.gsub(":", "").gsub(" ", "_").gsub("'s", "").to_sym}

        values = profile_html.xpath('//*[@id="centerbig"]//div[1]//table//tr//td[2]//table//tr//td[2]').collect(&:text)
        values = values.collect {|value| value.strip.match(/[A-Za-z0-9,. -]*/)[0] }
        self.new(options.merge(Hash[headers.zip(values)]))
      end
    end
  end
end