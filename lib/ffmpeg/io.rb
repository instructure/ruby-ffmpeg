# frozen_string_literal: true

require 'English'
require 'open3'

module FFMPEG
  # The IO module provides low-level methods for opening, capturing, and encoding
  # IO streams produced by the ffmpeg and ffprobe binaries.
  module IO
    class << self
      attr_writer :timeout, :encoding

      # Returns the I/O timeout in seconds. Defaults to 30.
      #
      # @return [Integer]
      def timeout
        return @timeout if defined?(@timeout)

        @timeout = 30
      end

      # Returns the I/O encoding. Defaults to UTF-8.
      #
      # @return [Encoding]
      def encoding
        @encoding ||= Encoding::UTF_8
      end

      # Encodes the string in-place using the configured encoding,
      # replacing invalid and undefined characters.
      #
      # @param string [String] The string to encode.
      # @return [String]
      def encode!(string)
        string.encode!(encoding, invalid: :replace, undef: :replace)
      end

      # Extends the given IO object with the configured timeout, encoding,
      # and the FFMPEG::IO module.
      #
      # @param io [IO] The IO object to extend.
      # @return [IO]
      def extend!(io)
        io.timeout = timeout
        io.set_encoding(encoding, invalid: :replace, undef: :replace)
        io.extend(FFMPEG::IO)
      end

      # Runs the given command and captures stdout, stderr, and the process status.
      # Encodes the output using the configured encoding.
      #
      # @param cmd [Array<String>] The command to run.
      # @return [Array<String, Process::Status>] stdout, stderr, and the process status.
      def capture3(*cmd)
        *io, status = Open3.capture3(*cmd)
        io.each(&method(:encode!))
        [*io, status]
      end

      # Starts the given command and yields or returns stdin, stdout, stderr, and the wait thread.
      # Each IO stream is extended with the configured timeout and encoding.
      #
      # @param cmd [Array<String>] The command to run.
      # @yieldparam stdin [IO]
      # @yieldparam stdout [FFMPEG::IO]
      # @yieldparam stderr [FFMPEG::IO]
      # @yieldparam wait_thr [Thread]
      # @return [Process::Status, Array<IO, Thread>]
      def popen3(*cmd, &block)
        if block_given?
          Open3.popen3(*cmd) do |*io, wait_thr|
            io = io.map(&method(:extend!))
            block.call(*io, wait_thr)
          rescue StandardError
            wait_thr.kill
            wait_thr.join
            raise
          end
        else
          *io, wait_thr = Open3.popen3(*cmd)
          io = io.map(&method(:extend!))
          [*io, wait_thr]
        end
      end
    end

    # Iterates over each line of the IO stream, yielding each line to the block.
    #
    # @param chomp [Boolean] Whether to include the line separator in each yielded line.
    # @yieldparam line [String] Each line from the stream.
    def each(chomp: false, &block)
      # We need to run this loop in a separate thread to avoid
      # errors with exit signals being sent to the main thread.
      Thread.new do
        Thread.current.report_on_exception = false

        buffer = String.new

        until eof?
          char = getc
          case char
          when "\r", "\n"
            buffer << ($ORS || "\n") unless chomp
            block.call(buffer) unless buffer.empty?
            buffer.clear
          else
            buffer << FFMPEG::IO.encode!(char)
          end
        end

        block.call(buffer) unless buffer.empty?
      end.value
    end
  end
end
