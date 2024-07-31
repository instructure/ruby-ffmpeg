# frozen_string_literal: true

require_relative '../preset'
require_relative '../filters/scale'

module FFMPEG
  module Presets
    # https://support.google.com/youtube/answer/1722171?hl=en#zippy=%2Cvideo-codec-h%2Cbitrate
    # https://en.wikipedia.org/wiki/Advanced_Video_Coding#Levels

    H264_1080P_30 = Preset.new(
      name: 'h264 1080p 30fps',
      filename: '%<basename>s.1080p30%<extname>s',
      video_codec_name: 'libx264',
      preset: 'fast',
      frame_rate: 30,
      video_profile: 'high',
      max_video_bit_rate: '8000k',
      buffer_size: '4000k',
      level: 4.1,
      audio_bit_rate: '384k',
      filters: [
        Filters::Scale.new(
          width: 'if(gt(iw,ih),-2,1080)',
          height: 'if(gt(iw,ih),1080,-2)',
          flags: ['lanczos']
        )
      ]
    )

    H264_1080P_60 = H264_1080P_30.extend(
      name: 'h264 1080p 60fps',
      filename: '%<basename>s.1080p60%<extname>s',
      frame_rate: 60,
      max_video_bit_rate: '12000k',
      buffer_size: '8000k',
      level: 4.2
    )

    H264_720P_30 = Preset.new(
      name: 'h264 720p 30fps',
      filename: '%<basename>s.720p30%<extname>s',
      video_codec_name: 'libx264',
      preset: 'fast',
      frame_rate: 30,
      video_profile: 'high',
      max_video_bit_rate: '5000k',
      buffer_size: '2500k',
      level: 3.1,
      audio_bit_rate: '384k',
      filters: [
        Filters::Scale.new(
          width: 'if(gt(iw,ih),-2,720)',
          height: 'if(gt(iw,ih),720,-2)',
          flags: ['lanczos']
        )
      ]
    )

    H264_720P_60 = H264_720P_30.extend(
      name: 'h264 720p 60fps',
      filename: '%<basename>s.720p60%<extname>s',
      frame_rate: 60,
      max_video_bit_rate: '7500k',
      buffer_size: '3750k',
      level: 3.2
    )

    H264_480P_30 = Preset.new(
      name: 'h264 480p 30fps',
      filename: '%<basename>s.480p30%<extname>s',
      video_codec_name: 'libx264',
      preset: 'fast',
      frame_rate: 30,
      video_profile: 'main',
      max_video_bit_rate: '2500k',
      buffer_size: '1250k',
      level: 3.1,
      audio_bit_rate: '128k',
      filters: [
        Filters::Scale.new(
          width: 'if(gt(iw,ih),-2,480)',
          height: 'if(gt(iw,ih),480,-2)',
          flags: ['lanczos']
        )
      ]
    )

    H264_360P_30 = Preset.new(
      name: 'h264 360p 30fps',
      filename: '%<basename>s.360p30%<extname>s',
      video_codec_name: 'libx264',
      preset: 'ultrafast',
      frame_rate: 30,
      video_profile: 'baseline',
      max_video_bit_rate: '1000k',
      buffer_size: '500k',
      level: 3.0,
      audio_bit_rate: '128k',
      filters: [
        Filters::Scale.new(
          width: 'if(gt(iw,ih),-2,360)',
          height: 'if(gt(iw,ih),360,-2)',
          flags: ['lanczos']
        )
      ]
    )
  end
end
