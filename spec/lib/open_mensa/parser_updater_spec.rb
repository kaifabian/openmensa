require 'spec_helper'
include Nokogiri

describe OpenMensa::ParserUpdater do
  let(:parser) { FactoryGirl.create :parser, index_url: 'http://example.com/index.json' }
  let(:updater) { described_class.new(parser) }
  def stub_data(body)
    stub_request(:any, parser.index_url)
      .to_return(body: body, status: 200)
  end
  def stub_json(json)
    stub_request(:any, parser.index_url)
      .to_return(body: JSON.generate(json), status: 200)
  end

  context '#fetch' do
    it 'should skip invalid urls' do
      parser.update_attribute :index_url, ':///:asdf'
      expect(updater.fetch!).to be_falsey
      m = parser.messages.first
      expect(m).to be_an_instance_of(FeedInvalidUrlError)
      expect(updater.errors).to eq([m])
    end

    it 'should receive feed data via http' do
      stub_data '{}'
      expect(updater.fetch!.read).to eq('{}')
    end

    it 'should update index url on 301 responses' do
      stub_request(:any, 'example.com/301.json')
        .to_return(status: 301, headers: {location: 'http://example.com/index.json'})
      stub_data '{}'
      parser.update_attribute :index_url, 'http://example.com/301.json'
      expect(updater.fetch!.read).to eq('{}')
      expect(parser.reload.index_url).to eq('http://example.com/index.json')
      m = parser.messages.first
      expect(m).to be_an_instance_of(FeedUrlUpdatedInfo)
      expect(m.old_url).to eq('http://example.com/301.json')
      expect(m.new_url).to eq('http://example.com/index.json')
    end

    it 'should not update index url on 302 responses' do
      stub_request(:any, 'example.com/302.json')
        .to_return(status: 302, headers: {location: 'http://example.com/index.json'})
      stub_data '{}'
      parser.update_attribute :index_url, 'http://example.com/302.json'
      expect(updater.fetch!.read).to eq('{}')
      expect(parser.reload.index_url).to eq('http://example.com/302.json')
    end

    it 'should handle http errors correctly' do
      stub_request(:any, 'example.com/500.json')
        .to_return(status: 500)
      parser.update_attribute :index_url, 'http://example.com/500.json'
      expect(updater.fetch!).to be_falsey
      m = parser.messages.first
      expect(m).to be_an_instance_of(FeedFetchError)
      expect(m.code).to eq(500)
      expect(updater.errors).to eq([m])
    end

    it 'should handle network errors correctly' do
      stub_request(:any, 'unknowndomain.org')
        .to_raise(SocketError.new('getaddrinfo: Name or service not known'))
      parser.update_attribute :index_url, 'http://unknowndomain.org'
      expect(updater.fetch!).to be_falsey
      m = parser.messages.first
      expect(m).to be_an_instance_of(FeedFetchError)
      expect(m.code).to eq(nil)
      expect(updater.errors).to eq([m])
    end

    it 'should handle network timeout ' do
      stub_request(:any, 'example.org/timeout.xml')
        .to_timeout
      parser.update_attribute :index_url, 'http://example.org/timeout.xml'
      expect(updater.fetch!).to be_falsey
      m = parser.messages.first
      expect(m).to be_an_instance_of(FeedFetchError)
      expect(m.code).to eq(nil)
      expect(updater.errors).to eq([m])
    end
  end

  context '#parse' do
    it 'should parse valid json' do
      stub_data('{"test": "http://example.org/test.xml",
                  "test2": null}')
      expect(updater.fetch!).to be_truthy
      expect(updater.parse!).to eq({
        'test' => 'http://example.org/test.xml',
        'test2' => nil
      })
    end

    it 'should parse valid json' do
      stub_data('{"test": "http://example.org/test.xml",
                  "test2": null}')
      expect(updater.fetch!).to be_truthy
      expect(updater.parse!).to eq({
        'test' => 'http://example.org/test.xml',
        'test2' => nil
      })
    end

    it 'should fail on invalid json' do
      stub_data('{"test": "http://example.org/test.xml",
                  "test2": nil}{')
      expect(updater.fetch!).to be_truthy
      expect(updater.parse!).to be_falsey

      parser.messages.first.tap do |message|
        expect(message).to be_a(FeedValidationError)
        expect(message.kind).to eq(:no_json)
        expect(updater.errors).to eq([message])
      end
    end
  end

  context '#validate' do
    it 'valid but expected json (invalid value for name)' do
      stub_data('{"test": 4}')
      expect(updater.fetch!).to be_truthy
      expect(updater.parse!).to be_truthy
      expect(updater.validate!).to be_falsey

      parser.messages.first.tap do |message|
        expect(message).to be_a(FeedValidationError)
        expect(message.kind).to eq(:invalid_json)
        expect(message.version).to eq(nil)
        expect(message.message).to eq('URL must be a string or null')
        expect(updater.errors).to eq([message])
      end
    end

    it 'valid but expected json (invalid value for name 2)' do
      stub_data('{"test": {"test": "http://test.xml"}}')
      expect(updater.fetch!).to be_truthy
      expect(updater.parse!).to be_truthy
      expect(updater.validate!).to be_falsey

      parser.messages.first.tap do |message|
        expect(message).to be_a(FeedValidationError)
        expect(message.kind).to eq(:invalid_json)
        expect(message.version).to eq(nil)
        expect(message.message).to eq('URL must be a string or null')
        expect(updater.errors).to eq([message])
      end
    end
  end

  context '#sync' do
    it 'create message for new source' do
      stub_json test: 'http://example.org/test.xml'

      expect(updater.sync).to be_truthy
      expect(updater.stats).to eq new: 1, updated: 0, archived: 0

      parser.messages.first.tap do |message|
        expect(message).to be_a(SourceListChanged)
        expect(message.kind).to eq(:new_source)
        expect(message.name).to eq 'test'
        expect(message.url).to eq 'http://example.org/test.xml'
      end
    end

    it 'create message for new source without url' do
      stub_json test: nil

      expect(updater.sync).to be_truthy
      expect(updater.stats).to eq new: 1, updated: 0, archived: 0

      parser.messages.first.tap do |message|
        expect(message).to be_a(SourceListChanged)
        expect(message.kind).to eq(:new_source)
        expect(message.name).to eq 'test'
        expect(message.url).to be_nil
      end
    end

    it 'should update source urls' do
      stub_json test: 'http://example.com/test/meta.xml'
      source = FactoryGirl.create :source, parser: parser,
                                           name: 'test',
                                           meta_url: 'http://example.com/test.xml'

      expect(updater.sync).to be_truthy
      expect(updater.stats).to eq new: 0, updated: 1, archived: 0
      expect(source.reload.meta_url).to eq 'http://example.com/test/meta.xml'

      source.messages.first.tap do |message|
        expect(message).to be_a(FeedUrlUpdatedInfo)
        expect(message.old_url).to eq 'http://example.com/test.xml'
        expect(message.new_url).to eq 'http://example.com/test/meta.xml'
      end
    end

    it 'should add source urls if not existing' do
      stub_json test: 'http://example.com/test/meta.xml'
      source = FactoryGirl.create :source, parser: parser,
                                           name: 'test',
                                           meta_url: nil

      expect(updater.sync).to be_truthy
      expect(updater.stats).to eq new: 0, updated: 1, archived: 0
      expect(source.reload.meta_url).to eq 'http://example.com/test/meta.xml'

      source.messages.first.tap do |message|
        expect(message).to be_a(FeedUrlUpdatedInfo)
        expect(message.old_url).to be_nil
        expect(message.new_url).to eq 'http://example.com/test/meta.xml'
      end
    end

    it 'should add source urls if not existing' do
      stub_json({})
      source = FactoryGirl.create :source, parser: parser,
                                           name: 'test',
                                           meta_url: 'http://example.org/test/test2.xml'

      expect(updater.sync).to be_truthy
      expect(updater.stats).to eq new: 0, updated: 0, archived: 1
      expect(source.canteen.reload.state).to eq 'archived'

      source.messages.first.tap do |message|
        expect(message).to be_a(SourceListChanged)
        expect(message.kind).to eq(:source_archived)
        expect(message.name).to eq 'test'
        expect(message.url).to be_nil
      end
    end

    it 'should reactive a archived source' do
      stub_json test: 'http://example.org/test/test2.xml'
      canteen = FactoryGirl.create :canteen, state: 'archived'
      source = FactoryGirl.create :source, parser: parser,
                                           canteen: canteen,
                                           name: 'test',
                                           meta_url: 'http://example.org/test/test2.xml'

      expect(updater.sync).to be_truthy
      expect(updater.stats).to eq new: 1, updated: 0, archived: 0
      expect(source.canteen.reload.state).to eq 'wanted'

      source.messages.first.tap do |message|
        expect(message).to be_a(SourceListChanged)
        expect(message.kind).to eq(:source_reactivated)
        expect(message.name).to eq 'test'
        expect(message.url).to eq 'http://example.org/test/test2.xml'
      end
    end
  end
end