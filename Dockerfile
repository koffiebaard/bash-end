FROM debian:jessie

RUN apt-get update
RUN apt-get install -y nginx fcgiwrap
RUN apt-get install -y wget telnet vim
RUN apt-get install -y mysql-client

# install jq from binary
RUN wget -O /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
RUN chmod +x /usr/bin/jq

# nginx config
COPY nginx-bash-end.conf /etc/nginx/sites-enabled/

# rights for the fcgi socket
RUN chmod 777 /run

RUN /etc/init.d/nginx reload

COPY . /var/www/

# change the db_host to connect to the host (instead of localhost on the docker container)
RUN sed -i 's/^db_host.*$/db_host: host.docker.internal/' /var/www/config.yaml

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 6969

STOPSIGNAL SIGTERM

#CMD ["nginx", "-g", "daemon off;"]

CMD service fcgiwrap start; nginx -g "daemon off;"