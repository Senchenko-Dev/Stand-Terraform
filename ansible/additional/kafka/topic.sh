echo "hello world" > /tmp/hello

systemctl stop kafka
systemctl start kafka

cd `dirname $(find / -name kafka-acls 2>/dev/null)`
echo "Создание топиков"
./kafka-topics --zookeeper `hostname -f`:2181 --create --topic ufs-ul-sbercms-content-data --partitions 2 --replication-factor 1
./kafka-topics --zookeeper `hostname -f`:2181 --create --topic ufs-sbercms-content-acknowledgement --partitions 2 --replication-factor 1

echo "Установка времени хранения сообщений"
./kafka-configs --zookeeper `hostname -f`:2181 --entity-type topics --alter --entity-name ufs-ul-sbercms-content-data --add-config retention.ms=1800000
./kafka-configs --zookeeper `hostname -f`:2181 --entity-type topics --alter --entity-name ufs-sbercms-content-acknowledgement --add-config retention.ms=1800000


echo "Просмотр конфигурации брокера"
./kafka-configs.sh --bootstrap-server `hostname -f`:9092 --entity-type brokers --all --describe


