require 'socket'
require 'timeout'

module OdbcSocketClient
  class Connection
    include Timeout

    DEFAULT_PORT = 9628
    OPEN_TIMEOUT = 30
    QUERY_TIMEOUT = 3000
    class SocketOpenTimeoutError < Timeout::Error ; end
    class QueryTimeoutError < Timeout::Error ; end

    def initialize host, port = DEFAULT_PORT, open_timeout = OPEN_TIMEOUT, query_timeout = QUERY_TIMEOUT
      @host, @port, @open_timeout, @query_timeout = host, port, open_timeout, query_timeout
    end

    def socket &block
      socket = open_socket

      query socket, &block
    ensure
      socket && socket.close
    end

    protected
    def open_socket
      timeout @open_timeout , SocketOpenTimeoutError do
        TCPSocket.open @host, @port
      end
    end

    def query socket, &block
      timeout @query_timeout, QueryTimeoutError do
        block[socket]
      end
    end
  end
end
