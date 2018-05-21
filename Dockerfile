FROM ruby:alpine

MAINTAINER abcang <abcang1015@gmail.com>

# timezone
RUN apk --update add tzdata && \
  cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
  apk del tzdata && \
  rm -rf /var/cache/apk/*

RUN set -x \
  && apk upgrade --no-cache \
  && apk add --no-cache build-base

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile /app/
COPY Gemfile.lock /app/
RUN bundle install --deployment

COPY . /app

CMD ["ruby", "./main.rb"]
