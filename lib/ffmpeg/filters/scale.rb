# frozen_string_literal: true

require_relative '../filter'

module FFMPEG
  module Filters # rubocop:disable Style/Documentation
    class << self
      def scale(
        width: nil,
        height: nil,
        algorithm: nil,
        in_color_space: nil,
        out_color_space: nil,
        in_color_range: nil,
        out_color_range: nil,
        in_color_primaries: nil,
        out_color_primaries: nil,
        in_color_transfer: nil,
        out_color_transfer: nil,
        in_chroma_location: nil,
        out_chroma_location: nil,
        force_original_aspect_ratio: nil,
        force_divisible_by: nil
      )
        Scale.new(
          width:,
          height:,
          algorithm:,
          in_color_space:,
          out_color_space:,
          in_color_range:,
          out_color_range:,
          in_color_primaries:,
          out_color_primaries:,
          in_color_transfer:,
          out_color_transfer:,
          in_chroma_location:,
          out_chroma_location:,
          force_original_aspect_ratio:,
          force_divisible_by:
        )
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
        # @param kwargs [Hash] Additional options for the scale filter.
        # @return [FFMPEG::Filters::Scale] The scale filter.
        def contained(media, max_width: nil, max_height: nil, **kwargs)
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
            new(width:, height:, **kwargs)
          elsif media.display_aspect_ratio > Rational(width, height)
            new(width:, height: -2, **kwargs)
          else
            new(width: -2, height:, **kwargs)
          end
        end
      end

      attr_reader :width, :height, :algorithm,
                  :in_color_space, :out_color_space,
                  :in_color_range, :out_color_range,
                  :in_color_primaries, :out_color_primaries,
                  :in_color_transfer, :out_color_transfer,
                  :in_chroma_location, :out_chroma_location,
                  :force_original_aspect_ratio, :force_divisible_by

      def initialize(
        width: nil,
        height: nil,
        algorithm: nil,
        in_color_space: nil,
        out_color_space: nil,
        in_color_range: nil,
        out_color_range: nil,
        in_color_primaries: nil,
        out_color_primaries: nil,
        in_color_transfer: nil,
        out_color_transfer: nil,
        in_chroma_location: nil,
        out_chroma_location: nil,
        force_original_aspect_ratio: nil,
        force_divisible_by: nil
      )
        if !width.nil? && !width.is_a?(Numeric) && !width.is_a?(String)
          raise ArgumentError, "Unknown width format #{width.class}, expected #{Numeric} or #{String}"
        end

        if !height.nil? && !height.is_a?(Numeric) && !height.is_a?(String)
          raise ArgumentError, "Unknown height format #{height.class}, expected #{Numeric} or #{String}"
        end

        @width = width
        @height = height
        @algorithm = algorithm
        @in_color_space = in_color_space
        @out_color_space = out_color_space
        @in_color_range = in_color_range
        @out_color_range = out_color_range
        @in_color_primaries = in_color_primaries
        @out_color_primaries = out_color_primaries
        @in_color_transfer = in_color_transfer
        @out_color_transfer = out_color_transfer
        @in_chroma_location = in_chroma_location
        @out_chroma_location = out_chroma_location
        @force_original_aspect_ratio = force_original_aspect_ratio
        @force_divisible_by = force_divisible_by

        super(:video, 'scale')
      end

      protected

      def format_kwargs
        super(
          w: @width,
          h: @height,
          flags: @algorithm && [@algorithm],
          in_color_matrix: @in_color_space,
          out_color_matrix: @out_color_space,
          in_range: @in_color_range,
          out_range: @out_color_range,
          in_primaries: @in_color_primaries,
          out_primaries: @out_color_primaries,
          in_transfer: @in_color_transfer,
          out_transfer: @out_color_transfer,
          in_chroma_loc: @in_chroma_location,
          out_chroma_loc: @out_chroma_location,
          force_original_aspect_ratio: @force_original_aspect_ratio,
          force_divisible_by: @force_divisible_by
        )
      end
    end
  end
end
