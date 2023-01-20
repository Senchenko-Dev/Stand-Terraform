# Руководство установке Platform V Pangolin

Platform V Pangolin - система управления базами данных, основанная на PostgreSQL. В этом документе описываются аспекты Pangolin, связанные с установкой системы.

Этот документ предназначен для администраторов и специалистов по безопасности, отвечающих за установку и обновление продукта.

## Системные требования

Для установки Platform V Pangolin на сервер на базе Linux потребуются:

- Ansible не ниже версии 2.9.2 
- sshpass 
- Модули Python: 
    
    - jmespath версии 0.9.4
    - netaddr версии 0.7.19
    - PyYAML версии 5.3

## Установка

### Варианты развертывания

Pangolin поддерживает несколько вариантов развертывания с использованием разных сочетаний компонентов.

Компоненты, используемые в разных сценариях развертывания:

**Patroni** - это демон на Python, позволяющий автоматически обслуживать кластеры PostgreSQL с различными типами репликации.

**Etcd** - высоконадёжное распределённое хранилище параметров конфигурации, задаваемых в форме ключ/значение.

**Pgbouncer** - мультиплексоры соединений (программы для создания пула соединений), позволяют уменьшить накладные расходы на базу данных в случае, когда огромное количество физических соединений ведет к падению производительности PostgreSQL.

**confd** - легковесный менеджер конфигураций, проверяющий хранилище параметров конфигураций и изменяющий конфигурационные файлы в зависимости от изменения ключа.

**haproxy** - серверное программное обеспечение для обеспечения высокой доступности и балансировки нагрузки для TCP и HTTP-приложений.

В таблице представлена компиляция результатов тестирования различных конфигураций кластера на соответствие следующему набору требований:

Функциональные требования (RTO = 6 минут, RPO = 0)
Нефункциональные требования (10000 tps1, Объем БД = 10 ТБ2, 2500 одновременных активных подключений, установка 100 новых подключений в секунду)

| Варианты конфигураций   | Преимущества | Ограничения |
|---------|--------------------|------|
| Pangolin <br />+ pgBouncer <br />(открытие - версия 4.2.5) | Схема Pangolin для АС, где не требуется соответствие заявленным нефункциональным требованиям (RTO = 6 минут, RPO = 0). Также возможно прерывание предоставляемого сервиса.<br /><br />Исключена возможная проблема с ПО арбитража, возникающая на виртуальных средах ДЕВ/ИФТ/ПСИ | **Ограничения:**<br />Не соответствует заявленным нефункциональным требованиям. |
| Patroni <br />+ Etcd <br />+ Pgbouncer, <br />standalone | Схема кластера, используемая для тестовых сред, ввиду отдельного решения архитектурного совета запрещающая к использованию кластерного решения вне ПРОМ сред. <br /><br /> Позволяет функционально проверить, что кластерная конфигурация подходит для использования в рамках АС, а также получить опыт экплуатации |**Ограничения:**<br />Не соответствует заявленным нефункциональным требованиям <br /><br />**Недостатки:** <br />Проблема с ПО арбитража, что может привести к переводу БД в режим Read-only. Проблема подтверждена для сред ДЕВ/ИФТ/ПСИ на виртуальных серверах вследствие использования opensource решения для виртуализации, которое не может обеспечить квотирование ресурсов сервера. На средах НТ/ПРОМ проблема исключена. |
| Patroni <br />+ Etcd <br />+ Pgbouncer | Обеспечивается возможность достижения RTO = 6, но практическое подтверждение возможно по результатам длительной эксплуатации <br />RPO = 0 выполняется кроме случая, описанного в недостатках решения<br />Простая в конфигурировании и эксплуатации схема с минимумом потребляемых ресурсов сервера. <br />Patroni имеет внешний интерфейс для управления состоянием кластера и единую точку конфигурирования всех серверов БД, входящих в кластер <br />Несмотря на добавление в конфигурацию дополнительного сервиса, схема остается простой для установки и настройки - pgbouncer имеет единый файл для конфигурирования и обладает простым синтаксисом настроек <br />Позволяет гибко управлять настройками пулов соединений<br />Pgbouncer обеспечивает количество соединений большее, чем сконфигурировано в БД Pgbouncer, позволяет обеспечить стабильную скорость обработки транзакций даже в случае превышения лимита возможных одновременных подключений к БД, согласно конфигурации<br />В pgbouncer можно реализовать автоматическое перенаправление трафика к новому ведущему сервера на основе информации из Etcd <br /><br />**Рекомендация:** использование схемы с pgbouncer имеет смысл, когда планируемое максимальное количество подключений max_connections превышает число, рассчитанное по формуле 3хCPU (включая виртуальные (hyperthreading) ядра. Например, для типовой конфигурации промышленного сервера (28 CPU) рекомендованное число подключений на уровне БД - 84, если требуется больше, следует использовать PgBouncer5 | **Ограничения:**<br />RPO = 0 обеспечивается только в случае использования синхронной репликации и наличия механизма обработки timeout на стороне клиентского предложения, в случае следующих обнаруженных недостатков:<br />RPO=0 не выполняется при использовании асинхронной репликации возможно возникновение ситуации "split brain".<br />При использовании асинхронной репликации с pg_rewind возможны расхождения в данных между ведущей и ведомой нодой.<br />При использовании синхронной репликации c включенным pg_rewind необходима обработка timeout на стороне клиента, так как запросы не будут завершаться до получения ответа от ведомого сервера. <br />При использовании синхронной репликации с отключенным pg_rewind данные, полученные до переключения кластера на новый мастер, останутся только на "старом" мастере. <br />Необходимо использовать измененную строку подключения на стороне АС для того, чтобы отправлять все запросы на ведущий сервер кластера, пример для JDBC jdbc://postgresql:127.0.0.1:6544,127.0.0.2:6544/dbname?targetServerType=master&prepareThreshold=0 <br />Клиентское приложение должно уметь работать с БД в режиме транзакций в соответствии с рекомендуемыми настройками pgbouncer <br /><br />**Недостатки:**<br />RPO = 0 не обеспечивается, возможно возникновение ситуации Split Brain<br />Использование PgBouncer при небольшом числе соединений не несет никакого выигрыша и приводит только к незначительному росту накладных расходов <br />В кластере происходит снижение скорости в среднем на 30% из-за накладных расходов на инфраструктуру - etcd, Patroni и др.|
| Patroni <br />+ Etcd <br />+ Pgbouncer <br />+ Haproxy | Те же, что и для **Patroni + Etcd + Pgbouncer**. <br />Обеспечивает возможность реализовать различные стратегии балансировки трафика между нодами кластера, в том числе балансировку уровня БД; к примеру, балансировку запросов чтения между всеми ведомыми нодами с учетом времени отставания ведомой ноды.<br />HAProxy обладает обширной документацией и возможностью настройки. <br />Возможность организовать автоматический обрыв соединений в случае смены ролей в кластере| **Ограничения:**<br />В специфическом случае падения HAProxy на ноде с ведущим сервером все запросы пойдут через Haproxy ведомого сервера, что может привести к увеличению сетевых задержек <br />Настройка алгоритма балансировки может потребовать понимания работы сетевых протоколов и знания SLA сетевой доступности между ЦОДами. Возможно, потребуется корректировка алгоритма постфактум, на основе логов работы в реальном окружении  <br />Клиенты должны будут реализовать функциональность переподключения к кластеру и повторной отправки запросов <br /><br />**Недостатки:** <br />В кластере происходит снижение скорости в среднем на 30% из-за накладных расходов на инфраструктуру - etcd, Patroni и др.<br />Использование PgBouncer при небольшом числе соединений не несет никакого выигрыша и приводит только к росту накладных расходов и, как следствие, падению скорости обработки запросов  |
| Patroni <br />+ Etcd <br />+ pgbouncer <br />+ Балансировщик нагрузки | Те же, что и для **Patroni + Etcd + Pgbouncer**. <br />Предоставляет единую точку входа для клиентских соединений. <br />RPO = 0 выполняется, так как балансировщик автоматически перенаправит трафик от клиентов на ведущий сервер в соответствии с разработанной стратегией <br />Балансировщики нагрузки промышленных стендов размещаются в соответствии с принципами георезервирования. <br />Наличие команды поддержки БН. <br />Позволяет реализовать большинство стратегий уровня L3/L7, кроме стратегий прикладного уровня; например, балансировку трафика с учетом информации от БД <br />Рекомендация: использование схемы с pgbouncer имеет смысл, когда планируемое максимальное количество подключений max_connections превышает число, рассчитанное по формуле 3хCPU (включая виртуальные (hyperthreading) ядра. Например, для типовой конфигурации промышленного сервера (28 CPU) рекомендованное число подключений на уровне БД - 84, если требуется больше, следует использовать PgBouncer |**Ограничения:** <br />Клиентское приложение должно уметь работать с БД в режиме транзакций в соответствии с рекомендуемыми <br />настройками pgbouncer <br />Разработка алгоритма балансировки может потребовать понимания работы сетевых протоколов и знания SLA сетевой доступности между ЦОДами. Возможно, потребуется корректировка алгоритма постфактум, на основе логов работы в реальном окружении <br />Клиенты должны будут реализовать функциональность переподключения к кластеру и повторной отправки запросов. <br />Балансировщик нагрузки является черным ящиком по отношению к потребителям, что может привести к увеличению времени понимания и исправления проблемы с балансированием запросов. <br /><br />**Недостатки:** <br />Дороговизна решения: балансировщик нагрузки хоть и является георезервированным и отказоустойчивым, но при этом имеет высокую стоимость эксплуатации, рекомендуется рассчитать стоимость использования

Дистрибутивы Platform V Pangolin собираются из необходимых компонентов с помощью задач Jenkins, загружаются из дистрибутива Nexus и устанавливаются на серверы на базе Linux.

### Сборка дистрибутива

Для сборки общего дистрибутива Pangolin из частей
(owned-distrib, party-distrib и utilities-distrib) и его публикации в Nexus используется пайплайн `sbercloud_build_distrib_from_parts`.

Ниже описана инструкция по созданию и использованию задач на основе данного пайплана.

### Создание задачи
Чтобы создать задачу, необходима папка в Jenkins, в которой указаны учетные данные вашей технической учетной записи:

- с типом `SSH username with private key`;
- с типом `Username with password`.

В папке Jenkins выполните следующие шаги:

- Нажмите кнопку New item. Откроется страница создания задачи.
- Введите имя задачи и выберите тип `Pipeline`.
- Нажмите кнопку OK. Откроется страница настройки задачи.
- Внизу страницы, в разделе `Pipeline`, в поле `Definition` выберите вариант `Pipeline script from SCM`. Откроется форма настройки репозитория.
- В открывшейся форме укажите адрес текщуего репозитория.
- В поле `Credentials` укажите учетные данные учетной записи с типом `SSH username with private key`.
- В поле `Script path` укажите `sbercloud_build_distrib_from_parts.groovy`.
- Нажмите кнопку `SAVE`.

Задача создана.

### Использование задачи

Задача использует следующие параметры:

Данные Nexus для получения частей owned-distrib, party-distrib и utilities-distrib:

- **NEXUS_REST_API_URL:** адрес API для Nexus
- **NEXUS_REPO_ID:** repoId Nexus
- **NEXUS_GROUP_ID:** groupId Nexus
- **NEXUS_ARTIFACT_ID:** artifactId Nexus
- **version:** version Nexus
- **postgresql_nexus_cred:** данные учетной записи для ТУЗ с правами доступа в Nexus

Данные Nexus для загрузки общего дистрибутива distrib:

- **UPLOAD_NEXUS_REST_API_URL:** адрес API для Nexus
- **UPLOAD_NEXUS_REPO_ID:** repoId Nexus
- **UPLOAD_NEXUS_GROUP_ID:** groupId Nexus
- **UPLOAD_NEXUS_ARTIFACT_ID:** artifactId Nexus
- **upload_version:** version Nexus
- **upload_postgresql_nexus_cred:** credentials для ТУЗа с правами доступа в Nexus на запись

Дополнительно:

- **jenkinsAgentLabel:** метка агента для запуска сценария

После запуска задача выполнит следующие операции:

- выполнит проверку входных переменных;
- загрузит разделенный дистрибутив;
- объединит дистрибутив;
- опубликует объединенный дистрибутив в Nexus.

Теперь вы можете загрузить дистрибутив Platform V Pangolin и установить его на сервер.

### Установка дистрибутива

Установка Platform V Pangolin осуществляется с помощью Ansible:

1.	Распакуйте дистрибутив на сервере Linux c установленным Ansible не ниже версии 2.9.2, установите пакет sshpass и следующие модули Python:

	- jmespath версии 0.9.4
	- netaddr версии 0.7.19
	- PyYAML версии 5.3

2.	Перейдите в каталог с распакованным дистрибутивом, там – в каталог `installer`.
3.	Перед запуском установки заполните файл `hosts.ini` в соответствии с шаблоном и требуемым типом установки (`installer/inventories/cluster/hosts.ini` или `installer/inventories/standalone/hosts.ini`), добавив информацию о хостах и учетных данных пользователя, которые будет использовать Ansible.
Переменная `ansible_password` должна содержать пароль пользователя в чистом виде или же имя переменной, которая будет содержать зашифрованный с помощью `ansible-vault` пароль. 

    Ниже представлены шаблоны файла `hosts.ini` для архитектур standalone и cluster.

    *hosts.ini для standalone*

    ```CODE
    [standalone:children]
    postgres_group

    [postgres_group:children]
    postgres_nodes

    [postgres_group:vars]
    ansible_connection=ssh

    [postgres_nodes]
    master      ansible_host=hostname/ip address   ansible_port=ssh_port_number     ansible_user=логин пользователя     ansible_password=пароль пользователя
    ```

    *hosts.ini для cluster*

    ```CODE
    [cluster:children]
    postgres_group
    etcd_group

    [postgres_group:children]
    postgres_nodes

    [etcd_group:children]
    etcd_nodes

    [postgres_group:vars]
    ansible_connection=ssh

    [etcd_group:vars]
    ansible_connection=ssh

    [postgres_nodes]
    master      ansible_host=hostname/ip address   ansible_port=ssh_port_number     ansible_user=логин пользователя     ansible_password=пароль пользователя
    replica     ansible_host=hostname/ip address    ansible_port=ssh_port_number    ansible_user=логин пользователя     ansible_password=пароль пользователя

    [etcd_nodes]
    etcd        ansible_host=hostname/ip address    ansible_port=ssh_port_number    ansible_user=логин пользователя     ansible_password=пароль пользователя
    ```

    **Важно!** Для корректной установки `ansible_user` должен иметь права для эскалации до root, т.е. должен иметь возможность выполнять все команды от имени root

4.	В случае, если в файле `hosts.ini` переменная `ansible_password` будет содержать `ansible-vault`, то пароль необходимо зашифровать следующей командой на хосте с установленным Ansible:

    ```CODE
    ansible-vault encrypt_string ${шифруемый пароль}
    ```

    В случае, если пароль для хостов групп `postgres_group` и `etcd_group` одинаков, то достаточно вывод команды `ansible-vault` поместить в inventory файл `сluster.yml/standalone.yml`, расположенный в каталоге inventories.
    Аналогичным образом необходимо перешифровать пароли в файле `all.yml` (частично приведен ниже).

    **Важно!** Пароли должны быть зашифрованы одним и тем же секретом. В случае работы с зашифрованным паролем при запуске Ansible необходимо добавить ключ `--ask-vault-pass`.

5. Находясь в каталоге `installer`, запустите `ansible-playbook` нужного типа установки, передавая `vault password postgreSQL_SE_654321` для расшифровки паролей.

### Одиночная установка PostgeSQL без дополнительного программного обеспечения

```Bash
ansible-playbook playbook.yaml -i inventories/standalone/hosts.ini -t always,standalone-postgresql-only --extra-vars "local_distr_path=${путь до дистрибутива} installation_type=standalone customer=${LDAP логин заказчика} db_name=${имя базы данных} schema_name=${имя схемы} PGDATA=${путь до PGDATA} PGLOGS=${путь до PGLOGS} tablespace_name=${имя tablespace} tablespace_location=${полный путь до tablespace} segment=${сегмент сети} stand=${стенд}" -e '{"as_admins":[${LDAP логин/логины админов АС}]}' -e '{"as_TUZ":[${логины/логины ТУЗ}]}' --ask-vault-pass -v
```

### Одиночная установка PostgeSQL с patroni, etcd и pgbouncer

```Bash
ansible-playbook playbook.yaml -i inventories/standalone/hosts.ini -t always,standalone-patroni-etcd-pgbouncer --extra-vars "local_distr_path=${путь до дистрибутива} installation_type=standalone customer=${LDAP логин заказчика} db_name=${имя базы данных} schema_name=${имя схемы} PGDATA=${путь до PGDATA} PGLOGS=${путь до PGLOGS} tablespace_name=${имя tablespace} tablespace_location=${полный путь до tablespace} segment=${сегмент сети} stand=${стенд}" -e '{"as_admins":[${LDAP логин/логины админов АС}]}' -e '{"as_TUZ":[${логины/логины ТУЗ}]}' --ask-vault-pass -v
```

### Кластерная установка PostgeSQL с patroni, etcd и pgbouncer

```Bash
ansible-playbook playbook.yaml -i inventories/cluster/hosts.ini -t always,cluster-patroni-etcd-pgbouncer --extra-vars "local_distr_path=${путь до дистрибутива} installation_type=cluster customer=${LDAP логин заказчика} db_name=${имя базы данных} schema_name=${имя схемы} PGDATA=${путь до PGDATA} PGLOGS=${путь до PGLOGS} tablespace_name=${имя tablespace} tablespace_location=${полный путь до tablespace} segment=${сегмент сети} stand=${стенд}" -e '{"as_admins":[${LDAP логин/логины админов АС}]}' -e '{"as_TUZ":[${логины/логины ТУЗ}]}' --ask-vault-pass -v
```

### Кластерная установка postgeSQL с patroni, etcd, pgbouncer и haproxy

```Bash
ansible-playbook playbook.yaml -i inventories/cluster/hosts.ini -t always,cluster-patroni-etcd-pgbouncer-haproxy --extra-vars "local_distr_path=${путь до дистрибутива} installation_type=cluster customer=${LDAP логин заказчика} db_name=${имя базы данных} schema_name=${имя схемы} PGDATA=${путь до PGDATA} PGLOGS=${путь до PGLOGS} tablespace_name=${имя tablespace} tablespace_location=${полный путь до tablespace} segment=${сегмент сети} stand=${стенд}" -e '{"as_admins":[${LDAP логин/логины админов АС}]}' -e '{"as_TUZ":[${логины/логины ТУЗ}]}' --ask-vault-pass -v
```

### Используемые в представленных выше командах переменные

- ${путь до дистрибутива} - абсолютный путь до загруженного и распакованного дистрибутива Platform V Pangolin
- ${LDAP логин заказчика} - логин Active Directory заказчика.
- ${имя базы данных} - имя базы данных, которая будет создана в результате установки
- ${имя схемы} - имя схемы, которая будет создана в результате установки
- ${путь до PGDATA} - полный путь до каталога, где будет расположена инициализированная база данных
- ${путь до PGLOGS} - полный путь до каталога, где будут расположены логирующие файлы
-   ${имя tablespace} - имя табличного пространства, которое будет создано в результате установки;
- ${полный путь до tablespace} - полный путь до каталога, где будет расположено созданное табличное пространство
- ${сегмент сети} - alpha/sigma
- ${стенд} - dev или prom
- ${LDAP логин/логины админов АС} - Active Directory логин или логины будущих администраторов АС. В зависимости от сети указываются логины sigma или alpha. Если логинов несколько, то они указываются через запятую, без пробелов. Например -e ‘{“as_admins”:[as_admin1,as_admin2,as_admin3]}’
- ${логины/логины ТУЗ} - логины ТУЗ, которые будут созданы в результате установки. Если логинов несколько, то они указываются через запятую, без пробелов. Например -e ‘{“as_TUZ”:[test,test1,test2]}’
Значения используемых в команде запуска Ansible ключей:
- -i - путь до inventory-файла
- --extra-vars - переменные, которые по приоритету важнее переменных из inventory
- -t - теги для запуска
- -v - уровень логирования Ansible. Может быть как пустым, так и -vvvvvv, где запуск без v - минимальное логирование

### Установка и настройка элементов системы

#### HashiCorp Vault

Решение HashiCorp Vault используется в качестве защищенного хранилища ключей шифрования и настроек, а также как система управления ключами.

##### Установка

1. Скачать и распаковать Vault:

    ```Bash
    VAULT_VERSION="1.3.1" #актуальная версия на момент написания инструкции
    curl -O https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip
    unzip vault_${VAULT_VERSION}_linux_amd64.zip
    sudo mv vault /usr/local/bin/
    ```

2. Создать пользователя:

    ```Bash
    sudo useradd --system --home /etc/vault --shell /bin/false vault
    ```

3. Подготовить директории для хранения настроек и данных:

    ```Bash
    sudo mkdir /etc/vault
    sudo mkdir -p /var/lib/vault/data
    ```

4. Создать службу Vault:

    ```bash
    sudo cp vault.service /etc/systemd/system/
    ```

5. Создать конфиг vault:

    ```bash
    sudo cp config.hcl /etc/vault/
    ```

6. Генерация сертификатов для связи с Vault через TLS соединение:

    1.  Подготовка директорий:

        `cd ~/ && mkdir ca && mkdir -p ca/signedcerts && mkdir ca/private && cd ca`

    2.  Создание индексных данных БД:

        `echo '01' > serial && touch index.txt && echo 'unique_subject = yes' > index.txt.attr`

    3.  Создание корневого сертификата/ключа:

        1.  В файле caconfig.cnf (в аттаче) изменить путь до директории "ca" (/home/pprb_dev/nechaev_temp/ca) на свой.
        2.  Выполнить:
            
            ```bash
            export OPENSSL_CONF=~/ca/caconfig.cnf`.
            openssl req -x509 -newkey rsa:2048 -out cacert.pem -outform PEM -days 1825
            ```

        3.  Ввести пароль.
        4. Генерация ключа и запроса на серверный сертификат:

            ```bash
            export OPENSSL_CONF=~/ca/localhost.cnf
            openssl req -newkey rsa:2048 -keyout key.pem -keyform PEM -out req.pem -outform PEM
            ```

        5.  Ввести пароль.
        6.  Расшифровка ключа:

            ```bash
            openssl rsa < key.pem > server_key.pem
            ```
        
        7.  Генерация и подпись серверного сертификата:
            
            ```bash
            export OPENSSL_CONF=~/ca/caconfig.cnf
            openssl ca -in req.pem -out server_crt.pem
            ```
        
        8.  Ввести пароль.
        9.  Копирование ключа, серверного сертификата и корневого сертификата:
            
            ```bash
            sudo cp server_key.pem server_crt.pem cacert.pem /etc/vault/
            sudo chown -R vault:vault /etc/vault /var/lib/vault
            ```

7. Настройка автодополнения команд vault:

    ```bash
    vault -autocomplete-install
    complete -C /usr/local/bin/vault vault
    ```

8. Запуск vault при загрузке системы:

    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable --now vault
    ```

9. Запуск vault:

    ```bash
    sudo systemctl start vault
    ```

10. Инициализация vault:

    ```bash
    sudo -u vault bash -c 'env VAULT_ADDR=https://127.0.0.1:8200 VAULT_CACERT=/etc/vault/cacert.pem /usr/local/bin/vault operator init > /etc/vault/init.file'
    ```

11. Ввести 3 ключа по одному в хранилище Unseal, где s.Ns9St5p0BIaRo2sQ7YYTxjkQ - пример корневого токена (см. cat /etc/vault/init.file):

    ```bash
    sudo -u vault bash -c 'env VAULT_ADDR=https://127.0.0.1:8200 VAULT_TOKEN=s.Ns9St5p0BIaRo2sQ7YYTxjkQ VAULT_CACERT=/etc/vault/cacert.pem /usr/local/bin/vault operator unseal be8fCt4rH3H42viDqQ+Xm6tYaPPsCZMmgQ70QiqD2UGN'
    sudo -u vault bash -c 'env VAULT_ADDR=https://127.0.0.1:8200 VAULT_TOKEN=s.Ns9St5p0BIaRo2sQ7YYTxjkQ VAULT_CACERT=/etc/vault/cacert.pem /usr/local/bin/vault operator unseal ...'
    sudo -u vault bash -c 'env VAULT_ADDR=https://127.0.0.1:8200 VAULT_TOKEN=s.Ns9St5p0BIaRo2sQ7YYTxjkQ VAULT_CACERT=/etc/vault/cacert.pem /usr/local/bin/vault operator unseal ...'
    ```

12. Разрешить аутентификацию по логину/паролю:

    ```bash
    sudo -u vault bash -c 'env VAULT_ADDR=https://127.0.0.1:8200 VAULT_TOKEN=s.Ns9St5p0BIaRo2sQ7YYTxjkQ VAULT_CACERT=/etc/vault/cacert.pem /usr/local/bin/vault auth enable userpass'
    ```

13. Установить логин/пароль:

    ```bash
    sudo -u vault bash -c 'env VAULT_ADDR=https://127.0.0.1:8200 VAULT_TOKEN=s.Ns9St5p0BIaRo2sQ7YYTxjkQ VAULT_CACERT=/etc/vault/cacert.pem /usr/local/bin/vault write auth/userpass/users/adminencryption password=qwerty policies=admins'
    ```

14. Через Web UI создать хранилище KV и разрешить с ним работу:

    1.  https://10.53.67.99:8200, где 10.53.67.99 - IP-адрес сервера, на котором производится настройка vault).
    2.  Для аутентификации использовать корневой токен (в данном примере s.Ns9St5p0BIaRo2sQ7YYTxjkQ).
    3. Выполнить переходы:

        Secrets -> Enable new engine -> KV -> Next -> Enable engine Policies -> default

    4.  Нажать **Edit policy** и добавить в конец:

        ```text
        path "kv/*" {
        capabilities = ["create", "update", "read", "delete", "list"]
        }
        ```

15.  Получить клиентский токен для последующих обращений к Vault:

    ```bash
    curl --insecure --request POST --data '{"password": "qwerty"}' https://127.0.0.1:8200/v1/auth/userpass/login/adminencryption
    ```

    Вывод:

    ```json
    {"request_id":"9afc0f2a-402f-5bc4-c282-ffc604f302a6","lease_id":"","renewable":false,"lease_duration":0,"data":null,"wrap_info":null,"warnings":null,"auth":{"client_token":"s.2C7acCkguAOpD1","policies":["admins","default"],"token_policies":["admins","default"],"metadata":{"username":"adminencryption"},"lease_duration":36000,"renewable":true,"entity_id":"ea854659-6a63-orphan":true}}
    ```

    Впоследующих запросах использовать "client_token":"s.2C7acCkguAOpD1". Например:

    ```bash
    curl --insecure --header "X-Vault-Token:s.2C7acCkguAOpD1" --request GET https://127.0.0.1:8200/v1/kv/data/
    ```

16. Создать файл с параметрами аутентификации для подключения БД к KMS:

    ```bash
    sudo -u postgres bash -c '/usr/local/pgsql/bin/auto_setup_kms_credentials --config_path /opt/postgres_data/enc_connection_settings.cfg --ip 10.53.67.99 --port 8200 --login adminencryption --password qwerty'
    ```

    Предварительно PostgreSQL установлен в `/usr/local/pgsql`, кластер БД PostgreSQL создан в `/opt/postgres_data`.

###### Обновление Hashicorp Vault до версии 1.4.0

1.  Остановить работу vault:

    ```bash
    sudo systemctl stop vault
    ```
2.  Скачать и распаковать vault:

    ```bash
    VAULT_VERSION="1.4.0"
    curl -O https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip

    unzip vault_${VAULT_VERSION}_linux_amd64.zip
    sudo mv vault /usr/local/bin/
    ```

3. Запуск vault:

    ```bash
    sudo systemctl start vault
    ```

##### Настройка подключения

В системе используются механизм защиты данных от привилегированных пользователей и механизм прозрачного шифрования данных. Их функционирование описывается в соответствующих разделах.
Оба механизма используют сервис управления ключами (KMS).

В обязанности администратора безопасности входит настройка соединения со службой управления ключами (KMS). Если на сервере настроены параметры KMS, то при выполнении команды `initdb` происходит конфликт между параметрами локальной и удаленной конфигурации.
Чтобы восстановить возможность инициализировать новые базы данных, переместите или удалите файл `/etc/postgres/enc_connection_settings.cfg`.

Настройка соединения с KMS осуществляется через утилиту `setup_kms_credentials`:

1. Запустите `setup_kms_credentials` на экземпляре СУБД Pangolin

2. Вы увидите сообщение с предложением выбрать, для какого домена задать идентификационные данные: KMS или POSTGRESQL. Выберите первый вариант.

    ```
        Choose credentials domain:
        1. KMS					<-
        2. POSTGRESQL
        3. AUTH_TOKEN
    ```

3. Вы увидите сообщение с предложением указать ID кластера Pangolin:

    ```
        Enter Pangolin cluster ID:
        2						<-
    ```

4. Вы увидите сообщение с предложением указать IP-адрес и порт KMS:

    ```
        Enter IP address:
        10.53.116.39				<-
        Enter port:
        82002						<-
    ```

5. Вы увидите сообщение с предложением выбрать метод аутентификации: Userpass или AppRole. Выберите первый вариант.

    ```
        Choose credentials type:
        1. Userpass Auth Method	<-
        2. AppRole Auth Method
    ```

6. Вы увидите предложение указать логин и пароль и подтвердить пароль:

    ```
        Enter login:
        adminencryption			<-
        Enter password:
        ****					<-
        Confirm password:
        ****					<-
    ```

7. Вы увидите предложение добавить настройки для еще одного KMS:

    ```
        Do you want to add another KMS credentials? (yes/no)?:
        no						<-
    ```

8. Если установка идентификационных данных выполнена успешно, вы увидите следующее сообщение:

    ```
        Credentials for KMS has been set successfully
    ```

    Если при установке возникли проблемы, воспользуйтесь командой:

    ```
        setup_kms_credentials --help
    ```

9. Установите необходимые права доступа на созданный файл настроек. Для этого введите в консоли команду:

    ```
        $ chmod 600 /etc/postgres/enc_connection_settings.cfg
    ```

Настройка соединения с системой управления ключами завершена.

#### etcd

В кластере Platform V Pangolin для хранения информации о состоянии кластера Patroni используется хранилище etcd версии 3.3.11 (устанавливается инсталлятором).

```Bash
sudo systemctl yum install etcd
```

##### Настройка etcd

Для настройки сервиса откройте файл параметров `etcd.service` и укажите в нем следующие данные:

```Bash
Sudo vi /etc/systemd/system/etcd.service

[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
User=etcd
### set GOMAXPROCS to number of processors
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/bin/etcd"

Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
node-1 /etc/etcd/etcd.conf
[pprb_dev@tkle-pprb0100 ~]$ sudo cat /etc/etcd/etcd.conf | grep -v ^#
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_NAME="node-01"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${HOST_VM1}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${HOST_VM1}:2379"
ETCD_INITIAL_CLUSTER="node-01=http://${HOST_VM1}:2380,node-02=http://${HOST_VM2}:2380,node-03=http://${HOST_VM3}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
node-02 /etc/etcd/etcd.conf
[pprb_dev@tkle-pprb0095 ~]$ sudo cat /etc/etcd/etcd.conf | grep -v ^#
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_NAME="node-02"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${HOST_VM2}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${HOST_VM2}:2379"
ETCD_INITIAL_CLUSTER="node-01=http://${HOST_VM1}:2380,node-02=http://${HOST_VM2}:2380,node-03=http://${HOST_VM3}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
node-03 /etc/etcd/etcd.conf
[pprb_dev@tkle-pprb0081 ~]$ sudo cat /etc/etcd/etcd.conf | grep -v ^#
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_NAME="node-03"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${HOST_VM3}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${HOST_VM3}:2379"
ETCD_INITIAL_CLUSTER="node-01=http://${HOST_VM1}:2380,node-02=http://${HOST_VM2}:2380,node-03=http://${HOST_VM3}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
```

Параметры `etcd.service`:

- --listen-peer-urls ’ http://localhost:2380 ’ - список ссылок, с которых собирается трафик пиров.
- --listen-client-urls ’ http://localhost:2379 ’- список ссылок, с которых собирается трафик пиров.
- --heartbeat-interval ‘100’ - время (мс) периода проверки (heartbeat).
- --election-timeout ‘1000’ - время (в мс) таймаута алгоритма выбора.
- --initial-advertise-peer-urls ’ http://localhost:2380 ’ - список ссылок пиров этого элемента кластера для передачи другим элемента кластера.
- --advertise-client-urls ’ http://localhost:2379 ’ - список ссылок клиентов этого элемента кластера для публичной передачи. Передаваемые ссылки клиентов будут доступны системам, взаимодействующим с кластером etcd. Клиентские библиотеки обрабатывают эти ссылки для подключения к кластеру etcd.
- --initial-cluster ‘default= http://localhost:2380’ - исходная конфиугурация кластера для бутстрапинга.
- --initial-cluster-state ‘new’ - исходное состояние кластера (‘new’ или ‘existing’).
-   --initial-cluster-token ‘etcd-cluster’ - исходный токен кластера etcd во время бутстрапа. При исользовании нескольких кластеров позволяет избежать непреднамеренного взаимодействия между ними.

Обязательно рекурсивно смените владельца директории. Для этого выполните:

```Bash
sudo chown -R etcd:etcd /var/lib/etcd/
```

Затем запустите на каждом узле кластера:

```Bash
sudo systemctl daemon-reload
sudo systemctl start etcd.service
sudo systemctl status etcd.service
sudo journalctl -xe
```

##### Устранение неполадок

*Ошибка:* 

```Bash
sudo journalctl -xe:
etcd[1667]: request cluster ID mismatch (got 7cea461d0dab6173 want e769641869d94218)
```

*Решение:* 

Орстановите кластер и пересоздайте директорию `/var/lib/etcd`:

```Bash
sudo systemctl stop etcd.service
sudo rm -rf /var/lib/etcd/
sudo mkdir /var/lib/etcd
sudo chown -R etcd:etcd /var/lib/etcd/
sudo systemctl start etcd.service
```

*Ошибка:*

```
CRITICAL: system ID mismatch, node pg02 belongs to a different cluster: 6792170493505963560 != 6792187323051185862
```

*Решение:*

Выполните команду:

```Bash
etcdctl rm /service/clustername/initialize
```

и перезапустите patroni.

*Ошибка:*

При одном запущенном patroni:

```Bash
INFO: following a different leader because i am not the healthiest node
```

*Решение:*

Выполните команду:

```Bash
etcdctl rm /service/clustername/optime/leader
```
и перезапустите patroni.

##### Полезные функции

Для быстрого просмотра проблем с кластером:

```Bash
etcdctl cluster-health
```

Для просмотра структуры хранилища:

```Bash
etcdctl ls --recursive --sort -p /service/clustername
```

где `clustername` - имя кластера базы.

Для просмотра всей структуры:

```Bash
etcdctl ls --recursive /
```

Пример:

```Bash
[pprb_dev@tkle-pprb0066 ~]$ etcdctl ls -r /
/service
/service/clus
/service/clus/members
/service/clus/members/pg02
/service/clus/members/pg01
/service/clus/initialize
/service/clus/config
/service/clus/optime
/service/clus/optime/leader
/service/clus/history
/service/clus/leader
```

Для получения значения из параметра:

```Bash
etcdctl -o extended get /service/clustername/leader
etcdctl -o extended get /service/clustername/members/
```

#### HAProxy

HAProxy - инструмент для обеспечения высокой доступности и балансировки нагрузки для TCP и HTTP-приложений посредством распределения входящих запросов на несколько обслуживающих серверов.

##### Установка

sudo yum install haproxy
sudo systemctl enable haproxy
sudo mkdir -p /var/lib/haproxy
sudo touch /var/lib/haproxy/stats
haproxy.cfg

##### Настройка

Конфигурация HAProxy задаётся в файле `/etc/haproxy/haproxy.cfg`:

```Bash
##---------------------------------------------------------------------
### Global settings
##---------------------------------------------------------------------
global
    log         127.0.0.1 local0 debug
    log         127.0.0.1 local1 notice

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        postgres
    group       postgres
    daemon

    ## turn on stats unix socket
    stats socket /var/lib/haproxy/stats

##---------------------------------------------------------------------
### common defaults that all the 'listen' and 'backend' sections will
### use if not designated in their block
##---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option                  http-server-close
    option                  redispatch
    retries                 2
    timeout http-request    10s
    timeout queue           1m
    timeout connect         4s
    timeout client          30m
    timeout server          30m
    timeout http-keep-alive 10s
    timeout check           5s
    maxconn                 3000

frontend fe_postgresql
    bind *:5000 #
    default_backend be_postgres

backend be_postgres
 option httpchk
 http-check expect status 200
 default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions #
 server postgresql1 ${HOST_VM1}:${PORT_PG_VM1} maxconn 100 check port ${patroni_port} #
 server postgresql2 ${HOST_VM2}:${PORT_PG_VM2} maxconn 100 check port ${patroni_port} #
```

После сохранения конфигурации необходимо перезапустить HAProxy с новыми параметрами:

```
sudo systemctl restart haproxy.service
sudo systemctl status haproxy.service -l
```

##### Настройка панели статистики

Чтобы иметь возможность просматривать текущую статистику HAProxy, добавьте в файл конфигурации следующий блок:

```Bash
listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /
```

Затем перезапустите HAProxy.

Панель статистики будет доступна по адресу `{адрес сервера}:7000`.

#### confd

##### Настройка

Создайте файл `/etc/confd/conf.d/haproxy.toml` со следующим содержанием:

```Bash
[template]
prefix = "/service/cluster_name"
owner = "pprb_dev"
mode = "0644"
src = "haproxy.tmpl"
dest = "/etc/haproxy/haproxy.cfg"

check_cmd = "/usr/sbin/haproxy -c -f {{.src }}"
reload_cmd = "haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -D -sf $(cat /var/run/haproxy.pid)"

keys = [
    "/members/"
]


Создайте файл `/etc/confd/templates/haproxy.tmpl` со следующим содержанием:

```Bash
 global
    log         127.0.0.1 local0 debug
    log         127.0.0.1 local1 notice

    chroot     /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        postgres
    group     postgres
    daemon

    stats socket /var/lib/haproxy/stats

defaults
    mode                    http
    log                     global
    option                 httplog
    option                 dontlognull
    option http-server-close
    option                 redispatch
    retries                 2
    timeout http-request    10s
    timeout queue         1m
    timeout connect         4s
    timeout client         30m
    timeout server         30m
    timeout http-keep-alive 10s
    timeout check         5s
    maxconn                 3000

frontend fe_postgresql
    bind *:5000 #
    default_backend be_postgres

backend be_postgres
 option httpchk
 http-check expect status 200
 default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions #
{{range gets "/members/*"}} server {{base.Key}} {{$data := json.Value}}{{base (replace (index (split $data.conn_url "/") 2) "@" "/" -1)}} maxconn 100 check port {{index (split (index (split $data.api_url "/") 2) ":") 1}}
{{end}}
```

#### Расширения

##### pg_pathman

pg_pathman - это расширение, реализующее оптимизированное решение для секционирования больших и распределённых баз данных.

Секционированием данных называется разбиение одной большой логической таблицы на несколько меньших физических секций. Секционирование может принести следующую пользу:

- В определённых ситуациях оно кардинально увеличивает быстродействие, особенно когда большой процент часто запрашиваемых строк таблицы относится к одной или лишь нескольким секциям. Секционирование может сыграть роль ведущих столбцов в индексах, что позволит уменьшить размер индекса и увеличит вероятность нахождения наиболее востребованных частей индексов в памяти.
- Когда в выборке или изменении данных задействована большая часть одной секции, последовательное сканирование этой секции может выполняться гораздо быстрее, чем случайный доступ по индексу к данным, разбросанным по всей таблице.
- Массовую загрузку и удаление данных можно осуществлять, добавляя и удаляя секции, если это было предусмотрено при проектировании секционированных таблиц. Операция ALTER TABLE DETACH PARTITION или удаление отдельной секции с помощью команды DROP TABLE выполняются гораздо быстрее, чем массовая обработка. Эти команды также полностью исключают накладные расходы, связанные с выполнением VACUUM после DELETE.
- Редко используемые данные можно перенести на более дешёвые и медленные носители.

###### Установка

1.	Необходимо добавить pg_pathman в настроечный параметр `shared_preload_libraries` в конфигурационном файле `PostgreSQL.conf`. 

    **Важно!** pg_pathman может конфликтовать с другими расширениями, которые используют те же функции для перехвата управления. В связи с этим необходимо всегда добавлять это расширение в конец списка `shared_preload_libraries`.

1.	Создать расширение в БД:

    ```SQL
    CREATE EXTENSION pg_pathman;
    ```

###### Проблемы и решения

*Проблема*

При запуске секционирования может возникнуть ограничение блокировок по транзакциям.

*Решение*

Увеличить параметр `max_locks_per_transactions` до 1024.

#### pg_cron

Расширение позволяет создавать задачи cron, выполняющие команды Platform V Pangolin в заданной БД.

##### Настройка
Расширение уже входит в поставку Platform V Pangolin. Для его использования необходимо:

В `postgresql.conf` прописать:

```code
shared_preload_libraries = 'pg_cron'
cron.database_name = 'pangolin'
```
где pangolin - имя БД, в которой будет работать cron.

От пользователя с правами `superuser` необходимо включить расширения:

```SQL
CREATE EXTENSION pg_cron;
```

Выдать права на cron нужному пользователю:

```SQL
GRANT USAGE ON SCHEMA cron TO marco;
```

Так как процессу `pg_cron` необходимо создавать коннекцию к БД, в файле `.pgpass` нужно прописать имя и пароль пользователей, использующих cron.

#### Фрагментация: pg_repack и pgcompacttable
В состав Platform V Pangolin входят утилиты по реорганизации данных:
- расширение `pg_repack` - реорганизация таблиц без блокировки, удаление пустот в таблицах и индексах, восстановление физического порядка кластеризованных индексов. Есть переведённая документация;
- инструмент `pgcompacttable` - скрипт perl для уменьшения размера “раздутых” таблиц и индексов без применения Access Exclusive блокировки.

##### Расширение pg_repack
Функциональность:
- реорганизация таблиц без блокировки, в отличие от стандартных средств PostgreSQL: VACUUM FULL и CLUSTER. Производительность сравнима с CLUSTER.
- удаление пустот в таблицах и индексах;
- восстановление физического порядка кластеризованных индексов;
- наличие официальной переведённой документации.

###### Установка

Включить расширение в Platform V Pangolin:

```SQL
CREATE EXTENSION pg_repack;
```

###### Известные проблемы

*Проблема*

Включено расширение `pg_pathman`. `pg_repack` входит в бесконечный цикл при обработки таблиц `pg_pathman`, что приводит к реорганизация не отдельной таблицы, а всей базы.

*Решение*

Явно исключить pg_pathman из обработки с помощью ключа “-C pg_pathman”.

###### Пример использования

Реорганизовать таблицу `bloated_table`:

```SQL
pg_repack -U <username> -d <dbname> -t bloated_table
```

##### Инструмент pgcompacttable

Инструмент реорганизации данных в “раздутых” таблицах (bloated tables), восстановления индексов и возврата дискового пространства. Преимущества:

- не влияет на производительность базы данных;
- не использует Access Exclusive блокировки.

Требования к программному окружению

- библиотека Perl DBI с модулем поддержки PostgresSQL;
- установлен модуль pgstattuple.

###### Установка pgcompacttable

Не требуется.

## Проверка работоспособности

Значительная часть проверок осуществляется системой в автоматическом режиме:

- На начальном этапе инсталяции любой схемы Platform V Pangolin проводятся проверки корректности переданных на вход инсталятору значений.

- На конечном этапе инсталяции любой схемы Platform V Pangolin происходят следующие автоматические проверки:

	- консистентность состава инсталяции;
	- наличие документации;
	- проверка конфигурационных файлов всех сервисов;
	- интерфейсные проверки всех сервисов.

Чтобы убедиться в работоспособности системы, выполните следующие операции:

1.	Проверка подключения к БД:

    ```Bash
    psql -U $admin_as_name $db_name
    ```

2.	Проверка возможности создания таблицы в пользовательской схеме:

    ```Bash
    psql -U $admin_as_name $db_name
    SET ROLE as_admin;
    CREATE TABLE $installed_schema.t1();
    ```

3.	Проверка доступности таблицы под локальной УЗ:

    ```Bash
    psql -U $TUZ_name $db_name
    SELECT * FROM $installed_schema.t1;
    ```

4.	Проверка возможности создания новой схемы:

    ```Bash
    psql -U $admin_as_name $db_name
    SET ROLE as_admin;
    CREATE SCHEMA $new_schema_name AUTHORIZATION «as_admin»;
    ```

## Удаление существующей инсталляции

Чтобы удалить Platform V Pangolin, выполните следующую команду на каждом узле:

```Bash
sudo systemctl stop patroni; sudo systemctl stop pgbouncer; sudo systemctl stop etcd; sudo systemctl stop confd; sudo yum remove python-psycopg2 -y; sudo pip uninstall psycopg2-binary -y; sudo yum remove postgresql-sber-edition -y; sudo yum remove etcd -y; sudo pip uninstall patroni -y; sudo yum remove confd -y; sudo yum remove haproxy -y; sudo rm -rf /usr/local/pgsql/; sudo yum remove -y etcd postgresql-sber-edition;  sudo su -c "rm -rf /pgsql/"; etcdctl rm service/clustername/initialize; sudo rm -rf /etc/etcd; sudo rm -rf /etc/confd; sudo rm -rf /etc/pgbouncer; sudo rm -rf /etc/patroni; sudo rm -rf /pgdata/; sudo rm -rf /pgerrorlogs/; sudo rm -rf /pgbackup/; sudo yum remove pg_probackup-11 -y; sudo rm -rf /pgarclogs/; sudo rm -rf /var/lib/etcd/; sudo rm -rf /usr/pgsql-se-04; sudo rm -rf /usr/pgsql-se-04.003.00/; sudo rm -rf /usr/patroni/; sudo sed -i "/\/usr\/local\/sbin\/dynmotd.sh/d" /etc/profile; sudo sed -i "/# Dynamic motd/d" /etc/profile; sudo rm /etc/pip.conf; echo $? 
```

## Часто встречающиеся проблемы и пути их устранения

**Проблема:**

Обрыв сети между ЦОД.

**Рекомендация:**

-   размещение HAProxy за пределами КТС с СУБД;
-   дублирование экземпляров `HAProxy`;
-   добавление в схему решений, реализующих VRRP или аналоги - BGP.

**Проблема:**

Если используется асинхронная репликация, то в случае частичного обрыва сети на `Active` (запросы от клиентов продолжают поступать на `Active`) и срабатывания `AutoFailOver` может возникнуть ситуация, называемая S`plit Brain`. До срабатывания `ttl` изолированный экземпляр PostgreSQL продолжает обрабатывать клиентские запросы в режиме `Active`. Если восстановление сети произойдет после срабатывания `ttl` (смена ролей `Active/StandBy`), то на "старом" `Active` будет выполнена команда `pg_rewind`, в результате которой будут отменены все транзакции, примененные в период с момента разрыва до срабатывания `ttl`.

**Рекомендации:**

-   использовать режим синхронной репликации;
-   реализовать `callback` в скриптах `patroni` для переключения `Active` в `StandBy` при разрыве сети (без ожидания срабатывания `ttl`);

**Проблема:**

Если в рамках описанного выше сценария отключить использование `pg_rewind`, то добавленные до истечения `ttl` транзакции не удаляются, но и не реплицируются на "новый" `Active`, после восстановления соединения. Аналогичное поведение наблюдается и при синхронной репликации.

**Рекомендации:**

-   перенос данных на новый `Active` (возможно, `pg_receivewal`), с проработкой вопроса "мёрджа" данных в случае конфликтов.

**Проблема:**

Если в рамках описанного выше сценария будет использована синхронная репликация, то запросы на "старом" `Active` будут висеть, не завершаясь, при этом транзакции на нем будут применены. После восстановления соединения транзакции откатываются `pg_rewind`.

**Рекомендации:**

-   реализовать на стороне клиента защитный механизм с таймаутами (в случаях срабатывания таймаута откатывать текущую транзакцию);
-   не применять транзакцию в случае невозможности репликации.

**Проблема:**

При использовании строгой синхронной репликации и недоступности `StandBy` запрос на `Active` висит, не завершаясь. Запись в базу добавляется после сигнала прерывания, либо при восстановлении связи со `StandBy`. Репликация отрабатывает после восстановления связи с `StandBy`.

**Рекомендации:**

-   реализовать на стороне клиента защитный механизм с таймаутами (в случаях срабатывания таймаута - откатывать текущую транзакцию);
-   добавить в схему второй `StandBy`, настроенный на асинхронное реплицирование с синхронным `StandBy`;
-   не применять транзакцию в случае невозможности репликации.

**Проблема:**

В случае аварийного завершения сервиса `patroni` на `Active` во всех режимах работы есть вероятность потери транзакций в результате работы `pg_rewind`.

**Рекомендации:**

-   использовать схему с автоматическим переключением трафика клиентов на новый `Active` (использование `pgbouncer`).

**Проблема:**

Во всех режимах работы при разрыве сети между ЦОДами и недоступностью `Active` велика вероятность потери данных в результате `Split Brain`.

**Рекомендации:**

-   добавление в схему новых элементов: `pgbouncer` и `confd`.

## Чек-лист валидации установки

Значительная часть проверок осуществляется системой в автоматическом режиме:

-   на начальном этапе инсталяции любой схемы PostgreSQL SE проводятся проверки корректности переданных на вход инсталятору значений;

-   на конечном этапе инсталяции любой схемы PostgreSQL SE происходят следующие автоматические проверки:

        -   консистентность состава инсталяции;
        -   наличие документации;
        -   проверка конфигурационных файлов всех сервисов;
        -   интерфейсные проверки всех сервисов.

Для того, чтобы убедиться в работоспособности системы, выполните следующие функции:

1.  Проверка коннекта к БД:

    ```Bash
    psql -U $admin_as_name $db_name
    ```

2.  Проверка возможности создания таблицы в пользовательской схеме:

    ```Bash
    psql -U $admin_as_name $db_name
    SET ROLE as_admin;
    CREATE TABLE $installed_schema.t1();
    ```

3.  Проверка доступности таблицы под локальной УЗ:

    ```Bash
    psql -U $TUZ_name $db_name
    SELECT * FROM $installed_schema.t1;
    ```

4.  Проверка возможности создания новой схемы:

    ```Bash
    psql -U $admin_as_name $db_name
    SET ROLE as_admin;
    CREATE SCHEMA $new_schema_name AUTHORIZATION «as_admin»;
    ```