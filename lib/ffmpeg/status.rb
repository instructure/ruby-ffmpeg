# frozen_string_literal: true

module FFMPEG
  # The Status class represents the status of a ffmpeg process.
  # It wraps a Process::Status object and delegates method calls to it.
  # It also provides a method to raise an error if the subprocess
  # did not finish successfully.
  class Status
    attr_reader :duration, :output, :upstream

    def initialize
      @mutex = Mutex.new
      @output = StringIO.new
      @warnings = []
    end

    # Raises an error if the subprocess did not finish successfully.
    #
    # @return [self]
    # @raise [FFMPEG::ExitError] If the subprocess exited with a non-zero exit code.
    def assert!
      return self if success?

      message = @output.string.match(/\b(?:error|invalid|failed|could not)\b.+$/i)
      message ||= 'FFmpeg exited with non-zero exit status'

      raise ExitError.new("#{message} (code: #{exitstatus})", @output)
    end

    # Binds the status to an upstream Process::Status object.
    #
    # @yield The block whose return value is expected to be a Process::Status.
    # @return [self]
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

    # Returns a frozen copy of all warnings associated with this status.
    # Warnings are non-fatal messages added during processing, e.g. when an
    # optional post-processing step fails.
    #
    # @return [Array<String>]
    def warnings
      @warnings.dup.freeze
    end

    # Returns true if any warnings have been added to this status.
    #
    # @return [Boolean]
    def warnings? = !@warnings.empty?

    # Appends a warning message to this status.
    # Warnings are non-fatal and do not affect {#success?}.
    #
    # @param message [String] The warning message to add.
    # @return [Array<String>]
    def warn!(message)
      @warnings << message
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
