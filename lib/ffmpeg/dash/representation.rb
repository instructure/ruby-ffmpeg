# frozen_string_literal: true

require_relative 'segment_template'

module FFMPEG
  module DASH
    # Represents a Representation in a DASH manifest.
    class Representation
      def initialize(node)
        @node = node
      end

      # Returns the ID of the representation.
      #
      # @return [Integer, nil] The ID of the representation.
      def id
        @id ||= @node['id']&.to_i
      end

      # Returns the MIME type of the representation.
      #
      # @return [String, nil] The MIME type.
      def mime_type
        @mime_type ||= @node['mimeType']
      end

      # Returns the codecs used in the representation.
      #
      # @return [String, nil] The codecs string.
      def codecs
        @codecs ||= @node['codecs']
      end

      # Returns the bandwidth of the representation in bits per second.
      #
      # @return [Integer, nil] The bandwidth in bits per second.
      def bandwidth
        @bandwidth ||= @node['bandwidth']&.to_i
      end

      # Returns the pixel aspect ratio of the representation.
      #
      # @return [String, nil] The pixel aspect ratio.
      def sar
        @sar ||= @node['sar']
      end

      # Returns the width of the representation.
      #
      # @return [Integer, nil] The width in pixels.
      def width
        @width ||= @node['width']&.to_i
      end

      # Returns the height of the representation.
      #
      # @return [Integer, nil] The height in pixels.
      def height
        @height ||= @node['height']&.to_i
      end

      # Returns the resolution of the representation in the format "width x height".
      #
      # @return [String, nil] The resolution string.
      def resolution
        @resolution ||= "#{width}x#{height}" if width && height
      end

      # Returns the segment template associated with the representation.
      #
      # @return [SegmentTemplate, nil] The SegmentTemplate object.
      def segment_template
        @segment_template ||= @node.at_xpath('./xmlns:SegmentTemplate')&.then(&SegmentTemplate.method(:new))
      end

      # Returns the base URL of the representation.
      #
      # @return [String, nil] The base URL.
      def base_url
        @base_url ||= @node.at_xpath('./xmlns:BaseURL')&.content
      end

      # Returns the segment timeline associated with the representation.
      #
      # @return [SegmentTimeline, nil] The SegmentTimeline object.
      def segment_timeline
        @segment_timeline ||= @node&.at_xpath('./xmlns:SegmentTimeline').then(&SegmentTimeline.method(:new))
      end

      # Sets the base URL for the representation.
      #
      # @param value [String] The base URL to set.
      # @return [void]
      def base_url=(value)
        @node.xpath('./xmlns:BaseURL').each(&:remove)
        return unless (@base_url = value)

        node = @node.document.create_element('BaseURL', value)
        node_to_prepend = @node.element_children.find { _1.name.casecmp('BaseURL').positive? }

        if node_to_prepend
          node_to_prepend.add_previous_sibling(node)
        else
          @node.add_child(node)
        end
      end

      # Sets the segment query for the segment template of the representation.
      #
      # @param value [String] The segment query to set.
      # @return [void]
      def segment_query=(value)
        segment_template&.segment_query = value
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
