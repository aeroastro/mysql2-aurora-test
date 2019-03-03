# frozen_string_literal: true

require 'logger'

require 'securerandom'
require 'parallel'

require 'bank'
require 'simple_concurrency'

namespace :bank do # rubocop:disable Metrics/BlockLength
  desc 'Load MySQL concurrently'
  task :transfer, [:concurrency, :max_sleep, :aurora] do |_t, args| # rubocop:disable Metrics/BlockLength
    Bank.setup!

    concurrency = args[:concurrency]&.to_i || 10
    max_sleep = args[:max_sleep]&.to_f || 4.0
    client_class = args[:aurora] ? Mysql2::AWSAurora::Client : Mysql2::Client

    logger = Logger.new('log/bank_transfer.log')
    puts "Client: #{client_class}"
    puts "Concurrency: #{concurrency}"
    puts "Max sleep: #{max_sleep}"
    puts 'Balances before transfers'
    puts YAML.dump(Bank.fetch_report)
    puts 'Now starting transfers. Ctrl+C to stop.'

    ClientPool.with_client_class(client_class) do
      SimpleConcurrency.loop_until_sigint(concurrency: concurrency) do
        begin
          Bank.transfer_balance(to: "receiver_#{SecureRandom.hex(10)}", client_options: { reconnect: true }) do |_client1, _client2|
            sleep rand * max_sleep
          end
          print '.'
          logger.info('Success')
        rescue StandardError => e
          print 'F'
          logger.info("Error: #{e.class}: #{e.message}")
          sleep max_sleep / 10.0 # In order to avoid too heavy load under error
          next
        end
      end
    end

    puts "\nFinished"
    puts 'Balances after transfers'
    puts YAML.dump(Bank.fetch_report)
  end
end
