# Scheduling Data-Intensive Applications

This is an example project supporting a talk of the same title.

## goal

Use nomad instead of yarn if your task doesn't need hdfs


## backdrop

- tf vpc

- tf client and a handful of nomad servers (use provisioners on a raw ubuntu ami)

    - install consul (maybe w/dnsmasq)
    - install nomad

- create nomad exec job

- get nomad exec job to read from/to S3

- gen faker data in s3

- scrub it via nomad job


## demo

A demo job run and s3 output bucket contents is recorded
[here](http://archive.markmims.com/box/talks/2017-04-25-hashitalk/media/nomad-scrub.mkv)


## attribution

hc already has an ffmpeg nomad exec example.  This repo started life as a fork
of `github.com/hashicorp/nomad-dispatch-ffmpeg`.


