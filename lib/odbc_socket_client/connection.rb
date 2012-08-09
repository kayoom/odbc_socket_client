require 'socket'
require 'system_timer'

module OdbcSocketClient
  class Connection
    include Timeout

    DEFAULT_PORT = 9628
    OPEN_TIMEOUT = 30
    QUERY_TIMEOUT = 300
    class SocketOpenTimeoutError < Exception ; end
    class QueryTimeoutError < Exception ; end

    def initialize host, port = DEFAULT_PORT, open_timeout = OPEN_TIMEOUT, query_timeout = QUERY_TIMEOUT
      @host, @port, @open_timeout, @query_timeout = host, port, OPEN_TIMEOUT, QUERY_TIMEOUT
    end

    def socket &block
      socket = open_socket

      query socket, &block
    ensure
      socket && socket.close
    end

    protected
    def open_socket
      SystemTimer.timeout_after(OPEN_TIMEOUT, SocketOpenTimeoutError) do
        TCPSocket.open @host, @port
      end
    end

    def query socket, &block
      SystemTimer.timeout_after(QUERY_TIMEOUT, QueryTimeoutError) do
        block[socket]
      end
    end
  end
end
