# Занятие №8: Представления (VIEW)

**Представление (VIEW)** - это объект базы данных (виртуальная таблица), который представляет собой именованный результат выполнения SQL-запроса. Представление хранится в памяти в виде структуры и запроса, результат которого пересчитываются при каждом обращении. Представление, в отличие от CTE, может использоваться в любом количестве запросов.

## Зачем нужны представления

Основные предназначения представлений:

-   упростить логику запросов
-   скрыть структуру базы данных от пользователя
-   ограничить доступ пользователя к данным

## Базовый синтаксис

``` sql
CREATE VIEW schema_name.view_name AS
SELECT ...;
```

Создадим схему для примеров:

``` sql
DROP SCHEMA IF EXISTS sem8 CASCADE;
CREATE SCHEMA sem8;

CREATE TABLE sem8.students (
    student_id   INTEGER PRIMARY KEY,
    full_name    TEXT NOT NULL,
    group_name   TEXT,
    enrollment_year INTEGER
);

CREATE TABLE sem8.course (
    course_id    INTEGER PRIMARY KEY,
    course_name  TEXT NOT NULL,
    credits      INTEGER NOT NULL CHECK (credits > 0)
);

CREATE TABLE sem8.enrollment (
    enrollment_id INTEGER PRIMARY KEY,
    student_id    INTEGER NOT NULL REFERENCES sem8.students(student_id),
    course_id     INTEGER NOT NULL REFERENCES sem8.course(course_id),
    enroll_date   DATE NOT NULL,
    grade         INTEGER CHECK (grade BETWEEN 2 AND 5)
);

INSERT INTO sem8.students (student_id, full_name, group_name, enrollment_year) VALUES
(1, 'Иван Петров', 'T01-301', 2023),
(2, 'Мария Соколова', 'T01-301', 2023),
(3, 'Алексей Смирнов', 'T01-302', 2023),
(4, 'Елена Кузнецова', 'T01-302', 2023),
(5, 'Дмитрий Волков', 'T01-303', 2023),
(6, 'Анна Морозова', 'T01-303', 2023),
(7, 'Сергей Орлов', 'T01-201', 2022),
(8, 'Ольга Белова', 'T01-201', 2022),
(9, 'Никита Павлов', 'T01-202', 2022),
(10, 'Татьяна Федорова', 'T01-202', 2022),
(11, 'Артем Васильев', 'T01-203', 2022),
(12, 'Юлия Захарова', 'T01-203', 2022),
(13, 'Максим Громов', 'T01-401', 2024),
(14, 'Виктория Лебедева', 'T01-401', 2024),
(15, 'Павел Киселев', 'T01-402', 2024),
(16, 'Дарья Николаева', 'T01-402', 2024),
(17, 'Роман Егоров', 'T01-403', 2024),
(18, 'Ксения Титова', 'T01-403', 2024);

INSERT INTO sem8.course (course_id, course_name, credits) VALUES
(1, 'Базы данных', 4),
(2, 'Алгоритмы и структуры данных', 5),
(3, 'Дискретная математика', 3),
(4, 'Операционные системы', 4),
(5, 'Компьютерные сети', 3),
(6, 'Машинное обучение', 5);

INSERT INTO sem8.enrollment (enrollment_id, student_id, course_id, enroll_date, grade) VALUES
(1, 1, 1, DATE '2023-09-01', 5),
(2, 1, 2, DATE '2023-09-01', 4),
(3, 1, 3, DATE '2023-09-01', 4),
(4, 2, 1, DATE '2023-09-01', 4),
(5, 2, 3, DATE '2023-09-01', 5),
(6, 3, 1, DATE '2023-09-01', 3),
(7, 3, 4, DATE '2023-09-01', 4),
(8, 4, 2, DATE '2023-09-01', 5),
(9, 4, 3, DATE '2023-09-01', 4),
(10, 4, 5, DATE '2023-09-01', 5),
(11, 5, 1, DATE '2023-09-01', 4),
(12, 5, 2, DATE '2023-09-01', 4),
(13, 5, 6, DATE '2023-09-01', 5),
(14, 6, 3, DATE '2023-09-01', 3),
(15, 6, 4, DATE '2023-09-01', 4),
(16, 7, 1, DATE '2022-09-01', 5),
(17, 7, 2, DATE '2022-09-01', 5),
(18, 8, 3, DATE '2022-09-01', 4),
(19, 8, 4, DATE '2022-09-01', 4),
(20, 9, 1, DATE '2022-09-01', 3),
(21, 9, 5, DATE '2022-09-01', 4),
(22, 10, 2, DATE '2022-09-01', 5),
(23, 10, 3, DATE '2022-09-01', 5),
(24, 10, 6, DATE '2022-09-01', 4),
(25, 11, 4, DATE '2022-09-01', 3),
(26, 11, 5, DATE '2022-09-01', 4),
(27, 12, 1, DATE '2022-09-01', 4),
(28, 12, 6, DATE '2022-09-01', 5),
(29, 13, 1, DATE '2024-09-01', NULL),
(30, 13, 2, DATE '2024-09-01', NULL),
(31, 14, 3, DATE '2024-09-01', NULL),
(32, 14, 4, DATE '2024-09-01', NULL),
(33, 15, 2, DATE '2024-09-01', NULL),
(34, 15, 5, DATE '2024-09-01', NULL),
(35, 16, 1, DATE '2024-09-01', NULL),
(36, 16, 6, DATE '2024-09-01', NULL),
(37, 17, 3, DATE '2024-09-01', NULL),
(38, 17, 4, DATE '2024-09-01', NULL),
(39, 18, 5, DATE '2024-09-01', NULL),
(40, 18, 6, DATE '2024-09-01', NULL);
```

## Простое представление

``` sql
CREATE VIEW sem8.student_list AS
SELECT full_name, group_name
FROM sem8.students;
```

Представление хранит только определенную информацию из таблицы. Пользователь может иметь доступ на чтение представления, но не иметь доступа на чтение таблицы, данные из которой получает представление.

``` sql
SELECT * FROM sem8.student_list;
```

Еще примеры:

``` sql
CREATE VIEW sem8.student_courses AS
SELECT
    s.student_id,
    s.full_name,
    c.course_name,
    e.enroll_date,
    e.grade
FROM sem8.students s
JOIN sem8.enrollment e ON s.student_id = e.student_id
JOIN sem8.course c ON c.course_id = e.course_id;
```

``` sql
CREATE VIEW sem8.course_stats AS
SELECT
    course_id,
    COUNT(*) AS student_count,
    AVG(grade) AS avg_grade
FROM sem8.enrollment
GROUP BY course_id;
```

Важно: VIEW не хранит данные. Каждый вызов:

``` sql
SELECT * FROM sem8.student_courses;
```

фактически выполняет исходный SELECT.

## CREATE OR REPLACE VIEW

CREATE OR REPLACE позволяет в случае несуществования представления с указанным именем создать его как при обычном CREATE, а в случае существования может изменить текущее представление. В этом случае заголовок SELECT у нового представления должен быть расширением заголовка текущего, причем с сохранением порядка столбцов.

``` sql
CREATE OR REPLACE VIEW sem8.student_list AS
SELECT full_name
FROM sem8.students; -- ошибка, новый заголовок - не расширение старого
```

``` sql
CREATE OR REPLACE VIEW sem8.student_list AS
SELECT student_id, full_name, group_name
FROM sem8.students; -- ошибка, новый заголовок является расширением старого, но порядок столбцов нарушен
```

``` sql
CREATE OR REPLACE VIEW sem8.student_list AS
SELECT full_name, group_name, student_id
FROM sem8.students; -- корректно
```

## DROP VIEW

Аналогичен DROP TABLE, можно указать опции CASCADE / RESTRICT (например, если от представления зависит другое представление)

``` sql
DROP VIEW sem8.student_list;
```

## Обновляемые представления

К представлдениям может применяться не только оператор SELECT, но и INSERT/UPDATE/DELETE, но не всегда.

Предстваления, для которых это возможно, называются обновляемыми. С их помощью можно изменять содержимое таблицы, на которой основано представление, не имея доступа к изменению таблицы.

### Условия обновляемости:

- один источник данных (т.е. нет JOIN), являющийся таблицей или другим обновляемым представлением 
- нет WITH, DISTINCT, GROUP BY, HAVING, LIMIT и OFFSET в основном SELECT
- нет операций над множествами (UNION, INTERSECT or EXCEPT)
- нет агрегатных, оконных или _функций, возвращающих несколько строк (set-returning functions)_

Общая идея - добиться, чтобы каждой строке из представления соответствовала ровно одна конкретная строка таблицы.

Если представление обновляемое, то его колонки (атрибуты) делятся на обновляемые и необновляемые. Обновляемые колонки - это прямые ссылки на колонки таблицы (или на обновляемые колонки родительского представления, если источник данных у представления - другое представление).

INSERT, UPDATE и DELETE могут быть применены к обновляемым представлениям, и изменения будут применены к таблицам, на которых они построены. INSERT и UPDATE могут добавлять / изменять только значения обновляемых колонок.

``` sql
CREATE VIEW sem8.students_nogroups AS
SELECT student_id, full_name
FROM sem8.students; -- обновляемое
```

``` sql
INSERT INTO sem8.students_nogroups VALUES (19, 'Иван Иванов');
```

``` sql
SELECT * FROM sem8.students; -- убеждаемся, что все сработало
```

``` sql
CREATE OR REPLACE VIEW sem8.students_nogroups AS
SELECT student_id, full_name, EXTRACT(years FROM CURRENT_DATE) - enrollment_year AS year -- добавили необновляемую колонку
FROM sem8.students;
```

``` sql
INSERT INTO sem8.students_nogroups VALUES (20, 'Александр Васильев', 3); -- убеждаемся, что не работает
```

## CHECK OPTION

По умолчанию обновляемое представление не требует, чтобы добавляемые / изменяемые через него данные удовляетворяли его условию WHERE. Создадим представление:


``` sql
CREATE VIEW sem8.second_years AS
SELECT *
FROM sem8.students
WHERE enrollment_year = 2024;
```

Попытаемся вставить в него строку, не удовляетворяющую WHERE:

```sql
INSERT INTO sem8.second_years VALUES (20, 'Петр Сергеев', 'T01-301', 2023); -- все работает
```

Чтобы это запретить, используется CHECK OPTION:

``` sql
CREATE VIEW sem8.checked_second_years AS
SELECT *
FROM sem8.students
WHERE enrollment_year = 2024
WITH CHECK OPTION;
```

```sql
INSERT INTO sem8.checked_second_years VALUES (21, 'Федор Степанов', 'T01-301', 2023); -- теперь ошибка
```

CHECK OPTION по умолчанию имеет режим CASCADED - то есть проверяет условия представления и всех представлений, на которых оно основано. Можно указать LOCAL CHECK OPTION, и тогда будут проверены условия только для того представления, к которому обращается операция, а также всех "предшествующих" представлений, для которых определена CHECK OPTION. Создадим вложенное представление:

``` sql
CREATE VIEW sem8.group402 AS
SELECT *
FROM sem8.second_years -- представление без CHECK OPTION
WHERE group_name = 'T01-402'
WITH LOCAL CHECK OPTION;
```

```sql
INSERT INTO sem8.group402 VALUES (21, 'Федор Степанов', 'T01-402', 2023); -- все работает
```

Вариант с наличием CHECK OPTION у предшествующих представлений:

``` sql
CREATE VIEW sem8.checked_group402 AS
SELECT *
FROM sem8.checked_second_years -- представление с CHECK OPTION
WHERE group_name = 'T01-402'
WITH LOCAL CHECK OPTION;
```

```sql
INSERT INTO sem8.checked_group402 VALUES (22, 'Тимофей  Петров', 'T01-402', 2023); -- ошибка
```

## ALTER VIEW

Оператор ALTER также применим к VIEW, и позволяет изменить

```sql
ALTER VIEW view_name ALTER column_name SET DEFAULT expression -- значение по умолчанию используется только в INSERT-операциях, если значение колонки представления не указано
ALTER VIEW view_name ALTER column_name DROP DEFAULT
ALTER VIEW view_name RENAME COLUMN column_name TO new_column_name
ALTER VIEW view_name RENAME TO new_name
ALTER VIEW view_name SET SCHEMA new_schema
ALTER VIEW view_name SET ( view_option_name [= view_option_value] [, ... ] )
ALTER VIEW view_name RESET ( view_option_name [, ... ] )
```

Единственная рассматриваемая view_option_name - это check_option со значениями local и cascaded

## Рекурсивные представления

Если представление должно хранить только полные данные из рекурсивного CTE, то вместо

```sql
CREATE VIEW v1 AS
WITH RECURSIVE v AS (
    SELECT ...
)
SELECT * FROM v;
```

можно использовать краткий синтаксис

```sql
CREATE RECURSIVE VIEW v1 AS
SELECT ...
```

## Материализованные представления

Материализованное представление - объект базы данных, пободный представлению, но в отличие от него хранящий данные - результат запроса, обновляющийся не при каждом обращении, а отдельной командой.

## Создание

``` sql
CREATE MATERIALIZED VIEW sem8.mv_course_stats AS
SELECT
    course_id,
    COUNT(*) AS student_count
FROM sem8.enrollment
GROUP BY course_id;
```

```sql
SELECT * FROM sem8.mv_course_stats ORDER BY course_id;
```

```sql
INSERT INTO sem8.enrollment (enrollment_id, student_id, course_id, enroll_date, grade) VALUES
(100, 1, 5, DATE '2023-10-01', 5),
(101, 2, 5, DATE '2023-10-02', 4),
(102, 3, 5, DATE '2023-10-03', 3),
(103, 4, 6, DATE '2023-10-01', 5),
(104, 5, 6, DATE '2023-10-02', 4),
(105, 6, 1, DATE '2023-10-05', 5),
(106, 7, 1, DATE '2023-10-06', 4);
```

```sql
SELECT * FROM sem8.mv_course_stats ORDER BY course_id; -- изменений нет
```

Для обновления материализованных представлений используется REFRESH:

``` sql
REFRESH MATERIALIZED VIEW sem8.mv_course_stats;
```

```sql
SELECT * FROM sem8.mv_course_stats ORDER BY course_id; -- данные изменились
```

Для операций DROP и ALTER над материализованными VIEW используются DROP MATERIALIZED VIEW и ALTER MATERIALIZED VIEW соответственно.

Обычные представления позволяют разграничить доступ к данным и упростить логику запросов, но не могут улучшить быстродействие. Материализованные представления могут хранить данные, используемые в различных запросах, что улучшит быстродействие, но данные не всегда будут актуальными _(в будущем сможем добиться, чтобы были всегда)_.

## Практические задания

Скрипт для создания таблиц и вставки данных в папке семинара. Используются таблицы:

sem8.reader

- reader_id - уникальный идентификатор читателя (PRIMARY KEY)
- full_name - полное имя читателя
- registration_dt - дата регистрации в библиотеке

sem8.book

- book_id - уникальный идентификатор книги (PRIMARY KEY)
- title - название книги
- author_name - автор
- genre_name - жанр
- publish_year - год издания

sem8.book_copy
- copy_id - уникальный идентификатор экземпляра (PRIMARY KEY)
- book_id - ссылка на книгу (FOREIGN KEY → book.book_id)
- inventory_code - уникальный инвентарный номер
- shelf_code - код полки или места хранения
- status - статус экземпляра (available, loaned, repair, lost)

sem8.loan
- loan_id - уникальный идентификатор выдачи (PRIMARY KEY)
- copy_id - ссылка на экземпляр книги (FOREIGN KEY → book_copy.copy_id)
- reader_id - ссылка на читателя (FOREIGN KEY → reader.reader_id)
- loan_dt - дата выдачи
- due_dt - дата, до которой книгу нужно вернуть
- return_dt - фактическая дата возврата 


### Задание 1

Создайте представление sem8.active_readers, которое содержит только тех читателей, которые зарегистрировались начиная с 2024-01-01.

В представлении должны быть поля:

- reader_id
- full_name
- registration_dt

### Задание 2

Создайте представление sem8.available_copies, которое показывает только экземпляры книг, доступные для выдачи.

В представлении должны быть поля:

- copy_id
- inventory_code
- shelf_code
- book_id

Используйте только таблицу sem8.book_copy.

### Задание 3

Создайте представление sem8.book_catalog, которое объединяет сведения о книге и её экземплярах.

В представлении должны быть поля:

- copy_id
- inventory_code
- title
- author_name
- genre_name
- status

### Задание 4

Создайте представление sem8.current_loans, которое содержит только те выдачи, по которым книга еще не возвращена.

В представлении должны быть поля:

- loan_id
- copy_id
- reader_id
- loan_dt
- due_dt

### Задание 5

Создайте представление sem8.overdue_loans, которое показывает просроченные выдачи.

Считайте выдачу просроченной, если:

- return_dt IS NULL
- due_dt < CURRENT_DATE

В представлении должны быть поля:

- loan_id
- copy_id
- reader_id
- loan_dt
- due_dt

### Задание 6

Создайте представление sem8.reader_current_loans, которое показывает читателей и все их текущие невозвращенные книги.

В представлении должны быть поля:

- reader_id
- full_name
- copy_id
- loan_dt
- due_dt

### Задание 7

Создайте представление sem8.loan_history_detailed, которое показывает историю выдач с расширенной информацией.

В представлении должны быть поля:

- loan_id
- full_name читателя
- title книги
- loan_dt
- due_dt
- return_dt

### Задание 8

Создайте представление sem8.books_with_copy_count, которое для каждой книги показывает количество экземпляров этой книги в библиотеке.

В представлении должны быть поля:

- book_id
- title
- copy_count

### Задание 9

Создайте представление sem8.readers_with_loan_count, которое для каждого читателя показывает количество всех оформленных им выдач.

В представлении должны быть поля:

- reader_id
- full_name
- loan_count

### Задание 10

Создайте представление sem8.genre_stats, которое показывает по каждому жанру:

количество разных книг

количество экземпляров книг этого жанра

В представлении должны быть поля:

- genre_name
- book_count
- copy_count
