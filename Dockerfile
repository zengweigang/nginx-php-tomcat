FROM       centos:centos7.1.1503
MAINTAINER zengweigang <zengweigang@gmail.com>

ENV TZ "Asia/Shanghai"
ENV TERM xterm

RUN yum install -y curl wget tar bzip2 unzip vim-enhanced passwd sudo yum-utils hostname net-tools rsync man \
        gcc gcc-c++ git make automake cmake patch logrotate python-devel libpng-devel libjpeg-devel \
        php-cli php-mysql php-pear php-pecl-memcache php-ldap php-mbstring php-soap php-dom php-gd php-xmlrpc php-fpm php-mcrypt java-1.8.0-openjdk-devel.x86_64 \
        fuse-devel libcurl-devel libxml2-devel make openssl-devel \
		pcre-devel zlib-devel openssl-devel

ENV NGINX_VERSION 1.8.0
RUN mkdir /opt/nginx && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O /opt/nginx.tar.gz && tar xfz /opt/nginx.tar.gz -C /opt/nginx && rm -f /opt/nginx.tar.gz

RUN mkdir /opt/http_subs && wget https://raw.githubusercontent.com/szmolin/dist/master/ngx_http_substitutions_filter_module/ngx_http_subs_filter_module.c -O /opt/http_subs/ngx_http_subs_filter_module.c && wget https://raw.githubusercontent.com/szmolin/dist/master/ngx_http_substitutions_filter_module/config -O /opt/http_subs/config

RUN useradd --system --no-create-home --user-group nginx && mkdir -p /var/cache/nginx/ && \
    cd /opt/nginx/nginx-${NGINX_VERSION} && ./configure --prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-http_auth_request_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-file-aio \
	--with-http_spdy_module \
	--with-ipv6 \
	--with-threads \
	--add-module=/opt/http_subs \
	&& make && make install

ADD aliyun-epel.repo /etc/yum.repos.d/epel.repo

RUN yum install -y --enablerepo=epel pwgen python-pip && \
    yum clean all

RUN pip install supervisor
ADD supervisord.conf /etc/supervisord.conf

RUN mkdir -p /etc/supervisor.conf.d && \
    mkdir -p /var/log/supervisor

RUN wget https://raw.githubusercontent.com/szmolin/dist/master/s3fs/v1.79.tar.gz -O /usr/src/v1.79.tar.gz

RUN tar xvz -C /usr/src -f /usr/src/v1.79.tar.gz
RUN cd /usr/src/s3fs-fuse-1.79 && ./autogen.sh && ./configure --prefix=/usr && make && make install

# Set environment variable
ENV	APP_DIR /app

ADD nginx_nginx.conf /etc/nginx/nginx.conf

ADD	php_www.conf /etc/php-fpm.d/www.conf
RUN	sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php.ini

RUN	mkdir -p /app


ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME



ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.28
ENV TOMCAT_TGZ_URL https://raw.githubusercontent.com/szmolin/dist/master/tomcat/apache-tomcat-8.0.28.tar.gz

RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz*
RUN rm -Rf /usr/local/tomcat/webapps/* && mkdir -p /usr/local/tomcat/internal /usr/local/tomcat/external&& mkdir -p /usr/local/tomcat/internal /usr/local/tomcat/external
ADD server.xml /usr/local/tomcat/conf/server.xml
ADD context.xml /usr/local/tomcat/conf/context.xml
ADD	supervisor_nginx.conf /etc/supervisor.conf.d/nginx.conf
ADD	supervisor_php-fpm.conf /etc/supervisor.conf.d/php-fpm.conf
ADD	supervisor_tomcat.conf /etc/supervisor.conf.d/tomcat.conf
EXPOSE 8080 9999
ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
