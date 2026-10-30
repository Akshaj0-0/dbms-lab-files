-- =====================================================================
-- EXPERIMENT 7
-- AIM: To identify functional dependencies in a denormalized Sales table
-- and normalize the relation step-by-step from UNF to 1NF, 2NF, 3NF and
-- BCNF. To verify lossless join and dependency preservation using SQL.
-- 25LBCS3048  Akshaj Dwivedi
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. CREATE DATABASE
-- ---------------------------------------------------------------------
CREATE DATABASE SalesNormalization;
USE SalesNormalization;

-- ---------------------------------------------------------------------
-- 2. CREATE THE DENORMALIZED SALES TABLE (UNF)
-- ---------------------------------------------------------------------
CREATE TABLE Sales_UNF (
    Order_ID         INT,
    Order_Date       DATE,
    Customer_ID      VARCHAR(10),
    Customer_Name    VARCHAR(50),
    Product_ID       VARCHAR(10),
    Product_Name     VARCHAR(50),
    Quantity         INT,
    Unit_Price       DECIMAL(10,2),
    Salesperson_ID   VARCHAR(10),
    Salesperson_Name VARCHAR(50)
);

INSERT INTO Sales_UNF VALUES
(1001, '2026-01-10', 'C01', 'Aarav', 'P01', 'Laptop',   2, 50000, 'S01', 'Rahul'),
(1001, '2026-01-10', 'C01', 'Aarav', 'P02', 'Mouse',    3, 500,   'S01', 'Rahul'),
(1002, '2026-01-12', 'C02', 'Priya', 'P01', 'Laptop',   1, 50000, 'S02', 'Neha'),
(1003, '2026-01-15', 'C03', 'Rohan', 'P03', 'Keyboard', 2, 1500,  'S01', 'Rahul'),
(1004, '2026-01-18', 'C01', 'Aarav', 'P03', 'Keyboard', 1, 1500,  'S02', 'Neha'),
(1005, '2026-01-20', 'C04', 'Meera', 'P02', 'Mouse',    4, 500,   'S03', 'Amit');

SELECT * FROM Sales_UNF;

-- ---------------------------------------------------------------------
-- 3. IDENTIFY FUNCTIONAL DEPENDENCIES
-- ---------------------------------------------------------------------
-- 1. Order_ID -> Order_Date          : An order determines its date.
-- 2. Order_ID -> Customer_ID         : An order determines its customer.
-- 3. Order_ID -> Salesperson_ID      : An order determines its salesperson.
-- 4. Customer_ID -> Customer_Name    : A customer ID determines the customer name.
-- 5. Product_ID -> Product_Name      : A product ID determines its name.
-- 6. Product_ID -> Unit_Price        : A product ID determines its price.
-- 7. Salesperson_ID -> Salesperson_Name : A salesperson ID determines the salesperson name.
-- 8. (Order_ID, Product_ID) -> Quantity : An order-product pair determines the quantity.
--
-- Candidate Key: (Order_ID, Product_ID)

-- ---------------------------------------------------------------------
-- 4. FIRST NORMAL FORM (1NF)
-- ---------------------------------------------------------------------
CREATE TABLE Sales_1NF (
    Order_ID         INT,
    Order_Date       DATE,
    Customer_ID      VARCHAR(10),
    Customer_Name    VARCHAR(50),
    Product_ID       VARCHAR(10),
    Product_Name     VARCHAR(50),
    Quantity         INT,
    Unit_Price       DECIMAL(10,2),
    Salesperson_ID   VARCHAR(10),
    Salesperson_Name VARCHAR(50),
    PRIMARY KEY (Order_ID, Product_ID)
);

INSERT INTO Sales_1NF
SELECT * FROM Sales_UNF;

SELECT * FROM Sales_UNF;
SELECT * FROM Sales_1NF;

-- ---------------------------------------------------------------------
-- 5. SECOND NORMAL FORM (2NF)
-- ---------------------------------------------------------------------
-- The candidate key is: (Order_ID, Product_ID)
--
-- PARTIAL DEPENDENCIES
-- Order_ID   -> Order_Date, Customer_ID, Customer_Name,
--               Salesperson_ID, Salesperson_Name
-- Product_ID -> Product_Name, Unit_Price
--
-- DECOMPOSITION INTO 2NF

-- Table 1: Orders
CREATE TABLE Orders (
    Order_ID         INT PRIMARY KEY,
    Order_Date       DATE,
    Customer_ID      VARCHAR(10),
    Customer_Name    VARCHAR(50),
    Salesperson_ID   VARCHAR(10),
    Salesperson_Name VARCHAR(50)
);

INSERT INTO Orders
SELECT DISTINCT
    Order_ID,
    Order_Date,
    Customer_ID,
    Customer_Name,
    Salesperson_ID,
    Salesperson_Name
FROM Sales_1NF;

-- Table 2: Products
CREATE TABLE Products (
    Product_ID   VARCHAR(10) PRIMARY KEY,
    Product_Name VARCHAR(50),
    Unit_Price   DECIMAL(10,2)
);

INSERT INTO Products
SELECT DISTINCT
    Product_ID,
    Product_Name,
    Unit_Price
FROM Sales_1NF;

-- Table 3: Order_Details
CREATE TABLE Order_Details (
    Order_ID   INT,
    Product_ID VARCHAR(10),
    Quantity   INT,
    PRIMARY KEY (Order_ID, Product_ID),
    FOREIGN KEY (Order_ID)   REFERENCES Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID)
);

INSERT INTO Order_Details
SELECT Order_ID, Product_ID, Quantity
FROM Sales_1NF;

-- Verify
SELECT * FROM Orders;
SELECT * FROM Products;
SELECT * FROM Order_Details;

-- ---------------------------------------------------------------------
-- 6. THIRD NORMAL FORM (3NF)
-- ---------------------------------------------------------------------
-- IDENTIFY TRANSITIVE DEPENDENCIES
-- Order_ID -> Customer_ID    -> Customer_Name
-- Order_ID -> Salesperson_ID -> Salesperson_Name
--
-- Therefore:
-- Customer_ID    -> Customer_Name
-- Salesperson_ID -> Salesperson_Name

-- Table 1: Customers
CREATE TABLE Customers (
    Customer_ID   VARCHAR(10) PRIMARY KEY,
    Customer_Name VARCHAR(50)
);

INSERT INTO Customers
SELECT DISTINCT Customer_ID, Customer_Name
FROM Sales_1NF;

-- Table 2: Salespersons
CREATE TABLE Salespersons (
    Salesperson_ID   VARCHAR(10) PRIMARY KEY,
    Salesperson_Name VARCHAR(50)
);

INSERT INTO Salespersons
SELECT DISTINCT Salesperson_ID, Salesperson_Name
FROM Sales_1NF;

-- Table 3: Orders_3NF
CREATE TABLE Orders_3NF (
    Order_ID       INT PRIMARY KEY,
    Order_Date     DATE,
    Customer_ID    VARCHAR(10),
    Salesperson_ID VARCHAR(10),
    FOREIGN KEY (Customer_ID)
        REFERENCES Customers(Customer_ID),
    FOREIGN KEY (Salesperson_ID)
        REFERENCES Salespersons(Salesperson_ID)
);

INSERT INTO Orders_3NF
SELECT DISTINCT
    Order_ID,
    Order_Date,
    Customer_ID,
    Salesperson_ID
FROM Sales_1NF;

-- The Products and Order_Details tables from the 2NF decomposition are retained.

-- Verify
SELECT * FROM Customers;
SELECT * FROM Salespersons;
SELECT * FROM Orders_3NF;

-- ---------------------------------------------------------------------
-- 7. BOYCE-CODD NORMAL FORM (BCNF)
-- ---------------------------------------------------------------------
-- Employee_Assignment(Employee_ID, Project_ID, Supervisor_ID)
--
-- Functional dependencies:
-- (Employee_ID, Project_ID) -> Supervisor_ID
-- Supervisor_ID -> Project_ID

-- Create Table
CREATE TABLE Employee_Assignment (
    Employee_ID   VARCHAR(10),
    Project_ID    VARCHAR(10),
    Supervisor_ID VARCHAR(10),
    PRIMARY KEY (Employee_ID, Project_ID)
);

INSERT INTO Employee_Assignment VALUES
('E01', 'P01', 'S01'),
('E02', 'P01', 'S01'),
('E03', 'P02', 'S02'),
('E04', 'P02', 'S02');

-- Here, Supervisor_ID -> Project_ID violates BCNF because Supervisor_ID is
-- not a superkey. However, the relation satisfies 3NF because Project_ID is
-- a prime attribute under the stated dependencies.

-- DECOMPOSE INTO BCNF

-- Table 1: Supervisor_Project
CREATE TABLE Supervisor_Project (
    Supervisor_ID VARCHAR(10) PRIMARY KEY,
    Project_ID    VARCHAR(10)
);

INSERT INTO Supervisor_Project VALUES
('S01', 'P01'),
('S02', 'P02');

-- Table 2: Employee_Supervisor
CREATE TABLE Employee_Supervisor (
    Employee_ID   VARCHAR(10),
    Supervisor_ID VARCHAR(10),
    PRIMARY KEY (Employee_ID, Supervisor_ID)
);

INSERT INTO Employee_Supervisor VALUES
('E01', 'S01'),
('E02', 'S01'),
('E03', 'S02'),
('E04', 'S02');

-- Verify BCNF Decomposition
SELECT
    es.Employee_ID,
    sp.Project_ID,
    es.Supervisor_ID
FROM Employee_Supervisor es
JOIN Supervisor_Project sp
    ON es.Supervisor_ID = sp.Supervisor_ID;

-- ---------------------------------------------------------------------
-- 8. VERIFY LOSSLESS JOIN
-- ---------------------------------------------------------------------
SELECT
    o.Order_ID,
    o.Order_Date,
    c.Customer_ID,
    c.Customer_Name,
    od.Product_ID,
    p.Product_Name,
    od.Quantity,
    p.Unit_Price,
    s.Salesperson_ID,
    s.Salesperson_Name
FROM Orders_3NF o
JOIN Customers c
    ON o.Customer_ID = c.Customer_ID
JOIN Salespersons s
    ON o.Salesperson_ID = s.Salesperson_ID
JOIN Order_Details od
    ON o.Order_ID = od.Order_ID
JOIN Products p
    ON od.Product_ID = p.Product_ID
ORDER BY o.Order_ID, od.Product_ID;

-- Verify Row Count
SELECT COUNT(*) AS reconstructed_rows
FROM Orders_3NF o
JOIN Customers c
    ON o.Customer_ID = c.Customer_ID
JOIN Salespersons s
    ON o.Salesperson_ID = s.Salesperson_ID
JOIN Order_Details od
    ON o.Order_ID = od.Order_ID
JOIN Products p
    ON od.Product_ID = p.Product_ID;

-- ---------------------------------------------------------------------
-- 9. VERIFY DEPENDENCY PRESERVATION
-- ---------------------------------------------------------------------
-- Functional Dependency                                  Relation
-- Customer_ID -> Customer_Name                           Customers
-- Salesperson_ID -> Salesperson_Name                     Salespersons
-- Order_ID -> Order_Date, Customer_ID, Salesperson_ID    Orders_3NF
-- Product_ID -> Product_Name, Unit_Price                 Products
-- (Order_ID, Product_ID) -> Quantity                     Order_Details

-- SQL Verification
SHOW CREATE TABLE Customers;
SHOW CREATE TABLE Salespersons;
SHOW CREATE TABLE Orders_3NF;
SHOW CREATE TABLE Products;
SHOW CREATE TABLE Order_Details;

-- ---------------------------------------------------------------------
-- 10. COMPARISON OF NORMAL FORMS
-- ---------------------------------------------------------------------
-- UNF  : May contain repeating groups or non-atomic values
-- 1NF  : Atomic values and no repeating groups
-- 2NF  : 1NF and no partial dependency of non-prime attributes on a candidate key
-- 3NF  : 2NF and no prohibited transitive dependencies
-- BCNF : Every determinant of a non-trivial functional dependency is a superkey

-- RESULT:
-- The denormalized Sales table was analyzed for functional dependencies and
-- normalized step-by-step from UNF to 1NF, 2NF, and 3NF. A separate relation
-- was decomposed into BCNF to demonstrate the stricter BCNF requirement.
-- Lossless reconstruction and dependency preservation were examined using SQL.
