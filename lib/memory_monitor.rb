
class MemoryMonitor
  def initialize pid
    @pid = pid
    @data = {}
  end
  
  def before_request url
    @data[url] = memory
  end
  
  def after_request url
    @data[url] = memory - @data[url]
  end
  
  def report
    sorted = @data.sort_by { |url, memory| -memory }
    
    
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
