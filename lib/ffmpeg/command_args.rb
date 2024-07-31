# frozen_string_literal: true

module FFMPEG
  # The CommandArgs module contains visitors (convert_*) for
  # common options that can be passed to the ffmpeg command,
  # as well as utilities for formatting and escaping them.
  module CommandArgs
    # ================= #
    # === UTILITIES === #
    # ================= #

    def self.order(arg)
      case arg.to_s
      when /codec/
        1
      when /preset/
        2
      else
        999
      end
    end

    def self.escape(value)
      value = value.to_s
      value =~ /[\\'\[\]=:|;,]/ ? "'#{value.gsub(/([\\'])/, '\\\\\1')}'" : value
    end

    def self.convert(key, value)
      return ["-#{key}", value.to_s] if !value.is_a?(Array) && !value.is_a?(Hash)

      formatted = value.is_a?(Array) ? format_flags(value) : format_options(value)
      return [] if formatted.empty?

      ["-#{key}", formatted]
    end

    def self.format_flags(value, separator: '|', escape: true)
      raise ArgumentError, "Unknown value format #{value.class}, expected #{Array}" unless value.is_a?(Array)

      value.map { |e| escape ? escape(e) : e.to_s }.join(separator)
    end

    def self.format_options(value, separator: ':', escape: true)
      raise ArgumentError, "Unknown value format #{value.class}, expected #{Hash}" unless value.is_a?(Hash)

      value.each_with_object([]) do |(k, v), acc|
        if v.nil?
          next acc
        elsif v.is_a?(Array)
          acc << "#{k}=#{format_flags(v, escape: escape)}"
        else
          acc << "#{k}=#{escape ? escape(v) : v}"
        end
      end.join(separator)
    end

    # ======================= #
    # === GENERAL OPTIONS === #
    # ======================= #

    def self.convert_threads(value)
      ['-threads', value.to_s]
    end

    def self.convert_buffer_size(value)
      ['-bufsize', value.to_s]
    end

    def self.convert_max_muxing_queue_size(value)
      ['-max_muxing_queue_size', value.to_s]
    end

    def self.convert_muxing_flags(value)
      if !value.is_a?(Array)
        ['-movflags', value.to_s]
      elsif !value.empty?
        ['-movflags', format_flags(value, escape: false, separator: '+')]
      else
        []
      end
    end

    def self.convert_map(value)
      if value.is_a?(Array)
        value.map { |elem| ['-map', elem] }.flatten
      else
        ['-map', value.to_s]
      end
    end

    def self.convert_map_chapters(value)
      ['-map_chapters', value.to_s]
    end

    def self.convert_duration(value)
      ['-t', value.to_s]
    end

    # ===================== #
    # === VIDEO OPTIONS === #
    # ===================== #

    def self.convert_video_codec_name(value)
      ['-c:v', value.to_s]
    end

    def self.convert_video_bit_rate(value)
      ['-b:v', value.to_s]
    end

    def self.convert_min_video_bit_rate(value)
      ['-minrate', value.to_s]
    end

    def self.convert_max_video_bit_rate(value)
      ['-maxrate', value.to_s]
    end

    def self.convert_video_profile(value)
      ['-profile:v', value.to_s]
    end

    def self.convert_video_quality(value)
      ['-q:v', value.to_s]
    end

    def self.convert_constant_rate_factor(value)
      ['-crf', value.to_s]
    end

    def self.convert_preset(value)
      ['-preset', value.to_s]
    end

    def self.convert_pixel_format(value)
      ['-pix_fmt', value.to_s]
    end

    def self.convert_frame_rate(value)
      ['-r', value.to_s]
    end

    def self.convert_resolution(value)
      ['-s', value.to_s]
    end

    def self.convert_aspect_ratio(value)
      ['-aspect', value.to_s]
    end

    # ===================== #
    # === AUDIO OPTIONS === #
    # ===================== #

    def self.convert_audio_codec_name(value)
      ['-c:a', value.to_s]
    end

    def self.convert_audio_bit_rate(value)
      ['-b:a', value.to_s]
    end

    def self.convert_audio_sample_rate(value)
      ['-ar', value.to_s]
    end

    def self.convert_audio_channels(value)
      ['-ac', value.to_s]
    end

    def self.convert_audio_profile(value)
      ['-profile:a', value.to_s]
    end

    def self.convert_audio_quality(value)
      ['-q:a', value.to_s]
    end
  end
end
