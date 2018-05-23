FROM phusion/baseimage:0.10.1

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

ENV HOME /root

ENV NGINX_VERSION 1.14.0
ENV PHP_VERSION 7.0.30

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

# Add Repositories tp apt list
RUN add-apt-repository -y ppa:nginx/stable

# Fix apt-get update super slow issue
RUN printf "net.ipv6.conf.all.disable_ipv6 = 1 \n net.ipv6.conf.default.disable_ipv6 = 1 \n net.ipv6.conf.lo.disable_ipv6 = 1 \n" >> /etc/sysctl.conf

# Update before install
RUN apt-get update

# PHP Installation
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y vim curl wget build-essential nano python-software-properties zip
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y php7.0-cli php7.0-fpm php7.0-mysql php7.0-pgsql php7.0-sqlite php7.0-curl\
               php7.0-gd php7.0-mcrypt php7.0-intl php7.0-imap php7.0-tidy php7.0-mbstring php7.0-dom


# NGINX Installtion
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx

# NGINX CONFIGURATION
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# GiT installation
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y git

# Composer Installtion
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/usr/local/bin
RUN php -r "unlink('composer-setup.php');"

# Creating directories
RUN mkdir -p            /var/www/live

# October Installation
RUN git clone https://github.com/octobercms/october.git /var/www/live/october

RUN cd /var/www/live/october && \
php /usr/local/bin/composer.phar install

# Remove the default configuration

# Add custom nginx configurations
ADD conf/php-backend.conf    /etc/nginx/conf.d/php-backend.conf
ADD conf/october.conf        /etc/nginx/sites-available/october.conf

RUN mkdir               /etc/service/nginx
ADD scripts/nginx.sh    /etc/service/nginx/run

RUN chmod +x            /etc/service/nginx/run
RUN mkdir               /etc/service/phpfpm
ADD scripts/phpfpm.sh   /etc/service/phpfpm/run
RUN chmod +x            /etc/service/phpfpm/run

EXPOSE 80

# Tidy up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*