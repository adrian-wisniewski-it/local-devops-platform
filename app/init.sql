CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    age INT,
    country VARCHAR(50),
    city VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    product_id INT REFERENCES products(id),
    quantity INT NOT NULL DEFAULT 1,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email, age, country, city) VALUES
('Jan Kowalski', 'jan.kowalski@example.com', 32, 'Poland', 'Warsaw'),
('Anna Nowak', 'anna.nowak@example.com', 27, 'Poland', 'Krakow'),
('Hans Müller', 'hans.mueller@example.com', 45, 'Germany', 'Berlin'),
('Clara Schmidt', 'clara.schmidt@example.com', 29, 'Germany', 'Munich'),
('John Smith', 'john.smith@example.com', 38, 'USA', 'New York'),
('Emily Johnson', 'emily.johnson@example.com', 26, 'UK', 'London'),
('Jean Lefebvre', 'jean.lefebvre@example.com', 41, 'France', 'Paris'),
('Sophie Laurent', 'sophie.laurent@example.com', 35, 'France', 'Lyon'),
('Miguel Rodríguez', 'miguel.rodriguez@example.com', 33, 'Spain', 'Madrid'),
('Isabella Fernández', 'isabella.fernandez@example.com', 28, 'Spain', 'Barcelona');

INSERT INTO products (name, category, price) VALUES
('Laptop', 'Electronics', 1200.50),
('Phone', 'Electronics', 799.99),
('Headphones', 'Electronics', 199.99),
('Keyboard', 'Electronics', 89.90),
('Monitor', 'Electronics', 300.00),
('Tablet', 'Electronics', 450.00),
('Desk Chair', 'Furniture', 150.00),
('Bookshelf', 'Furniture', 200.00),
('Desk Lamp', 'Furniture', 75.00),
('Desk', 'Furniture', 350.00);

INSERT INTO orders (user_id, product_id, quantity, status) VALUES
(1, 1, 1, 'shipped'),
(2, 2, 1, 'pending'),
(3, 3, 2, 'shipped'),
(4, 4, 1, 'cancelled'),
(5, 5, 1, 'shipped'),
(6, 6, 3, 'shipped'),
(7, 7, 1, 'pending'),
(8, 2, 2, 'shipped'),
(9, 3, 1, 'pending'),
(10, 1, 1, 'shipped'),
(1, 5, 2, 'shipped'),
(2, 8, 1, 'pending'),
(3, 9, 1, 'shipped'),
(4, 10, 1, 'pending');