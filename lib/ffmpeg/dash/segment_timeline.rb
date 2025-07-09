# frozen_string_literal: true

module FFMPEG
  module DASH
    # Represents a Segment Template in a DASH manifest.
    class SegmentTimeline
      def initialize(node)
        @node = node
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
