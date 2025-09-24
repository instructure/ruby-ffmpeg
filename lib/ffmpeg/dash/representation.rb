# frozen_string_literal: true

require 'uri'
require_relative 'hls_class_methods'
require_relative 'segment_template'

module FFMPEG
  module DASH
    # Represents a Representation in a DASH manifest.
    class Representation
      include HLSClassMethods

      attr_reader :manifest, :adaptation_set

      def initialize(adaptation_set, node)
        @manifest = adaptation_set.manifest
        @adaptation_set = adaptation_set
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
        @segment_template ||=
          @node
          .at_xpath('./xmlns:SegmentTemplate')
          &.then { SegmentTemplate.new(self, _1) }
      end

      # Returns the base URL of the representation.
      #
      # @return [String, nil] The base URL.
      def base_url
        @base_url ||= @node.at_xpath('./xmlns:BaseURL')&.content
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

      # Returns the segment ranges of the representation as an enumerable of ranges.
      #
      # @return [Enumerable::Lazy<Range>, nil] An enumerable of ranges representing the segments.
      def to_ranges
        segment_template&.to_ranges
      end

      # Returns the representation as a string in M3U8 (HLS playlist) format.
      # NOTE: Currently we only support audio and video representations.
      #
      # See https://datatracker.ietf.org/doc/html/rfc8216
      #
      # @return [String, nil] The M3U8 formatted string for the representation.
      def to_m3u8
        return unless %w[audio video].include?(@adaptation_set.content_type)
        return unless segment_template

        m3u8 = %w[#EXTM3U #EXT-X-VERSION:6]
        m3u8 << m3u8t('EXT-X-PLAYLIST-TYPE', %w[VOD]) if @manifest.vod?
        m3u8 << m3u8t(
          'EXT-X-MAP',
          'URI' => quote(url(segment_template.initialization_filename))
        )

        target_duration = 0
        to_ranges.each_with_index do |range, index|
          filename = segment_template.media_filename(index)
          duration = (range.end - range.begin).round(5)
          target_duration = [duration, target_duration].max

          m3u8 << m3u8t('EXTINF', [duration, ''])
          m3u8 << url(filename)
        end

        [
          m3u8[0..1],
          m3u8t('EXT-X-TARGETDURATION', [target_duration.ceil]),
          m3u8[2..],
          @manifest.vod? ? '#EXT-X-ENDLIST' : nil
        ].compact.join("\n")
      end

      # Returns the representation as a string in M3U8 (HLS playlist) stream info format.
      # NOTE: Currently we only support audio and video representations.
      #
      # See https://datatracker.ietf.org/doc/html/rfc8216
      #
      # @param audio_group_id [String, nil] The audio group ID to include in the stream info.
      # @return [String, nil] The M3U8 formatted string for the representation as a stream.
      def to_m3u8si(audio_group_id: nil, video_group_id: nil)
        return unless %w[audio video].include?(@adaptation_set.content_type)

        url = "stream#{id}.m3u8"
        url = URI.join(base_url, url).to_s if base_url

        "#{m3u8t(
          'EXT-X-STREAM-INF',
          'BANDWIDTH' => bandwidth,
          'CODECS' => quote(codecs),
          'RESOLUTION' => resolution,
          'AUDIO' => quote(audio_group_id),
          'VIDEO' => quote(video_group_id)
        )}\n#{url}"
      end

      private

      def vod?
        @adaptation_set.manifest.vod?
      end

      def url(filename)
        return filename unless base_url

        URI.join(base_url, filename).to_s
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
