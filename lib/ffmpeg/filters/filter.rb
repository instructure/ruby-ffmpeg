# frozen_string_literal: true

module FFMPEG
  module Filters
    # The Filter module is the base "interface" for all filters.
    module Filter
      def to_s
        raise NotImplementedError
      end

      def to_a
        raise NotImplementedError
      end
    end
  end
end
