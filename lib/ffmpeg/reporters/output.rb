# frozen_string_literal: true

module FFMPEG
  module Reporters
    # Represents a raw output line from ffmpeg.
    class Output
      def self.match?(_line) = true

      attr_reader :output

      def initialize(output)
        @output = output
      end

      def to_s
        output
      end
    end
  end
end
