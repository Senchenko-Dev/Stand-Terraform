# Kafka SberEdition DeployTool Install_EIP mod

## Что изменено:

| Вместо | стало |  
| ---  | --- |  
| hosts: all         | hosts: KafkaNodes:ZookeeperNodes |  
| inventory_hostname | ansible_host |  
| become user |   become_user: "{{ kafka_user }}" vars: - ansible_become_user: "{{kafka_user}}" - ansible_become_password: "{{kafka_default_password}}" |
|  |  |






## Based on Ansible for deploying Kafka and Zookeeper clusters on bare metal servers

Цели разработки данного инструмента заключаются в автоматизации процесса развертывания кластеров Zookeeper и Kafka, выполнения действие с кластером и отдельными его частями, минимизации времени затрачиваемого на "рутинные" действия и исключении ошибок при ручном выполнении развертывания.

Описание и инструкция по использованию инструментом: https://sbtatlas.sigma.sbrf.ru/wiki/pages/viewpage.action?pageId=2805661893

Фадеев Денис Сергеевич
Ведущий ИТ-инженер
ПАО Сбербанк, Акционерное общество "Сбербанк-Технологии"
Департамент базовых платформенных компонентов
Команда развития Kafka
УРМ г. Барнаул (Обской, д. 30)
