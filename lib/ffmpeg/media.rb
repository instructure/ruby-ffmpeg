# frozen_string_literal: true

require 'multi_json'
require 'net/http'
require 'uri'
require 'tempfile'

module FFMPEG
  # The Media class represents a multimedia file and provides methods
  # to inspect and transcode it.
  # It accepts a local path or remote URL to a multimedia file as input.
  # It uses ffprobe to get the streams and format of the multimedia file.
  class Media
    attr_reader :path, :size, :metadata, :streams, :tags,
                :format_name, :format_long_name,
                :start_time, :bitrate, :duration

    def self.concat(output_path, *media)
      raise ArgumentError, 'Unknown *media format, must be Array<Media>' unless media.all? { |m| m.is_a?(Media) }
      raise ArgumentError, 'Invalid *media format, must contain more than one Media object' if media.length < 2
      raise ArgumentError, 'Invalid *media format, has to be all valid Media objects' unless media.all?(&:valid?)
      raise ArgumentError, 'Invalid *media format, has to be all local Media objects' unless media.all?(&:local?)

      tempfile = Tempfile.open(%w[ffmpeg .txt])
      tempfile.write(media.map { |m| "file '#{File.absolute_path(m.path)}'" }.join("\n"))
      tempfile.close

      options = { custom: %w[-c copy] }
      kwargs = { input_options: %w[-safe 0 -f concat] }
      Transcoder.new(tempfile.path, output_path, options, **kwargs).run
    ensure
      tempfile&.close
      tempfile&.unlink
    end

    def initialize(path)
      @path = path

      # Check if the file exists and get its size
      if remote?
        response = FFMPEG.fetch_http_head(@path)

        unless response.is_a?(Net::HTTPSuccess)
          raise Errno::ENOENT,
                "The file at '#{@path}' does not exist or is not available (response code: #{response.code})"
        end

        @size = response.content_length
      else
        raise Errno::ENOENT, "The file at '#{@path}' does not exist" unless File.exist?(@path)

        @size = File.size(@path)
      end

      # Run ffprobe to get the streams and format
      stdout, stderr, _status = FFMPEG.ffprobe_capture3(
        '-i', @path, '-print_format', 'json',
        '-show_format', '-show_streams', '-show_error'
      )

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

    def audio_with_attached_pic?
      audio? && streams.any?(&:attached_pic?)
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

    def transcoder(output_path, options, **kwargs)
      Transcoder.new(self, output_path, options, **kwargs)
    end

    def transcode(output_path, options = EncodingOptions.new, **kwargs, &block)
      transcoder(output_path, options, **kwargs).run(&block)
    end

    def screenshot(output_path, options = EncodingOptions.new, **kwargs, &block)
      options = options.merge(screenshot: true)
      transcode(output_path, options, **kwargs, &block)
    end

    def cut(output_path, from, to, options = EncodingOptions.new, **kwargs)
      kwargs[:input_options] ||= []
      if kwargs[:input_options].is_a?(Array)
        kwargs[:input_options] << '-to'
        kwargs[:input_options] << to.to_s
      elsif kwargs[:input_options].is_a?(Hash)
        kwargs[:input_options][:to] = to
      end

      options = options.merge(seek_time: from)
      transcode(output_path, options, **kwargs)
    end
  end
end
