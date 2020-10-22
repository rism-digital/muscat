# Follows Ruby and Docker compose reference at https://docs.docker.com/compose/rails/
FROM ruby:2.6

# Install apt based dependencies required to run Rails as well as RubyGems.
RUN apt-get update && apt-get install -y build-essential nodejs
RUN apt-get update -y
#RUN apt-get install mysql-server -y
RUN apt-get install default-jdk -y
RUN apt-get update
#RUN apt-get install mysql-server libmysqlclient-dev # If mysql was not installed separately
RUN apt-get install -y dirmngr gnupg
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
RUN apt-get install -y apt-transport-https ca-certificates

#RUN apt install openjdk-8-jdk
#RUN apt-get install openjdk-8-jdk-headless
RUN apt-get install -y apache2 git ruby ruby-dev gcc zlib1g-dev libxml2-dev imagemagick libmagickcore-6.q16-dev libmagickwand-6.q16-dev   passenger libapache2-mod-passenger
RUN a2enmod passenger

RUN mkdir /var/www/.passenger
RUN chown -R www-data:www-data /var/www/.passenger

# Configure the main working directory. This is the base directory used in any further RUN, COPY, and ENTRYPOINT commands.
RUN mkdir -p /muscat
WORKDIR /muscat
RUN gem install docker-sync
RUN gem install bundler -v '1.17.3'
#RUN chown -R www-data:www-data muscat/
WORKDIR /muscat

# Copy the main application.
COPY . /muscat

RUN gem install debase
RUN gem install ruby-debug-ide
# Copy the Gemfile as well as the Gemfile.lock and install the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those two files are made.
COPY Gemfile /muscat/Gemfile
COPY Gemfile.lock /muscat/Gemfile.lock
RUN bundle install --jobs 20 --retry 5
RUN gem install docker-sync
# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000
EXPOSE 8983
#RUN iptables -A INPUT -p tcp -s localhost --dport 8983 -j ACCEPT
#RUN iptables -A INPUT -p tcp --dport 8983 -j DROP

# Configure an entry point, so we don't need to specify "bundle exec" for each of our commands.
ENTRYPOINT ["bundle", "exec"]

RUN apt-get remove openjdk* -y
RUN apt-get remove --auto-remove openjdk* -y
RUN apt-get purge openjdk* -y
RUN apt-get purge --auto-remove openjdk*

RUN apt-get install software-properties-common -y
RUN apt install apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common
RUN wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -
RUN add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
RUN apt update
RUN apt install adoptopenjdk-8-hotspot -y

#RUN apt install openjdk-8-jre-headless -y
# The main command to run when the container starts. Also tell the Rails dev server to bind to all interfaces by default.
#CMD rake jobs:work
CMD ["rails", "server", "-b", "0.0.0.0"]
#CMD tail -f /muscat/Gemfile
