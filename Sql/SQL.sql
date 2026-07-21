USE PROJECT_1;

-- =======================
-- BANKING DATA
-- =======================
-- 1.TOTAL CLIENTS
SELECT COUNT(*) FROM dim_client;

-- 2. ACTIVE CLIENTS
SELECT COUNT(DISTINCT Client_ID) FROM fact_loan WHERE Loan_Status NOT IN ('Default');

-- 3. TOTAL LOAN AMOUNT
SELECT CONCAT(ROUND(SUM(Loan_Amount) / 1000000, 1), 'M') AS Total_Loan FROM fact_loan;

-- 4. TOTAL FUNDED AMOUNT
SELECT CONCAT(ROUND(SUM(Funded_Amount) / 1000000, 1), 'M') AS Total_Funded_Amount FROM fact_loan;

-- 5. AVERAGE LOAN SIZE
SELECT CONCAT(ROUND(AVG(Loan_Amount) / 1000000, 2), 'M') AS Avg_Loan_Amount FROM fact_loan;

-- 6. TOTAL REPAYMENTS COLLECTED
SELECT CONCAT(ROUND(SUM(Total_Pymnt) / 1000000, 1), 'M') AS Total_Payment FROM fact_repayment;

-- 7. PRINCIPAL RECOVERY RATE
SELECT CONCAT(ROUND((SUM(Total_Rec_Prncp) / SUM(Loan_Amount)) * 100, 2),'%') AS Recovery_Rate FROM fact_loan JOIN fact_repayment ON fact_loan.Account_ID = fact_repayment.Account_ID;

-- 8. INTEREST INCOME
SELECT CONCAT(ROUND(SUM(Total_Rrec_Int) / 1000000, 1), 'M') AS Total_Recovered_Interest FROM fact_repayment;

-- 9. DEFAULT RATE
SELECT CONCAT(ROUND((SUM(CASE WHEN Is_Default_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*)) * 100,2),'%') AS Default_Rate FROM fact_repayment;

-- 10. DELIQUENCY RATE
SELECT CONCAT(ROUND((SUM(CASE WHEN Is_Delinquent_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*)) * 100,2),'%') AS Delinquency_Rate FROM fact_repayment;

-- 11. ON TIME REPAYMENT
SELECT CONCAT(ROUND((SUM(CASE WHEN Repayment_Behavior = 'On-Time' THEN 1 ELSE 0 END) / COUNT(*)) * 100,2),'%') AS On_Time_Repayment_Rate FROM fact_repayment;

-- 12. LOAN DISTRIBUTION BY BRANCH
SELECT b.Branch_Name,CONCAT(ROUND(SUM(o.Loan_Amount) / 1000000, 1), 'M') AS Total_Loan FROM fact_loan o JOIN dim_branch b ON o.BranchID = b.BranchID GROUP BY b.Branch_Name ORDER BY SUM(o.Loan_Amount) DESC;




-- ========================================
-- CREDIT AND DEBIT DATA
-- ========================================



-- 1.TOTAL CREDIT AMOUNT
SELECT CONCAT(ROUND(SUM(Amount) / 1000000, 1),'M') AS Total_Credit_Amount 
FROM debit_credit_csv WHERE Transaction_Type = "Credit";

-- 2. TOTAL DEBIT AMOUNT
SELECT CONCAT(ROUND(SUM(Amount) / 1000000, 1),'M') AS Total_Debit_Amount 
FROM debit_credit_csv WHERE Transaction_Type = "Debit";

-- 3. CREDIT AND DEBIT RATIO
SELECT CONCAT(ROUND((SUM(Amount) /(SELECT SUM(Amount)FROM debit_credit_csv 
WHERE Transaction_Type = 'Debit')) * 100,2),'%') AS Credit_to_Debit_Ratio FROM debit_credit_csv WHERE Transaction_Type = "Credit";

-- 4. NET TRANSACTION CASHFLOW
SELECT CONCAT(ROUND((SUM(Amount) - (SELECT SUM(Amount)FROM debit_credit_csv 
WHERE Transaction_Type = 'Debit')) / 1000000,1),'M') AS Net_Transaction_Amount FROM debit_credit_csv WHERE Transaction_Type = "Credit";

-- 5. ACCOUNT ACTIVE RATIO
SELECT CONCAT(ROUND(
(COUNT(Account_Number) / AVG(Balance))),'%') AS Account_Activity_Ratio FROM debit_credit_csv;

-- 6. TOTAL TRANSACTION AMOUNT BY BRANCH
SELECT Branch,CONCAT(ROUND(SUM(Amount) / 1000000, 1),'M') AS Total_Transaction_Amount
 FROM debit_credit_csv GROUP BY Branch ORDER BY SUM(Amount) DESC;
 
-- 7.TRANSACTIONS PER DAY/WEEK/MONTH
-- TRANSACTIONS PER DAY
SELECT  DATE(`Transaction_Date`) AS Transaction_Day,    
COUNT(*) AS Total_Transactions FROM debit_credit_csv 
GROUP BY DATE(`Transaction_Date`) ORDER BY Transaction_Day;

-- TRANSACTIONS PER WEEK
SELECT    YEAR(`Transaction_Date`) AS Year, WEEK(`Transaction_Date`) AS Week_No, 
COUNT(*) AS Total_Transactions FROM debit_credit_csv GROUP BY YEAR(`Transaction_Date`),WEEK(`Transaction_Date`)ORDER BY Year, Week_No;

-- TRANSACTIONS PER MONTH
SELECT    DATE_FORMAT(`Transaction_Date`,'%Y-%m') AS Month,COUNT(*) AS Total_Transactions 
FROM debit_credit_csv GROUP BY DATE_FORMAT(`Transaction_Date`,'%Y-%m')ORDER BY Month;

-- 8. TRANSACTION VOLUME BY BANK
SELECT Bank_Name,CONCAT(ROUND(SUM(Amount) / 1000000, 1),'M') AS Total_Transaction_Amount 
FROM debit_credit_csv GROUP BY Bank_Name ORDER BY SUM(Amount) DESC;

-- 9. TRANSACTION METHOD DISTRIBUTION
SELECT Transaction_Method,
COUNT(Account_Number) AS Transaction_count
 FROM debit_credit_csv GROUP BY Transaction_Method;
 
-- 10.SUSPICIOUS TRANSACTION FREQUENCY
SELECT
    DATE_FORMAT(`Transaction_Date`,'%Y-%m') AS Month,
    COUNT(*) AS Suspicious_Transactions
FROM high_risk_transaction_flag
WHERE Risk_Flag='High Risk'
GROUP BY DATE_FORMAT(`Transaction_Date`,'%Y-%m')
ORDER BY Month;

-- 11. BRANCH TRANSACTION GROWTH
SELECT Branch,CONCAT(ROUND(Total_Amount / 1000000, 0), 'M') AS Total_Amount,
CONCAT(ROUND(((Total_Amount - Previous_Amount) / Previous_Amount) * 100, 2),'%') AS Growth_Percentage 
FROM (SELECT Branch, SUM(Amount) AS Total_Amount, LAG(SUM(Amount)) OVER (ORDER BY Branch) AS Previous_Amount FROM debit_credit_csv GROUP BY Branch) AS t;

-- 12.HIGH RISK TRANSACTION FLAG
SELECT Risk_Flag, COUNT(*) AS Total_Transactions FROM 
( SELECT 
CASE 
WHEN Amount > 4000 
THEN "High Risk" 
ELSE "Normal" 
END AS Risk_Flag FROM debit_credit_csv
 ) AS t GROUP BY Risk_Flag;


