# frozen_string_literal: true

module FFMPEG
  describe Status do
    let(:output) { StringIO.new }
    let(:upstream) { instance_double(Process::Status) }

    subject { described_class.new }

    before do
      allow(StringIO).to receive(:new).and_return(output)
    end

    describe '#assert!' do
      before do
        subject.bind! { upstream }
      end

      context 'when the process was successful' do
        before do
          allow(upstream).to receive(:success?).and_return(true)
        end

        it 'does not raise an error' do
          expect(subject.assert!).to be(subject)
        end
      end

      context 'when the process was unsuccessful' do
        before do
          allow(upstream).to receive(:success?).and_return(false)
          allow(upstream).to receive(:exitstatus).and_return(999)
          allow(output).to receive(:string).and_return([
            'Copyright (c) 2000-2024 the FFmpeg developers',
            'Press [q] to stop, [?] for help',
            '[vf#0:0 @ 0x000000000000] Error reinitializing filters!',
            'frame=    0 fps=0.0 q=0.0 Lsize=       0KiB time=N/A bitrate=N/A speed=N/A',
            'Conversion failed!'
          ].join("\n"))
        end

        it 'raises an error' do
          expect { subject.assert! }.to raise_error(FFMPEG::Error, /\AError reinitializing filters! \(code: 999\)\z/)
        end
      end
    end

    describe '#bind!' do
      before do
        subject.bind! do
          sleep(0.1)
          upstream
        end
      end

      it 'freezes the object' do
        expect(subject).to be_frozen
        expect { subject.bind! { 'foo' } }.to raise_error(FrozenError)
      end

      it 'measures the duration of the block' do
        expect(subject.duration).to be >= 0.1
      end
    end

    describe '#method_missing' do
      before { subject.bind! { upstream } }

      it 'delegates to the upstream object' do
        expect(upstream).to receive(:exitstatus).and_return(999)
        expect(subject.exitstatus).to eq(999)
      end
    end
  end
end
