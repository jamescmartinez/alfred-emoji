require 'fileutils'
require 'json'
require 'net/http'
require 'securerandom'
require 'zip'

class Emoji
  attr_accessor :emoji, :name, :shortcode

  def initialize(emoji, name)
    @emoji = emoji
    @name = name.tr('_', ' ')
    @shortcode = ":#{@name}:"
  end

  def to_alfredsnippet
    AlfredSnippet.new(emoji, SecureRandom.uuid, name, shortcode)
  end

  def self.all
    url = 'https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json'
    uri = URI(url)
    response = Net::HTTP.get(uri)
    json = JSON.parse(response)

    json.select { |g| g.key?('emoji') }.flat_map do |e|
      e['aliases'].map do |a|
        Emoji.new(e['emoji'], a)
      end
    end
  end
end

class AlfredSnippet
  attr_accessor :snippet, :uid, :name, :keyword

  def initialize(snippet, uid, name, keyword)
    @snippet = snippet
    @uid = uid
    @name = name
    @keyword = keyword
  end

  def to_json
    {
      alfredsnippet: {
        snippet: @snippet,
        uid: @uid,
        name: @name,
        keyword: @keyword
      }
    }.to_json
  end
end

class AlfredSnippets
  def initialize(alfredsnippets)
    @alfredsnippets = alfredsnippets
  end

  def write
    FileUtils.mkdir_p('tmp')
    write_to_tmp
    create_alfredsnippets_file
    FileUtils.rm_rf('tmp')
  end

  private

  def write_to_tmp
    @alfredsnippets.each do |alfredsnippet|
      filename = "#{alfredsnippet.name} #{alfredsnippet.uid}.json"
      File.write("tmp/#{filename}", alfredsnippet.to_json)
    end
  end

  def create_alfredsnippets_file
    Zip::File.open('Emoji.alfredsnippets', Zip::File::CREATE) do |zipfile|
      Dir[File.join('tmp', '*')].each do |file|
        zipfile.add(file.sub('tmp/', ''), file)
      end
    end
  end
end

AlfredSnippets.new(Emoji.all.map(&:to_alfredsnippet)).write
