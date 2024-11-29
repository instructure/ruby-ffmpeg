# frozen_string_literal: true

require_relative 'output'

module FFMPEG
  module Reporters
    # Represents the progress of an encoding operation.
    class Progress < Output
      def self.match?(line)
        line.match?(/^\s*frame=/)
      end

      # Returns the current frame number.
      #
      # @return [Integer, nil]
      def frame
        return @frame if instance_variable_defined?(:@frame)

        @frame ||= output[/^\s*frame=\s*(\d+)/, 1]&.to_i
      end

      # Returns the current frame rate (speed).
      #
      # @return [Float, nil]
      def fps
        return @fps if instance_variable_defined?(:@fps)

        @fps ||= output[/\s*fps=\s*(\d+(?!\.\d+)?)/, 1]&.to_f
      end

      # Returns the current size of the output file.
      #
      # @return [String, nil]
      def size
        return @size if instance_variable_defined?(:@size)

        @size ||= output[/\s*size=\s*(\S+)/, 1]
      end

      # Returns the current time within the media.
      #
      # @return [Float, nil]
      def time
        return @time if instance_variable_defined?(:@time)

        @time = if output =~ /time=(\d+):(\d+):(\d+.\d+)/
                  (::Regexp.last_match(1).to_i * 3600) +
                    (::Regexp.last_match(2).to_i * 60) +
                    ::Regexp.last_match(3).to_f
                end
      end

      # Returns the current bit rate.
      #
      # @return [String, nil]
      def bit_rate
        return @bit_rate if instance_variable_defined?(:@bit_rate)

        @bit_rate ||= output[/\s*bitrate=\s*(\S+)/, 1]
      end

      # Returns the current processing speed.
      #
      # @return [Float, nil]
      def speed
        return @speed if instance_variable_defined?(:@speed)

        @speed ||= output[/\s*speed=\s*(\d+(?:\.\d+)?)/, 1]&.to_f
      end
    end
  end
end
