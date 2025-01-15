# Installation instructions

This document describes how to bootstrap into the Muscar web application. The documentation is updated for Debian 12

## Requirements

The following other libraries and programs are needed

* Ruby \> 3.2  
* Rails 7.2  
* MySQL \> 8.0.4 or MariaDB 10.x  
* Git  
* Java 17+

**NOTE** From Muscat 6.1 MySQL *8.0.4 is required* for autocomplete and comments to properly work, as the REGEX library was changed.  MariaDB 10.x, as provided by Debian 10 (Buster) also seems to work properly.

## Preliminary steps

Make sure the system is updated

```
sudo apt-get update
```

## Mysql 8

All modern systems should have a package. Make sure the`libmariadbd-dev`  client library is used instead of the default Mysql one.

```
sudo apt-get install mysql-server
# This is important! do NOT install the mysql client
sudo apt remove libmysqlclient-dev
sudo apt install libmariadbd-dev
```

### Installing from the Oracle distribution

Depending on your system, a package for Mysql 8 may not exist. In this case use the official package provided by Oracle [https://dev.mysql.com/downloads/repo/apt/](https://dev.mysql.com/downloads/repo/apt/)

NOTE: Download the latest version or the GPG keys may have been expired\! Copy the file from the link provided in that page, there is no need for an account, follow the "No thanks, just start my download" link. In this case it points to [https://dev.mysql.com/get/mysql-apt-config\_0.8.15-1\_all.deb](https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb)

```
wget https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.15-1_all.deb
```

(obviously subsitute with the exact file name in the link).  dpk will prompt a screen to configure tha package, select option to configure the server version and select 8, then exit.

Then update and install mysql:

```
sudo apt-get update
sudo apt-get install mysql-server
```

When prompted, select *use legacy passwords* as not all connectors for the moment work with the new system. This will be updated in the future. Also install the newest versions of the connector libraries:

```
sudo apt-get install libmysqlclient21 libmysqlclient-dev
```

## MariaDB 10

If you are using Debian 10 (Buster), the default MariaDB server (mariadb-server, that pulls 10.3) and clients (ruby-mysql2) are just fine.

## System dependencies

### Base packages

```
sudo apt-get install git gcc curl zlib1g-dev libxml2-dev imagemagick libmagickcore-6.q16-dev libmagickwand-6.q16-dev openjdk-17-jre-headless make libsqlite3-dev g++ nodejs
```

### How to break free of a proxy

```
# Run SSH on your local machine
# On your local machine, connect to iself...
ssh -N -D 54321 localhost

# On the remote machine, forward the remote port to the local one...
ssh -R9080:localhost:54321 remote-machine

# Then in the remote machine...
export http_proxy=socks5://localhost:9080
export https_proxy=socks5://localhost:9080

# For culr edit ~/.curlrc
proxy = socks5://localhost:9080
```

### Muscat user

```
sudo adduser muscat
```

Make sure the user can not login via ssh.  
Edit /etc/ssh/sshd\_config or make a file like /etc/ssh/sshd\_config.d/muscat.conf and add:

```
DenyUsers	muscat
```

Note the tab and not spaces\!

Add it temporarily to sudoers for the next step.

### RVM

Current installations are supported only via rvm, used to get the correct version of ruby.  
Install rvm following the instructions here: [https://rvm.io/rvm/install](https://rvm.io/rvm/install) ot the following. RVM will use .curlrc for a proxy as setup above

```
gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash

rvm install 3.3.6
rvm gemset create rails
rvm use 3.3.6@rails
rvm --default use 3.3.6@rails

source ~/.rvm/scripts/rvm
```

## Bootstrap the application

Get the sources if necessary ([https://github.com/rism-ch/muscat](https://github.com/rism-ch/muscat) and [https://github.com/rism-ch/muscat-guidelines](https://github.com/rism-ch/muscat-guidelines))  
All these commands are executed from the muscat user in the chosen muscat installation directory.

```
su - muscat # if necessary
git clone https://github.com/rism-ch/muscat.git --recursive
cd muscat
bundle install
```

Alternatively, you can just download and use the stable release tarballs found in [https://github.com/rism-ch/muscat/releases](https://github.com/rism-ch/muscat/releases).

Install base configuration:

```
cd muscat/config
cp sample_database.yml database.yml
cp sample_application.rb application.rb
cp muscat-custom-sample.scss ../vendor/assets/stylesheets/muscat-custom.scss
```

Set up databases access:

```
sudo mysql # Or log in with a user that has user creation privileges
```

Create the user, substitute with an appropriate user and password\!

```
CREATE DATABASE muscat_development CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER 'rism'@'localhost';
ALTER USER 'rism'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
GRANT ALL ON muscat_development.* TO 'rism'@'localhost';
```

Remember username and pass should be the same as in database.yml.  Then, migrate the database (that us, update the structure):

```
bundle exec rake db:migrate # development
```

NOTE: in a production environment all the tasks must declare RAILS\_ENV=production to run. For local development this is not necessary

```
sudo RAILS_ENV=production bundle exec rake db:migrate ## on a production system
```

Add basic dataset if needed:

```
bundle exec rake db:seed
```

### Create credential file

All the secret keys are now stored in the rails 5.2 credentials file, which is not included in the repo.  A blank on must be created with:

```
rails credentials:edit
```

This will automatically create credentials.yml.enc and the master key, along with a cookie secret key. 

The user and password are needed for background search and export, and should be a muscat user with minimum guest access.  So, to use the other services on Muscat, such as history, add to this file:

```
export:
  user: "xx"
  password: "xx"
```

Remember that they key must be readable from the user running apache, so check the permissions and change the user is needed:

```
chown www-data:www-data config/master.key
```

Lastly, precompile the assets. Use the correct env

```
bundle exec rake RAILS_ENV=production assets:precompile
```

### Add the digital objects directory

It should be in public/system. It can be a symlink to another place. The credentials must be the same as the app (ex. muscat)

## Solr installation and configuration

As of Muscat 7.1, external Solr 8.8 installations are now supported. This allows, for instance, the use of a Solr cluster hosted on a separate server. While the internal Solr 5.5 server remains functional, it will no longer be supported in the future due to its outdated status and compatibility issues with modern Java versions. Muscat's core is designed to work with any Solr installation; the following example outlines a sample installation procedure, which should be customized to suit individual setups.

### Installation using a "stock" solr using included setup script

**NOTE** this was tested on Linux distributions only. Grab a copy of the official distribution (8.11.4 at the time of writing) and unpack it in a suitable place. This is run as root or with sudo.

```
wget https://www.apache.org/dyn/closer.lua/lucene/solr/8.11.4/solr-8.11.4.tgz?action=download -O solr-8.11.4.tgz
tar -xvzf solr-8.11.4.tgz
```

Solr needs two directories, one for data and one for the binaries. The latter is generally /opt/solr, and the data installation for this example will be /data/solr. Extract just the installation script:

```
tar xzf solr-8.11.4.tgz solr-8.11.4/bin/install_solr_service.sh --strip-components=2
```

And execute it:

```
sudo ./install_solr_service.sh solr-8.11.4.tgz -d /data/solr -p 8983
```

This will create the directory layout as above. It will also create a `solr` user. For the complete reference see [https://solr.apache.org/guide/8\_11/taking-solr-to-production.html](https://solr.apache.org/guide/8_8/taking-solr-to-production.html) Now copy over the Muscat core:

```
cp -R $MUSCAT_HOME/solr-configuration/muscat /data/solr/data
chown -R solr:solr /data/solr/data/muscat
```

Where `/data/solr/` in the directory specified above with \-d. Solr includes a startup script so

```
systemctl daemon-reload
service solr start
```

Should start it. The log files in this case are found in `/data/solr/logs`.

It is recommended to add more memory to the process:

```
nano /etc/default/solr.in.sh
# edit the line SOLR_JAVA_MEM, for exampleSOLR_JAVA_MEM="-Xms8g -Xmx8g"
```

### Installation using a "stock" solr

But without using the installation script  
Grab a copy of the official distribution (8.11.4 at the time of writing) and unpack it in a suitable place. **NOTE** Solr is installed and run as the **muscat** user.

```
wget https://www.apache.org/dyn/closer.lua/lucene/solr/8.11.4/solr-8.11.4.tgz?action=download -O solr-8.11.4.tgz
tar -xvzf solr-8.11.4.tgz
```

When using this distribution, you can copy the `muscat` core bundled with Muscat directly into the binary distribution

```
cp -R $MUSCAT_HOME/solr-configuration/muscat solr-8.11.4/server/solr
```

Solr should run at this point:

```
./bin/solr start -p 8983 # Run as the muscat user
```

Or an appropriate startup script may be used

## Development Startup

Make sure Solr and Mysql are running. Default (development) startup:

```
rails s -e development
```

Try to open http://$IP\_ADDRESS:3000/

For startup in production mode see "Starting Daemons in Production Mode"

For refreshing an installation in production mode (with sudo, as root or sudo \-u www-data depending on the permissions on the installation dir):

```
bundle exec rake RAILS_ENV=production assets:clean
bundle exec rake RAILS_ENV=production assets:precompile
```

## Logging In

A default administrative user has been created as part of the installation process. To log in, go to `http://ip:3000/admin` and log in with the following credentials:

```
username: admin@example.com
password: Password1234
```

It is advised that you delete this account after creating a new administrative user in the admin interface.

#### Index rebuilding:

```
rake sunspot:reindex
```

In production mode run:

```
RAILS_ENV=production rake sunspot:reindex
```

Specify only a model:

```
rake sunspot:reindex[,Person]
```

Do reindex in 1 record batches, useful if reindex crashes to see in which one (very slow to start)

```
rake sunspot:reindex[1]
```

## Passenger standalone and Nginx

The recommended installation is as standalone and with Nginx as a frontend. The default gemfile includes the passenger gem.  
It assumes Muscat was installed with the muscat user.  
Edit `/etc/systemd/system/muscat.service` for the application startup

```
[Unit]
Description=Muscat
After=network-online.target

[Service]
Restart=always
RestartSec=5
TimeoutSec=5
User=muscat
Group=muscat
WorkingDirectory=/INSTALLATION/DIR/muscat
ExecStart=/home/muscat/.rvm/bin/rvm 3.3.6@rails do bundle exec passenger start

[Install]
WantedBy=multi-user.target
```

Change `/INSTALLATION/DIR/` to the actual installation dir. Then Edit `Passengerfile.json` for the basic configuration

```
{
  "environment": "production",
  "port": 8081,
  // Passenger is managed by systemd
  "daemonize": false,
  "user": "muscat"
}
```

To try the installation, run

```
bundle exec passenger start
```

If passenger boots and installs all the modules correctly, it is possible to reload systemd

```
systemctl daemon-reload
systemctl enable muscat
systemctl start muscat
```

Now it is possible to actually test the installation. If behind a proxy, do

```
ssh remote-host -L8081:localhost:8081
```

Note: 8081 is the port passenger is listening on. Then it can be accessed via localhost:8081

### Sample nginx configuration:

```
# These are some "magic" Nginx configuration options that aid in making
# WebSockets work properly with Passenger Standalone. Please learn more
# at http://nginx.org/en/docs/http/websocket.html
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

// Same as Passenger.json
upstream muscat {
    server localhost:8081;
}

# Virtual host configuration for muscat.
server {
    server_name         www.muscat.com;
    root                /var/www/muscat-dir-for-nginx;

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    keepalive_timeout 70;

    ssl_certificate		    /CERTS/fullchain.pem;
    ssl_certificate_key		/CERTS/privkey.pem;
    include               ssl_include;

    # ignore all location requests that start with a dot.
    # Return 404 to make it look like it's not found (otherwise
    # a 403 would say it is there, you just can't access it)
    location ~ /\. {
        deny all;
        access_log off;
        return 404;
    }

    if (-f /etc/nginx/muscat-test.unavailable) {
        return 503;
    }

    error_page 503 @custom503;
    location @custom503 {
        root    /var/www/muscat-dir-for-nginx/www;
        rewrite ^(.*)$ /nginx_errors/503.html break;
        internal;
    }

    location / {
        proxy_pass http://muscat;

        proxy_http_version 1.1;
        proxy_set_header        Host                $http_host;
        proxy_set_header        Upgrade             $http_upgrade;
        proxy_set_header        Connection          $connection_upgrade;
        proxy_set_header        X-Real-IP           $remote_addr;
        proxy_set_header        X-Forwarded-For     $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto   $scheme;
        proxy_set_header        X-Scheme            $scheme;

        proxy_buffering off;
    }
}

server {
    server_name         muscat.com;
    listen              80;
    listen              [::]:80;

    # Since we're just redirecting from this configuration, we don't need to count it in the
    # access logs.
    access_log off;

    # Ensure any challenges from Let's Encrypt are served.
    # directory on the server for this.
    location ~ /\.well-known/acme-challenge {
        root /var/www/muscat-dir-for-nginx/www;
    }

    # Redirect all other traffic to the muscat instance.
    location / {
        return      301 https://muscat.com/$request_uri;
    }
}
```

Change `muscat.com` to the actual address, and create muscat-dir-for-nginx and muscat-dir-for-nginx/www Create the file `/etc/nginx/ssl_include` for the SSL configuration:

```
add_header Strict-Transport-Security "max-age=63072000";
ssl_stapling                on;
ssl_stapling_verify         on;
ssl_session_tickets         on;
ssl_session_timeout         24h;
ssl_session_cache           shared:SSL:100m;
ssl_session_ticket_key      /etc/nginx/ssl/ticket.key;
ssl_dhparam                 /etc/nginx/ssl/dhparam.pem;
ssl_prefer_server_ciphers   on;
ssl_protocols               TLSv1.2 TLSv1.3;
ssl_ciphers                 ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
resolver                    8.8.8.8 [2001:4860:4860::8888] 1.1.1.1 [2606:4700:4700::1111] 8.8.4.4 1.0.0.1;
```

## Production Installation and daemons

`DelayedJob` should run from the muscat user:

```
RAILS_ENV=production bin/delayed_job start --pool=reindex,triggers,folders:10 --pool=sub_reindex:10 --pool=resave --pool=export
```

Other ways to start delayed\_job:

```
sudo RAILS_ENV=production bin/delayed_job start
rake jobs:work # Run in foreground
rake jobs:workoff # Run all jobs in foreground and exit
rake jobs:clear # Clear failed jobs
## in production it is then...
RAILS_ENV=production bundle exec rake jobs:<xxx>
```

Depending on the env, remove sudo if necessary. RAILS\_ENV is needed only on production, and has to come **after** sudo.

It is also good to block access to Solr:

```
sudo iptables -A INPUT -p tcp -s localhost --dport 8983 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8983 -j DROP
```

### Crontab installation

In version 7.0 the crono scheduler was removed and a normal crontab plus a script is provided. The default crontab file should be linked in /etc/con.d. Edit the muscat\_crontab to set PATH\_TO to the correct muscat installation, you will need to do it by hand.

On debian/ubuntu this should work:

```
ln -s config/muscat_crontab /etc/cron.d
chmod +x /etc/cron/muscat_crontab
sudo service cron restart
```

**NOTE** If you ever change the cron file name, it CANNOT contain dots\! Or it will silently fail.

### Logrotate

It is handy to rotate the logs in production, in /etc/logrotate.d:

```
/PATH_TO/muscat/log/*.log {
    size=100M
    missingok
    rotate 10
    compress
    delaycompress
    notifempty
    copytruncate
   prerotate
       bash -c "[[ ! $1 =~ validation.log ]]"
   endscript
}
```

This file is also in config/muscat.logrotate.sample. It can be tested:

```

logrotate -d /etc/logrotate.d/muscat.logrotate
```

### Some MySQL optimizations

Add to /etc/mysql.cnf

```
[mysqld]

innodb_buffer_pool_size = 8G
innodb_log_buffer_size = 512M
innodb_log_file_size = 1G
innodb_write_io_threads = 16
innodb_flush_log_at_trx_commit = 0
```

To speed up imports. (See here for \[more)\]([https://www.percona.com/blog/2014/01/28/10-mysql-performance-tuning-se](https://www.percona.com/blog/2014/01/28/10-mysql-performance-tuning-se)ttings-after-installation/)

## Lazy's man import speedup

On a full muscat DB there can be many many *old versions* in the `versions` table, since version snapshots are kept for each saved item. When doing development this can be quite annoying since it can take up to 30 minutes to restore a db.

```
sed '/INSERT INTO `versions`/d' muscat_dump.sql > muscat_no_versions.sql
```

Removes all the old versions. From 30 minutes to 9\.

### Validation Exclusions

This concerns really only the internal use of the source validator job, which can validate all the sources periodically. Often it is useful to add blanket exclusions if some data will not be corrected. They must be placed in the folder `validation_exclusions` in config/, with subfolders containing the exclusions for each model, for example:

```
config/validation_exclusions/source/exclusions.yml
```

is the configuration file for sources. This is a sample configuration

```
exclude:
  "650":
    tags:
      "0":
        from_file_list: 650_0_exclude
  "588":
    tags:
      "a":
        and_rules: 
          id_prefix: "234"
          creation_date: "2023-06-06"
```

Every tag specifies some rules for the subtags to be excluded:

* `from_file_list`: read ids to be excluded from a file, one by line  
* `id_prefix`: ignore records with the id starting with these digits  
* `creation_date`: ignore records created exactly on this date

Other rules will be implemented in the future.

No rules are provided by default in muscat and none should be pushed to the repo since the use depends on the user data.

## Muscat user authentication

In Muscat's default configuration, users are created and authenticated in Muscat's own local database. This authentication method is called `:database_authenticatable`, and if it is fine to you, there is no need to modify nor configure anything further.

There is an alternative Single Sign On (SSO) authentication for corporate environments, and it is implemented using SAML integration. If you are interested, please follow this steps as described:

1. First, run the generator with `bin/rails g muscat:install_saml` to get the required configuration files.  
     
2. Add :saml\_authenticatable as one of the AUTHENTICATION\_METHODS in `config/application.rb` (order of methods is not important)  
     
3. SAML users will have the role defined by `RISM::SAML_AUTHENTICATION_CREATE_USER_ROLE` which is "guest" by default. Edit `config/application.rb` and uncomment `RISM::SAML_AUTHENTICATION_CREATE_USER_ROLE` and set the desired role if you prefer another one.  
     
4. Customize the new devise login form that the generator created at `"app/views/active_admin/devise/sessions/new.html.erb"`. At least, edit the file and remove the unused link to the IdP or define yours if it's none of the two.  
     
5. Configure the SAML settings at `config/initializers/devise_saml_authenticatable.rb`  
     
   - To automatically parse IdP's metadata, parse the remote url just before ruby\_saml's settings

```
 ...
 idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
 config.saml_config= idp_metadata_parser.parse_remote "https://remote-sso-server.example.org/saml/idp/metadata"
 config.saml_configure do |settings|
 ...
```

6. Configure the mapping between SAML user attributes (keys) and application user attributes (values).  
     
7. Muscat must be restarted if any configuration is changed.

The SSO authentication method is added as convenience to Muscat to serve some external users, but it is not supported by upstream developers. If you need support, please contact its authors: [https://coditramuntana.com/en/contact](https://coditramuntana.com/en/contact) .

## Basic Apache configuration (deprecated)

Example Apache configuration:

```
# create /usr/local/etc/apache/Includes/default.conf
# and add default site:
<VirtualHost *:80>
        # ServerName www..org
        DocumentRoot /var/rails/rism-ch/public
        <Directory "/var/rails/rism-ch/public">
                Options All -Indexes +ExecCGI -Includes +MultiViewsny
                Require all granted
        </Directory>
        RailsEnv production
</VirtualHost>
```

Double check permissions in the muscat installation. Also make sure DocumentRoot and Directory point to public/ in the muscat installation location.

Start Apache and the related services in production mode (see below).

## Apache-itk option

Alternatively, you can take advantage of the Apache itk module, that simplifies not only having more than one Muscat in a single server using virtual hosts, but also the whole file permissions and ownership altogether. This Apache module ([http://mpm-itk.sesse.net/](http://mpm-itk.sesse.net/)) makes the Apache web server to run as a plain user, so it is the owner of the files, and it is no longer necessary file ownership via chown or users via sudo.  Apache-itk is an official Debian and Ubuntu package, so:

```
apt install libapache2-mpm-itk
```

And add the following stanza in the apache configuration file, for example just before the DocumentRoot declaration:

```
<IfModule mpm_itk_module>
   AssignUserId muscat_linux_user_name muscat_linux_group
</IfModule>
```

where `muscat_linux_user_name` and `muscat_linux_group` are the first two fields of the output of the id shell command.

npm install node-gyp yarn add i18n-js@latest  
