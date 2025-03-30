-- Step 1: Create the Database
DROP DATABASE BankingSystem;
CREATE DATABASE BankingSystem;
USE BankingSystem;

-- Step 2: Create Tables
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15),
    Address TEXT,
    PasswordHash VARCHAR(255) -- Added for user authentication
);

CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    AccountType ENUM('Savings', 'Checking'),
    Balance DECIMAL(15,2),
    InterestRate DECIMAL(5,2) DEFAULT 0.0, -- Added interest rate for savings
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY AUTO_INCREMENT,
    AccountID INT,
    Amount DECIMAL(10,2),
    TransactionType ENUM('Deposit', 'Withdrawal', 'Transfer'),
    TransactionDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
);

CREATE TABLE Loans (
    LoanID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    LoanAmount DECIMAL(15,2),
    InterestRate DECIMAL(5,2),
    LoanStatus ENUM('Pending', 'Approved', 'Rejected'),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Added Loan Payments Table for real-time loan tracking
CREATE TABLE LoanPayments (
    PaymentID INT PRIMARY KEY AUTO_INCREMENT,
    LoanID INT,
    AmountPaid DECIMAL(15,2),
    PaymentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (LoanID) REFERENCES Loans(LoanID)
);

-- Step 3: Insert Sample Data
INSERT INTO Customers (Name, Email, Phone, Address, PasswordHash) VALUES
('John Doe', 'john@example.com', '1234567890', '123 Main St', 'hashed_password_1'),
('Jane Smith', 'jane@example.com', '0987654321', '456 Elm St', 'hashed_password_2');

INSERT INTO Accounts (CustomerID, AccountType, Balance, InterestRate) VALUES
(1, 'Savings', 5000.00, 3.5),
(1, 'Checking', 2000.00, 0.0),
(2, 'Savings', 7000.00, 4.0);

INSERT INTO Transactions (AccountID, Amount, TransactionType) VALUES
(1, 1000.00, 'Deposit'),
(1, 500.00, 'Withdrawal'),
(2, 2000.00, 'Deposit'),
(2, 1000.00, 'Withdrawal'),
(1, 300.00, 'Deposit');

INSERT INTO Loans (CustomerID, LoanAmount, InterestRate, LoanStatus) VALUES
(1, 10000.00, 5.5, 'Approved'),
(2, 15000.00, 6.0, 'Pending');

-- Step 4: Queries
-- 1. Get Account Balance for Each Customer
SELECT c.CustomerID, c.Name, a.AccountID, a.AccountType, a.Balance, a.InterestRate 
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID;

-- 2. Get Loan Approvals
SELECT c.Name, l.LoanAmount, l.InterestRate, l.LoanStatus
FROM Customers c
JOIN Loans l ON c.CustomerID = l.CustomerID
WHERE l.LoanStatus = 'Approved';

-- 3. Get Recent 5 Transactions for a Customer
SELECT t.TransactionID, c.Name, t.AccountID, t.Amount, t.TransactionType, t.TransactionDate
FROM Transactions t
JOIN Accounts a ON t.AccountID = a.AccountID
JOIN Customers c ON a.CustomerID = c.CustomerID
WHERE c.CustomerID = 1
ORDER BY t.TransactionDate DESC
LIMIT 5;

-- 4. Calculate Interest for Savings Accounts
SELECT AccountID, Balance, InterestRate, 
       (Balance * InterestRate / 100) AS InterestEarned
FROM Accounts
WHERE AccountType = 'Savings';

-- 5. Authenticate User (Check if email and password match)
SELECT CustomerID, Name FROM Customers
WHERE Email = 'john@example.com' AND PasswordHash = 'hashed_password_1';

-- 6. Trigger to Auto-Update Balance on Deposit or Withdrawal
DELIMITER //
CREATE TRIGGER update_balance_after_transaction
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.TransactionType = 'Deposit' THEN
        UPDATE Accounts
        SET Balance = Balance + NEW.Amount
        WHERE AccountID = NEW.AccountID;
    ELSEIF NEW.TransactionType = 'Withdrawal' THEN
        UPDATE Accounts
        SET Balance = Balance - NEW.Amount
        WHERE AccountID = NEW.AccountID AND Balance >= NEW.Amount;
    END IF;
END;
//
DELIMITER ;

-- 7. Trigger to Auto-Update Loan Balance on Payment
DELIMITER //
CREATE TRIGGER update_loan_balance_after_payment
AFTER INSERT ON LoanPayments
FOR EACH ROW
BEGIN
    UPDATE Loans
    SET LoanAmount = LoanAmount - NEW.AmountPaid
    WHERE LoanID = NEW.LoanID;
END;
//
DELIMITER ;
