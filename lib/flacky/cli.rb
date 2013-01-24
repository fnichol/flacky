# -*- encoding: utf-8 -*-

require 'benchmark'
require 'json'
require 'thor'

require 'flacky'
require 'flacky/metadata_generator'

module Flacky

  class CLI < Thor

    include Thor::Actions

    desc "generate <root_path>", "Generate and populate metadata as JSON"
    def generate(root_dir = ENV['PWD'])
      start_dir = File.join(File.expand_path(root_dir), '**/*.flac')
      Dir.glob(start_dir).map { |f| File.dirname(f) }.uniq.each do |dir|
        mdf = File.join(dir, "metadata.json")
        say("Processing <#{dir}>", :cyan)
        data = Flacky::MetadataGenerator.new(mdf).combined_data
        IO.write(mdf, JSON.pretty_generate(data))
      end
    end

    desc "missing_urls <root_path>", "List all metadata files with missing URLs"
    method_option :print0, :aliases => "-0", :type => :boolean
    def missing_urls(root_dir = ENV['PWD'])
      start_dir = File.join(File.expand_path(root_dir), '**/metadata.json')
      files = []

      Dir.glob(start_dir).each do |mdf|
        attr = JSON.parse(IO.read(mdf))["allmusic_url"]
        files << mdf if attr.nil? || attr.empty?
      end

      if options[:print0]
        print files.join("\x0").concat("\x0")
      else
        puts files.join("\n") unless files.empty?
      end
    end

    desc "to_mp3 [file ...]|[**/*.flac ...]", "Convert Flac files to MP3 files"
    method_option :destination, :aliases => "-d",
      :desc => "Sets optional destination directory"
    method_option :'lame-opts', :aliases => "-l",
      :default => "--vbr-new -V 0 -b 320",
      :desc => "Set the lame encoding arguments"
    def to_mp3(*args)
      %w{flac metaflac lame}.each do |cmd|
        abort "Command #{cmd} must be on your PATH" unless %x{which #{cmd}}
      end

      args.each do |glob|
        FlacToMp3.new(
          :glob       => glob,
          :lame_opts  => options[:'lame-opts'],
          :dest_root  => options[:destination]
        ).convert!
      end
    end

    private

    class FlacToMp3

      def initialize(opts = {})
        @glob = opts[:glob]
        @lame_opts = opts[:lame_opts]
        @dest_root = opts[:dest_root]
      end

      def convert!
        Dir.glob(glob).each do |file|
          next unless file =~ /\.flac$/
          convert_file(file)
        end
      end

      private

      attr_reader :glob, :lame_opts, :dest_root

      def convert_file(file)
        dst = file.sub(/\.flac$/, ".mp3")
        if dest_root
          dst = File.join(dest_root, dst)
          FileUtils.mkdir_p File.dirname(dst)
        end

        cmd = %{flac -dcs "#{file}" | lame #{lame_opts}}
        tags.each { |lt, ft| cmd << %{ --#{lt} "#{tag(file, ft)}"} }
        cmd << %{ - "#{dst}"}

        banner "Processing #{file}..."
        elapsed = Benchmark.measure do
          %x{#{cmd}}
        end
        banner "Wrote out #{dst} #{duration(elapsed.real)}"
      end

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

      def duration(total)
        minutes = (total / 60).to_i
        seconds = (total - (minutes * 60))
        "(%dm%.2fs)" % [minutes, seconds]
      end

      def banner(msg)
        puts "-----> #{msg}"
      end
    end
  end
end
