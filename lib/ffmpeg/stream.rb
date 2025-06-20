# frozen_string_literal: true

module FFMPEG
  # The Stream class represents a multimedia stream in a file.
  class Stream
    attr_reader :metadata,
                :id, :index, :profile, :tags,
                :codec_name, :codec_long_name, :codec_tag, :codec_tag_string, :codec_type,
                :raw_width, :raw_height, :coded_width, :coded_height,
                :raw_sample_aspect_ratio, :raw_display_aspect_ratio, :rotation,
                :pixel_format, :color_range, :color_space, :color_primaries, :color_transfer, :field_order, :frame_rate,
                :sample_rate, :sample_fmt, :channels, :channel_layout,
                :start_time, :bit_rate, :duration, :frames, :overview

    def initialize(metadata, stderr = '')
      @metadata = metadata

      @id = metadata[:id]
      @index = metadata[:index]
      @profile = metadata[:profile]
      @tags = metadata[:tags]

      @codec_name = metadata[:codec_name]
      @codec_long_name = metadata[:codec_long_name]
      @codec_tag = metadata[:codec_tag]
      @codec_tag_string = metadata[:codec_tag_string]
      @codec_type = metadata[:codec_type]&.to_sym

      @raw_width = metadata[:width]&.to_i
      @raw_height = metadata[:height]&.to_i
      @coded_width = metadata[:coded_width]&.to_i
      @coded_height = metadata[:coded_height]&.to_i
      @raw_sample_aspect_ratio = metadata[:sample_aspect_ratio]
      @raw_display_aspect_ratio = metadata[:display_aspect_ratio]

      @rotation =
        if metadata.dig(:tags, :rotate)
          metadata.dig(:tags, :rotate).to_i
        else
          metadata[:side_data_list]
            &.find { |data| data[:side_data_type] =~ /display matrix/i }
            &.dig(:rotation)
            &.to_i
            &.tap { |value| break value + 180 if value % 180 != 0 }
            &.abs
        end

      @pixel_format = metadata[:pix_fmt]
      @color_range = metadata[:color_range]
      @color_space = metadata[:color_space]
      @color_primaries = metadata[:color_primaries]
      @color_transfer = metadata[:color_transfer]
      @field_order = metadata[:field_order]
      unless metadata[:avg_frame_rate].nil? || metadata[:avg_frame_rate] == '0/0'
        @frame_rate = Rational(metadata[:avg_frame_rate])
      end

      @sample_rate = metadata[:sample_rate].to_i
      @sample_fmt = metadata[:sample_fmt]
      @channels = metadata[:channels]
      @channel_layout = metadata[:channel_layout]

      @start_time = metadata[:start_time].to_f
      @bit_rate = metadata[:bit_rate].to_i
      @duration = metadata[:duration].to_f
      @frames = metadata[:nb_frames].to_i

      if video?
        @overview = "#{codec_name} " \
                    "(#{profile}) " \
                    "(#{codec_tag_string} / #{codec_tag}), " \
                    "#{pixel_format}" \
                    "(#{color_range || 'unknown'}, " \
                    "#{color_space || 'unknown'}/#{color_transfer || 'unknown'}/#{color_primaries || 'unknown'}, " \
                    "#{field_order || 'unknown'}), " \
                    "#{resolution} " \
                    "[SAR #{raw_sample_aspect_ratio} DAR #{raw_display_aspect_ratio}]"
      elsif audio?
        @overview = "#{codec_name} " \
                    "(#{codec_tag_string} / #{codec_tag}), " \
                    "#{sample_rate} Hz, " \
                    "#{channel_layout}, " \
                    "#{sample_fmt}, " \
                    "#{bit_rate} bit/s"
      end

      @supported = stderr !~ /^Unsupported codec with id (\d+) for input stream #{Regexp.quote(@index.to_s)}$/
    end

    # Whether the stream is supported.
    #
    # @return [Boolean]
    def supported?
      @supported
    end

    # Whether the stream is unsupported.
    #
    # @return [Boolean]
    def unsupported?
      !supported?
    end

    # Whether the stream is a video stream.
    #
    # @return [Boolean]
    def video?
      codec_type == :video
    end

    # Whether the stream is an audio stream.
    #
    # @return [Boolean]
    def audio?
      codec_type == :audio
    end

    # Whether the stream is marked as default.
    #
    # @return [Boolean]
    def default?
      metadata.dig(:disposition, :default) == 1
    end

    # Whether the stream is marked as an attached picture.
    #
    # @return [Boolean]
    def attached_pic?
      metadata.dig(:disposition, :attached_pic) == 1
    end

    # Whether the stream is rotated.
    # This is determined by the value of a rotation tag or display matrix side data.
    #
    # @return [Boolean]
    def rotated?
      !@rotation.nil? && @rotation % 180 != 0
    end

    # Whether the stream is portrait.
    #
    # @return [Boolean]
    def portrait?
      return true if width < height

      width == height && rotated?
    end

    # Whether the stream is landscape.
    #
    # @return [Boolean]
    def landscape?
      return true if width > height

      width == height && !rotated?
    end

    # The width of the stream.
    # If the stream is rotated, the height is returned instead.
    #
    # @return [Integer]
    def width
      rotated? ? @raw_height : @raw_width
    end

    # The height of the stream.
    # If the stream is rotated, the width is returned instead.
    #
    # @return [Integer]
    def height
      rotated? ? @raw_width : @raw_height
    end

    # The resolution of the stream.
    # This is a string in the format "#{width}x#{height}".
    #
    # @return [String]
    def resolution
      return if width.nil? || height.nil?

      "#{width}x#{height}"
    end

    # The calculated aspect ratio of the stream.
    # This is calculated from the display aspect ratio or the width and height.
    # If neither are available, nil is returned.
    # If the stream is rotated, the inverted aspect ratio is returned.
    #
    # @return [Rational, nil]
    def display_aspect_ratio
      return @display_aspect_ratio if defined?(@display_aspect_ratio)

      @display_aspect_ratio = calculate_aspect_ratio(@raw_display_aspect_ratio)
      return unless width && height && !height.zero?

      @display_aspect_ratio ||= Rational(width, height)
    end

    # The calculated pixel aspect ratio of the stream.
    # This is calculated from the sample aspect ratio.
    # If the sample aspect ratio is not available, 1 is returned.
    # If the stream is rotated, the inverted aspect ratio is returned.
    #
    # @return [Rational]
    def sample_aspect_ratio
      return @sample_aspect_ratio if defined?(@sample_aspect_ratio)

      @sample_aspect_ratio = calculate_aspect_ratio(@raw_sample_aspect_ratio)
      @sample_aspect_ratio ||= Rational(1)
    end

    protected

    def calculate_aspect_ratio(source)
      return nil if source.nil?

      width, height = source.split(':').map(&:to_i)
      return nil if width.zero? || height.zero?

      rotated? ? Rational(height, width) : Rational(width, height)
    end
  end
end
