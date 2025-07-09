# frozen_string_literal: true

require_relative 'representation'

module FFMPEG
  module DASH
    # Represents an Adaptation Set in a DASH manifest.
    class AdaptationSet
      def initialize(node)
        @node = node
      end

      # Returns the ID of the adaptation set.
      #
      # @return [Integer, nil] The ID of the adaptation set.
      def id
        @id ||= @node['id']&.to_i
      end

      # Returns the aspect ratio of the adaptation set.
      #
      # @return [String, nil] The pixel aspect ratio.
      def par
        @par ||= @node['par']
      end

      # Returns the content type of the adaptation set.
      #
      # @return [String, nil] The content type.
      def content_type
        @content_type ||= @node['contentType']
      end

      # Returns the max width of the adaptation set.
      #
      # @return [Integer, nil] The maximum width in pixels.
      def max_width
        @max_width ||= @node['maxWidth']&.to_i
      end

      # Returns the max height of the adaptation set.
      #
      # @return [Integer, nil] The maximum height in pixels.
      def max_height
        @max_height ||= @node['maxHeight']&.to_i
      end

      # Returns the frame rate of the adaptation set.
      #
      # @return [Rational, nil] The frame rate as a Rational number.
      def frame_rate
        @frame_rate ||= @node['frameRate']&.to_r
      end

      # Returns the representations in the adaptation set.
      #
      # @return [Array<Representation>, nil] An array of Representation objects.
      def representations
        @representations ||= @node.xpath('./xmlns:Representation')&.map(&Representation.method(:new))
      end

      # Sets the base URL for all representations in the adaptation set.
      #
      # @param value [String] The base URL to set.
      # @return [void]
      def base_url=(value)
        representations&.each { _1.base_url = value }
      end

      # Sets the segment query for all representations in the adaptation set.
      #
      # @param value [String] The segment query to set.
      # @return [void]
      def segment_query=(value)
        representations&.each { _1.segment_query = value }
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
