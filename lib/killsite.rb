require 'bundler'
require 'uri'
Bundler.require

class KillSite
  def initialize(prefix, limit = 1, verbose = false)
    @count = 1
    @prefix = prefix
    @visited = [prefix]
    @queue = [prefix]
    @verbose = verbose
    @limit = limit
  end

  def run
    EM.stop if @count == 0
    return if @queue.empty?

    url = @queue.shift

    http = EventMachine::HttpRequest.new(url).get
    http.callback do
      puts "Processing '#{url}'" if @verbose

      Nokogiri::HTML.parse(http.response).xpath("//a[@href]").each do |link|
	next_url = process_url link['href']
	if next_url and !@visited.include? next_url
	  puts "  Queueing '#{next_url}'" if @verbose

	  @limit.times { @queue << next_url }
	  @visited << next_url
	  @count += @limit
	end
      end
      @count -= 1
      EM.next_tick { run }
    end
  end

private
  def process_url url
    return nil if url =~ /^http/ and URI.parse(@prefix).host != URI.parse(url).host
    return nil if url =~ /^javascript/
    return nil if url =~ /^#/
    URI.join @prefix, url
  end
end
