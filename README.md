# DockerPress

**DockerPress** is a set of services that allows you to configure an exclusive Docker environment for WordPress with the most powerful tools like **OpenliteSpeed**, **Redis**, **Traefik** and **MySQL 8**.

The official DockerPress image can be accessed at [https://hub.docker.com/r/luizeof/dockerpress](https://hub.docker.com/r/luizeof/dockerpress).

## Environment Variables

Use the values below to configure your WordPress installation.

### Database Settings

| ENV                   | Default Value | Required | Description    |
| --------------------- | ------------- | -------- | -------------- |
| WORDPRESS_DB_HOST     |               | Sim      | MySQL Host     |
| WORDPRESS_DB_PORT     | 3306          | Sim      | MySQL Port     |
| WORDPRESS_DB_NAME     |               | Sim      | Database Name  |
| WORDPRESS_DB_PASSWORD |               | Sim      | MySQL Password |
| WORDPRESS_DB_USER     |               | Sim      | MySQL Username |

### General Settings

| ENV          | Default Value | Required | Description                                                                    |
| ------------ | ------------- | -------- | ------------------------------------------------------------------------------ |
| VIRTUAL_HOST |               | Sim      | Website Domain                                                                 |
| ADMIN_EMAIL  |               | No       | Wordpress Admin E-mail                                                         |
| WP_LOCALE    | en_US         | Sim      | Wordpress Locale ([Available Locales](https://translate.wordpress.org/stats/)) |

## Container Volume

By default, DockerPress uses a single volume that must be mapped to `/var/www/html`. The entire WordPress installation is stored in this path.
