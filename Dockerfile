FROM ruby:3.4.7-slim

ENV TZ=America/Chicago

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY app.rb .

EXPOSE 8000

CMD ["bundle", "exec", "ruby", "app.rb"]
