TRUNCATE TABLE cinema.watch
CASCADE;

INSERT INTO cinema.users (user_id, email, full_name, country) VALUES
(1, 'alex.stone@mail.com',   'Alex Stone',   'USA'),
(2, 'billy.fox@mail.com',    'Billy Fox',    'UK'),
(3, 'chris.pine@mail.com',   'Chris Pine',   'USA'),
(4, 'dana.white@mail.com',   'Dana White',   'Canada'),
(5, 'elena.kim@mail.com',    'Elena Kim',    'Korea');

INSERT INTO cinema.movies (movie_id, title, release_year, duration_min, rating, country) VALUES
(10, 'Inception',      2010, 148, 8.8, 'USA'),
(11, 'The Matrix',     1999, 136, 8.7, 'USA'),
(12, 'Amelie',         2001, 122, 8.3, 'France'),
(13, 'Parasite',       2019, 132, 8.5, 'Korea'),
(14, 'Spirited Away',  2001, 125, 8.6, 'Japan'),
(15, 'The Intouchables',2011,112, 8.5, 'France');

INSERT INTO cinema.genres (genre_id, name) VALUES
(1, 'Sci-Fi'),
(2, 'Drama'),
(3, 'Comedy'),
(4, 'Animation');

INSERT INTO cinema.movie_genres (movie_id, genre_id) VALUES
(10, 1),
(11, 1),
(12, 2),
(13, 2),
(14, 4),
(15, 2),
(15, 3);

INSERT INTO cinema.watch (user_id, movie_id) VALUES
(1, 10),
(1, 11),
(2, 11),
(3, 13),
(5, 13),
(5, 14);