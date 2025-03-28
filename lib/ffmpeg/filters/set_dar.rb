# frozen_string_literal: true

module FFMPEG
  module Filters # rubocop:disable Style/Documentation
    class << self
      def set_dar(dar) # rubocop:disable Naming/AccessorMethodName
        SetDAR.new(dar)
      end
    end

    # The SetDAR class uses the setdar filter
    # to set the display aspect ratio of a multimedia stream.
    class SetDAR < Filter
      attr_reader :dar

      def initialize(dar)
        unless dar.is_a?(String) || dar.is_a?(Numeric)
          raise ArgumentError, "Unknown dar format #{dar.class}, expected #{String} or #{Numeric}"
        end

        @dar = dar

        super(:video, 'setdar')
      end

      protected

      def format_kwargs
        @dar.to_s
      end
    end
  end
end
