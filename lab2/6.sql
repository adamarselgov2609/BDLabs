CREATE OR REPLACE VIEW active_listings_with_rating AS
SELECT 
    l.listing_id,
    l.title,
    l.property_type,
    l.price_per_night,
    l.max_guests,
    l.bedrooms,
    l.bathrooms,
    l.city,
    l.address,
    u.user_id AS host_id,
    u.full_name AS host_name,
    u.phone AS host_phone,
    u.is_verified AS host_verified,
    COALESCE(AVG(r.rating), 0) AS avg_rating,
    COUNT(DISTINCT r.review_id) AS reviews_count,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    COUNT(CASE WHEN b.status = 'confirmed' THEN 1 END) AS upcoming_bookings
FROM listings l
INNER JOIN users u ON l.host_id = u.user_id
LEFT JOIN bookings b ON l.listing_id = b.listing_id
LEFT JOIN reviews r ON b.booking_id = r.booking_id
WHERE l.is_active = TRUE
GROUP BY l.listing_id, l.title, l.property_type, l.price_per_night, l.max_guests, 
         l.bedrooms, l.bathrooms, l.city, l.address, u.user_id, u.full_name, u.phone, u.is_verified;


SELECT * FROM active_listings_with_rating WHERE avg_rating >= 4.5 ORDER BY price_per_night;


CREATE OR REPLACE VIEW host_financial_summary AS
SELECT 
    u.user_id,
    u.full_name AS host_name,
    u.email,
    u.is_verified,
    COUNT(DISTINCT l.listing_id) AS total_listings,
    COUNT(DISTINCT CASE WHEN l.is_active THEN l.listing_id END) AS active_listings,
    COUNT(b.booking_id) AS total_bookings,
    COUNT(CASE WHEN b.status = 'completed' THEN 1 END) AS completed_bookings,
    COALESCE(SUM(CASE WHEN b.status = 'completed' THEN b.total_price ELSE 0 END), 0) AS total_revenue,
    COALESCE(SUM(CASE WHEN b.status = 'completed' AND b.end_date >= CURRENT_DATE - INTERVAL '30 days' THEN b.total_price ELSE 0 END), 0) AS revenue_last_30days,
    COALESCE(ROUND(AVG(CASE WHEN b.status = 'completed' THEN b.total_price END), 0), 0) AS avg_booking_value,
    COALESCE(ROUND(AVG(r.rating), 1), 0) AS avg_host_rating
FROM users u
LEFT JOIN listings l ON u.user_id = l.host_id
LEFT JOIN bookings b ON l.listing_id = b.listing_id
LEFT JOIN reviews r ON b.booking_id = r.booking_id
WHERE u.role = 'host'
GROUP BY u.user_id, u.full_name, u.email, u.is_verified;


SELECT * FROM host_financial_summary WHERE total_revenue > 50000 ORDER BY total_revenue DESC;


CREATE OR REPLACE VIEW guest_activity_analytics AS
SELECT 
    u.user_id,
    u.full_name AS guest_name,
    u.email,
    u.is_verified,
    u.created_at AS registered_at,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    COUNT(DISTINCT CASE WHEN b.status = 'completed' THEN b.booking_id END) AS completed_bookings,
    COUNT(DISTINCT CASE WHEN b.status = 'cancelled' THEN b.booking_id END) AS cancelled_bookings,
    COALESCE(SUM(CASE WHEN b.status = 'completed' THEN b.total_price ELSE 0 END), 0) AS total_spent,
    COALESCE(SUM(CASE WHEN b.status = 'completed' AND b.end_date >= CURRENT_DATE - INTERVAL '30 days' THEN b.total_price ELSE 0 END), 0) AS spent_last_30days,
    MAX(b.end_date) AS last_stay_date,
    COUNT(DISTINCT r.review_id) AS reviews_left,
    COALESCE(ROUND(AVG(r.rating), 1), 0) AS avg_rating_given,
    COUNT(DISTINCT l.city) AS unique_cities_visited
FROM users u
LEFT JOIN bookings b ON u.user_id = b.guest_id
LEFT JOIN reviews r ON b.booking_id = r.booking_id
LEFT JOIN listings l ON b.listing_id = l.listing_id
WHERE u.role = 'guest'
GROUP BY u.user_id, u.full_name, u.email, u.is_verified, u.created_at;


SELECT * FROM guest_activity_analytics WHERE total_spent > 50000 ORDER BY total_spent DESC;