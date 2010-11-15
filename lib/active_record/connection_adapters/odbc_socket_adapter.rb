require 'active_record/connection_adapters/abstract_adapter'

module ActiveRecord
  class Base
    class ColumnMapper
      def initialize mapping
        @mapping = mapping
      end
      
      %w(string integer float decimal datetime date timestamp time binary boolean text).each do |type|
        define_method type do |column_name, attribute_name|
          @mapping[column_name.to_sym] = ConnectionAdapters::MappedColumn.new(attribute_name, nil, type).tap do |c|
            c.sql_column_name = column_name.to_s
          end
        end
      end
    end
    
    
    class_attribute :column_mapping
    
    class << self
      def odbc_socket_connection config
        ConnectionAdapters::OdbcSocketAdapter.new config, logger
      end
    
      def map_columns &block
        self.column_mapping = {}
        block.call ColumnMapper.new(self.column_mapping)
        
        @columns = column_mapping.values
        class_eval <<-RUBY
          def self.instantiate record
            super remap(record)
          end
          
          def self.arel_table
            @arel_table ||= Arel::Table.new(table_name, arel_engine).tap do |t|
              t.instance_variable_set :@columns, column_mapping.values
            end
          end
        RUBY
      end
      
      def remap record
        attributes = {}
        
        record.each do |column_name, value|
          if column = column_mapping[column_name.to_sym]
            attributes[column.name.to_s] = value
          else
            attributes[column_name.to_s] = value
          end
        end
        
        attributes
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class MappedColumn < Column
      attr_accessor :sql_column_name
    end
    
    class OdbcSocketAdapter < AbstractAdapter
      ADAPTER_NAME = 'OdbcSocket'.freeze
      TABLES_QUERY = "SELECT * FROM MSysObjects WHERE (MSysObjects.Type = 1 AND left(MSysObjects.Name, 4) <> 'MSys');".freeze
      TABLE_NAME_COLUMN = :Name
    
      def initialize config, logger = nil
        @client = OdbcSocketClient::Client.new config, logger
        super @client, logger
      end
      
      def tables
        @tables ||= load_tables
      end      
      
      def table_exists? table_name
        tables.include? table_name.to_s
      end
    
      def adapter_name
        ADAPTER_NAME
      end    
      
      def select sql, name = nil
        @client.execute_query(sql).rows
      end
      
      protected
      def load_tables        
        @client.execute_query(TABLES_QUERY).rows.map do |table|
          table[TABLE_NAME_COLUMN]
        end
      end
    end    
  end  
end