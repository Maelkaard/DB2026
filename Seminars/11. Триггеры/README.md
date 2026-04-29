# Занятие №11: Триггеры

Триггер — это объект базы данных, который автоматически запускает заданную функцию при определённом событии над таблицей или представлением.

## События триггера

Триггер можно связать с операциями:

- `INSERT`
- `UPDATE`
- `DELETE`
- `TRUNCATE`

## Время срабатывания триггера

- `BEFORE` — до выполнения операции;
- `AFTER` — после выполнения операции;
- `INSTEAD OF` — вместо операции, обычно используется для представлений.

## Уровень срабатывания триггера

- `FOR EACH ROW` — триггер срабатывает для каждой затронутой строки;
- `FOR EACH STATEMENT` — триггер срабатывает один раз на всю команду.

## Триггер-функция

Код триггера оформляется в виде специальной функции, которая:

- не принимает обычных аргументов;
- возвращает тип `trigger`;
- использует специальные переменные триггера.

## Общий синтаксис триггер-функции

```sql
CREATE OR REPLACE FUNCTION schema_name.trigger_function_name()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    trigger_function_body
    RETURN NEW;
END;
$$;
```

## Общий синтаксис триггера

```sql
CREATE TRIGGER trigger_name
{ BEFORE | AFTER | INSTEAD OF }
{ INSERT | UPDATE | DELETE | TRUNCATE }
ON schema_name.table_name
[ FOR EACH ] { ROW | STATEMENT } ]
[ WHEN (condition) ]
EXECUTE FUNCTION schema_name.trigger_function_name();
```

## Условие срабатывания WHEN

Можно настроить срабатывание триггера только при выполнении определенного условия. обычно условие связано с содержимым переменных триггера NEW и OLD, о них далее.

## Специальные переменные триггера

Внутри триггер-функции доступны специальные переменные.

### `NEW`

Новая строка, поддерживает обращение к атрибутам по их именам.

Используется:

- в `INSERT`;
- в `UPDATE`,

только для уровня срабатывания FOR_EACH_ROW.

### `OLD`

Старая строка, поддерживает обращение к атрибутам по их именам.

Используется:

- в `UPDATE`;
- в `DELETE`,

только для уровня срабатывания FOR_EACH_ROW.

### `TG_NAME`

Имя триггера, который вызвал функцию (одна и та же триггер-функция может вызываться разными триггерами).

### `TG_WHEN`

Момент срабатывания: `BEFORE`, `AFTER`, `INSTEAD OF`.

### `TG_LEVEL`

Уровень триггера: `ROW` или `STATEMENT`.

### `TG_OP`

Операция, вызвавшая триггер: `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`.

### `TG_TABLE_NAME`

Имя таблицы, на которой сработал триггер.

### `TG_TABLE_SCHEMA`

Имя схемы таблицы, на которой сработал триггер.

## Возврат значения из триггер-функции

### Для `BEFORE ... FOR EACH ROW`

Обычно возвращают:

- `NEW` — если нужно разрешить вставку или изменение строки;
- `NULL` — если нужно отменить обработку строки.

### Для `AFTER`-триггеров

Возвращаемое значение обычно игнорируется, но принято возвращать `NEW` или `OLD` в зависимости от ситуации.

Скрипт для заполнения данными в папке семинара.

## Пример 1. Автоматическое заполнение даты


```sql
ALTER TABLE sem11.product -- добавим поля в таблицу
ADD COLUMN updated_at timestamp NOT NULL DEFAULT current_timestamp;

CREATE OR REPLACE FUNCTION sem11.set_product_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := current_timestamp;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_product_set_updated_at
BEFORE UPDATE
ON sem11.product
FOR EACH ROW
EXECUTE FUNCTION sem11.set_product_updated_at();
```

## Пример 2. Проверка данных перед вставкой или обновлением

```sql
CREATE OR REPLACE FUNCTION sem11.check_order_item_quantity()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than 0';
    END IF;

    RETURN NEW;
END;
$$;
```

```sql
CREATE TRIGGER trg_order_item_check_quantity
BEFORE INSERT OR UPDATE
ON sem11.order_item
FOR EACH ROW
EXECUTE FUNCTION sem11.check_order_item_quantity();
```

## Пример 3. Хранение истории изменений

```sql
CREATE TABLE sem11.product_price_audit ( --таблица с историей
    audit_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INTEGER NOT NULL,
    old_price NUMERIC(10, 2),
    new_price NUMERIC(10, 2),
    changed_at timestamp NOT NULL DEFAULT current_timestamp
);

CREATE OR REPLACE FUNCTION sem11.log_product_price_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.price IS DISTINCT FROM OLD.price THEN -- храним только изменения значения price
        INSERT INTO sem11.product_price_audit(product_id, old_price, new_price)
        VALUES (OLD.product_id, OLD.price, NEW.price);
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_product_log_price_change
AFTER UPDATE
ON sem11.product
FOR EACH ROW
EXECUTE FUNCTION sem11.log_product_price_change();
```

Продемонстрируем работу триггера:

```sql
UPDATE sem11.products
SET price = round(price * 1.08, 2)
WHERE price < 1000;

UPDATE sem11.products
SET price = round(price * 0.97, 2)
WHERE price >= 1000 AND price < 3000;

UPDATE sem11.products
SET price = round(price * 1.15, 2)
WHERE price >= 3000;

SELECT * FROM sem11.product_price_audit;
```

## Практические задания

### Задание 1

Создайте таблицу `sem11.archived_products`, в которую будут помещаться удалённые товары.

После этого напишите триггер-функцию и триггер для таблицы `sem11.products`, чтобы при удалении товара информация о нём автоматически добавлялась в `sem11.archived_products`.

### Задание 2

Напишите триггер-функцию и триггер для таблицы `sem11.order_items`, который будет про каждом добавлении / удалении корректно пересчитывать значение `total_amount` и соответствующего заказа в таблице `sem11.orders`

### Задание 3

Напишите триггер-функцию и триггер для таблицы `sem11.products`, чтобы при достижении `stock_qty` значения 0 он переводился в неактивные, и обратно, если у неактивного товара `stock_qty` становится больше 0, он должен становиться активным.

### Задание 4

Напишите триггер-функцию и триггер для таблицы `sem11.products`, который будет запрещать уменьшение цены товара больше, чем на 20%.
