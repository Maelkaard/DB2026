# Занятие №10: Функции и процедуры

Хранимый код — объект базы данных, представляющий собой набор SQL-инструкций (или инструкций на другом языке программирования), который компилируется один раз и хранится на сервере, т.е. функции, процедуры, триггеры.

Зачем нужен хранимый код?
* Позволяет декомпозировать логику, скрывая внутреннюю реализацию;
* Поддерживает функции безопасности и целостности данных, обработку исключений.

## Функции

Функция в PostgreSQL — это вид программного кода, который можно вызывать из SQL-выражений и SQL-запросов. Функция принимает параметры, выполняет код и возвращает значение.

## Общий синтаксис функции

```sql
CREATE [ OR REPLACE ] FUNCTION schema_name.function_name (
    [ [ argmode ] [ argname ] argtype [ { DEFAULT | = } default_expr ] [, ...] ]
)
RETURNS return_type
[ LANGUAGE lang_name ]
[ { IMMUTABLE | STABLE | VOLATILE } ]
[ CALLED ON NULL INPUT | RETURNS NULL ON NULL INPUT ]
AS $$
function_body
$$;
```

## Основные элементы синтаксиса

### Параметры

В списке параметров можно задавать:

- режим параметра `IN`, `OUT`, `INOUT`, `VARIADIC`;
- имя параметра;
- тип параметра;
- значение по умолчанию.

Пример:

```sql
CREATE SCHEMA sem10;

CREATE FUNCTION sem10.sum_three_numbers(
    a INTEGER,
    b INTEGER,
    c INTEGER DEFAULT 0
)
RETURNS INTEGER
LANGUAGE sql
AS $$
    SELECT a + b + c;
$$;
```

### Возвращаемый тип

Функция может возвращать:

- скалярное значение (`INTEGER`, `TEXT`, `DATE` и т.д.);
- таблицу через `RETURNS TABLE (...)`;
- множество строк одинакового типа через `SETOF`.

Примеры:

```sql
RETURNS INTEGER
```

```sql
RETURNS TABLE(order_id INTEGER, total NUMERIC)
```

```sql
RETURNS SETOF TEXT
```

### Язык функции

В курсе рассматриваются:

- `LANGUAGE sql` — когда тело функции состоит из SQL-выражения или SQL-запроса. Используется по умолчанию;
- `LANGUAGE plpgsql` — когда нужны переменные, ветвления, циклы и более сложная логика.

PostgreSQL поддерживает и другие языки - полноценный язык C и процедурные версии других языков, в частности PL/Python. При желании, особенности написания функций на них могут быть изучены самостоятельно.

## Функции на языке SQL

Функции на `SQL` удобно использовать для короткой и декларативной логики. Тело функции представляет из себя корректный SQL-скрипт.

### Пример 1. Простая функция на SQL

Выполните скрипт создания схемы и ее заполнения из папки семинара.

```sql
CREATE OR REPLACE FUNCTION sem10.calculate_discount_price(
    price NUMERIC,
    discount_percent NUMERIC
)
RETURNS NUMERIC
LANGUAGE sql
AS $$
    SELECT price * (1 - discount_percent / 100.0);
$$;
```

Пример вызова:

```sql
SELECT sem10.calculate_discount_price(1000, 15);
```

### Пример 2. Функция, возвращающая таблицу

```sql
CREATE OR REPLACE FUNCTION sem10.get_expensive_products(
    min_price NUMERIC
)
RETURNS TABLE (
    product_id INTEGER,
    product_name TEXT,
    price NUMERIC
)
LANGUAGE sql
AS $$
    SELECT p.product_id, p.product_name, p.price
    FROM sem10.product p
    WHERE p.price >= min_price;
$$;
```

Пример вызова:

```sql
SELECT *
FROM sem10.get_expensive_products(5000);
```

## Функции на языке PL/pgSQL

`PL/pgSQL` позволяет писать более сложную логику:

- объявлять переменные;
- использовать `IF`, `CASE`;
- выполнять циклы;
- выполнять запросы и сохранять их результат в переменные;
- выводить сообщения, в том числе об ошибках.

### Общий синтаксис тела функции на PL/pgSQL

```sql
... AS $$
DECLARE
    -- объявления переменных
BEGIN
    -- исполняемый код
    RETURN ...;
END;
$$;
```

### Структура PL/pgSQL-функции

#### Блок `DECLARE`

Содержит объявления переменных.

```sql
DECLARE
    v_total NUMERIC;
    v_count INTEGER := 0;
```

#### Блок `BEGIN ... END`

Содержит исполняемый код.

```sql
BEGIN
    v_count := v_count + 1;
    RETURN v_count;
END;
```

### Пример функции на PL/pgSQL

```sql
CREATE OR REPLACE FUNCTION sem10.get_customer_orders(
    customer_id INTEGER
)
RETURNS TABLE (
    order_id INTEGER,
    order_dt DATE,
    status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, o.order_dt, o.status
    FROM sem10.order o
    WHERE o.customer_id = customer_id
    ORDER BY o.order_dt DESC;
END;
$$;
```

Более подробно о возможностях PL/pgSQL рассказывается в отдельном MD-файле, лежащем в папке семинара.

## Опции функций: IMMUTABLE, STABLE, VOLATILE

Эти опции описывают, насколько результат функции зависит от внешнего состояния. Это позволяет в определенных случаях сохранять в кэше уже подсчитанные значения, и при новых вызовах функции не тратить время на ее исполнение.

### `IMMUTABLE`

Функция всегда возвращает один и тот же результат для одних и тех же аргументов. Она не зависит от содержимого таблиц, текущей даты, времени, настроек сеанса и других внешних факторов.

Пример: модуль, округление, функции над строковыми константами.

```sql
CREATE OR REPLACE FUNCTION sem10.add_vat(
    amount NUMERIC
)
RETURNS NUMERIC
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT amount * 1.22;
$$;
```

### `STABLE`

В рамках одного SQL-оператора функция считается возвращающей одинаковый результат для одинаковых аргументов, но в разных операторах результат может отличаться. Обычно это функции, которые читают данные, но не изменяют их.

Пример: чтение значения из таблицы или использование `CURRENT_DATE`.

```sql
CREATE OR REPLACE FUNCTION sem10.get_product_price(
    product_id INTEGER
)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
    SELECT p.price
    FROM sem10.product p
    WHERE p.product_id = product_id;
$$;
```

### `VOLATILE`

Функция может возвращать разный результат даже при одинаковых аргументах в рамках одного запроса. Функция гарантированно будет вычисляться заново при каждом вызове. Это значение по умолчанию.

Пример: функция random().

Такой тип подходит, если функция:

- зависит от изменяемого состояния;
- использует случайные значения;
- модифицирует данные;
- зависит от времени с точностью до вызова.

```sql
CREATE OR REPLACE FUNCTION sem10.get_random_discount()
RETURNS numeric(4,2)
LANGUAGE sql
VOLATILE
CALLED ON NULL INPUT
AS $$
    SELECT round((random() * 0.30)::numeric, 2)
$$;
```

## Опции функций: CALLED ON NULL INPUT и RETURNS NULL ON NULL INPUT

### `CALLED ON NULL INPUT`

Функция будет вызвана даже в том случае, если один или несколько аргументов равны `NULL`. Это поведение используется по умолчанию.

```sql
CREATE OR REPLACE FUNCTION sem10.safe_text_length(
    text TEXT
)
RETURNS INTEGER
LANGUAGE sql
CALLED ON NULL INPUT
AS $$
    SELECT CASE
        WHEN text IS NULL THEN 0
        ELSE length(text)
    END;
$$;
```

### `RETURNS NULL ON NULL INPUT`

Если хотя бы один аргумент имеет значение `NULL`, PostgreSQL не вызывает функцию, а сразу возвращает `NULL`.

Это удобно для функций, где `NULL` на входе автоматически означает `NULL` на выходе.

```sql
CREATE OR REPLACE FUNCTION sem10.double_value(
    value INTEGER
)
RETURNS INTEGER
LANGUAGE sql
RETURNS NULL ON NULL INPUT
AS $$
    SELECT value * 2;
$$;
```

Пример:

```sql
SELECT sem10.double_value(NULL);
```

Результат: `NULL`.

## Процедуры

Процедура — это вид программного кода, поддерживающий только исполнение отдельной инструкцией.

## Основные отличия процедур от функций

### Функции

- обычно возвращают значение;
- могут вызываться в SQL-выражениях;
- могут выполняться только внутри одной транзакции _(о транзакциях уже говорилось на лекциях и будет говориться на следующем семинаре)_.

### Процедуры

- не используются как часть SQL-выражения;
- вызываются командой `CALL`;
- обычно не возвращают значение;
- могут выполнять управление транзакциями.

## Общий синтаксис процедуры

```sql
CREATE [ OR REPLACE ] PROCEDURE schema_name.procedure_name (
    [ [ argmode ] [ argname ] argtype [ { DEFAULT | = } default_expr ] [, ...] ]
)
[ LANGUAGE lang_name ]
AS $$
procedure_body
$$;
```

Синтаксис полностью совпадает с синтаксисом функций, кроме того, что процедура не допускает возвращение значений через RETURNS, только через аргументы в OUT или INOUT режиме.

## Пример процедуры

```sql
CREATE OR REPLACE PROCEDURE sem10.change_order_status(
    order_id INTEGER,
    new_status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE sem10.customer_order
    SET status = new_status
    WHERE order_id = order_id;
END;
$$;
```

Вызов процедуры:

```sql
CALL sem10.change_order_status(1, 'shipped');
```

## Практические задания

### Задание 1

Напишите функцию, которая принимает `id` товара и возвращает его цену из таблицы `sem10.product`.

### Задание 2

Напишите функцию, которая принимает `category_name` категории и возвращает таблицу со столбцами:

- `product_id`
- `product_name`
- `price`

и данными по всем товарам данной категории

### Задание 3

Напишите функцию, которая вычисляет и возвращает общую стоимость заказа по его `id`.

Если в заказе нет строк, функция должна возвращать `0`.

### Задание 4

Напишите процедуру, которая принимает `category_name` категории и процент, и увеличивает цены всех товаров указанной категории на заданный процент.
