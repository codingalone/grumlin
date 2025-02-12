# frozen_string_literal: true

RSpec.describe Grumlin::Transport, gremlin_server: true do
  let!(:transport) { described_class.new(Grumlin.config.url) }

  describe "when Async::WebSocket::Client#connect is not used" do
    it "successfully connects and disconnects" do
      transport.connect
      transport.close
    end
  end
end
