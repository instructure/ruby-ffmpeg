# frozen_string_literal: true

module FFMPEG
  module Filters
    # The Grayscale class uses the format filter
    # to convert a multimedia file to grayscale.
    class Grayscale
      include Filter

      def to_s
        'format=gray'
      end

      def to_a
        ['-vf', to_s]
      end
    end
  end
end
