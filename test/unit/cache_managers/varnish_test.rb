require File.dirname(__FILE__) + "/../../test_helper.rb"

class UbiquoDesign::CacheManagers::VarnishTest < ActiveSupport::TestCase

  def setup
    @manager = UbiquoDesign::CacheManagers::Varnish
  end

  test 'should not raise exception when varnish is not available' do
    with_proxy_server do
      Rails.logger.expects(:warn)
      @manager.send(:varnish_request, 'BAN', '/')
    end
  end

  test 'should not raise exception when varnish requests raise a timeout' do
    with_proxy_server do
      Rails.logger.expects(:warn)
      s = Net::HTTP.new("foo").tap { |o|
        o.singleton_class.send(:define_method, :send_request) { raise Timeout::Error }
      }
      Net::HTTP.stubs(:new).returns(s)
      @manager.send(:varnish_request, 'BAN', '/')
    end
  end

  test 'should have configure connection and read timeouts' do
    Net::HTTP.any_instance.expects(:open_timeout=).with(Settings[:ubiquo_design][:varnish_request_timeout])
    Net::HTTP.any_instance.expects(:read_timeout=).with(Settings[:ubiquo_design][:varnish_request_timeout])
    with_proxy_server do
      @manager.send(:varnish_request, 'BAN', '/')
    end
  end

  protected

  def with_proxy_server
    ProxyServer.alive.first or ProxyServer.create(:host => '127.0.0.1', :port => '1')
    yield
  end

end
