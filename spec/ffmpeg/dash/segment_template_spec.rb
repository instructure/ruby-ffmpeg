# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe FFMPEG::DASH::SegmentTemplate do
  let(:path) { 'spec/fixtures/media/dash.mpd' }
  let(:manifest) { FFMPEG::DASH::Manifest.parse(File.read(path)) }
  let(:segment_template) do
    manifest.adaptation_sets.first.representations.first.segment_template
  end

  describe '#timescale' do
    subject { segment_template.timescale }

    it 'returns the timescale' do
      is_expected.to eq(90_000)
    end
  end

  describe '#initialization' do
    subject { segment_template.initialization }

    it 'returns the initialization template' do
      is_expected.to eq('init-stream$RepresentationID$.m4s')
    end
  end

  describe '#media' do
    subject { segment_template.media }

    it 'returns the media template' do
      is_expected.to eq('chunk-stream$RepresentationID$-$Number%05d$.m4s')
    end
  end

  describe '#start_number' do
    subject { segment_template.start_number }

    it 'returns the start number' do
      is_expected.to eq(1)
    end
  end

  describe '#segment_timeline' do
    subject { segment_template.segment_timeline }

    it 'returns the segment timeline' do
      is_expected.to be_a(FFMPEG::DASH::SegmentTimeline)
    end
  end

  describe '#segment_query=' do
    before { segment_template.segment_query = 'foo=bar' }

    it 'includes query in the initialization template' do
      expect(segment_template.initialization).to include('foo=bar')
    end

    it 'includes query in the media template' do
      expect(segment_template.media).to include('foo=bar')
    end
  end

  describe '#to_ranges' do
    subject { segment_template.to_ranges.to_a }

    it 'returns the segment ranges' do
      is_expected.to eq([0.0..3.0, 3.0..6.0, 9.0..10.1])
    end
  end

  describe '#initialization_filename' do
    it 'returns the formatted initialization filename' do
      expect(segment_template.initialization_filename).to eq('init-stream0.m4s')
    end
  end

  describe '#media_filename' do
    it 'returns the formatted media filename for segments' do
      expect(segment_template.media_filename(0)).to eq('chunk-stream0-00001.m4s')
      expect(segment_template.media_filename(1)).to eq('chunk-stream0-00002.m4s')
      expect(segment_template.media_filename(5)).to eq('chunk-stream0-00006.m4s')
    end
  end
end
