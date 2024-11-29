# frozen_string_literal: true

require_relative '../filters/scale'
require_relative '../preset'

module FFMPEG
  # rubocop:disable Style/Documentation
  module Presets
    # rubocop:enable Style/Documentation
    class << self
      def thumbnail(
        name: 'JPEG thumbnail',
        filename: '%<basename>s.thumb.jpg',
        metadata: nil,
        max_width: nil,
        max_height: nil
      )
        Thumbnail.new(
          name:,
          filename:,
          metadata:,
          max_width: max_width,
          max_height: max_height
        )
      end
    end

    # Preset to create a thumbnail from a video.
    class Thumbnail < Preset
      attr_reader :max_width, :max_height

      # @param name [String] The name of the preset.
      # @param filename [String] The filename format of the output.
      # @param metadata [Hash] The metadata to associate with the preset.
      # @param max_width [Numeric] The maximum width of the thumbnail.
      # @param max_height [Numeric] The maximum height of the thumbnail.
      # @yield The block to execute to compose the command arguments.
      def initialize(name: nil, filename: nil, metadata: nil, max_width: nil, max_height: nil, &)
        if max_width && !max_width.is_a?(Numeric)
          raise ArgumentError, "Unknown max_width format #{max_width.class}, expected #{Numeric}"
        end

        if max_height && !max_height.is_a?(Numeric)
          raise ArgumentError, "Unknown max_height format #{max_height.class}, expected #{Numeric}"
        end

        @max_width = max_width
        @max_height = max_height
        preset = self

        super(name:, filename:, metadata:) do
          arg 'ss', (media.duration / 2).floor if media.duration.is_a?(Numeric)
          arg 'frames:v', 1
          filter preset.scale_filter(media)
        end
      end

      def scale_filter(media)
        return unless @max_width || @max_height

        Filters::Scale.contained(media, max_width: @max_width, max_height: @max_height)
      end
    end
  end
end
