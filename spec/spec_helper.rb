# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'bundler'
Bundler.require

require 'fileutils'
require 'webmock/rspec'
require 'webrick'
WebMock.allow_net_connect!

FFMPEG.logger = Logger.new(nil)

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    stub_request(:head, 'http://127.0.0.1:8000/moved/awesome_movie.mov')
      .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
      .to_return(status: 302, headers: { location: '/awesome_movie.mov' })
    stub_request(:head, 'http://127.0.0.1:8000/notfound/awesome_movie.mov')
      .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
      .to_return(status: 404, headers: {})
  end

  config.after(:suite) do
    FileUtils.rm_rf(tmp_path)
  end
end

def fixture_path
  @fixture_path ||= File.join(File.dirname(__FILE__), 'fixtures')
end

def tmp_path
  @tmp_path ||= File.join(File.dirname(__FILE__), '..', 'tmp')
end

def read_fixture_file(filename)
  File.read(File.join(fixture_path, filename))
end

def tmp_file(filename: nil, basename: nil, ext: nil)
  if filename.nil?
    filename = RSpec.current_example.metadata[:description].downcase.gsub(/[^\w]/, '_')
    filename += "_#{('a'..'z').to_a.sample(8).join}"
    filename += "_#{basename}" if basename
    filename += ".#{ext}" if ext
  end

  File.join(tmp_path, filename)
end

def start_web_server
  @server = WEBrick::HTTPServer.new(
    Port: 8000,
    DocumentRoot: "#{fixture_path}/movies",
    Logger: WEBrick::Log.new(File.open(File::NULL, 'w')),
    AccessLog: []
  )

  @server.mount_proc '/unauthorized.mov' do |_, response|
    response.body = 'Unauthorized'
    response.status = 403
  end

  Thread.new { @server.start }
end

def stop_web_server
  @server.shutdown
end

FileUtils.rm_rf(tmp_path)
FileUtils.mkdir_p tmp_path
