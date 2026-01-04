select * from transactions;
select * from final_customers;


#Клиенты, у которых есть операции в каждом из 12 месяцев, и для них: количество операций,средний чек за год,средняя сумма покупок в месяц

WITH monthly_activity AS (
    SELECT
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS ym
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'
    GROUP BY ID_client, ym
),
clients_12_months AS (
    SELECT ID_client
    FROM monthly_activity
    GROUP BY ID_client
    HAVING COUNT(*) = 12
)
SELECT
    t.ID_client,
    COUNT(DISTINCT t.Id_check)        AS operations_cnt,
    ROUND(AVG(t.Sum_payment), 2)      AS avg_check_year,
    ROUND(SUM(t.Sum_payment)/12, 2)   AS avg_month_sum
FROM transactions t
JOIN clients_12_months c
  ON t.ID_client = c.ID_client
GROUP BY t.ID_client;

#Средний чек, операции, активные клиенты
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    ROUND(AVG(Sum_payment), 2)     AS avg_check,
    COUNT(DISTINCT Id_check)       AS operations_cnt,
    COUNT(DISTINCT ID_client)      AS active_clients
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY month
ORDER BY month;

#Доля операций и доля суммы от года
SELECT
    m.month,
    ROUND(m.ops_cnt / y.total_ops, 4) AS ops_share_year,
    ROUND(m.sum_cnt / y.total_sum, 4) AS sum_share_year
FROM (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(*) AS ops_cnt,
        SUM(Sum_payment) AS sum_cnt
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'
    GROUP BY month
) m
CROSS JOIN (
    SELECT
        COUNT(*) AS total_ops,
        SUM(Sum_payment) AS total_sum
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'
) y
ORDER BY m.month;

#Гендер M / F / NA по месяцам + доля затрат
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COALESCE(c.Gender, 'NA')         AS gender,
    COUNT(DISTINCT t.ID_client)      AS clients_cnt,
    ROUND(SUM(t.Sum_payment), 2)     AS total_sum,
    ROUND(
        SUM(t.Sum_payment)
        / SUM(SUM(t.Sum_payment)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')),
        4
    ) AS sum_share
FROM transactions t
LEFT JOIN final_customers c
  ON t.ID_client = c.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new <  '2016-06-01'
GROUP BY month, gender
ORDER BY month, gender;

#Возрастные группы (шаг 10 лет + NA) За весь период
SELECT
    CASE
        WHEN c.Age IS NULL THEN 'NA'
        ELSE CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10 + 9)
    END AS age_group,
    COUNT(DISTINCT t.ID_client) AS clients_cnt,
    COUNT(t.Id_check)           AS operations_cnt,
    ROUND(SUM(t.Sum_payment),2) AS total_sum
FROM transactions t
LEFT JOIN final_customers c
  ON t.ID_client = c.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new <  '2016-06-01'
GROUP BY age_group
ORDER BY age_group;


#Поквартально (с долями)
WITH q_data AS (
    SELECT
        CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS qtr,
        CASE
            WHEN c.Age IS NULL THEN 'NA'
            ELSE CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10 + 9)
        END AS age_group,
        COUNT(t.Id_check)  AS ops_cnt,
        SUM(t.Sum_payment) AS sum_pay
    FROM transactions t
    LEFT JOIN final_customers c
      ON t.ID_client = c.ID_client
    WHERE t.date_new >= '2015-06-01'
      AND t.date_new <  '2016-06-01'
    GROUP BY qtr, age_group
)
SELECT
    qtr,
    age_group,
    ops_cnt,
    ROUND(sum_pay, 2) AS sum_pay,
    ROUND(
        sum_pay / SUM(sum_pay) OVER (PARTITION BY qtr),
        4
    ) AS sum_share
FROM q_data
ORDER BY qtr, age_group;


