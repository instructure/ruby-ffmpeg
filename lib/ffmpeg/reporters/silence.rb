# frozen_string_literal: true

require_relative 'output'

module FFMPEG
  module Reporters
    # Represents a silence report from ffmpeg.
    class Silence < Output
      def self.match?(line)
        line =~ /^\[silencedetect @ \w+\]/ ? true : false
      end

      # Returns the ID of the filter.
      #
      # @return [String, nil]
      def filter_id
        output[/^\[silencedetect @ (\w+)\]/, 1]
      end

      # Returns the start time of the silence.
      #
      # @return [Float, nil]
      def start
        return @start if instance_variable_defined?(:@start)

        @start ||= output[/silence_start: (\d+(?:\.\d+)?)/, 1]&.to_f
      end

      # Returns the end time of the silence.
      #
      # @return [Float, nil]
      def end
        return @end if instance_variable_defined?(:@end)

        @end ||= output[/silence_end: (\d+(?:\.\d+)?)/, 1]&.to_f
      end

      # Returns the duration of the silence.
      #
      # @return [Float, nil]
      def duration
        return @duration if instance_variable_defined?(:@duration)

        @duration ||= output[/silence_duration: (\d+(?:\.\d+)?)/, 1]&.to_f
      end
    end
  end
end
