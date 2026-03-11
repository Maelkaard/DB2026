DROP SCHEMA IF EXISTS sem5 CASCADE;
CREATE SCHEMA sem5;

CREATE TABLE sem5.departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL
);

CREATE TABLE sem5.employees (
    employee_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    department_id INT REFERENCES sem5.departments(department_id),
    salary NUMERIC(10,2) NOT NULL,
    hire_date DATE NOT NULL
);

CREATE TABLE sem5.customers (
    customer_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    registration_date DATE NOT NULL
);

CREATE TABLE sem5.products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    stock INT NOT NULL
);

CREATE TABLE sem5.orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES sem5.customers(customer_id),
    employee_id INT REFERENCES sem5.employees(employee_id),
    order_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL
);

CREATE TABLE sem5.order_items (
    order_id INT REFERENCES sem5.orders(order_id),
    product_id INT REFERENCES sem5.products(product_id),
    quantity INT NOT NULL,
    sale_price NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO sem5.departments VALUES
(1,'Sales'),
(2,'IT'),
(3,'HR'),
(4,'Logistics'),
(5,'Marketing'),
(6,'Support');

INSERT INTO sem5.employees VALUES
(1,'Alice Johnson',1,65000,'2021-03-15'),
(2,'Bob Smith',1,72000,'2020-07-01'),
(3,'Carol White',2,90000,'2019-11-20'),
(4,'David Brown',2,85000,'2022-01-10'),
(5,'Eva Green',3,60000,'2023-05-05'),
(6,'Frank Black',4,58000,'2021-09-09'),
(7,'George Adams',1,67000,'2022-02-14'),
(8,'Helen Carter',2,92000,'2018-09-10'),
(9,'Ian Scott',2,78000,'2021-06-21'),
(10,'Julia Turner',3,61000,'2023-01-11'),
(11,'Kevin Young',4,54000,'2022-11-30'),
(12,'Laura King',5,73000,'2020-04-19'),
(13,'Mark Walker',5,69000,'2021-12-01'),
(14,'Nina Hall',6,58000,'2023-07-07'),
(15,'Oscar Allen',6,62000,'2022-05-18');

INSERT INTO sem5.customers VALUES
(1,'Ivan Petrov','Moscow','2023-01-10'),
(2,'Maria Sidorova','Kazan','2023-02-05'),
(3,'John Miller','Moscow','2023-03-12'),
(4,'Anna Lee','Sochi','2023-04-18'),
(5,'Olga Ivanova','Kazan','2023-06-30'),
(6,'Peter Novak','Prague','2023-07-02'),
(7,'Sergey Volkov','Moscow','2023-07-10'),
(8,'Anna Petrova','Saint Petersburg','2023-08-01'),
(9,'Ivan Smirnov','Kazan','2023-08-15'),
(10,'Maria Volkova','Sochi','2023-09-03'),
(11,'John Carter','London','2023-09-10'),
(12,'Emily Stone','London','2023-09-12'),
(13,'Pavel Kuznetsov','Moscow','2023-10-01'),
(14,'Olga Smirnova','Kazan','2023-10-05'),
(15,'Victor Ivanov','Novosibirsk','2023-11-11');

INSERT INTO sem5.products VALUES
(1,'Laptop','Electronics',1200,15),
(2,'Mouse','Electronics',25,100),
(3,'Desk','Furniture',300,20),
(4,'Chair','Furniture',150,35),
(5,'Monitor','Electronics',400,18),
(6,'Notebook','Stationery',5,500),
(7,'Keyboard','Electronics',80,60),
(8,'Tablet','Electronics',600,12),
(9,'Smartphone','Electronics',900,25),
(10,'Printer','Electronics',250,14),
(11,'Lamp','Furniture',45,90),
(12,'Bookshelf','Furniture',200,16),
(13,'Pen','Stationery',2,1000),
(14,'Marker','Stationery',3,700),
(15,'Paper pack','Stationery',7,400),
(16,'Office chair','Furniture',220,30),
(17,'Gaming laptop','Electronics',1800,5),
(18,'Desk lamp','Furniture',35,75);

INSERT INTO sem5.orders VALUES
(1,1,1,'2024-01-15','completed'),
(2,2,2,'2024-01-20','completed'),
(3,1,1,'2024-02-10','cancelled'),
(4,3,3,'2024-02-17','completed'),
(5,4,2,'2024-03-01','new'),
(6,5,4,'2024-03-03','completed'),
(7,2,1,'2024-03-05','completed'),
(8,6,7,'2024-03-07','completed'),
(9,7,7,'2024-03-08','completed'),
(10,8,8,'2024-03-09','completed'),
(11,9,9,'2024-03-10','new'),
(12,10,2,'2024-03-11','completed'),
(13,11,3,'2024-03-12','cancelled'),
(14,12,4,'2024-03-13','completed'),
(15,13,8,'2024-03-14','completed'),
(16,14,9,'2024-03-15','new'),
(17,15,10,'2024-03-16','completed'),
(18,1,7,'2024-03-17','completed'),
(19,3,1,'2024-03-18','completed'),
(20,5,2,'2024-03-19','cancelled');

INSERT INTO sem5.order_items VALUES
(1,1,1,1150),
(1,2,2,20),
(2,3,1,290),
(2,4,4,140),
(3,2,1,25),
(4,5,2,390),
(4,2,1,25),
(5,6,10,4.5),
(6,1,1,1200),
(6,5,1,400),
(7,4,2,145),
(7,6,20,4.8),
(8,9,1,880),
(8,2,2,22),
(9,7,1,75),
(9,13,10,1.8),
(10,8,1,590),
(10,2,1,25),
(11,15,5,6.5),
(12,10,1,240),
(12,13,20,1.9),
(13,3,1,300),
(14,11,2,40),
(14,12,1,190),
(15,17,1,1750),
(16,14,15,2.5),
(17,1,1,1180),
(17,5,1,390),
(18,9,1,910),
(18,7,2,70),
(19,16,1,210),
(19,11,3,42),
(20,6,10,5);