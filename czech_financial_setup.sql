-- czech_financial_setup.sql

USE czech_financial;

-- STEP 1: DROP TABLES (if duplicate tables exist)

DROP TABLE IF EXISTS trans;
DROP TABLE IF EXISTS loan;
DROP TABLE IF EXISTS disp;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS account;

-- STEP 2: CREATE TABLES

CREATE TABLE account (
    account_id   INT PRIMARY KEY,
    district_id  INT,
    frequency    VARCHAR(30),
    date_opened  DATE
);

CREATE TABLE client (
    client_id    INT PRIMARY KEY,
    birth_number VARCHAR(20),
    district_id  INT
);

CREATE TABLE disp (
    disp_id      INT PRIMARY KEY,
    client_id    INT,
    account_id   INT,
    type         VARCHAR(15)
);

CREATE TABLE loan (
    loan_id      INT PRIMARY KEY,
    account_id   INT,
    date_issued  DATE,
    amount       DECIMAL(12,2),
    duration     INT,
    payments     DECIMAL(12,2),
    status       VARCHAR(10)
);

CREATE TABLE trans (
    trans_id     INT PRIMARY KEY,
    account_id   INT,
    date_trans   DATE,
    type         VARCHAR(10),
    operation    VARCHAR(50),
    amount       DECIMAL(12,2),
    balance      DECIMAL(12,2),
    k_symbol     VARCHAR(20),
    bank         VARCHAR(10),
    account_to   VARCHAR(20)
);


-- STEP 3: LOAD DATA

-- account
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/account.csv'
INTO TABLE account
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@account_id, @district_id, @frequency, @date_raw)
SET
    account_id  = @account_id,
    district_id = @district_id,
    frequency   = @frequency,
    date_opened = STR_TO_DATE(CAST(@date_raw AS CHAR), '%y%m%d');

-- client 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/client.csv'
INTO TABLE client
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- disp 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/disp.csv'
INTO TABLE disp
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- loan 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/loan.csv'
INTO TABLE loan
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@loan_id, @account_id, @date_raw, @amount, @duration, @payments, @status)
SET
    loan_id     = @loan_id,
    account_id  = @account_id,
    date_issued = STR_TO_DATE(CAST(@date_raw AS CHAR), '%y%m%d'),
    amount      = @amount,
    duration    = @duration,
    payments    = @payments,
    status      = @status;


-- trans 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/trans.csv'
INTO TABLE trans
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@trans_id, @account_id, @date_raw, @type, @operation,
 @amount, @balance, @k_symbol, @bank, @account_to)
SET
    trans_id   = @trans_id,
    account_id = @account_id,
    date_trans = STR_TO_DATE(CAST(@date_raw AS CHAR), '%y%m%d'),
    type       = @type,
    operation  = @operation,
    amount     = @amount,
    balance    = @balance,
    k_symbol   = @k_symbol,
    bank       = @bank,
    account_to = @account_to;


-- STEP 4: VERIFY ROW COUNTS
-- Expected: account ~4500, client ~5369, disp ~5369, loan ~682, trans ~1056320

SELECT 'account' AS tbl, COUNT(*) AS row_count FROM account
UNION ALL
SELECT 'client',  COUNT(*) FROM client
UNION ALL
SELECT 'disp',    COUNT(*) FROM disp
UNION ALL
SELECT 'loan',    COUNT(*) FROM loan
UNION ALL
SELECT 'trans',   COUNT(*) FROM trans;

-- Spot-check date conversion (should look like 1993-01-01, not 930101)
SELECT account_id, date_opened FROM account LIMIT 5;
SELECT loan_id, date_issued FROM loan LIMIT 5;
SELECT trans_id, date_trans FROM trans LIMIT 5;
