# frozen_string_literal: true

require_relative 'command_args'

module FFMPEG
  # The Filter class represents an ffmpeg filter
  # that can be applied to a stream.
  class Filter
    # The Type module contains the valid types for a filter.
    module Type
      AUDIO = :a
      VIDEO = :v

      def self.valid?(type)
        [AUDIO, VIDEO].include?(type)
      end
    end

    attr_reader :type, :name, :kwargs

    def initialize(type, name, **kwargs)
      raise ArgumentError, "Unknown type #{type}, expected #{Type}" unless Type.valid?(type)
      raise ArgumentError, "Unknown name format #{name.class}, expected #{String}" unless name.is_a?(String)

      @type = type
      @name = name
      @kwargs = kwargs
    end

    def to_s
      options = CommandArgs.format_options(@kwargs)
      options.empty? ? @name : "#{@name}=#{options}"
    end
  end
end
