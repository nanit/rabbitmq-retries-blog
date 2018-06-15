require 'bunny'
$stdout.sync = true
def rmq_connect
  i = 1
  while true do
    begin
      conn = Bunny.new host: "rabbitmq", log_level: Logger::ERROR
      conn.start
      puts "connected!"
      return conn.create_channel
    rescue => e
      sleep 3
      puts "connecting to rabbitmq (attempt #{i})"
      i = i + 1
    end
  end
end

def time
  Time.now.strftime("%H:%M:%S")
end
def putsi(str)
  indentation = " " * 9
  puts "#{indentation}#{str}"
end
