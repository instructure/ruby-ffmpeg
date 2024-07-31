# frozen_string_literal: true

require_relative 'output'

module FFMPEG
  module Reporters
    class Progress < Output
      def self.match?(line)
        line =~ /^\s*frame=/ ? true : false
      end

      def frame
        return @frame if instance_variable_defined?(:@frame)

        @frame ||= output[/^\s*frame=\s*(\d+)/, 1]&.to_i
      end

      def fps
        return @fps if instance_variable_defined?(:@fps)

        @fps ||= output[/\s*fps=\s*(\d+(?!\.\d+)?)/, 1]&.to_f
      end

      def size
        return @size if instance_variable_defined?(:@size)

        @size ||= output[/\s*size=\s*(\S+)/, 1]
      end

      def time
        return @time if instance_variable_defined?(:@time)

        @time = if output =~ /time=(\d+):(\d+):(\d+.\d+)/
                  (::Regexp.last_match(1).to_i * 3600) +
                    (::Regexp.last_match(2).to_i * 60) +
                    ::Regexp.last_match(3).to_f
                end
      end

      def bit_rate
        return @bit_rate if instance_variable_defined?(:@bit_rate)

        @bit_rate ||= output[/\s*bitrate=\s*(\S+)/, 1]
      end

      def speed
        return @speed if instance_variable_defined?(:@speed)

        @speed ||= output[/\s*speed=\s*(\d+(?!\.\d+)?)/, 1]&.to_f
      end
    end
  end
end
