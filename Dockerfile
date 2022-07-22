FROM centos:7

RUN set -ex; \
echo "# install php(php53) & nginx"; \
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
yum install -y epel-release; yum update -y; \
yum install -y gcc autoconf wget curl nginx libxml2-devel libcurl-devel libjpeg-turbo-devel libpng-devel freetype-devel openssl-devel gmp-devel; \
mkdir /tmp/build; \
wget https://www.php.net/distributions/php-5.3.27.tar.gz; \
tar -xf php-5.3.27.tar.gz; cd php-5.3.27; \
./configure --prefix=/usr --sysconfdir=/etc --with-config-file-path=/etc --localstatedir=/var \
            --with-iconv --with-jpeg-dir --with-png-dir --with-freetype-dir \
            --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-xmlrpc \
            --with-curl --with-curlwrappers --with-gd --with-openssl --with-mhash --with-gmp \
            --enable-xml --enable-bcmath --enable-shmop --enable-gd-native-ttf \
            --enable-sysvsem --enable-sockets --enable-zip --enable-soap \
            --enable-mbstring --enable-pcntl --enable-fpm; \
make && make install; \
cp ./php.ini-production /etc/php.ini; \
cp ./sapi/fpm/php-fpm.conf /etc/php-fpm.conf; \
cd /tmp/build; \
wget https://getcomposer.org/download/latest-1.x/composer.phar; mv composer.phar /usr/bin/composer; \
chmod +x /usr/bin/composer; \
cd /tmp/build; wget https://github.com/redis/hiredis/archive/v0.13.3.tar.gz -O hiredis-v0.13.3.tar.gz; \
tar -xf hiredis-v0.13.3.tar.gz; cd hiredis-0.13.3; make && make install; \
cd /tmp/build; wget https://github.com/nrk/phpiredis/archive/v1.0.0.tar.gz -O phpiredis-v1.0.0.tar.gz; \
tar -xf phpiredis-v1.0.0.tar.gz; cd phpiredis-1.0.0; phpize; ./configure --enable-phpiredis; make && make install; \
echo 'extension=phpiredis.so' >> /etc/php.ini; \
printf "\n" | pecl install apc; \
echo 'extension=apc.so' >> /etc/php.ini; \
echo "# config php & nginx"; \
sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/g' /etc/php.ini; \
sed -i 's/;daemonize = yes/daemonize = no/g' /etc/php-fpm.conf; \
sed -i 's/user = nobody/user = nginx/g' /etc/php-fpm.conf; \
sed -i 's/group = nobody/group = nginx/g' /etc/php-fpm.conf; \
sed -i 's/listen = 127.0.0.1\:9000/listen = \/tmp\/php-fpm.sock/g' /etc/php-fpm.conf; \
sed -i 's/listen.allowed_clients = /;listen.allowed_clients = /g' /etc/php-fpm.conf; \
sed -i 's/#tcp_nopush/client_max_body_size 2048M;\n\t#tcp_nopush/' /etc/nginx/nginx.conf; \
touch /var/log/php-fpm.log; \
chown nginx:nginx /var/log/php-fpm.log; \
echo 'server { include /srv/*_nginx.conf; }' > /etc/nginx/conf.d/default.conf; \
echo "# start nginx and php service"; \
cd /tmp/build; \
wget -O /usr/bin/phpunit https://phar.phpunit.de/phpunit-4.phar; \
chmod +x /usr/bin/phpunit; \
wget https://cr.yp.to/daemontools/daemontools-0.76.tar.gz; \
tar -xf daemontools-0.76.tar.gz; cd admin/daemontools-0.76; \
sed -i 's/gcc/gcc -include \/usr\/include\/errno.h/g' src/conf-cc; \
./package/install; \
cp command/* /usr/bin/; \
mkdir /etc/service; \
mkdir /opt/service_nginx; \
mkdir /opt/service_php-fpm; \
echo -e '#!/bin/bash\n\nexec nginx -g "daemon off;" >> /var/log/nginx/run.log 2>&1' > /opt/service_nginx/run; \
chmod +x /opt/service_nginx/run; \
echo -e '#!/bin/bash\n\nexec setuidgid nginx php-fpm >> /var/log/php-fpm_run.log 2>&1' > /opt/service_php-fpm/run; \
chmod +x /opt/service_php-fpm/run; \
ln -s /opt/service_nginx /etc/service/nginx; \
ln -s /opt/service_php-fpm /etc/service/php-fpm; \
echo "# clean"; \
rm -rf /tmp/build; \
yum remove -y wget gcc

WORKDIR /srv

EXPOSE 80

ENTRYPOINT [ "svscan", "/etc/service" ]
