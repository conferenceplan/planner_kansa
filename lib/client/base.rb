module Kansa
  
  class Base
    include HTTParty

    attr_accessor :client
    
    def self.get_cookie
      res = get('/login',
        client.options.merge({
          query: {
            email: client.config.username,
            key:   client.config.key
          }
        })
      )
      raise RuntimeError, "Problem authenticating: #{response.body}" if res.code != 200

      cookie = parse_cookie(res.headers)
    end
        
    def method_missing(method, *args, &block) # TODO - check
      methodInspect = method == nil ? nil : method.to_string
      puts "Kansa::Base.method_missing() - method=#{methodInspect}"
      
      return @hash[method.to_s] if(@hash[method.to_s])
      if(method.match(/\?$/))
        is_method = method.to_s.gsub(/\?$/, "")
        if defined? @hash[is_method]
          return @hash[is_method].to_i == 1 ? true : false
        end
      else
        super()
      end
    end
    
    def respond_to(method)
      return true if @hash[method.to_s]
      super()
    end
    
    def methods
      methods = super()
      [methods, @hash.keys.map{ |k| k.to_sym} ].flatten
    end

    def json_true?(thing)
      [ "1", 1, true, "true"].include? thing
    end

    def client
      Client.instance
    end

    def self.client
      Client.instance
    end    
  end

end
