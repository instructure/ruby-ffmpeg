# frozen_string_literal: true

require 'uri'
require_relative 'segment_timeline'

module FFMPEG
  module DASH
    # Represents a Segment Template in a DASH manifest.
    class SegmentTemplate
      def initialize(node)
        @node = node
      end

      # Returns the timescale of the segment template.
      #
      # @return [Integer, nil] The timescale as an integer.
      def timescale
        @timescale ||= @node['timescale']&.to_i
      end

      # Returns the initialization segment format of the segment template.
      #
      # @return [String, nil] The initialization segment format.
      def initialization
        @initialization ||= @node['initialization']
      end

      # Returns the media segment format of the segment template.
      #
      # @return [String, nil] The media segment format.
      def media
        @media ||= @node['media']
      end

      # Returns the start number of the segment template.
      #
      # @return [Integer, nil] The start number as an integer.
      def start_number
        @start_number ||= @node['startNumber']&.to_i
      end

      # Returns the segment timeline associated with the segment template.
      #
      # @return [SegmentTimeline, nil] The SegmentTimeline object.
      def segment_timeline
        @segment_timeline ||= @node.at_xpath('./xmlns:SegmentTimeline')&.then(&SegmentTimeline.method(:new))
      end

      # Sets an arbitrary query for the initialization and media segments.
      #
      # @param value [String] The query string to set.
      # @return [void]
      def segment_query=(value)
        return unless value

        %w[initialization media].each do |attribute|
          next unless @node.attributes[attribute]

          @node.attributes[attribute].value =
            URI.parse(@node.attributes[attribute].value)
               .tap { _1.query = value }
               .to_s
        end
      end

      # Returns the segment ranges of the segment timeline.
      #
      # @return [Enumerator::Lazy<Range>, nil] An enumerable of ranges representing the segments.
      def to_ranges
        return unless segment_timeline

        segment_timeline&.to_ranges&.map do |range|
          (range.first / timescale).round(5)..(range.last / timescale).round(5)
        end
      end

      private

      def respond_to_missing?(name, include_private = false)
        @node.respond_to?(name, include_private) || super
      end

      def method_missing(name, *args, &)
        @node.send(name, *args, &)
      end
    end
  end
end
