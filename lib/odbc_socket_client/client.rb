

require 'odbc_socket_client/request'
require 'odbc_socket_client/result'
require 'odbc_socket_client/connection'
require 'odbc_socket_client/connection_string'

module OdbcSocketClient
  class Client
    
    
    def initialize config, logger
      config = config.symbolize_keys
      
      @connection_string = ConnectionString.build config
      @host = config[:host]
      @port = config[:port].to_i || 9628
      @logger = logger
    end
    
    def build_request query
      Request.new query, @connection_string
    end
    
    def connection
      @connection ||= Connection.new @host, @port
    end
    
    def execute_query query
      puts "Executing: " + query
      execute build_request(query)
    end
    
    def execute request
      connection.socket do |s|
        s.print request.to_xml
        
        Result.new s.read
      end
    end
  end
end