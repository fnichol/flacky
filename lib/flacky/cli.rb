# -*- encoding: utf-8 -*-

require 'json'
require 'thor'

require 'flacky'
require 'flacky/metadata_generator'

module Flacky

  class CLI < Thor

    include Thor::Actions

    desc "generate <root_path>", "Generate"
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
  end
end
