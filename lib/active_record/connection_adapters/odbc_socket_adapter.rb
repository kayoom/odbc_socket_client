require 'active_record/connection_adapters/abstract_adapter'

module ActiveRecord
  module ColumnMapping
    def instantiate record
      super remap(record)
    end
    
    def remap_sql sql
      # Hack to support Jet SQL's idiotic TOP 10 syntax
      if limit = sql.match(/LIMIT (\d+)/)
        limit_clause, limit = limit.to_a[0,2]
    
        sql.sub! limit_clause, ''
        sql.sub! 'SELECT', "SELECT TOP #{limit}"
      end
  
      # Column mapping hack, i should've based this on DataMapper...
      sql.gsub! /#{table_name}\.([a-zA-Z0-9_]+)/ do |match|
        column_name = $1
        column = columns.find {|c| c.name.to_s == column_name}

        if column
          "#{table_name}.#{column.sql_column_name.to_s}"
        else
          "#{table_name}.#{column_name}"
        end
      end
  
      sql
    end
    
    def find_by_sql sql, *args
      super remap_sql(sql.to_sql), *args
    end
    
    def count_by_sql sql
      super remap_sql(sql)
    end
    
    def remap record
      attributes = {}
      
      record.each do |column_name, value|
        if column = column_mapping[column_name.to_s]
          attributes[column.name.to_s] = value
        else
          attributes[column_name.to_s] = value
        end
      end
      
      attributes
    end
  end
  
  class Base
    class ColumnMapper
      def initialize mapping
        @mapping = mapping
      end
      
      %w(string integer float decimal datetime date timestamp time binary boolean text).each do |type|
        define_method type do |column_name, attribute_name|
          @mapping[column_name.to_s] = ConnectionAdapters::MappedColumn.new(attribute_name.to_s, nil, type).tap do |c|
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
      
      def map_primary_key name
        connection.set_primary_key self, name
        
        set_primary_key name
      end
      
      def map_columns options = {}, &block
        options = {
          :default_scope => true
        }.merge(options)
        
        self.column_mapping = {}
        block.call ColumnMapper.new(self.column_mapping)
        
        connection.table_columns[table_name.to_s] = column_mapping.values
        
        default_scope select(column_mapping.keys) if options[:default_scope]
        
        extend ColumnMapping
      end
      
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class MappedColumn < Column
      module Format
        MS_ACCESS_DATETIME = /\A(\d{4})-(\d\d)-(\d\d) (\d\d?):(\d\d?):(\d\d?)(\.\d+)?\z/
      end
      
      attr_accessor :sql_column_name
      
      def self.fast_string_to_time string
        if string =~ Format::MS_ACCESS_DATETIME
          microsec = ($7.to_f * 1_000_000).to_i
          new_time $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, microsec
        end
      end
    end
    
    class OdbcSocketAdapter < AbstractAdapter
      attr_accessor :table_columns, :primary_keys
      ADAPTER_NAME = 'OdbcSocket'.freeze
      TABLES_QUERY = "SELECT * FROM MSysObjects WHERE (MSysObjects.Type = 1 AND left(MSysObjects.Name, 4) <> 'MSys');".freeze
      TABLE_NAME_COLUMN = :Name
    
      def initialize config, logger = nil
        @client = OdbcSocketClient::Client.new config, logger
        super @client, logger
        
        @table_columns = {}
        @primary_keys = {}
      end
      
      def tables
        @tables ||= load_tables
      end      
      
      def table_exists? table_name
        tables.include? table_name.to_s
      end
      
      def set_primary_key table, key
        @primary_keys ||= {}
        
        @primary_keys[table.table_name.to_s] = key.to_s
      end
      
      def primary_key table_name
        @primary_keys[table_name.to_s]
      end
      
      def quoted_true
        "True"
      end

      def quoted_false
        "False"
      end
    
      def adapter_name
        ADAPTER_NAME
      end    
      
      def quote(value, column = nil)
        # records are quoted as their primary key
        return value.quoted_id if value.respond_to?(:quoted_id)

        case value
          when String, ActiveSupport::Multibyte::Chars
            value = value.to_s
            if column && column.type == :binary && column.class.respond_to?(:string_to_binary)
              "'#{quote_string(column.class.string_to_binary(value))}'" # ' (for ruby-mode)
            elsif column && [:integer, :float].include?(column.type)
              value = column.type == :integer ? value.to_i : value.to_f
              value.to_s
            else
              "'#{quote_string(value)}'" # ' (for ruby-mode)
            end
          when NilClass                 then "NULL"
          when TrueClass                then (column && column.type == :integer ? '1' : quoted_true)
          when FalseClass               then (column && column.type == :integer ? '0' : quoted_false)
          when Float, Fixnum, Bignum    then value.to_s
          # BigDecimals need to be output in a non-normalized form and quoted.
          when BigDecimal               then value.to_s('F')
          else
            if value.acts_like?(:date) || value.acts_like?(:time)
              "#{quoted_date(value)}"
            else
              "'#{quote_string(value.to_s)}'"
            end
        end
      end
      
      def quoted_date value
        "##{value.strftime("%Y-%m-%d")}#"
      end
      
      def columns table_name, whatever = nil
        @table_columns[table_name.to_s]
      end
      
      def select sql, name = nil, binds = []
        result = @client.execute_query(sql)
        
        raise result.error if result.error?
        
        result.rows
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