# frozen_string_literal: true

require "securerandom"
require "oj"
require "yaml"

# TODO: use Oj directly
Oj.mimic_JSON
Oj.add_to_json

require "async"
require "async/pool"
require "async/pool/resource"
require "async/pool/controller"
require "async/queue"
require "async/barrier"
require "async/http/endpoint"
require "async/websocket/client"

require "retryable"

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.inflector.inflect(
  "rspec" => "RSpec",
  "db_cleaner_context" => "DBCleanerContext"
)

test_helpers = "#{__dir__}/grumlin/test"
loader.do_not_eager_load(test_helpers)

module Grumlin
  class Error < StandardError; end

  class TransactionError < Error; end
  class Rollback < TransactionError; end

  class UnknownError < Error; end

  class ConnectionError < Error; end

  class CannotConnectError < ConnectionError; end

  class DisconnectError < ConnectionError; end

  class ConnectionStatusError < Error; end

  class NotConnectedError < ConnectionStatusError; end

  class AlreadyConnectedError < ConnectionStatusError; end

  class ClientClosedError < ConnectionStatusError; end

  class ProtocolError < Error; end

  class UnknownResponseStatus < ProtocolError
    attr_reader :status

    def initialize(status)
      super("unknown response status code #{status[:code]}")
      @status = status
    end
  end

  class UnknownTypeError < ProtocolError; end

  class StatusError < Error
    attr_reader :status, :query

    def initialize(status, query)
      super(status[:message])
      @status = status
      @query = query
    end
  end

  class ClientSideError < StatusError; end

  class ServerSideError < StatusError; end

  class ScriptEvaluationError < ServerSideError; end

  class InvalidRequestArgumentsError < ServerSideError; end

  class ServerError < ServerSideError; end

  class AlreadyExistsError < ServerError
    attr_reader :id

    def initialize(status, query)
      super
      id = status[:message].split(":").last.strip
      @id = id == "" ? nil : id
    end

    # TODO: parse message and assign @id
    # NOTE: Neptune does not return id.
  end

  class VertexAlreadyExistsError < AlreadyExistsError; end
  class EdgeAlreadyExistsError < AlreadyExistsError; end

  class ConcurrentModificationError < ServerError; end
  class ConcurrentInsertFailedError < ConcurrentModificationError; end

  class ConcurrentVertexInsertFailedError < ConcurrentInsertFailedError; end
  class ConcurrentEdgeInsertFailedError < ConcurrentInsertFailedError; end

  class ConcurrentVertexPropertyInsertFailedError < ConcurrentInsertFailedError; end
  class ConcurrentEdgePropertyInsertFailedError < ConcurrentInsertFailedError; end

  class ServerSerializationError < ServerSideError; end

  class ServerTimeoutError < ServerSideError; end

  class InternalClientError < Error; end

  class UnknownRequestStoppedError < InternalClientError; end

  class ResourceLeakError < InternalClientError; end

  class UnknownMapKey < InternalClientError
    attr_reader :key, :map

    def initialize(key, map)
      @key = key
      @map = map
      super("Cannot cast key #{key} in map #{map}")
    end
  end

  class RepositoryError < Error; end

  class WrongQueryResult < RepositoryError; end

  @pool_mutex = Mutex.new

  class << self
    def configure
      yield config

      config.validate!
    end

    def config
      @config ||= Config.new
    end

    # returns a subset of features for currently configured backend.
    # The features lists are hardcoded as there is no way to get them
    # from the remote server.
    def features
      Features.for(config.provider) # no memoization as provider may be changed
    end

    def default_pool
      if Thread.current.thread_variable_get(:grumlin_default_pool)
        return Thread.current.thread_variable_get(:grumlin_default_pool)
      end

      @pool_mutex.synchronize do
        Thread.current.thread_variable_set(:grumlin_default_pool,
                                           Async::Pool::Controller.new(Grumlin::Client::PoolResource,
                                                                       limit: config.pool_size))
      end
    end

    def close
      return if Thread.current.thread_variable_get(:grumlin_default_pool).nil?

      @pool_mutex.synchronize do
        pool = Thread.current.thread_variable_get(:grumlin_default_pool)
        pool.wait while pool.busy?
        pool.close
        Thread.current.thread_variable_set(:grumlin_default_pool, nil)
      end
    end

    def definitions
      @definitions ||= YAML.safe_load(File.read(File.join(__dir__, "definitions.yml")), symbolize_names: true)
    end
  end
end

loader.setup
loader.eager_load
