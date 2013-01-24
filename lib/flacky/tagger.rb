# -*- encoding: utf-8 -*-

require 'flacinfo'

module Flacky
  class Tagger
    def self.update(flac_file, &block)
      instance = self.new(flac_file)
      instance.instance_eval(&block)
      instance.update!
    end

    def initialize(flac_file)
      @flac_file = flac_file
      @flac = FlacInfo.new(@flac_file)
    end

    def [](attr)
      @flac.tags[attr]
    end

    def find(attr)
      key = @flac.tags.keys.find { |key| key =~ /#{attr}/i }
      key ? @flac.tags[key] : nil
    end

    def tag(name, value)
      @flac.comment_del(name) if @flac.tags.keys.include?(name)
      @flac.comment_add("#{name}=#{value}")
    end

    def update!()
      @flac.update!
    end
  end
end
