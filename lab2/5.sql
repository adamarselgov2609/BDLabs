SELECT 
    b.booking_id,
    g.full_name AS guest_name,
    g.email AS guest_email,
    l.title AS listing_title,
    l.city,
    u.full_name AS host_name,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    p.payment_status,
    r.rating,
    r.comment
FROM bookings b
INNER JOIN users g ON b.guest_id = g.user_id
INNER JOIN listings l ON b.listing_id = l.listing_id
INNER JOIN users u ON l.host_id = u.user_id
LEFT JOIN payments p ON b.booking_id = p.booking_id
LEFT JOIN reviews r ON b.booking_id = r.booking_id
WHERE b.status IN ('confirmed', 'completed')
ORDER BY b.start_date DESC;


SELECT 
    l.listing_id,
    l.title,
    l.price_per_night,
    l.city,
    u.full_name AS host_name,
    u.phone AS host_phone,
    COUNT(b.booking_id) AS total_bookings,
    COUNT(CASE WHEN b.status = 'completed' THEN 1 END) AS completed_bookings,
    COALESCE(ROUND(AVG(r.rating), 1), 0) AS avg_rating
FROM listings l
INNER JOIN users u ON l.host_id = u.user_id
LEFT JOIN bookings b ON l.listing_id = b.listing_id
LEFT JOIN reviews r ON b.booking_id = r.booking_id
WHERE l.is_active = TRUE
GROUP BY l.listing_id, l.title, l.price_per_night, l.city, u.full_name, u.phone
ORDER BY total_bookings DESC;


SELECT 
    u.user_id,
    u.full_name AS guest_name,
    u.email,
    u.is_verified,
    u.created_at AS registered_at,
    COUNT(b.booking_id) AS total_bookings,
    SUM(CASE WHEN b.status = 'completed' THEN b.total_price ELSE 0 END) AS total_spent,
    MAX(b.start_date) AS last_booking_date,
    AVG(r.rating) AS avg_given_rating
FROM users u
LEFT JOIN bookings b ON u.user_id = b.guest_id
LEFT JOIN reviews r ON b.booking_id = r.booking_id
WHERE u.role = 'guest'
GROUP BY u.user_id, u.full_name, u.email, u.is_verified, u.created_at
ORDER BY total_spent DESC NULLS LAST;


SELECT 
    l.listing_id,
    l.title,
    l.city,
    u.full_name AS host_name,
    COUNT(b.booking_id) AS bookings_count
FROM listings l
INNER JOIN users u ON l.host_id = u.user_id
LEFT JOIN bookings b ON l.listing_id = b.listing_id AND b.status = 'completed'
LEFT JOIN reviews r ON b.booking_id = r.booking_id
WHERE r.review_id IS NULL AND l.is_active = TRUE
GROUP BY l.listing_id, l.title, l.city, u.full_name
HAVING COUNT(b.booking_id) > 0
ORDER BY bookings_count DESC;