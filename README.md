# dockerpress

Aprenda a Instalar e Configurar um Ambiente Docker exclusivo para WordPress com as ferramentas mais poderosas da atualidade.

Sem acesso ao SSH, não é necessário conhecimento de infra e funciona nos principais provedores: Digital Ocean, Linode, Vultr e AWS Lightsail.

Instale várias instâncias do Wordpress no mesmo servidor com SSL nota A+ e Proxy Reverso.

[Ainda não domina o Docker? Faça o Curso Setup  Configuração do Wordpress com Dockere](https://www.udemy.com/setup-e-configuracao-do-wordpress-com-docker/?couponCode=GITHUB) no Udemy.

## Variáveis de Ambiente

| ENV | Value |
| --- | --- |
| WORDPRESS_DB_HOST |	0.0.0.0 |
| WORDPRESS_DB_NAME	| DB_NAME |
| WORDPRESS_DB_PASSWORD |	YOURSECRET |
| WORDPRESS_DB_USER	| root |
| WP_REDIS_DATABASE |	1 |
| WP_REDIS_PORT	| 6379 |
| WP_REDIS_HOST	| 0.0.0.0 |
