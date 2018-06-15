require_relative 'rmq'
require 'bunny'
MAX_RETRIES = 3
BASE_RETRY_DELAY = 3000
ch = rmq_connect

def build_rabbitmq_topology(ch)
  @nanit_users_ex          = ch.direct   "nanit.users"
  @mailman_users_created_q = ch.queue    "mailman.users.created"
  @nanit_users_retry_ex    = ch.exchange "nanit.users.retry", {type: "x-delayed-message", arguments: {"x-delayed-type" => "direct"}}

  @mailman_users_created_q.bind(@nanit_users_ex, routing_key: "created")
  @mailman_users_created_q.bind(@nanit_users_retry_ex, routing_key: "mailman.users.created")
end

def start_subscriber(ch)
  @mailman_users_created_q.subscribe(manual_ack: true) do |delivery_info, properties, payload|
    queue_name = delivery_info.consumer.queue.name
    retry_count = properties[:headers]["x-retries"].to_i rescue 0
    puts "#{time} received message: #{payload} | retry_count: #{retry_count} "
    ch.ack(delivery_info.delivery_tag)
    if retry_count < MAX_RETRIES
      retry_delay = BASE_RETRY_DELAY * (retry_count + 1)
      putsi "publishing to retry (delayed) exchange with #{retry_delay / 1000}s delay "
      @nanit_users_retry_ex.publish(payload, routing_key: queue_name, headers: {"x-retries" => retry_count + 1, "x-delay" => retry_delay})
    else
      putsi "max retries reached - throwing message";
    end
  end
end

build_rabbitmq_topology(ch)
start_subscriber(ch)
@nanit_users_ex.publish("hello", routing_key: "created")

sleep 21

puts "#{time} Bye"


