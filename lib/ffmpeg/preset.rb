# frozen_string_literal: true

require_relative 'command_args'

module FFMPEG
  class Preset
    attr_reader :name, :metadata, :filters, :kwargs

    def initialize(name: nil, metadata: nil, filename: nil, filters: [], args: [], **kwargs)
      @name = name
      @metadata = metadata

      @filename = filename
      @filters = filters
      @args = args
      @kwargs = kwargs
    end

    def extend(name: nil, metadata: nil, filename: nil, filters: [], args: [], **kwargs)
      self.class.new(
        name: name || @name,
        metadata: metadata || @metadata,
        filename: filename || @filename,
        filters: filters + @filters,
        args: args + @args,
        **@kwargs.merge(kwargs)
      )
    end

    def filename(**kwargs)
      return nil if @filename.nil?

      @filename % kwargs
    end

    def args
      args = []

      @kwargs.keys.sort_by(&CommandArgs.method(:order)).each do |key|
        args += if CommandArgs.respond_to?(:"convert_#{key}")
                  CommandArgs.send(:"convert_#{key}", @kwargs[key])
                else
                  CommandArgs.convert(key, @kwargs[key])
                end
      end

      @args.each do |arg|
        args << arg.to_s
      end

      @filters.group_by(&:type).each do |type, filters|
        next if filters.empty?

        args << "-#{type}f"
        args << filters.map(&:to_s).join(',')
      end

      args
    end
  end
end
