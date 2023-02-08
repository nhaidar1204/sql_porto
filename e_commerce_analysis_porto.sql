-- question 1
SELECT 
MONTH(website_sessions.created_at) AS mo,
MIN(website_sessions.created_at) AS date_start,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
AND utm_source = 'gsearch'
GROUP BY 1;

-- question 2
SELECT 
MONTH(website_sessions.created_at) AS mo,
MIN(website_sessions.created_at) AS date_start,
COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign ='nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_sessions,
COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign ='nonbrand' THEN orders.order_id ELSE NULL END) AS nonbrand_order,
COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign ='nonbrand' THEN orders.order_id ELSE NULL END) / 
COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign ='nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_cvr,
COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign ='brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign ='brand' THEN orders.order_id ELSE NULL END) AS brand_order,
COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign ='brand' THEN orders.order_id ELSE NULL END) /
COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign ='brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_cvr
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
AND utm_source = 'gsearch'
GROUP BY 1;

-- question 3
SELECT 
MONTH(website_sessions.created_at) AS mo,
MIN(website_sessions.created_at) AS date_start,
COUNT(DISTINCT CASE WHEN website_sessions.device_type ='mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions,
COUNT(DISTINCT CASE WHEN website_sessions.device_type ='mobile' THEN orders.order_id ELSE NULL END) AS mobile_order,
COUNT(DISTINCT CASE WHEN website_sessions.device_type ='mobile' THEN orders.order_id ELSE NULL END) / 
COUNT(DISTINCT CASE WHEN website_sessions.device_type ='mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_cvr,
COUNT(DISTINCT CASE WHEN website_sessions.device_type ='desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions,
COUNT(DISTINCT CASE WHEN website_sessions.device_type ='desktop' THEN orders.order_id ELSE NULL END) AS desktop_order,
COUNT(DISTINCT CASE WHEN website_sessions.device_type ='desktop' THEN orders.order_id ELSE NULL END) /
COUNT(DISTINCT CASE WHEN website_sessions.device_type ='desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_cvr
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
AND utm_campaign = 'nonbrand'
AND utm_source = 'gsearch'
GROUP BY 1;

-- question 4
SELECT 
MONTH(created_at) AS mo,
MIN(created_at) AS start_date,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) /
COUNT(DISTINCT website_sessions.website_session_id)  AS g_search_trafic,
COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) /
COUNT(DISTINCT website_sessions.website_session_id)  AS b_search_trafic,
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN website_sessions.website_session_id ELSE NULL END) /
COUNT(DISTINCT website_sessions.website_session_id)  AS organic_trafic,
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) /
COUNT(DISTINCT website_sessions.website_session_id)  AS direct_session_trafic
FROM website_sessions
WHERE created_at < '2012-11-27'
GROUP BY 1;

-- question 5
SELECT 
year(website_sessions.created_at) AS years,
month(website_sessions.created_at) AS monthly,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_cvr
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1,2;

-- question 6
-- Step 1: we need to search first website_pageview_id for new lander test
SELECT 
MIN(website_pageview_id)
FROM website_pageviews
WHERE pageview_url= '/lander-1';

-- Step 2: we need to search first_pageview_id per website_sessions
CREATE TEMPORARY TABLE sessions_w_page_view
SELECT 
website_sessions.website_session_id,
MIN(website_pageview_id) AS first_pv_id
FROM website_pageviews
INNER JOIN website_sessions
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at < '2012-07-28'
AND utm_campaign = 'nonbrand'
AND website_pageview_id >=23504 -- we selected first website_pageview_id into to filter 
AND utm_source  = 'gsearch'
GROUP BY 1;

-- Step 3: we need to search first saw pageview_url per website session_id
CREATE TEMPORARY TABLE first_pageviews_session_id
SELECT 
sessions_w_page_view.website_session_id,
website_pageviews.pageview_url AS first_pageview_url
FROM sessions_w_page_view
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = sessions_w_page_view.website_session_id
WHERE pageview_url IN ('/home','/lander-1');

-- step 4 : we need search order per website_session_id and first pageview customer has been seen
CREATE TEMPORARY TABLE sessions_with_order
SELECT 
first_pageviews_session_id.website_session_id,
first_pageviews_session_id.first_pageview_url,
orders.order_id,
orders.price_usd
FROM first_pageviews_session_id
LEFT JOIN orders 
ON orders.website_session_id = first_pageviews_session_id.website_session_id;

-- step 5 : in this step we need search total of sessions and total of order and convertion rate from session to order
SELECT 
first_pageview_url,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT order_id) AS orders,
SUM(price_usd) AS revenue,
COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS order_to_session_cvr,
SUM(price_usd) / COUNT(DISTINCT website_session_id) AS revenue_per_session
FROM sessions_with_order
GROUP BY 1;

-- question 7
-- step 1 : we make subqery to define flag in each step of pageviews
SELECT 
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN website_pageviews.pageview_url = '/home' THEN 1 ELSE 0 END AS home_flag,
CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS products_flag,
CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS fuzzy_flag,
CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_flag,
CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_flag,
CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_flag,
CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_flag
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at < '2012-07-28'
AND website_sessions.created_at > '2012-06-19'
AND website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
ORDER BY website_sessions.website_session_id , website_sessions.created_at;

-- step 2 : we need to search max flags in each website_session_id to know journey of each customer in buying product
CREATE TEMPORARY TABLE funnel_flags
SELECT
website_session_id,
MAX(home_flag) AS saw_homepage,
MAX(custom_lander) AS saw_custom_lander,
MAX(products_flag) AS products_made_it,
MAX(fuzzy_flag) AS fuzzy_made_it,
MAX(cart_flag) AS cart_made_it,
MAX(shipping_flag) AS shipping_made_it,
MAX(billing_flag) AS billing_made_it,
MAX(thankyou_flag) AS thankyou_made_it
FROM ( SELECT 
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN website_pageviews.pageview_url = '/home' THEN 1 ELSE 0 END AS home_flag,
CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS products_flag,
CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS fuzzy_flag,
CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_flag,
CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_flag,
CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_flag,
CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_flag
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at < '2012-07-28'
AND website_sessions.created_at > '2012-06-19'
AND website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
ORDER BY website_sessions.website_session_id , website_sessions.created_at) AS agg_flag
GROUP BY 1;

-- step 3 : we need to search journey of customer breakdown by each segments
SELECT 
CASE 
WHEN saw_homepage = 1 THEN 'homepage_segments'
WHEN saw_custom_lander = 1 THEN 'custom_lander_segments'
ELSE 'error_check_again'
END AS segments,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS to_product,
COUNT(DISTINCT CASE WHEN fuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_fuzzy,
COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM funnel_flags
GROUP BY 1;
-- we need to search click rates in each session
SELECT 
CASE 
WHEN saw_homepage = 1 THEN 'homepage_segments'
WHEN saw_custom_lander = 1 THEN 'custom_lander_segments'
ELSE 'error_check_again'
END AS segments,
COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS lander_cilck_rate,
COUNT(DISTINCT CASE WHEN fuzzy_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS product_click_rate,
COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN fuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS fuzzy_click_rate,
COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rate,
COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_cilck_rate,
COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_cilick_rate
FROM funnel_flags
GROUP BY 1; 

-- question 8

-- based on this query we got first pageview_id for this billing pageview test is 53550
SELECT 
version_seen,
COUNT(DISTINCT website_session_id) AS sessions,
ROUND(SUM(price_usd) / COUNT(DISTINCT website_session_id),2) AS revenue_per_click
FROM (SELECT
website_pageviews.website_session_id,
website_pageviews.pageview_url AS version_seen,
orders.order_id,
orders.price_usd
FROM website_pageviews
LEFT JOIN orders
ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at > '2012-09-10'
AND website_pageviews.created_at < '2012-11-10'
AND website_pageviews.pageview_url IN ('/billing','/billing-2')) AS billing_test
GROUP BY 1;
-- we get total revenue in old version of billing pageview is $22.83
-- we get total revenue in new version of billing pageview is $31.34
-- LIFT : $8.51 per billing pageview

-- we need to search total number of billing sessions in past month
SELECT 
COUNT(website_session_id) AS billing_session_past_month
FROM website_pageviews
WHERE pageview_url IN ('/billing','/billing-2')
AND created_at BETWEEN '2012-10-27' AND '2012-11-27' -- past months

-- based on that we get number of billing_session in past month is 1193
-- LIFT : $8.51 per billing pageview
-- based on that we get revenue of billing pageview in past months is $ 10,153 