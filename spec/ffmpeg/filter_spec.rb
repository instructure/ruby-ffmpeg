# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  describe Filter do
    describe '#initialize' do
      context 'when the type is invalid' do
        it 'raises an ArgumentError' do
          expect do
            described_class.new(:x, 'foo')
          end.to raise_error(ArgumentError, 'Unknown type x, expected FFMPEG::Filter::Type')
        end
      end

      context 'when the name is not a string' do
        it 'raises an ArgumentError' do
          expect do
            described_class.new(described_class::Type::AUDIO, 1)
          end.to raise_error(ArgumentError, 'Unknown name format Integer, expected String')
        end
      end
    end

    describe '#to_s' do
      context 'when the kwargs are empty' do
        it 'returns the name' do
          filter = described_class.new(described_class::Type::AUDIO, 'foo')
          expect(filter.to_s).to eq('foo')
        end
      end

      context 'when the kwargs contain only nil values' do
        it 'returns the name' do
          filter = described_class.new(described_class::Type::AUDIO, 'foo', bar: nil, baz: nil)
          expect(filter.to_s).to eq('foo')
        end
      end

      context 'when the kwargs are not empty' do
        it 'returns the name and options' do
          filter = described_class.new(
            described_class::Type::AUDIO,
            'foo',
            bar: "'[Vive La Liberté]'",
            baz: [1, 2],
            fizz: nil,
            buzz: true
          )

          expect(filter.to_s).to eq("foo=bar='\\'[Vive La Liberté]\\'':baz=1|2:buzz=true")
        end
      end
    end
  end
end
