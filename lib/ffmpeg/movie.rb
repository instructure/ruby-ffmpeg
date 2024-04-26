# frozen_string_literal: true

require 'time'
require 'multi_json'
require 'uri'
require 'net/http'

module FFMPEG
  class Movie
    attr_reader :path, :duration, :time, :bitrate, :rotation, :creation_time,
                :video_stream_id, :video_stream, :video_codec, :video_bitrate,
                :colorspace, :sar, :dar, :frame_rate,
                :audio_stream_id, :audio_streams, :audio_stream, :audio_codec, :audio_bitrate,
                :audio_sample_rate, :audio_channels, :audio_tags,
                :container, :metadata, :format_tags

    UNSUPPORTED_CODEC_PATTERN = /^Unsupported codec with id (\d+) for input stream (\d+)$/.freeze

    def initialize(path)
      @path = path

      if remote?
        @head = head
        unless @head.is_a?(Net::HTTPSuccess)
          raise Errno::ENOENT, "the URL '#{path}' does not exist or is not available (response code: #{@head.code})"
        end
      else
        raise Errno::ENOENT, "the file '#{path}' does not exist" unless File.exist?(path)
      end

      @path = path

      # ffmpeg will output to stderr
      command = [FFMPEG.ffprobe_binary, '-i', path, '-print_format', 'json', '-show_format', '-show_streams',
                 '-show_error']
      stdout, stderr, _status = Open3.capture3(*command)

      fix_encoding(stdout)
      fix_encoding(stderr)

      begin
        @metadata = MultiJson.load(stdout, symbolize_keys: true)
      rescue MultiJson::ParseError
        raise "Could not parse output from FFProbe:\n#{stdout}"
      end

      @duration = 0
      unless @metadata.key?(:error)
        video_streams = @metadata[:streams].select do |stream|
          stream[:codec_type] == 'video'
        end
        audio_streams = @metadata[:streams].select do |stream|
          stream[:codec_type] == 'audio'
        end

        @container = @metadata[:format][:format_name]

        @duration = @metadata[:format][:duration].to_f

        @time = @metadata[:format][:start_time].to_f

        @format_tags = @metadata[:format][:tags]

        @creation_time = if @format_tags&.key?(:creation_time)
                           begin
                             Time.parse(@format_tags[:creation_time])
                           rescue ArgumentError
                             nil
                           end
                         end

        @bitrate = @metadata[:format][:bit_rate].to_i

        initialize_video_metadata(video_streams)
        initialize_audio_streams(audio_streams)
        initialize_audio_metadata
      end

      initialize_unsupported_stream_ids(stderr)
      initialize_invalid(stderr)
    end

    def valid?
      !@invalid
    end

    def remote?
      @path =~ URI::DEFAULT_PARSER.make_regexp(%w[http https])
    end

    def local?
      !remote?
    end

    def width
      rotation.nil? || rotation == 180 ? @width : @height
    end

    def height
      rotation.nil? || rotation == 180 ? @height : @width
    end

    def resolution
      return if width.nil? || height.nil?

      "#{width}x#{height}"
    end

    def calculated_aspect_ratio
      aspect_from_dar || aspect_from_dimensions
    end

    def calculated_pixel_aspect_ratio
      aspect_from_sar || 1
    end

    def size
      if local?
        File.size(@path)
      else
        @head.content_length
      end
    end

    def audio_channel_layout
      # TODO: Whenever support for ffmpeg/ffprobe 1.2.1 is dropped this is no longer needed
      @audio_channel_layout || case audio_channels
                               when 1, 2
                                 'stereo'
                               when 6
                                 '5.1'
                               else
                                 'unknown'
                               end
    end

    def transcode(output_file, options = EncodingOptions.new, **kwargs, &block)
      Transcoder.new(self, output_file, options, **kwargs).run(&block)
    end

    def screenshot(output_file, options = EncodingOptions.new, **kwargs, &block)
      transcode(output_file, options.merge(screenshot: true), **kwargs, &block)
    end

    protected

    def initialize_video_metadata(video_streams)
      # TODO: Handle multiple video codecs (is that possible?)
      video_stream = video_streams.first
      return if video_stream.nil?

      @video_stream_id = video_stream[:index]
      @video_codec = video_stream[:codec_name]
      @colorspace = video_stream[:pix_fmt]
      @width = video_stream[:width]
      @height = video_stream[:height]
      @video_bitrate = video_stream[:bit_rate].to_i
      @sar = video_stream[:sample_aspect_ratio]
      @dar = video_stream[:display_aspect_ratio]
      @frame_rate = (Rational(video_stream[:avg_frame_rate]) unless video_stream[:avg_frame_rate] == '0/0')

      @video_stream = "#{video_stream[:codec_name]} " \
                      "(#{video_stream[:profile]}) " \
                      "(#{video_stream[:codec_tag_string]} / #{video_stream[:codec_tag]}), " \
                      "#{colorspace}, #{resolution} " \
                      "[SAR #{sar} DAR #{dar}]"

      @rotation = if video_stream[:tags]&.key?(:rotate)
                    video_stream[:tags][:rotate].to_i
                  elsif video_stream[:side_data_list]&.first&.key?(:rotation)
                    rotation = video_stream[:side_data_list].first[:rotation].to_i
                    rotation.positive? ? 360 - rotation : rotation.abs
                  end
    end

    def initialize_audio_streams(audio_streams)
      @audio_streams = audio_streams.map do |audio_stream|
        {
          index: audio_stream[:index],
          channels: audio_stream[:channels].to_i,
          codec_name: audio_stream[:codec_name],
          sample_rate: audio_stream[:sample_rate].to_i,
          bitrate: audio_stream[:bit_rate].to_i,
          channel_layout: audio_stream[:channel_layout],
          tags: audio_stream[:streams],
          overview: "#{audio_stream[:codec_name]} " \
                    "(#{audio_stream[:codec_tag_string]} / #{audio_stream[:codec_tag]}), " \
                    "#{audio_stream[:sample_rate]} Hz, " \
                    "#{audio_stream[:channel_layout]}, " \
                    "#{audio_stream[:sample_fmt]}, " \
                    "#{audio_stream[:bit_rate]} bit/s"
        }
      end
    end

    def initialize_audio_metadata
      return if @audio_streams.empty?

      @audio_stream_id = @audio_streams.first[:index]
      @audio_channels = @audio_streams.first[:channels]
      @audio_codec = @audio_streams.first[:codec_name]
      @audio_sample_rate = @audio_streams.first[:sample_rate]
      @audio_bitrate = @audio_streams.first[:bitrate]
      @audio_channel_layout = @audio_streams.first[:channel_layout]
      @audio_tags = @audio_streams.first[:audio_tags]
      @audio_stream = @audio_streams.first[:overview]
    end

    def initialize_unsupported_stream_ids(stderr)
      @unsupported_stream_ids =
        [].tap do |stream_ids|
          stderr.each_line do |line|
            match = line.match(UNSUPPORTED_CODEC_PATTERN)
            stream_ids << match[2].to_i if match
          end
        end
    end

    def initialize_invalid(stderr)
      @invalid = true if unsupported_stream?(@video_stream_id) && unsupported_stream?(@audio_stream_id)
      @invalid = true if @metadata.key?(:error)
      @invalid = true if stderr.include?('could not find codec parameters')
    end

    def unsupported_stream?(stream_id)
      stream_id.nil? || @unsupported_stream_ids.include?(stream_id)
    end

    def aspect_from_dar
      calculate_aspect(dar)
    end

    def aspect_from_sar
      calculate_aspect(sar)
    end

    def calculate_aspect(ratio)
      return nil unless ratio

      w, h = ratio.split(':')
      return nil if w == '0' || h == '0'

      @rotation.nil? || (@rotation == 180) ? (w.to_f / h.to_f) : (h.to_f / w.to_f)
    end

    def aspect_from_dimensions
      aspect = width.to_f / height.to_f
      aspect.nan? ? nil : aspect
    end

    def fix_encoding(output)
      output[/test/] # Running a regexp on the string throws error if it's not UTF-8
    rescue ArgumentError
      output.force_encoding('ISO-8859-1')
    end

    def head(location = @path, limit = FFMPEG.max_http_redirect_attempts)
      url = URI(location)
      return unless url.path

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.port == 443
      response = http.request_head(url.request_uri)

      case response
      when Net::HTTPRedirection
        raise FFMPEG::HTTPTooManyRequests if limit.zero?

        redirect_url = url + URI(response['Location'])

        head(redirect_url, limit - 1)
      else
        response
      end
    rescue SocketError, Errno::ECONNREFUSED
      nil
    end
  end
end
