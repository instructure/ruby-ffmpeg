# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  describe Filter do
    describe '#initialize' do
      context 'when the type is invalid' do
        it 'raises an ArgumentError' do
          expect do
            described_class.new(:x, 'foo')
          end.to raise_error(ArgumentError, 'Unknown type x, expected :video or :audio')
        end
      end

      context 'when the name is not a string' do
        it 'raises an ArgumentError' do
          expect do
            described_class.new(:video, 1)
          end.to raise_error(ArgumentError, 'Unknown name format Integer, expected String')
        end
      end
    end

    describe '#with_input_links' do
      it 'returns a clone of the filter with the input links' do
        filter = described_class.new(:video, 'scale', w: -2, h: 720)
        expect(filter.with_input_links('0:v').to_s).to eq('[0:v]scale=w=-2:h=720')
        expect(filter.input_links).to eq([])
      end
    end

    describe '#with_input_links!' do
      it 'returns the filter with the input links' do
        filter = described_class.new(:video, 'scale', w: -2, h: 720)
        expect(filter.with_input_links!('0:v').to_s).to eq('[0:v]scale=w=-2:h=720')
        expect(filter.input_links).to eq(['0:v'])
      end

      it 'overwrites the input links' do
        filter = described_class.new(:video, 'scale', w: -2, h: 720)
        filter.with_input_links!('0:v').with_input_links!('1:v')
        expect(filter.input_links).to eq(['1:v'])
      end
    end

    describe '#with_input_link' do
      it 'returns a clone of the filter with the added input link' do
        filter = described_class.new(:video, 'scale', w: -2, h: 720)
        filter.with_input_link!('0:v')
        expect(filter.with_input_link('1:v').to_s).to eq('[0:v][1:v]scale=w=-2:h=720')
        expect(filter.input_links).to eq(['0:v'])
      end
    end

    describe '#with_input_link!' do
      it 'returns the filter with the added input link' do
        filter = described_class.new(:video, 'scale', w: -2, h: 720)
        filter.with_input_link!('0:v')
        expect(filter.with_input_link!('1:v').to_s).to eq('[0:v][1:v]scale=w=-2:h=720')
        expect(filter.input_links).to eq(%w[0:v 1:v])
      end
    end

    describe '#with_output_links' do
      it 'returns a clone of the filter with the output links' do
        filter = described_class.new(:video, 'scale', w: -2, h: 720)
        expect(filter.with_output_links('v0').to_s).to eq('scale=w=-2:h=720[v0]')
        expect(filter.output_links).to eq([])
      end
    end

    describe '#with_output_links!' do
      it 'returns the filter with the output links' do
        filter = described_class.new(:video, 'scale', w: -2, h: 720)
        expect(filter.with_output_links!('v0').to_s).to eq('scale=w=-2:h=720[v0]')
        expect(filter.output_links).to eq(['v0'])
      end

      it 'overwrites the output links' do
        filter = described_class.new(:video, 'scale', w: -2, h: 720)
        filter.with_output_links!('v0').with_output_links!('v1')
        expect(filter.output_links).to eq(['v1'])
      end
    end

    describe '#with_output_link' do
      it 'returns a clone of the filter with the added output link' do
        filter = described_class.new(:video, 'scale', w: -2, h: 720)
        filter.with_output_link!('v0')
        expect(filter.with_output_link('v1').to_s).to eq('scale=w=-2:h=720[v0][v1]')
        expect(filter.output_links).to eq(['v0'])
      end
    end

    describe '#with_output_link!' do
      it 'returns the filter with the added output link' do
        filter = described_class.new(:video, 'scale', w: -2, h: 720)
        filter.with_output_link!('v0')
        expect(filter.with_output_link!('v1').to_s).to eq('scale=w=-2:h=720[v0][v1]')
        expect(filter.output_links).to eq(%w[v0 v1])
      end
    end

    describe '#to_s' do
      context 'when the kwargs are empty' do
        it 'returns the name' do
          filter = described_class.new(:audio, 'foo')
          expect(filter.to_s).to eq('foo')
        end
      end

      context 'when the kwargs contain only nil values' do
        it 'returns the name' do
          filter = described_class.new(:audio, 'foo', bar: nil, baz: nil)
          expect(filter.to_s).to eq('foo')
        end
      end

      context 'when the kwargs are not empty' do
        it 'returns the name and options' do
          filter = described_class.new(
            :audio,
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
