FROM gliderlabs/alpine:latest

RUN apk-install ruby ruby-json

COPY bin/github_verify.rb /usr/local/bin/

RUN chmod +x /usr/local/bin/github_verify.rb