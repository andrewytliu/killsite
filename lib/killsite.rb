require 'uri'
require 'em-http-request'
require 'nokogiri'

class SiteKiller
  def initialize(prefix, limit = 1, verbose = false, observers = [])
    @count = 1
    @prefix = URI.parse(prefix)
    @visited = [@prefix]
    @verbose = verbose
    @limit = limit
    @observers = observers
  end

  def run url = @prefix
    @observers.each { |o| o.before_request(url) if o.respond_to? :before_request }
    
    multi = EventMachine::MultiRequest.new
    @limit.times { multi.add(EventMachine::HttpRequest.new(url).get) }
    
    multi.callback do
      @observers.each { |o| o.after_request(url) if o.respond_to? :after_request }
      
      http = (multi.responses[:succeeded].size > 0) ? multi.responses[:succeeded].first : nil
      
      puts "Processing '#{url}'" if @verbose
      if http
        Nokogiri::HTML.parse(http.response).xpath("//a[@href]").each do |link|
          next_url = process_url link['href']
          if next_url and !@visited.include?(next_url)
            puts "  Queueing '#{next_url}'" if @verbose

            @visited << next_url
            @count += 1
            run next_url
          end
        end
      else
        puts "  No valid response"
      end
      puts "  Progress #{'*' * multi.responses[:succeeded].size}#{'X' * multi.responses[:failed].size}" if @verbose
      $stdout.flush
      
      @count -= 1
      EventMachine.stop if @count == 0
    end
  end

  private
  def process_url url
    return nil if url =~ /^http/ and URI.parse(@prefix.to_s).host != URI.parse(url).host
    return nil if url =~ /^javascript|^#|^mailto/
    URI.join @prefix.to_s, url
  end
end
