# DockerPress

O DockerPress é uma suíte de serviços que permitem Configurar um Ambiente Docker exclusivo para WordPress com as ferramentas mais poderosas da atualidade.

**Sem acesso ao SSH**, não é necessário conhecimento de infra e funciona nos principais provedores: **Digital Ocean**, **Linode**, **Vultr** e **AWS Lightsail**.

- Acompanhe o DockerPress em [https://hub.docker.com/r/luizeof/dockerpress](https://hub.docker.com/r/luizeof/dockerpress).

## Variáveis de Ambiente

Utilize os valores abaixo para configurar sua instalação do Wordpress.

#### Configurações do Mysql
| ENV | Padrão | Obrigatório | Descrição |
| --- | --- | --- | --- |
| WORDPRESS_DB_HOST |  | Sim | IP ou Host do MySQL |
| WORDPRESS_DB_NAME	|  | Sim | Nome do Banco de Dados |
| WORDPRESS_DB_PASSWORD |	 | Sim | Senha do MySQL |
| WORDPRESS_DB_USER	|  | Sim | Usuário do MySQL |

#### Configurações do  Redis
| ENV | Padrão | Obrigatório | Descrição |
| --- | --- | --- | --- |
| WP_REDIS_DATABASE |	1 | Não | ID do Banco de Dados Redis |
| WP_REDIS_PORT	| 6379 | Não | Porta do Servidor Redis |
| WP_REDIS_HOST	|  | Não | IP do Servidor Redis |
