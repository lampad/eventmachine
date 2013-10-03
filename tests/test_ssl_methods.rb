require 'em_test_helper'

class TestSSLMethods < Test::Unit::TestCase
  def setup
      $dir = File.dirname(File.expand_path(__FILE__)) + '/'
      $client_cert_from_file = File.read($dir+'client.crt')
      $server_cert_from_file = File.read($dir+'server.crt')
  end

  module ServerHandler
    def post_init
      start_tls(:private_key_file => $dir+'server.key', :cert_chain_file => $dir+'server.crt', :verify_peer => true)
    end

    def ssl_handshake_completed
      $server_called_back = true
      $server_cert_value = get_peer_cert
      $server_cipher_bits = get_cipher_bits
      $server_cipher_name = get_cipher_name
      $server_cipher_protocol = get_cipher_protocol
    end

    def ssl_verify_peer cert
      true
    end
  end

  module ClientHandler
    def post_init
      start_tls(:private_key_file => $dir+'client.key', :cert_chain_file => $dir+'client.crt')
    end

    def ssl_handshake_completed
      $client_called_back = true
      $client_cert_value = get_peer_cert
      $client_cipher_bits = get_cipher_bits
      $client_cipher_name = get_cipher_name
      $client_cipher_protocol = get_cipher_protocol
      EM.stop_event_loop
    end
  end

  def test_ssl_methods
    omit_unless(EM.ssl?)
    omit_if(rbx?)
    $server_called_back, $client_called_back = false, false
    $server_cert_value, $client_cert_value = nil, nil
    $server_cipher_bits, $client_cipher_bits = nil, nil
    $server_cipher_name, $client_cipher_name = nil, nil
    $server_cipher_protocol, $client_cipher_protocol = nil, nil

    EM.run {
      EM.start_server("127.0.0.1", 9999, ServerHandler)
      EM.connect("127.0.0.1", 9999, ClientHandler)
    }

    assert($server_called_back)
    assert($client_called_back)


    assert_equal($server_cert_from_file, $server_cert_value.gsub("\r", ""))
    assert_equal($client_cert_from_file, $client_cert_value.gsub("\r", ""))
    assert($client_cipher_bits > 0)
    assert_equal($client_cipher_bits, $server_cipher_bits)

    assert($client_cipher_name.length > 0)
    assert_match(/AES/, $client_cipher_name)
    assert_equal($client_cipher_name, $server_cipher_name)

    assert_match(/TLS/, $client_cipher_protocol)
    assert_equal($client_cipher_protocol, $server_cipher_protocol)
  end

end if EM.ssl?
