require 'highline'
require 'conjur/api'
require 'netrc'

module Conjur::Authn
  class << self
    def login(options = {})
      delete_credentials
      get_credentials(options)
    end
    
    def delete_credentials
      netrc.delete host
      netrc.save
    end
    
    def host
      Conjur::Authn::API.host
    end
    
    def netrc
      @netrc ||= Netrc.read
    end
    
    def get_credentials(options = {})
      @credentials ||= (read_credentials || fetch_credentials(options))
    end
    
    def read_credentials
      netrc[host]
    end
    
    def fetch_credentials(options = {})
      ask_for_credentials(options)
      write_credentials
    end
    
    def write_credentials
      netrc[host] = @credentials
      netrc.save
      @credentials
    end
    
    def ask_for_credentials(options = {})
      hl = HighLine.new
      user = options[:username] || hl.ask("Enter your login to log into Conjur: ")
      pass = options[:password] || hl.ask("Please enter your password (it will not be echoed): "){ |q| q.echo = false }
      @credentials = [user, get_api_key(user, pass)]
    end
    
    def get_api_key user, pass
      Conjur::API.login(user, pass)
    end
    
    def connect(cls = Conjur::API, options = {})
      cls.new_from_key(*get_credentials(options))
    end
  end
end