# frozen_string_literal: true

require_relative '../filter'

module FFMPEG
  # rubocop:disable Style/Documentation
  module Filters
    # rubocop:enable Style/Documentation

    class << self
      def grayscale
        Grayscale.new
      end
    end

    # The Grayscale class uses the format filter
    # to convert a multimedia stream to grayscale.
    class Grayscale < Filter
      def initialize
        super(:video, 'format', pix_fmts: ['gray'])
      end
    end
  end
end
