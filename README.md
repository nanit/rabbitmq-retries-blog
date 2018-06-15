# RabbitMQ Retries Topologies

If you haven't read the blog post, please do so [here](link)

This repo contains 4 different topologies to implement retries on RabbitMQ
The only thing you need to be able to run the examples is [docker-compose](https://docs.docker.com/compose/install/)
To run each of the tasks:

1. Clone this repo
2. In the root dir run: OPTION=1 make run-example

This will create the topology and run a retry consumer with some output to stdout so you can see how it works
`OPTION` can be set to 1-4 according to the scenraio you want to run
