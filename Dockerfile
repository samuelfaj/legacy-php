FROM ubuntu:20.04

RUN apt-get -y update \
    && apt-get -y install software-properties-common \
	&& /usr/bin/add-apt-repository -y ppa:nginx/stable \
	&& LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php \
	&& /usr/bin/apt-get -y update

RUN echo '=== Installing basic packages apt-get' \
	 && /usr/bin/apt-get -y update \
	 && /usr/bin/apt-get -y install \
	 	bsd-mailx \
	 	cron \
		exim4 \
		gcc \ 
        geoip-bin \ 
        geoip-database \ 
        git \
		libevent-dev \
        libmhash-dev \ 
        liblua5.1-0-dev \ 
        libpcre3 \
        libpcre3-dev \ 
        luarocks \ 
        lua-sql-mysql \
		make memcached \
		nginx-extras \ 
        ntp \
		openssl \
		patch perl \
		php-pear \
		php5.6 \
		php5.6-apcu \
		php5.6-cli \
		php5.6-common \
		php5.6-mbstring \
		php5.6-curl \
		php5.6-fpm \
		php5.6-dev \
		php5.6-gd \
		php5.6-imap \
		php5.6-mcrypt \
		php5.6-memcache \
		php5.6-mongo \
		php5.6-mysql \
		php5.6-oauth \
		php5.6-dev \
		php5.6-pgsql \
		php5.6-redis \
		php5.6-xml \
		# php5.6-snmp \
		screen \
		sudo \
		supervisor \
        libnginx-mod-http-ndk \
		telnet \
		vim \
		python \
		curl \ 
        libxml2 \
        wget \ 
        libnginx-mod-http-perl \ 
        libnginx-mod-http-lua \
        libnginx-mod-http-image-filter \ 
        libnginx-mod-http-geoip

RUN /usr/bin/luarocks install lua-cjson

RUN pecl install mongo

RUN /bin/mkdir -p /tmp/s3 \
	 && /bin/chmod -c 0777 /tmp/s3 \
	 && curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" \
	 && unzip awscli-bundle.zip \
	 && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

# Cleaning
RUN apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# Variaveis
ENV EC2_HOME "/opt/aws/apitools/ec2"
ENV EC2_AMITOOL_HOME "/opt/aws/amitools/ec2"
ENV JAVA_HOME "/usr/lib/jvm/jre"

# Common
RUN echo "==== Setando o timezone para BRST (America/Sao_Paulo)" \
    && /bin/ln -sf /usr/share/zoneinfo/America/Sao_Paulo  /etc/localtime

RUN mkdir -p /var/log/php-fpm/
RUN adduser apache > /dev/null 2> /dev/null

RUN echo '=== Extra configuration' \
    && mkdir -p /etc/sysconfig/ \
    && echo 'LANG="en_US.ISO-8859-1"' > /etc/sysconfig/i18n \
    && pecl channel-update pecl.php.net \
    && /bin/ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

RUN /bin/mkdir -p /media/ephemeral0/nginx.tmp \
    && /bin/rm -rf /var/lib/nginx/tmp \
    && /bin/ln -sf /media/ephemeral0/nginx.tmp /var/lib/nginx/tmp \
    && /bin/chmod +rx /var/lib/nginx

RUN echo "==== Configurando localização do cache de dyncontents e backends" \
    && /bin/mkdir -p /media/ephemeral0/nginx.cache/backend \
    && /bin/mkdir -p /media/ephemeral0/nginx.cache/node \
    && /bin/mkdir -p /media/ephemeral0/s3queue \
    && /bin/chown -Rf apache.apache /media/ephemeral0/nginx.cache /media/ephemeral0/s3queue

RUN echo "==== Configurando localização do /var/www/html" \
    && /bin/rm /var/www/html -Rf \
    && /bin/mkdir -p /media/ephemeral0/html/includes \
    && /bin/ln -s /media/ephemeral0/html /var/www/html \
    && /bin/chown -Rf apache.apache /media/ephemeral0/html \
    && VTAG=$(/bin/date +_%Y%m%d%H%M) \
    && echo $VTAG > /var/www/html/includes/vTag.txt \
    && echo '<script>var vTag="'$VTAG'";</script>' > /var/www/html/includes/vTag.html

RUN echo "==== Configurando rc.local" \
    && /bin/mkdir /dev/shm/templates_compiled/ \
    && /bin/chown -Rf apache.apache /dev/shm/templates_compiled/ \
    && /bin/chmod ug+rwx /dev/shm/templates_compiled/

RUN echo "==== Configurando script_generated" \
    && /bin/mkdir -p /var/www/templates/sources/script_generated \
    && /bin/chown -Rf apache.apache /var/www/templates/sources/script_generated

RUN echo "==== Cfg. Nginx" \
    && /bin/mv /var/log/nginx /media/ephemeral0/log.nginx \
    && /bin/ln -s /media/ephemeral0/log.nginx /var/log/nginx \
    && /bin/mkdir -p /media/ephemeral0/nginxcache \
    && /bin/mkdir -p /media/ephemeral0/nginx.cache \
    && /bin/chown -R apache.apache /media/ephemeral0 \
    && /bin/rm /etc/nginx/nginx.conf

EXPOSE 80
ENTRYPOINT ["/bin/bash"]

