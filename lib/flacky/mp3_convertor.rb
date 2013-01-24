# -*- encoding: utf-8 -*-

require 'flacky/tagger'

module Flacky

  class Mp3Convertor

    def initialize(opts = {})
      @lame_opts = opts[:lame_opts]
      @dest_root = opts[:dest_root]
    end

    def convert_file!(file)
      dst = file.sub(/\.flac$/, ".mp3")
      if dest_root
        dst = File.join(dest_root, dst)
        FileUtils.mkdir_p File.dirname(dst)
      end

      tagger = Flacky::Tagger.new(file)
      require 'pry' ; binding.pry

      cmd = %{flac -dcs "#{file}" | lame #{lame_opts}}
      tags.each do |lame_tag, flac_tag|
        cmd << %{ --#{lame_tag} "#{tagger.find(flac_tag)}"}
      end
      cmd << %{ --tc '#{lame_comment(tagger)}'}
      cmd << %{ - "#{dst}"}

      elapsed = Benchmark.measure do ; %x{#{cmd}} ; end
      Response.new(dst, elapsed.real)
    end

    Response = Struct.new(:mp3_filename, :elapsed)

    private

    attr_reader :lame_opts, :dest_root

    def tags
      { :tt => :title, :tl => :album, :ta => :artist, :tn => :tracknumber,
        :tg => :genre, :ty => :date }.freeze
    end

    def lame_comment(tagger)
      comment = []
      (tagger.find(:mood) || "").split(';').each do |mood|
        comment << "mood=#{mood}"
      end
      (tagger.find(:style) || "").split(';').each do |style|
        comment << "style=#{style}"
      end
      if owner = tagger.find(:fileowner)
        comment << "fileowner=#{owner}"
      end
      comment.join("\n")
    end
  end
end
