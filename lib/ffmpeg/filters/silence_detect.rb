# frozen_string_literal: true

require_relative '../filter'

module FFMPEG
  module Filters # rubocop:disable Style/Documentation
    class << self
      def silence_detect(threshold: nil, duration: nil, mono: nil)
        SilenceDetect.new(threshold:, duration:, mono:)
      end
    end

    # The SilenceDetect class uses the silencedetect filter
    # to detect silent parts in a multimedia stream.
    class SilenceDetect < Filter
      attr_reader :threshold, :duration, :mono

      def initialize(threshold: nil, duration: nil, mono: nil)
        if !threshold.nil? && !threshold.is_a?(Numeric) && !threshold.is_a?(String)
          raise ArgumentError, "Unknown threshold format #{threshold.class}, expected #{Numeric} or #{String}"
        end

        if !duration.nil? && !duration.is_a?(Numeric)
          raise ArgumentError, "Unknown duration format #{duration.class}, expected #{Numeric}"
        end

        if !mono.nil? && !mono.is_a?(TrueClass) && !mono.is_a?(FalseClass)
          raise ArgumentError, "Unknown mono format #{mono.class}, expected #{TrueClass} or #{FalseClass}"
        end

        @threshold = threshold
        @duration = duration
        @mono = mono

        super(:audio, 'silencedetect')
      end

      protected

      def format_kwargs
        super(n: @threshold, d: @duration, m: @mono)
      end
    end
  end
end
