# frozen_string_literal: true

require 'multi_json'
require 'uri'

require_relative 'errors'
require_relative 'stream'

module FFMPEG
  # The Media class represents a multimedia file and provides methods
  # to inspect its metadata.
  # It accepts a local path or remote URL to a multimedia file as input.
  # It uses ffprobe to get the streams and format of the multimedia file.
  #
  # @example
  #  media = FFMPEG::Media.new('/path/to/media.mp4')
  #  media.video? # => true
  #  media.video_streams? # => true
  #  media.audio? # => false
  #  media.audio_streams? # => true
  #  media.local? # => true
  #
  # @example
  #  media = FFMPEG::Media.new('https://example.com/media.mp4', load: false)
  #  media.loaded? # => false
  #  media.video? # => true (loaded automatically)
  #  media.loaded? # => true
  #  media.remote? # => true
  #
  # @example
  #  media = FFMPEG::Media.new('/path/to/media.mp4', load: false, autoload: false)
  #  media.loaded? # => false
  #  media.video? # => raises 'Media not loaded'
  #  media.load!
  #  media.video? # => true
  class Media
    # Raised if media metadata cannot be loaded.
    class LoadError < Error
      attr_reader :output

      def initialize(message, output)
        @output = output
        super(message)
      end
    end

    private_class_method def self.autoload(*method_names)
      method_names.flatten!
      method_names.each do |method_name|
        method = instance_method(method_name)
        define_method(method_name) do |*args, &block|
          if loaded?
            method.bind(self).call(*args, &block)
          elsif @autoload
            load!
            method.bind(self).call(*args, &block)
          else
            raise 'Media not loaded'
          end
        end
      end
    end

    attr_reader :path

    autoload attr_reader :size, :metadata, :streams, :tags,
                         :format_name, :format_long_name,
                         :start_time, :bit_rate, :duration

    # @param path [String, Pathname, URI] The local path or remote URL to a multimedia file.
    # @param ffprobe_args [Array<String>] Additional arguments to pass to ffprobe.
    # @param load [Boolean] Whether to load the metadata immediately.
    # @param autoload [Boolean] Whether to autoload the metadata when accessing attributes.
    def initialize(path, *ffprobe_args, load: true, autoload: true)
      @path = path.to_s
      @ffprobe_args = ffprobe_args
      @autoload = autoload
      @loaded = false
      @mutex = Mutex.new
      load! if load
    end

    # Load the metadata of the multimedia file.
    #
    # @return [Boolean]
    def load!
      @mutex.lock

      return @loaded if @loaded

      stdout, stderr, = FFMPEG.ffprobe_capture3(
        '-i', @path, '-print_format', 'json',
        '-show_format', '-show_streams', '-show_error',
        *@ffprobe_args
      )

      begin
        @metadata = MultiJson.load(stdout, symbolize_keys: true)
      rescue MultiJson::ParseError => e
        raise LoadError.new(e.message.capitalize, stdout)
      end

      if @metadata.key?(:error)
        raise LoadError.new(
          "#{@metadata[:error][:string].capitalize} (code #{@metadata[:error][:code]})",
          stdout
        )
      end

      @size = @metadata[:format][:size].to_i
      @streams = @metadata[:streams].map { |metadata| Stream.new(metadata, stderr) }
      @tags = @metadata[:format][:tags]

      @format_name = @metadata[:format][:format_name]
      @format_long_name = @metadata[:format][:format_long_name]

      @start_time = @metadata[:format][:start_time].to_f
      @bit_rate = @metadata[:format][:bit_rate].to_i
      @duration = @metadata[:format][:duration].to_f

      @valid = @streams.any?(&:supported?)

      @loaded = true
    ensure
      @mutex.unlock
    end

    # Whether the media has been loaded.
    #
    # @return [Boolean]
    def loaded?
      @loaded
    end

    # Whether the media is on a remote URL.
    #
    # @return [Boolean]
    def remote?
      @remote ||= @path =~ URI::DEFAULT_PARSER.make_regexp(%w[http https]) ? true : false
    end

    # Whether the media is at a local path.
    #
    # @return [Boolean]
    def local?
      !remote?
    end

    # Whether the media is valid (there is at least one stream that is supported).
    #
    # @return [Boolean]
    autoload def valid?
      @valid
    end

    # Returns the major brand of the media (if any).
    autoload def major_brand
      tags&.fetch(:major_brand, nil)&.to_s&.strip
    end

    # Returns all video streams.
    #
    # @return [Array<Stream>, nil]
    autoload def video_streams
      return @video_streams if instance_variable_defined?(:@video_streams)

      @video_streams = @streams.select(&:video?)
    end

    # Whether the media has video streams.
    #
    # @return [Boolean]
    autoload def video_streams?
      !video_streams.empty?
    end

    # Whether the media has a video stream (excluding attached pictures).
    #
    # @return [Boolean]
    autoload def video?
      video_streams.any? { |stream| !stream.attached_pic? }
    end

    # Returns the default video stream (if any).
    #
    # @return [Stream, nil]
    autoload def default_video_stream
      return @default_video_stream if instance_variable_defined?(:@default_video_stream)

      @default_video_stream = video_streams.find(&:default?) || video_streams.first
    end

    # Whether the media is HDR (High Dynamic Range).
    #
    # @return [Boolean]
    autoload def hdr?
      default_video_stream&.color_primaries == 'bt2020' &&
        default_video_stream&.color_space == 'bt2020nc' &&
        %w[smpte2084 arib-std-b67].include?(default_video_stream&.color_transfer)
    end

    # Whether the media is rotated (based on the default video stream).
    # (e.g. 90°, 180°, 270°)
    #
    # @return [Boolean]
    autoload def rotated?
      default_video_stream&.rotated? || false
    end

    # Whether the media is portrait (based on the default video stream).
    #
    # @return [Boolean]
    autoload def portrait?
      default_video_stream&.portrait? || false
    end

    # Whether the media is landscape (based on the default video stream).
    #
    # @return [Boolean]
    autoload def landscape?
      default_video_stream&.landscape? || false
    end

    # Returns the width of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def width
      default_video_stream&.width
    end

    # Returns the raw (unrotated) width of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def raw_width
      default_video_stream&.raw_width
    end

    # Returns the height of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def height
      default_video_stream&.height
    end

    # Returns the raw (unrotated) height of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def raw_height
      default_video_stream&.raw_height
    end

    # Returns the rotation of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def rotation
      default_video_stream&.rotation
    end

    # Returns the resolution of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def resolution
      default_video_stream&.resolution
    end

    # Returns the display aspect ratio of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def display_aspect_ratio
      default_video_stream&.display_aspect_ratio
    end

    # Returns the raw display aspect ratio of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def raw_display_aspect_ratio
      default_video_stream&.raw_display_aspect_ratio
    end

    # Returns the sample aspect ratio of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def sample_aspect_ratio
      default_video_stream&.sample_aspect_ratio
    end

    # Returns the raw sample aspect ratio of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def raw_sample_aspect_ratio
      default_video_stream&.raw_sample_aspect_ratio
    end

    # Returns the pixel format of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def pixel_format
      default_video_stream&.pixel_format
    end

    # Returns the color range of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def color_range
      default_video_stream&.color_range
    end

    # Returns the color space of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def color_space
      default_video_stream&.color_space
    end

    # Returns the color primaries of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def color_primaries
      default_video_stream&.color_primaries
    end

    # Returns the color transfer of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def color_transfer
      default_video_stream&.color_transfer
    end

    # Returns the frame rate (avg_frame_rate) of the default video stream (if any).
    #
    # @return [Float, nil]
    autoload def frame_rate
      default_video_stream&.frame_rate
    end

    # Returns the number of frames of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def frames
      default_video_stream&.frames
    end

    # Returns the index of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def video_index
      default_video_stream&.index
    end

    # Returns the mapping index of the default video stream (if any).
    # (Can be used as an output option for ffmpeg to select the video stream.)
    #
    # @return [Integer, nil]
    autoload def video_mapping_index
      video_streams.index(default_video_stream)
    end

    # Returns the mapping ID of the default video stream (if any).
    # (Can be used as an output option for ffmpeg to select the video stream.)
    # (e.g. "-map v:0" to select the first video stream.)
    #
    # @return [String, nil]
    autoload def video_mapping_id
      index = video_mapping_index
      return if index.nil?

      "v:#{index}"
    end

    # Returns the profile of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def video_profile
      default_video_stream&.profile
    end

    # Returns the codec name of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def video_codec_name
      default_video_stream&.codec_name
    end

    # Returns the bit rate of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def video_bit_rate
      default_video_stream&.bit_rate
    end

    # Returns the overview of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def video_overview
      default_video_stream&.overview
    end

    # Returns the tags of the default video stream (if any).
    #
    # @return [Hash, nil]
    autoload def video_tags
      default_video_stream&.tags
    end

    # Returns all audio streams.
    #
    # @return [Array<Stream>, nil]
    autoload def audio_streams
      return @audio_streams if instance_variable_defined?(:@audio_streams)

      @audio_streams = @streams.select(&:audio?)
    end

    # Whether the media has audio streams.
    #
    # @return [Boolean]
    autoload def audio_streams?
      audio_streams && !audio_streams.empty?
    end

    # Whether the media only contains audio streams and optional attached pictures.
    #
    # @return [Boolean]
    autoload def audio?
      audio_streams? && video_streams.all?(&:attached_pic?)
    end

    # Whether the media is silent (no audio streams).
    #
    # @return [Boolean]
    autoload def silent?
      !audio_streams?
    end

    # Returns the default audio stream (if any).
    #
    # @return [Stream, nil]
    autoload def default_audio_stream
      return @default_audio_stream if instance_variable_defined?(:@default_audio_stream)

      @default_audio_stream = audio_streams.find(&:default?) || audio_streams.first
    end

    # Returns the index of the default audio stream (if any).
    #
    # @return [Integer, nil]
    autoload def audio_index
      default_audio_stream&.index
    end

    # Returns the mapping index of the default audio stream (if any).
    # (Can be used as an output option for ffmpeg to select the audio stream.)
    #
    # @return [Integer, nil]
    autoload def audio_mapping_index
      audio_streams.index(default_audio_stream)
    end

    # Returns the mapping ID of the default audio stream (if any).
    # (Can be used as an output option for ffmpeg to select the audio stream.)
    # (e.g. "-map a:0" to select the first audio stream.)
    #
    # @return [String, nil]
    autoload def audio_mapping_id
      index = audio_mapping_index
      return if index.nil?

      "a:#{index}"
    end

    # Returns the profile of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_profile
      default_audio_stream&.profile
    end

    # Returns the codec name of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_codec_name
      default_audio_stream&.codec_name
    end

    # Returns the bit rate of the default audio stream (if any).
    #
    # @return [Integer, nil]
    autoload def audio_bit_rate
      default_audio_stream&.bit_rate
    end

    # Returns the channels of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_channels
      default_audio_stream&.channels
    end

    # Returns the channel layout of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_channel_layout
      default_audio_stream&.channel_layout
    end

    # Returns the sample rate of the default audio stream (if any).
    #
    # @return [Integer, nil]
    autoload def audio_sample_rate
      default_audio_stream&.sample_rate
    end

    # Returns the overview of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_overview
      default_audio_stream&.overview
    end

    # Returns the tags of the default audio stream (if any).
    #
    # @return [Hash, nil]
    autoload def audio_tags
      default_audio_stream&.tags
    end

    # Execute a ffmpeg command with the media as input.
    #
    # @param args [Array<String>] The arguments to pass to ffmpeg.
    # @param inargs [Array<String>] The arguments to pass before the input.
    # @yield [report] Reports from the ffmpeg command (see FFMPEG::Reporters).
    # @return [Process::Status]
    def ffmpeg_execute(*args, inargs: [], status: nil, reporters: nil, timeout: nil, &block)
      FFMPEG.ffmpeg_execute(*inargs, '-i', path, *args, status:, reporters:, timeout:, &block)
    end

    # Execute a ffmpeg command with the media as input
    # and raise an error if the subprocess did not finish successfully.
    #
    # @param args [Array<String>] The arguments to pass to ffmpeg.
    # @param inargs [Array<String>] The arguments to pass before the input.
    # @yield [report] Reports from the ffmpeg command (see FFMPEG::Reporters).
    # @return [Process::Status]
    def ffmpeg_execute!(*args, inargs: [], status: nil, reporters: nil, timeout: nil, &block)
      ffmpeg_execute(*args, inargs:, status:, reporters:, timeout:, &block).assert!
    end
  end
end
