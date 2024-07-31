# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'bundler'
Bundler.require

require 'debug'
require 'fileutils'
require 'uri'
require 'webmock/rspec'
require 'webrick'

FFMPEG.logger = Logger.new(nil)

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.after(:suite) do
    FileUtils.rm_rf(tmp_dir)
  end
end

def fixture_dir
  @fixture_dir ||= File.join(File.dirname(__FILE__), 'fixtures')
end

def fixture_file(*path)
  File.join(fixture_dir, *path)
end

def fixture_media_dir
  @fixture_media_dir ||= File.join(fixture_dir, 'media')
end

def fixture_media_url
  'http://127.0.0.1:8000'
end

def fixture_media_file(*path, remote: false)
  if remote
    URI.join(fixture_media_url, *path).to_s
  else
    File.join(fixture_media_dir, *path)
  end
end

def read_fixture_file(*path)
  File.read(fixture_file(*path))
end

def tmp_dir
  @tmp_dir ||= File.join(File.dirname(__FILE__), '..', 'tmp')
end

def tmp_file(filename: nil, basename: nil, ext: nil)
  if filename.nil?
    filename = RSpec.current_example.metadata[:description].downcase.gsub(/[^\w]/, '_')
    filename += "_#{('a'..'z').to_a.sample(8).join}"
    filename += "_#{basename}" if basename
    filename += ".#{ext}" if ext
  end

  File.join(tmp_dir, filename)
end

def start_web_server
  @server = WEBrick::HTTPServer.new(
    Port: 8000,
    DocumentRoot: "#{fixture_dir}/media",
    Logger: WEBrick::Log.new(File.open(File::NULL, 'w')),
    AccessLog: []
  )

  @server.mount_proc '/unauthorized' do |_, response|
    response.body = 'Unauthorized'
    response.status = 403
  end

  @server.mount_proc '/moved' do |request, response|
    filename = request.path&.split('/')&.last
    raise WEBrick::HTTPStatus::ServerError unless filename

    response['Location'] = "/#{filename}"
    response.status = 302
  end

  Thread.new { @server.start }
end

def stop_web_server
  @server.shutdown
end

FileUtils.rm_rf(tmp_dir)
FileUtils.mkdir_p tmp_dir
