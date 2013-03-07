require 'spec_helper'
require 'nokogiri'

describe OpenMensa::FeedValidator do
  let(:valid_xml_v1) { Nokogiri::XML::Document.parse mock_content('canteen_feed.xml') }
  let(:valid_xml)    { Nokogiri::XML::Document.parse mock_content('feed_v2.xml') }
  let(:invalid_xml)  { Nokogiri::XML::Document.parse mock_content('feed_wellformated.xml') }
  let(:non_om_xml)   { Nokogiri::XML::Document.parse mock_content('carrier_ship.xml') }

  let(:doc_v1) { Nokogiri::XML::Document.parse mock_content('canteen_feed.xml') }
  let(:doc_v2)    { Nokogiri::XML::Document.parse mock_content('feed_v2.xml') }

  describe '#valid?' do
    it 'should return true on valid feeds' do
      OpenMensa::FeedValidator.new(valid_xml).should be_valid
    end

    it 'should return false on invalid XML' do
      OpenMensa::FeedValidator.new(invalid_xml).should_not be_valid
    end

    it 'should return false on non OpenMensa XML' do
      OpenMensa::FeedValidator.new(non_om_xml).should_not be_valid
    end
  end

  describe '#validate!' do
    it 'should return version on valid feeds (1)' do
      OpenMensa::FeedValidator.new(valid_xml_v1).validate!.should == 1
    end

    it 'should return version on valid feeds (2)' do
      OpenMensa::FeedValidator.new(valid_xml).validate!.should == 2
    end

    it 'should raise an error on invalid XML' do
      expect {
        OpenMensa::FeedValidator.new(invalid_xml).validate!
      }.to raise_error(OpenMensa::FeedValidator::FeedValidationError)
    end

    it 'should raise an error on non OpenMensa XML' do
      expect {
        OpenMensa::FeedValidator.new(non_om_xml).validate!
      }.to raise_error(OpenMensa::FeedValidator::InvalidFeedVersionError)
    end
  end

  describe '#validate' do
    it 'should return version on valid feeds (1)' do
      OpenMensa::FeedValidator.new(valid_xml_v1).validate.should == 1
    end

    it 'should return version on valid feeds (2)' do
      OpenMensa::FeedValidator.new(valid_xml).validate.should == 2
    end

    it 'should return false on invalid XML' do
      OpenMensa::FeedValidator.new(invalid_xml).validate.should == false
    end

    it 'should return false on non OpenMensa XML' do
      OpenMensa::FeedValidator.new(non_om_xml).validate.should == false
    end
  end

  describe '#validated?' do
    it 'should return false before validating a feed' do
      OpenMensa::FeedValidator.new(valid_xml).should_not be_validated
    end

    it 'should return true after validating valid feeds' do
      OpenMensa::FeedValidator.new(valid_xml).tap do |vd|
        vd.validate!
        vd.should be_validated
      end
    end
  end

  describe '#version' do
    it 'should return version after validating a feed (v1)' do
      OpenMensa::FeedValidator.new(doc_v1).tap do |vd|
        vd.validate!
        vd.version.should == 1
      end
    end

    it 'should return version after validating a feed (v2)' do
      OpenMensa::FeedValidator.new(doc_v2).tap do |vd|
        vd.validate!
        vd.version.should == 2
      end
    end
  end
end
