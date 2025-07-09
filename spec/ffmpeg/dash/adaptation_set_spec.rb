# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe FFMPEG::DASH::AdaptationSet do
  let(:path) { 'spec/fixtures/media/dash.mpd' }
  let(:manifest) { FFMPEG::DASH::Manifest.parse(File.read(path)) }
  let(:video_adaptation_set) { manifest.adaptation_sets.find { |s| s.content_type == 'video' } }
  let(:audio_adaptation_set) { manifest.adaptation_sets.find { |s| s.content_type == 'audio' } }

  describe '#id' do
    it 'returns the id' do
      expect(video_adaptation_set.id).to eq(0)
      expect(audio_adaptation_set.id).to eq(1)
    end
  end

  describe '#par' do
    it 'returns the par' do
      expect(video_adaptation_set.par).to eq('16:9')
    end
  end

  describe '#content_type' do
    it 'returns the content type' do
      expect(video_adaptation_set.content_type).to eq('video')
      expect(audio_adaptation_set.content_type).to eq('audio')
    end
  end

  describe '#max_width' do
    it 'returns the max width' do
      expect(video_adaptation_set.max_width).to eq(1920)
    end
  end

  describe '#max_height' do
    it 'returns the max height' do
      expect(video_adaptation_set.max_height).to eq(1080)
    end
  end

  describe '#frame_rate' do
    it 'returns the frame rate' do
      expect(video_adaptation_set.frame_rate).to eq(30.to_r)
    end
  end

  describe '#representations' do
    it 'returns the representations' do
      expect(video_adaptation_set.representations.count).to eq(2)
      expect(audio_adaptation_set.representations.count).to eq(1)
    end
  end

  describe '#base_url=' do
    it 'sets the base url on all representations' do
      video_adaptation_set.base_url = 'http://example.com/'
      video_adaptation_set.representations.each do |representation|
        expect(representation.at_xpath('.//xmlns:BaseURL').content).to eq('http://example.com/')
      end
    end
  end

  describe '#segment_query=' do
    it 'sets the segment query on all segment templates' do
      video_adaptation_set.segment_query = 'foo=bar'
      video_adaptation_set.representations.each do |representation|
        expect(representation.segment_template.initialization).to match(/\?foo=bar$/)
        expect(representation.segment_template.media).to match(/\?foo=bar$/)
      end
    end
  end
end
