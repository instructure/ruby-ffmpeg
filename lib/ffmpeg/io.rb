# frozen_string_literal: true

require 'English'
require 'timeout'

if RUBY_PLATFORM =~ /(win|w)(32|64)$/
  begin
    require 'win32/process'
  rescue LoadError
    'Warning: ffmpeg is missing the win32-process gem to properly handle hung transcodings. ' \
    'Install the gem (in Gemfile if using bundler) to avoid errors.'
  end
end

# Monkey Patch timeout support into the IO class...
class IO
  def each_with_timeout(pid, seconds, separator = $INPUT_RECORD_SEPARATOR)
    last_tick = Time.now
    current_thr = Thread.current
    timeout_thr = Thread.new do
      loop do
        sleep 0.1
        current_thr.raise Timeout::Error.new('output wait time expired') if last_tick - Time.now < -seconds
      end
    end

    each(separator) do |buffer|
      last_tick = Time.now
      yield buffer
    end
  rescue Timeout::Error
    if RUBY_PLATFORM =~ /(win|w)(32|64)$/
      Process.kill(1, pid)
    else
      Process.kill('SIGKILL', pid)
    end
    raise
  ensure
    timeout_thr.kill
  end
end
