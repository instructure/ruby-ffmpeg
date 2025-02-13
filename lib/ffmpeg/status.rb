# frozen_string_literal: true

module FFMPEG
  # The Status class represents the status of a ffmpeg process.
  # It inherits all methods from the Process::Status class.
  # It also provides a method to raise an error if the subprocess
  # did not finish successfully.
  class Status
    # Raised by #assert! if the status has a non-zero exit code.
    class ExitError < Error
      attr_reader :output

      def initialize(message, output)
        @output = output
        super(message)
      end
    end

    attr_reader :duration, :output, :upstream

    def initialize
      @mutex = Mutex.new
      @output = StringIO.new
    end

    # Raises an error if the subprocess did not finish successfully.
    def assert!
      return self if success?

      message = @output.string.match(/\b(?:error|invalid|failed|could not)\b.+$/i)
      message ||= 'FFmpeg exited with non-zero exit status'

      raise ExitError.new("#{message} (code: #{exitstatus})", @output.string)
    end

    # Binds the status to an upstream Process::Status object.
    def bind!
      @mutex.synchronize do
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @upstream = yield
        t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @duration = t1 - t0
        @output.close_write

        freeze
      end
    end

    private

    def respond_to_missing?(symbol, include_private)
      @upstream.respond_to?(symbol, include_private)
    end

    def method_missing(symbol, *args)
      @upstream.send(symbol, *args)
    end
  end
end
