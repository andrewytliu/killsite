
class MemoryMonitor
  def initialize pid
    @pid = pid
    @data = {}
  end
  
  def before_request id, url
    @data[id] = [url, [memory]]
  end
  
  def after_request id, url
    @data[id].last << memory
  end
  
  def report
    combined = @data.values.inject(Hash.new(0)) { |h, (url, memories)| h[url] += memories.last - memories.first; h }
    sorted = combined.sort_by { |url, memory| -memory }
    
    
    puts "\nMost memory used actions:"
    sorted.each_with_index do |(url, memory), index|
      puts "##{index + 1}\t#{memory/1024} KB\t=> #{url.to_s}"
    end
  end
  
  private
  def memory
    mem = `ps -o rss #{@pid}`[/\d+/].to_i
    raise 'invalid PID' unless mem > 0
    mem
  end
end
