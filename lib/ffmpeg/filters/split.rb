# frozen_string_literal: true

require_relative '../filter'

module FFMPEG
  # rubocop:disable Style/Documentation
  module Filters
    # rubocop:enable Style/Documentation

    class << self
      def split(output_count)
        Split.new(output_count)
      end
    end

    # The Split class uses the split filter
    # to split a multimedia stream into multiple outputs.
    class Split < Filter
      attr_reader :output_count

      def initialize(output_count = nil)
        unless output_count.nil? || output_count.is_a?(Integer)
          raise ArgumentError,
                "Unknown output_count format #{output_count.class}, expected #{Integer}"
        end

        @output_count = output_count if output_count

        super(:video, 'split')
      end

      protected

      def format_kwargs
        @output_count.to_s
      end
    end
  end
end
