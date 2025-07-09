# frozen_string_literal: true

module FFMPEG
  module DASH
    # Represents a Segment Template in a DASH manifest.
    class SegmentTimeline
      def initialize(node)
        @node = node
      end

      # Returns the timescale of the segment timeline.
      #
      # @return [Integer, nil] The timescale as an integer.
      def timescale
        @timescale ||= @node['timescale']&.to_i || 1
      end

      # Returns the segment ranges of the timeline as an enumerable of ranges.
      #
      # @return [Enumerable::Lazy<Range>] An enumerable of ranges representing the segments.
      def to_ranges
        time = nil
        @node.xpath('./xmlns:S').lazy.flat_map do |segment|
          time = segment['t']&.to_f || time
          duration = segment['d'].to_f
          repeat = segment['r']&.to_i || 1

          repeat.times.map do
            ((time / timescale).round(5)..((time + duration) / timescale).round(5)).tap do
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
