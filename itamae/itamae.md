# Apresentando: Itamae


![Itamae](images/logo_2.png)

Itamae é um projeto open-source baseado no Chef, disponibilizado no Github: https://github.com/itamae-kitchen/itamae. Há mais ou menos um ano e meio atrás, fui apresentado ao Itamae uma ferramenta para gestão e configuração de ambientes (<i>configuration management tool</i>) uma ferramenta poderosa se combinado com sua criativade. E naquela época não demonstrei nenhum interesse em sua utilização, porém surguiu uma motiviação, devido uma demanda na qual necessitava de recriar um ambiente de forma automatizada, com consistencia e de execução simples. Como estava buscando alternativas o Itame resurgiu em minha mente e em poucos passos consegui evoluir utilizando o Itamae.


Com ele podemos garantir arquivos, aplicações e outras coisas, que queremos que nosso servidor, mantendo sempre rodando "aquela" aplicação e com "aquele" arquivo de configuração.


Nesse post quero apresentar o Itame, dando-lhes uma visão geral do seu funcionamento. Vamos lá:

Primeiramente, tenha o ruby instalado e execute o comando abaixo:

`$gem install itamae`

Após instalar, chegou a hora de criar as receitas, com elas vamos definir como será a configuração de nosso host.

`$vi minha_receita.rb`

Na documentação do Itamae no github (https://github.com/itamae-kitchen/itamae/wiki) temos às estruturas das funções que o Itamae implementa.

Costumo sempre iniciar pelos pacotes necessários para à serem mantidos no servidor, ou seja pelas depêndencias necessárias ao projeto, como usuários,pacotes e serviços. No exemplo abaixo estou especificando algumas variaveis que será utilizado na receita, e será criado um usuário e seu respectivo grupo.




```
## Variables
$container_name = "jenkins"
$user = "alguem"
$grupo = "alguem"



#Cria o grupo e o usuário no servidor
group "#{$grupo}" do
  action :create
  groupname "#{$grupo}"
end

user "#{$user}" do
  action      :create
  username    "#{$user}"
  gid         "#{$grupo}"
  home        "/home/#{$user}"
  password    "$6$PvKiKK/6$jL0Ffp7NWjlUiwIGLqW4EYLVg8vDI41FJPvOPZuSyXE/fCDBIbhPSdqJqBUulHqsgZOeciahTU1Ww31o1f56U1"
  system_user true
  shell       "/bin/bash"
  create_home true
end

directory "/home/#{$user}/.ssh" do
  action :create
  mode   "755"
  owner   "#{$user}"
  group   "#{$grupo}"
end

execute "Add sudoers" do
  command "echo '#{$user} ALL=NOPASSWD: ALL' >> /etc/sudoers"
  not_if "cat /etc/sudoers |grep #{$user}"
end

```

Um outro bloco de comando bastante util é o <i>execute ... do ... end </i>. Pois com ele podemos executar comandos shell caso necessário. No exemplo abaixo utilizo ele para adicionar o repositorio oficial do docker no servidor.

```
#Instala o pacote do Git no servidor.
package 'git' do
  action :install
end


execute "Adicionar chaves e repo-docker | ubuntu-trusty" do
  command "apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' | tee /etc/apt/sources.list.d/docker.list && apt-get update"
  not_if "test -e /etc/apt/sources.list.d/docker.list"
  only_if "cat /etc/issue |grep 'Ubuntu 14.04'" #Somente para ubuntu-trusty 14.04
end

```

Uma grande sacada do Itamae é ele possuir em alguns do seu blocos os campos <i>not_if</i> e <i>only_if</i>, no exemplo acima ele não irá  executar o bloco caso o comando no campo <i>not_if</i> retornar sucesso. E o campo <i>only_if</i> irá garantir que ele execute somente na versão do Ubuntu 14.04.


Os blocos a seguir instala o Docker e manter o serviço ativo e em execução.

```
package 'docker-engine' do
  action :install
end


# Keep service docker running
service 'docker' do
  action [:enable, :start]
end
```
Para arquivos o Itamae possui dois blocos na qual podemos trabalhar, o <i>remote_file</i> e o <i>file</i>. A diferença entre eles é que o <i>remote_file</i> espera um arquivo fonte que se encontra no mesmo diretório que nosso arquivo de receita. E o <i>file</i> é criado/autalizado com base no campo <i>content</i>


```
#Bloco de diretório
directory "/cs-temp" do
  action :create
  mode   "755"
end

directory "/#{$container_name}" do
  action :create
  mode   "755"
end

#Arquivo remoto
remote_file "/cs-temp/update_sdk.sh" do
  action  :create
  path    "/cs-temp/update_sdk.sh"
  source  "jenkins/update_sdk.sh"
end

#Arquivo cirado/atualizado em tempo de execução.
file "/#{$container_name}/.ssh/id_rsa.pub" do
  action :create
  path    "/#{$container_name}/.ssh/id_rsa.pub"
  content "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCldjCpdcS4u5nlaRWGEIcImOKQMoBN5qMs5JmpCQAHrDDd+h50JcxQWoih5GN18xV9dOZzOafKZVG0CRo7MVs/l0AnkyBBpWfj0MnnXLdZjt3cj65kfGVaZOU6E3b1QDzF9rd+eJjoyNu1sw/qDnbeXm5PjWEyKki9YilIEXzAweH+xXzOAS8Wh1vypQi+T7jiTD8b4U36XlE+KYEb0xpxGfgP+ReEFAD+Sfr41n2bahFcRVWIC9HbvRIq9WXC+1x2J8GLEMvPIKywNDZg18y9q3Tg/33VbRCmZGKAh3pwaDLipwdivWZG1jDmudLw0pYFDoIxl224ZAVdnFnXL2yv jenkins$e3b1ac9aa924"
  mode    "644"
  owner   "#{$user}"
  group   "#{$grupo}"
end

```



No bloco de diretório irá garantir que o diretorio /cs-temp será criado com à permissão 755. No bloco de arquivo remoto que o arquivo update_sdk.sh será entregue no <i>path</i> /cs-temp/update_sdk.sh, note que o source do arquivo é outro <i>path</i> que está na minha máquina local.

Uffa, muita coisa? está quase terminando, resumindo o que entregamos até o momento:

- Dependencias
- Serviços
- Diretórios
- Arquivos


Falta colocar para rodar nossa aplicação, que será um container basico do Jenkins. Neste caso vou voltar a utilizar o bloco execute.

```
execute "Run a Docker Container Jenkins" do
  action :run
  command "docker rm -f $(docker ps -qa) 2> /dev/null || docker run -d --restart=always --name #{$container_name} -p 9090:8080 -p 50000:50000 -v /#{$container_name}:/var/jenkins_home #{$container_name}:latest"
  only_if "docker images |grep #{$container_name}"
  not_if  "docker ps |grep #{$container_name}"
end
```

Agora vamos executar nossa receita no servidor, podendo ser ele remoto ou localmente. Com os comandos abaixo:

``$ itamae ssh -i /home/user/.ssh/user-key -u user -h host minha_receita.rb --log-level=DEBUG``

Ou localmente

`` $ itamae local minha_receita.rb --log-level=DEBUG``


Ao utulizar o parâmetro --log-leval=DEBUG o Itamae irá mostrar todos o passos que ele executa.

Após a execução será possivel acessar e conferir nossa aplciação.




O Itamae é uma ferramenta bastante poderosa e cumpre sua missão de ser leve e eficaz na automação de ambientes. Existe bastante funções que você poderá utilizar e extrair o máximo do Itamae.



Quero agradecer ao nosso time de DevOps que sempre nos motivou a escrever este post, também quero também deixar um abraço ao antigo colega de trabalho Fábio Ornellas que me apresentou o Itamae.


E também gostaria de opniões, sugestões de melhorias, pois esse é meu primeiro post!!!!  :D
