# frozen_string_literal: true

RSpec.describe Grumlin::Transaction, gremlin_server: true do
  let(:tx) { g.tx }

  before do
    Grumlin.config.provider = :neptune
  end

  describe "defaults" do
    it "has assigned uuid" do
      expect(tx.session_id).not_to be_nil
    end
  end

  describe "#begin" do
    subject { tx.begin }

    it "returns a TraversalStart session_id" do
      expect(subject).to be_a(Grumlin::TraversalStart)
      expect(subject.session_id).not_to be_nil
    end
  end

  describe "#commit" do
    subject { tx.commit }

    before do
      allow(SecureRandom).to receive(:uuid).and_return("529962d2-374b-4470-915f-cf452bead1be")
    end

    it "submits commit step" do
      expect_any_instance_of(Grumlin::Transport).to receive(:write).with( # rubocop:disable RSpec/AnyInstance, RSpec/StubbedMock no easier way
        { args: { aliases: { g: :g },
                  gremlin: { :@type => "g:Bytecode", :@value => { source: [%i[tx commit]] } },
                  session: "529962d2-374b-4470-915f-cf452bead1be" },
          op: :bytecode,
          processor: :session,
          requestId: "529962d2-374b-4470-915f-cf452bead1be" }
      ).and_raise(Async::Stop)
      # we raise a RuntimeError because otherwise client will be stuck waiting for the commit result
      # which are not sent on tinkergraph as it does not support transactions
      begin
        subject
      rescue Async::Stop
        nil
      end
    end
  end

  describe "#rollback" do
    subject { tx.rollback }

    before do
      allow(SecureRandom).to receive(:uuid).and_return("529962d2-374b-4470-915f-cf452bead1be")
    end

    it "submits commit step" do
      expect_any_instance_of(Grumlin::Transport).to receive(:write).with( # rubocop:disable RSpec/AnyInstance, RSpec/StubbedMock no easier way
        { args: { aliases: { g: :g },
                  gremlin: { :@type => "g:Bytecode", :@value => { source: [%i[tx rollback]] } },
                  session: "529962d2-374b-4470-915f-cf452bead1be" },
          op: :bytecode,
          processor: :session,
          requestId: "529962d2-374b-4470-915f-cf452bead1be" }
      ).and_raise(Async::Stop)
      # we raise a RuntimeError because otherwise client will be stuck waiting for the commit result
      # which are not sent on tinkergraph as it does not support transactions
      begin
        subject
      rescue Async::Stop
        nil
      end
    end
  end
end
