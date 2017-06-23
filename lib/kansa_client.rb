require "planner_kansa/engine"

require 'httparty'
require 'singleton'

module Kansa

  require_relative './client/base'
  require_relative './client/configuration'
  require_relative './client/member'

  #############################################################################
  # Represents the configuration of a single session to a Kansa server
  class Client
    include HTTParty
    include Singleton
    
    attr_reader   :config
    attr_accessor :options
    
    # Creates a new {Client} instance and yields {#config}.
    # Requires a block to be given.
    def configure
      raise ArgumentError, "block not given" unless block_given?
      
      @config = Configuration.new
      yield config

      raise ArgumentError, "Kansa username not provided!" if config.username.nil?
      raise ArgumentError, "Kansa key not provided!" if config.key.nil?

      @config.base_url ||= "https://members.worldcon.fi/api"
      url = !config.base_url.blank? ? config.base_url : @config.base_url
      @options = {
        base_uri: url,
        :headers => {
          # "X-REMOTE-DOMAIN" => "1",
          "Accept"          => "application/json",
          "Content-Type"    => "application/json",
          "Accept-Charset"  => "utf-8"
        }
      }
                  
      @options.delete_if{|k, v| k == :body}
    end
    
    def configured?
      ! config.nil?
    end

  end

end
