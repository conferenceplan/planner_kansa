module Kansa
  
  class Member < Base
    
    def initialize(params={})
      @hash = params
    end

    # get the list of members from the remote system
    def self.get_members(since = nil)
      cookie = get_cookie
      
      opts = {}
      if since
        opts = {
          query: {
            since: since.iso8601
          }
        }
      end
      
      response = get('/people', client.options.merge({
          headers: {
            'Cookie' => cookie.to_cookie_string 
          }
        }.merge(opts)
      ))
      
     if response.code == 200
       JSON.parse(response.body)
     else
       raise RuntimeError, "Problem search for people: #{response.body}"  
     end
    end
    
    def get_members(since = nil)
      self.class.get_members(since)
    end

    private

      def self.parse_cookie(resp)
        cookie_hash = HTTParty::CookieHash .new
        resp.get_fields('Set-Cookie').each { |c| cookie_hash.add_cookies(c) }
        cookie_hash
      end    
  end

end
