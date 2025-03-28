# frozen_string_literal: true

require_relative '../filter'

module FFMPEG
  module Filters # rubocop:disable Style/Documentation
    class << self
      def grayscale
        Grayscale.new
      end
    end

    # The Grayscale class uses the format filter
    # to convert a multimedia stream to grayscale.
    class Grayscale < Format
      def initialize
        super(pixel_formats: 'gray')
      end
    end
  end
end
