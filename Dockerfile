# WordPress with ThemeIsle Development Environment
# Docker Hub: https://hub.docker.com/r/hardeepasrani/pirate-brewery/
# Github Repo: https://github.com/HardeepAsrani/pirate-brewery/

# Use WordPress as the base image
FROM wordpress:latest

# Copy wp-su.sh
COPY wp-su.sh /bin/wp

# Copy publish.sh
COPY publish.sh /bin/publish

# Copy entrypoint
COPY docker-pirate-entrypoint.sh /usr/local/bin/

# Copy Vim Config
COPY vim_config.txt /vim_config.txt

# Setup ThemeIsle Development Environment
RUN apt-get update \
	# Install required packages
	&& apt-get install -y --no-install-recommends sudo less wget default-mysql-client gnupg gnupg2 gnupg1 git subversion nano unzip vim \
	# Configure Vim
	&& git clone https://github.com/amix/vimrc.git ~/.vim_runtime \
	&& sh ~/.vim_runtime/install_awesome_vimrc.sh \
	&& mv /vim_config.txt ~/.vim_runtime/my_configs.vim \
	# Install Xdebug
	&& pecl install xdebug && docker-php-ext-enable xdebug \
	# Install WP-CLI
	&& curl -o /bin/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /bin/wp-cli.phar /bin/wp /bin/publish \
	# Install Node and npm
	&& curl -sL https://deb.nodesource.com/setup_11.x | bash - \
	&& apt-get install -y nodejs \
	# Install PHP CodeSniffer
	&& pear install PHP_CodeSniffer \
	# Install WordPress Codeing Standards
	&& git clone https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git wpcs \
	&& mv wpcs /bin/wpcs \
	&& phpcs --config-set installed_paths /bin/wpcs/ \
	&& pear upgrade PHP_CodeSniffer \
	# Install Grunt and GruntCLI
	&& npm install -g grunt grunt-cli \
	# Install Composer
	&& php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
	&& php composer-setup.php \
	&& php -r "unlink('composer-setup.php');" \
	&& mv /var/www/html/composer.phar /bin/composer \
	# Install PHPUnit
	&& wget https://phar.phpunit.de/phpunit-6.5.phar \
	&& chmod +x phpunit-6.5.phar \
	&& mv phpunit-6.5.phar /bin/phpunit \
	# Checkout WordPress' PHP Unit Files
	&& mkdir /tmp/wordpress-tests-lib/ \
	&& svn checkout https://develop.svn.wordpress.org/trunk/tests/phpunit/includes/ /tmp/wordpress-tests-lib/includes/ \
	&& svn checkout https://develop.svn.wordpress.org/trunk/tests/phpunit/data/ /tmp/wordpress-tests-lib/data/ \
	&& curl -O https://develop.svn.wordpress.org/trunk/wp-tests-config-sample.php  \
	&& mv wp-tests-config-sample.php /tmp/wordpress-tests-lib/wp-tests-config-sample.php \
	# Configure ngrok
	&& curl -O https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip \
	&& unzip ngrok-stable-linux-amd64.zip \
	&& mv ngrok /bin/ngrok \
	&& rm ngrok-stable-linux-amd64.zip \
	# Remove unuseable packages
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/pear /var/tmp/*

# Setup Entrypoint
ENTRYPOINT [ "docker-pirate-entrypoint.sh" ]

# Start Apache Process
CMD [ "apache2-foreground" ]
