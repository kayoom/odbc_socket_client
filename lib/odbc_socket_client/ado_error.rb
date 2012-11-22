module OdbcSocketClient
  class AdoError < Exception
  end

  class TableLockedError < AdoError
    MATCH = /Table '(.*)' is exclusively locked by user '(.*)' on machine '(.*)'/
  end
end
