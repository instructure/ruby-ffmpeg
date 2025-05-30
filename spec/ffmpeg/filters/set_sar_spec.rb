# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  describe Filters do
    describe '.set_sar' do
      it 'returns a new SetSAR filter' do
        expect(described_class.set_sar(Rational(16, 9)).to_s).to eq('setsar=16/9')
      end
    end
  end

  module Filters
    describe SetSAR do
      describe '#initialize' do
        it 'raises ArgumentError if frame_rate is not numeric or string' do
          expect { described_class.new(30) }.not_to raise_error
          expect { described_class.new(0.01) }.not_to raise_error
          expect { described_class.new(Rational(16, 9)) }.not_to raise_error
          expect { described_class.new('30') }.not_to raise_error
          expect { described_class.new([]) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
