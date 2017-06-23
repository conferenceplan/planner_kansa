module Kansa
  
  class Configuration
    attr_accessor :username   # Name of the report user 
    attr_accessor :key        # Password for the report user
    attr_accessor :base_url   # The base URL
    
    def initialize
      @client_options = {}
    end
  end
  
end
