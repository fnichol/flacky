# -*- encoding: utf-8 -*-

require 'taglib'

require 'flacky/tagger'

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
      %x{flac -dcs "#{flac_file}" | lame #{lame_opts} - "#{mp3_file}"}
    end

    def tag_file(flac_file, mp3_file)
      flac_tags = Flacky::Tagger.new(flac_file)

      TagLib::MPEG::File.open(mp3_file) do |file|
        mp3_tags  = file.id3v2_tag

        mp3_tags.album    = flac_tags.find(:album)
        mp3_tags.artist   = flac_tags.find(:artist)
        mp3_tags.title    = flac_tags.find(:title)
        mp3_tags.year     = flac_tags.find(:date).to_i
        mp3_tags.genre    = flac_tags.find(:genre)

        mp3_tags.add_frame(track_frame(flac_tags))
        mp3_tags.add_frame(disc_frame(flac_tags))
        mp3_tags.add_frame(comment_frame(flac_tags))

        file.save
      end
    end

    def encoding
      TagLib::String::Latin1
    end

    def comment_frame(flac_tags)
      frame = TagLib::ID3v2::CommentsFrame.new
      frame.text_encoding = encoding
      frame.language = "eng"
      frame.text = mp3_comment(flac_tags)
      frame
    end

    def track_frame(flac_tags)
      track_number = flac_tags.find(:tracknumber) || "0"
      track_total = flac_tags.find(:totaltracks) || "1"

      frame = TagLib::ID3v2::TextIdentificationFrame.new("TRCK", encoding)
      frame.text = "#{track_number}/#{track_total}"
      frame
    end

    def disc_frame(flac_tags)
      disc_number = flac_tags.find(:discnumber) || "0"
      disc_total = flac_tags.find(:totaldiscs) || "1"

      frame = TagLib::ID3v2::TextIdentificationFrame.new("TPOS", encoding)
      frame.text = "#{disc_number}/#{disc_total}"
      frame
    end

    def mp3_comment(flac_tags)
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
