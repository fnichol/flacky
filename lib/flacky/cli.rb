# -*- encoding: utf-8 -*-

require 'benchmark'
require 'json'
require 'thor'

require 'flacky'
require 'flacky/flac_metadata_importer'
require 'flacky/flac_track_zero_pad_stripper'
require 'flacky/metadata_generator'
require 'flacky/mp3_convertor'

module Flacky

  class CLI < Thor

    include Thor::Actions

    desc "generate_json <root_path>", "Generate and populate metadata as JSON"
    def generate_json(root_dir = ENV['PWD'])
      start_dir = File.join(File.expand_path(root_dir), '**/*.flac')
      Dir.glob(start_dir).sort.map { |f| File.dirname(f) }.uniq.each do |dir|
        mdf = File.join(dir, "metadata.json")
        say("Processing <#{dir}>", :cyan)
        data = Flacky::MetadataGenerator.new(mdf).combined_data
        IO.write(mdf, JSON.pretty_generate(data))
      end
    end

    desc "import_json [file ...]|[**/*.flac ...]", "Import metadata JSON into Flac files"
    def import_json(*args)
      args.each { |glob| import_metadata_for_files(glob) }
    end

    desc "missing_urls <root_path>", "List all metadata files with missing URLs"
    method_option :print0, :aliases => "-0", :type => :boolean
    def missing_urls(root_dir = ENV['PWD'])
      start_dir = File.join(File.expand_path(root_dir), '**/metadata.json')
      files = []

      Dir.glob(start_dir).sort.each do |mdf|
        attr = JSON.parse(IO.read(mdf))["allmusic_url"]
        files << mdf if attr.nil? || attr.empty?
      end

      if options[:print0]
        print files.join("\x0").concat("\x0")
      else
        puts files.join("\n") unless files.empty?
      end
    end

    desc "strip_pad [file ...]|[**/*.flac ...]", "Strip zero-padded track numbers in Flac files"
    def strip_pad(*args)
      args.each do |glob|
        Dir.glob(glob).sort.each do |file|
          say("Processing <#{file}>", :cyan)
          Flacky::FlacTrackZeroPadStripper.new(file).strip!
        end
      end
    end

    desc "to_mp3 [file ...]|[**/*.flac ...] [options]", "Convert Flac files to MP3 files"
    method_option :destination, :aliases => "-d",
      :desc => "Sets optional destination directory"
    method_option :'lame-opts', :aliases => "-l",
      :default => "--vbr-new --verbose -V 0 -b 320",
      :desc => "Set the lame encoding arguments"
    def to_mp3(*args)
      %w{flac lame}.each do |cmd|
        abort "Command #{cmd} must be on your PATH" unless %x{which #{cmd}}
      end

      mp3izer = Flacky::Mp3Convertor.new(
        :lame_opts  => options[:'lame-opts'],
        :dest_root  => options[:destination]
      )

      args.each { |glob| convert_files(glob, mp3izer) }
    end

    desc "version", "Print Flacky's version information"
    def version
      say "Flacky version #{Flacky::VERSION}"
    end
    map %w(-v --version) => :version

    private

    def convert_files(glob, mp3izer)
      Dir.glob(glob).sort.each do |file|
        next unless file =~ /\.flac$/

        say("Processing #{file}...", :cyan)
        response = mp3izer.convert_file!(file)
        say("Created #{response.mp3_filename} #{duration(response.elapsed)}",
          :yellow)
      end
    end

    def import_metadata_for_files(glob)
      Dir.glob(glob).sort.each do |file|
        next unless file =~ /\.flac$/

        say("Processing #{file}...", :cyan)
        response = Flacky::FlacMetadataImporter.new(file).import!
        say("Imported #{response.metadata_filename} into #{file} " +
          "#{duration(response.elapsed)}", :yellow)
      end
    end

    def duration(total)
      minutes = (total / 60).to_i
      seconds = (total - (minutes * 60))
      "(%dm%.2fs)" % [minutes, seconds]
    end
  end
end
