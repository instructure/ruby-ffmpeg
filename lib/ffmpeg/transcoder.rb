# frozen_string_literal: true

require 'timeout'

module FFMPEG
  # The Transcoder class is responsible for transcoding multimedia files.
  # It accepts a Media object or a path to a multimedia file as input.
  class Transcoder
    attr_reader :args, :output, :errors, :input_path, :output_path

    @timeout = 30

    class << self
      attr_accessor :timeout
    end

    def initialize(
      input,
      output_path,
      options,
      validate: true,
      preserve_aspect_ratio: true,
      input_options: [],
      filters: []
    )
      if input.is_a?(Media)
        @media = input
        @input_path = input.path
      elsif input.is_a?(String)
        @input_path = input
      end

      @output_path = output_path
      @options = options.is_a?(Hash) ? EncodingOptions.new(options) : options
      @validate = validate
      @preserve_aspect_ratio = preserve_aspect_ratio
      @input_options = input_options
      @filters = filters
      @errors = []

      if @input_options.is_a?(Hash)
        @input_options = @input_options.reduce([]) do |acc, (key, value)|
          acc.push("-#{key}", value.to_s)
        end
      end

      unless @options.is_a?(Array) || @options.is_a?(EncodingOptions)
        raise ArgumentError, "Unknown options format '#{@options}', should be either EncodingOptions, Hash or Array."
      end

      unless @input_options.is_a?(Array)
        raise ArgumentError, "Unknown input_options format '#{@input_options}', should be either Hash or Array."
      end

      prepare_resolution
      prepare_seek_time

      @args = ['-y', *@input_options, '-i', @input_path,
               *@options.to_a, *@filters.map(&:to_a).flatten,
               @output_path]
    end

    def command
      [FFMPEG.ffmpeg_binary, *@args]
    end

    def run(&block)
      execute(&block)
      return nil unless @validate

      validate_output_file(&block)
      result
    end

    def succeeded?
      @errors.empty?
    end

    def failed?
      !succeeded?
    end

    def result
      @result ||= Media.new(@output_path) if File.exist?(@output_path)
    end

    def timeout
      self.class.timeout
    end

    private

    def prepare_resolution
      return unless @preserve_aspect_ratio
      return if @media&.video&.calculated_aspect_ratio.nil?

      case @preserve_aspect_ratio.to_s
      when 'width'
        height = @options.width / @media.video.calculated_aspect_ratio
        height = height.ceil.even? ? height.ceil : height.floor
        height += 1 if height.odd? # needed if height ended up with no decimals in the first place
        @options[:resolution] = "#{@options.width}x#{height}"
      when 'height'
        width = @options.height * @media.video.calculated_aspect_ratio
        width = width.ceil.even? ? width.ceil : width.floor
        width += 1 if width.odd?
        @options[:resolution] = "#{width}x#{@options.height}"
      end
    end

    def prepare_seek_time
      # Moves any seek_time to an 'ss' input option

      seek_time = ''

      if @options.is_a?(Array)
        index = @options.find_index('-ss')
        unless index.nil?
          @options.delete_at(index) # delete 'ss'
          seek_time = @options.delete_at(index + 1).to_s # fetch the seek value
        end
      else
        seek_time = @options.delete(:seek_time).to_s
      end

      return if seek_time.to_s == ''

      index = @input_options.find_index('-ss')
      if index.nil?
        @input_options.push('-ss', seek_time)
      else
        @input_options[index + 1] = seek_time
      end
    end

    def validate_output_file
      @errors << 'no output file created' unless File.exist?(@output_path)
      @errors << 'encoded file is invalid' if result.nil? || !result.valid?

      if succeeded?
        yield(1.0) if block_given?
        FFMPEG.logger.info "Transcoding of #{@input_path} to #{@output_path} succeeded\n"
      else
        errors = "Errors: #{@errors.join(', ')}. "
        FFMPEG.logger.error "Failed encoding...\n#{command.join(' ')}\n\n#{@output}\n#{errors}\n"
        raise Error, "Failed encoding. #{errors}Full output: #{@output}"
      end
    end

    def execute
      FFMPEG.logger.info("Running transcoding...\n#{command.join(' ')}\n")

      @output = String.new

      FFMPEG.ffmpeg_popen3(*@args) do |_stdin, stdout, stderr, wait_thr|
        yield(0.0) if block_given?

        if timeout
          stdout.timeout = timeout
          stderr.timeout = timeout
        end

        stderr.each do |line|
          @output << line

          next unless @media
          next unless block_given?
          next unless line =~ /time=(\d+):(\d+):(\d+.\d+)/ # time=00:02:42.28

          time = (::Regexp.last_match(1).to_i * 3600) +
                 (::Regexp.last_match(2).to_i * 60) +
                 ::Regexp.last_match(3).to_f
          yield(time / @media.duration)
        end

        @errors << 'ffmpeg returned non-zero exit code' unless wait_thr.value.success?
      rescue Timeout::Error
        Process.kill(FFMPEG::SIGKILL, wait_thr.pid)
        FFMPEG.logger.error "Process hung...\n#{command.join(' ')}\nOutput\n#{@output}\n"
        raise Error, "Process hung. Full output: #{@output}"
      end
    end
  end
end
