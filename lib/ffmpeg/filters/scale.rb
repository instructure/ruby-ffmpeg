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
      NEAREST_DIMENSION = -1
      NEAREST_EVEN_DIMENSION = -2

      class << self
        # Returns a scale filter that fits the specified media
        # within the specified maximum width and height,
        # keeping the original aspect ratio.
        #
        # @param media [FFMPEG::Media] The media to fit.
        # @param max_width [Numeric] The maximum width to fit.
        # @param max_height [Numeric] The maximum height to fit.
        # @return [FFMPEG::Filters::Scale] The scale filter.
        def contained(media, max_width: nil, max_height: nil)
          unless media.is_a?(FFMPEG::Media)
            raise ArgumentError,
                  "Unknown media format #{media.class}, expected #{FFMPEG::Media}"
          end

          if max_width && !max_width.is_a?(Numeric)
            raise ArgumentError,
                  "Unknown max_width format #{max_width.class}, expected #{Numeric}"
          end

          if max_height && !max_height.is_a?(Numeric)
            raise ArgumentError,
                  "Unknown max_height format #{max_height.class}, expected #{Numeric}"
          end

          return unless max_width || max_height

          if media.rotated?
            width = max_height || NEAREST_EVEN_DIMENSION
            height = max_width || NEAREST_EVEN_DIMENSION
          else
            width = max_width || NEAREST_EVEN_DIMENSION
            height = max_height || NEAREST_EVEN_DIMENSION
          end

          if width.negative? || height.negative?
            Filters.scale(width:, height:)
          elsif media.calculated_aspect_ratio > Rational(width, height)
            Filters.scale(width:, height: -2)
          else
            Filters.scale(width: -2, height:)
          end
        end
      end

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
