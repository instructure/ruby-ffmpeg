# frozen_string_literal: true

require 'English'
require 'timeout'

module FFMPEG
  # The IO class is a simple wrapper around IO objects that adds a timeout
  # to all read operations and fixes encoding issues.
  class IO
    attr_accessor :timeout

    def self.force_encoding(chunk)
      chunk[/test/]
    rescue ArgumentError
      chunk.force_encoding('ISO-8859-1')
    end

    def initialize(target)
      @target = target
    end

    %i[
      getc
      gets
      readchar
      readline
    ].each do |symbol|
      define_method(symbol) do |*args|
        Timeout.timeout(timeout) do
          output = @target.send(symbol, *args)
          self.class.force_encoding(output)
          output
        end
      end
    end

    %i[
      each
      each_char
      each_line
    ].each do |symbol|
      read = symbol == :each_char ? :getc : :gets
      define_method(symbol) do |*args, &block|
        until eof?
          output = send(read, *args)
          block.call(output)
        end
      end
    end

    def readlines(*args)
      lines = []
      lines << gets(*args) until eof?
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
