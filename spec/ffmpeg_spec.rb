# frozen_string_literal: true

require 'spec_helper'

describe FFMPEG do
  describe '.logger' do
    after do
      FFMPEG.logger = Logger.new(nil)
    end

    it 'should be a Logger' do
      expect(FFMPEG.logger).to be_instance_of(Logger)
    end

    it 'should be at info level' do
      FFMPEG.logger = nil # Reset the logger so that we get the default
      expect(FFMPEG.logger.level).to eq(Logger::INFO)
    end

    it 'should be assignable' do
      new_logger = Logger.new($stdout)
      FFMPEG.logger = new_logger
      expect(FFMPEG.logger).to eq(new_logger)
    end
  end

  describe '.ffmpeg_binary' do
    before do
      FFMPEG.instance_variable_set(:@ffmpeg_binary, nil)
    end

    after do
      FFMPEG.instance_variable_set(:@ffmpeg_binary, nil)
    end

    it 'should default to finding from path' do
      allow(FFMPEG).to receive(:which) { '/usr/local/bin/ffmpeg' }
      allow(File).to receive(:executable?) { true }
      expect(FFMPEG.ffmpeg_binary).to eq FFMPEG.which('ffmpeg')
    end

    it 'should be assignable' do
      allow(File).to receive(:executable?).with('/new/path/to/ffmpeg') { true }
      FFMPEG.ffmpeg_binary = '/new/path/to/ffmpeg'
      expect(FFMPEG.ffmpeg_binary).to eq '/new/path/to/ffmpeg'
    end

    it 'should raise exception if it cannot find assigned executable' do
      expect { FFMPEG.ffmpeg_binary = '/new/path/to/ffmpeg' }.to raise_error(Errno::ENOENT)
    end

    it 'should raise exception if it cannot find executable on path' do
      allow(File).to receive(:executable?) { false }
      expect { FFMPEG.ffmpeg_binary }.to raise_error(Errno::ENOENT)
    end
  end

  describe '.ffprobe_binary' do
    before do
      FFMPEG.instance_variable_set(:@ffprobe_binary, nil)
    end

    after do
      FFMPEG.instance_variable_set(:@ffprobe_binary, nil)
    end

    it 'should default to finding from path' do
      allow(FFMPEG).to receive(:which) { '/usr/local/bin/ffprobe' }
      allow(File).to receive(:executable?) { true }
      expect(FFMPEG.ffprobe_binary).to eq FFMPEG.which('ffprobe')
    end

    it 'should be assignable' do
      allow(File).to receive(:executable?).with('/new/path/to/ffprobe') { true }
      FFMPEG.ffprobe_binary = '/new/path/to/ffprobe'
      expect(FFMPEG.ffprobe_binary).to eq '/new/path/to/ffprobe'
    end

    it 'should raise exception if it cannot find assigned executable' do
      expect { FFMPEG.ffprobe_binary = '/new/path/to/ffprobe' }.to raise_error(Errno::ENOENT)
    end

    it 'should raise exception if it cannot find executable on path' do
      allow(File).to receive(:executable?) { false }
      expect { FFMPEG.ffprobe_binary }.to raise_error(Errno::ENOENT)
    end
  end

  describe '.max_http_redirect_attempts' do
    after do
      FFMPEG.max_http_redirect_attempts = nil
    end

    it 'should default to 10' do
      expect(FFMPEG.max_http_redirect_attempts).to eq 10
    end

    it 'should be an Integer' do
      expect { FFMPEG.max_http_redirect_attempts = 1.23 }.to raise_error(ArgumentError)
    end

    it 'should not be negative' do
      expect { FFMPEG.max_http_redirect_attempts = -1 }.to raise_error(ArgumentError)
    end

    it 'should be assignable' do
      FFMPEG.max_http_redirect_attempts = 5
      expect(FFMPEG.max_http_redirect_attempts).to eq 5
    end
  end
end
