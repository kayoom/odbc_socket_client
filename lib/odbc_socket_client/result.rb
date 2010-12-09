require 'nokogiri'
require 'active_support/ordered_hash'
require 'iconv'

module OdbcSocketClient
  class Result
    attr_accessor :status, :rows, :columns, :error
    
    def initialize xml_result
      @status = 'unknown'
      @rows = []
      
      parse iconv(xml_result)
    end
    
    def success?
      status.to_s == 'success'
    end
    
    def error?
      status.to_s == 'failure'
    end    
    
    protected
    def iconv xml_result
      Iconv.conv 'UTF-8', 'LATIN-9', xml_result
    end
    
    def parse xml_result
      doc = Nokogiri::XML.parse xml_result
      
      root_element = doc.xpath('/result').first
      
      @status = root_element.attr('state').to_s
      
      case @status
      when 'success'
        parse_rows root_element
      when 'failure'
        parse_error root_element
      end
    end
    
    def parse_error element
      @error = element.xpath('./error').first.try :text
    end
    
    def parse_rows element
      @rows = []
      
      row_nodes = element.element_children
      
      if first_row = row_nodes.first
        @columns = parse_columns first_row
      else
        return
      end
      
      row_nodes.each do |row|
        parse_row row
      end
    end
    
    def parse_row row
      current_row = {}
      column_number = 0
      
      @rows << current_row
      
      column_nodes = row.element_children
      
      column_nodes.each do |column|
        current_row[@columns[column_number]] = column.text
        column_number += 1
      end
    end
    
    def parse_columns row
      column_nodes = row.element_children
      
      [].tap do |columns|
        column_nodes.each do |column|
          name = column.attr 'name'
          
          columns << name.to_sym
        end        
      end      
    end
  end
end