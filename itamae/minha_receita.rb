## Variables
$container_name = "jenkins"
$user = "alguem"
$grupo = "alguem"

#Cria grupo e usuário.

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

execute "Add ao sudoers" do
  command "echo '#{$user} ALL=NOPASSWD: ALL' >> /etc/sudoers"
  not_if "cat /etc/sudoers |grep #{$user}"
end

#Instala o pacote do Git no servidor.
package 'git' do
  action :install
end

#Adiciona repositori oficial do docker

execute "Adicionar chaves e repo-docker | ubuntu-xenial" do
  command "apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' | tee /etc/apt/sources.list.d/docker.list && apt-get update"
  not_if "test -e /etc/apt/sources.list.d/docker.list"
  only_if "cat /etc/issue |grep 'Ubuntu 16.04'"
end


package 'docker-engine' do
  action :install
end


# Keep service docker running
service 'docker' do
  action [:enable, :start]
end

#Bloco de diretório
directory "/cs-temp" do
  action :create
  mode   "755"
end

directory "/#{$container_name}" do
  action :create
  mode   "777"
end

#Arquivo remoto
remote_file "/cs-temp/update_sdk.sh" do
  action  :create
  path    "/cs-temp/update_sdk.sh"
  source  "jenkins/update_sdk.sh"
end
directory "/#{$container_name}/.ssh" do
  action :create
  mode   "775"
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

execute "Pull Docker Images Jenkins" do
  action :run
  command "docker pull #{$container_name}"
  not_if  "docker ps |grep #{$container_name}"
end

execute "Run a Docker Container Jenkins" do
  action :run
  command "docker rm -f $(docker ps -qa) 2> /dev/null || docker run -d --restart=always --name #{$container_name} -p 9090:8080 -p 50000:50000 -v /#{$container_name}:/var/jenkins_home #{$container_name}:latest"
  only_if "docker images |grep #{$container_name}"
  not_if  "docker ps |grep #{$container_name}"
end
