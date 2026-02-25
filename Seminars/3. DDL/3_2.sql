INSERT INTO cinema.users (user_id, email, full_name, country) VALUES
(6, 'frank.meyer@mail.com',  'Frank Meyer',  'Germany'),
(7, 'maria.rossi@mail.com',  'Maria Rossi',  'Italy');

INSERT INTO cinema.movies (movie_id, title, release_year, duration_min, rating, country) VALUES
(16, 'Interstellar',  2014, 169, 8.6, 'USA'),
(17, 'Life Is Beautiful', 1997, 116, 8.6, 'Italy'),
(18, 'Coco',          2017, 105, 8.4, 'USA');

INSERT INTO cinema.movie_genres (movie_id, genre_id) VALUES
(16, 1),
(16, 2),
(17, 2),
(17, 3),
(18, 4),
(18, 3);

INSERT INTO cinema.watch (user_id, movie_id) VALUES
(6, 10),
(6, 12),
(6, 16),
(7, 12),
(7, 17),
(2, 16);

INSERT INTO cinema.reviews (review_id, user_id, movie_id, score, review_text) VALUES
(1, 1, 10, 9, 'Amazing movie'),
(2, 1, 11, 8, 'Classic sci-fi'),
(3, 2, 11, 9, 'Still great'),
(4, 3, 13, 10, 'Masterpiece'),
(5, 5, 13, 9, 'Very strong film'),
(6, 5, 14, 8, 'Beautiful animation'),
(7, 6, 16, 9, 'Mind blowing'),
(8, 7, 17, 10, 'Emotional story'),
(9, 2, 16, 8, 'Very interesting'),
(10, 6, 12, 7, 'Nice atmosphere');