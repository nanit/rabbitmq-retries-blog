require_relative 'rmq'
require 'bunny'
MAX_RETRIES = 3
RETRY_DELAY=5000
ch = rmq_connect

def build_rabbitmq_topology(ch)
  @nanit_users_ex          = ch.direct "nanit.users"
  @mailman_users_created_q = ch.queue  "mailman.users.created", arguments: {"x-dead-letter-exchange" => "nanit.users.retry1", "x-dead-letter-routing-key" => "mailman.users.created"}
  @nanit_users_retry1_ex   = ch.direct "nanit.users.retry1"
  @nanit_users_retry_q     = ch.queue  "nanit.users.wait_queue", arguments: { "x-message-ttl" => RETRY_DELAY, "x-dead-letter-exchange" => "nanit.users.retry2"}
  @nanit_users_retry2_ex   = ch.direct "nanit.users.retry2"

  @nanit_users_retry_q.bind     @nanit_users_retry1_ex, routing_key: "mailman.users.created"
  @mailman_users_created_q.bind @nanit_users_ex, routing_key: "created"
  @mailman_users_created_q.bind @nanit_users_retry2_ex, routing_key: "mailman.users.created"
end

def start_subscriber(ch)
  @mailman_users_created_q.subscribe(manual_ack: true) do |delivery_info, properties, payload|
    retry_count = properties[:headers]["x-death"].first["count"] rescue 0
    puts "#{time} received message: #{payload} | retry_count: #{retry_count} "
    if retry_count < MAX_RETRIES
      putsi "rejecting (retry via DLX)"; ch.reject(delivery_info.delivery_tag)
    else
      putsi "max retries reached - acking"; ch.ack(delivery_info.delivery_tag)
    end
  end
end

build_rabbitmq_topology(ch)
start_subscriber(ch)
@nanit_users_ex.publish("hello", routing_key: "created")

sleep 21

puts "#{time} Bye"
