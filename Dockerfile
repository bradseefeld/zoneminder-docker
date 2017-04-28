FROM ubuntu:16.04

EXPOSE 80

RUN apt-get update && apt-get install -f -y software-properties-common supervisor

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mysql-server && \
  add-apt-repository ppa:iconnor/zoneminder && \
  apt-get update && apt-get install -f -y zoneminder supervisor && \
  apt-get remove -y --purge mysql-server

# Setup permissions
RUN chmod 640 /etc/zm/zm.conf \
  && chown www-data:www-data /etc/zm/zm.conf \
  && chown -R www-data:www-data /usr/share/zoneminder/

COPY apache/zoneminder.conf /etc/apache2/conf-available/zoneminder.conf

RUN a2enconf zoneminder \
  && a2enmod cgi \
  && a2enmod rewrite \
  && a2dissite 000-default

RUN mkdir -p /var/log/zm && \
  chown -R www-data:www-data /var/log/zm

RUN mkdir -p /var/run/zm && \
  chown -R www-data:www-data /var/run/zm

# Do something like this to get logs to stdout. Once we know which logs are getting touched...
RUN ln -sf /dev/stdout /var/log/apache2/access.log
RUN ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log
RUN ln -sf /dev/stderr /var/log/apache2/error.log

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY phpdate.ini /etc/php/7.0/apache2/conf.d/25-phpdate.ini
WORKDIR /usr/share/zoneminder

COPY zm.conf /etc/zm/zm.conf
COPY maybe-create-database.sh ./

ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_LOCK_DIR=/tmp
ENV APACHE_PID_FILE=/tmp/apache.pid
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
RUN mkdir -p /var/log/apache2

RUN apt-get install -y python-pip && pip install supervisor-stdout

# Runs the perl daemon. We switch user to www-data so that the perl script can
# switch back to root :( Not my design...
# su -c "/usr/bin/zmpkg.pl start" -s /bin/sh www-data
#CMD ["su", "-c", "'/usr/bin/zmpkg.pl start'", "-s", "/bin/sh", "www-data"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
