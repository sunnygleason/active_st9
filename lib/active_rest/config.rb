module ActiveRest
  module Config
    def self.config=(config)
      if (config['http_client'].nil?)
        require "silly_putty/clients/auto_detect"
      else
        require "silly_putty/clients/#{config['http_client']}"
      end
      ActiveRest::Connection.http_client = SillyPutty::DefaultClient.new(config['host'], config['port'].to_i)
      @@allow_cascades = config['allow_cascades']
    end

    def self.allow_cascades?
      !!@@allow_cascades
    end
  end
end
