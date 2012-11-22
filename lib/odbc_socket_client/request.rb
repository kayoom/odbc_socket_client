# require 'builder' unless defined? ::Builder
require 'nokogiri'

module OdbcSocketClient
  class Request
    attr_accessor :query, :connection_string

    def initialize query, connection_string
      @query = query
      @connection_string = connection_string
    end

    def to_xml
      x = Nokogiri::XML::Builder.new

      x.request do |x|
        x.connectionstring @connection_string
        x.sql do |x|
          x.cdata @query
        end
      end

      iconv x.to_xml
    end

    protected
    def iconv xml_request
      Iconv.conv 'LATIN-9', 'UTF-8', xml_request
    end
  end
end
