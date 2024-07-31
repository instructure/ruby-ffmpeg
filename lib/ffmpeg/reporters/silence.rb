# frozen_string_literal: true

require_relative 'output'

module FFMPEG
  module Reporters
    class Silence < Output
      def self.match?(line)
        line =~ /silence_start|silence_end/ ? true : false
      end

      def start
        return @start if instance_variable_defined?(:@start)

        @start ||= output[/silence_start: (\d+(?!\.\d+)?)/, 1]&.to_f
      end

      def end
        return @end if instance_variable_defined?(:@end)

        @end ||= output[/silence_end: (\d+(?!\.\d+)?)/, 1]&.to_f
      end

      def duration
        return @duration if instance_variable_defined?(:@duration)

        @duration ||= output[/silence_duration: (\d+(?!\.\d+)?)/, 1]&.to_f
      end
    end
  end
end
