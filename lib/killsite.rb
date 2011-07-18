require 'uri'
require 'em-http-request'
require 'nokogiri'

class SiteKiller
  def initialize(prefix, limit = 1, verbose = false, observers = [])
    @count = 1
    @serial = "1"
    @prefix = URI.parse(prefix)
    @visited = { @prefix => 0 }
    @verbose = verbose
    @limit = limit
    @observers = observers
  end

  def run url = @prefix
    @limit.times { single_run url }
  end

  def single_run url
    id = @serial.succ!.dup
    @observers.each { |o| o.before_request(id, url) if o.respond_to? :before_request }
    
    http = EventMachine::HttpRequest.new(url).get
    http.errback do
      @count -= 1
      print 'X'
      EM.stop if @count == 0
    end
    
    http.callback do
      @observers.each { |o| o.after_request(id, url) if o.respond_to? :after_request }
      if @visited[url] == 0
        puts "Processing '#{url}'" if @verbose
        Nokogiri::HTML.parse(http.response).xpath("//a[@href]").each do |link|
          next_url = process_url link['href']
          if next_url and !@visited.include?(next_url)
            puts "  Queueing '#{next_url}'" if @verbose

            @visited[next_url] = 0
            @count += @limit
            @limit.times { single_run next_url }
          end
        end
        print "  Progress *" if @verbose
        $stdout.flush
      else
        print '*' if @verbose
        $stdout.flush
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
    return nil if url =~ /^javascript|^#|^mailto/
    URI.join @prefix.to_s, url
  end
end
