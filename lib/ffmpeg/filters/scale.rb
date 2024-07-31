# frozen_string_literal: true

require_relative '../filter'

module FFMPEG
  module Filters
    class Scale < Filter
      def initialize(width: nil, height: nil, force_original_aspect_ratio: nil, flags: [])
        if !width.nil? && !width.is_a?(Numeric) && !width.is_a?(String)
          raise ArgumentError, "Unknown width format #{width.class}, expected #{Numeric} or #{String}"
        end

        if !height.nil? && !height.is_a?(Numeric) && !width.is_a?(String)
          raise ArgumentError, "Unknown height format #{height.class}, expected #{Numeric} or #{String}"
        end

        if !force_original_aspect_ratio.nil? && !force_original_aspect_ratio.is_a?(String)
          raise ArgumentError,
                "Unknown force_original_aspect_ratio format #{force_original_aspect_ratio.class}, expected #{String}"
        end

        if !flags.nil? && !flags.is_a?(Array)
          raise ArgumentError, "Unknown flags format #{flags.class}, expected #{Array}"
        end

        super(
          Filter::Type::VIDEO,
          'scale',
          w: width,
          h: height,
          force_original_aspect_ratio: force_original_aspect_ratio,
          flags: flags
        )
      end
    end
  end
end
