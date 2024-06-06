# frozen_string_literal: true

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'logger'
require 'net/http'
require 'open3'
require 'uri'

require_relative 'ffmpeg/version'
require_relative 'ffmpeg/encoding_options'
require_relative 'ffmpeg/errors'
require_relative 'ffmpeg/timeout'
require_relative 'ffmpeg/io'
require_relative 'ffmpeg/media'
require_relative 'ffmpeg/stream'
require_relative 'ffmpeg/transcoder'
require_relative 'ffmpeg/filters/filter'
require_relative 'ffmpeg/filters/grayscale'
require_relative 'ffmpeg/filters/silence_detect'

if RUBY_PLATFORM =~ /(win|w)(32|64)$/
  begin
    require 'win32/process'
  rescue LoadError
    'Warning: ffmpeg is missing the win32-process gem to properly handle hung transcodings. ' \
    'Install the gem (in Gemfile if using bundler) to avoid errors.'
  end
end

# The FFMPEG module allows you to customise the behaviour of the FFMPEG library.
#
# @example
#   FFMPEG.ffmpeg_binary = '/usr/local/bin/ffmpeg'
#   FFMPEG.ffprobe_binary = '/usr/local/bin/ffprobe'
#   FFMPEG.logger = Logger.new(STDOUT)
module FFMPEG
  SIGKILL = RUBY_PLATFORM =~ /(win|w)(32|64)$/ ? 1 : 'SIGKILL'

  # FFMPEG logs information about its progress when it's transcoding.
  # Jack in your own logger through this method if you wish to.
  #
  # @param [Logger] log your own logger
  # @return [Logger] the logger you set
  def self.logger=(log)
    @logger = log
  end

  # Get FFMPEG logger.
  #
  # @return [Logger]
  def self.logger
    return @logger if @logger

    logger = Logger.new($stdout)
    logger.level = Logger::INFO
    @logger = logger
  end

  # Set the path of the ffmpeg binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/ffmpeg
  #
  # @param [String] path to the ffmpeg binary
  # @return [String] the path you set
  # @raise Errno::ENOENT if the ffmpeg binary cannot be found
  def self.ffmpeg_binary=(bin)
    raise Errno::ENOENT, "The ffmpeg binary, '#{bin}', is not executable" if bin.is_a?(String) && !File.executable?(bin)

    @ffmpeg_binary = bin
  end

  # Get the path to the ffmpeg binary, defaulting to 'ffmpeg'
  #
  # @return [String] the path to the ffmpeg binary
  # @raise Errno::ENOENT if the ffmpeg binary cannot be found
  def self.ffmpeg_binary
    @ffmpeg_binary ||= which('ffmpeg')
  end

  # Safely captures the standard output and the standard error of the ffmpeg command.
  #
  # @return [[String, String, Process::Status]] the standard output, the standard error, and the process status
  # @raise [Errno::ENOENT] if the ffmpeg binary cannot be found
  def self.ffmpeg_capture3(*args)
    stdout, stderr, status = Open3.capture3(ffmpeg_binary, *args)
    FFMPEG::IO.encode!(stdout)
    FFMPEG::IO.encode!(stderr)
    [stdout, stderr, status]
  end

  # Starts a new ffmpeg process with the given arguments.
  # Yields the the standard input (#<FFMPEG::IO>), the standard output (#<FFMPEG::IO>)
  # and the standard error (#<FFMPEG::IO>) streams, as well as the child process Thread
  # to the specified block.
  #
  # @return [void]
  # @raise [Errno::ENOENT] if the ffmpeg binary cannot be found
  def self.ffmpeg_popen3(*args, &block)
    Open3.popen3(ffmpeg_binary, *args) do |stdin, stdout, stderr, wait_thr|
      block.call(stdin, FFMPEG::IO.new(stdout), FFMPEG::IO.new(stderr), wait_thr)
    end
  end

  # Get the path to the ffprobe binary, defaulting to what is on ENV['PATH']
  #
  # @return [String] the path to the ffprobe binary
  # @raise Errno::ENOENT if the ffprobe binary cannot be found
  def self.ffprobe_binary
    @ffprobe_binary ||= which('ffprobe')
  end

  # Set the path of the ffprobe binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/ffprobe
  #
  # @param [String] path to the ffprobe binary
  # @return [String] the path you set
  # @raise Errno::ENOENT if the ffprobe binary cannot be found
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
    stdout, stderr, status = Open3.capture3(ffprobe_binary, *args)
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
    Open3.popen3(ffprobe_binary, *args) do |stdin, stdout, stderr, wait_thr|
      block.call(stdin, FFMPEG::IO.new(stdout), FFMPEG::IO.new(stderr), wait_thr)
    end
  end

  # Get the maximum number of http redirect attempts
  #
  # @return [Integer] the maximum number of retries
  def self.max_http_redirect_attempts
    @max_http_redirect_attempts.nil? ? 10 : @max_http_redirect_attempts
  end

  # Set the maximum number of http redirect attempts.
  #
  # @param [Integer] the maximum number of retries
  # @return [Integer] the number of retries you set
  # @raise Errno::ENOENT if the value is negative or not an Integer
  def self.max_http_redirect_attempts=(value)
    if value && !value.is_a?(Integer)
      raise ArgumentError, 'Unknown max_http_redirect_attempts format, must be an Integer'
    end
    raise ArgumentError, 'Invalid max_http_redirect_attempts format, may not be negative' if value&.negative?

    @max_http_redirect_attempts = value
  end

  # Sends a HEAD request to a remote URL.
  # Follows redirects up to the maximum number of attempts.
  #
  # @return [Net::HTTPResponse, nil] the response object
  # @raise [FFMPEG::HTTPTooManyRedirects] if the maximum number of redirects is exceeded
  def self.fetch_http_head(url, max_redirect_attempts = max_http_redirect_attempts)
    uri = URI(url)
    return unless uri.path

    conn = Net::HTTP.new(uri.host, uri.port)
    conn.use_ssl = uri.port == 443
    response = conn.request_head(uri.request_uri)

    case response
    when Net::HTTPRedirection
      raise HTTPTooManyRedirects if max_redirect_attempts.zero?

      redirect_uri = uri + URI(response.header['Location'])

      fetch_http_head(redirect_uri, max_redirect_attempts - 1)
    else
      response
    end
  rescue SocketError, Errno::ECONNREFUSED
    nil
  end

  # Cross-platform way of finding an executable in the $PATH.
  #
  #   which('ruby') #=> /usr/bin/ruby
  # see: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
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
