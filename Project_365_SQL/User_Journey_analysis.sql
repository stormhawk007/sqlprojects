
SET SESSION group_concat_max_len = 100000; 

-- ------------------------------- INTERACTION BASE ------------------------------
WITH interactions_base AS (
SELECT *,
CASE WHEN event_source_url LIKE "https://365datascience.com/" THEN "Homepage"
	 WHEN event_source_url LIKE "%https://365datascience.com/login/%" THEN "Log in"
	 WHEN event_source_url LIKE "%https://365datascience.com/signup/%" THEN "Sign up"
	 WHEN event_source_url LIKE "%https://365datascience.com/resources-center/%" THEN "Resources center"
	 WHEN event_source_url LIKE "%https://365datascience.com/courses/%" THEN "Courses"
	 WHEN event_source_url LIKE "%https://365datascience.com/career-tracks/%" THEN "Career tracks"
	 WHEN event_source_url LIKE "%https://365datascience.com/upcoming-courses/%" THEN "Upcoming courses"
	 WHEN event_source_url LIKE "%https://365datascience.com/career-track-certificate/%" THEN "Career track certificate"
	 WHEN event_source_url LIKE "%https://365datascience.com/course-certificate/%" THEN "Course certificate"
	 WHEN event_source_url LIKE "%https://365datascience.com/success-stories/%" THEN "Success stories"
	 WHEN event_source_url LIKE "%https://365datascience.com/blog/%" THEN "Blog"
	 WHEN event_source_url LIKE "%https://365datascience.com/pricing/%" THEN "Pricing"
	 WHEN event_source_url LIKE "%https://365datascience.com/about-us/%" THEN "About us"
	 WHEN event_source_url LIKE "%https://365datascience.com/instructors/%" THEN "Instructors"
	 WHEN event_source_url LIKE "%https://365datascience.com/checkout/%" AND event_source_url LIKE "%coupon%" THEN "Coupon"
	 WHEN event_source_url LIKE "%https://365datascience.com/checkout/%" AND event_source_url NOT LIKE "%coupon%" THEN "Checkout"
	 ELSE "Other" END AS event_source_type,
     
CASE WHEN event_destination_url LIKE "https://365datascience.com/" THEN "Homepage"
	 WHEN event_destination_url LIKE "%https://365datascience.com/login/%" THEN "Log in"
	 WHEN event_destination_url LIKE "%https://365datascience.com/signup/%" THEN "Sign up"
	 WHEN event_destination_url LIKE "%https://365datascience.com/resources-center/%" THEN "Resources center"
	 WHEN event_destination_url LIKE "%https://365datascience.com/courses/%" THEN "Courses"
	 WHEN event_destination_url LIKE "%https://365datascience.com/career-tracks/%" THEN "Career tracks"
	 WHEN event_destination_url LIKE "%https://365datascience.com/upcoming-courses/%" THEN "Upcoming courses"
	 WHEN event_destination_url LIKE "%https://365datascience.com/career-track-certificate/%" THEN "Career track certificate"
	 WHEN event_destination_url LIKE "%https://365datascience.com/course-certificate/%" THEN "Course certificate"
	 WHEN event_destination_url LIKE "%https://365datascience.com/success-stories/%" THEN "Success stories"
	 WHEN event_destination_url LIKE "%https://365datascience.com/blog/%" THEN "Blog"
	 WHEN event_destination_url LIKE "%https://365datascience.com/pricing/%" THEN "Pricing"
	 WHEN event_destination_url LIKE "%https://365datascience.com/about-us/%" THEN "About us"
	 WHEN event_destination_url LIKE "%https://365datascience.com/instructors/%" THEN "Instructors"
	 WHEN event_destination_url LIKE "%https://365datascience.com/checkout/%" AND event_destination_url LIKE "%coupon%" THEN "Coupon"
	 WHEN event_destination_url LIKE "%https://365datascience.com/checkout/%" AND event_destination_url NOT LIKE "%coupon%" THEN "Checkout"
	 ELSE "Other" END AS event_destination_type -- CONDITION 4
     
FROM front_interactions),

-- ---------------------------- STUDENT WHO MADE PURCHASE != 0 ------------------------
student_purchases AS (SELECT *,
CASE WHEN purchase_type = 0 THEN "Monthly"
	 WHEN purchase_type = 1 THEN "Quaterly"
     WHEN purchase_type = 2 THEN "Annual"
END AS plan_type,
MIN(date_purchased) OVER (PARTITION BY user_id) AS first_purchase_date

FROM student_purchases
WHERE purchase_price <> 0 -- CONDITION 3
LIMIT 1000),

-- -------------------------------- FINAL BASE ----------------------------------
final_base AS (SELECT sp.user_id,session_id,plan_type,CONCAT(event_source_type,'-',event_destination_type) AS event_type,first_purchase_date,event_date
FROM student_purchases sp
LEFT JOIN front_visitors v
ON v.user_id = sp.user_id
LEFT JOIN interactions_base i
ON i.visitor_id = v.visitor_id
WHERE (first_purchase_date BETWEEN "2023-01-01" AND "2023-03-31") -- CONDITION 1
AND event_date < first_purchase_date -- CONDITION 2
ORDER BY user_id,event_date)

SELECT user_id,session_id,plan_type AS subscription_type,
group_concat(event_type  SEPARATOR '**') AS journey
FROM final_base
WHERE session_id IS NOT NULL
GROUP BY user_id,session_id,plan_type;