# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe FFMPEG::DASH::HLSClassMethods do
  # Create a dummy class to test the module methods
  let(:test_class) do
    Class.new do
      include FFMPEG::DASH::HLSClassMethods
    end
  end

  subject { test_class.new }

  describe '#quote' do
    context 'with string values' do
      it 'returns quoted JSON string' do
        expect(subject.send(:quote, 'foo"bar')).to eq('"foo\\"bar"')
        expect(subject.send(:quote, "foo\nbar")).to eq('"foo\\nbar"')
      end
    end

    context 'with symbol values' do
      it 'returns quoted JSON string' do
        expect(subject.send(:quote, :foo)).to eq('"foo"')
      end
    end

    context 'with numeric values' do
      it 'returns quoted JSON string' do
        expect(subject.send(:quote, 123)).to eq('"123"')
        expect(subject.send(:quote, 45.67)).to eq('"45.67"')
      end
    end

    context 'with boolean values' do
      it 'returns quoted JSON string' do
        expect(subject.send(:quote, false)).to eq('"false"')
      end
    end

    context 'with nil values' do
      it 'returns nil' do
        expect(subject.send(:quote, nil)).to be_nil
      end
    end
  end

  describe '#m3u8t' do
    context 'with hash attributes' do
      it 'returns an HLS tag with hash attributes' do
        attributes = { 'TYPE' => 'AUDIO', 'GROUP-ID' => 'audio', 'NAME' => '"English"', 'CHANNELS' => nil }

        expect(
          subject.send(:m3u8t, 'EXT-X-MEDIA', attributes)
        ).to eq('#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=audio,NAME="English"')
      end
    end

    context 'with array attributes' do
      it 'returns an HLS tag with array attributes' do
        attributes = [3.0, '']

        expect(
          subject.send(:m3u8t, 'EXTINF', attributes)
        ).to eq('#EXTINF:3.0,')
      end
    end
  end
end
