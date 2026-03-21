# Занятие №6: CTE

**Common Table Expression (CTE)** — это именованный временный набор данных, формируемый как результат запроса, который можно использовать внутри другого SQL-запроса.

CTE объявляется с помощью ключевого слова WITH:

```sql
WITH cte_name AS (
    OPERATOR1 ...
)
OPERATOR2 ...;
```

Оператором в CTE (OPERATOR1) может быть любой оператор, возвращающий значения - не только SELECT, но и UPDATE/DELETE/INSERT с опцией RETURNING.
На месте OPERATOR2 (основного выражения) может стоять любой DML-оператор.

Запрос в CTE всегда является независимым от основного выражения и выполняется до него. К результату запроса из CTE можно обращаться сколько угодно раз в основном выражении по указанному имени cte_name.


## CTE vs Подзапрос

CTE по возможностям напоминает несвязанный подзапрос, но может быть использован многократно. Также _почти_ всегда CTE вычисляется до выполнения основного запроса, что не позволяет оптимизировать вычисление предикатов (как, например, EXISTS возвращает значение после первой найденной строки)

## Пример использования

Создадим схему и таблицу

```sql
CREATE SCHEMA sem6;

CREATE TABLE sem6.orders (
    order_id INT,
    person_id INT,
    amount NUMERIC,
    status TEXT
);

INSERT INTO sem6.orders VALUES
(1, 1, 120, 'paid'),
(2, 1, 50, 'new'),
(3, 2, 300, 'paid'),
(4, 3, 200, 'canceled'),
(5, 2, 150, 'paid');
```

Найдем общую сумму только заказов со статусом `paid`:

Без CTE:

```sql
SELECT SUM(amount)
FROM (
    SELECT *
    FROM sem6.orders
    WHERE status = 'paid'
) t;
```

С CTE:

```sql
WITH paid_orders AS (
    SELECT *
    FROM sem6.orders
    WHERE status = 'paid'
)
SELECT SUM(amount)
FROM paid_orders;
```
## Последовательные CTE

В одном запросе может быть использовано несколько CTE, в том числе ссылающиеся на предыдущие:

```sql
WITH paid_orders AS (
    SELECT *
    FROM sem6.orders
    WHERE status = 'paid'
),
total_by_person AS (
    SELECT
        person_id,
        SUM(amount) AS total_amount
    FROM paid_orders
    GROUP BY person_id
)
SELECT *
FROM total_by_person
WHERE total_amount > 200;
``` 

# CTE и JOIN

Часто CTE используется для подготовки агрегированных данных.

Добавим таблицу людей.

```sql
CREATE TABLE sem6.people (
    person_id INT,
    first_name TEXT,
    last_name TEXT
);

INSERT INTO sem6.people (person_id, first_name, last_name) VALUES
(1, 'Alice', 'Johnson'),
(2, 'Bob', 'Smith'),
(3, 'Carol', 'Davis'),
(4, 'David', 'Brown');
```

```sql
WITH order_totals AS (
    SELECT
        person_id,
        SUM(amount) AS total_amount
    FROM sem6.orders
    GROUP BY person_id
)
SELECT
    p.first_name,
    p.last_name,
    o.total_amount
FROM sem6.people p
JOIN order_totals o
    ON p.person_id = o.person_id;
```

## CTE в INSERT

CTE можно использовать перед INSERT.

```sql
WITH new_people AS (
    SELECT
        'John' AS first_name,
        'Smith' AS last_name
)
INSERT INTO sem6.people(first_name, last_name)
SELECT *
FROM new_people;
```

## CTE в UPDATE

```sql
WITH big_spenders AS (
    SELECT person_id
    FROM sem6.orders
    GROUP BY person_id
    HAVING SUM(amount) > 300
)
UPDATE sem6.people
SET last_name = last_name || ' (VIP)'
WHERE person_id IN (
    SELECT person_id
    FROM big_spenders
);
```

## CTE в DELETE

```sql
WITH canceled_orders AS (
    SELECT order_id
    FROM sem6.orders
    WHERE status = 'canceled'
)
DELETE FROM sem6.orders
WHERE order_id IN (
    SELECT order_id
    FROM canceled_orders
);
```

## Рекурсивные CTE

Рекурсивные CTE - CTE особого типа: формирующий их SELECT-запрос обращается к самому CTE, и вызывается произвольное количество раз (до выполнения стандартного условия остановки). Например CTE следующего вида

```sql
WITH RECURSIVE t(n) AS (
    VALUES (1)
  UNION ALL
    SELECT n+1 FROM t WHERE n < 100
)
SELECT sum(n) FROM t;
```
вычислит все числа от 1 до 100.

Рекурсивные CTE состоят из нерекурсивной части (где не допускается обращение к самому CTE), оператора объединения (UNION или UNION ALL) и рекурсивной части, где происходит обращение к самому CTE.

Работает следующим образом:

1. Изначально _результат_ пуст, также создается временная _рабочая таблица_, она также пуста
1. Вычисляется нерекурсивная часть, она помещается в рабочую таблицу и в результат
2. Пока рабочая таблица не пуста:
- Вычисляется рекурсивная часть, обращение к имени CTE интерпретируется как обращение к рабочей таблице
- Если используется UNION - удаляются дубликаты и совпадения со строками из результата
- Получившиеся строки добавляются в результат и заменяют собой содержимое рабочей таблицы
3. CTE возвращает строки из результата

Таким образом, в рабочей таблице всегда лежит результат вычисления предыдущей итерации _(на самом деле никакой рекурсии в SQL нет, рекурсивные CTE выполяются итеративно)_. Остановка таким образом происходит, если на какой-либо итерации не получено новых строк при UNION ALL или новых уникальных строк при UNION. Важно гарантировать остановку любого используемого рекурсивного CTE.

Более практический пример:

```sql
CREATE TABLE sem6.employees (
    employee_id INT,
    name TEXT,
    manager_id INT
);
INSERT INTO sem6.employees VALUES
(1, 'CEO', NULL),
(2, 'Alice', 1),
(3, 'Bob', 1),
(4, 'Carol', 2),
(5, 'Dave', 2),
(6, 'Eve', 3);
```

Найти всех подчинённых сотрудника по id:

```sql
WITH RECURSIVE hierarchy AS (

    SELECT
        employee_id,
        name,
        manager_id
    FROM sem6.employees
    WHERE employee_id = 2

    UNION ALL

    SELECT
        e.employee_id,
        e.name,
        e.manager_id
    FROM sem6.employees e
    JOIN hierarchy h
        ON e.manager_id = h.employee_id

)
SELECT *
FROM hierarchy;
```

Можно добавить глубину дерева:

```sql
WITH RECURSIVE hierarchy AS (

    SELECT
        employee_id,
        name,
        manager_id,
        1 AS level
    FROM sem6.employees
    WHERE employee_id = 1

    UNION ALL

    SELECT
        e.employee_id,
        e.name,
        e.manager_id,
        h.level + 1
    FROM sem6.employees e
    JOIN hierarchy h
        ON e.manager_id = h.employee_id

)
SELECT *
FROM hierarchy;
```

## UNION vs UNION ALL

Использовать UNION стоит только в тех случаях, когда невозможно гарантировать отсутствие дубликатов в данных, но при этом в итоговом CTE все строки должны быть уникальны. Если уникальность не требуется, или же будет достигаться за счет особенности данных (как в примере выше - из-за того что у каждого сотрудника не более 1 непосредственного начальника), стоит использовать UNION ALL, т.к. он работает быстрее.

## Практические задачи 

Скрипт для пересоздания схемы и наполнения данными в папке с семинаром.

### 1
Для каждого клиента посчитать общую сумму его заказов.  
Вывести имя, фамилию клиента и сумму его заказов.  

### 2
Найти клиентов, у которых общая сумма заказов выше средней общей суммы по всем клиентам.  

### 3
Для каждого региона посчитать общую сумму продаж.  
Затем вывести только те регионы, у которых продажи составляют более 20% от общей суммы продаж по всем регионам.

### 4
Для каждой категории товаров посчитать:
- количество проданных единиц
- общую сумму продаж.

### 5
Найти заказы, сумма которых выше средней суммы заказа.

### 6
Для каждого клиента найти:
- количество заказов
- общую сумму покупок.

Вывести только тех клиентов, у которых:
- не меньше 3 заказов
- общая сумма покупок больше 3000.

### 7
Найти товары, которые встречаются только в одном заказе.  

### 8
Для каждого месяца посчитать общую выручку.  
Затем вывести месяцы, в которых выручка была выше, чем в предыдущем месяце.

### 9
Найти клиентов, у которых средняя стоимость одной позиции заказа выше средней стоимости позиции по всей таблице `order_items`.

### 10
Для каждого заказа определить его долю в общей сумме продаж по своему клиенту.

### 11
Сначала посчитать продажи по регионам.  
Затем выбрать только те регионы, у которых суммарные продажи превышают 20% от общей суммы продаж.
После этого вывести продажи по товарам только в этих регионах.

### 12
Найти топ-3 самых продаваемых товаров в каждой категории (`Electronics`, `Accessories`, `Furniture`, `Office`).


### 13
Для каждого клиента определить дату его первого и последнего заказа.

### 14
Найти категории товаров, у которых суммарная выручка ниже средней выручки по категориям.

### 15
Для каждого сотрудника вывести путь от корня дерева до него.  
Например:

```text
John Carter -> Alice Brown -> Emma Scott -> Lucas Edwards
```

### 16
Найти всех сотрудников из отдела `'Sales'`, которые находятся в подчинении у сотрудника `'Alice Brown'`.

### 17
Найти максимальную глубину дерева сотрудников (то есть определить, сколько уровней имеет организационная структура).

### 18
Для изделия `'our_product'` вывести все его непосредственные компоненты из таблицы `parts`.

### 19
Для изделия `'our_product'` вывести все компоненты всех уровней вложенности.  
Необходимо получить:
- прямые компоненты
- компоненты этих компонентов
- и так далее.

### 20
Для изделия `'our_product'` посчитать суммарное количество каждого компонента по всем уровням структуры.
