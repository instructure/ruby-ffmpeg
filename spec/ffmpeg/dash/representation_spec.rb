# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe FFMPEG::DASH::Representation do
  let(:path) { 'spec/fixtures/media/dash.mpd' }
  let(:manifest) { FFMPEG::DASH::Manifest.parse(File.read(path)) }
  let(:video_representation) { manifest.adaptation_sets.find { |s| s.content_type == 'video' }.representations.first }
  let(:audio_representation) { manifest.adaptation_sets.find { |s| s.content_type == 'audio' }.representations.first }

  describe '#id' do
    it 'returns the id' do
      expect(video_representation.id).to eq(0)
      expect(audio_representation.id).to eq(2)
    end
  end

  describe '#mime_type' do
    it 'returns the mime type' do
      expect(video_representation.mime_type).to eq('video/mp4')
      expect(audio_representation.mime_type).to eq('audio/mp4')
    end
  end

  describe '#codecs' do
    it 'returns the codecs' do
      expect(video_representation.codecs).to eq('avc1.640028')
      expect(audio_representation.codecs).to eq('mp4a.40.2')
    end
  end

  describe '#bandwidth' do
    it 'returns the bandwidth' do
      expect(video_representation.bandwidth).to eq(2_500_000)
      expect(audio_representation.bandwidth).to eq(128_000)
    end
  end

  describe '#sar' do
    it 'returns the sar' do
      expect(video_representation.sar).to eq('1:1')
    end
  end

  describe '#width' do
    it 'returns the width' do
      expect(video_representation.width).to eq(1920)
    end
  end

  describe '#height' do
    it 'returns the height' do
      expect(video_representation.height).to eq(1080)
    end
  end

  describe '#resolution' do
    it 'returns the resolution based on width and height' do
      expect(video_representation.resolution).to eq('1920x1080')
      expect(audio_representation.resolution).to be_nil
    end
  end

  describe '#segment_template' do
    it 'returns the segment template' do
      expect(video_representation.segment_template).to be_a(FFMPEG::DASH::SegmentTemplate)
    end
  end

  describe '#base_url' do
    before do
      video_representation.add_child('<BaseURL>http://example.com/</BaseURL>')
    end

    it 'returns the base url' do
      expect(video_representation.base_url).to eq('http://example.com/')
      expect(audio_representation.base_url).to be_nil
    end
  end

  describe '#base_url=' do
    it 'sets the base url' do
      video_representation.base_url = 'http://example.com/'
      expect(video_representation.at_xpath('.//xmlns:BaseURL').content).to eq('http://example.com/')
    end
  end

  describe '#segment_query=' do
    it 'sets the segment query' do
      video_representation.segment_query = 'foo=bar'
      expect(video_representation.segment_template.initialization).to match(/\?foo=bar$/)
      expect(video_representation.segment_template.media).to match(/\?foo=bar$/)
    end
  end

  describe '#to_ranges' do
    it 'returns the segment ranges' do
      expect(video_representation.to_ranges.to_a).to eq(
        [0.0..3.0, 3.0..6.0, 9.0..10.1]
      )
      expect(audio_representation.to_ranges.to_a).to eq(
        [0.0..2.98958, 2.98958..5.98958, 5.98958..8.98958, 8.98958..10.1]
      )
    end
  end
end
