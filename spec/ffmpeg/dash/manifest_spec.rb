# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe FFMPEG::DASH::Manifest do
  let(:path) { 'spec/fixtures/media/dash.mpd' }
  let(:manifest) { described_class.parse(File.read(path)) }

  describe '#type' do
    it 'returns the type' do
      expect(manifest.type).to eq('static')
    end
  end

  describe '#adaptation_sets' do
    it 'returns the adaptation sets' do
      expect(manifest.adaptation_sets.count).to eq(2)
    end
  end

  describe '#base_url=' do
    it 'sets the base url on all representations' do
      manifest.base_url = 'http://example.com/'
      manifest.adaptation_sets.each do |adaptation_set|
        adaptation_set.representations.each do |representation|
          expect(representation.at_xpath('.//xmlns:BaseURL').content).to eq('http://example.com/')
        end
      end
    end
  end

  describe '#segment_query=' do
    it 'sets the segment query on all segment templates' do
      manifest.segment_query = 'foo=bar'
      manifest.adaptation_sets.each do |adaptation_set|
        adaptation_set.representations.each do |representation|
          expect(representation.segment_template.initialization).to match(/\?foo=bar$/)
          expect(representation.segment_template.media).to match(/\?foo=bar$/)
        end
      end
    end
  end

  describe '#to_s' do
    it 'returns the MPD as a formatted XML string' do
      expect(manifest.to_s.strip).to eq(File.read(path).strip)
    end
  end
end
