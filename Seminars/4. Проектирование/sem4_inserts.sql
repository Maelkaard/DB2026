CREATE SCHEMA sem4;

CREATE TABLE sem4.people (
    person_id    SERIAL PRIMARY KEY,
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    email        VARCHAR(120) NOT NULL,
    bio          TEXT,
    birth_date   DATE,
    created_at   TIMESTAMP NOT NULL DEFAULT now(),
    last_login   TIMESTAMP
);

INSERT INTO sem4.people (first_name, last_name, email, bio, birth_date, created_at, last_login) VALUES
('Ivan',  'Ivanov',   'ivan.ivanov@gmail.com',            'Likes Premium coffee and SQL', '1992-04-12', '2024-02-10 09:15', '2024-03-01 18:20'),
('Petr',  'Petrov',   'petrov_longemail@example.com',     'Premium user. Loves Postgres', '1988-11-03', '2023-12-01 12:00', '2024-02-28 08:05'),
('Anna',  'Smirnova', 'anna@company.org',                 'Writes about data and dates',  '1999-07-25', '2024-01-20 17:30', NULL),
('Olga',  'Sidorova', 'olga.sidorova@yahoo.com',          'Standard plan',               '2001-01-15', '2022-06-10 10:10', '2024-02-10 10:10'),
('Sergey','Kuznetsov','sergey+kzn@pro-mail.com',          NULL,                           NULL,         '2024-03-01 00:05', '2024-03-01 00:10');