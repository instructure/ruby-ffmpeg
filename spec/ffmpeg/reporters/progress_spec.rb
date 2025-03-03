# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  module Reporters
    describe Progress do
      subject do
        described_class.new(
          'frame=  210 fps= 90 q=-1.0 Lsize=    3366KiB time=00:00:03.46 bitrate=7953.3kbits/s dup=1 drop=0 speed=1.49x'
        )
      end

      describe '.match?' do
        context 'when the line starts with size, time or frame' do
          it 'returns true' do
            expect(Progress.match?('size=1')).to be(true)
            expect(Progress.match?('time=1')).to be(true)
            expect(Progress.match?('frame=1')).to be(true)
          end
        end

        context 'when the line does not start with size, time or frame' do
          it 'returns false' do
            expect(Progress.match?('foo=1')).to be(false)
          end
        end
      end

      describe '#frame' do
        it 'returns the current frame number' do
          expect(subject.frame).to eq(210)
        end
      end

      describe '#fps' do
        it 'returns the current frame rate' do
          expect(subject.fps).to eq(90.0)
        end
      end

      describe '#size' do
        it 'returns the current size of the output file' do
          expect(subject.size).to eq('3366KiB')
        end
      end

      describe '#time' do
        it 'returns the current time within the media' do
          expect(subject.time).to eq(3.46)
        end
      end

      describe '#bit_rate' do
        it 'returns the current bit rate' do
          expect(subject.bit_rate).to eq('7953.3kbits/s')
        end
      end

      describe '#speed' do
        it 'returns the current processing speed' do
          expect(subject.speed).to eq(1.49)
        end
      end
    end
  end
end
