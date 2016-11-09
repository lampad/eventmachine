require 'em_test_helper'
require 'socket'

class TestServers < Test::Unit::TestCase

  def setup
    @port = next_port
  end

  def server_alive?
    port_in_use?(@port)
  end

  def run_test_stop_server
    EM.run {
      sig = EM.start_server("127.0.0.1", @port)
      assert server_alive?, "Server didn't start"
      EM.stop_server sig
      # Give the server some time to shutdown.
      EM.add_timer(0.1) {
        assert !server_alive?, "Server didn't stop"
        EM.stop
      }
    }
  end

  def test_get_sock_name
    EM.run {
      sig = EM.start_server("127.0.0.1", @port)
      port_num = Socket.unpack_sockaddr_in(EM.get_sockname(sig)).first
      assert port_num == @port, "Didn't get the same port"
    }
  end

  def test_stop_server
    assert !server_alive?, "Port already in use"
    2.times { run_test_stop_server }
    assert !server_alive?, "Servers didn't stop"
  end

end
