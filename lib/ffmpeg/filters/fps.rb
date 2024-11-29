# frozen_string_literal: true

require_relative '../filter'

module FFMPEG
  # rubocop:disable Style/Documentation
  module Filters
    # rubocop:enable Style/Documentation

    class << self
      def fps(frame_rate)
        FPS.new(frame_rate)
      end
    end

    # The FPS class uses the fps filter
    # to set the frame rate of a multimedia stream.
    class FPS < Filter
      attr_reader :frame_rate

      def initialize(frame_rate)
        unless frame_rate.is_a?(Numeric)
          raise ArgumentError,
                "Unknown frame_rate format #{frame_rate.class}, expected #{Numeric}"
        end

        @frame_rate = frame_rate

        super(:video, 'fps')
      end

      protected

      def format_kwargs
        @frame_rate.to_s
      end
    end
  end
end
