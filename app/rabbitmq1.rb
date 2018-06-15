require_relative 'rmq'
require 'bunny'
ch = rmq_connect

def build_rabbitmq_topology(ch)
  @nanit_users_ex          = ch.direct "nanit.users"
  @mailman_users_created_q = ch.queue "mailman.users.created"

  @mailman_users_created_q.bind(@nanit_users_ex, routing_key: "created")
end

def start_subscriber(ch)
  @mailman_users_created_q.subscribe(manual_ack: true) do |delivery_info, properties, payload|
    puts "#{time} received message: #{payload} | redelivered: #{delivery_info.redelivered}"
    putsi (delivery_info.redelivered ? "already retried, rejecting with retry=false" : "first try, rejecting with requeue=true")  
    ch.reject(delivery_info.delivery_tag, !delivery_info.redelivered)
  end
end

build_rabbitmq_topology(ch)
start_subscriber(ch)
@nanit_users_ex.publish("hello", routing_key: "created")
sleep 5

puts "#{time} Bye"
