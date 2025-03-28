# frozen_string_literal: true

module FFMPEG
  module Filters # rubocop:disable Style/Documentation
    class << self
      def format(pixel_formats: nil, color_spaces: nil, color_ranges: nil)
        Format.new(pixel_formats:, color_spaces:, color_ranges:)
      end
    end

    # The Format class uses the format filter
    # to set the pixel format, color space, and color range of a multimedia stream.
    class Format < Filter
      attr_reader :pixel_formats, :color_spaces, :color_ranges

      def initialize(pixel_formats: nil, color_spaces: nil, color_ranges: nil)
        if pixel_formats.nil? && color_spaces.nil? && color_ranges.nil?
          raise ArgumentError, 'At least one of pixel_formats, color_spaces, or color_ranges must be set'
        end

        unless pixel_formats.nil? || pixel_formats.is_a?(String) || pixel_formats.is_a?(Array)
          raise ArgumentError, "Unknown pixel_formats format #{pixel_formats.class}, expected #{String} or #{Array}"
        end

        unless color_spaces.nil? || color_spaces.is_a?(String) || color_spaces.is_a?(Array)
          raise ArgumentError, "Unknown color_spaces format #{color_spaces.class}, expected #{String} or #{Array}"
        end

        unless color_ranges.nil? || color_ranges.is_a?(String) || color_ranges.is_a?(Array)
          raise ArgumentError, "Unknown color_ranges format #{color_ranges.class}, expected #{String} or #{Array}"
        end

        @pixel_formats = pixel_formats
        @color_spaces = color_spaces
        @color_ranges = color_ranges

        super(:video, 'format')
      end

      protected

      def format_kwargs
        super(
          pix_fmts: @pixel_formats,
          color_spaces: @color_spaces,
          color_ranges: @color_ranges
        )
      end
    end
  end
end
