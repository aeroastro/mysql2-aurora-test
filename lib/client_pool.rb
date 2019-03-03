# frozen_string_literal: true

require 'mysql2'
require 'mysql2/awsaurora'
require 'yaml'

class ClientPool
  YAML_PATH = 'database.yml'

  def self.client_class
    @client_class ||= Mysql2::Client
  end

  def self.with_client_class(klass)
    prev_klass = @client_class
    @client_class = klass
    yield
  ensure
    @client_class = prev_klass
  end

  def self.setup!
    reload_default_options!
  end

  def self.reload_default_options!
    @default_options = nil
    default_options
  end

  def self.default_options
    @default_options ||= YAML.safe_load(File.read(YAML_PATH))
  end

  def initialize(options = {})
    @options = self.class.default_options.dup.tap do |opt|
      options.each { |k, v| opt[k.to_s] = v }
    end
  end

  def with_clients(&block)
    clients = Array.new(block.arity) { self.class.client_class.new(@options) }
    yield(*clients)
  ensure
    clients&.each(&:close)
  end
end
