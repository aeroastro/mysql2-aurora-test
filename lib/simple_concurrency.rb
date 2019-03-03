# frozen_string_literal: true

class SimpleConcurrency
  QUEUE_FILL_CHECK_INTERVAL = 0.1
  QUEUE_BUFFER_SAFETY_RATIO = 10

  def self.loop_until_sigint(concurrency:)
    challenge_queue, enq_thread = generate_challenge_queue_with_enq_thread(concurrency)

    Signal.trap(:SIGINT) do
      puts '\nReceived SIGINT, now shutting down......'
      enq_thread.kill
    end

    Parallel.map(-> { challenge_queue.pop || Parallel::Stop }, in_threads: concurrency) do
      yield
    end
  end

  def self.generate_challenge_queue_with_enq_thread(concurrency)
    challenge_queue = Queue.new
    enq_thread = Thread.new do
      Thread.current[:target_buffer_size] = concurrency * QUEUE_BUFFER_SAFETY_RATIO
      Thread.current[:prev_buffer_size] = 0
      begin
        loop do
          current_buffer_size = challenge_queue.size
          Thread.current[:target_buffer_size] = [
            (Thread.current[:prev_buffer_size] - current_buffer_size) * QUEUE_BUFFER_SAFETY_RATIO,
            concurrency
          ].max
          Thread.current[:prev_buffer_size] = current_buffer_size

          ((Thread.current[:target_buffer_size] - current_buffer_size)).times { challenge_queue << 1 }
          sleep QUEUE_FILL_CHECK_INTERVAL
        end
      ensure
        challenge_queue.clear
        challenge_queue.close
      end
    end

    [challenge_queue, enq_thread]
  end
  private_class_method :generate_challenge_queue_with_enq_thread
end
