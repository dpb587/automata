FROM ubuntu:16.04
RUN apt-get update && apt-get install -y build-essential zlib1g-dev libssl-dev ruby curl git && curl -o /usr/bin/bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-0.0.18-linux-amd64 && chmod +x /usr/bin/bosh
RUN curl -Ls https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 > /usr/bin/jq && chmod +x /usr/bin/jq
