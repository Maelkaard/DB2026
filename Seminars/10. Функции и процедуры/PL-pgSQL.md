# PL/pgSQL

PL/pgSQL — язык программирования, используемый для написания хранимого кода PostgreSQL.
С помощью данного расширения можно писать выполняемые блоки, функции и особый объект баз данных – триггеры.

## Структура функций

Тела функций на PL/pgSQL состоят из блоков.
Структура блока (в [...] указаны опциональные команды):
```sql
[ <<label>> ]
[ DECLARE ... ]
BEGIN
    ...
END [ label ];
```

Пример:
```sql
CREATE FUNCTION add_one (int) RETURNS int AS $$
    BEGIN
        RETURN $1 + 1;
    END;
$$ LANGUAGE plpgsql;
```

`DECLARE` определяет внутренние переменные функции: 
```sql
CREATE FUNCTION add_one (int) RETURNS int AS $$
    <<block1>> -- Метка блока
    DECLARE
        delta int = 1;
    BEGIN
        RETURN $1 + delta;
    END;
$$ LANGUAGE plpgsql;
```
Метка используется, когда нужно дополнить имена переменных, объявленных в этом блоке.
Явно это будет показано в примере с вложенными блоками ниже.
Если метка указана после `END`, то она должна совпадать с меткой в начале блока.

## Возврат сообщений и исключений

Для возврата сообщений используется RAISE NOTICE.

Для возврата исключений используется RAISE EXCEPTION; выполнение команды при этом прерывается.

## Вложенные блоки кода

Вложенные блоки используются для логической группировки нескольких операторов или локализации области действия переменных для группы операторов.

Во время выполнения вложенного блока переменные, объявленные в нём, скрывают переменные внешних блоков с такими же именами.
Чтобы получить доступ к внешним переменным, нужно дополнить их имена меткой блока.

```sql
CREATE FUNCTION somefunc() RETURNS int AS $$
<< outerblock >>
DECLARE
    quantity int = 30;
BEGIN
    RAISE NOTICE 'Сейчас quantity = %', quantity;  -- Выводится 30
    quantity = 50;
    
    -- Вложенный блок
    DECLARE
        quantity int = 80;
    BEGIN
        RAISE NOTICE 'Сейчас quantity = %', quantity;  -- Выводится 80
        RAISE NOTICE 'Во внешнем блоке quantity = %', outerblock.quantity;  -- Выводится 50
    END;

    RAISE NOTICE 'Сейчас quantity = %', quantity;  -- Выводится 50

    RETURN quantity;
END;
$$ LANGUAGE plpgsql;
```

 Каждое логическое действие, будь то `DECLARE`, `RETURN`, `RAISE`, ... (`BEGIN` таковым не является), в блоке должно завершаться символом `;`.
Каждый вложенный блок, также должен иметь точку с запятой после `END`, как показано выше.
Однако финальный `END`, завершающий тело функции, не требует `;`.

Ключевые слова не чувствительны к регистру символов. Как и в обычных SQL-командах, идентификаторы неявно преобразуются к
нижнему регистру, если они не взяты в двойные кавычки.

## Блочные комментарии

Блочный комментарий начинается с `/*` и завершается `*/`.
Они также могут быть вложенными.

```sql
CREATE FUNCTION add_ten (int) RETURNS int AS $$
    -- Комментарий 1

    /*
     Комментарий 2
     Комментарий 2
    */

    /*
     Комментарий 3
     Комментарий 3
        /*
         Вложенный комментарий 3
        */
    */
    BEGIN
        RETURN $1 + 10;
    END;
$$ LANGUAGE plpgsql;
```

## Операторы PL/pgSQL

Важно понимать, что внутри блоков функции или процедуры в PL/pgSQL можно использовать различные операторы и структуры такие, как условные операторы, циклы, динамические запросы и многое другое.

### Условные операторы

PL/pgSQL поддерживает выражения `IF ... THEN ... ELSIF ... THEN ... ELSE ... END IF` и `CASE ... WHEN ... THEN ... ELSE ... END CASE` выражения.

```sql
CREATE OR REPLACE FUNCTION classify_number(number numeric) RETURNS text AS $$
DECLARE
   result text;
BEGIN
   IF number = 0 THEN
      result = 'zero';
   ELSIF number > 0 THEN
      result = 'positive';
   ELSIF number < 0 THEN
      result = 'negative';
   ELSE
      result = 'NULL';
   END IF;

   RETURN result;
END;
$$ LANGUAGE plpgsql;
```

### Выполнение динамических запросов

Часто требуется динамически формировать команды внутри функций на PL/pgSQL, то есть такие команды, в которых при каждом выполнении могут использоваться разные таблицы или типы данных.
Для исполнения динамических команд предусмотрен оператор `EXECUTE`:
```sql
EXECUTE строка-команды 
    [ INTO цель ] 
    [ USING выражение [, ... ] ];
```
Строка-команды — это команды типа `text`, которую нужно выполнить.
Необязательная цель — это то, куда будут помещены результаты команды.
Необязательные выражения в `USING` формируют значения, которые будут вставлены в команду.

В тексте команды можно использовать значения параметров, ссылки на параметры обозначаются как `$1`, `$2` и т.д.
Эти символы указывают на значения, находящиеся в команде `USING`.
Пример:
```sql
DO $$
DECLARE
    c int; -- Переменная для хранения результата
    checked_user text = 'user123';
    checked_date date = '2001-09-11';
BEGIN
    -- Выполнение динамического запроса
    EXECUTE 'SELECT count(*) FROM mytable WHERE inserted_by = $1 AND inserted <= $2'
        INTO c
        USING checked_user, checked_date;
    
    RAISE NOTICE 'Count: %', c;
END;
$$;
```
`DO` здесь выполняет анонимный блок кода, то есть не сохраняет его в базе как функцию, а сразу исполняет один раз и выводит в консоль.


### Циклы

Синтаксис цикла:
```sql
[<<метка>>]
LOOP
    операторы
END LOOP [ метка ];
```

- `EXIT`:
```sql
EXIT [ метка ] [WHEN логическое-выражение];
```
При наличии `WHEN` цикл прекращается, только если логическое-выражение истинно.
В противном случае управление переходит к оператору, следующему за `EXIT`.

- `CONTINUE`:
```sql
CONTINUE [ метка ] [WHEN логическое-выражение];
```
При наличии `WHEN` следующая итерация цикла начинается только тогда, когда логическое-выражение истинно.
В противном случае управление переходит к оператору, следующему за `CONTINUE`.

- `WHILE`:
```sql
DO $$
DECLARE
    counter int = 1;
BEGIN
    WHILE counter < 1000 LOOP
        counter = counter * 2;
        RAISE NOTICE 'Counter: %', counter;
    END LOOP;
END;
$$;
```

- Цикл `FOR` по целым числам:
```sql
DO $$
DECLARE
    start_value int = 20;
    end_value int = 0;
    step int = 2;
    i int;
BEGIN
    -- Цикл с start_value по end_value с шагом step в обратном порядке
    FOR i IN REVERSE start_value..end_value BY step LOOP
        RAISE NOTICE 'Current value: %', i;
    END LOOP;
END;
$$;
```

- Цикл `FOR` по результатам запроса:
```sql
DO $$
DECLARE
    rec RECORD; -- Переменная для хранения текущей строки
BEGIN
    FOR rec IN SELECT id, name FROM mytable WHERE active = TRUE LOOP
        RAISE NOTICE 'ID: %, Name: %', rec.id, rec.name;
    END LOOP;
END;
$$;
```

- Цикл `FOREACH` по массиву:
```sql
DO $$
DECLARE
    numbers int[] = ARRAY[10, 20, 30, 40, 50];
    num int;
BEGIN
    FOREACH num IN ARRAY numbers LOOP
        RAISE NOTICE 'Number: %', num;
    END LOOP;
END;
$$;
```