# -*- encoding: utf-8 -*-

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

      cmd = %{flac -dcs "#{file}" | lame #{lame_opts}}
      tags.each { |lt, ft| cmd << %{ --#{lt} "#{tag(file, ft)}"} }
      cmd << %{ - "#{dst}"}

      elapsed = Benchmark.measure do ; %x{#{cmd}} ; end
      Response.new(dst, elapsed.real)
    end

    Response = Struct.new(:mp3_filename, :elapsed)

    private

    attr_reader :lame_opts, :dest_root

    def tags
      { :tt => :title, :tl => :album, :ta => :artist, :tn => :tracknumber,
        :tg => :genre, :tc => :comment, :ty => :date }.freeze
    end

    def tag(file, tag)
      r = %x{metaflac --show-tag=#{tag.to_s.upcase} "#{file}"}
      unless r.nil? || r.empty?
        r.split("=").last.chomp
      else
        ""
      end
    end
  end
end
