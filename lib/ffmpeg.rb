# frozen_string_literal: true

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'logger'
require 'open3'

require_relative 'ffmpeg/command_args'
require_relative 'ffmpeg/errors'
require_relative 'ffmpeg/filter'
require_relative 'ffmpeg/filters/fps'
require_relative 'ffmpeg/filters/grayscale'
require_relative 'ffmpeg/filters/scale'
require_relative 'ffmpeg/filters/silence_detect'
require_relative 'ffmpeg/filters/split'
require_relative 'ffmpeg/io'
require_relative 'ffmpeg/media'
require_relative 'ffmpeg/preset'
require_relative 'ffmpeg/presets/aac'
require_relative 'ffmpeg/presets/dash'
require_relative 'ffmpeg/presets/dash/aac'
require_relative 'ffmpeg/presets/dash/h264'
require_relative 'ffmpeg/presets/h264'
require_relative 'ffmpeg/presets/thumbnail'
require_relative 'ffmpeg/raw_command_args'
require_relative 'ffmpeg/reporters/output'
require_relative 'ffmpeg/reporters/progress'
require_relative 'ffmpeg/reporters/silence'
require_relative 'ffmpeg/transcoder'
require_relative 'ffmpeg/version'

if RUBY_PLATFORM =~ /(win|w)(32|64)$/
  begin
    require 'win32/process'
  rescue LoadError
    'Warning: ffmpeg is missing the win32-process gem to properly handle hanging transcodings. ' \
    'Install the gem (in Gemfile if using bundler) to avoid errors.'
  end
end

# The FFMPEG module allows you to customise the behaviour of the FFMPEG library.
#
# @example
#   FFMPEG.logger = Logger.new($stdout)
#   FFMPEG.io_timeout = 60
#   FFMPEG.ffmpeg_binary = '/usr/local/bin/ffmpeg'
#   FFMPEG.ffprobe_binary = '/usr/local/bin/ffprobe'
module FFMPEG
  SIGKILL = RUBY_PLATFORM =~ /(win|w)(32|64)$/ ? 1 : 'SIGKILL'

  class << self
    attr_writer :logger, :io_timeout

    # Get the FFMPEG logger.
    #
    # @return [Logger]
    def logger
      @logger ||= Logger.new($stdout, level: Logger::INFO)
    end

    # Get the timeout that's used when waiting for ffmpeg output.
    # This timeout is used by ffmpeg_execute calls and the Transcoder class.
    # Defaults to 30 seconds.
    #
    # @return [Integer]
    def io_timeout
      @io_timeout ||= 30
    end

    # Set the path to the ffmpeg binary.
    #
    # @param path [String]
    # @return [String]
    # @raise [Errno::ENOENT] If the ffmpeg binary is not an executable.
    def ffmpeg_binary=(path)
      if path.is_a?(String) && !File.executable?(path)
        raise Errno::ENOENT,
              "The ffmpeg binary, '#{path}', is not executable"
      end

      @ffmpeg_binary = path
    end

    # Get the path to the ffmpeg binary.
    # Defaults to the first ffmpeg binary found in the PATH.
    #
    # @return [String]
    def ffmpeg_binary
      @ffmpeg_binary ||= which('ffmpeg')
    end

    # Safely captures the standard output and the standard error of the ffmpeg command.
    #
    # @return [Array] The standard output, the standard error, and the process status.
    def ffmpeg_capture3(*args)
      logger.debug(self) { "ffmpeg -y #{args.join(' ')}" }
      stdout, stderr, status = Open3.capture3(ffmpeg_binary, '-y', *args)
      FFMPEG::IO.encode!(stdout)
      FFMPEG::IO.encode!(stderr)
      [stdout, stderr, status]
    end

    # Starts a new ffmpeg process with the given arguments.
    # Yields the standard input, the standard output
    # and the standard error streams, as well as the child process
    # to the specified block.
    #
    # @yieldparam stdin (+IO+) The standard input stream.
    # @yieldparam stdout (+FFMPEG::IO+) The standard output stream.
    # @yieldparam stderr (+FFMPEG::IO+) The standard error stream.
    # @yieldparam wait_thr (+Thread+) The child process thread.
    # @return [void]
    def ffmpeg_popen3(*args, &block)
      logger.debug(self) { "ffmpeg -y #{args.join(' ')}" }
      Open3.popen3(ffmpeg_binary, '-y', *args) do |stdin, stdout, stderr, wait_thr|
        block.call(stdin, FFMPEG::IO.new(stdout), FFMPEG::IO.new(stderr), wait_thr)
      rescue StandardError
        wait_thr.kill
        wait_thr.join
        raise
      end
    end

    # Execute a ffmpeg command.
    #
    # @param args [Array<String>] The arguments to pass to ffmpeg.
    # @param reporters [Array<FFMPEG::Reporters::Output>] The reporters to use to parse the output.
    # @yield [report] Reports from the ffmpeg command (see FFMPEG::Reporters).
    # @return [Process::Status]
    def ffmpeg_execute(*args, reporters: [Reporters::Progress])
      ffmpeg_popen3(*args) do |_stdin, _stdout, stderr, wait_thr|
        stderr.each do |line|
          next unless block_given?

          reporter = reporters.find { |r| r.match?(line) }
          reporter ||= Reporters::Output
          report = reporter.new(line)
          yield report
        end

        wait_thr.value
      end
    end

    # Get the path to the ffprobe binary.
    # Defaults to the first ffprobe binary found in the PATH.
    #
    # @return [String] The path to the ffprobe binary.
    # @raise [Errno::ENOENT] If the ffprobe binary cannot be found.
    def ffprobe_binary
      @ffprobe_binary ||= which('ffprobe')
    end

    # Set the path of the ffprobe binary.
    # Can be useful if you need to specify a path such as /usr/local/bin/ffprobe.
    #
    # @param [String] path
    # @return [String]
    # @raise [Errno::ENOENT] If the ffprobe binary is not an executable.
    def ffprobe_binary=(path)
      if path.is_a?(String) && !File.executable?(path)
        raise Errno::ENOENT, "The ffprobe binary, '#{path}', is not executable"
      end

      @ffprobe_binary = path
    end

    # Safely captures the standard output and the standard error of the ffmpeg command.
    #
    # @return [Array] The standard output, the standard error, and the process status.
    # @raise [Errno::ENOENT] If the ffprobe binary cannot be found.
    def ffprobe_capture3(*args)
      logger.debug(self) { "ffprobe -y #{args.join(' ')}" }
      stdout, stderr, status = Open3.capture3(ffprobe_binary, '-y', *args)
      FFMPEG::IO.encode!(stdout)
      FFMPEG::IO.encode!(stderr)
      [stdout, stderr, status]
    end

    # Starts a new ffprobe process with the given arguments.
    # Yields the standard input, the standard output
    # and the standard error streams, as well as the child process
    # to the specified block.
    #
    # @yieldparam stdin (+IO+) The standard input stream.
    # @yieldparam stdout (+FFMPEG::IO+) The standard output stream.
    # @yieldparam stderr (+FFMPEG::IO+) The standard error stream.
    # @return [void]
    # @raise [Errno::ENOENT] If the ffprobe binary cannot be found.
    def ffprobe_popen3(*args, &block)
      logger.debug(self) { "ffprobe -y #{args.join(' ')}" }
      Open3.popen3(ffprobe_binary, '-y', *args) do |stdin, stdout, stderr, wait_thr|
        block.call(stdin, FFMPEG::IO.new(stdout), FFMPEG::IO.new(stderr), wait_thr)
      rescue StandardError
        wait_thr.kill
        wait_thr.join
        raise
      end
    end

    # Cross-platform way of finding an executable in the $PATH.
    # See http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
    #
    # @example
    #   which('ruby') #=> /usr/bin/ruby
    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          match = File.join(path, "#{cmd}#{ext}")
          return match if File.executable?(match)
        end
      end

      raise Errno::ENOENT, "The #{cmd} binary could not be found in the PATH"
    end
  end
end
