require 'rexml/document'
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
      status.to_s == 'error'
    end    
    
    protected
    def iconv xml_result
      Iconv.conv 'UTF-8', 'LATIN-9', xml_result
    end
    
    def parse xml_result
      doc = REXML::Document.new xml_result
      
      root_element = doc.root
      
      @status = root_element.attribute('state').value
      
      case @status
      when 'success'
        parse_rows root_element
      when 'failure'
        parse_error root_element
      end
    end
    
    def parse_error element
      @error = element[1].text
    end
    
    def parse_rows element
      @rows = []
      
      if first_row = element[1]
        @columns = parse_columns first_row
      else
        return
      end
      
      element.each_element 'row' do |row|
        parse_row row
      end
    end
    
    def parse_row row
      current_row = {}
      column_number = 0
      
      @rows << current_row
      row.each_element 'column' do |column|
        current_row[@columns[column_number]] = column.text
        column_number += 1
      end
    end
    
    def parse_columns row
      [].tap do |columns|
        row.each_element 'column' do |column|
          name = column.attribute('name').value
          
          columns << name.to_sym
        end        
      end      
    end
  end
end