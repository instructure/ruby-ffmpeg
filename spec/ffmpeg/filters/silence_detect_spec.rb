# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  module Filters
    describe SilenceDetect do
      subject { described_class.new(threshold: '-30dB', duration: 1, mono: true) }

      describe '.scan' do
        it 'returns an array of silence ranges' do
          output = <<~OUTPUT
            silence_end: 1.000000 | silence_duration: 1.000000
            silence_end: 3.000000 | silence_duration: 1.000000
          OUTPUT

          ranges = described_class.scan(output)

          expect(ranges).to eq([
                                 described_class::Range.new(0.0, 1.0, 1.0),
                                 described_class::Range.new(2.0, 3.0, 1.0)
                               ])
        end
      end

      describe '#initialize' do
        it 'raises ArgumentError if threshold is not numeric or string' do
          expect { described_class.new(threshold: '-30dB') }.not_to raise_error
          expect { described_class.new(threshold: 1) }.not_to raise_error
          expect { described_class.new(threshold: 0.01) }.not_to raise_error
          expect { described_class.new(threshold: []) }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError if duration is not numeric' do
          expect { described_class.new(duration: 1) }.not_to raise_error
          expect { described_class.new(duration: 0.01) }.not_to raise_error
          expect { described_class.new(duration: '1') }.to raise_error(ArgumentError)
        end

        it 'sets the threshold' do
          expect(subject.threshold).to eq('-30dB')
        end

        it 'sets the duration' do
          expect(subject.duration).to eq(1)
        end

        it 'sets mono to true' do
          expect(subject.mono).to eq(true)
        end
      end

      describe '#to_s' do
        it 'returns the filter as a string' do
          expect(subject.to_s).to eq('silencedetect=n=-30dB:d=1:m=true')
        end
      end

      describe '#to_a' do
        it 'returns the filter as an array' do
          expect(subject.to_a).to eq(['-af', subject.to_s])
        end
      end
    end
  end
end
