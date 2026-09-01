CREATE TABLE reviews (
	app_name VARCHAR(50),
	username VARCHAR(255),
	score INT,
	review_date TIMESTAMP,
	content TEXT,
	app_version VARCHAR(50)
);

SELECT *
FROM reviews
WHERE LENGTH(content) < 5
GROUP BY app_name;

SELECT username, COUNT(*) AS count_per_username
FROM reviews
GROUP BY username
ORDER BY count_per_username DESC

CREATE TABLE reviews_clean AS
SELECT 
	app_name,
	username,
	score,
	review_date,
	content,
	COALESCE(app_version, 'unknown') AS app_version,
	-- klasification sentiment based on rating
	CASE
		WHEN score >= 4 THEN 'positive'
		WHEN score = 3 THEN 'netral'
		ELSE 'negative'
	END AS sentiment_category
FROM reviews
WHERE content IS NOT NULL AND LENGTH(TRIM(content)) >= 5;

SELECT *
FROM reviews_clean;

SELECT app_name, COUNT(*) AS count_reviews_per_app
FROM reviews_clean
GROUP BY app_name;

-- Perbandingan Average Rating & Total Sentiment per E-Wallet
SELECT 
	app_name,
	COUNT(*) AS total_reviews,
	ROUND(AVG(score), 2) AS average_rating,
	COUNT(CASE WHEN sentiment_category = 'positive' THEN 1 END) AS positive_count,
	COUNT(CASE WHEN sentiment_category = 'netral' THEN 1 END) AS netral_count,
	COUNT(CASE WHEN sentiment_category = 'negative' THEN 1 END) AS negative_count,
	ROUND(COUNT(CASE WHEN sentiment_category = 'negative' THEN 1 END) * 100.0 / COUNT(*), 2) AS negative_percentage
FROM reviews_clean
GROUP BY app_name
ORDER BY average_rating DESC;

-- Pain Point Analysis
SELECT
	app_name,
	SUM(CASE WHEN LOWER(content) LIKE '%gagal%' OR LOWER(content) LIKE '%error%' THEN 1 END) AS issue_system_error,
	SUM(CASE WHEN LOWER(content) LIKE '%transfer%' OR LOWER(content) LIKE '%saldo%' THEN 1 END) AS issue_transaction,
	SUM(CASE WHEN LOWER(content) LIKE '%otp%' OR LOWER(content) LIKE '%verifikasi%' THEN 1 END) AS issue_account_kyc,
	SUM(CASE WHEN LOWER(content) LIKE '%promo%' OR LOWER(content) LIKE '%voucher%' THEN 1 END) AS issue_promo
FROM reviews_clean
WHERE sentiment_category = 'negative'
GROUP BY app_name;

CREATE TABLE app_issues_breakdownn AS
SELECT 
    app_name,
    score,
    review_date,
    content,
    CASE 
        WHEN LOWER(content) LIKE '%gagal%' OR LOWER(content) LIKE '%error%' OR LOWER(content) LIKE '%lemot%' THEN 'System & Performance Error'
        WHEN LOWER(content) LIKE '%topup%' OR LOWER(content) LIKE '%transfer%' OR LOWER(content) LIKE '%saldo%' THEN 'Transaction & Balance Issue'
        WHEN LOWER(content) LIKE '%login%' OR LOWER(content) LIKE '%otp%' OR LOWER(content) LIKE '%verifikasi%' OR LOWER(content) LIKE '%kyc%' THEN 'Account & Verification (KYC)'
        WHEN LOWER(content) LIKE '%promo%' OR LOWER(content) LIKE '%cashback%' OR LOWER(content) LIKE '%voucher%' THEN 'Promo & Cashback Issue'
        ELSE 'Other Concerns'
    END AS issue_category
FROM reviews_clean
WHERE sentiment_category = 'negative';

SELECT *
FROM app_issues_breakdownn;

-- Tren Rating
SELECT 
	app_name,
	DATE_TRUNC('week', review_date) AS week_review,
	COUNT(*) AS weekly_total_review,
	ROUND(AVG(score), 2) AS weekly_avg_rating,
	RANK() OVER (PARTITION BY DATE_TRUNC('week', review_date) ORDER BY AVG(score)) AS rank_in_week
FROM reviews_clean
GROUP BY app_name, DATE_TRUNC('week', review_date)
ORDER BY week_review DESC, rank_in_week ASC;