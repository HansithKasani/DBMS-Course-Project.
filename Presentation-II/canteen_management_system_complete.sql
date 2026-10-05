-- CANTEEN MANAGEMENT SYSTEM
-- Presentation-II Query: Net Profit of Total Canteen

CREATE DATABASE IF NOT EXISTS CanteenManagement;
USE CanteenManagement;

-- TABLE CREATION

CREATE TABLE IF NOT EXISTS MenuCategory (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL,
    description VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS FoodItem (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    category_id INT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (category_id) REFERENCES MenuCategory(category_id),
    CHECK (price >= 0)
);

CREATE TABLE IF NOT EXISTS Customer (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE,
    email VARCHAR(100),
    customer_type VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS Ingredient (
    ingredient_id INT PRIMARY KEY AUTO_INCREMENT,
    ingredient_name VARCHAR(100) NOT NULL,
    unit VARCHAR(30) NOT NULL,
    stock_quantity DECIMAL(10,2) DEFAULT 0,
    reorder_level DECIMAL(10,2) DEFAULT 0,
    cost_per_unit DECIMAL(10,2) NOT NULL DEFAULT 0,
    CHECK (stock_quantity >= 0),
    CHECK (reorder_level >= 0),
    CHECK (cost_per_unit >= 0)
);

CREATE TABLE IF NOT EXISTS Recipe (
    recipe_id INT PRIMARY KEY AUTO_INCREMENT,
    item_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    qty_required DECIMAL(10,3) NOT NULL,
    FOREIGN KEY (item_id) REFERENCES FoodItem(item_id),
    FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id),
    CHECK (qty_required > 0)
);

CREATE TABLE IF NOT EXISTS KitchenStaff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE,
    role VARCHAR(50),
    shift VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    status VARCHAR(30) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    CHECK (total_amount >= 0)
);

CREATE TABLE IF NOT EXISTS OrderItem (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (item_id) REFERENCES FoodItem(item_id),
    CHECK (quantity > 0),
    CHECK (unit_price >= 0),
    CHECK (subtotal >= 0)
);

CREATE TABLE IF NOT EXISTS KitchenTask (
    task_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    staff_id INT NOT NULL,
    status VARCHAR(30),
    start_time DATETIME,
    end_time DATETIME,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (staff_id) REFERENCES KitchenStaff(staff_id)
);

CREATE TABLE IF NOT EXISTS StockUsage (
    usage_id INT PRIMARY KEY AUTO_INCREMENT,
    ingredient_id INT NOT NULL,
    order_id INT NOT NULL,
    qty_used DECIMAL(10,3) NOT NULL,
    usage_date DATE NOT NULL,
    FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    CHECK (qty_used > 0)
);

CREATE TABLE IF NOT EXISTS Bill (
    bill_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    bill_date DATETIME NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0,
    tax DECIMAL(10,2) DEFAULT 0,
    net_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    CHECK (discount >= 0),
    CHECK (tax >= 0),
    CHECK (net_amount >= 0)
);

CREATE TABLE IF NOT EXISTS Payment (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    bill_id INT NOT NULL,
    payment_mode VARCHAR(30) NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    payment_date DATETIME NOT NULL,
    payment_status VARCHAR(30) NOT NULL,
    FOREIGN KEY (bill_id) REFERENCES Bill(bill_id),
    CHECK (amount_paid > 0)
);

-- SHOW TABLES / DATA

SHOW TABLES;

SELECT * FROM MenuCategory;
SELECT * FROM FoodItem;
SELECT * FROM Customer;
SELECT * FROM Ingredient;
SELECT * FROM Recipe;
SELECT * FROM KitchenStaff;
SELECT * FROM Orders;
SELECT * FROM OrderItem;
SELECT * FROM KitchenTask;
SELECT * FROM StockUsage;
SELECT * FROM Bill;
SELECT * FROM Payment;

-- TWO-TABLE JOINS

SELECT m.category_name, f.item_name, f.price
FROM MenuCategory m
JOIN FoodItem f ON m.category_id = f.category_id;

SELECT c.name AS customer_name, o.order_id, o.status, o.total_amount
FROM Customer c
JOIN Orders o ON c.customer_id = o.customer_id;

SELECT f.item_name, oi.quantity, oi.unit_price, oi.subtotal
FROM FoodItem f
JOIN OrderItem oi ON f.item_id = oi.item_id;

SELECT ks.name AS staff_name, ks.role, kt.task_id, kt.status
FROM KitchenStaff ks
JOIN KitchenTask kt ON ks.staff_id = kt.staff_id;

SELECT b.bill_id, b.order_id, b.net_amount,
       p.payment_id, p.payment_mode, p.amount_paid, p.payment_status
FROM Bill b
JOIN Payment p ON b.bill_id = p.bill_id;

-- AGGREGATION / SUBQUERY

SELECT c.customer_id, c.name AS customer_name,
       COUNT(o.order_id) AS total_orders
FROM Customer c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;

SELECT c.customer_id, c.name AS customer_name,
       COUNT(o.order_id) AS total_orders
FROM Customer c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(o.order_id) > 1;

SELECT status, COUNT(*) AS total_orders
FROM Orders
GROUP BY status;

SELECT *
FROM Orders
WHERE total_amount > (SELECT AVG(total_amount) FROM Orders);

-- REQUIRED REPORTS

SELECT o.order_id, c.name AS customer_name, o.order_date,
       o.status, o.total_amount
FROM Orders o
JOIN Customer c ON o.customer_id = c.customer_id
WHERE o.status = 'Placed'
ORDER BY o.order_date;

SELECT o.order_id, c.name AS customer_name, o.order_date, o.total_amount
FROM Orders o
JOIN Customer c ON o.customer_id = c.customer_id
WHERE o.status = 'Cancelled';

SELECT *
FROM Orders
WHERE status = 'Served';

SELECT i.ingredient_name, SUM(s.qty_used) AS total_consumed
FROM StockUsage s
JOIN Ingredient i ON s.ingredient_id = i.ingredient_id
GROUP BY i.ingredient_id, i.ingredient_name;

SELECT m.category_name, SUM(oi.subtotal) AS total_amount
FROM MenuCategory m
JOIN FoodItem f ON m.category_id = f.category_id
JOIN OrderItem oi ON f.item_id = oi.item_id
JOIN Orders o ON oi.order_id = o.order_id
WHERE o.status <> 'Cancelled'
GROUP BY m.category_id, m.category_name;

SELECT f.item_name, SUM(oi.quantity) AS quantity_sold
FROM OrderItem oi
JOIN FoodItem f ON oi.item_id = f.item_id
JOIN Orders o ON oi.order_id = o.order_id
WHERE o.status <> 'Cancelled'
GROUP BY f.item_id, f.item_name
ORDER BY quantity_sold DESC
LIMIT 1;

SELECT DATE(order_date) AS sales_date,
       SUM(total_amount) AS daily_sales
FROM Orders
WHERE status <> 'Cancelled'
GROUP BY DATE(order_date);

SELECT SUM(amount_paid) AS total_revenue
FROM Payment
WHERE payment_status = 'Paid';

SELECT ingredient_id, ingredient_name, stock_quantity, reorder_level
FROM Ingredient
WHERE stock_quantity <= reorder_level;

CREATE OR REPLACE VIEW DailySales AS
SELECT DATE(order_date) AS sales_date,
       COUNT(*) AS total_orders,
       SUM(total_amount) AS daily_sales
FROM Orders
WHERE status <> 'Cancelled'
GROUP BY DATE(order_date);

SELECT * FROM DailySales;

-- PRESENTATION-II: NET PROFIT OF TOTAL CANTEEN

-- STEP 1: TOTAL REVENUE
SELECT SUM(oi.subtotal) AS total_revenue
FROM OrderItem oi
JOIN Orders o ON oi.order_id = o.order_id
WHERE o.status <> 'Cancelled';

-- STEP 2: TOTAL INGREDIENT COST
SELECT SUM(oi.quantity * r.qty_required * i.cost_per_unit)
       AS total_ingredient_cost
FROM OrderItem oi
JOIN Orders o ON oi.order_id = o.order_id
JOIN Recipe r ON oi.item_id = r.item_id
JOIN Ingredient i ON r.ingredient_id = i.ingredient_id
WHERE o.status <> 'Cancelled';

-- STEP 3: TOTAL NET PROFIT
-- Net Profit = Total Revenue - Total Ingredient Cost
SELECT
    SUM(oi.subtotal - (oi.quantity * r.qty_required * i.cost_per_unit))
    AS net_profit
FROM OrderItem oi
JOIN Orders o ON oi.order_id = o.order_id
JOIN Recipe r ON oi.item_id = r.item_id
JOIN Ingredient i ON r.ingredient_id = i.ingredient_id
WHERE o.status <> 'Cancelled';