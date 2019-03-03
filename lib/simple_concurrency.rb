class SimpleConcurrency
  def self.loop_until_sigint(concurrency:, interval:)
    queue_buffer_length = (concurrency / interval * 10).to_i

    challenge_queue = Queue.new
    enq_thread = Thread.new do
      begin
        loop do
          (queue_buffer_length - challenge_queue.length).times { challenge_queue << 1 }
          sleep interval
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

    Parallel.map(-> { challenge_queue.pop || Parallel::Stop }, in_threads: concurrency) do
      yield
    end
  end
end
