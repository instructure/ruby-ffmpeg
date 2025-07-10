# frozen_string_literal: true

require 'uri'
require_relative 'segment_timeline'

module FFMPEG
  module DASH
    # Represents a Segment Template in a DASH manifest.
    class SegmentTemplate
      attr_reader :manifest, :representation

      def initialize(representation, node)
        @manifest = representation.manifest
        @representation = representation
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

      # Returns the initialization segment filename.
      #
      # @return [String, nil] The formatted initialization segment filename.
      def initialization_filename
        return unless initialization

        format_filename(initialization, start_number)
      end

      # Returns the media segment format of the segment template.
      #
      # @return [String, nil] The media segment format.
      def media
        @media ||= @node['media']
      end

      # Returns the media segment filename for a given index.
      # Note that the index in the argument is zero-based, while the segment numbering
      # starts from the `startNumber`. This method adjusts the index accordingly.
      #
      # @return [String, nil] The formatted media segment filename.
      def media_filename(index)
        return unless media

        format_filename(media, index + start_number)
      end

      # Returns the start number of the segment template.
      #
      # @return [Integer] The start number as an integer.
      def start_number
        @start_number ||= @node['startNumber']&.to_i || 1
      end

      # Returns the segment timeline associated with the segment template.
      #
      # @return [SegmentTimeline, nil] The SegmentTimeline object.
      def segment_timeline
        @segment_timeline ||=
          @node
          .at_xpath('./xmlns:SegmentTimeline')
          &.then { SegmentTimeline.new(self, _1) }
      end

      # Sets an arbitrary query for the initialization and media segments.
      #
      # @param value [String] The query string to set.
      # @return [void]
      def segment_query=(value)
        return unless value

        %w[initialization media].each do |attribute|
          next unless @node[attribute]

          @node[attribute] =
            URI.parse(@node[attribute])
               .tap { _1.query = value }
               .to_s
        end
      end

      # Returns the segment ranges of the segment timeline.
      #
      # @return [Enumerator::Lazy<Range>, nil] An enumerable of ranges representing the segments.
      def to_ranges
        return unless segment_timeline

        timescale = self.timescale.to_f
        segment_timeline&.to_ranges&.map do |range|
          (range.begin / timescale).round(5)..(range.end / timescale).round(5)
        end
      end

      private

      def format_filename(template, number)
        template.gsub(/\$(RepresentationID|Number)(%\w+)?\$/) do
          key = Regexp.last_match(1)
          format = Regexp.last_match(2)
          value =
            case key
            when 'RepresentationID'
              @representation.id
            else
              number
            end

          format ? format % value : value
        end
      end

      def respond_to_missing?(name, include_private = false)
        @node.respond_to?(name, include_private) || super
      end

      def method_missing(name, *args, &)
        @node.send(name, *args, &)
      end
    end
  end
end
