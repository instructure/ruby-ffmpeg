# frozen_string_literal: true

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'logger'
require 'net/http'
require 'open3'
require 'uri'

require_relative 'ffmpeg/version'
require_relative 'ffmpeg/errors'
require_relative 'ffmpeg/filter'
require_relative 'ffmpeg/filters/grayscale'
require_relative 'ffmpeg/filters/scale'
require_relative 'ffmpeg/filters/silence_detect'
require_relative 'ffmpeg/io'
require_relative 'ffmpeg/media'
require_relative 'ffmpeg/reporters/output'
require_relative 'ffmpeg/reporters/progress'
require_relative 'ffmpeg/reporters/silence'
require_relative 'ffmpeg/preset'
require_relative 'ffmpeg/presets/h264'
require_relative 'ffmpeg/transcoder'

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

  # FFMPEG logs information about its progress when it's transcoding.
  # Jack in your own logger through this method if you wish to.
  #
  # @param logger [Logger]
  # @return [Logger]
  def self.logger=(logger)
    @logger = logger
  end

  # Get the FFMPEG logger.
  #
  # @return [Logger]
  def self.logger
    @logger ||= Logger.new($stdout, level: Logger::INFO)
  end

  # Set the timeout that's used when waiting for ffmpeg output.
  # This timeout is used by all streaming calls to ffmpeg (*_popen3, ffmpeg_execute).
  #
  # @param [Integer]
  def self.io_timeout=(value)
    @io_timeout = value
  end

  # Get the timeout that's used when waiting for ffmpeg output.
  # This timeout is used by ffmpeg_execute calls and the Transcoder class.
  # Defaults to 30 seconds.
  #
  # @return [Integer]
  def self.io_timeout
    @io_timeout ||= 30
  end

  # Set the path to the ffmpeg binary.
  #
  # @param bin [String]
  # @return [String]
  def self.ffmpeg_binary=(bin)
    raise Errno::ENOENT, "The ffmpeg binary, '#{bin}', is not executable" if bin.is_a?(String) && !File.executable?(bin)

    @ffmpeg_binary = bin
  end

  # Get the path to the ffmpeg binary.
  #
  # @return [String]
  def self.ffmpeg_binary
    @ffmpeg_binary ||= which('ffmpeg')
  end

  # Safely captures the standard output and the standard error of the ffmpeg command.
  #
  # @return [[String, String, Process::Status]] The standard output, the standard error, and the process status
  def self.ffmpeg_capture3(*args)
    FFMPEG.logger.debug { "ffmpeg: ffmpeg -y #{args.join(' ')}" }
    stdout, stderr, status = Open3.capture3(ffmpeg_binary, '-y', *args)
    FFMPEG::IO.encode!(stdout)
    FFMPEG::IO.encode!(stderr)
    [stdout, stderr, status]
  end

  # Starts a new ffmpeg process with the given arguments.
  #
  # @yield [stdin, stdout, stderr, wait_thr] The standard input, the standard output, the standard error, and the child process thread.
  # @return [void]
  def self.ffmpeg_popen3(*args, &block)
    FFMPEG.logger.debug { "ffmpeg: ffmpeg -y #{args.join(' ')}" }
    Open3.popen3(ffmpeg_binary, '-y', *args) do |stdin, stdout, stderr, wait_thr|
      block.call(stdin, FFMPEG::IO.new(stdout), FFMPEG::IO.new(stderr), wait_thr)
    rescue StandardError
      wait_thr.kill
      wait_thr.join
      raise
    end
  end

  # Execute an ffmpeg command.
  #
  # @param args [Array<String>] The arguments to pass to ffmpeg.
  # @param reporters [Array<FFMPEG::Reporters>] The reporters to use to parse the output.
  # @yield [report] Reports from the ffmpeg command (see FFMPEG::Reporters).
  # @return [Process::Status]
  def self.ffmpeg_execute(*args, reporters: [Reporters::Progress])
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

  # Get the path to the ffprobe binary, defaulting to what is on ENV['PATH']
  #
  # @return [String] the path to the ffprobe binary
  # @raise [Errno::ENOENT] if the ffprobe binary cannot be found
  def self.ffprobe_binary
    @ffprobe_binary ||= which('ffprobe')
  end

  # Set the path of the ffprobe binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/ffprobe
  #
  # @param [String] path to the ffprobe binary
  # @return [String] the path you set
  # @raise [Errno::ENOENT] if the ffprobe binary cannot be found
  def self.ffprobe_binary=(bin)
    if bin.is_a?(String) && !File.executable?(bin)
      raise Errno::ENOENT, "The ffprobe binary, '#{bin}', is not executable"
    end

    @ffprobe_binary = bin
  end

  # Safely captures the standard output and the standard error of the ffmpeg command.
  #
  # @return [[String, String, Process::Status]] the standard output, the standard error, and the process status
  # @raise [Errno::ENOENT] if the ffprobe binary cannot be found
  def self.ffprobe_capture3(*args)
    FFMPEG.logger.debug { "ffmpeg: ffprobe -y #{args.join(' ')}" }
    stdout, stderr, status = Open3.capture3(ffprobe_binary, '-y', *args)
    FFMPEG::IO.encode!(stdout)
    FFMPEG::IO.encode!(stderr)
    [stdout, stderr, status]
  end

  # Starts a new ffprobe process with the given arguments.
  # Yields the the standard input (#<FFMPEG::IO>), the standard output (#<FFMPEG::IO>)
  # and the standard error (#<FFMPEG::IO>) streams, as well as the child process Thread
  # to the specified block.
  #
  # @return [void]
  # @raise [Errno::ENOENT] if the ffprobe binary cannot be found
  def self.ffprobe_popen3(*args, &block)
    FFMPEG.logger.debug { "ffmpeg: ffprobe -y #{args.join(' ')}" }
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
  def self.which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable? exe
      end
    end
    raise Errno::ENOENT, "The #{cmd} binary could not be found in #{ENV.fetch('PATH', nil)}"
  end
end
