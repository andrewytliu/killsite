require 'open-uri'
require 'nokogiri'

class SiteKiller
  def initialize(prefix, limit = nil, concurrency = nil, verbose = nil, observers = nil)
    @prefix = URI.parse(prefix)
    @visited = [@prefix]
    @queue = [@prefix]
    @verbose = verbose || false
    @limit = limit || 1
    @concurrency = concurrency || 10
    @concurrency = @limit if @concurrency > @limit
    @observers = observers || []
  end

  def run
    while @queue.size > 0
      url = @queue.shift
    
      @observers.each { |o| o.before_request(url) if o.respond_to? :before_request }
      `ab -n #{@limit} -c #{@concurrency} #{url}`
      @observers.each { |o| o.after_request(url) if o.respond_to? :after_request }
      
      puts "Processing '#{url}'" if @verbose
      begin
        response = open(url).read
        Nokogiri::HTML.parse(response).xpath("//a[@href]").each do |link|
          next_url = process_url link['href']
          if next_url and !@visited.include?(next_url)
            puts "  Queueing '#{next_url}'" if @verbose

            @visited << next_url
            @queue << next_url
          end
        end
      rescue => e
        puts "  No valid response: #{e}"
      end
    end
  end

  private
  def process_url url
    return nil if url =~ /^http/ and URI.parse(@prefix.to_s).host != URI.parse(url).host
    return nil if url =~ /^javascript|^#|^mailto/
    URI.join @prefix.to_s, url
  end
end
