# FFMPEG

Simple yet powerful wrapper around the ffmpeg command for reading metadata and transcoding movies.

## Compatibility

### Ruby

Only guaranteed to work with MRI Ruby 1.9.3 or later.
Should work with rubinius head in 1.9 mode.
Will not work in jruby until they fix: http://goo.gl/Z4UcX (should work in the upcoming 1.7.5)

### ffmpeg

The current gem is tested against ffmpeg 2.8.4. So no guarantees with earlier (or much later) 
versions. Output and input standards have inconveniently changed rather a lot between versions 
of ffmpeg. My goal is to keep this library in sync with new versions of ffmpeg as they come along.

On macOS: `brew install ffmpeg`.

## Usage

### Require the gem

```ruby
require 'ffmpeg', git: 'https://github.com/instructure/ruby-ffmpeg'
```

### Reading Metadata

```ruby
media = FFMPEG::Media.new('path/to/movie.mov')

media.duration # 7.5 (duration of the media in seconds)
media.bitrate # 481 (bitrate in kb/s)
media.size # 455546 (filesize in bytes)

media.video_overview # 'h264, yuv420p, 640x480 [PAR 1:1 DAR 4:3], 371 kb/s, 16.75 fps, 15 tbr, 600 tbn, 1200 tbc' (raw video stream info)
media.video_codec_name # 'h264'
media.color_space # 'yuv420p'
media.resolution # '640x480'
media.width # 640 (width of the video stream in pixels)
media.height # 480 (height of the video stream in pixels)
media.frame_rate # 16.72 (frames per second)

media.audio_overview # 'aac, 44100 Hz, stereo, s16, 75 kb/s' (raw audio stream info)
media.audio_codec_name # 'aac'
media.audio_sample_rate # 44100
media.audio_channels # 2

media.video # FFMPEG::Stream
# Multiple audio streams
media.audio[0] # FFMPEG::Stream

media.valid? # true (would be false if ffmpeg fails to read the movie)
```

### Transcoding

First argument is the output file path.

```ruby
media.transcode('path/to/new_movie.mp4') # Default ffmpeg settings for mp4 format
```

Keep track of progress with an optional block.

```ruby
media.transcode('path/to/new_movie.mp4') { |progress| puts progress } # 0.2 ... 0.5 ... 1.0
```

Give custom command line options with an array.

```ruby
media.transcode('path/to/new_movie.mp4', %w(-ac aac -vc libx264 -ac 2 ...))
```

Use the EncodingOptions parser for humanly readable transcoding options. Below you'll find most of the supported options.
Note that the :custom key is an array so that it can be used for FFMpeg options like
`-map` that can be repeated:

```ruby
options = {
  video_codec: 'libx264', frame_rate: 10, resolution: '320x240', video_bitrate: 300, video_bitrate_tolerance: 100,
  aspect: 1.333333, keyframe_interval: 90, x264_vprofile: 'high', x264_preset: 'slow',
  audio_codec: 'libfaac', audio_bitrate: 32, audio_sample_rate: 22050, audio_channels: 1,
  threads: 2, custom: %w(-vf crop=60:60:10:10 -map 0:0 -map 0:1)
}

media.transcode('movie.mp4', options)
```

The transcode function returns a Movie object for the encoded file.

```ruby
new_media = media.transcode('path/to/new_movie.flv')

new_media.video_codec_name # 'flv'
new_media.audio_codec_name # 'mp3'
```

Aspect ratio is added to encoding options automatically if none is specified.

```ruby
options = { resolution: '320x180' } # Will add -aspect 1.77777777777778 to ffmpeg
```

Preserve aspect ratio on width or height by using the preserve_aspect_ratio transcoder option.

```ruby
media = FFMPEG::Media.new('path/to/movie.mov')

options = { resolution: '320x240' }

kwargs = { preserve_aspect_ratio: :width }
media.transcode('movie.mp4', options, **kwargs) # Output resolution will be 320x180

kwargs = { preserve_aspect_ratio: :height }
media.transcode('movie.mp4', options, **kwargs) # Output resolution will be 426x240
```

For constant bitrate encoding use video_min_bitrate and video_max_bitrate with buffer_size.

```ruby
options = {video_min_bitrate: 600, video_max_bitrate: 600, buffer_size: 2000}
media.transcode('path/to/new_movie.flv', options)
```

### Specifying Input Options

To specify which options apply the input, such as changing the input framerate, use `input_options` hash
in the transcoder kwargs.

```ruby
movie = FFMPEG::Media.new('path/to/movie.mov')

kwargs = { input_options: { framerate: '1/5' } }
movie.transcode('path/to/new_movie.mp4', {}, **kwargs)

# FFMPEG Command will look like this:
# ffmpeg -y -framerate 1/5 -i path/to/movie.mov movie.mp4
```

### Watermarking

Add watermark image on the video.

For example, you want to add a watermark on the video at right top corner with 10px padding.

```ruby
options = {
  watermark: 'path/to/watermark.png', resolution: '640x360',
  watermark_filter: { position: 'RT', padding_x: 10, padding_y: 10 }
}
```

Position can be "LT" (Left Top Corner), "RT" (Right Top Corner), "LB" (Left Bottom Corner), "RB" (Right Bottom Corner).
The watermark will not appear unless `watermark_filter` specifies the position. `padding_x` and `padding_y` default to
`10`.

### Taking Screenshots

You can use the screenshot method to make taking screenshots a bit simpler.

```ruby
media.screenshot('path/to/new_screenshot.jpg')
```

The screenshot method has the very same API as transcode so the same options will work.

```ruby
media.screenshot('path/to/new_screenshot.bmp', seek_time: 5, resolution: '320x240')
```

To generate multiple screenshots in a single pass, specify `vframes` and a wildcard filename. Make
sure to disable output file validation. The following code generates up to 20 screenshots every 10 seconds:

```ruby
media.screenshot('path/to/new_screenshot_%d.jpg', { vframes: 20, frame_rate: '1/6' }, validate: false)
```

To specify the quality when generating compressed screenshots (.jpg), use `quality` which specifies
ffmpeg `-v:q` option. Quality is an integer between 1 and 31, where lower is better quality:

```ruby
media.screenshot('path/to/new_screenshot_%d.jpg', quality: 3)
```

You can preserve aspect ratio the same way as when using transcode.

```ruby
media.screenshot('path/to/new_screenshot.png', { seek_time: 2, resolution: '200x120' }, preserve_aspect_ratio: :width)
```

### Create a Slideshow from Stills
Creating a slideshow from stills uses named sequences of files and stiches the result together in a slideshow
video.

Since there is no media to transcode, the Transcoder class needs to be used.

```ruby
slideshow_transcoder = FFMPEG::Transcoder.new(
  'img_%03d.jpeg',
  'slideshow.mp4',
  { resolution: '320x240' },
  input_options: { framerate: '1/5' }
)

slideshow = slideshow_transcoder.run
# slideshow is a Movie object
```

Specify the path to ffmpeg
--------------------------

By default, the gem assumes that the ffmpeg binary is available in the execution path and named ffmpeg and so will run commands that look something like `ffmpeg -i /path/to/input.file ...`. Use the FFMPEG.ffmpeg_binary setter to specify the full path to the binary if necessary:

```ruby
FFMPEG.ffmpeg_binary = '/usr/local/bin/ffmpeg'
```

This will cause the same command to run as `/usr/local/bin/ffmpeg -i /path/to/input.file ...` instead.


Automatically kill hung processes
---------------------------------

By default, the gem will wait for 30 seconds between IO feedback from the FFMPEG process. After which an error is logged and the process killed.
It is possible to modify this behaviour by setting a new default:

```ruby
# Change the timeout
Transcoder.timeout = 10

# Disable the timeout altogether
Transcoder.timeout = false
```

Disabling output file validation
------------------------------

By default Transcoder validates the output file, in case you use FFMPEG for HLS
format that creates multiple outputs you can disable the validation by passing
`validate: false` in the transcoder kwargs.

Note that transcode will not return the encoded media object in this case since
attempting to open a (possibly) invalid output file might result in an error being raised.

```ruby
kwargs = { validate: false }
media.transcode('movie.mp4', options, **kwargs) # returns nil
```

Copyright
---------

Copyright (c) Instructure, Inc. See LICENSE for details.
