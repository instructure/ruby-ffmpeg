# frozen_string_literal: true

require 'English'
require 'timeout'

module FFMPEG
  # The IO class is a simple wrapper around IO objects that adds a timeout
  # to all read operations and fixes encoding issues.
  class IO
    attr_accessor :timeout

    def self.encode!(chunk)
      chunk[/test/]
    rescue ArgumentError
      chunk.encode!(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '?')
    end

    def initialize(target)
      @target = target
    end

    def each(&block)
      timer = timeout.nil? ? nil : Timeout.start(timeout)
      buffer = String.new

      until eof?
        char = getc
        case char
        when "\n", "\r"
          timer&.tick
          timer&.pause
          block.call(buffer)
          timer&.resume
          buffer = String.new
        else
          buffer << char
        end
      end

      block.call(buffer) unless buffer.empty?
    ensure
      timer&.cancel
    end

    %i[
      getc
      gets
      readchar
      readline
    ].each do |symbol|
      define_method(symbol) do |*args|
        data = @target.send(symbol, *args)
        self.class.encode!(data) unless data.nil?
        data
      end
    end

    %i[
      each_char
      each_line
    ].each do |symbol|
      define_method(symbol) do |*args, &block|
        timer = timeout.nil? ? nil : Timeout.start(timeout)
        @target.send(symbol, *args) do |data|
          timer&.tick
          timer&.pause
          block.call(self.class.encode!(data))
          timer&.resume
        end
      ensure
        timer&.cancel
      end
    end

    def readlines(*args)
      lines = []
      each(*args) { |line| lines << line }
      lines
    end

    private

    def respond_to_missing?(symbol, include_private = false)
      @target.respond_to?(symbol, include_private)
    end

    def method_missing(symbol, *args)
      @target.send(symbol, *args)
    end
  end
end
