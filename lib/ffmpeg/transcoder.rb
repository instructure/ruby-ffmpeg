# frozen_string_literal: true

require 'open3'

module FFMPEG
  class Transcoder
    attr_reader :command, :output, :errors, :input_file, :output_file

    @timeout = 30

    class << self
      attr_accessor :timeout
    end

    def initialize(
      input,
      output_file,
      options = EncodingOptions.new,
      validate: true,
      preserve_aspect_ratio: true,
      input_options: []
    )
      if input.is_a?(FFMPEG::Movie)
        @movie = input
        @input_file = input.path
      elsif input.is_a?(String)
        @input_file = input
      end

      @output_file = output_file
      @options = options.is_a?(Hash) ? EncodingOptions.new(options) : options
      @validate = validate
      @preserve_aspect_ratio = preserve_aspect_ratio
      @input_options = input_options
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

      initialize_resolution
      initialize_screenshot

      @command = [FFMPEG.ffmpeg_binary, '-y', *@input_options, '-i', @input_file, *@options.to_a, @output_file]
    end

    def run(&block)
      execute(&block)
      return nil unless @validate

      validate_output_file(&block)
      encoded
    end

    def encoding_succeeded?
      @errors.empty?
    end

    def encoded
      @encoded ||= Movie.new(@output_file) if File.exist?(@output_file)
    end

    def timeout
      self.class.timeout
    end

    private

    def initialize_resolution
      return if @movie.nil? || @movie.calculated_aspect_ratio.nil?

      case @preserve_aspect_ratio.to_s
      when 'width'
        new_height = @options.width / @movie.calculated_aspect_ratio
        new_height = new_height.ceil.even? ? new_height.ceil : new_height.floor
        new_height += 1 if new_height.odd? # needed if new_height ended up with no decimals in the first place
        @options[:resolution] = "#{@options.width}x#{new_height}"
      when 'height'
        new_width = @options.height * @movie.calculated_aspect_ratio
        new_width = new_width.ceil.even? ? new_width.ceil : new_width.floor
        new_width += 1 if new_width.odd?
        @options[:resolution] = "#{new_width}x#{@options.height}"
      end
    end

    def initialize_screenshot
      # Moves any screenshot seek_time to an 'ss' custom arg

      timestamp = ''

      if @options.is_a?(Array)
        index = @options.find_index('-seek_time') unless @options.find_index('-screenshot').nil?
        unless index.nil?
          @options.delete_at(index) # delete 'seek_time'
          timestamp = @options.delete_at(index + 1).to_s # fetch the seek value
        end
      else
        timestamp = @options.delete(:seek_time).to_s unless @options[:screenshot].nil?
      end

      return if timestamp.to_s == ''

      index = @input_options.find_index('-ss')
      if index.nil?
        @input_options.push('-ss', timestamp)
      else
        @input_options[index + 1] = timestamp
      end
    end

    def validate_output_file
      @errors << 'no output file created' unless File.exist?(@output_file)
      @errors << 'encoded file is invalid' if encoded.nil? || !encoded.valid?

      if encoding_succeeded?
        yield(1.0) if block_given?
        FFMPEG.logger.info "Transcoding of #{@input_file} to #{@output_file} succeeded\n"
      else
        errors = "Errors: #{@errors.join(', ')}. "
        FFMPEG.logger.error "Failed encoding...\n#{@command}\n\n#{@output}\n#{errors}\n"
        raise Error, "Failed encoding. #{errors}Full output: #{@output}"
      end
    end

    def fix_encoding(output)
      output[/test/]
    rescue ArgumentError
      output.force_encoding('ISO-8859-1')
    end

    # frame= 4855 fps= 46 q=31.0 size=   45306kB time=00:02:42.28 bitrate=2287.0kbits/
    def execute
      FFMPEG.logger.info("Running transcoding...\n#{@command}\n")

      @output = String.new

      Open3.popen3(*@command) do |_stdin, _stdout, stderr, wait_thr|
        yield(0.0) if block_given?

        handler = proc do |line|
          fix_encoding(line)
          @output << line
          if line.include?('time=')
            time = if line =~ /time=(\d+):(\d+):(\d+.\d+)/ # ffmpeg 0.8 and above style
                     (Regexp.last_match(1).to_i * 3600) +
                       (Regexp.last_match(2).to_i * 60) +
                       Regexp.last_match(3).to_f
                   else # better make sure it wont blow up in case of unexpected output
                     0.0
                   end

            if @movie
              progress = time / @movie.duration
              yield(progress) if block_given?
            end
          end
        end

        if timeout
          stderr.each_with_timeout(wait_thr.pid, timeout, 'size=', &handler)
        else
          stderr.each('size=', &handler)
        end

        @errors << 'ffmpeg returned non-zero exit code' unless wait_thr.value.success?
      rescue Timeout::Error
        FFMPEG.logger.error "Process hung...\n@command\n#{@command}\nOutput\n#{@output}\n"
        raise Error, "Process hung. Full output: #{@output}"
      end
    end
  end
end
