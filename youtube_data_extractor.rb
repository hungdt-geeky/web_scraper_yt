# YouTube Data Extractor
# Author: Me + ChatGPT
# Date: 2024-04-04
# Version: 1.0

# Description:
# This script extracts data from a YouTube video URL including the title, author, and related videos. It utilizes Nokogiri and Net::HTTP to scrape the YouTube page and extract relevant information. The extracted data is then formatted into a table using Terminal::Table.

# Note:
# - This script requires the 'json', 'nokogiri', 'net/http', 'byebug', and 'terminal-table' gems. Make sure they are installed.
# - Ensure that the provided YouTube URL is valid and accessible.

# Suggestions for Improvement:
# - Add error handling for cases where the expected data is not available or the URL is invalid.
# - Implement input validation to ensure the provided YouTube URL follows the expected format.
# - Consider optimizing the code for better performance, especially when dealing with large HTML responses.

# Changes:
# [Include any recent changes or updates made to the script]

# To-do:
# [List any pending tasks or improvements that need to be addressed in future updates]

require 'json'
require 'nokogiri'
require 'net/http'
require 'byebug'
require 'terminal-table'

def extract_yt_initial_player_response(youtube_url)
  uri = URI.parse(youtube_url)

  response = Net::HTTP.get_response(uri)

  if response.is_a?(Net::HTTPSuccess)
    doc = Nokogiri::HTML(response.body)

    script_tags = doc.css('script')
    script_tags.each do |tag|
      if tag.text.include?('ytInitialData')
        return tag if tag.text.match(/ytInitialData\s*=\s*({.*?})/)[1]
      end
    end
  else
    puts "Failed to retrieve data from the URL. HTTP status code: #{response.code}"
  end
end

def tag_to_json(tag)
  json_content = tag.to_s.match(/\{.*\}/)[0]

  JSON.parse(json_content)
end

def align_string(string, width)
  string + " " * [0, width - string.length].max
end

begin
  print "Enter a YouTube video URL: "
  url = gets.chomp
  tag = extract_yt_initial_player_response(url)
  result = tag_to_json(tag)

  print "Author: "
  puts result["playerOverlays"]["playerOverlayRenderer"]["videoDetails"]["playerOverlayVideoDetailsRenderer"]["subtitle"]["runs"][0]["text"].encode("iso-8859-1").force_encoding("utf-8")
  print "Title: "
  puts result["playerOverlays"]["playerOverlayRenderer"]["videoDetails"]["playerOverlayVideoDetailsRenderer"]["title"]["simpleText"].encode("iso-8859-1").force_encoding("utf-8")

  video_data = []
  result["contents"]["twoColumnWatchNextResults"]["secondaryResults"]["secondaryResults"]["results"].each_with_index do |item, index|
    compactVideoRenderer = item["compactVideoRenderer"]
    next unless compactVideoRenderer

    title = compactVideoRenderer["title"]["simpleText"].encode("iso-8859-1").force_encoding("utf-8") rescue "No title"
    author = compactVideoRenderer["longBylineText"]["runs"][0]["text"].encode("iso-8859-1").force_encoding("utf-8") rescue "No author"
    duration = compactVideoRenderer["thumbnailOverlays"][0]["thumbnailOverlayTimeStatusRenderer"]["text"]["simpleText"] rescue "No duration"

    video_data << [index + 1, title, author, duration]
  end

  table = Terminal::Table.new :headings => ['No', 'Title', 'Author', 'Duration'], :rows => video_data
  puts "Related Videos: "
  puts table
rescue
  puts "Invalid YouTube URL"
end
