# frozen_string_literal: true

module FFMPEG
  module DASH
    # Represents a Segment Template in a DASH manifest.
    class SegmentTimeline
      attr_reader :manifest, :segment_template

      def initialize(segment_template, node)
        @manifest = segment_template.manifest
        @segment_template = segment_template
        @node = node
      end

      # Returns the segment ranges of the timeline as an enumerable of ranges.
      #
      # @return [Enumerable::Lazy<Range>] An enumerable of ranges representing the segments.
      def to_ranges
        time = 0
        @node.xpath('./xmlns:S').lazy.flat_map do |segment|
          time = segment['t']&.to_i || time
          duration = segment['d'].to_i
          repeat = segment['r'].to_i

          (repeat + 1).times.map do
            (time..(time + duration)).tap do
              time += duration
            end
          end
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
