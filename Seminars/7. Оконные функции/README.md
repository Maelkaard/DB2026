# Занятие №7: Оконные функции

**Оконные функции (Window Functions)** — функции языка SQL, которые выполняют вычисления над набором строк таблицы, которые каким-то образом связаны с текущей строкой. Это сравнимо с типом вычислений, которые можно выполнить с помощью агрегатной функции. Однако оконные функции не группируют строки в одну выходную строку, как это происходит при использовании обычных агрегатных функций. Вместо этого строки сохраняются отдельными. Другими словами, оконная функция может получить доступ не только к текущей строке результата запроса.

## Зачем нужны оконные функции

Оконные функции полезны, когда нужно выполнить вычисления по группе строк, но при этом сохранить каждую строку результата отдельно.

Например:

* посчитать сумму по группе, не теряя строки;
* пронумеровать записи;
* получить предыдущую/следующую строку;
* вычислить накопительный итог;
* сравнить значение со средним по группе.

Создадим простую таблицу:

```sql
DROP SCHEMA IF EXISTS sem7 CASCADE;
CREATE SCHEMA sem7;

CREATE TABLE sem7.employee_salaries (
    salary_id      INTEGER PRIMARY KEY,
    department_id  INTEGER NOT NULL,
    employee_name  TEXT NOT NULL,
    salary_date      DATE NOT NULL,
    amount         NUMERIC(10,2) NOT NULL CHECK (amount > 0)
);

INSERT INTO sem7.employee_salaries (salary_id, department_id, employee_name, salary_date, amount) VALUES
(1,  10, 'Alex',    DATE '2025-01-10', 1000.00),
(2,  10, 'Billy',   DATE '2025-01-11', 1200.00),
(3,  10, 'Chris',   DATE '2025-01-12', 1200.00),
(4,  10, 'Danny',   DATE '2025-01-13', 1500.00),
(5,  10, 'Alex',    DATE '2025-01-14', 1500.00),
(6,  10, 'Billy',   DATE '2025-01-15', 1800.00),
(7,  20, 'Emily',   DATE '2025-01-10',  900.00),
(8,  20, 'Frank',   DATE '2025-01-11',  900.00),
(9,  20, 'George',  DATE '2025-01-12', 1100.00),
(10, 20, 'Henry',   DATE '2025-01-13', 1300.00),
(11, 20, 'Emily',   DATE '2025-01-14', 1300.00),
(12, 20, 'Frank',   DATE '2025-01-15', 1700.00),
(13, 30, 'Ivan',    DATE '2025-01-10',  800.00),
(14, 30, 'John',    DATE '2025-01-11', 1000.00),
(15, 30, 'Kevin',   DATE '2025-01-12', 1000.00),
(16, 30, 'Leonard', DATE '2025-01-13', 1400.00),
(17, 30, 'Ivan',    DATE '2025-01-14', 1600.00),
(18, 30, 'John',    DATE '2025-01-15', 1600.00);
```

## Базовый синтаксис

```sql
function(...) OVER (
    [PARTITION BY ...]
    [ORDER BY ...]
    [ROWS | RANGE | GROUPS ...]
)
```

Пример:

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    salary_date,
    amount,
    AVG(amount) OVER () AS avg_amount_all
FROM sem7.employee_salaries
ORDER BY salary_id;
```

Важно - оконные функции могут быть использованы только в SELECT и ORDER BY (т.к. они используют для вычисления значения других строк, необходимо завершить формирование этих строк). Для фильтрации по значению оконной функции необходимо использовать подзапрос или CTE.

## OVER()

OVER() задает для каждой строки таблицы так называемое "окно" - множество строк, по которым будет произведено вычисление оконной функции. При указании OVER() без параметров окном для каждой строки будет вся таблица целиком.

### PARTITION BY attr

Разбивает строки на группы по аналогии с GROUP BY - в окно для каждой строки попадают только строки с совпадающим значением атрибута.

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    AVG(amount) OVER (PARTITION BY department_id) AS avg_amount_in_department
FROM sem7.employee_salaries
ORDER BY department_id, salary_id;
```

### ORDER BY 

Задает порядок строк внутри окна.

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    ROW_NUMBER() OVER (
        PARTITION BY department_id
        ORDER BY amount DESC, salary_id
    ) AS row_num
FROM sem7.employee_salaries
ORDER BY department_id, row_num;
```

### Frame Clause

Используется для создания границ подокна в зависимости от значения атрибута в строке. Используется при наличии ORDER BY, порядок "до/после" определяется относительно сортировки. Допустимые границы:
* UNBOUNDED PRECEDING
* CURRENT ROW
* UNBOUNDED FOLLOWING
* n PRECEDING
* n FOLLOWING

#### ROWS

Задает границы фрейма по количеству строк до / после текущей.

```sql
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW -- 3 строки, 2 до текущей и текущая
```

```sql
ROWS BETWEEN UNBOUNDED PRECEDING AND 1 FOLLOWING ROW -- нижняя граница - неограниченно (т.е. граница окна по PARTITION, если оно есть, или начало таблицы), верхняя - первая соедующая за данной строка
```

#### RANGE

Задает границы по значению атрибута группировки.

```sql
RANGE BETWEEN 2 PRECEDING AND CURRENT ROW -- здесь это будет означать, что во фрейм попадают строки, где значение атрибута сортировки меньше текущего не более чем на 2, и не больше текущего.
```

#### GROUPS

Задает границы по количеству предшествующих значений атрибута сортировки.
```sql
GROUPS BETWEEN 2 PRECEDING AND CURRENT ROW -- во фрейм попадут все строки с 2 предыдущими значениями атрибута сортировки
```

Frame clause по умолчанию - RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

## Виды оконных функций

### Ранжирующие (Ranking)

* ROW_NUMBER()
* RANK()
* DENSE_RANK()
* NTILE()
* PERCENT_RANK()
* CUME_DIST()

### Смещения (Value)

* LAG()
* LEAD()
* FIRST_VALUE()
* LAST_VALUE()
* NTH_VALUE()

### Агрегатные (Aggregate)

* SUM()
* AVG()
* COUNT()
* MIN()
* MAX()

---

## Ранжирующие функции

Подразумевают наличие ORDER BY, иначе их значение малоосмысленно, но работают и без него. Игнорируют Frame clause.

### ROW_NUMBER()

Нумерует строки уникальными номерами по возрастанию (здесь и далее - внутри окна)

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    ROW_NUMBER() OVER (
        PARTITION BY department_id
        ORDER BY amount DESC, salary_id
    ) AS row_num
FROM sem7.employee_salaries
ORDER BY department_id, row_num;
```

### RANK()

Нумерует строки, присваивая одинаковые номера строкам с одинаковыми значениями, с пропусками (напр. 1, 2, 2, 4, ... )

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    RANK() OVER (
        PARTITION BY department_id
        ORDER BY amount DESC
    ) AS rnk
FROM sem7.employee_salaries
ORDER BY department_id, rnk, salary_id;
```

### DENSE_RANK()

Нумерует строки, присваивая одинаковые номера строкам с одинаковыми значениями, без пропусков (напр. 1, 2, 2, 3, ... )

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    DENSE_RANK() OVER (
        PARTITION BY department_id
        ORDER BY amount DESC
    ) AS dense_rnk
FROM sem7.employee_salaries
ORDER BY department_id, dense_rnk, salary_id;
```

### NTILE(n)

Разбивает окно на N равных групп по порядку сортировки (если не разбивается нацело - то первые несколько групп будут иметь на 1 больше элементов)

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    NTILE(4) OVER (
        PARTITION BY department_id
        ORDER BY amount DESC, salary_id
    ) AS quartile
FROM sem7.employee_salaries
ORDER BY department_id, amount DESC, quartile, salary_id;
```

### PERCENT_RANK()

Расчтывает ранг по доле от 0 до 1 (фактически (RANK() - 1) / (<размер окна> - 1))

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    PERCENT_RANK() OVER (
        PARTITION BY department_id
        ORDER BY amount
    ) AS percent_rank_value
FROM sem7.employee_salaries
ORDER BY department_id, amount, salary_id;
```

### CUME_DIST()

Возвращает долю строк, не превышающих текущую

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    CUME_DIST() OVER (
        PARTITION BY department_id
        ORDER BY amount
    ) AS cume_dist_value
FROM sem7.employee_salaries
ORDER BY department_id, amount, salary_id;
```

## Функции смещения

### LAG(expr [, offset [, default]])

Возвращает значение выражения expr из строки на offset (по умолчанию - 1) предшествующей текущей. При выходе за границу окна возвращет default. Игнорирует Frame clause.

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    salary_date,
    amount,
    LAG(amount) OVER (
        PARTITION BY department_id
        ORDER BY salary_date, salary_id
    ) AS prev_amount
FROM sem7.employee_salaries
ORDER BY department_id, salary_date, salary_id;
```

### LEAD(expr [, offset [, default]])

Возвращает значение выражения expr из строки на offset (по умолчанию - 1) следующей за текущей. При выходе за границу окна возвращет default. Игнорирует Frame clause.

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    salary_date,
    amount,
    LEAD(amount) OVER (
        PARTITION BY department_id
        ORDER BY salary_date, salary_id
    ) AS next_amount
FROM sem7.employee_salaries
ORDER BY department_id, salary_date, salary_id;
```

### FIRST_VALUE(expr)

Возвращает значение expr из первой строки окна.

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    FIRST_VALUE(employee_name) OVER (
        PARTITION BY department_id
        ORDER BY amount DESC, salary_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS top_employee
FROM sem7.employee_salaries
ORDER BY department_id, salary_id;

```

### LAST_VALUE(expr)

Возвращает значение expr из первой строки окна.

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    LAST_VALUE(employee_name) OVER (
        PARTITION BY department_id
        ORDER BY amount DESC, salary_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_employee
FROM sem7.employee_salaries
ORDER BY department_id, salary_id;
```

### NTH_VALUE(expr, n)

Возвращает значение expr из n-й строки окна.

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    NTH_VALUE(employee_name, 2) OVER (
        PARTITION BY department_id
        ORDER BY amount DESC, salary_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS second_employee
FROM sem7.employee_salaries
ORDER BY department_id, salary_id;
```

## Агрегатные оконные функции

Вычисляют значение по таким же принципам, что и не оконные, но не требуют группировки.

### SUM()

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    SUM(amount) OVER (
        PARTITION BY department_id
    ) AS sum_amount_in_department
FROM sem7.employee_salaries
ORDER BY department_id, salary_id;
```

### AVG()

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    AVG(amount) OVER (
        PARTITION BY department_id
    ) AS avg_amount_in_department
FROM sem7.employee_salaries
ORDER BY department_id, salary_id;
```

### COUNT()

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    COUNT(*) OVER (
        PARTITION BY department_id
    ) AS count_in_department
FROM sem7.employee_salaries
ORDER BY department_id, salary_id;
```

### MIN()

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    MIN(amount) OVER (
        PARTITION BY department_id
    ) AS min_amount_in_department
FROM sem7.employee_salaries
ORDER BY department_id, salary_id;
```

### MAX()

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    MAX(amount) OVER (
        PARTITION BY department_id
    ) AS max_amount_in_department
FROM sem7.employee_salaries
ORDER BY department_id, salary_id;
```

## Примеры на Frame clause

### ROWS()

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    salary_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY department_id
        ORDER BY salary_date, salary_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS sum_rows_2_preceding
FROM sem7.employee_salaries
ORDER BY department_id, salary_date, salary_id;
```

### RANGE()

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    SUM(amount) OVER (
        PARTITION BY department_id
        ORDER BY amount
        RANGE BETWEEN 200 PRECEDING AND CURRENT ROW
    ) AS sum_range_200_preceding
FROM sem7.employee_salaries
ORDER BY department_id, amount, salary_id;
```

### GROUPS()

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    SUM(amount) OVER (
        PARTITION BY department_id
        ORDER BY amount
        GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS sum_groups_1_preceding
FROM sem7.employee_salaries
ORDER BY department_id, amount, salary_id;
```

## Именованное разбиение на окна

При использовании нескольких оконных функций с одинаковым разбиением на окна, можно использовать ключевое слово WINDOW для создания именованного разбиения; в таком случае код станет читаемее _(оптимизированный расчет одинаковых разбиений произойдет даже без именования, если просто указать одинаковое разбиение у нескольких функций)_.

```sql
SELECT
    salary_id,
    department_id,
    employee_name,
    amount,
    ROW_NUMBER() OVER w AS row_num,
    AVG(amount) OVER w AS avg_amount_ordered
FROM sem7.employee_salaries
WINDOW w AS (
    PARTITION BY department_id
    ORDER BY amount DESC, salary_id
)
ORDER BY department_id, salary_id;
```

## Практические задания

Таблица `sem7.orders(order_id, customer_id, order_date, amount, status)`. 

Скрипт создания и заполнения в папке семинара.

### Задание 1

Для каждой строки выведите:
- `order_id`
- `customer_id`
- `amount`
- среднюю сумму заказа по всей таблице

## Задание 2

Для каждой строки выведите:
- `order_id`
- `customer_id`
- `amount`
- среднюю сумму заказа данного статуса

## Задание 3

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `order_date`
- порядковый номер заказа клиента по дате

## Задание 4

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `amount`
- уникальный ранг заказа по убыванию суммы внутри клиента

## Задание 5

То же самое, но присвойте равным по сумме заказам равные ранги

## Задание 6

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `order_date`
- `amount`
- статус предыдущего заказа этого же клиента

## Задание 7

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `amount`
- сумму предыдущего заказа клиента
- разницу между текущей суммой и предыдущей

Для первого заказа клиента выведите сумму равную NULL, и разницу равную `NULL`.

## Задание 8

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `order_date`
- `amount`
- накопительную сумму заказов клиента от первого заказа до текущего

## Задание 9

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `amount`
- общую сумму заказов клиента
- долю текущего заказа в общей сумме заказов клиента

## Задание 10

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `order_date`
- `amount`
- сумму:
  - текущего заказа
  - предыдущего заказа
  - и заказа перед ним

В случае первого и второго заказа отсуствующие слагаемые замените нулями.

## Задание 11

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `amount`
- номер группы (от 1 до 4), на которую разбивается набор заказов клиента _(квартиля)_

Разбиение выполнить по убыванию суммы заказа.

## Задание 12

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `amount`
- сумму самого дорогого заказа клиента

## Задание 13

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `order_date`
- сумму первого заказа клиента

## Задание 14

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `amount`
- максимальную сумму заказа клиента
- разницу между текущей суммой и максимальной

## Задание 15

Для каждой строки выведите:
- `customer_id`
- `order_id`
- `order_date`
- дату следующего заказа клиента
- количество дней до следующего заказа

Если следующего заказа нет — результат должен быть `NULL`.
