# frozen_string_literal: true

require 'securerandom'

require_relative '../command_args'

module FFMPEG
  class CommandArgs
    # The Composable module allows for composing command arguments in a modular way.
    module Composable
      module ClassMethods # rubocop:disable Style/Documentation
        attr_reader :blocks

        # Defines a block of code that can be composed into command arguments.
        # Multiple blocks can be defined with different names,
        # and they can be used to compose command arguments in a modular way.
        #
        # @param name [Object] The name of the block.
        # @param block [Proc] The block of code to be executed in context of the command arguments.
        # @return [self]
        #
        # @example
        #  module MyCommandArgs
        #    include FFMPEG::CommandArgs::Composable
        #
        #    compose :h264 do
        #      video_codec_name 'libx264'
        #    end
        #
        #    compose :aac do
        #      audio_codec_name 'aac'
        #    end
        #  end
        #
        #  args = FFMPEG::RawCommandArgs.compose do
        #    use MyCommandArgs, only: %i[h264]
        #  end
        #  args.to_s # "-c:v libx264"
        def compose(name = SecureRandom.hex(4), &block)
          return unless block_given?

          @blocks ||= {}
          @blocks[name] = block

          self
        end
      end

      class << self
        def included(base)
          base.extend(ClassMethods)
        end
      end
    end
  end
end
