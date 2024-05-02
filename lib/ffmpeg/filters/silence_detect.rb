# frozen_string_literal: true

module FFMPEG
  module Filters
    # The SilenceDetect class is uses the silencedetect filter
    # to detect silent parts in a multimedia file.
    class SilenceDetect
      Range = Struct.new(:start, :end, :duration)

      include Filter

      attr_reader :threshold, :duration, :mono

      def initialize(threshold: nil, duration: nil, mono: false)
        if !threshold.nil? && !threshold.is_a?(Numeric) && !threshold.is_a?(String)
          raise ArgumentError, 'Unknown threshold format, should be either Numeric or String'
        end

        raise ArgumentError, 'Unknown duration format, should be Numeric' if !duration.nil? && !duration.is_a?(Numeric)

        @threshold = threshold
        @duration = duration
        @mono = mono
      end

      def self.scan(output)
        result = []

        output.scan(/silence_end: (\d+\.\d+) \| silence_duration: (\d+\.\d+)/) do
          e = Regexp.last_match(1).to_f
          d = Regexp.last_match(2).to_f
          result << Range.new(e - d, e, d)
        end

        result
      end

      def to_s
        args = []
        args << "n=#{@threshold}" if @threshold
        args << "d=#{@duration}" if @duration
        args << 'm=true' if @mono
        args.empty? ? 'silencedetect' : "silencedetect=#{args.join(':')}"
      end

      def to_a
        ['-af', to_s]
      end

      def scan(output)
        self.class.scan(output)
      end
    end
  end
end
