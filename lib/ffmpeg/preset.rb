# frozen_string_literal: true

require_relative 'command_args'

module FFMPEG
  # Represents a preset for a specific encoding configuration.
  # @!attribute [r] name
  # @!attribute [r] metadata
  class Preset
    attr_reader :name, :metadata

    # @param name [String] The name of the preset.
    # @param filename [String] The filename format for the output.
    # @param metadata [Hash] The metadata for the preset.
    # @param command_args_klass [Class] The class to use when composing command arguments.
    # @yield The block to execute to compose the command arguments.
    def initialize(name: nil, filename: nil, metadata: nil, command_args_klass: CommandArgs, &compose_args)
      @name = name
      @metadata = metadata
      @filename = filename
      @command_args_klass = command_args_klass
      @compose_args = compose_args
    end

    # Returns a rendered filename.
    #
    # @param kwargs [Hash] The key-value pairs to use when rendering the filename.
    # @return [String, nil] The rendered filename.
    def filename(**kwargs)
      return nil if @filename.nil?

      @filename % kwargs
    end

    # Returns the command arguments for the given media.
    #
    # @param media [Media] The media to encode.
    # @return [Array<String>] The command arguments.
    def args(media)
      @command_args_klass.compose(media, &@compose_args).to_a
    end

    # Transcode the media to the output path.
    #
    # @param media [Media] The media to transcode.
    # @param output_path [String, Pathname] The path to the output file.
    # @yield The block to execute when progress is made.
    # @return [FFMPEG::Transcoder::Status] The status of the transcoding process.
    def transcode(media, output_path, &)
      FFMPEG::Transcoder.new(presets: [self]).process(media, output_path, &)
    end
  end
end
