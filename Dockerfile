# Use an official Ruby runtime as a parent image
FROM ruby:3.1.2

# Install essential dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
# RUN gem install pg 
# Set the working directory in the container
WORKDIR /app

# Install bundler
RUN gem install bundler -v 2.3.6

# Copy the Gemfile and Gemfile.lock from the application directory into the container
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install 
# Add Yarn installation
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

# Copy database.yml from host to container
COPY config/database.yml /app/config/database.yml

# Copy the application code into the container
COPY . .
COPY /db/migrate /app/db/migrate
# RUN bundle exec rake db:setup RAILS_ENV=development
# RUN bundle exec rails webpacker:install
# Expose port 3000 to the outside world
COPY entrypoint.sh /usr/bin/entrypoint.sh
# Set the entrypoint
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000 3001
# Start the Rails server when the container launches
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
