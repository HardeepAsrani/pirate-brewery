# Pirate Brewery: WordPress with ThemeIsle Development Environment

This repository contains the Dockerfile for the autobuild of [pirate-brewery](https://hub.docker.com/r/hardeepasrani/pirate-brewery/) Docker image.

The Dockerfile uses the official WordPress image that adds:

- WP-CLI
- NodeJS & npm
- PHP CodeSniffer with WordPress Coding Standards
- grunt and grunt-cli
- Composer
- PHPUnit with WordPress Unti Tests

To use, simply run:

```
docker run --name <containername> hardeepasrani/pirate-brewery
```

Setting up the image is same as official WordPress image with only on additional variable. You need to provide *WORDPRESS_DB_ROOT_PASSWORD* environment variable which will be same as *MYSQL_ROOT_PASSWORD*.

For all other configuration items, please see the official Docker WordPress [ReadMe](https://github.com/docker-library/docs/tree/master/wordpress).

If you want to use it with docker-compose, you can use this *docker-compose.yml* as sample:

```
version: '3.3'

services:
  mysql:
    image: mysql:5.7
    volumes:
      - ./db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: wordpress
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress

  wordpress:
    depends_on:
      - mysql
    image: hardeepasrani/pirate-brewery
    ports:
      - 8888:80
    volumes:
       - ./wp-content:/var/www/html/wp-content/
    restart: always
    environment:
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_ROOT_PASSWORD: wordpress
```

If you have any questions or want to report an issue, please do it on [GitHub](https://github.com/HardeepAsrani/pirate-brewery/).