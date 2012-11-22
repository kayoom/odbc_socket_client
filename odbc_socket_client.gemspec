Gem::Specification.new do |s|
  s.name = 'odbc_socket_client'
  s.version = "0.0.2"
  s.date = "2012-11-21"
  s.authors = ['Marian Theisen']
  s.email = 'marian@cice-online.net'
  s.summary = 'Rudimentary ActiveRecord ODBCSocketServer Adapter'
  s.homepage = 'www.cice-online.net'
  s.description = 'Rudimentary ActiveRecord ODBCSocketServer Adapter'

  s.files        =  Dir["**/*"] - 
                    Dir["coverage/**/*"] - 
                    Dir["rdoc/**/*"] - 
                    Dir["doc/**/*"] - 
                    Dir["sdoc/**/*"] - 
                    Dir["rcov/**/*"]

  s.require_path = 'lib'

  s.add_dependency 'nokogiri'
end
