FROM rabbitmq:management-alpine

RUN apk add --update jq curl bash

ADD rabbitmq_delayed_message_exchange-20171201-3.7.x.ez /plugins
RUN rabbitmq-plugins enable rabbitmq_delayed_message_exchange --offline
