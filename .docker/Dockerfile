FROM ruby:2.5-alpine3.8
RUN apk add --update alpine-sdk

ARG RUBY_GEMS="riemann-tools"
RUN gem install --verbose --no-rdoc --no-ri $RUBY_GEMS

CMD ["riemann-health", "--help"]
