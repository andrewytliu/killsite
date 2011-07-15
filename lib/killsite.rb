require 'bundler'
require 'uri'
Bundler.require

class SiteKiller
  def initialize(prefix, limit = 1, verbose = false)
    @count = 1
    @prefix = URI.parse(prefix)
    @visited = { @prefix => 0 }
    @verbose = verbose
    @limit = limit
  end

  def run url = nil
    url ||= @prefix

    http = EventMachine::HttpRequest.new(url).get
    http.callback do
      if @visited[url] == 0
        puts "Processing '#{url}'" if @verbose
        Nokogiri::HTML.parse(http.response).xpath("//a[@href]").each do |link|
          next_url = process_url link['href']
          if next_url and !@visited.include?(next_url)
            puts "  Queueing '#{next_url}'" if @verbose

            @visited[next_url] = 0
            @count += @limit
            @limit.times { run next_url }
          end
        end
        print "  Progress " if @verbose
      else
        print '*' if @verbose
      end

      @visited[url] += 1
      puts if @verbose and @visited[url] == @limit
      @count -= 1
      EM.stop if @count == 0
    end
  end

  private
  def process_url url
    return nil if url =~ /^http/ and URI.parse(@prefix.to_s).host != URI.parse(url).host
    return nil if url =~ /^javascript/ or url =~ /^#/
    URI.join @prefix.to_s, url
  end
end
