# frozen_string_literal: true

module FFMPEG
  # The Stream class represents a multimedia stream in a file.
  class Stream
    module CodecType
      VIDEO = 'video'
      AUDIO = 'audio'
    end

    module ChannelLayout
      MONO = 'mono'
      STEREO = 'stereo'
      FIVE_ONE = '5.1'
      SEVEN_ONE = '7.1'
      UNKNOWN = 'unknown'
    end

    attr_reader :metadata,
                :id, :index, :profile, :tags,
                :codec_name, :codec_long_name, :codec_tag, :codec_tag_string, :codec_type,
                :coded_width, :coded_height, :sample_aspect_ratio, :display_aspect_ratio, :rotation,
                :color_range, :color_space, :frame_rate,
                :sample_rate, :sample_fmt, :channels, :channel_layout,
                :start_time, :bitrate, :duration, :frames, :overview

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
      @codec_type = metadata[:codec_type]

      @width = metadata[:width]
      @height = metadata[:height]
      @coded_width = metadata[:coded_width]
      @coded_height = metadata[:coded_height]
      @sample_aspect_ratio = metadata[:sample_aspect_ratio]
      @display_aspect_ratio = metadata[:display_aspect_ratio]
      @rotation = if metadata[:tags]&.key?(:rotate)
                    metadata[:tags][:rotate].to_i
                  elsif metadata[:side_data_list]&.first&.key?(:rotation)
                    rotation = metadata[:side_data_list].first[:rotation].to_i
                    rotation.positive? ? 360 - rotation : rotation.abs
                  end

      @color_range = metadata[:color_range]
      @color_space = metadata[:pix_fmt] || metadata[:color_space]
      unless metadata[:avg_frame_rate].nil? || metadata[:avg_frame_rate] == '0/0'
        @frame_rate = Rational(metadata[:avg_frame_rate])
      end

      @sample_rate = metadata[:sample_rate].to_i
      @sample_fmt = metadata[:sample_fmt]
      @channels = metadata[:channels]
      @channel_layout = metadata[:channel_layout]

      @start_time = metadata[:start_time].to_f
      @bitrate = metadata[:bit_rate].to_i
      @duration = metadata[:duration].to_f
      @frames = metadata[:nb_frames].to_i

      if video?
        @overview = "#{codec_name} " \
                    "(#{profile}) " \
                    "(#{codec_tag_string} / #{codec_tag}), " \
                    "#{color_space}, #{resolution} " \
                    "[SAR #{sample_aspect_ratio} DAR #{display_aspect_ratio}]"
      elsif audio?
        @overview = "#{codec_name} " \
                    "(#{codec_tag_string} / #{codec_tag}), " \
                    "#{sample_rate} Hz, " \
                    "#{channel_layout}, " \
                    "#{sample_fmt}, " \
                    "#{bitrate} bit/s"
      end

      @supported = stderr !~ /^Unsupported codec with id (\d+) for input stream #{Regexp.quote(@index.to_s)}$/
    end

    def supported?
      @supported
    end

    def unsupported?
      !supported?
    end

    def video?
      codec_type == CodecType::VIDEO
    end

    def audio?
      codec_type == CodecType::AUDIO
    end

    def default?
      metadata.dig(:disposition, :default) == 1
    end

    def attached_pic?
      metadata.dig(:disposition, :attached_pic) == 1
    end

    def width
      @rotation.nil? || @rotation == 180 ? @width : @height
    end

    def height
      @rotation.nil? || @rotation == 180 ? @height : @width
    end

    def resolution
      return if width.nil? || height.nil?

      "#{width}x#{height}"
    end

    def calculated_aspect_ratio
      return @calculated_aspect_ratio unless @calculated_aspect_ratio.nil?

      @calculated_aspect_ratio = calculate_aspect_ratio(display_aspect_ratio)
      @calculated_aspect_ratio ||= width.to_f / height.to_f
      @calculated_aspect_ratio = nil if @calculated_aspect_ratio.nan?

      @calculated_aspect_ratio
    end

    def calculated_pixel_aspect_ratio
      return @calculated_pixel_aspect_ratio unless @calculated_pixel_aspect_ratio.nil?

      @calculated_pixel_aspect_ratio = calculate_aspect_ratio(sample_aspect_ratio)
      @calculated_pixel_aspect_ratio ||= 1
    end

    protected

    def calculate_aspect_ratio(source)
      return nil if source.nil?

      width, height = source.split(':')
      return nil if width == '0' || height == '0'

      @rotation.nil? || (@rotation == 180) ? width.to_f / height.to_f : height.to_f / width.to_f
    end
  end
end
