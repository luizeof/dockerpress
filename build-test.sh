#!/bin/bash
docker build -t local/dockerpress:test .

docker image rm local/dockerpress:test
