DROP SCHEMA IF EXISTS cinema CASCADE;
CREATE SCHEMA cinema;

CREATE TABLE cinema.users (
    user_id    SERIAL PRIMARY KEY,
    email      VARCHAR(255),
    full_name  VARCHAR(150) NOT NULL,
    birth_date DATE,
    country    VARCHAR(100)
);

CREATE TABLE cinema.movies (
    movie_id     INTEGER PRIMARY KEY,
    title        VARCHAR(200),
    release_year INTEGER,
    duration_min INTEGER,
    rating       NUMERIC(3,1),
    country      VARCHAR(100)
);

CREATE TABLE cinema.watch (
    user_id  INTEGER,
    movie_id INTEGER,
    PRIMARY KEY (user_id, movie_id),
    FOREIGN KEY (user_id) REFERENCES cinema.users(user_id),
    FOREIGN KEY (movie_id) REFERENCES cinema.movies(movie_id)
);