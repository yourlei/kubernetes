#!/bin/bash

docker run -dit \
--name fluent \
-p 9880:9880 \
-v /Users/a123/fluent:/home/fluent \
-v $PWD/conf:/fluentd/etc \
-e FLUENTD_CONF=fluentd.conf \
fluent/fluentd
