# frozen_string_literal: true

require 'multi_json'
require 'net/http'

module FFMPEG
  # The Media class represents a multimedia file and provides methods
  # to inspect and transcode it.
  # It accepts a local path or remote URL to a multimedia file as input.
  # It uses ffprobe to get the streams and format of the multimedia file.
  class Media
    attr_reader :path, :size, :metadata, :streams, :tags,
                :format_name, :format_long_name,
                :start_time, :bitrate, :duration

    def initialize(path)
      @path = path

      # Check if the file exists and get its size
      if remote?
        response = Utils.fetch_http_head(path)

        unless response.is_a?(Net::HTTPSuccess)
          raise Errno::ENOENT, "the URL '#{path}' does not exist or is not available (response code: #{response.code})"
        end

        @size = response.content_length
      else
        raise Errno::ENOENT, "the file '#{path}' does not exist" unless File.exist?(path)

        @size = File.size(path)
      end

      # Run ffprobe to get the streams and format
      command = [FFMPEG.ffprobe_binary, '-i', path,
                 '-print_format', 'json', '-show_format', '-show_streams', '-show_error']
      stdout, stderr, _status = Open3.capture3(*command)
      Utils.force_iso8859(stdout)
      Utils.force_iso8859(stderr)

      # Parse ffprobe metadata
      begin
        @metadata = MultiJson.load(stdout, symbolize_keys: true)
      rescue MultiJson::ParseError
        raise "Could not parse output from FFProbe:\n#{stdout}"
      end

      if @metadata.key?(:error) || stderr.include?('could not find codec parameters')
        @invalid = true
        return
      end

      @streams = @metadata[:streams].map { |stream| Stream.new(stream, stderr) }
      @tags = @metadata[:format][:tags]

      @format_name = @metadata[:format][:format_name]
      @format_long_name = @metadata[:format][:format_long_name]

      @start_time = @metadata[:format][:start_time].to_f
      @bitrate = @metadata[:format][:bit_rate].to_i
      @duration = @metadata[:format][:duration].to_f

      @invalid = @streams.all?(&:unsupported?)
    end

    def valid?
      !@invalid
    end

    def remote?
      @remote ||= @path =~ URI::DEFAULT_PARSER.make_regexp(%w[http https]) ? true : false
    end

    def local?
      !remote?
    end

    def width
      video&.width
    end

    def height
      video&.height
    end

    def rotation
      video&.rotation
    end

    def resolution
      video&.resolution
    end

    def display_aspect_ratio
      video&.display_aspect_ratio
    end

    def sample_aspect_ratio
      video&.sample_aspect_ratio
    end

    def calculated_aspect_ratio
      video&.calculated_aspect_ratio
    end

    def calculated_pixel_aspect_ratio
      video&.calculated_pixel_aspect_ratio
    end

    def color_range
      video&.color_range
    end

    def color_space
      video&.color_space
    end

    def frame_rate
      video&.frame_rate
    end

    def frames
      video&.frames
    end

    def video
      @video ||= @streams&.find(&:video?)
    end

    def video?
      !video.nil?
    end

    def video_only?
      video? && !audio?
    end

    def video_index
      video&.index
    end

    def video_profile
      video&.profile
    end

    def video_codec_name
      video&.codec_name
    end

    def video_codec_type
      video&.codec_type
    end

    def video_bitrate
      video&.bitrate
    end

    def video_overview
      video&.overview
    end

    def video_tags
      video&.tags
    end

    def audio
      @audio ||= @streams&.select(&:audio?)
    end

    def audio?
      audio&.length&.positive?
    end

    def audio_only?
      audio? && !video?
    end

    def silent?
      !audio?
    end

    def audio_index
      audio&.first&.index
    end

    def audio_profile
      audio&.first&.profile
    end

    def audio_codec_name
      audio&.first&.codec_name
    end

    def audio_codec_type
      audio&.first&.codec_type
    end

    def audio_bitrate
      audio&.first&.bitrate
    end

    def audio_channels
      audio&.first&.channels
    end

    def audio_channel_layout
      audio&.first&.channel_layout
    end

    def audio_sample_rate
      audio&.first&.sample_rate
    end

    def audio_overview
      audio&.first&.overview
    end

    def audio_tags
      audio&.first&.tags
    end

    def transcode(output_path, options = EncodingOptions.new, **kwargs, &block)
      Transcoder.new(self, output_path, options, **kwargs).run(&block)
    end

    def screenshot(output_path, options = EncodingOptions.new, **kwargs, &block)
      transcode(output_path, options.merge(screenshot: true), **kwargs, &block)
    end
  end
end
