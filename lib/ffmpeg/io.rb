# frozen_string_literal: true

require 'English'
require 'open3'

module FFMPEG
  # The IO module provides low-level methods for opening, capturing, and encoding
  # IO streams produced by the ffmpeg and ffprobe binaries.
  module IO
    class << self
      attr_writer :timeout, :encoding

      def timeout
        return @timeout if defined?(@timeout)

        @timeout = 30
      end

      def encoding
        @encoding ||= Encoding::UTF_8
      end

      def encode!(string)
        string.encode!(encoding, invalid: :replace, undef: :replace)
      end

      def extend!(io)
        io.timeout = timeout
        io.set_encoding(encoding, invalid: :replace, undef: :replace)
        io.extend(FFMPEG::IO)
      end

      def capture3(*cmd, **spawn_opts)
        *io, status = Open3.capture3(*cmd, **spawn_opts)
        io.each(&method(:encode!))
        [*io, status]
      end

      def popen3(*cmd, **spawn_opts, &block)
        if block_given?
          Open3.popen3(*cmd, **spawn_opts) do |*io, wait_thr|
            io = io.map(&method(:extend!))
            block.call(*io, wait_thr)
          rescue StandardError
            wait_thr.kill
            wait_thr.join
            raise
          end
        else
          *io, wait_thr = Open3.popen3(*cmd, **spawn_opts)
          io = io.map(&method(:extend!))
          [*io, wait_thr]
        end
      end
    end

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
