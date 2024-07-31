# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  describe Filters do
    describe '.silence_detect' do
      it 'returns a new SilenceDetect filter' do
        expect(described_class.silence_detect.to_s).to eq('silencedetect')
      end
    end
  end

  module Filters
    describe SilenceDetect do
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
      end

      describe '#to_s' do
        it 'returns the filter as a string' do
          filter = described_class.new(threshold: '-30dB', duration: 1, mono: true)
          expect(filter.to_s).to eq('silencedetect=n=-30dB:d=1:m=true')

          filter = described_class.new
          expect(filter.to_s).to eq('silencedetect')
        end
      end
    end
  end
end
