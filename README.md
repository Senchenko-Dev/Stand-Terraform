# 1. Создайте свой проект в Bitbucket
```
Create repository
```
# 2. Сделать git clone repo
```
git clone https://dzo.sw.sbc.space/bitbucket-ci/scm/insteip/terra_project_prepare_supermaster.git
```
# 3. Переименовать папку с проектом
```
mv старое_имя  новое_имя
cd новое_имя
git remote set-url origin http://ссылка_на_созданный_репозитрой
git push -u origin --all
git push origin --tags
```
# 4. Настроить WebHooks
```
Выбрать в настройках Git:
а) Opened
b) Source branch update
c) Merge
```
# 5. Create Branch
```
Создать ветку для того чтобы можно было сделать Pull Request
из созданной ветки в ветку Master
```

# 6. Создание и Настройка Job'ы

#### Создание Job'ы:
```
  а) New Item -> Создать задачу со свободной конфигурацией
```

#### Настройка Job'ы:
```
  Отмечаем галочкой:
  a) Do not allow concurrent builds
  b) Prepare an environment for the run
     * Keep Jenkins Environment Variables
     * Keep Jenkins Build Variables
     * Properties Content  
       Копируме и вставляем:
          #NODE=sbt-pd10-r4c-ci-1
          NODE=spinnaker-testing
          COLLECTIVE_TERRAFORM_WORKSPACE=senchenko
          TERRAFORM_PG_REMOTE_CONN_STR="10.42.4.126/terraform_backend?sslmode=disable"
  с) Use Groovy Sandbox
  d) Build with BitBucket Push and Pull Request Plugin
     * Bitbucket Server Pull Request
       Select an Action:
       в выпадающем списке выбираем: Created
       
     * Bitbucket Server Pull Request
       Select an Action:
       в выпадающем списке выбираем: Source Branch of Pull Request Update
       
     * Bitbucket Server Pull Request
       Select an Action:
       в выпадающем списке выбираем: Merged
       
  e) Настраиваем раздел Pipline:
     * Definition:
         в выпадающем списке выбираем: Pipline script from SCM
     * SCM:
         в выпадающем списке выбираем: Git
     * Repositories:
         Repository URL: Ссылка на наш репозиторий
       Credentials:
         Выбираем кред
     * Branches to build:
         */Jenkinsfile  
     * Script Path:
         Пишем: checkOrApply.groovy
         
  f) Lightweight checkout         
```

# 7. Файл main.tf
```
После клонирования репозитроя нужно ИЗМЕНИТЬ имя стэнда!
```

```
locals {
  stand_name = "senchenko-test"  //имя стэнда
  network_name = "main_VDC02"

# передается в модуль (затем в провайдер VCD_VM)
  vm_props_default = {
    template_name = "CentOS7_64-bit_custom2"
    catalog_name = "Custom"
    network_type = "org"
    ip_allocation_mode = "POOL"

    network_name = local.network_name
    stand_name = local.stand_name

    ssh_keys_list = local.ssh_keys_list
    guest_properties = local.guest_properties_common
    private_key = local.secrets.private_key
    public_key = local.secrets.public_key
  }

  guest_properties_common = {
    "enablecustomization" : "enabled",
    "rootpassword" : local.secrets.rootpassword,
    "dnsserver" : "10.255.1.3",
    "ansible_auth_pub_key" : local.secrets.public_key # ключ пользователя ansible
  }
  
  
module "Nginx-1" {

# TF module properties
  source = "./modules/nginx"  //путь до папки(модуля) где лежит nginx.tf

# VM properties
  vm_count = 5  //количество машин в группе
  memory = 4096 //объем памяти в МБ
  cpu = 4  //число ядер

  vm_disk_data = [  //список требуемых внешних дисков (типа independent disk) с размером в ГБ и точкой монтирования. Дополнительно указываются права.
   { size: "3G", mnt_dir: "/opt/nginx" , owner: "nginx"},
   { size: "1G", mnt_dir: "/var/log/nginx" , owner: "nginx", group: "nginx", mode: "0755"}
  ]

  vm_props = local.vm_props_default //набор параметров образа виртуальной машины. Настраивается один раз для всех КТС.
  awx_props = local.awx_props //при использовании AWX задаются параметры соединения для создания шаблонов задач обслуживания. При необходимости использовать внешний AWX задать значения параметров local.awx_props явно.

# Ansible properties
  force_ansible_run = "01" // опциональная переменная для принудительного запуска ансибл.
  inventory_group_name = "nginx_ssl" // для связи с group_vars/group_name.yml
  spo_role_name = "nginx"  //опциональная переменная для использования альтернативной роли (например, для тестирования обновленной версии)
}
```

# 8 Делаем изменения в файле main.tf
```
Например:
Изменили в файле main.tf колличество vm_count.
Делаем в нашей среде разработки(ide):
a) Git commit
b) Git push
```

# 9 Create Pull Requset
```
Переходим в Web Ui Bitbucet:
a) Создаем Pull Request
б) выбираем нешу созданную ветку в
   разделе Source и выбираем в разделе
   Destination ветку в котрую надо влить 
   изменения, в ветку Master
```

# 10 Merge
```
После нажатия кнопки continue и create.
срабатывает webhook и запускается job c
нашим commit'ом
```

# 11 Plan
```
а)После работы job'ы
  в Bitbucket мы видим Terrafrom plan
  он показывает каие ресурсы будут создаваться.

б) Жмем кнопку Merge
```

# 12 Console Jenkins
```
Переходим в console Jenkins
в ней мы видим что Job начал работу.
```

