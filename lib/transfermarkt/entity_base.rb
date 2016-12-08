module Transfermarkt
  class EntityBase
    include HTTParty

    base_uri Transfermarkt.base_uri

    def initialize(options = {})
      options.each_pair do |key, value|
        self.send("#{key}=", value) if self.respond_to?("#{key}=")
      end
    end
  end
end
