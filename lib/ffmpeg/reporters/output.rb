# frozen_string_literal: true

module FFMPEG
  module Reporters
    # Represents a raw output line from ffmpeg.
    class Output
      # Returns true — raw output lines are always logged.
      #
      # @return [Boolean]
      def self.log? = true

      # Returns true — this reporter matches every output line.
      #
      # @param _line [String]
      # @return [Boolean]
      def self.match?(_line) = true

      attr_reader :output

      # @param output [String] The raw output line from ffmpeg.
      def initialize(output)
        @output = output
      end

      # @return [String]
      def to_s
        output
      end
    end
  end
end
