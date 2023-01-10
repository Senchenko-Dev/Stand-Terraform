# ELK

# TODO
- [ ] Возможность установки только elasticsearch 
- [ ] Добавить настройку шаблона sudoers.d 
- [ ] Как сделать /usr 40G ?
- [ ]
- [ ]
- [ ]

1. Что такое required_packages?
2. Почему так сложно сделан template tasks/os_conf.yml:68
3. 


## Правки
### Пееременные для group_vars
```
net_zone: INSTEIP
java_version: 1.8.0

elastic_pkg: "http://10.42.4.125/mirror/docker/images/awx/other/elk/elasticsearch-8.4.3-x86_64.rpm"
kibana_pkg: "http://10.42.4.125/mirror/docker/images/awx/other/elk/kibana-8.4.3-x86_64.rpm"
logstash_pkg: "http://10.42.4.125/mirror/docker/images/awx/other/elk/logstash-8.4.3-x86_64.rpm"
```

### Logstash

```
chown elk:logstash /usr/share/logstash/data/queue/
chmod 0775 /usr/share/logstash/data/queue/


chown elk:logstash /usr/share/logstash/data/dead_letter_queue/
chmod 0775 /usr/share/logstash/data/dead_letter_queue/

cp /etc/logstash/logstash-sample.conf /etc/logstash/conf.d/
```

### Elasticsearch

```
# elk_0 - добавить в /etc/hosts
/usr/share/elasticsearch/bin/elasticsearch-keystore list

#disable
discovery.seed_hosts
cluster.initial_master_nodes
discovery.type: single-node

xpack.security.transport.ssl.enabled: false
xpack.security.enabled: false
xpack.security.http.ssl.enabled: false
#xpack.security.enrollment.enabled: true
ingest.geoip.downloader.enabled: false
```

Проверить всели ок
```
curl  https://localhost:9200/_cluster/health?pretty -k -u elastic
```
Сбросить пароль для авторизации в кибана веб
```
/usr/share/elasticsearch/bin/elasticsearch-reset-password -i -u elastic

# сгенерировать пароль без вопросов и вывести его
/usr/share/elasticsearch/bin/elasticsearch-reset-password -b -s -a -u elastic --url  http://10.42.4.140:9200
```

Сбросить пароль для авторизации в кластере
```
/usr/share/elasticsearch/bin/elasticsearch-reset-password -b -s -u kibana_system
```

Авторизация через веб
```
bin/elasticsearch-create-enrollment-token --scope kibana
```

Изменить пароль для elastic
```
curl -X POST -u "elastic:XwP1qtp3saS+llj310HP" "http://10.42.4.140:9200/_security/user/elastic/_password?pretty" -H 'Content-Type: application/json' -d'
{
"password" : "123456"
}
'
```

### Kibana
Ругается на синтактическую ошибку
```
logging:
  appenders:
    file:
      type: file
      fileName: /var/log/kibana/kibana.log
      layout:
        type: json
  root:
    appenders:
      - default
      - file

# Настройки
elasticsearch.hosts: ["http://10.42.4.162:9200"]
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.username: "kibana"
elasticsearch.password: "qwe123qwe"

# Генерация секретного ключа
/usr/share/kibana/bin/kibana-encryption-keys generate
```









