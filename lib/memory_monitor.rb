require 'bundler'
Bundler.require

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
    sorted = @data.sort_by { |id, (url, memories)| memories.last - memories.first }
    puts sorted.inspect
  end
  
  private
  def memory
    `ps -o rss #{@pid}`[/\d+/].to_i
  end
end
