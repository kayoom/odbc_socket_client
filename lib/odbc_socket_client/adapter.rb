require 'active_record/connection_adapters/abstract_adapter'

module ActiveRecord
  class Base
    def self.odbc_socket_client_connection config
      
    end
  end
end

module OdbcSocketClient
  
  class Adapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
    ADAPTER_NAME = 'OdbcSocketClient'.freeze
    
    def initialize config, logger = nil
    end
    
    def adapter_name
      ADAPTER_NAME
    end
    
  end
end