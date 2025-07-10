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
    subject { video_adaptation_set.par }

    it 'returns tha par' do
      is_expected.to eq('16:9')
    end
  end

  describe '#content_type' do
    subject { video_adaptation_set.content_type }

    it 'returns the content type' do
      is_expected.to eq('video')
    end
  end

  describe '#max_width' do
    subject { video_adaptation_set.max_width }

    it 'returns the max_width' do
      is_expected.to eq(1920)
    end
  end

  describe '#max_height' do
    subject { video_adaptation_set.max_height }

    it 'returns the max_height' do
      is_expected.to eq(1080)
    end
  end

  describe '#frame_rate' do
    subject { video_adaptation_set.frame_rate }

    it 'returns the frame_rate' do
      is_expected.to eq(30.to_r)
    end
  end

  describe '#lang' do
    subject { adaptation_set.lang }

    context 'when language is specified' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
            <Period>
              <AdaptationSet id="0" contentType="audio" lang="en">
                <Representation id="0" mimeType="audio/mp4" codecs="mp4a.40.2" bandwidth="128000">
                  <SegmentTemplate timescale="48000" initialization="init.m4s" media="chunk.m4s">
                    <SegmentTimeline>
                      <S t="0" d="143500"/>
                    </SegmentTimeline>
                  </SegmentTemplate>
                </Representation>
              </AdaptationSet>
            </Period>
          </MPD>
        XML
      end
      let(:manifest) { FFMPEG::DASH::Manifest.parse(mpd) }
      let(:adaptation_set) { manifest.adaptation_sets.first }

      it 'returns the language' do
        is_expected.to eq('en')
      end
    end

    context 'when language is not specified' do
      let(:adaptation_set) { video_adaptation_set }

      it 'returns nil' do
        is_expected.to be_nil
      end
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

  describe '#to_m3u8mt' do
    subject { adaptation_set.to_m3u8mt(group_id: group_id, default: default, autoselect: autoselect) }

    let(:group_id) { 'audio' }
    let(:default) { true }
    let(:autoselect) { true }

    context 'with an audio adaptation set' do
      let(:adaptation_set) { audio_adaptation_set }

      it 'returns an EXT-X-MEDIA tag' do
        is_expected.to eq(
          '#EXT-X-MEDIA:TYPE=AUDIO,' \
          'GROUP-ID=audio,NAME="und",LANGUAGE="und",DEFAULT=YES,AUTOSELECT=YES,URI="stream2.m3u8"'
        )
      end
    end

    context 'with a video adaptation set' do
      let(:adaptation_set) { video_adaptation_set }
      let(:group_id) { 'video' }
      let(:default) { false }
      let(:autoselect) { false }

      it 'returns an EXT-X-MEDIA tag' do
        is_expected.to eq(
          '#EXT-X-MEDIA:TYPE=VIDEO,' \
          'GROUP-ID=video,NAME="und",LANGUAGE="und",DEFAULT=NO,AUTOSELECT=NO,URI="stream0.m3u8"'
        )
      end
    end

    context 'with language specified' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
            <Period>
              <AdaptationSet id="0" contentType="audio" lang="en">
                <Representation id="0" mimeType="audio/mp4" codecs="mp4a.40.2" bandwidth="128000">
                  <SegmentTemplate timescale="48000" initialization="init.m4s" media="chunk.m4s">
                    <SegmentTimeline>
                      <S t="0" d="143500"/>
                    </SegmentTimeline>
                  </SegmentTemplate>
                </Representation>
              </AdaptationSet>
            </Period>
          </MPD>
        XML
      end
      let(:manifest) { FFMPEG::DASH::Manifest.parse(mpd) }
      let(:adaptation_set) { manifest.adaptation_sets.first }

      it 'uses the specified language' do
        is_expected.to eq(
          '#EXT-X-MEDIA:TYPE=AUDIO,' \
          'GROUP-ID=audio,NAME="en",LANGUAGE="en",DEFAULT=YES,AUTOSELECT=YES,URI="stream0.m3u8"'
        )
      end
    end

    context 'with unsupported content types' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
            <Period>
              <AdaptationSet id="0" contentType="subtitle">
                <Representation id="0" mimeType="text/vtt" bandwidth="1000">
                  <SegmentTemplate initialization="init.m4s" media="chunk.m4s">
                    <SegmentTimeline>
                      <S t="0" d="143500"/>
                    </SegmentTimeline>
                  </SegmentTemplate>
                </Representation>
              </AdaptationSet>
            </Period>
          </MPD>
        XML
      end
      let(:manifest) { FFMPEG::DASH::Manifest.parse(mpd) }
      let(:adaptation_set) { manifest.adaptation_sets.first }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when no representations are present' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
            <Period>
              <AdaptationSet id="0" contentType="audio">
              </AdaptationSet>
            </Period>
          </MPD>
        XML
      end
      let(:manifest) { FFMPEG::DASH::Manifest.parse(mpd) }
      let(:adaptation_set) { manifest.adaptation_sets.first }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end
end
