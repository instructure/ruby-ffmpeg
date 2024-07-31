# frozen_string_literal: true

require_relative '../filter'

module FFMPEG
  # rubocop:disable Style/Documentation
  module Filters
    # rubocop:enable Style/Documentation

    class << self
      def scale(width: nil, height: nil, force_original_aspect_ratio: nil, flags: nil)
        Scale.new(width:, height:, force_original_aspect_ratio:, flags:)
      end
    end

    # The Scale class uses the scale filter
    # to resize a multimedia stream.
    class Scale < Filter
      attr_reader :width, :height, :force_original_aspect_ratio, :flags

      def initialize(width: nil, height: nil, force_original_aspect_ratio: nil, flags: nil)
        if !width.nil? && !width.is_a?(Numeric) && !width.is_a?(String)
          raise ArgumentError, "Unknown width format #{width.class}, expected #{Numeric} or #{String}"
        end

        if !height.nil? && !height.is_a?(Numeric) && !height.is_a?(String)
          raise ArgumentError, "Unknown height format #{height.class}, expected #{Numeric} or #{String}"
        end

        if !force_original_aspect_ratio.nil? && !force_original_aspect_ratio.is_a?(String)
          raise ArgumentError,
                "Unknown force_original_aspect_ratio format #{force_original_aspect_ratio.class}, expected #{String}"
        end

        if !flags.nil? && !flags.is_a?(Array)
          raise ArgumentError, "Unknown flags format #{flags.class}, expected #{Array}"
        end

        @width = width
        @height = height
        @force_original_aspect_ratio = force_original_aspect_ratio
        @flags = flags

        super(:video, 'scale')
      end

      protected

      def format_kwargs
        super(
          w: @width,
          h: @height,
          force_original_aspect_ratio: @force_original_aspect_ratio,
          flags: @flags
        )
      end
    end
  end
end
