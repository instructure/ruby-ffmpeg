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
    it 'returns the process status' do
      args = ['-i', fixture_media_file('hello.wav'), '-f', 'null', '-']
      status = described_class.ffmpeg_execute(*args)

      expect(status).to be_a(FFMPEG::Status)
      expect(status.exitstatus).to eq(0)
    end

    it 'forwards spawn parameter to popen3' do
      spawn = { chdir: '/tmp/test' }

      expect(FFMPEG::IO).to receive(:popen3).with(any_args, chdir: '/tmp/test')
      described_class.ffmpeg_execute(spawn:)
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

    context 'when the assigned value is not executable' do
      it 'raises an error' do
        expect(File).to receive(:executable?).with('/path/to/ffprobe').and_return(false)
        expect { described_class.ffprobe_binary = '/path/to/ffprobe' }.to raise_error(Errno::ENOENT)
      end
    end
  end
end
