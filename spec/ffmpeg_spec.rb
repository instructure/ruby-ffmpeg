# frozen_string_literal: true

require 'spec_helper'

describe FFMPEG do
  before do
    described_class.instance_variable_set(:@logger, nil)
    described_class.instance_variable_set(:@ffmpeg_binary, nil)
    described_class.instance_variable_set(:@ffprobe_binary, nil)
  end

  after do
    described_class.instance_variable_set(:@logger, nil)
    described_class.instance_variable_set(:@ffmpeg_binary, nil)
    described_class.instance_variable_set(:@ffprobe_binary, nil)
  end

  describe '.logger' do
    it 'defaults to a Logger with info level' do
      expect(described_class.logger).to be_instance_of(Logger)
      expect(described_class.logger.level).to eq(Logger::INFO)
    end
  end

  describe '.logger=' do
    it 'assigns the logger' do
      logger = Logger.new($stdout)
      described_class.logger = logger
      expect(described_class.logger).to eq(logger)
    end
  end

  describe '.ffmpeg_binary' do
    it 'defaults to finding from path' do
      expect(described_class).to receive(:which).and_return('/path/to/ffmpeg')
      expect(described_class.ffmpeg_binary).to eq('/path/to/ffmpeg')
    end
  end

  describe '.ffmpeg_binary=' do
    it 'assigns the ffmpeg binary' do
      expect(File).to receive(:executable?).with('/path/to/ffmpeg').and_return(true)
      described_class.ffmpeg_binary = '/path/to/ffmpeg'
      expect(described_class.ffmpeg_binary).to eq('/path/to/ffmpeg')
    end

    context 'when the assigned value is not executable' do
      it 'raises an error' do
        expect(File).to receive(:executable?).with('/path/to/ffmpeg').and_return(false)
        expect { described_class.ffmpeg_binary = '/path/to/ffmpeg' }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe '.ffmpeg_execute' do
    let(:args) { ['-i', fixture_media_file('hello.wav'), '-f', 'null', '/dev/null'] }

    it 'returns the process status and yields reports' do
      reports = []

      status = described_class.ffmpeg_execute(*args) do |report|
        reports << report
      end

      expect(status).to be_a(Process::Status)
      expect(status.exitstatus).to eq(0)
      expect(reports.length).to be >= 1
    end

    context 'when ffmpeg hangs' do
      before do
        FFMPEG::IO.timeout = 0.5
        FFMPEG.ffmpeg_binary = fixture_file('bin/ffmpeg-hanging')
      end

      after do
        FFMPEG::IO.remove_instance_variable(:@timeout)
        FFMPEG.ffmpeg_binary = nil
      end

      it 'raises IO::TimeoutError' do
        expect { described_class.ffmpeg_execute(*args) }.to raise_error(IO::TimeoutError)
      end
    end
  end

  describe '.ffprobe_binary' do
    it 'defaults to finding from path' do
      expect(described_class).to receive(:which).and_return('/path/to/ffprobe')
      expect(described_class.ffprobe_binary).to eq('/path/to/ffprobe')
    end
  end

  describe '.ffprobe_binary=' do
    it 'assigns the ffprobe binary' do
      expect(File).to receive(:executable?).with('/path/to/ffprobe').and_return(true)
      described_class.ffprobe_binary = '/path/to/ffprobe'
      expect(described_class.ffprobe_binary).to eq '/path/to/ffprobe'
    end

    context 'when the assigned value is not executable' do
      it 'raises an error' do
        expect(File).to receive(:executable?).with('/path/to/ffprobe').and_return(false)
        expect { described_class.ffprobe_binary = '/path/to/ffprobe' }.to raise_error(Errno::ENOENT)
      end
    end
  end
end
