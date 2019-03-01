# frozen_string_literal: true

require 'logger'

require 'securerandom'
require 'parallel'

require 'bank'

namespace :bank do # rubocop:disable Metrics/BlockLength
  desc 'Load MySQL concurrently'
  task :transfer, [:concurrency] do |_t, args| # rubocop:disable Metrics/BlockLength
    Bank.setup!

    concurrency = args[:concurrency] ? args[:concurrency].to_i : 10
    max_sleep = 4.0
    queue_buffer_length = concurrency * 10

    logger = Logger.new('log/bank_transfer.log')
    challenge_queue = Queue.new
    enq_thread = Thread.new do
      begin
        loop do
          (queue_buffer_length - challenge_queue.length).times { challenge_queue << 1 }
          sleep max_sleep
        end
      ensure
        challenge_queue.clear
        challenge_queue.close
      end
    end

    Signal.trap(:SIGINT) do
      puts '\nReceived SIGINT, now shutting down......'
      enq_thread.kill
    end

    puts "Concurrency: #{concurrency}"
    puts 'Balances before transfers'
    puts YAML.dump(Bank.fetch_report)
    puts 'Now starting transfers. Ctrl+C to stop.'

    Parallel.map(-> { challenge_queue.pop || Parallel::Stop }, in_threads: concurrency) do
      begin
        # Signal.trap(:SIGINT, :IGNORE) # ignore signal in child process (This is what this code was in multi processes)

        Bank.transfer_balance(to: "receiver_#{SecureRandom.hex(10)}", client_options: { reconnect: true }) do |_client1, _client2|
          sleep rand * max_sleep
        end
        print '.'
        logger.debug('Success')
      rescue StandardError => e
        print 'F'
        logger.debug("Error: #{e.class}: #{e.message}")
        sleep max_sleep / 10.0 # In order to avoid too heavy load under error
        next
      end
    end

    puts "\nFinished"
    puts 'Balances after transfers'
    puts YAML.dump(Bank.fetch_report)
  end
end
