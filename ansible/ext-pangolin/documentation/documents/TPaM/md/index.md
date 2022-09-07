# Программа и методика испытаний

## Объект испытаний

PostgreSQL — это объектно-реляционная система управления базами данных, основанная на POSTGRES 4.2 — программе, разработанной на факультете компьютерных наук Калифорнийского университета в Беркли. PostgreSQL — СУБД с открытым исходным кодом, основой которого был код, написанный в Беркли. Она поддерживает большую часть стандарта SQL и предлагает множество современных функций:

-   сложные запросы;
-   внешние ключи;
-   триггеры;
-   изменяемые представления;
-   транзакционная целостность;
-   многоверсионность.

Platform V Pangolin – это объектно-реляционная система управления базами данных, основанная на свободно распространяемой версии PostgreSQL. Она содержит ряд доработок, позволяющих обеспечить повышенные требования к безопасности хранимых данных, доступности, надежности и производительности.

Ключевые функциональные особенности:

-   гибкое управление парольными политиками;
-   прозрачное шифрование хранимой информации;
-   защита от привилегированных пользователей;
-   аудирование действий пользователей;
-   автоматическое развертывание и конфигурирование кластера высокой доступности;
-   интеграция с инфраструктурой банка: LDAP, система резервного копирования, система мониторинга, ДИ;
-   функционирование в виртуальной и облачной среде;
-   инкрементальное резервное копирование;
-   сквозная аутентификация при использовании `pgBouncer`;
-   поддержка `prepared statements` для транзакционного режима кластера высокой доступности;
-   соответствие четвертому уровню доверия по ФСТЭК.

## Цель испытаний

Подтвердить выполение требований, указанных в разделе "Требования к программе".

## Требования к программе

Программа выполняет функции:

-   поддержка параллельных транзакций без взаимной блокировки сеансов с использованием версионности данных (MVCC);
-   ссылочная целостность данных;
-   поддержка реализации пользовательских типов данных;
-   функционирование в режиме отказоустойчивого кластера: физическая репликация данных и автоматическое переключение клиентских приложений на реплику в случае аварии;
-   возможность снятия резервной копии со standby-базы;
-   защита данных от привилегированных пользователей (администраторов баз данных);
-   прозрачное шифрование данных, включая интеграцию с системами класса key management для хранения мастер-ключей.

## Требования к программной документации

В документах "Детальная архитектура" и "Руководство по системному администрированию" содержится информация о проверяемых функциях, приведены варианты их использования (если применимо).

## Состав и порядок испытаний

Испытания проводится на операционной системе Linux Red Hat 7.8. 

Предварительно необходимо установить проверяемый объект, следуя инструкциям в документе "Руководство по установке".

Для выполнения испытаний необходима утилита `psql`.

Испытания необходимо проводить в порядке их следования в документе.

## Методы испытаний

### Проверка функции «Поддержка параллельных транзакций без взаимной блокировки сеансов с использованием версионности данных (MVCC)»

#### Сценарий «Поддержка параллельных транзакций без взаимной блокировки сеансов с использованием версионности данных (MVCC)»

1.  Создать таблицы и наполнить данными. Для этого на узле `$MASTER_HOST` открыть `psql` и выполнить sql код:

    ```SQL
    create table test_table (id int, name text);
    create table test_table2 (id int primary key, name text);
    insert into test_table(id, name) values (0, 'pit');
    insert into test_table(id, name) values (1, 'jim');
    insert into test_table(id, name) values (2, 'janis');
    insert into test_table2(id, name) values (0, 'pit');
    insert into test_table2(id, name) values (1, 'jim');
    insert into test_table2(id, name) values (2, 'janis');
    ```

    > *Ожидаемый результат*<br>Успешно созданы и наполнены данными две тестовые таблицы.

2.  Проверяется неблокирующее выполнение чтений записей таблицы в параллельно выполняемых транзакциях. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL    
    # коннекция 1:
    BEGIN; select * from test_table;
    # коннекция 2:
    BEGIN; select * from test_table; COMMIT;
    # коннекция 1:
    COMMIT;
    ```

    > *Ожидаемый результат*<br>Чтение из одной таблицы в параллельных транзакциях не блокируется.

3.  На этом шаге проверяется неблокирующее выполнение вставки записей в таблице параллельно с чтением записей из той же таблицы. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; insert into test_table(id, name) values (3, 'curt');
    # коннекция 2:
    BEGIN; select * from test_table; COMMIT;
    # коннекция 1:
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>Чтение и вставка данных в параллельных транзакциях не блокируются. Вставленные данные видны после завершения транзакции в коннекции 1.

4.  На этом шаге проверяется неблокирующее выполнение изменения записей в таблице параллельно с чтением записей из той же таблицы. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; update test_table set name = 'amy' where id = 1;
    # коннекция 2:
    BEGIN; select * from test_table; COMMIT;
    # коннекция 1:
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>Чтение и изменение данных в параллельных транзакциях не блокируются. Измененные данные видны после завершения транзакции в коннекции 1.

5.  На этом шаге проверяется неблокирующее выполнение удаления записей в таблице параллельно с чтением записей из той же таблицы. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; delete from test_table where id = 1;
    # коннекция 2:
    BEGIN; select * from test_table;COMMIT;
    # коннекция 1:
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>Чтение и удаление данных в параллельных транзакциях не блокируются. Удаление данных видно после завершения транзакции в коннекции 1.

6.  На этом шаге проверяется неблокирующее выполнение вставок записей таблицы в параллельно выполняемых транзакциях при условии отсутствия на таблице уникальных или первичных ключей, либо при отсутствии параллельных вставок записей с одинаковыми значениями полей ключей. 

    1.  Вставка одинаковых данных. При наличии первичного или уникального ключа будет блокировка. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

        ```SQL
        # коннекция 1:
        BEGIN; insert into test_table2 (id, name) values (4, 'jimmy');
        # коннекция 2:
        BEGIN; insert into test_table2 (id, name) values (4, 'jimmy');
        COMMIT; select * from test_table2;
        # коннекция 1:
        COMMIT; select * from test_table2;
        ```

        > *Ожидаемый результат*<br>Вставка данных в коннекции 2 блокируется, после завершения транзакции в коннекции 1 транзакция в коннекции 2 откатывается.<br>
        >
        > Коннекция 2:<br>
        >
        ```SQL
        BEGIN; insert into test_table2 (id, name) values (4, 'jimmy');
        BEGIN
        ERROR:  duplicate key value violates unique constraint "test_table2_pkey"
        DETAIL:  Key (id)=(4) already exists.
        ```

    2.  Без коллизий, без блокировки. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; insert into test_table (id, name) values (4, 'jimmy');
    # коннекция 2:
    BEGIN; insert into test_table (id, name) values (5, 'amy');
    COMMIT; select * from test_table;
    # коннекция 1:
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>Вставка данных в парарельных транзакция не блокируется.

7.  На этом шаге проверяется неблокирующее выполнение вставки записей в таблице параллельно с изменением записей в той же таблице, при условии отсутствия на таблице уникальных или первичных ключей, либо при отсутствии параллельных операций вставки и изменения записей с одинаковыми значениями полей ключей. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; update test_table set name='robert' where id=5;
    # коннекция 2:
    BEGIN; insert into test_table (id, name) values (5,'brian');
    # коннекция 2:
    COMMIT; select * from test_table;
    # коннекция 1:
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>В коннекции 1 будут изменены данные, которые были в таблице в момент начала транзакции и не будут измены данные вставленные транзакцией в коннекции 2.

8.  На этом шаге проверяется неблокирующее выполнение вставки записей в таблице параллельно с удалением записей в той же таблице, при условии отсутствия на таблице уникальных или первичных ключей, либо при отсутствии параллельных операций вставки и удаления записей с одинаковыми значениями полей ключей. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; delete from test_table where id=4;
    # коннекция 2:
    BEGIN; insert into test_table (id, name) values (4,'jonh');
    COMMIT; select * from test_table;
    # коннекция 1:
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>В коннекции 1 будут удалены данные, которые были в таблице в момент начала транзакции и не будут удалены данные вставленные транзакцией в коннекции 2.

9.  На этом шаге проверяется неблокирующее выполнение изменения записей в таблице параллельно с изменением не пересекающегося набора записей в той же таблице. При пересечении наборов изменяемых записей для операций изменения будет происходить блокировка до применения изменений блокирующей транзакции.

    1.  update пересекающегося множества записей - с блокировкой. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; update test_table set name='mia' where id=5;
    # коннекция 2:
    BEGIN; update test_table set name='gary' where id=5;
    # => блокировка
    # коннекция 1:
    COMMIT; select * from test_table;
    # коннекция 2:
    # => сошли с блокировки
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>Обновление данных в коннекции 2 блокируется, после завершения транзакции в коннекции 1 транзакция в коннекции 2 сойдет с блокировки и данные будут обновлены.

    2.  update не переесекающегося множества записей - без блокировки. Выполнить на узле `$MASTER_HOST`:

    ```SQL
    # коннекция 1:
    BEGIN; update test_table set name='mia' where id=5;
    # коннекция 2:
    BEGIN; update test_table set name='gary' where id=4;
    COMMIT; select * from test_table;
    # коннекция 1:
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>Обновление данных в параллельных транзакциях не блокируется.

10. На этом шаге проверяется неблокирующее выполнение удаления записей в таблице параллельно с изменением не пересекающегося набора записей в той же таблице. При пересечении наборов удаляемых и изменяемых записей для операций удаления будет происходить блокировка до применения изменений блокирующей транзакции. 

    1.  update и delete пересекающегося множества записей - с блокировкой. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; update test_table set name='gary' where id=5;
    # коннекция 2:
    BEGIN; delete from test_table where id=5;
    # => блокировка
    # коннекция 1:
    COMMIT; select * from test_table;
    # коннекция 2:
    # => сошли с блокировки
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>Удаление данных в коннекции 2 блокируется, после завершения обновления в транзакции в коннекции1 транзакция в коннекции 2 сойдет с блокировки, и данные обновленные в коннекции 1 будут удалены.

    2.  update не пересекающегося множества записей - без блокировки. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; update test_table set name='mia' where id=4;
    BEGIN; update test_table set name='mia' where id=4;
    # коннекция 2:
    BEGIN; delete from test_table where id=2;
    COMMIT; select * from test_table;
    # коннекция 1:
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>Обновление и удаление данных в параллельных транзакциях не блокируется.

11. На этом шаге проверяется неблокирующее выполнение удаление записей в таблице параллельно с удалением не пересекающегося набора записей в той же таблице. При пересечении наборов удаляемых записей для операций удаления будет происходить блокировка до применения изменений блокирующей транзакции.

    1.  delete пересекающегося множества записей - с блокировкой. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; delete from test_table where id=4;
    # коннекция 2:
    BEGIN; delete from test_table where id=4;
    # => блокировка
    # коннекция 1:
    COMMIT; select * from test_table;
    # коннекция 2:
    # =>сходим с блокировки
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>Удаление данных в коннекции 2 блокируется, после завершения транзакции в коннекции 1 транзакция в коннекции 2 сойдет с блокировки, данные уже удалены.

    2.  delete не переесекающегося множества записей - без блокировки. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    BEGIN; delete from test_table where id=0;
    # коннекция 2:
    BEGIN; delete from test_table where id=3;
    COMMIT; select * from test_table;
    # коннекция 1:
    COMMIT; select * from test_table;
    ```

    > *Ожидаемый результат*<br>Удаление данных в параллельных транзакциях не блокируется.

12. На этом шаге проверяется атомарность применения всех изменений транзакции. Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    1.  Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 2:
    select * from test_table;
    select * from test_table2;
    # коннекция 1:
    begin;
    insert into test_table (id, name) values (8,'louis');
    update test_table set name='pit' where id=8;
    delete from test_table where id=8;
    insert into test_table2 (id, name) values (8,'louis');
    commit;
    # коннекция 2:
    select * from test_table;
    select * from test_table2;
    ```

    > *Ожидаемый результат*<br>В таблице 1 данные не изменились, в таблице 2 добавилась одна запись.

    2.  Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    # коннекция 1:
    begin;
    insert into test_table (id, name) values (9,'louis');
    update test_table set name = 'pit' where id=9;
    delete from test_table where id=9;
    insert into test_table2 (id, name) values (9,'louis');
    rollback;
    # коннекция 2:
    select * from test_table;
    select * from test_table2;
    ```

### Проверка функции «Ссылочная целостность данных»

#### Сценарий «Ссылочная целостность данных»

1.  Создать таблицы и наполнить данными.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    CREATE TABLE t3 (
            f1 int primary key,
            f2 text
    );
    
    CREATE TABLE t4 (
            f1        int references t3(f1) ON DELETE RESTRICT ON UPDATE RESTRICT,
            f2        text
    );
    
    CREATE TABLE t5 (
            f1        int,
            f2        text
    );
    
    alter table t5 add foreign key (f1) REFERENCES t3(f1) ON DELETE CASCADE ON UPDATE CASCADE;
    
    insert into t3 (f1, f2) values (1, 'aaaa');
    ```

    > *Ожидаемый результат*<br>Таблицы созданны корректно и наполнены данными.

2.  Вставить данные в таблицы содержащие поля с внешним ключем:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    insert into t4(f1, f2) values (2, 'qqqqq');
    insert into t5(f1, f2) values (2, 'qqqqq');
    ```

    > *Ожидаемый результат*<br>Обе операции вставки приводят к ошибкам:
    >
```text
ERROR:  insert or update on table "t4" violates foreign key constraint "t4_f1_fkey"
DETAIL:  Key (f1)=(2) is not present in table "t3".
ERROR:  insert or update on table "t5" violates foreign key constraint "t5_f1_fkey"
DETAIL:  Key (f1)=(2) is not present in table "t3".
```

3.  Удалить запись в таблице, на которую ссылается внешний ключ.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    postgres$ psql
    insert into t5(f1, f2) values (1, 'qqqqq');
    select * from t5;
    delete from t3 where f1=1;
    select * from t5;
    insert into t3 (f1, f2) values (1, 'aaaa');
    ```

    > *Ожидаемый результат*<br>В ссылающейся таблице t5 запись также удалена.

4.  Удалить запись в таблице, на которую ссылается внешний ключ.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    insert into t4(f1, f2) values (1, 'qqqqq');
    select * from t4;
    delete from t3 where f1=1;
    delete from t4 where f1=1;
    delete from t3 where f1=1;
    select * from t4;
    insert into t3 (f1, f2) values (1, 'aaaa');
    ```

    > *Ожидаемый результат*<br>Попытка удаления записи из таблицы t3 приводит к ошибке:
    >
```text
ERROR: update or delete on table "t3" violates foreign key constraint "t4_f1_fkey" on table "t4"
DETAIL: Key (f1)=(1) is still referenced from table "t4".
```
    >
    > После удаления записи из t4 удаление из t3 проходит успешно.

5.  Изменить запись в таблице, на которую ссылается внешний ключ.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    insert into t5(f1, f2) values (1, 'qqqqq');
    select * from t5;
    update t3 set f1=2 where f1=1;
    select * from t5;
    insert into t3 (f1, f2) values (1, 'aaaa');
    delete from t3 where f1=2;
    ```

    > *Ожидаемый результат*<br>В ссылающейся таблице t5 запись также изменена.

6.  Изменить запись в таблице, на которую ссылается внешний ключ.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    insert into t4(f1, f2) values (1, 'qqqqq');
    select * from t4;
    update t3 set f1=2 where f1=1;
    delete from t4 where f1=1;
    update t3 set f1=2 where f1=1;
    insert into t3 (f1, f2) values (1, 'aaaa');
    delete from t3 where f1=2;
    ```

    > *Ожидаемый результат*<br>Попытка изменения записи из таблицы t5 приводит к ошибке:
    >
```text
ERROR:  update or delete on table "t3" violates foreign key constraint "t4_f1_fkey" on table "t4"
DETAIL:  Key (f1)=(1) is still referenced from table "t4".
```
    >
    > После удаления записи из t4 измененние записи в t3 проходит успешно.

### Проверка функции «Поддержка реализации пользовательских типов данных»

#### Сценарий «Поддержка реализации пользовательских типов данных»

1.  Создать пользовательские данные.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    CREATE DOMAIN posint AS integer CHECK (VALUE > 0);
    CREATE TYPE my_dum;
    CREATE TYPE compfoo AS (f1 int, f2 text);
    CREATE TYPE bug_status AS ENUM ('new', 'open', 'closed');
    CREATE TYPE float8_range AS RANGE (subtype = float8, subtype_diff = float8mi);
    CREATE TYPE mybox;
    CREATE FUNCTION my_box_in_function(cstring) RETURNS mybox    AS 'box_in'
        LANGUAGE internal
        STRICT;
    CREATE FUNCTION my_box_out_function(mybox) RETURNS cstring AS 'box_out'
        LANGUAGE internal
        STRICT;
    CREATE TYPE mybox (
        INTERNALLENGTH = 16,
        INPUT = my_box_in_function,
        OUTPUT = my_box_out_function
    );
    CREATE TABLE myboxes (
        id integer,
        description mybox
    );
    ```

    > *Ожидаемый результат*<br>Типы успешно созданы.

2.  Использовать пользовательские типы для создания таблиц и функций.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    CREATE TABLE posfoo(id posint);
    CREATE FUNCTION getpos() RETURNS SETOF posint AS $$
        SELECT id FROM posfoo
    $$ LANGUAGE SQL;
    CREATE FUNCTION setpos(posint) RETURNS void AS $$
        UPDATE posfoo SET id = $1;
    $$ LANGUAGE SQL;
    
    CREATE TABLE foo1(id compfoo);
    CREATE FUNCTION getfoo() RETURNS SETOF my_dum AS $$
        SELECT fooid, fooname FROM foo1
    $$ LANGUAGE SQL;
    
    CREATE FUNCTION getcompfoo() RETURNS SETOF compfoo AS $$
        SELECT * FROM foo1
    $$ LANGUAGE SQL;
    CREATE FUNCTION setcompfoo(compfoo) RETURNS void AS $$
        UPDATE foo1 SET id=$1;
    $$ LANGUAGE SQL;
    
    CREATE TABLE bug (
        id serial,
        description text,
        status my_dum
    );
    
    CREATE TABLE bug1 (
        id serial,
        description text,
        status bug_status
    );
    CREATE FUNCTION setbug(bug_status) RETURNS void AS $$
        UPDATE BUG SET status = $1 WHERE id =1;
    $$ LANGUAGE SQL;
    
    CREATE TABLE rangefoo(id float8_range);
    
    CREATE TABLE myboxes1 (
        id integer,
        flag mybox
    );
    ```

    > *Ожидаемый результат*<br>Таблицы и функции созданы успешно, кроме:<br>
    >
    > -   функции `getfoo`: `ERROR: SQL function cannot return shell type my_dum`
    > -   таблицы `bug`: `ERROR: type "my_dum" is only a shell LINE 4: status my_dum`
    > -   функции `setbug`: `ERROR:  relation "bug" does not exist`
    >
    > `LINE 2:     UPDATE BUG SET status = $1 WHERE id =1;`

3.  Выполнить операции с использованием пользовательских типов.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    insert into posfoo values (1);
    SELECT id FROM posfoo;
    insert into posfoo values (-1);
    SELECT id FROM posfoo;
    UPDATE posfoo SET id = 5 WHERE id = 1;
    SELECT id FROM posfoo;
    select setpos(6);
    select getpos();
    
    
    insert into foo1 values ((1, 'aaa'));
    UPDATE foo1 SET id = (1, 'ccc') WHERE (id).f1 = 1;
    select * from foo1;
    select getcompfoo();
    select setcompfoo((1, 'bbb'));
    
    INSERT INTO bug1 VALUES (1, 'aaa', 'new');
    SELECT status from BUG1;
    UPDATE BUG1 SET status = 'open' WHERE id =1;
    CREATE INDEX idx_btree ON BUG1 USING btree(status);
    select * from BUG1;
    
    insert into rangefoo values ('[1.234, 5.678]');
    select * from rangefoo ;
    update rangefoo set id='[2.234, 4.678]';
    
    insert into myboxes(id, description) values (1, '((0,0),(1,1))' );
    select * from myboxes;
    ```

    > *Ожидаемый результат*<br>Все операции выполнены успешно, кроме:<br>
    >
    > Добавления в таблицу `posfoo`:<br>
    >
    > `ERROR:  value for domain posint violates check constraint "posint_check"`

### Проверка функции «Функционирование в режиме отказоустойчивого кластера: физическая репликация данных и автоматическое переключение клиентских приложений на реплику в случае аварии»

#### Сценарий «Функционирование в режиме отказоустойчивого кластера: физическая репликация данных и автоматическое переключение клиентских приложений на реплику в случае аварии - синхронная репликация данных»

1.  Создать таблицу на ведущем узле, наполнить таблицу данными.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    CREATE TABLE IF NOT EXISTS test_table(id integer, name varchar(30));
    INSERT INTO test_table VALUES (1, 'test');
    ```

    > *Ожидаемый результат*<br>Таблица создана и наполнена данными

2.  Проверить наличие данных таблицы на ведомом узле.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    SELECT * FROM test_table;
    ```

    > *Ожидаемый результат*<br>Данные на ведомом узле присутствуют и совпадают с данными на ведущем узле:<br>
    >
```text
id | name
-- | -----
1  | test

(1 row)
```

3.  Выполнить команду модификации данных на ведущем узле.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    UPDATE test_table SET id = id + 10 WHERE name='test';
    ```

    > *Ожидаемый результат*<br>Данные модифицированы

4. Проверить наличие данных таблицы на ведомом узле.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    SELECT * FROM test_table;
    ```

    > *Ожидаемый результат*<br>Данные на ведомом узле присутствуют и совпадают с данными на ведущем узле:
    >
```text
id | name
--|----
11 | test

(1 row)
```

5.  Удалить строку из таблицы на ведущем узле.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    delete from test_table WHERE name = 'test';
    ```

    > *Ожидаемый результат*<br>Строка удалена.

6.  Проверить наличие данных таблицы на ведомом узле.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    SELECT * FROM test_table;
    ```

    > *Ожидаемый результат*<br>Строка удалена на ведомом узле и данные совпадают с данными на ведущем узле:
    >
```
id | name
----|------

(0 rows)
```

7.  Удалить таблицу на ведущем узле.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    drop table test_table;
    ```

    > *Ожидаемый результат*<br>Таблица удалена.

8. Проверить наличие данных таблицы на ведомом узле.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    SELECT * FROM test_table;
    ```

    > *Ожидаемый результат*<br>Данные на ведомом узле отсутствуют, таблица тоже удалена: `ERROR:  relation "test_table" does not exist`

9.  Создать таблицу на ведомом узле.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    CREATE TABLE IF NOT EXISTS test_table(id integer, name varchar(30));
    ```

    > *Ожидаемый результат*<br>Запрос на создание таблицы не выполнен. Невозможно создать таблицу на узле, принимающем запросы только на чтение: `ERROR:  cannot execute CREATE TABLE in a read-only transaction`

10. Проверить настройки кластера высокой доступности на любом узле: синхронный режим.

    Выполнить на любом узле:

    ```bash
    postgres$ patronictl -c /etc/patroni/postgres.yml show-config
    postgres$ list
    ```

    > *Ожидаемый результат*<br>В результате вывода обратить внимание на значение параметров `synchronous_mode` и `synchronous_mode_strict : true`. Команда `list` отображает синхронную ведомую ноду (`Role: Sync Standby`).

#### Сценарий «Функционирование в режиме отказоустойчивого кластера: физическая репликация данных и автоматическое переключение клиентских приложений на реплику в случае аварии: механизмы переключения роли узла при аварии на ведущем узле»

1.  Внести заведомо невалидные изменения в конфигурацию `/etc/patroni/postgresql.yml` на ведущем узле: например, выставить `autovacuum_work_mem = qMb`.

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml`
    ```

    > *Ожидаемый результат*<br>Некорректные изменения внесены на ведущем узле.

2.  Рестартовать `patroni` на ведущем узле.

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ sudo systemctl restart patroni
    ```

    > *Ожидаемый результат*<br>На ведущем узле при перезагрузке будет считана новая конфигурация. В `postgresql.conf` выставится некорректное значение. `postgres` будет перезапущен, но не стартует с новой некорректной конфигурацией.
    >
    > Ведомый узел переходит в роль ведущего узла в следствие работы `autoFailOver`.

3.  Проверить состояние кластера на любом узле:

    ```bash
    postgres$ list
    ```

    > *Ожидаемый результат*<br>На ведущей ноде:<br>
    >
```text
State:  start
```

4.  Послать запрос на запись на «новый» ведущий узел.

    Открыть `psql` на узле `$REPLICA_HOST` и выполнить sql код:

    ```SQL
    CREATE TABLE IF NOT EXISTS test_table(id integer, name varchar(30));
    ```

    > *Ожидаемый результат*<br>В строгом синхронном режиме запрос на запись зависнет, пока не восстановится вторая нода.

5. Восстановить конфигурацию на «старом» ведущем узле и перезапустить `patroni`.

    > *Ожидаемый результат*<br>После восстановления второй ноды, кластер становится работоспособен, зависший запрос на запись выполнен.

6. Проверить состояние кластера на любом узле:

    ```bash
    postgres$ list
    ```

    > *Ожидаемый результат*<br>6. Обе ноды работают:
    >
```text
State:  running  
```

7. Выполнить ручное переключение роли ведомого и ведущего узлов.

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ patronictl -c /etc/patroni/postgres.yml switchover ${clustername} --force
    ```

    > *Ожидаемый результат*<br>Произошла корректная смена ролей ведущего и ведомого узлов: `Successfully switched over to "tkles-pprb00053.vm.esrt.cloud.sbrf.ru"`

#### Сценарий «Функционирование в режиме отказоустойчивого кластера: физическая репликация данных и автоматическое переключение клиентских приложений на реплику в случае аварии: управление отказоустойчивым кластером»

1.  Получить информацию по кластеру:

    -   определения ведущего и ведомого узла;
    -   определения типа репликации для ведомого узла - синхронный или асинхронный;
    -   проверки жизнеспособности СУБД компонента УРБД;
    -   получения информации по топологии кластера компонента УРБД;
    -   получения текущей конфигурации кластера компонента УРБД.

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ list
    ```

    > *Ожидаемый результат*<br>
    >
```text
Cluster: gtpsicl (6911952332177064372)

|           Member          |              Host              |     Role     |  State  | TL | Lag in MB |
|---------------------------|--------------------------------|--------------|---------|----|-----------|
| tkles-mvp000052.novalocal | tkles-mvp000052.novalocal:5433 |    Leader    | running | 50 |           |
| tkles-mvp000053.novalocal | tkles-mvp000053.novalocal:5433 | Sync Standby | running | 50 |         0 | 
```

2.  Проверить жизнеспособность и готовность координатора кластера.
    
    Выполнить на узле `$MASTER_HOST`:

    ```bash
    etcdctl cluster-health
    ```

    > *Ожидаемый результат*<br>cluster is healthy

3.  Получить историю переключения ролей узлов кластера.

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ patronictl -c /etc/patroni/postgres.yml history
    ```

    > *Ожидаемый результат*<br>Строки вида:
    >
```text
TL | LSN | Reason | Timestamp |
|----|-----------|------------------------------|---------------------------|
| 1 | 26575088 | no recovery target specified | 2020-11-09T15:06:24+03:00 |
```

4.  Просмотр и изменение динамической конфигурации кластера.

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ patronictl -c /etc/patroni/postgres.yml show-config
    postgres$ patronictl -c /etc/patroni/postgres.yml edit-config
    ```

    > *Ожидаемый результат*<br>Выводятся параметры и их значение:
    >
```text
synchronous_mode: true
synchronous_mode_strict: true
ttl: 30
```

5.  Переключить роли узлов кластера.

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ patronictl -c /etc/patroni/postgres.yml switchover ${clustername} –force
    ```

    > *Ожидаемый результат*<br>Роли переключены.

6.  Перезапуск СУБД узла кластера.

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ restart
    ```

    > *Ожидаемый результат*<br>СУБД перезапущена.

7.  Чтение и применение конфигурации кластера: выставить значение параметра `archive_timeout=179` в `/etc/patroni/postgres.yml`, открыть `psql` на узле `$REPLICA_HOST` и выполнить sql код:

    ```bash
    postgres$ psql
    
    postgres=# show archive_timeout;
    archive_timeout
    -----------------
    3min
    (1 row)
    postgres=# \q
    postgres$ reload
    Cluster: clustername (6895802558960469340)
    Member  tkles-pprb00053.vm.esrt.cloud.sbrf.ru  Host  tkles-pprb00053.vm.esrt.cloud.sbrf.ru:5433  Role  Leader  State  running  TL  4  Lag in MB  -  

    Member  tkles- tkles-pprb00103.vm.esrt.cloud.sbrf.ru  Host  tkles-pprb00103.vm.esrt.cloud.sbrf.ru:5433  Role  Sync Standby  State  running  TL  4  Lag in MB  0  
    Are you sure you want to reload members tkles-pprb00103.vm.esrt.cloud.sbrf.ru, tkles-pprb00053.vm.esrt.cloud.sbrf.ru? [y/N]: y
    Reload request received for member tkles-pprb00103.vm.esrt.cloud.sbrf.ru and will be processed within 10 seconds
    Reload request received for member tkles-pprb00053.vm.esrt.cloud.sbrf.ru and will be processed within 10 seconds
    ```

    ```bash
    postgres$ psql
    postgres=# show archive_timeout;
    ```

    > *Ожидаемый результат*<br>Параметры перезачитаны: после `reload` команда `show` выводит обновленное значение:<br>
    >
```text    
archive_timeout
179s
(1 row)
```

#### Сценарий «Функционирование в режиме отказоустойчивого кластера: физическая репликация данных и автоматическое переключение клиентских приложений на реплику в случае аварии: автоматическое восстановление сервиса после одиночного сбоя»

1.  Сэмулировать одиночный сбой `patroni` с помощью команды `kill` на ведущем узле.

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo kill -9 $(ps aux | grep patroni | grep -v grep | grep -v psql | awk '{print$2}')
    ```

    Сразу же после выполнения этой команды выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ list
    ```

    > *Ожидаемый результат*<br>После получения сигнала `SIGKILL` сервис останавливается и сразу же автоматически восстанавливается. Ведущий и ведомый узлы не переключаются.

2.  Сэмулировать одиночный сбой `patroni` с помощью команды `kill` на ведомом узле.

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    root$ sudo kill -9 $(ps aux | grep patroni | grep -v grep | grep -v psql | awk '{print$2}')
    ```

    Сразу же после выполнения этой команды выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ list
    ```

    > *Ожидаемый результат*<br>После получения сигнала `SIGKILL` сервис останавливается и сразу же автоматически восстанавливается. Ведущий и ведомый узлы не переключаются.

3. Сэмулировать одиночный сбой `postgres` с помощью команды `kill` на ведущем узле.

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo kill -9 $(ps aux | grep postgresql | grep -v grep | awk '{print$2}')
    ```

    Сразу же после выполнения этой команды вполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ list
    ```

    > *Ожидаемый результат*<br>`patroni` заметил нештатное завершение `postgresql` и автоматически восстанавливает его.<br>
    Ведомый узел не заметил проблем с ведущим (TL увеличился).

4. Сэмулировать одиночный сбой `postgres` с помощью команды `kill` на ведомом узле. Выполнить на узле `$REPLICA_HOST`:

    ```SQL
    root$ sudo kill -9 $(ps aux | grep postgresql | grep -v grep | awk '{print$2}')
    ```

    Сразу же после выполнения этой команды выполнить на узле `$REPLICA_HOST`:

    ```SQL
    postgres$ list
    ```

    > *Ожидаемый результат*<br>`patroni` заметил нештатное завершение `postgresql` и автоматически восстанавливает его. Ведущий узел не заметил проблем с ведомым.

#### Сценарий «Функционирование в режиме отказоустойчивого кластера: физическая репликация данных и автоматическое переключение клиентских приложений на реплику в случае аварии: создание парольной политики пользователей»

1. Попытаться создать пользователя c паролем, не соответствующем критериям сложности пароля, затем создать пользователя с соответствующим критериям паролем.

    Открыть `psql` на узле `$REPLICA_HOST` и выполнить sql код:

    ```SQL
    CREATE USER user1 WITH ENCRYPTED PASSWORD '12345678'; # ошибка
    CREATE USER user1 WITH ENCRYPTED PASSWORD 'Temptestpass123!';
    ```

    > *Ожидаемый результат*<br>Первая команда: `ERROR:  Syntax check fail: minimum length for password is 16`

2.  Добавить политику для пользователя.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    select * from set_role_policies('user1', min_length('1'), check_syntax('1'), policy_enable('1'), check_syntax('1'), max_failure(1), lockout(True));
    ```

    > *Ожидаемый результат*<br>Политика добавлена.

3. Вывести политику для пользователя, вывести детализированную политику, вывести все политики.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    select * from recognize_password_policy('user1');
    select * from recognize_password_policy_detailed('user1');
    select select_all_password_policies();
    ```

    > *Ожидаемый результат*<br>Команды отработали, политика выведена:<br>
    >
```text
select_all_password_policies
(user1,,,,,,,,t,,1,,t,1,,,,,,,,t,,,,,)
(1 row)
```

4.  Деактивировать политику для пользователя. Проверить, что политика для пользователя  деактивирована.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    select * from disable_policy('user1');
    ```

    > *Ожидаемый результат*<br>Политика деактивирована.

5. Активировать политику для пользователя и аналогично проверить.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    select * from enable_policy('user1');
    select * from recognize_password_policy_detailed('user1');
    ```

    > *Ожидаемый результат*<br>Политика активирована.

6. Установить политику, при которой пароль можно менять не чаще чем через 10 секунд; история паролей хранит 2 пароля в течение 20 секунд; и убедиться в выполнении этой политики.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    select * from set_role_policies('user1', min_length('1'), check_syntax('1'), policy_enable('1'), check_syntax('1'), max_failure(1), lockout(True), in_history(2), reuse_time('20 sec'), min_age('10 sec'));
    ALTER ROLE user1 WITH PASSWORD 'Temptestpass1234!'; # пароль сменен
    ALTER ROLE user1 WITH PASSWORD 'Temptestpass1235!'; # ошибка - частая смена папроля
    ALTER ROLE user1 WITH PASSWORD 'Temptestpass123!'; # ошибка - пароль уже использовался
    ALTER ROLE user1 WITH PASSWORD 'Temptestpass123!1'; # пароль сменен
    ```

    > *Ожидаемый результат*<br>Новая политика активирована.

7.  Создать политику блокирующего пользователя на 10 секунд при одном неправильном вводе пароля. Заблокировать пользоваля, убедиться, что через 10 секунд пользователь будет разблокирован.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    select * from set_role_policies('user1', min_length('1'), check_syntax('1'), policy_enable('1'), check_syntax('1'), max_failure(1), lockout(True), in_history(2), reuse_time('20 sec'), min_age('10 sec'), lockout_duration('10 sec'));
    ```

    Выполнить на узле `$MASTER_HOST`:

    ```SQL
    # при вводе неверного пароля пользователь заблокируется
    PGPASSWORD='wrong_pass' psql -U user1 
    ```

    Подождать 10 секунд.

    ```SQL
    # с верным паролем удалось подключиться.
    PGPASSWORD='Temptestpass123!1' psql -U user1 
    ```

    > *Ожидаемый результат*<br>Политика создана, роль заблокирована при неуспешной попытке коннекции.
    >
```text
PGPASSWORD='wrong_pass' psql -U user1
psql: FATAL:  password authentication failed for user "user1"
FATAL:  Role is blocked due to fail authentication attempts
```
    >
    > Через 10 секунд с верным паролем коннекция проходит:
    >
```text
PGPASSWORD='Temptestpass123!1' psql -U user1
postgres=>
```

8.  Создать политику, блокирующую пользователя через 10 секунд неактивности, разблокировать пользователя вручную.

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    ALTER ROLE user1 WITH PASSWORD 'Temptestpass123!2';
    select * from set_role_policies('user1', min_length('1'), check_syntax('1'), policy_enable('1'), check_syntax('1'), max_failure(1), lockout(True), in_history(2), reuse_time('20 sec'), min_age('10 sec'), max_inactivity('10 sec'), track_login('1'));
    # Выполнить на узле `$MASTER_HOST`:
    PGPASSWORD='Temptestpass123!2' psql -U user1 # c верным паролем подключение успешно
    # Подождать 15 секунд
    PGPASSWORD='Temptestpass123!2' psql -U user1 # пользователь заблокирован
    ```

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    select * from unblock_role('user1');
    ```

    > *Ожидаемый результат*<br>Политика создана, пользователь заблокирован после указанного периода неактивности. 
    >
```text
FATAL:  Role is blocked due to long inactivity
FATAL:  Role is blocked due to long inactivity
## Разблокировка вручную проходит успешно
```

9.  Создать политику, выставляющую срок действия пароля, и убедиться, что выводится предупреждение об окончании действия пароля:

    ```SQL
    ALTER ROLE user1 WITH PASSWORD 'Temptestpass123!3';
    select * from set_role_policies('user1', max_age('70 sec'), expire_warning('30 sec'), grace_login_time_limit('0'), policy_enable('1'), check_syntax('1'));
    ```

    Войти под пользователем user1:

    ```SQL
    PGPASSWORD='Temptestpass123!3' psql -U user1
    ```

    Подождать 40 секунд и залогиниться снова под пользователем user1 


    ```SQL
    PGPASSWORD='Temptestpass123!3' psql -U user1
    ```

    > *Ожидаемый результат*<br>При втором логине появляется сообщение:<br> 
    `WARNING: Password will expire in`

10. Добавление политики, проверяющей сложность пароля с помощью библиотеки `zxcvbn`:

    ```SQL
    select * from set_role_policies('user1', use_password_strength_estimator('1'), password_strength_estimator_score(1), check_syntax('1'), policy_enable('1'));
    ALTER USER user1 WITH ENCRYPTED PASSWORD '12345679'; # пароль не применен, ненадежный
    ALTER USER user1 WITH ENCRYPTED PASSWORD '165A!@qwert'; # пароль применен, надежный\
    ```

    > *Ожидаемый результат*<br>Политика создана и применена. При попытке создания пользователя с паролем, не проходящим проверку, выводится сообщение:
    >
```text
ERROR:  Syntax check fail: minimum number of special characters for password is 1
Syntax check fail: minimum number of uppercase characters for password is 1
## Вторая команда проходит успешно
```

11. Добавление политики, проверяющей сложность пароля с помощью библиотеки `cracklib`:

    ```SQL
    select * from set_role_policies('user1', illegal_values('1'), alpha_numeric('0'), check_syntax('1'), policy_enable('1'));
    ALTER USER user1 WITH ENCRYPTED PASSWORD 'zone5678'; - пароль не применен, ненадежный
    ALTER USER user1 WITH ENCRYPTED PASSWORD 'AAabv()!_222cc'; - пароль применен, надежный
    ```

    > *Ожидаемый результат*<br>Политика создана и применена. При попытке создания пользователя с паролем, не проходящим проверку, выводится сообщение:
    >
```text
ERROR:  Syntax check fail: minimum number of special characters for password is 1
Syntax check fail: minimum number of uppercase characters for password is 1
## Вторая команда проходит успешно
```

#### Сценарий «Функционирование в режиме отказоустойчивого кластера: физическая репликация данных и автоматическое переключение клиентских приложений на реплику в случае аварии: обеспечение аудита действий пользователей»

1.  Настроить логирование pgaudit для роли:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:
    
    ```sql
    CREATE EXTENSION IF NOT EXISTS pgaudit;
    CREATE USER user1 WITH ENCRYPTED PASSWORD 'Temptestpass123!';
    ALTER ROLE user1 WITH superuser;
    ALTER ROLE user1 SET pgaudit.log = 'ddl';
    ```

    > *Ожидаемый результат*<br> Логирование настроено, роль создана.

2.  Выполнить запросы:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```sql
    CREATE TABLE public.foo(data text);
    INSERT INTO public.foo VALUES('test sentence');
    SELECT * FROM public.foo;
    UPDATE public.foo SET data = 2;
    DELETE FROM public.foo;
    show search_path;
    set search_path='public';
    CREATE ROLE r1;
    ```

    > *Ожидаемый результат*<br> Запросы выполнены:
    >
```text
CREATE TABLE
INSERT 0 1
    data      
---------------
test sentence
(1 row)
UPDATE 1
DELETE 1
search_path 
-------------
public
1 row)
SET
CREATE ROLE
```

3.  Проверить лог на наличие сообщения:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ cat $pgdata/current_logfiles
    ```

    Получаем, например:
    
    ```bash
    # копируем путь к файлу лога
    stderr /pgerrorlogs/postgresql-2020-12-02_000000.log`
    #выполняем поиск по этому логу сообщений от Аудита
    postgres$ cat /pgerrorlogs/postgresql-2020-12-02_000000.log |grep AUDIT
    ```

    > *Ожидаемый результат*<br> Вывод в лог сообщения от `pgaudit`: `LOG: AUDIT: SESSION,1,1,DDL,CREATE TABLE,TABLE,public.foo,CREATE TABLE public.foo(data text);,<not logged>`

4.  Настроить логирование `pgaudit` для роли:

    выполняем поиск по этому логу сообщений от Аудита

    ```SQL
    ALTER ROLE user1 SET pgaudit.log = 'read';
    ```

    > *Ожидаемый результат*<br> Логирование настроено

5.  Выполнить запросы:

    Выполнить на узле `$MASTER_HOST`:

    ```sql
    PGPASSWORD='Temptestpass123!' psql -U user1
    CREATE TABLE public.foo1(data text);
    INSERT INTO public.foo1 VALUES('test sentence');
    SELECT * FROM public.foo1;
    UPDATE public.foo1 SET data = 2;
    DELETE FROM public.foo1;
    show search_path;
    set search_path='public';
    CREATE ROLE r2;
    ```

    > *Ожидаемый результат*<br> Запросы выполнены:
    > 
```text
CREATE TABLE
INSERT 0 1
    data      
---------------
 test sentence
(1 row)
UPDATE 1
DELETE 1
search_path 
-------------
 public
(1 row)
SET
CREATE ROLE
```

6.  Проверить лог на наличие сообщения.

    > *Ожидаемый результат*<br> Вывод в лог сообщения от `pgaudit`: `LOG: AUDIT: SESSION,1,1,READ,SELECT,,,SELECT * FROM public.foo1;,<not logged>`

7.  Настроить логирование `pgaudit` для роли:

    ```SQL
    ALTER ROLE user1 SET pgaudit.log = 'write';
    ```

    > *Ожидаемый результат*<br>Логирование настроено

8.  Выполнить запросы :

    Выполнить на узле `$MASTER_HOST`:

    ```sql
    PGPASSWORD='Temptestpass123!' psql -U user1
    CREATE TABLE public.foo3(data text);
    INSERT INTO public.foo3 VALUES('test sentence');
    SELECT * FROM public.foo3;
    UPDATE public.foo3 SET data = 2;
    DELETE FROM public.foo3;
    show search_path;
    set search_path='public';
    CREATE ROLE r3;
    ```

    > *Ожидаемый результат*<br> Команды выполнены:
    >
```text
CREATE TABLE
INSERT 0 1
    data      
---------------
 test sentence
(1 row)
UPDATE 1
DELETE 1
search_path 
-------------
 public
(1 row)
SET
CREATE ROLE
```

9.  Проверить лог на наличие сообщения.

    > *Ожидаемый результат*<br> Вывод в лог сообщения от `pgaudit`:
    >
```text
LOG:  AUDIT: SESSION,1,1,WRITE,INSERT,,,INSERT INTO public.foo3 VALUES('test sentence');,<not logged>
LOG:  AUDIT: SESSION,2,1,WRITE,UPDATE,,,UPDATE public.foo3 SET data = 2;,<not logged>
LOG:  AUDIT: SESSION,3,1,WRITE,DELETE,,,DELETE FROM public.foo3;,<not logged>
```

10. Настроить логирование pgaudit для роли:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    ALTER ROLE user1 SET pgaudit.log ='MISC_SET';
    ```

    > *Ожидаемый результат*<br> Логирование настроено

11. Выполнить запросы :
    
    Выполнить на узле `$MASTER_HOST`:

    ```sql
    PGPASSWORD='Temptestpass123!' psql -U user1
    CREATE TABLE public.foo4(data text);
    INSERT INTO public.foo4 VALUES('test sentence');
    SELECT * FROM public.foo4;
    UPDATE public.foo4 SET data = 2;
    DELETE FROM public.foo4;
    show search_path;
    set search_path='public';
    CREATE ROLE r4;
    ```

    > *Ожидаемый результат*<br> Запросы выполнены:
    >
```text
CREATE TABLE
INSERT 0 1
    data      
---------------
 test sentence
(1 row)
UPDATE 1
DELETE 1
search_path 
-------------
 public
(1 row)
SET
CREATE ROLE
```

12. Проверить лог на наличие сообщения.

    > *Ожидаемый результат*<br> Вывод в лог сообщения от `pgaudit`: `AUDIT: SESSION,1,1,MISC,SET,,,set search_path='public';,<not logged>`

13. Настроить логирование pgaudit для роли:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    ALTER ROLE user1 SET pgaudit.log='role';
    ```

    > *Ожидаемый результат*<br> Логирование настроено.

14. Выполнить запросы :

    Выполнить на узле `$MASTER_HOST`:

    ```sql
    PGPASSWORD='Temptestpass123!' psql -U user1
    CREATE TABLE public.foo5(data text);
    INSERT INTO public.foo5 VALUES('test sentence');
    SELECT * FROM public.foo5;
    UPDATE public.foo5 SET data = 2;
    DELETE FROM public.foo5;
    show search_path;
    set search_path='public';
    CREATE ROLE r5;
    ```

    > *Ожидаемый результат*<br> Запросы выполнены:
    >
```text
CREATE TABLE
INSERT 0 1
    data      
---------------
 test sentence
(1 row)
UPDATE 1
DELETE 1
search_path 
-------------
 public
(1 row)
SET
CREATE ROLE
```

15. Проверить лог на наличие сообщения.

    > *Ожидаемый результат*<br> Вывод в лог сообщения от `pgaudit`: `LOG: AUDIT: SESSION,1,1,ROLE,CREATE ROLE,,,CREATE ROLE r5;,<not logged>`

16. Попробовать выставить логирование не под пользователем администратора СУБД:
    
    ```sql
    CREATE USER user2 WITH ENCRYPTED PASSWORD 'Temptestpass123!';
    PGPASSWORD='Temptestpass123!' psql -U user2
    ALTER ROLE user1 SET pgaudit.log='role';
    ```

    > *Ожидаемый результат*<br> `ERROR:  permission denied to set parameter "pgaudit.log"`

#### Сценарий «Функционирование в режиме отказоустойчивого кластера: физическая репликация данных и автоматическое переключение клиентских приложений на реплику в случае аварии: получение показателей, связанных с функциональностью»

Выполнить функции проверки активности функциональностей:

Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

```SQL
select * from check_password_policy_is_on();
select * from check_pg_audit_is_on();
select * from check_tde_is_on();
```

> *Ожидаемый результат*<br>Получены показатели, связанные с функциональностью:
> 
> Парольные политики:
>
```text
check_password_policy_is_on
----------------------------- 
 t
(1 row)
 Аудит:
 check_pg_audit_is_on
----------------------
 t
(1 row)
 Прозрачное шифрование:
 check_tde_is_on
-----------------
 t
(1 row)
```

### Проверка функции «Возможность снятия резервной копии со standby-базы»

#### Сценарий «Возможность снятие резервной копии со standby-базы»

1.  Создать базу данных и наполнить ее данными на ведущем узле.

    ```sql
    CREATE TABLESPACE table_space LOCATION '/pgdata/ts_location' WITH (is_encrypted = on);
    CREATE TABLE a_table (a text) TABLESPACE table_space;
    INSERT INTO a_table VALUES ('test sentence');
    CREATE TABLE b_table (b text);
    INSERT INTO b_table VALUES ('test sentence1');
    ```

    > *Ожидаемый результат*<br> База создана  и наполнена данными.

2.  Проверить наличие данных на ведомом узле.

    ```sql
    select * from a_table ;
    select * from b_table;
    ```

    > *Ожидаемый результат*<br> Данные на ведомом узле присутствуют, сработала репликация, шифрованные данные корректно среплицированы
    >
```text
       a      
---------------
 test sentence
       b       
----------------
 test sentence1
```

3.  Создать резервную бинарную копию на ведущем узле с ведомого узла:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ pg_basebackup -h $REPLICA_HOST -p $DB_PORT -D /home/postgres/backup -Ft -z -Xf -v
    ```

    > *Ожидаемый результат*<br> Резервная копия создана успешно: `pg_basebackup: base backup completed`

4.  Выполнить восстановление из резервной бинарной копии на ведущем узле (директории табличных пространств тоже должны быть очищены):

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ sudo systemctl stop patroni
    postgres$ rm -rf $PGDATA/*
    postgres$ rm -rf /pgdata/ts_location/*
    postgres$ tar xzf /home/postgres/backup/base.tar.gz -C $PGDATA
    postgres$  tar xzf /home/postgres/backup/$TS.tar.gz -C /pgdata/ts_location
    postgres$ auto_setup_kms_credentials --config_path /$PGDATA/enc_connection_settings.cfg --ip $KMS_HOST --port 8200 --login adminencryption --password qwerty
    postgres$ sudo systemctl start patroni
    ```

    > *Ожидаемый результат*<br> Восстановление выполнено успешно.

5.  Проверить доступность БД и данных в ней после восстановления на "старом" ведущем узле:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ list
    postgres$ psql
    select * from a_table;
    select * from b_table;
    ```

    > *Ожидаемый результат*<br> БД после восстановления полностью работоспособна и содержит данные, находящиеся в БД до снятия резервной бинарной копии:
    >
```text
State:  running  
       a      
---------------
 test sentence
(1 row)
 
       b       
----------------
 test sentence1
```

### Проверка функции «Защита  данных от привилегированных пользователей (администраторов баз данных)»

#### Сценарий «Защита  данных от привилегированных пользователей (администраторов баз данных): обеспечение защиты параметров от привилегированных пользователей»

1.  В `/etc/patroni/postgres.yml` поменять значение `pg_hba` на отличное от значения в защищенном хранилище и рестартовать базу:

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    pg_hba:
    new
    postgres$ reload
    postgres$ restart
    postgres$ list
    postgres$ psql
    show pg_hba_conf;
    ```

    > *Ожидаемый результат*<br> База рестартовала корректно, локальный параметр игнорируется, актуальные данные берутся из защищенного хранилища: после рестарта команда `show pg_hba_conf;` показывает исходное значение.

2.  В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение `ssl_ca_file` на отличное от значения в защищенном хранилище, выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    ssl_ca_file:
    new
    postgres$ reload
    postgres$ restart
    postgres$ list
    postgres$ psql
    show ssl_ca_file;
    ```

    > *Ожидаемый результат*<br> База рестартовала корректно, локальный параметр игнорируется, актуальные данные берутся из защищенного хранилища: после рестарта команда `show ssl_ca_file;` показывает исходное значение.

3.  В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение `ssl_cert_file` на отличное от значения в защищенном хранилище, выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    ssl_cert_file:
    new
    postgres$ reload
    postgres$ restart
    postgres$ list
    postgres$ psql
    show ssl_cert_file;
    ```

    > *Ожидаемый результат*<br> База рестартовала корректно, локальный параметр игнорируется, актуальные данные берутся из защищенного хранилища: после рестарта команда `show ssl_cert_file;` показывает исходное значение.

4.  В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение `ssl_crl_file` на отличное от значения в защищенном хранилище, выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    ssl_crl_file:
    new
    postgres$ reload
    postgres$ restart
    postgres$ list
    postgres$ psql
    show ssl_crl_file;
    ```

    > *Ожидаемый результат*<br> База рестартовала корректно, локальный параметр игнорируется, актуальные данные берутся из защищенного хранилища: после рестарта команда `show ssl_crl_file;` показывает исходное значение.

5.  В /etc/patroni/postgres.yml вернуть предыдущий параметр в исходное значение и поменять значение `ssl_key_file` на отличное от значения в защищенном хранилище, выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    ssl_key_file:
    new
    postgres$ reload
    postgres$ restart
    postgres$ list
    postgres$ psql
    show ssl_key_file;
    ```

    > *Ожидаемый результат*<br> База рестартовала корректно, локальный параметр игнорируется, актуальные данные берутся из защищенного хранилища: после рестарта команда `show ssl_crl_file;` показывает исходное значение.

6.  В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение `ssl_ciphers` на отличное от значения в защищенном хранилище, выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    ssl_ciphers:
    new
    postgres$ reload
    postgres$ restart
    postgres$ list
    postgres$ psql
    show ssl_ciphers;
    ```

    > *Ожидаемый результат*<br> База рестартовала корректно, локальный параметр игнорируется, актуальные данные берутся из защищенного хранилища: после рестарта команда `show ssl_key_file;` показывает исходное значение.

7.  В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение `ssl_prefer_server_ciphers` на отличное от значения в защищенном хранилище, выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    ssl_prefer_server_ciphers:
    off
    postgres$ reload
    postgres$ restart
    postgres$ list
    postgres$ psql
    show ssl_prefer_server_ciphers;
    ```

    > *Ожидаемый результат*<br> База рестартовала корректно, локальный параметр игнорируется, актуальные данные берутся из защищенного хранилища: после рестарта команда `show ssl_prefer_server_ciphers;` показывает исходное значение.

8.  В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение `ssl_ecdh_curve` на отличное от значения в защищенном хранилище, выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    ssl_ecdh_curve:
    new
    postgres$ reload
    postgres$ restart
    postgres$ list
    postgres$ psql
    show ssl_ecdh_curve;
    ssl_dh_params_file
    ```

    > *Ожидаемый результат*<br> База рестартовала корректно, локальный параметр игнорируется, актуальные данные берутся из защищенного хранилища: после рестарта команда `show ssl_ecdh_curve;` показывает исходное значение.

9.  В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение `ssl_dh_params_file` на отличное от значения в защищенном хранилище, выполнить перезачитывание параметров `postgresql patroni`:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    ssl_dh_params_file:
    new
    postgres$ reload
    postgres$ restart
    postgres$ list
    postgres$ psql
    show ssl_dh_params_file;
    ```

    > *Ожидаемый результат*<br> База рестартовала корректно, локальный параметр игнорируется, актуальные данные берутся из защищенного хранилища: после рестарта команда `show ssl_dh_params_file;` показывает исходное значение.

10. В `/etc/patroni/postgres.yml` поменять значение параметра `password_encryption` и выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    password_encryption: scram-sha-256
    postgres$ reload
    postgres$ restart
    postgres$ list
    ```

    > *Ожидаемый результат*<br> База не рестартует, параметр должен совпадать локально и в защищенном хранилище, т.к. он помещен под защиту.

11. В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение параметра `ssl` и выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    ssl: off
    postgres$ reload
    postgres$ restart
    postgres$ list
    ```

    > *Ожидаемый результат*<br> База не рестартует, параметр должен совпадать локально и в защищенном хранилище, т.к. он помещен под защиту.

12. В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение параметра `dynamic_library_path` и выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    dynamic_library_path: new_value
    postgres$ reload
    postgres$ restart
    postgres$ list
    ```

    > *Ожидаемый результат*<br> База не рестартует, параметр должен совпадать локально и в защищенном хранилище, т.к. он помещен под защиту.

13. В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение параметра `shared_preload_libraries` и выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    shared_preload_libraries: new_value
    postgres$ reload
    postgres$ restart
    postgres$ list
    ```

    > *Ожидаемый результат*<br> База не рестартует, параметр должен совпадать локально и в защищенном хранилище, т.к. он помещен под защиту.

14. В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение параметра `jit_provider` и выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    jit_provider: new_value
    postgres$ reload
    postgres$ restart
    postgres$ list
    ```

    > *Ожидаемый результат*<br> База не рестартует, параметр должен совпадать локально и в защищенном хранилище, т.к. он помещен под защиту.

15. В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение параметра `is_tde_on` и выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    is_tde_on: off
    postgres$ reload
    postgres$ restart
    postgres$ list
    ```

    > *Ожидаемый результат*<br> База не рестартует, параметр должен совпадать локально и в защищенном хранилище, т.к. он помещен под защиту.

16. В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение параметра `allowed_servers` и выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    allowed_servers: new_value
    postgres$ sudo systemctl restart patroni
    postgres$ list
    ```

    > *Ожидаемый результат*<br> База не рестартует, параметр должен совпадать локально и в защищенном хранилище, т.к. он помещен под защиту.

17. В `/etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и поменять значение параметра `ssl_passphrase_command` и выполнить перезачитывание параметров postgresql:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    ssl_passphrase_command: new_value
    postgres$ reload
    postgres$ restart
    postgres$ list
    ```

    > *Ожидаемый результат*<br> База не рестартует, параметр должен совпадать локально и в защищенном хранилище, т.к. он помещен под защиту.

18. В /`etc/patroni/postgres.yml` вернуть предыдущий параметр в исходное значение и в защищенном хранилище поменять значение (в веб-версии или в консоли) параметра `password_encryption` и рестартовать базу:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request GET https://$KMS_HOST:8200/v1/kv/data/postgresql/1/postgresql/password_encryption
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request POST --data '{"data": {"value": "scram-sha-256"}}' https://$KMS_HOST:8200/v1/kv/data/postgresql/1/postgresql/password_encryption

    postgres$ restart
    postgres$ list
    ```

    > *Ожидаемый результат*<br> База не рестартует, параметр должен совпадать локально и в защищенном хранилище, т.к. он помещен под защиту.

19. Вернуть исходное значение для предыдущего параметра и выполнить изменение параметров в защищенном хранилище (в веб-версии или в консоли) для следующих параметров, аналогично пункту 18:

    -   `ssl` выставить: off 
    -   `dynamic_library_path` выставить: new
    -   `shared_preload_libraries` выставить: new
    -   `jit_provider` выставить: new
    -   `is_tde_on` выставить: off 
    -   `allowed_servers` выставить: new
    -   `ssl_passphrase_command` выставить: new

    > *Ожидаемый результат*<br> База не рестартует, параметр должен совпадать локально и в защищенном хранилище, т.к. он помещен под защиту.

20. Поменять значение параметра `pg_hba` на некорректное  в защищенном хранилище (в веб-версии или в консоли) и рестартовать БД:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request GET https://$KMS_HOST:8200/v1/kv/data/postgresql/1/postgresql/pg_hba
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request POST --data '{"data": {"value": "вамтватмва"}}' https://$KMS_HOST:8200/v1/kv/data/postgresql/1/postgresql/pg_hba

    postgres$ restart
    postgres$ list
    ```

    > *Ожидаемый результат*<br> БД не стартует, параметры применились из защищенного хранилища, они некорректные (проверить лог postgres)

21. Вернуть исходное значение для предыдущего параметра и выполнить изменение параметров в защищенном хранилище (в веб-версии или в консоли) для следующих параметров, аналогично пункту 20 (некорректное значение - кириллица):

    -   `ssl_ca_file`
    -   `ssl_cert_file`
    -   `ssl_crl_file`
    -   `ssl_key_file`
    -   `ssl_ciphers`
    -   `ssl_prefer_server_ciphers`
    -   `ssl_ecdh_curve`
    -   `ssl_dh_params_file`

    > *Ожидаемый результат*<br> БД не стартует, параметры применились из защищенного хранилища, они некорректные (проверить лог postgres) 

#### Сценарий «Защита данных от привилегированных пользователей (администраторов баз данных): обеспечение защиты данных от привилегированных пользователей»

1. Создать тестовые данные под пользователем администратора СУБД:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ psql -U postgres
    ```

    и выполнить sql код:
    
    ```sql
    CREATE TABLE foo(data text);
    INSERT INTO foo VALUES('test sentence');
    SELECT * FROM foo;
    ```

    > *Ожидаемый результат*<br> Данные созданы.

2.  Создать второго админа безопасности `sec_admin2` под пользователем администратора СУБД:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ psql -U postgres
    ```

    ```sql
    CREATE USER sec_admin2 with password 'sec12345!adminSEC';
    ```

    > *Ожидаемый результат*<br> Админ безопасности `sec_admin2` создан.

3. Под `sec_admin` помещаем пользователя `sec_admin2` под защиту, чтобы его нельзя было изменить/удалить, и выдаем ему права админа безопасности:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ PGPASSWORD='Supersecadmin$1234' psql -U sec_admin
    ```

    и выполнить sql код:

    ```sql
    SELECT pm_protect_object('postgres', 'role', 'sec_admin2');
    SELECT pm_grant_security_admin('sec_admin2');
    ```

    > *Ожидаемый результат*<br> sec_admin2 помещен под защиту, права выданы:
    >
```text
 pm_protect_object
-------------------
 t
 pm_grant_security_admin
-------------------------
 t
```

4. Под новым пользователем sec_admin2 добавляем таблицу под защиту:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ PGPASSWORD='sec12345!adminSEC' psql -U sec_admin2
    ```

    и выполнить sql код:

    ```sql
    SELECT pm_protect_object('postgres', 'table', 'foo');
    # Создаем политику
    SELECT pm_make_policy('foo_policy');
    # Грантуем в бд селекты из таблицы для созданной политики
    SELECT pm_grant_to_policy('foo_policy', 'postgres', 'table', 'foo', array['select']::name[]);
    # Связываем политику с пользователем
    SELECT pm_assign_policy_to_user('postgres', 'foo_policy');
    # Проверяем гранты
    SELECT pm_get_policy_grants('foo_policy');
    ```

    > *Ожидаемый результат*<br> Таблица помещена под защиту, запросы успешно выполнены:
    >
```text
          pm_get_policy_grants          
-----------------------------------------
 (13291,postgres,16481,foo,table,select)
```

5.  Пробуем добавить данные в таблицу под пользователем администратора СУБД:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ psql -U postgres
    ```

    и выполнить sql код:

    ```sql
    INSERT INTO foo VALUES('test sentence2');
    SELECT * FROM foo;
    ```

    > *Ожидаемый результат*<br> Добавление данных проходит неуспешно: у пользователя теперь нет прав на это.
    >
    > Селект выводит исходное содержимое таблицы.
    >
```text
ERROR:  Action for relation is forbidden
     data     
---------------
 test sentence
```

6.  Пробуем выполнить под пользователем администратора СУБД команды, доступные только администратору безопасности:

    Выполнить на узле $MASTER_HOST6

    ```bash
    postgres$ psql -U postgres
    ```

    и выполнить sql код:

    ```sql
    SELECT pm_revoke_from_policy('foo_policy', 'postgres', 'table', 'foo', array['select']::name[]);
    SELECT pm_unassign_policy_from_user('postgres', 'foo_policy');
    SELECT pm_unprotect_object('postgres', 'table', 'foo');
    SELECT pm_unprotect_object('postgres', 'role', 'sec_admin2');
    SELECT pm_revoke_security_admin('sec_admin2');
    DROP USER sec_admin2;
    ```

    > *Ожидаемый результат*<br> Ни одна команда не выполнена: у пользователя нет доступа к функциям API управления механизмом защиты данных, учетным записеям пользователей-администраторов безопасности, объектам, хранящим данные механизма защиты данных: `ERROR:  Action on function is forbidden`

7.  Под `sec_admin` удаляем связь политики с пользователем, очищаем политики, снимаем защиту с объектов и ролей:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ PGPASSWORD='Supersecadmin$1234' psql -U sec_admin
    ```

    и выполнить sql код:

    ```sql
    SELECT pm_revoke_from_policy('foo_policy', 'postgres', 'table', 'foo', array['select']::name[]);
    SELECT pm_unassign_policy_from_user('postgres', 'foo_policy');
    SELECT pm_unprotect_object('postgres', 'table', 'foo');
    SELECT pm_unprotect_object('postgres', 'role', 'sec_admin2');
    SELECT pm_revoke_security_admin('sec_admin2');
    ```

    > *Ожидаемый результат*<br> Политики очищены, связь объектов удалена, защита снята, запросы выполнены успешно.

8.  Снова пробуем добавить данные в таблицу под пользователем администратора СУБД:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ psql -U postgres
    ```

    и выполнить sql код:

    ```sql
    INSERT INTO foo VALUES('test sentence2');
    SELECT * FROM foo;
    ```

    > *Ожидаемый результат*<br> Данные добавлены успешно, Селект выводит обновленное содержимое таблицы:
    >
```text
      data     
----------------
 test sentence
 test sentence2
(2 rows)
```

#### Сценарий «Защита данных от привилегированных пользователей (администраторов баз данных): отключение слабых типов аутентификации»

1.  Добавить в защищенное хранилище (в веб-версии или в консоли) параметр `pg_hba='local all all trust'`, предварительно сохранив исходный `pg_hba`:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request GET https://$KMS_HOST:8200/v1/kv/data/postgresql/1/postgresql/pg_hba
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request POST --data '{"data": {"value": "local all all trust"}}' https://$KMS_HOST:8200/v1/kv/data/postgresql/1/postgresql/pg_hba
    ```

    > Параметры выставлены: GET запрос выдает новое значение.

2.  Перезапустить кластер:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    restart
    ```

    > База не рестартует, в логе ошибка: `authentication method "trust" isn't allowed in secure configuration mode`


3.  Вернуть значение `pg_hba` в защищенном хранилище (в веб-версии или в консоли)  в исходное состояние и повторить пункты 1-2 для остальных типов аутентификации (вместо trust подставить поочередно): `password`, `ident`, `peer`.

    > Слабые типы аутентификации отключены, поэтому база не рестартует, в логе ошибки:
    > 
```text
authentication method "password" isn't allowed in secure configuration mode
authentication method "ident" isn't allowed in secure configuration mode
authentication method "peer" isn't allowed in secure configuration mode
```

#### Сценарий «Защита данных от привилегированных пользователей (администраторов баз данных): инициализация механизма защиты данных с помощью вспомогательной утилиты»

1.  В защищенном хранилище (в веб-версии или в консоли) выключить параметров защиту `secure_config=off` (защита параметров выключается для упрощения тестового сценария и возможности запуска утилиты `initdb`):

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request POST --data '{"data": {"value": "off"}}' https://$KMS_HOST:8200/v1/kv/data/postgresql/1/postgresql/secure_config
    ```

    > *Ожидаемый результат*<br> Параметр изменен

2.  Проинициализировать БД во временной директории:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    mkdir ~/tmp_data
    initdb -D ~/tmp_data
    ```

    > *Ожидаемый результат*<br> База успешно проинициализирована: `Success. You can now start the database server using:`

3.  Запустить утилиту инициализации механизма защиты, по запросу ввести пароль администратора безопасности:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    auto_setup_kms_credentials --config_path ~/tmp_data/enc_connection_settings.cfg --ip $KMS_HOST --port 8200 --login adminencryption --password qwerty
    initprotection -D ~/tmp_data -U sec_admin
    Enter new security admin password: sec12345!adminSEC
    Enter it again: sec12345!adminSEC
    ```

    > *Ожидаемый результат*<br> Механизм защиты данных успешно проинициализирован:
    >
```text
running bootstrap script ...
Security catalogs are in the expected state.
Policies and security adminstrator account have been created.
All initialization procedures have been succeed.
performing post-bootstrap initialization ... Protection mechanism is initialized.
syncing data to disk ...
```

4.  Отредактировать файл pg_hba:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    echo "host all all 0.0.0.0/0 trust" >> ~/tmp_data/pg_hba.conf
    ```

    > *Ожидаемый результат*<br> Файл отредактирован.

5.  Запустить БД:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    pg_ctl -D ~/tmp_data -l log -o '-h 0.0.0.0 -p 9999' start
    ```

    > *Ожидаемый результат*<br> База успешно запустилась:
    >
```text
waiting for server to start.... done
server started
```

6.  Убедиться в возможности подключения к БД под ролью администратора безопасности и помещения роли под защиту:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    PGPASSWORD='sec12345!adminSEC' psql -p 9999 -U sec_admin
    ```
    
    и выполнить sql код:

    ```sql
    SELECT * FROM pm_get_protected_objects() where object_name = 'sec_admin'
    ```

    > *Ожидаемый результат*<br> Подключение прошло успешно, роль администратора безопасности помещена под защиту:
    >
```text
postgres-> ;
 sec_admin   | role        | t
(1 row)
```

7.  Остановить БД, очистить директорию, включить защиту параметров в защищенном хранилище (в веб-версии или в консоли):

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    pg_ctl -D ~/tmp_data -l log stop
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request POST --data '{"data": {"value": "on"}}' https://$KMS_HOST:8200/v1/kv/data/postgresql/1/postgresql/secure_config
    ```

    > *Ожидаемый результат*<br> База остановлена, параметр изменен.

### Проверка функции «Прозрачное шифрование данных, включая интеграцию с системами класса key management для хранения мастер-ключей»

#### Сценарий «Прозрачное шифрование данных, включая интеграцию с системами класса key management для хранения мастер-ключей: шифрование файлов данных, интеграция с защищенным хранилищем»

1.  Создать шифрованное табличное пространство, в нем таблицу  и внести тестовые данные. Для сравнения создать нешифрованную таблицу:

    Выполнить на узле `$MASTER_HOST`:

    ```SQL
    postgres$ psql
    CREATE TABLESPACE a_table_space_on LOCATION $table_space_location WITH (is_encrypted = on);
    CREATE TABLE a_table_on (a text) TABLESPACE a_table_space_on;
    INSERT INTO a_table_on VALUES ('test1');
    CREATE TABLE b_table (b text);
    INSERT INTO b_table VALUES ('test2');
    checkpoint;
    ```

    > *Ожидаемый результат*<br> Шифрованное табличное пространство создано, таблицы созданы.

2.  Выполнить поиск ранее занесенных тестовых данных по файлам данных на ведущем и ведомом узлах и файлам WAL:

    ```bash
    postgres$ grep -R 'test1' $pgdata/base
    postgres$ grep -R 'test1' $pgdata/pg_wal
    postgres$ grep -R 'test1' $table_space_location
    postgres$ grep -R 'test2' $pgdata/base
    ```

    > *Ожидаемый результат*<br> Зашифрованные данные в открытом виде не обнаружены ни на ведущем, ни на ведомом узле. Обнаружены только данные, созданные в незашифрованной таблице

3.  Создать временную таблицу и внести тестовые данные:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```sql
    CREATE TEMP TABLE temp_table_on (a text) TABLESPACE a_table_space_on;
    INSERT INTO temp_table_on VALUES ('temptest1');
    checkpoint;
    ```

    > *Ожидаемый результат*<br> Временная таблица создана.

4.  Выполнить поиск ранее занесенных тестовых данных по файлам данных на ведущем и ведомом узлах и файлам WAL:

    ```bash
    postgres$ grep -R 'temptest1' $pgdata/base
    postgres$ grep -R 'temptest1' $pgdata/pg_wal
    postgres$ grep -R 'temptest1' $table_space_location
    ```

    > *Ожидаемый результат*<br> Шифрованные данные в открытом виде не обнаружены ни на ведущем, ни на ведомом узле:
    >
```bash
postgres$ grep -R 'temptest1' /pgdata/
```

5.  Выполнить запросы данных созданных таблиц через консоль psql:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    select * from a_table_on;
    select * from temp_table_on;
    ```
    > *Ожидаемый результат*<br> Данные видны в открытом виде, корректно:
    >
```text
       a      
---------------
 test1
     a    
-----------
 temptest1
```

6.  Проверить, что в файле `/PG_DATA/global/enc_keys.json` добавлены записи после создания шифрованных объектов:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ cat $pgdata/global/enc_keys.json
    ```

    > *Ожидаемый результат*<br> После создания шифрованных объектов в файл `$PGDATA/global/enc_keys.json` добавляются ключи шифрования этих объектов.

7.  Запомнить файлы данных таблицы для дальнейшего сравнения:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    SELECT pg_relation_filepath('a_table_on');
    Checkpoint;
    ```

    хатем выполнить команду

    ```bash
    postgres$ cp $relation_filepath $pgdata/file1
    ```

    > *Ожидаемый результат*<br> Файл скопирован для дальнейшего сравнения.

8.  Выполнить смену мастер-ключа :

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    create extension keyring_module;
    SELECT * FROM rotate_master_key();
    checkpoint;
    ```

    > *Ожидаемый результат*<br> Смена мастер-ключа прошла успешно, продемонстирована интеграция с защищенным хранилищем:
    >
```text
rotate_master_key
-------------------
 t
(1 row)
active_master_key_id изменился в файле /pgdata/11/data/global/enc_settings.cfg
```

9.  Сравнить содержимое файлов данных таблицы с ранее снятой копией:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ cp $relation_filepath $pgdata/file2
    postgres$ diff $pgdata/file1 $pgdata/file2 > $pgdata/changes.diff
    postgres$ cat $pgdata/changes.diff
    ```

    > *Ожидаемый результат*<br> Файлы должны совпадать. Смена ключа происходит без перешифрования файлов отношений.
    >
    > `cat changes.diff` - пустой файл

10. Выполнить остальные функции работы с ключами: установку нового ключа:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQl
    SELECT * FROM set_master_key('H6LVS0fpwWWbBuvXRNmbbqatVcAa5c4iYHZP8vAKwwA=');
    checkpoint;
    \q
    ```

    Проверка, что в защищенном хранилище действительно выставлен новый ключ (в веб-версии или в консоли)

    ```bash
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request GET https://$KMS_HOST:8200/v1/kv/data/postgresql/1/keys/actual_master_key -> $result
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request GET https://$KMS_HOST:8200/v1/kv/data/$result
    ```

    > *Ожидаемый результат*<br> В защищенном хранилище действительно выставлен новый ключ, продемонстирована интеграция с защищенным хранилищем:
    >
```text
set_master_key
----------------
 t
(1 row)
11 Продемонстирована интеграция с защищенным хранилищем: reencrypt_keys
----------------
 t
(1 row)
```

11. Выполнить остальные функции работы с ключами: перешифровку ключей:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    SELECT * FROM reencrypt_keys();
    checkpoint;
    ```

    > *Ожидаемый результат*<br> Продемонстирована интеграция с защищенным хранилищем:
    >
```text
reencrypt_keys
--------------
 t
(1 row)
```

12. Выполнить остальные функции работы с ключами: восстановление ключей:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    SELECT * FROM restore_keys();
    checkpoint;
    ```

    > *Ожидаемый результат*<br> Продемонстирована интеграция с защищенным хранилищем:
    >
```text
restore_keys
--------------
 t
(1 row)
```

13. Выполнить смену мастер-ключа непосредственно в защищенном хранилище (в веб-версии или в консоли):

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ cat $pgdata/global/enc_settings.cfg
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request GET https://$KMS_HOST:8200/v1/kv/data/postgresql/1/keys/prev_master_key -> $result
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request POST --data '{"data": {"value": "$result"}}' https://$KMS_HOST:8200/v1/kv/data/postgresql/1/keys/actual_master_key
    ```

    > *Ожидаемый результат*<br> Продемонстирована интеграция с защищенным хранилищем, смена мастер-ключа произведена.

14. Перезагрузить базу:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ restart
    ```

    > *Ожидаемый результат*<br> Успешный рестарт.

15. Проверить, что локально мастер-ключи совпадают с выставленными в защищенном хранилище (в веб-версии или в консоли):

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request GET https://$KMS_HOST:8200/v1/kv/data/postgresql/1/keys/actual_master_key
    postgres$ cat $PGDATA/global/enc_settings.cfg
    ```

    > *Ожидаемый результат*<br> `GET actual_master_key -value:postgresql/1/keys/$MASTER_KEY_VALUE`
    > 
    > В файле `enc_settings.cfg` `active_master_key_id = postgresql/1/keys/$MASTER_KEY_VALUE` – ключи совпадают, актуальный мастер ключ совпадает с ключем установленным в п.13, продемонстирована интеграция с защищенным хранилищем.

#### Сценарий «Прозрачное шифрование данных, включая интеграцию с системами класса key management для хранения мастер-ключей: шифрование временных файлов, используемых для сортировки или слияния данных в операциях над данными»

1.  Выставить параметр в защищенном хранилище (в веб-версии или в консоли) `secure_config=off`:

    ```bash
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request POST --data '{"data": {"value": "off"}}' https://$KMS_HOST:8200/v1/kv/data/postgresql/1/postgresql/secure_config
    ```

    > *Ожидаемый результат*<br> Параметр выставлен.

2. Выставить в конфигурации `/etc/patroni/postgres.yml` на ведущей и ведомой нодах:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    work_mem: '64KB'
    # установить пакет, необходимы для дальнейших действий
    root$ sudo yum install inotify-tools
    ```

    > *Ожидаемый результат*<br> Параметр выставлен.

3.  Выполнить перезачитывание параметров:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ reload
    postgers$ restart
    ```

    > *Ожидаемый результат*<br> Выполнено зачитывание новых параметров, база рестартовала.

4.  Создать зашифрованное табличное пространство, таблицу в зашифрованном табличном пространстве на ведущем узле:

    Выполнить на узле `$MASTER_HOST`:

    ```sql
    CREATE TABLESPACE a_table_space_on LOCATION '/pgdata/ts_location' WITH (is_encrypted=on);
    set temp_tablespaces = a_table_space_on;
    CREATE TABLE a_big_table_on
    (
    id bigint NOT NULL,
    str_field varchar NOT NULL,
    CONSTRAINT a_big_table_on_id_pk PRIMARY KEY (id)
    )
    WITH (
    OIDS=FALSE
    )
    TABLESPACE a_table_space_on;
    ```

    > *Ожидаемый результат*<br> Табличное пространство и таблица созданы.

5.  Создана директория для сохранения временных файлов на ведущем узле:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ mkdir /home/postgres/buffs
    ```

    > *Ожидаемый результат*<br> Директория создана.

6.  Заполнить таблицу данными на ведущем узле:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    create function fill_tables()
    returns void as
    $$
    declare
    cur_id_ bigint;
    begin
    for cur_id_ in 1..300000
    loop
    insert into a_big_table_on(
    id,
    str_field)
    values(
    cur_id_,
    format('test string %I', cur_id_)::varchar);
    end loop;
    end;
    $$
    language plpgsql
    security definer
    set search_path = public, pg_temp;
     
    select * from fill_tables();
    select str_field, count(*) from (select str_field from a_big_table_on order by str_field) x group by str_field;
    ```

    > *Ожидаемый результат*<br> Таблица наполнена.

7.  Запустить скрипт копирования временных файлов на ведущем узле в отдельном окне (скрипт будет работать в фоне):

    ```bash
    postgres$ nano ./temp_script.sh
    #!/bin/bash
     
    while inotifywait -e modify,create /pgdata/ts_location/*/pgsql_tmp;
    do
    cp -Rf /pgdata/ts_location/*/pgsql_tmp /home/postgres/buffs;
    done
    postgres$ chmod +x ./temp_script.sh
    postgres$ ./temp_script.sh
    ```

    > *Ожидаемый результат*<br> Скрипт запущен:
    >
```text
Setting up watches.
Watches established.
```

8.  Выполнить сортировку таблицы на ведущем узле:

    Выполнить на узле `$MASTER_HOST`:

    ```sql
    select str_field, count(*) from (select str_field from a_big_table_on order by str_field) x group by str_field;
    ```

    > *Ожидаемый результат*<br> Сортировка таблицы выполнена.

9.  Остановить выполнение скрипта (`CTRL + Z`) и проверить `Buff` файл на наличие не зашифрованных данных на ведущем узле:

    ```bash
    postgres$ cat /home/postgres/buffs/pgsql_tmp/* | grep "test string"
    ```

    > *Ожидаемый результат*<br> Данные не обнаружены, файл зашифрован.

10. Скачать прикрепленные скрипты: `decrypt_relation_file.py`, `decrypt_wal_dump.py`, `decrypt_wal_file.py` и перенести на ведущий узел и установить необходимые пакеты:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo cp /home/$root/decrypt_relation_file.py /home/postgres/
    root$ sudo cp /home/$root/decrypt_wal_dump.py /home/postgres/
    root$ sudo cp /home/$root/decrypt_wal_file.py /home/postgres/
    root$ sudo cp /home/$root/get_params_from_kms.py /home/postgres/
    root$ sudo chmod +x /home/postgres/decrypt_relation_file.py
    root$ sudo chmod +x /home/postgres/decrypt_wal_dump.py
    root$ sudo chmod +x /home/postgres/decrypt_wal_file.py
    root$ sudo chmod +x /home/postgres/get_params_from_kms.py
    root$ sudo chown postgres:postgres /home/postgres/decrypt_relation_file.py
    root$ sudo chown postgres:postgres /home/postgres/decrypt_wal_dump.py
    root$ sudo chown postgres:postgres /home/postgres/decrypt_wal_file.py
    root$ sudo chown postgres:postgres /home/postgres/get_params_from_kms.py
    root$ sudo pip3 install pycryptodome
    root$ sudo pip3 install requests
    ```

    > *Ожидаемый результат*<br> Файлы и скрипты скопированы, пакеты установлены: `pip3 freeze` – проверить

11. Создать таблицу в шифруемом табличном пространстве и наполнить данными:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    SELECT pg_current_wal_insert_lsn();
    ```

    Получаем, например:

    ```text
     pg_current_wal_insert_lsn
    ---------------------------
     0/730426D8
    ```

    тут важно посмотреть первые цифры после `/`. По этим цифрам будем искать файл WAL

    ```sql
    create table t_enc_on(a integer, b text, c boolean) TABLESPACE a_table_space_on;

    insert into t_enc_on(a,b,c)
    select s.id,
    (select 'test_' || string_agg(x, '')
        from (select chr(ascii('A') + ((random() * id * 25)::integer % 26)::integer)
            from generate_series(1, 2048 + 1)) as y(x)),
           random() < 0.01
    from generate_series(1, 100) as s(id);
    checkpoint;
    select pg_relation_filepath(reltoastrelid)
      from pg_class
        where relname = 't_enc_on'; - скопировать выведенный путь к файлу $FILEPATH
    ```

    > *Ожидаемый результат*<br> Таблица создана и наполнена данными.

12. Запустить скрипт расшифровки файла и проверить, что в расшифрованном файле есть тестовые данные:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ python3 ./decrypt_relation_file.py --ip $KMS_HOST --port 8200 --token $VAULT_TOKEN --cluster_id 1 --file /pgdata/11/data/$FILEPATH --mode 1
    ```

    Получаем:

    ```text
    master_key_base64=RRkQUv8PiwYhYhE/8sAB5wLjhSruzl5nhG4CPxewB5A=
    master_key=b'45191052ff0f8b062162113ff2c001e702e3852aeece5e67846e023f17b00790'
    enc_key_base64=22jg7bbUOci0ifUxukO1x1wXTXvKEHODAcEgDjTRw7M=
    iv=b'23600000ee3300000200000000000000'
    enc_key=b'1873164f7e42d63c54dbcd2acba826897dbcb1364179b6878c9a876fc45bed55'
    Decryption is completed: /pgdata/11/data/pg_tblspc/24599/PG_11_202003221/13294/24611.decrypted
    ```

    смотрим полученный файл

    ```bash
    postgres$ cat /pgdata/11/data/pg_tblspc/24599/PG_11_202003221/13294/24611.decrypted | grep 'test'
    ```

    Получаем: `Binary file (standard input) matches`

    > *Ожидаемый результат*<br> `mode=1` в вызове скрипта означает, что мы пытаемся расшифровать данные с помощью AES-256-CBC, сообщение "Binary file (standard input) matches" говорит о том, что файл расшифрован корректно и тестовые данные найдены.

13. При включенном шифровании WAL должен быть зашифрован. Выполнить скрипт с указанием одного из файлов WAL:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ ls -la $pgdata/pg_wal
    ```

    Например, получаем:

    ```text
    000000090000000000000029
    0000000E0000000000000071
    0000000E0000000000000073
    0000000E0000000000000074
    0000000E0000000000000075
    ```

    Ищем имя WAL файла, который мы смотрели в пункте 11, и выполняем его расшифровку:

    ```bash
    postgres$ python3 ./decrypt_wal_file.py --ip $KMS_HOST --port 8200 --token $VAULT_TOKEN --cluster_id 1 --file $pgdata/pg_wal/0000000E0000000000000073 --mode 2
    ```

    Получаем:

    ```text
    master_key_base64=RRkQUv8PiwYhYhE/8sAB5wLjhSruzl5nhG4CPxewB5A=
    master_key=b'45191052ff0f8b062162113ff2c001e702e3852aeece5e67846e023f17b00790'
    wal_key_base64=9vRQEe6I3WmVwVgivw378/FLtNH4m1tmJgXL96PGDDY=
    iv=b'00000000000000000300000000000000'
    wal_key=b'21a346e1fb35e264f45f3bd9ed43556b14d85435c88baf2e78e2e5d47fe9e503'
    tli=9, seg=41, wal_segsz_bytes=16777216
    Decryption is completed: /pgdata/11/data/pg_wal/0000000E0000000000000073.decrypted - смотрим полученный файл
    postgres$ cat /pgdata/11/data/pg_wal/0000000E0000000000000073.decrypted | grep 'test'
    ```

    Получаем: `Binary file (standard input) matches`

    > *Ожидаемый результат*<br> WAL файлы расшифровываются при `mode=2`. Это означает, что расшифровка происходит с помощью AES-256-CTR, сообщение "Binary file (standard input) matches" говорит о том, что файл расшифрован корректно и тестовые данные найдены.

14. Вернуть состояние кластера в исходное состояние:

    ```bash
    postgres$ curl --insecure --header "X-Vault-Token:$VAULT_TOKEN" --request POST --data '{"data": {"value": "on"}}' https://$KMS_HOST:8200/v1/kv/data/postgresql/1/postgresql/secure_config
    ```

    на обеих нодах кластера:

    ```bash
    root$ sudo nano /etc/patroni/postgres.yml
    #'16384kB' - исходное значение
    work_mem: '16384kB'
    ```

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ reload
    postgers$ restart
    ```

    > *Ожидаемый результат*<br> Кластер возвращен в исходное состояние: обе ноды работают, проверить командой `list`.

#### Сценарий «Прозрачное шифрование данных, включая интеграцию с системами класса key management для хранения мастер-ключей: неудачное восстановление из резервной копии на ноде, относящейся к другому кластеру без шифрования»

1.  Создать базу данных и наполнить ее шифрованными данными на ведущем узле:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    CREATE TABLESPACE a_table_space_on LOCATION $table_space_location WITH (is_encrypted = on);
    CREATE TABLE a_table_on (a text) TABLESPACE a_table_space_on;
    INSERT INTO a_table_on VALUES ('test sentence');
    ```

    > *Ожидаемый результат*<br> База создана и наполнена данными.

2.  Создать резервную бинарную копию на ведомом узле с ведущего узла:

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ pg_basebackup -h $MASTER_HOST -p $DB_PORT -D /home/postgres/backup -Ft -z -Xf -v
    ```

    > *Ожидаемый результат*<br> Резервная копия создана:
    >
```bash
pg_basebackup: base backup completed
```

3.  Остановить `patroni` и очистить базу на ведомом узле:

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ sudo systemctl stop patroni
    postgres$ rm -rf $PGDATA/*
    postgres$ rm -rf $table_space_location/*
    ```

    > *Ожидаемый результат*<br> Patroni остановлен, база удалена.

4.  Выставить на ведомом узле новый `cluster_id` в `/etc/patroni/postgres.yml` и выключить шифрование:

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    sudo$ sudo nano /etc/patroni/postgres.yml
    pg_cluster_id: 'new_id'
    is_tde_on: off
    ```

    > *Ожидаемый результат*<br> Параметры выставлены.

5.  Выполнить восстановление из резервной бинарной копии на ведомом узле (директории табличных пространств тоже должны быть очищены):

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ tar xzf /home/postgres/backup/base.tar.gz -C $PGDATA
    postgres$ tar xzf /home/postgres/backup/$TS.tar.gz -C $table_space_location
    postgres$ sudo systemctl start patroni
    ```

    > *Ожидаемый результат*<br> Данные распакованы, база не стартует. 

6.  Проверить доступность БД:

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ list
    ```

    > *Ожидаемый результат*<br> БД не может стартовать из-за того, что в резервной копии зашифрованы WAL файлы и данные объектов, узел с выключенным шифрованием не может их расшифровать 

#### Сценарий «Прозрачное шифрование данных, включая интеграцию с системами класса key management для хранения мастер-ключей: некорректный старт при переносе файлов отношений на ноду, относящуюся к другому кластеру без шифрования»

1.  Создать шифрованное табличное пространство, в нем таблицу, индекс, материализованное представление:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    CREATE TABLESPACE tblspc_transfer LOCATION '$ts_location' WITH (is_encrypted = on);
    create table test_table(id bigint NOT NULL, str_field varchar) TABLESPACE tblspc_transfer;
    create table test_toast(id integer, hex_value text) TABLESPACE tblspc_transfer;
    CREATE INDEX idx_btree ON test_table USING
    btree(str_field) TABLESPACE tblspc_transfer;
    CREATE MATERIALIZED VIEW test_mat_mv TABLESPACE tblspc_transfer AS SELECT * FROM test_table WHERE id<=100;
    INSERT INTO test_table SELECT id, 'test_data_'||(id) FROM generate_series(1, 2000) AS gs(id) order by random();
    checkpoint;
    ```

    > *Ожидаемый результат*<br> Шифрованное табличное пространство создано, таблицы и все объекты созданы.

2.  Остановить кластер, выставить параметры на ведомой ноде:

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ sudo systemctl stop patroni
    postgres$ rm $pgdata/enc_connection_settings.cfg
    root$ sudo nano /etc/patroni/postgres.yml
    pg_cluster_id= 'new_id'
    is_tde_on=off
    ```

    > *Ожидаемый результат*<br> Параметры выставлены.

3.  Очистить директорию табличного пространства на ведомом узле кластера, скопировать файлы из директории табличного пространства с ведущего узла на ведомый:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    root$ sudo cp -r $ts_location /home/$root/
    root$ sudo chown -R $root:$root /home/$root/$ts_dir_name
    ```

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ rm -rf $ts_location/*
    ```

    Скопировать с ведущей ноды на локальную машину и затем на ведомую ноду с помощью winscp или в консоли:

    ```bash
    root$ scp -P 9022 -r $root@$master_host:/home/$root/$ts_dir_name /home/$root
    root$ sudo cp -r /home/$root/$ts_dir_name $ts_location
    root$ sudo chown -R postgres:postgres $ts_location
    ```

    > *Ожидаемый результат*<br> Директория очищена, новые файлы скопированы.

4.  Запустить ведомый узел:

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    sudo systemctl start patroni
    ```

    > *Ожидаемый результат*<br> Ведомый узел не стартует, файлы отношений на ведущем узле зашифрованы, нода с выключенным шифрованием не может их считать.

#### Сценарий «Прозрачное шифрование данных, включая интеграцию с системами класса key management для хранения мастер-ключей: восстановление резервной копии, содержащей зашифрованные объекты баз данных под управлением компонента УРБД, на узле того же отказоустойчивого кластера, с которого была снята резервная копия.»

1.  Создать табличное пространство, таблицы в нем и наполнить данными

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    CREATE TABLESPACE a_table_space_on LOCATION $table_space_location WITH (is_encrypted = on);
    CREATE TABLE a_table_on (a text) TABLESPACE a_table_space_on;
    INSERT INTO a_table_on VALUES ('test sentence');
    ```

    > *Ожидаемый результат*<br> Табличное пространство и таблица успешно созданы, данные добавлены.

2.  Создать резервную копию с мастера:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    pg_basebackup -h $MASTER_HOST -p $DB_PORT -D /home/postgres/backup -Ft -z -Xf -v
    ```

    > *Ожидаемый результат*<br> Команда выполнена успешно, резервная копия создана.

3.  Остановить кластер:

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    sudo systemctl stop patroni
    ```

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    sudo systemctl stop patroni
    ```

    > *Ожидаемый результат*<br> Кластер успешно остановлен.

4.  Очистить директории табличного пространства и `PGDATA`, восстановить резервную копию на узле того же отказоустойчивого кластера, с которого была снята резервная копия:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    rm -rf $PGDATA/*
    rm -rf $table_space_location/*
     
    tar xzf /home/postgres/backup/base.tar.gz -C $PGDATA
    tar xzf /home/postgres/backup/$TS.tar.gz -C $table_space_location
    auto_setup_kms_credentials --config_path /$PGDATA/enc_connection_settings.cfg --ip $KMS_HOST --port 8200 --login adminencryption --password qwerty
    ```

    > *Ожидаемый результат*<br> Директории очищены, архивы с резервной копией успешно распакованы в соответствующие директории.

5.  Запустить кластер:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    sudo systemctl start patroni
    ```

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    sudo systemctl start patroni
    ```

    > *Ожидаемый результат*<br> Кластер успешно стартовал.

6.  Проверить доступность ранее добавленных данных:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    select * from a_table_on;
    ```

    > *Ожидаемый результат*<br> Добавленные на шаге 1 данные доступны.

#### Сценарий «Прозрачное шифрование данных, включая интеграцию с системами класса key management для хранения мастер-ключей: инициализация параметров подключения к защищенному хранилищу с помощью вспомогательной утилиты»

1.  Удалить файл с параметрами подключения к хранилищу ключей на ведущем узле:

    ```bash
    rm /$PGDATA/enc_connection_settings.cfg
    ```

    > *Ожидаемый результат*<br> Файл удален.

2.  Рестартовать `patroni`:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    restart
    ```

    > *Ожидаемый результат*<br> База не стартует, тк включено шифрование и защита от привилегированных пользователей, для которых необходимо подключение к защищенному хранилищу.

3.  Создать файл с креденшелами для подключения к защищенному хранилищу с помощью вспомогательной утилиты:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    auto_setup_kms_credentials --config_path /$PGDATA/enc_connection_settings.cfg --ip $KMS_HOST --port 8200 --login adminencryption --password qwerty
    ```

    > *Ожидаемый результат*<br> Файл создан, параметры подключения к защищенному хранилищу хранятся в нем. База стартует корректно.

4.  Проверить работоспособность кластера командой list.

    > *Ожидаемый результат*<br> База, которая до этого не стартовала, теперь работоспособна.

#### Сценарий «Прозрачное шифрование данных, включая интеграцию с системами класса key management для хранения мастер-ключей: интеграция с защищенным хранилищем (предоставление возможности расширения состава поддерживаемых реализаций внешних защищенных хранилищ через реализацию плагинов интеграции)»

1.  Остановить кластер:

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ sudo systemctl stop patroni
    ```

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ sudo systemctl stop patroni
    ```

    > *Ожидаемый результат*<br> Кластер остановлен.

2.  Скопировать прикрепленный файл `libtest_connector_plugin.so` на ведущий и ведомый узел в директорию `/usr/local/pgsql/lib/plugins`.

    Выполнить на узле `$MASTER_HOST` и `$REPLICA_HOST`:

    ```bash
    root$ sudo cp /home/$root/libtest_connector_plugin.so /usr/local/pgsql/lib/plugins/
    root$ sudo chown postgres:postgres /usr/local/pgsql/lib/plugins/libtest_connector_plugin.so
    ```

    > *Ожидаемый результат*<br> Файл `libtest_connector_plugin.so` скопирован и перемещен на тестовый стенд.

3.  Скопировать прикрепленный скрипт `get_param_from_kms.py` на ведущий и ведомый узел в директорию `/usr/local/pgsql/`.

    Выполнить на узле `$MASTER_HOST` и `$REPLICA_HOST`:

    Установить пакет, нужный для запуска, если это не сделано ранее:

    ```bash
    root$ sudo pip3 install requests
    root$ sudo cp /home/$root/get_param_from_kms.py /usr/local/pgsql/
    root$ sudo chown postgres:postgres /usr/local/pgsql/get_param_from_kms.py
    ```

    > *Ожидаемый результат*<br> Скрипт `get_param_from_kms.py` скопирован и перемещен на тестовый стенд.

4.  Запустить скрипт `get_param_from_kms.py`. Он считывает все текущие параметры из защищенного хранилища и сохраняет их в файл `/tmp/test_connector.json` для дальнейшего использования плагином `libtest_connector_plugin.so`.

    Выполнить на узле $MASTER_HOST и $REPLICA_HOST:

    ```bash
    postgres$ python3 get_params_from_kms.py --ip $KMS_HOST --port 8200 --token $VAULT_TOKEN --cluster_id 1 --file /tmp/test_connector.json
    postgres$ cat /tmp/test_connector.json
    ```

    > *Ожидаемый результат*<br> Скрипт отработал корректно, файл создан.

5.  Переключить плагин:

    Выполнить на узле `$MASTER_HOST` и `$REPLICA_HOST`:

    ```bash
    postgres$ ln -sfr /usr/local/pgsql/lib/plugins/libtest_connector_plugin.so /usr/local/pgsql/lib/libconnector_plugin.so
    ```

    > *Ожидаемый результат*<br> Плагин переключен.

6.  Для дополнительной проверки остановить работу защищенного хранилища:

    Выполнить на узле `$KMS_HOST`:

    ```bash
    root$ sudo systemctl stop vault
    ```

    > *Ожидаемый результат*<br> Защащенное хранилище остановлено.

7.  Стартуем базу:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ sudo systemctl start patroni
    ```

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ sudo systemctl start patroni
    ```

    Проверить работоспособность кластера:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ list
    ```

    > *Ожидаемый результат*<br> База стартовала успешно.

8.  Создать шифруемое табличное пространство, в нем таблицу и наполнить данными:

    Открыть `psql` на узле `$MASTER_HOST` и выполнить sql код:

    ```SQL
    CREATE TABLESPACE a_table_space_on LOCATION $table_space_location WITH (is_encrypted = on);
    CREATE TABLE a_table_on (a text) TABLESPACE a_table_space_on;
    INSERT INTO a_table_on VALUES ('test1');
    ```
    > *Ожидаемый результат*<br> Объекты в базе созданы успешно.

9.  Проверить, что тестовых данных в открытом виде нет в файлах данных:

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ grep -R 'temptest1' $pgdata
    postgres$ grep -R 'temptest1' $table_space_location
    ```

    > *Ожидаемый результат*<br> Данные в открытом виде не обнаружены.

10. Вернуть кластер в исходное состояние:

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ sudo systemctl stop patroni
    ```

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ sudo systemctl stop patroni
    ```

    Выполнить на узле `$MASTER_HOST` и `$REPLICA_HOST`:

    ```bash
    postgres$ ln -sfr /usr/local/pgsql/lib/plugins/libvault_plugin.so /usr/local/pgsql/lib/libconnector_plugin.so
    ```

    Выполнить на узле `$KMS_HOST`:

    ```bash
    root$ sudo systemctl start vault
    root$ cat /etc/vault/init.file
    ```

    Получаем, например:

    ```text
    Unseal Key 1: 4sq/OwlIc7wkWOdbfK4gjUpmI2HEHxCC+rEQ8QbqR91P
    Unseal Key 2: h/fgBacinehkMQWHRZMHB0ii5V88aFevXRAmFwZuGYtZ
    Unseal Key 3: /UcUg+NiDGSAJ69/j44nja078pPAy+IKQx4mvkN4p+UW
    Unseal Key 4: Ax7duqrmh1MPCobu7MK7SMAKxyBQP8yAQUpfOc+vOe4Z
    Unseal Key 5: OuDGp7VvhGdREJMUSNg2xRFAX53RxL4zPXSTYO+4P3a2
    ```

    далее выполняем в консоли или веб-версии:

    ```bash
    # вводим ключ 1
    root$ env VAULT_ADDR=https://127.0.0.1:8200 VAULT_TOKEN=$VAULT_TOKEN VAULT_CACERT=/etc/vault/cacert.pem /usr/local/bin/vault operator unseal 4sq/OwlIc7wkWOdbfK4gjUpmI2HEHxCC+rEQ8QbqR91P
    # вводим ключ 2
    root$ env VAULT_ADDR=https://127.0.0.1:8200 VAULT_TOKEN=$VAULT_TOKEN VAULT_CACERT=/etc/vault/cacert.pem /usr/local/bin/vault operator unseal h/fgBacinehkMQWHRZMHB0ii5V88aFevXRAmFwZuGYtZ
    # вводим ключ 3
    root$ env VAULT_ADDR=https://127.0.0.1:8200 VAULT_TOKEN=$VAULT_TOKEN VAULT_CACERT=/etc/vault/cacert.pem /usr/local/bin/vault operator unseal /UcUg+NiDGSAJ69/j44nja078pPAy+IKQx4mvkN4p+UW
    ```

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ sudo systemctl start patroni
    ```

    Выполнить на узле `$REPLICA_HOST`:

    ```bash
    postgres$ sudo systemctl start patroni
    ```

    Выполнить на узле `$MASTER_HOST`:

    ```bash
    postgres$ list
    ```