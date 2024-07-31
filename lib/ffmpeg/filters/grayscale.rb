# frozen_string_literal: true

require_relative '../filter'

module FFMPEG
  module Filters
    # The Grayscale class uses the format filter
    # to convert a multimedia file to grayscale.
    class Grayscale < Filter
      def initialize
        super(Filter::Type::VIDEO, 'format', pix_fmts: ['gray'])
      end
    end
  end
end
