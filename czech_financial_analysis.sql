-- Czech Financial Queries 
USE czech_financial;
-- Q1 — Total loan exposure per account type
SELECT a.frequency,
SUM(l.amount) AS total_amount,
AVG(l.amount) AS average_amount
FROM loan l
INNER JOIN account a ON l.account_id = a.account_id
GROUP BY frequency;


-- Q2 — Client demographics WITH account and loan status
SELECT 
c.client_id,
a.account_id,
CASE 
	WHEN CAST(SUBSTRING(CAST(c.birth_number AS CHAR), 3,2) AS unsigned) > 12 THEN 'Female'
	ELSE 'Male'
END AS gENDer,
CASE
	WHEN l.status = 'A' THEN 'Paid Off (Good)'
	WHEN l.status = 'B' THEN 'Paid Off (Defaulted)'
	WHEN l.status = 'C' THEN 'Active (Good)'
	WHEN l.status = 'D' THEN 'Active (Arrears)'
    ELSE 'No Loan'
END AS loan_status
FROM client c
INNER JOIN disp d ON c.client_id = d.client_id
INNER JOIN account a ON d.account_id = a.account_id
LEFT JOIN loan l ON a.account_id = l.account_id
WHERE d.type = 'OWNER';


-- Q3 — Accounts WITH no loan history
SELECT
a.account_id,
l.amount
FROM account a
LEFT JOIN loan l ON a.account_id = l.account_id
WHERE l.loan_id is NULL;


-- Q4 — Top 10 highest-borrowing clients WITH rank
WITH cte1 AS (
    SELECT
        SUM(l.amount) AS total_amount,
        c.client_id,
        CASE
            WHEN CAST(SUBSTRING(CAST(c.birth_number AS CHAR), 3, 2) AS UNSIGNED) > 12
                THEN 'Female'
            ELSE 'Male'
        END AS gENDer
    FROM client c
    INNER JOIN disp d
        ON c.client_id = d.client_id
    INNER JOIN loan l
        ON d.account_id = l.account_id
    WHERE d.type = 'OWNER'
    GROUP BY c.client_id, gENDer
),
cte2 AS (
    SELECT
        client_id,
        gender,
        total_amount,
        DENSE_RANK() OVER (ORDER BY total_amount DESC) AS borrower_rank
    FROM cte1
)
SELECT
    client_id,
    total_amount,
    gENDer,
    borrower_rank
FROM cte2
WHERE borrower_rank <= 10;

-- Q5 — Loan portfolio health breakdown

SELECT
    l.status,
    COUNT(*) AS count_of_loans,
    SUM(l.amount) AS total_amount,
    AVG(l.amount) AS average_amount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS pct_of_portfolio
FROM account a
INNER JOIN loan l
    ON a.account_id = l.account_id
GROUP BY l.status;

-- Q6 — Accounts WITH net positive transactiON flow
WITH cte AS(
SELECT
account_id,
SUM(CASE
WHEN type = 'PRIJEM' THEN amount
ELSE 0
END) AS total_credit,
SUM(CASE
WHEN type = 'VYDAJ' THEN amount
ELSE 0
END) AS total_debit
FROM trans
GROUP BY account_id
)
SELECT
account_id,
total_credit,
total_debit,
total_credit - total_debit AS net_flow
FROM cte
WHERE total_credit > total_debit;


-- Q7 — Year-OVER-year loan disbursement change
WITH cte AS (
    SELECT
        YEAR(date_issued) AS loan_year,
        SUM(amount) AS total_disbursed
    FROM loan
    GROUP BY YEAR(date_issued)
)
SELECT
    loan_year,
    total_disbursed,
    LAG(total_disbursed, 1) OVER (ORDER BY loan_year) AS prev_year_disbursed,
    total_disbursed - LAG(total_disbursed, 1) OVER (ORDER BY loan_year) AS yoy_change
FROM cte;


-- Q8 — MONthly transactiON volume trEND
SELECT 
YEAR(date_trans) AS year,
MONTH(date_trans) AS mONth,
COUNT(trans_id) AS transactiON_count,
SUM(amount) AS total_volume,
AVG(balance) AS avg_closing_balance
FROM trans
GROUP BY YEAR(date_trans), MONTH(date_trans)
ORDER BY year, mONth;


-- Q9 — Running transactiON total per account
SELECT 
    account_id,
    trans_id,
    date_trans,
    amount,
    SUM(amount) OVER (
        PARTITION BY account_id
        ORDER BY date_trans, trans_id
    ) AS running_total
FROM trans
WHERE account_id IN (
    SELECT account_id
    FROM (
        SELECT account_id, COUNT(*) AS cnt
        FROM trans
        GROUP BY account_id
        ORDER BY cnt DESC
        LIMIT 5
    ) AS top_accounts
)
ORDER BY account_id, date_trans, trans_id;


-- Q10 — Risk clASsificatiON of loan accounts
SELECT
a.account_id,
a.frequency,
l.amount,
l.duratiON,
l.payments AS mONthly_payment,
CASE
WHEN l.status IN ('A','C') THEN 'LOW RISK'
ELSE 'HIGH RISK'
END AS risk_category
FROM account a 
INNER JOIN loan l ON a.account_id = l.account_id;