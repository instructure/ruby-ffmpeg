# frozen_string_literal: true

module FFMPEG
  class Error < StandardError; end

  # Raised by FFMPEG::Status#assert! if the underlying
  # process status has a non-zero exit code.
  class ExitError < Error
    attr_reader :output

    def initialize(message, output)
      @output = output
      super(message)
    end
  end
end
