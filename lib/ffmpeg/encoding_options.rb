# frozen_string_literal: true

module FFMPEG
  # Encoding options for the ffmpeg command
  # in the form of a hash.
  class EncodingOptions < Hash
    def initialize(options = {})
      super(nil)
      merge!(options)
    end

    def to_a
      ary = []

      # codecs should go before the presets so that the files will be matched successfully
      # all other parameters go after so that we can override whatever is in the preset
      keys.sort_by(&method(:params_order)).each do |key|
        value = self[key]
        chunk = send("convert_#{key}", value) if value && supports_option?(key)
        ary += chunk unless chunk.nil?
      end

      ary += convert_aspect(calculate_aspect) if calculate_aspect?
      ary.map(&:to_s)
    end

    def width
      self[:resolution].split('x').first.to_i
    rescue StandardError
      nil
    end

    def height
      self[:resolution].split('x').last.to_i
    rescue StandardError
      nil
    end

    private

    def params_order(key)
      case key
      when /watermark$/
        0
      when /watermark/
        1
      when /codec/
        2
      when /preset/
        3
      else
        4
      end
    end

    def supports_option?(option)
      method = RUBY_VERSION < '1.9' ? "convert_#{option}" : :"convert_#{option}"
      private_methods.include?(method)
    end

    def convert_aspect(value)
      ['-aspect', value]
    end

    def calculate_aspect
      width, height = self[:resolution].split('x')
      width.to_f / height.to_f
    end

    def calculate_aspect?
      self[:aspect].nil? && self[:resolution]
    end

    def convert_video_codec(value)
      ['-vcodec', value]
    end

    def convert_frame_rate(value)
      ['-r', value]
    end

    def convert_resolution(value)
      ['-s', value]
    end

    def convert_video_bitrate(value)
      ['-b:v', k_format(value)]
    end

    def convert_audio_codec(value)
      ['-acodec', value]
    end

    def convert_audio_bitrate(value)
      ['-b:a', k_format(value)]
    end

    def convert_audio_sample_rate(value)
      ['-ar', value]
    end

    def convert_audio_channels(value)
      ['-ac', value]
    end

    def convert_video_max_bitrate(value)
      ['-maxrate', k_format(value)]
    end

    def convert_video_min_bitrate(value)
      ['-minrate', k_format(value)]
    end

    def convert_buffer_size(value)
      ['-bufsize', k_format(value)]
    end

    def convert_video_bitrate_tolerance(value)
      ['-bt', k_format(value)]
    end

    def convert_threads(value)
      ['-threads', value]
    end

    def convert_target(value)
      ['-target', value]
    end

    def convert_duration(value)
      ['-t', value]
    end

    def convert_video_preset(value)
      ['-vpre', value]
    end

    def convert_audio_preset(value)
      ['-apre', value]
    end

    def convert_file_preset(value)
      ['-fpre', value]
    end

    def convert_keyframe_interval(value)
      ['-g', value]
    end

    def convert_seek_time(value)
      ['-ss', value]
    end

    def convert_screenshot(value)
      result = []
      unless self[:vframes]
        result << '-vframes'
        result << 1
      end
      result << '-f'
      result << 'image2'
      value ? result : []
    end

    def convert_quality(value)
      ['-q:v', value]
    end

    def convert_vframes(value)
      ['-vframes', value]
    end

    def convert_x264_vprofile(value)
      ['-vprofile', value]
    end

    def convert_x264_preset(value)
      ['-preset', value]
    end

    def convert_watermark(value)
      ['-i', value]
    end

    def convert_watermark_filter(value)
      position = value[:position]
      padding_x = value[:padding_x] || 10
      padding_y = value[:padding_y] || 10
      case position.to_s
      when 'LT'
        ['-filter_complex', "scale=#{self[:resolution]},overlay=x=#{padding_x}:y=#{padding_y}"]
      when 'RT'
        ['-filter_complex', "scale=#{self[:resolution]},overlay=x=main_w-overlay_w-#{padding_x}:y=#{padding_y}"]
      when 'LB'
        ['-filter_complex', "scale=#{self[:resolution]},overlay=x=#{padding_x}:y=main_h-overlay_h-#{padding_y}"]
      when 'RB'
        ['-filter_complex',
         "scale=#{self[:resolution]},overlay=x=main_w-overlay_w-#{padding_x}:y=main_h-overlay_h-#{padding_y}"]
      end
    end

    def convert_custom(value)
      raise ArgumentError unless value.class <= Array

      value
    end

    def k_format(value)
      value.to_s.include?('k') ? value : "#{value}k"
    end
  end
end
