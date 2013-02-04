# -*- encoding: utf-8 -*-

require 'flacky/flac_tagger'
require 'flacky/mp3_tagger'

module Flacky

  class Mp3Convertor

    def initialize(opts = {})
      @lame_opts = opts[:lame_opts]
      @dest_root = opts[:dest_root]
    end

    def convert_file!(flac_file)
      mp3_file = calculate_mp3_filename(flac_file)

      elapsed = Benchmark.measure do
        FileUtils.mkdir_p File.dirname(mp3_file)
        transcode_file(flac_file, mp3_file)
        tag_file(flac_file, mp3_file)
      end

      Response.new(mp3_file, elapsed.real)
    end

    Response = Struct.new(:mp3_filename, :elapsed)

    private

    attr_reader :lame_opts, :dest_root

    def calculate_mp3_filename(flac_file)
      mp3_file = flac_file.sub(/\.flac$/, ".mp3")
      mp3_file = File.join(dest_root, mp3_file) if dest_root
      File.expand_path(mp3_file)
    end

    def transcode_file(flac_file, mp3_file)
      %x{flac -dcs '#{flac_file}' | lame #{lame_opts} - '#{mp3_file}'}
    end

    def tag_file(flac_file, mp3_file)
      flac_tags = Flacky::FlacTagger.new(flac_file)
      track     = track_tag(flac_tags)
      disc      = disc_tag(flac_tags)
      comment   = comment_tag(flac_tags)

      Flacky::Mp3Tagger.update(mp3_file) do
        tag "album",    flac_tags.find(:album)
        tag "artist",   flac_tags.find(:artist)
        tag "title",    flac_tags.find(:title)
        tag "year",     flac_tags.find(:date).to_i
        tag "genre",    flac_tags.find(:genre)
        tag "track",    track
        tag "disc",     disc
        tag "comment",  comment
      end

      flac_tags.cleanup
    end

    def track_tag(flac_tags)
      track_number = flac_tags.find(:tracknumber) || "0"
      track_total = flac_tags.find(:totaltracks) || "1"

      "#{track_number}/#{track_total}"
    end

    def disc_tag(flac_tags)
      disc_number = flac_tags.find(:discnumber) || "0"
      disc_total = flac_tags.find(:totaldiscs) || "1"

      "#{disc_number}/#{disc_total}"
    end

    def comment_tag(flac_tags)
      comment = []
      if owner = flac_tags.find(:fileowner)
        comment << "o=#{owner}"
      end
      (flac_tags.find(:style) || "").split(';').each do |style|
        comment << "s=#{style}"
      end
      (flac_tags.find(:mood) || "").split(';').each do |mood|
        comment << "m=#{mood}"
      end
      comment.join("\n")
    end
  end
end
