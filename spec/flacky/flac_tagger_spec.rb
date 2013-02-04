# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'mocha/setup'
require 'flacky/flac_tagger'

describe Flacky::FlacTagger do

  let(:flac_file) do
    File.join(File.dirname(__FILE__), '../fixtures/silence.flac')
  end

  let(:tagger) do
    Flacky::FlacTagger.new(flac_file)
  end

  describe "when writing tags" do

    let(:tag) do
      mock('xiph_comment')
    end

    let(:taglib_flac) do
      mock = TagLib::FLAC::File.new(flac_file)
      mock.stubs(:save).returns(true)
      mock.stubs(:xiph_comment).returns(tag)
      mock
    end

    before do
      taglib_flac
      TagLib::FLAC::File.stubs(:new).returns(taglib_flac)
    end

    describe "#tag" do
      it "sets a tag if none exist" do
        tag.expects(:add_field).with("DISCNUMBER", "1", true)

        tagger.tag "DISCNUMBER", "1"
      end

      it "sets a tag if one exists" do
        tag.expects(:add_field).with("TITLE", "Foopants", true)

        tagger.tag "TITLE", "Foopants"
      end
    end

    describe ".update" do

      it "add the tag and updates" do
        tag.expects(:add_field).with("ARTIST", "The MiniTest", true)
        taglib_flac.expects(:save)
        taglib_flac.expects(:close).at_least_once

        Flacky::FlacTagger.update(flac_file) do
          tag "ARTIST", "The MiniTest"
        end
      end
    end
  end

  describe "when reading" do

    after do
      tagger.cleanup
    end

    describe "#find" do

      it "returns nil if attribute isn't found" do
        tagger.find("haha").must_be_nil
      end

      it "returns a string if tag value array only has only one element" do
        tagger.find("GENRE").must_equal "Avantgarde"
      end

      it "matches case insensitive attribute matches" do
        tagger.find("artist").must_equal "Fletcher Nichol"
      end
    end

    describe "#[]" do

      it "returns nil if attribute isn't found" do
        tagger["nope"].must_be_nil
      end

      it "returns a string if tag value array only has only one element" do
        tagger["GENRE"].must_equal "Avantgarde"
      end

      it "returns and array if tag value has multiple elements" do
        tagger["MULTIPLE"].must_equal ["One", "Two"]
      end
    end
  end
end
