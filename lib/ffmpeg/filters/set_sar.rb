# frozen_string_literal: true

module FFMPEG
  module Filters # rubocop:disable Style/Documentation
    class << self
      def set_sar(sar) # rubocop:disable Naming/AccessorMethodName
        SetSAR.new(sar)
      end
    end

    # The SetSAR class uses the setsar filter
    # to set the sample aspect ratio of a multimedia stream.
    class SetSAR < Filter
      attr_reader :sar

      def initialize(sar)
        unless sar.is_a?(String) || sar.is_a?(Numeric)
          raise ArgumentError, "Unknown sar format #{sar.class}, expected #{String}"
        end

        @sar = sar

        super(:video, 'setsar')
      end

      protected

      def format_kwargs
        @sar.to_s
      end
    end
  end
end
