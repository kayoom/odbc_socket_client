require 'builder' unless defined? ::Builder

module OdbcSocketClient
  class Request
    attr_accessor :query, :connection_string
    
    def initialize query, connection_string
      @query = query
      @connection_string = connection_string
    end
    
    def to_xml
      x = get_builder
      
      x.request do
        x.connectionstring @connection_string
        x.sql do
          x.cdata! @query
        end
      end
      
      iconv x.target!
    end
    
    protected
    def iconv xml_request
      Iconv.conv 'LATIN-9', 'UTF-8', xml_request
    end
    
    def get_builder
      x = Builder::XmlMarkup.new
      x.instruct! "xml", :version => '1.0'
      
      x
    end
  end
end