#/usr/ruby
require "rubygems"
require "mrss.rb"
require "simple-rss"
require 'syndication/rss' 
require 'syndication/atom'
require "rfeedparser"

def test_mrss(feed)
  begin
    # MRSS
    mr_start = Time.now 
    MRSS.parse(feed)
    mr_stop = Time.now
    mr_stop - mr_start
  rescue
    -1
  end
end

def test_simplerss(feed)
  begin
    # SimpleRSS
    si_start = Time.now  
    SimpleRSS.parse feed
    si_stop = Time.now
    si_stop - si_start
  rescue
    -1
  end
end

def test_syndication(feed, type)
  begin
    # Syndication
    if type[0..3] == "atom"
      atom_parser = Syndication::Atom::Parser.new
      sy_start = Time.now  
      atom_parser.parse feed  
      sy_stop = Time.now    
    elsif type[0..2] == "rss"
      rss_parser = Syndication::RSS::Parser.new
      sy_start = Time.now  
      rss_parser.parse feed  
      sy_stop = Time.now  
    else
      # Weird!
    end
    sy_stop - sy_start
  rescue
    -1
  end
end

def test_feedparser(feed)
  begin
    # FeedParser
    fp_start = Time.now  
    FeedParser.parse(feed)  
    fp_stop = Time.now
    fp_stop - fp_start
  rescue
    -1
  end
end

def init_results(stats, type)
  stats[type] = Hash.new
  stats[type][:any] = Hash.new
  stats[type][:rss] = Hash.new
  stats[type][:atom] = Hash.new
  stats[type][:any][:total_time] = 0
  stats[type][:any][:number_of_feeds] = 0
  stats[type][:any][:errors] = 0
  stats[type][:rss][:total_time] = 0
  stats[type][:rss][:number_of_feeds] = 0
  stats[type][:rss][:errors] = 0
  stats[type][:atom][:total_time] = 0
  stats[type][:atom][:number_of_feeds] = 0
  stats[type][:atom][:errors] = 0
end

def stats_for_type(stats, result, type)
  stats[type][:any][:total_time] += result[1][type] unless result[1][type] == -1
  stats[type][:any][:number_of_feeds] +=1  unless result[1][type] == -1
  stats[type][:any][:errors] +=1 if result[1][type] == -1
  stats[type][:rss][:total_time] += result[1][type] if (result[1][type] != -1 && result[1][:type][0..2] == "rss")
  stats[type][:rss][:number_of_feeds] +=1  if (result[1][type] != -1 && result[1][:type][0..2] == "rss")
  stats[type][:rss][:errors] +=1 if (result[1][type] == -1 && result[1][:type][0..2] == "rss")
  stats[type][:atom][:total_time] += result[1][type] if (result[1][type] != -1 && result[1][:type][0..3] == "atom")
  stats[type][:atom][:number_of_feeds] +=1  if (result[1][type] != -1 && result[1][:type][0..3] == "atom")
  stats[type][:atom][:errors] +=1 if (result[1][type] == -1 && result[1][:type][0..3] == "atom")
end

file_names = Dir['feeds/*']
results = Hash.new
index = 0
max = ARGV[0].to_i || 10000 # Maximum 10k feeds
puts "\"filename\", \"type\", \"rfeedparser\", \"syndication\",\"simplerss\", \"mrss\""
file_names.each do |file_name|
  index = index + 1
  file = File.open(file_name, "r")
  feed = file.read
  type = file_name.split(".")[1]
  begin
    results[file_name] = Hash.new
    results[file_name][:type] = type 
    results[file_name][:rfeedparser] = test_feedparser(feed) 
    results[file_name][:syndication] = test_syndication(feed, type)
    results[file_name][:simplerss] = test_simplerss(feed) 
    results[file_name][:mrss] = test_mrss(feed)
    puts "\"#{file_name}\", \"#{results[file_name][:type]}\", #{results[file_name][:rfeedparser]}, #{results[file_name][:syndication]}, #{results[file_name][:simplerss]}, #{results[file_name][:mrss]}"
  rescue
    puts "Error for feed: #{file_name} => #{$!}"
  end
  break if index > max
end

# Average by feed (all feed types, and number of errors)
stats = Hash.new
init_results(stats, :rfeedparser)
init_results(stats, :syndication)
init_results(stats, :simplerss)
init_results(stats, :mrss)

results.each do |result|
  stats_for_type(stats, result, :rfeedparser)
  stats_for_type(stats, result, :syndication)
  stats_for_type(stats, result, :simplerss)
  stats_for_type(stats, result, :mrss)
end

# And now fot each parser, print the average time for RSS and ATOM, as well as the number of errors
stats.each do |parser_name, stats|
  puts "#{parser_name} => Average: #{stats[:any][:total_time]/stats[:any][:number_of_feeds]} (#{stats[:any][:errors]} errors) RSS: #{stats[:rss][:total_time]/stats[:rss][:number_of_feeds]} Atom: #{stats[:atom][:total_time]/stats[:atom][:number_of_feeds]}"
end
