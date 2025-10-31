# frozen_string_literal: true

require 'spec_helper'

describe FFMPEG do
  before do
    described_class.instance_variable_set(:@logger, nil)
    described_class.instance_variable_set(:@ffmpeg_binary, nil)
    described_class.instance_variable_set(:@ffmpeg_version, nil)
    described_class.instance_variable_set(:@ffprobe_binary, nil)
    described_class.instance_variable_set(:@ffprobe_version, nil)
  end

  after do
    described_class.instance_variable_set(:@logger, nil)
    described_class.instance_variable_set(:@ffmpeg_binary, nil)
    described_class.instance_variable_set(:@ffmpeg_version, nil)
    described_class.instance_variable_set(:@ffprobe_binary, nil)
    described_class.instance_variable_set(:@ffprobe_version, nil)
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

    it 'clears the cached ffmpeg version' do
      expect(File).to receive(:executable?).with('/path/to/ffmpeg').and_return(true)
      described_class.instance_variable_set(:@ffmpeg_version, '4.4.6')
      described_class.ffmpeg_binary = '/path/to/ffmpeg'
      expect(described_class.instance_variable_get(:@ffmpeg_version)).to be_nil
    end

    context 'when the assigned value is not executable' do
      it 'raises an error' do
        expect(File).to receive(:executable?).with('/path/to/ffmpeg').and_return(false)
        expect { described_class.ffmpeg_binary = '/path/to/ffmpeg' }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe '.ffmpeg_version' do
    it 'returns the version string from ffmpeg binary' do
      expect(FFMPEG::IO).to receive(:capture3)
        .with(described_class.ffmpeg_binary, '-version')
        .and_return(['ffmpeg version 4.4.6 Copyright (c) 2000-2025 the FFmpeg developers', ''])

      expect(described_class.ffmpeg_version).to eq('4.4.6')
    end

    it 'caches the version' do
      expect(FFMPEG::IO).to receive(:capture3)
        .once
        .with(described_class.ffmpeg_binary, '-version')
        .and_return(['ffmpeg version 8.0 Copyright (c) 2000-2025 the FFmpeg developers', ''])

      described_class.ffmpeg_version
      expect(described_class.ffmpeg_version).to eq('8.0')
    end

    it 'handles versions with different formats' do
      expect(FFMPEG::IO).to receive(:capture3)
        .with(described_class.ffmpeg_binary, '-version')
        .and_return(['ffmpeg version 5.1.2-static https://johnvansickle.com/ffmpeg/', ''])

      expect(described_class.ffmpeg_version).to eq('5.1.2')
    end
  end

  describe '.ffmpeg_version?' do
    context 'when the version matches the pattern' do
      it 'returns true' do
        expect(FFMPEG::IO).to receive(:capture3)
          .with(described_class.ffmpeg_binary, '-version')
          .and_return(['ffmpeg version 4.4.6 Copyright (c) 2000-2025 the FFmpeg developers', ''])

        expect(described_class.ffmpeg_version?('4.4')).to be true
        expect(described_class.ffmpeg_version?(/^4\.\d+/)).to be true
      end
    end

    context 'when the version does not match the pattern' do
      it 'returns false' do
        expect(FFMPEG::IO).to receive(:capture3)
          .with(described_class.ffmpeg_binary, '-version')
          .and_return(['ffmpeg version 4.4.6 Copyright (c) 2000-2025 the FFmpeg developers', ''])

        expect(described_class.ffmpeg_version?('5')).to be false
        expect(described_class.ffmpeg_version?(/^5/)).to be false
      end
    end
  end

  describe '.ffmpeg_execute' do
    it 'returns the process status' do
      args = ['-i', fixture_media_file('hello.wav'), '-f', 'null', '-']
      status = described_class.ffmpeg_execute(*args)

      expect(status).to be_a(FFMPEG::Status)
      expect(status.exitstatus).to eq(0)
    end

    context 'when ffmpeg hangs' do
      before do
        described_class.ffmpeg_binary = fixture_file('bin/mock-ffmpeg')
      end

      context 'with IO timeout set' do
        before do
          FFMPEG::IO.timeout = 0.5
        end

        after do
          FFMPEG::IO.remove_instance_variable(:@timeout)
        end

        it 'raises IO::TimeoutError' do
          expect { described_class.ffmpeg_execute!('hello', 'world') }.to raise_error(IO::TimeoutError)
        end
      end

      context 'with operation timeout set' do
        it 'raises Timeout::Error' do
          expect { described_class.ffmpeg_execute!('hello', 'world', timeout: 0.5) }.to raise_error(Timeout::Error)
        end
      end
    end
  end

  describe '.ffmpeg_execute!' do
    it 'raises an error when the process is unsuccessful' do
      expect { described_class.ffmpeg_execute!('-v') }.to raise_error(FFMPEG::Error)
    end

    context 'when called in a subprocess' do
      before do
        described_class.ffmpeg_binary = fixture_file('bin/mock-ffmpeg')
      end

      context 'with exit signal traps' do
        it 'does not raise an error' do
          pid = fork do
            Signal.trap('QUIT') {} # rubocop:disable Lint/EmptyBlock

            described_class.ffmpeg_execute!('-n=3', '-progress', 'hello', 'world')
          end

          sleep 1
          Process.kill('QUIT', pid)
          Process.wait(pid)

          expect($CHILD_STATUS&.exitstatus).to eq(0)
        end
      end

      context 'without exit signal traps' do
        it 'does not raise an error' do
          pid = fork do
            described_class.ffmpeg_execute!('-n=10', '-progress', 'hello', 'world')
          end

          sleep 1
          Process.kill('QUIT', pid)
          _, status = Process.wait2(pid)

          expect(status.exitstatus).not_to eq(0)
        end
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

    it 'clears the cached ffprobe version' do
      expect(File).to receive(:executable?).with('/path/to/ffprobe').and_return(true)
      described_class.instance_variable_set(:@ffprobe_version, '4.4.6')
      described_class.ffprobe_binary = '/path/to/ffprobe'
      expect(described_class.instance_variable_get(:@ffprobe_version)).to be_nil
    end

    context 'when the assigned value is not executable' do
      it 'raises an error' do
        expect(File).to receive(:executable?).with('/path/to/ffprobe').and_return(false)
        expect { described_class.ffprobe_binary = '/path/to/ffprobe' }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe '.ffprobe_version' do
    it 'returns the version string from ffprobe binary' do
      expect(FFMPEG::IO).to receive(:capture3)
        .with(described_class.ffprobe_binary, '-version')
        .and_return(['ffprobe version 4.4.6 Copyright (c) 2007-2025 the FFmpeg developers', ''])

      expect(described_class.ffprobe_version).to eq('4.4.6')
    end

    it 'caches the version' do
      expect(FFMPEG::IO).to receive(:capture3)
        .once
        .with(described_class.ffprobe_binary, '-version')
        .and_return(['ffprobe version 8.0 Copyright (c) 2007-2025 the FFmpeg developers', ''])

      described_class.ffprobe_version
      expect(described_class.ffprobe_version).to eq('8.0')
    end

    it 'handles versions with different formats' do
      expect(FFMPEG::IO).to receive(:capture3)
        .with(described_class.ffprobe_binary, '-version')
        .and_return(['ffprobe version 5.1.2-static https://johnvansickle.com/ffmpeg/', ''])

      expect(described_class.ffprobe_version).to eq('5.1.2')
    end
  end

  describe '.ffprobe_version?' do
    context 'when the version matches the pattern' do
      it 'returns true' do
        expect(FFMPEG::IO).to receive(:capture3)
          .with(described_class.ffprobe_binary, '-version')
          .and_return(['ffprobe version 4.4.6 Copyright (c) 2007-2025 the FFmpeg developers', ''])

        expect(described_class.ffprobe_version?('4.4')).to be true
        expect(described_class.ffprobe_version?(/^4\.\d+/)).to be true
      end
    end

    context 'when the version does not match the pattern' do
      it 'returns false' do
        expect(FFMPEG::IO).to receive(:capture3)
          .with(described_class.ffprobe_binary, '-version')
          .and_return(['ffprobe version 4.4.6 Copyright (c) 2007-2025 the FFmpeg developers', ''])

        expect(described_class.ffprobe_version?('5')).to be false
        expect(described_class.ffprobe_version?(/^5/)).to be false
      end
    end
  end
end
