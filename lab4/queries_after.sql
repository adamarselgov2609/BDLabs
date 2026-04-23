

EXPLAIN ANALYZE
SELECT * FROM listings
WHERE city = 'Москва'
  AND property_type = 'apartment'
  AND price_per_night BETWEEN 3000 AND 10000
  AND is_active = TRUE;





EXPLAIN ANALYZE
SELECT u.user_id, u.full_name, COUNT(b.booking_id) AS booking_count
FROM users u
JOIN listings l ON u.user_id = l.host_id
JOIN bookings b ON l.listing_id = b.listing_id
WHERE b.status = 'completed'
GROUP BY u.user_id, u.full_name
ORDER BY booking_count DESC
LIMIT 20;





EXPLAIN ANALYZE
SELECT b.booking_id, b.start_date, b.end_date, b.total_price, b.status
FROM bookings b
WHERE b.guest_id = 5
  AND b.start_date >= '2025-01-01'
  AND b.status = 'completed';





EXPLAIN ANALYZE
SELECT b.booking_id, b.start_date, b.end_date, b.total_price, b.status
FROM bookings b
WHERE b.guest_id = 5
  AND b.start_date >= '2025-01-01'
  AND b.status = 'completed';





EXPLAIN ANALYZE
SELECT listing_id, title, city, price_per_night
FROM listings
WHERE title LIKE '%Студия%' OR description LIKE '%центр%';






EXPLAIN ANALYZE
SELECT b.booking_id, b.start_date, b.end_date, b.total_price,
       g.full_name AS guest_name, l.title AS listing_title,
       u.full_name AS host_name, p.status AS payment_status,
       r.rating
FROM bookings b
JOIN users g ON b.guest_id = g.user_id
JOIN listings l ON b.listing_id = l.listing_id
JOIN users u ON l.host_id = u.user_id
LEFT JOIN payments p ON b.booking_id = p.booking_id
LEFT JOIN reviews r ON b.booking_id = r.booking_id
WHERE b.status = 'completed'
  AND b.start_date >= '2025-01-01';





EXPLAIN ANALYZE
SELECT * FROM bookings
WHERE total_price > 1000;