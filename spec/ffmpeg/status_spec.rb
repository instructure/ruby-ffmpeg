# frozen_string_literal: true

module FFMPEG
  describe Status do
    let(:upstream) { double('upstream') }

    subject { described_class.new }

    describe '#assert!' do
      before do
        subject.bind!(upstream)
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

          subject.output.puts('Copyright (c) 2000-2024 the FFmpeg developers')
          subject.output.puts('Press [q] to stop, [?] for help')
          subject.output.puts('[vf#0:0 @ 0x000000000000] Error reinitializing filters!')
          subject.output.puts('frame=    0 fps=0.0 q=0.0 Lsize=       0KiB time=N/A bitrate=N/A speed=N/A')
          subject.output.puts('Conversion failed!')
        end

        it 'raises an error' do
          expect { subject.assert! }.to raise_error(FFMPEG::Error, /\AError reinitializing filters! \(code: 999\)\z/)
        end
      end
    end

    describe '#bind!' do
      before { subject.bind!(upstream) }

      it 'freezes the object' do
        expect(subject).to be_frozen
        expect { subject.bind!('foo') }.to raise_error(FrozenError)
      end
    end

    describe '#method_missing' do
      before { subject.bind!(upstream) }

      it 'delegates to the upstream object' do
        expect(upstream).to receive(:foo).and_return('bar')
        expect(subject.foo).to eq('bar')
      end
    end
  end
end
