FROM ruby:latest

RUN bundle config --global

WORKDIR /usr/src/app/

COPY Gemfile Gemfile.lock ./
RUN bundle install
RUN bundle add rackup

ADD . /usr/src/app/

EXPOSE 3333

CMD ["ruby", "/usr/src/app/helloworld.rb"]