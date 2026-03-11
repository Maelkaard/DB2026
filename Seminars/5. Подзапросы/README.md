# Занятие №5: Подзапросы

Скрипт, создающий и заполняющий таблицы, используемые в семинаре лежит в папке семинара.

## Подзапросы

Подзапрос - это SELECT-запрос, содержащийся в другом запросе, результат которого используется как виртуальная таблица для внешнего запроса (содержащего выражения).

Подзапрос всегда записывается в круглых скобках.

В SELECT-запросе подзапрос может использоваться в любой части, кроме GROUP BY (т.к. GROUP BY принимает не значения, а названия атрибутов группировки).


## Классификация подзапросов

### Связанные

Используют значения из внешнего запроса:

``` sql
SELECT e.full_name, e.salary
FROM sem5.employees e
WHERE e.salary >
(
    SELECT AVG(e2.salary)
    FROM sem5.employees e2
    WHERE e2.department_id = e.department_id
); --сотрудники с зарплатой выше средней по отделу
```

### Несвязанные

Выполняются независимо от содержащего выражения:

``` sql
SELECT product_name
FROM sem5.products
WHERE price >
(
    SELECT AVG(price)
    FROM sem5.products
); --товары дороже средней цены
```

### Скалярные

Возвращают одно значение (один столбец и одну строку). Могут использоваться как значение:

``` sql
SELECT *
FROM sem5.products
WHERE price >
(
    SELECT AVG(price)
    FROM sem5.products
);
```

### Нескалярные

Все, не являющиеся скалярными.

Могут быть использованы как источник данных в FROM, или для получения значений некоторых предикатов.

``` sql
SELECT full_name
FROM sem5.customers
WHERE customer_id IN
(
    SELECT customer_id
    FROM sem5.orders
); --клиенты, сделавшие хотя бы 1 заказ
```

## Предикаты подзапросов

Специальные выражения, которые могут возвращать логическое значение, получая подзапрос в качестве аргумента.

_Note. На самом деле - любую виртуальную таблицу_


### EXISTS

Проверяет непустоту аргумента (другими словами - проверяет, что количество строк больше 0). Количество и содержимое столбцов не имеет значения, поэтому часто подзапрос под таким предикатом возвращает константу:

``` sql
SELECT EXISTS
(
    SELECT 1
    FROM sem5.orders --проверяем, что в таблице есть хотя бы одна строка
);
```

### IN

Проверяет, принадлежит ли значение множеству.

```sql
SELECT *
FROM sem5.products
WHERE product_id IN (
    SELECT product_id
    FROM sem5.order_items
);
```

В подзапросе допустимо любое количество столбцов, если оно совпадает с количеством столбцов в первом операнде (таким образом можно проверять наличие кортежей).

Возвращает TRUE при существовании искомого элемента, FALSE при отсутствии искомого элемента и NULL, NULL - иначе.

### ALL / ANY

Используются вместе с логическим оператором сравнения (<, >, =, <>_(или !=)_).

Позволяют сравнить элемент с каждым из элементов результата подзапроса.

ALL возвращает TRUE при выполнении условия для каждого, FALSE при невыполнении (возвращении FALSE) хотя бы для одного, NULL иначе.

ANY возвращает TRUE при выполнении условия хотя бы для одного, FALSE при невыполнении (возвращении FALSE) для каждого, NULL иначе.

В случае использования этих предикатов, подзапрос должен вернуть ровно 1 столбец (и произвольное количество строк).

```sql
SELECT *
FROM sem5.products
WHERE price >= ALL (
    SELECT price
    FROM sem5.products
    WHERE category = 'Electronics' 
) AND category = 'Electronics'; --ищем самый дорогой товар категории
```

```sql
SELECT *
FROM sem5.products
WHERE price > ANY (
    SELECT price
    FROM sem5.products
    WHERE category = 'Electronics' 
) AND category = 'Electronics'; --ищем не самый дешевый товар категории
```

## Подзапрос в SELECT

### Подзапрос в SELECT

``` sql
SELECT
    c.full_name,
    EXISTS
    (
        SELECT 1
        FROM sem5.orders o
        WHERE o.customer_id = c.customer_id
    ) AS has_orders
FROM sem5.customers c; --все клиенты, и информация о том, делали ли они заказ
```

### Подзапрос в FROM

``` sql
SELECT AVG(t.total)
FROM
(
    SELECT order_id, SUM(quantity*sale_price) total
    FROM sem5.order_items
    GROUP BY order_id
) t; --средняя сумма заказа
```

### Подзапрос в HAVING

``` sql
SELECT employee_id, COUNT(*) orders_count
FROM sem5.orders
GROUP BY employee_id
HAVING COUNT(*) >
(
    SELECT AVG(cnt)
    FROM
    (
        SELECT employee_id, COUNT(*) cnt
        FROM sem5.orders
        GROUP BY employee_id
    ) t
); --сотрудники, выполнившие количество заказов, большее среднего 
```

### Подзапрос в ORDER BY

``` sql
SELECT c.customer_id, c.full_name
FROM sem5.customers c
ORDER BY
(
    SELECT COUNT(*)
    FROM sem5.orders o
    WHERE o.customer_id = c.customer_id
) DESC; --сортировка по количеству заказов
```

## CASE WHEN

CASE WHEN - конструкция, позволяющая возвращать значение в зависимости от выполнения логического выражения:

```sql
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ...
    [ELSE resultN]
END
```

Конструкция CASE WHEN является выражением, а значит может быть применена в любом месте запроса, где допускаются выражения. Например:

``` sql
SELECT
    full_name,
    salary,
    CASE
        WHEN salary < 60000 THEN 'low'
        WHEN salary < 80000 THEN 'middle'
        ELSE 'high'
    END salary_level
FROM sem5.employees;
```

Условия проверяются последовательно, при первом выполненном значение возвращается. В случае невыполнения всех условий и при отсуствии ELSE будет возвращено NULL. 

Существует также краткая форма, если все условия - это применение оператора равенства к одному и тому же значению.

``` sql
SELECT order_id, status
FROM sem5.orders
ORDER BY
CASE status
    WHEN 'completed' THEN 1
    WHEN 'new' THEN 2
    WHEN 'cancelled' THEN 3
END;
```

Часто используется в агрегатных функциях:

``` sql
SELECT
COUNT(*) total_orders,
SUM(CASE WHEN status='completed' THEN 1 ELSE 0 END) completed_orders,
SUM(CASE WHEN status='cancelled' THEN 1 ELSE 0 END) cancelled_orders
FROM sem5.orders;
```

## UNION / INTERSECT / EXCEPT

Операторы для выполнения теоретико-множественных операций _(почти)_ над результатами запросов. Требуют совпадения количества столбцов и совместимости их типов (возможности неявного приведения).

- UNION: объединение
- INTERSECT: пересечение
- EXCEPT: разность

Эти 3 оператора удаляют дубликаты в результате. Оператор UNION ALL работает как UNION, но не удаляет дубликаты. Это имеет смысл, когда важно количество дубликатов, или скорост работы скрипта (UNION ALL не тратит время на удаление дубликатов)

``` sql
SELECT city --varchar
FROM sem5.customers
UNION
SELECT department_name --varchar
FROM sem5.departments;
```

``` sql 
SELECT employee_id --int
FROM sem5.employees
EXCEPT
SELECT employee_id --int
FROM sem5.employees;
```

## Практические задачи

### Выполните задания при помощи подзапросов

1.  Найти товары дороже средней цены.

2.  Найти сотрудников с зарплатой меньше максимальной.

3.  Найти клиентов, которые сделали хотя бы один заказ.

4.  Найти клиентов, не сделавших заказов.

5.  Найти товары, которые ни разу не продавались.

6.  Найти сотрудников с зарплатой выше средней в их отделе.

7.  Для каждого заказа вывести сумму заказа.

8.  Найти заказы дороже среднего заказа.

9.  Найти сотрудников, у которых число заказов выше среднего.

10. Отсортировать клиентов по количеству заказов.

### Используйте CASE WHERE

11. Выведите статус наличия товара по stock (>0 - в наличии, 0 - не в наличии).

12. Посчитать количество заказов каждого статуса.

13. Для каждого заказа вывести его размер в зависимости от количества единиц товара в нем: 
- от 1 до 2 - `small`
- от 3 до 9 - `medium`
- 10 и более - `large`

### Используйте UNION / INTERSECT / EXCEPT

14. Найти клиентов из `Kazan` с заказами.

15. Найти клиентов, не сделавших заказов.

16. Найти товары с текущей стоимостью 100, которые были проданы по цене более 100.

17. Найти товары категории `Electronics`, которые не продавались.
