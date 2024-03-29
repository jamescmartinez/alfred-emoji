require "fileutils"
require "json"
require "net/http"
require "securerandom"
require "zip"

def fetch_gemoji
  url = "https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json"
  uri = URI(url)
  response = Net::HTTP.get(uri)
  JSON.parse(response)
end

def map_gemoji_to_alfredsnippets(gemoji)
  gemoji.flat_map do |g|
    g["aliases"].map do |a|
      keyword = a.tr("_", " ") # e.g. "smiley"
      keyword_with_colons = ":#{keyword}:" # e.g. ":smiley:"
      emoji = g["emoji"] # e.g. "😃"
      tags = g["tags"].join(", ") # e.g. "happy, joy, haha"
      name = "#{emoji} - #{keyword}" # e.g. "😃 - smiley"
      name += ", #{tags}" if g["tags"].count.positive? # e.g. "😃 - smiley, happy, joy, haha"

      {
        alfredsnippet: {
          uid: name,
          snippet: emoji,
          name: name,
          keyword: keyword_with_colons
        }
      }
    end
  end
end

def write_alfredsnippets_file(alfredsnippets)
  FileUtils.mkdir_p("tmp")

  alfredsnippets.each do |alfredsnippet|
    filename = "#{alfredsnippet.dig(:alfredsnippet, :name)}.json"
    File.write("tmp/#{filename}", alfredsnippet.to_json)
  end

  FileUtils.rm_rf("Emoji.alfredsnippets")

  Zip::File.open("Emoji.alfredsnippets", Zip::File::CREATE) do |zipfile|
    Dir[File.join("tmp", "*")].each do |file|
      zipfile.add(file.sub("tmp/", ""), file)
    end
  end

  FileUtils.rm_rf("tmp")
end

#####

gemoji = fetch_gemoji
alfredsnippets = map_gemoji_to_alfredsnippets(gemoji)
write_alfredsnippets_file(alfredsnippets)
puts "Done! #{alfredsnippets.count} Alfred emoji snippets created."
