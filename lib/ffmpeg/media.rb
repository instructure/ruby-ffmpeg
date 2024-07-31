# frozen_string_literal: true

require 'multi_json'
require 'net/http'
require 'uri'
require 'tempfile'

require_relative 'errors'
require_relative 'stream'

module FFMPEG
  # The Media class represents a multimedia file and provides methods
  # to inspect its metadata.
  # It accepts a local path or remote URL to a multimedia file as input.
  # It uses ffprobe to get the streams and format of the multimedia file.
  class Media
    class LoadError < FFMPEG::Error; end

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

    # @param path [String] The local path or remote URL to a multimedia file.
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
        raise LoadError, e.message.capitalize
      end

      if @metadata.key?(:error)
        raise LoadError, "#{@metadata[:error][:string].capitalize} (code #{@metadata[:error][:code]})"
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

    # Whether the media is a remote URL.
    #
    # @return [Boolean]
    def remote?
      @remote ||= @path =~ URI::DEFAULT_PARSER.make_regexp(%w[http https]) ? true : false
    end

    # Whether the media is a local path.
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

    # Get all video streams (if any).
    #
    # @return [Array<Stream>, nil]
    autoload def video_streams
      return @video_streams if instance_variable_defined?(:@video_streams)

      @video_streams = @streams&.select(&:video?)
    end

    # Get the default video stream (if any).
    #
    # @return [Stream, nil]
    autoload def video
      return @video if instance_variable_defined?(:@video)

      @video = video_streams&.find(&:default?) || video_streams&.first
    end

    # Get the width of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def width
      video&.width
    end

    # Get the height of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def height
      video&.height
    end

    # Get the rotation of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def rotation
      video&.rotation
    end

    # Get the resolution of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def resolution
      video&.resolution
    end

    # Get the display aspect ratio of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def display_aspect_ratio
      video&.display_aspect_ratio
    end

    # Get the sample aspect ratio of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def sample_aspect_ratio
      video&.sample_aspect_ratio
    end

    # Get the calculated aspect ratio of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def calculated_aspect_ratio
      video&.calculated_aspect_ratio
    end

    # Get the calculated pixel aspect ratio of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def calculated_pixel_aspect_ratio
      video&.calculated_pixel_aspect_ratio
    end

    # Get the color range of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def color_range
      video&.color_range
    end

    # Get the color space of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def color_space
      video&.color_space
    end

    # Get the frame rate of the default video stream (if any).
    #
    # @return [Float, nil]
    autoload def frame_rate
      video&.frame_rate
    end

    # Get the number of frames of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def frames
      video&.frames
    end

    # Whether the media has a video stream.
    #
    # @return [Boolean]
    autoload def video?
      !video.nil?
    end

    # Whether the media only has video streams.
    #
    # @return [Boolean]
    autoload def video_only?
      video? && !audio?
    end

    # Get the index of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def video_index
      video&.index
    end

    # Get the mapping index of the default video stream (if any).
    # (Can be used as an output option for ffmpeg to select the video stream.)
    #
    # @return [Integer, nil]
    autoload def video_mapping_index
      video_streams&.index(video)
    end

    # Get the profile of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def video_profile
      video&.profile
    end

    # Get the codec name of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def video_codec_name
      video&.codec_name
    end

    # Get the codec type of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def video_codec_type
      video&.codec_type
    end

    # Get the bit rate of the default video stream (if any).
    #
    # @return [Integer, nil]
    autoload def video_bit_rate
      video&.bit_rate
    end

    # Get the overview of the default video stream (if any).
    #
    # @return [String, nil]
    autoload def video_overview
      video&.overview
    end

    # Get the tags of the default video stream (if any).
    #
    # @return [Hash, nil]
    autoload def video_tags
      video&.tags
    end

    # Get all audio streams (if any).
    #
    # @return [Array<Stream>, nil]
    autoload def audio_streams
      return @audio_streams if instance_variable_defined?(:@audio_streams)

      @audio_streams = @streams&.select(&:audio?)
    end

    # Get the default audio stream (if any).
    #
    # @return [Stream, nil]
    autoload def audio
      return @audio if instance_variable_defined?(:@audio)

      @audio = audio_streams&.find(&:default?) || audio_streams&.first
    end

    # Whether the media has an audio stream.
    #
    # @return [Boolean]
    autoload def audio?
      audio&.length&.positive?
    end

    # Whether the media only has audio streams.
    #
    # @return [Boolean]
    autoload def audio_only?
      audio? && !video?
    end

    # Whether the media has an audio stream with one or more attached pictures.
    #
    # @return [Boolean]
    autoload def audio_with_attached_pic?
      audio? && streams.any?(&:attached_pic?)
    end

    # Whether the media is silent (no audio streams).
    #
    # @return [Boolean]
    autoload def silent?
      !audio?
    end

    # Get the index of the default audio stream (if any).
    #
    # @return [Integer, nil]
    autoload def audio_index
      audio&.index
    end

    # Get the mapping index of the default audio stream (if any).
    # (Can be used as an output option for ffmpeg to select the audio stream.)
    #
    # @return [Integer, nil]
    autoload def audio_mapping_index
      audio_streams&.index(audio)
    end

    # Get the profile of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_profile
      audio&.profile
    end

    # Get the codec name of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_codec_name
      audio&.codec_name
    end

    # Get the codec type of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_codec_type
      audio&.codec_type
    end

    # Get the bit rate of the default audio stream (if any).
    #
    # @return [Integer, nil]
    autoload def audio_bit_rate
      audio&.bit_rate
    end

    # Get the channels of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_channels
      audio&.channels
    end

    # Get the channel layout of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_channel_layout
      audio&.channel_layout
    end

    # Get the sample rate of the default audio stream (if any).
    #
    # @return [Integer, nil]
    autoload def audio_sample_rate
      audio&.sample_rate
    end

    # Get the overview of the default audio stream (if any).
    #
    # @return [String, nil]
    autoload def audio_overview
      audio&.overview
    end

    # Get the tags of the default audio stream (if any).
    #
    # @return [Hash, nil]
    autoload def audio_tags
      audio&.tags
    end

    # Execute an ffmpeg command with the media as input.
    #
    # @param args [Array<String>] The arguments to pass to ffmpeg.
    # @param inargs [Array<String>] The arguments to pass before the input.
    # @yield [report] Reports from the ffmpeg command (see FFMPEG::Reporters).
    # @return [Process::Status]
    def ffmpeg_execute(*args, inargs: [], reporters: nil, &block)
      if reporters.is_a?(Array)
        FFMPEG.ffmpeg_execute(*inargs, '-i', path, *args, reporters: reporters, &block)
      else
        FFMPEG.ffmpeg_execute(*inargs, '-i', path, *args, &block)
      end
    end
  end
end
