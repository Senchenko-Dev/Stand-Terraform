# Примечания к релизу

Platform V Pangolin - система управления базами данных, основанная на PostgreSQL. В этом документе приведены примечания к релизу версии Pangolin 4.3.1 от 21.04.2021.

Этот документ предназначен для специалистов, занимающихся установкой и обслуживанием системы, а также для разработчиков приложений, работающих с системой.

## Состав дистрибутива

В этом разделе перечислены элементы системы, входящие в релиз.

**Модуль**|**Версия**
:-----:|:-----:
Ядро PostgreSQL|11.10
pgBouncer|1.14
patroni|1.6.4
confd|0.16.0
RH|7.7/7.8/7.9
Агент DataProtector|10.60

### Список расширений

В этом разделе перечислены расширения, входящие в релиз.

**№**|**Расширение**|**Версия**
:-----:|:-----:|:-----:
1|plperlu|1.0
2|cube|1.4
3|hstore\_plperlu|1.0
4|hstore\_plpythonu|1.0
5|pltcl|1.0
6|hstore\_plperl|1.0
7|jsonb\_plpythonu|1.0
8|plpythonu|1.0
9|ltree|1.1
10|file\_fdw|1.0
11|pgrowlocks|1.2
12|insert\_username|1.0
13|dblink|1.2
14|refint|1.0
15|jsonb\_plperlu|1.0
16|sslinfo|1.2
17|moddatetime|1.0
18|btree\_gist|1.5
19|tablefunc|1.0
20|bloom|1.0
21|uuid-ossp|1.1
22|pg\_stat\_statements|1.6
23|unaccent|1.1
24|pg\_trgm|1.4
25|btree\_gin|1.3
26|ltree\_plpython2u|1.0
27|dict\_xsyn|1.0
28|pg\_cron|1.2
29|pg\_freespacemap|1.2
30|hstore\_plpython2u|1.0
31|pltclu|1.0
32|ltree\_plpython3u|1.0
33|jsonb\_plpython2u|1.0
34|dict\_int|1.0
35|fuzzystrmatch|1.1
36|postgres\_fdw|1.0
37|intagg|1.1
38|plperl|1.0
39|jsonb\_plpython3u|1.0
40|pg\_visibility|1.2
41|citext|1.5
42|pgcrypto|1.3
43|tsm\_system\_rows|1.0
44|tsm\_system\_time|1.0
45|timescaledb|2.1.0-dev
46|hstore\_plpython3u|1.0
47|pg\_repack|1.4.5
48|isn|1.2
49|pgstattuple|1.5
50|ltree\_plpythonu|1.0
51|seg|1.3
52|autoinc|1.0
53|pg\_prewarm|1.2
54|timetravel|1.0
55|tcn|1.0
56|xml2|1.1
57|pageinspect|1.7
58|amcheck|1.1
59|adminpack|2.0
60|pg\_pathman|1.5
61|lo|1.1
62|pg\_buffercache|1.3
63|plpgsql|1.0
64|jsonb\_plperl|1.0
65|plpython2u|1.0
66|earthdistance|1.1
67|hstore|1.5
68|pgse\_backup|1.1
69|intarray|1.2
70|pgaudit (включен в ядро)|1.3

## Новый функционал

- Инсталлятор
    - добавлено значение misc_set для параметра pgaudit.log
    - исправлены права для учетной записи all-sa-pam19002_ro
- Изменение инфраструктуры сборки/компиляции решения (переход на 7.9)
- Исправлен дефект несовместимости timescaledb и pgaudit 