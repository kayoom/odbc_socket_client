module OdbcSocketClient
  class ConnectionString
    attr_reader :config

    def initialize config
      @config = config
    end

    def self.build config
      new(config).to_s
    end

    def to_s
      [provider, user, password, security_persistence, database, system_database, ''] * ";"
    end

    def provider
      "Provider=" + config[:provider].to_s
    end

    def user
      "User ID=" + config[:user].to_s
    end

    def password
      "Password=" + config[:password].to_s
    end

    def security_persistence
      "Persist Security Info=" + config[:persist_security_info].to_s
    end

    def database
      "Data Source=" + config[:database].to_s
    end

    def system_database
      "Jet OLEDB:System database=" + config[:system_database].to_s
    end
  end

end
