# frozen_string_literal: true

require 'timeout'

module FFMPEG
  # The Timeout class is a simple wrapper around the Timeout module that
  # provides a more convenient API to handle timeouts in a loop.
  class Timeout
    def self.start(duration, message = nil)
      new(duration, message)
    end

    def pause
      @mutex.synchronize { @paused = true }
      nil
    end

    def resume
      @mutex.synchronize do
        @last_tick = Time.now
        @paused = false
        nil
      end
    end

    def tick
      @mutex.synchronize { @last_tick = Time.now }
      nil
    end

    def cancel
      return if @wait_thread.nil?

      @wait_thread.kill
      @wait_thread.join
    end

    private

    def initialize(duration, message = nil)
      @mutex = Mutex.new
      @duration = duration
      @message = message

      @last_tick = Time.now
      @current_thread = Thread.current
      @wait_thread = Thread.new { loop }
      @paused = false
    end

    def loop
      sleep 0.1 while @mutex.synchronize { @paused || Time.now - @last_tick <= @duration }

      @current_thread.raise(::Timeout::Error, @message || self.class.name)
    end
  end
end
