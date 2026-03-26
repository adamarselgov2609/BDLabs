
SELECT 
    city,
    COUNT(*) AS listings_count,
    ROUND(AVG(price_per_night), 0) AS avg_price_per_night,
    MIN(price_per_night) AS min_price,
    MAX(price_per_night) AS max_price,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_listings
FROM listings
GROUP BY city
ORDER BY avg_price_per_night DESC;


SELECT 
    u.user_id,
    u.full_name AS host_name,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_price) AS total_revenue,
    ROUND(AVG(b.total_price), 0) AS avg_booking_value,
    COUNT(DISTINCT b.guest_id) AS unique_guests
FROM users u
LEFT JOIN listings l ON u.user_id = l.host_id
LEFT JOIN bookings b ON l.listing_id = b.listing_id AND b.status = 'completed'
WHERE u.role = 'host'
GROUP BY u.user_id, u.full_name
ORDER BY total_revenue DESC NULLS LAST;


SELECT 
    u.user_id,
    u.full_name AS host_name,
    COUNT(r.review_id) AS reviews_count,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(CASE WHEN r.rating = 5 THEN 1 END) AS five_star_reviews
FROM users u
JOIN listings l ON u.user_id = l.host_id
JOIN bookings b ON l.listing_id = b.listing_id
JOIN reviews r ON b.booking_id = r.booking_id
WHERE b.status = 'completed'
GROUP BY u.user_id, u.full_name
HAVING COUNT(r.review_id) >= 1
ORDER BY avg_rating DESC;


SELECT 
    DATE_TRUNC('month', start_date) AS month,
    COUNT(*) AS bookings_count,
    SUM(total_price) AS total_revenue,
    ROUND(AVG(total_price), 0) AS avg_booking_value,
    COUNT(DISTINCT guest_id) AS unique_guests,
    COUNT(DISTINCT listing_id) AS active_listings
FROM bookings
WHERE status IN ('completed', 'confirmed')
GROUP BY DATE_TRUNC('month', start_date)
ORDER BY month;