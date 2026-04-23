INSERT INTO bookings (listing_id, guest_id, start_date, end_date, guest_count, total_price, status, created_at)
SELECT
    (SELECT listing_id FROM listings OFFSET floor(random() * 10000)::INTEGER LIMIT 1),
    (SELECT user_id FROM users WHERE role IN ('guest', 'admin') OFFSET floor(random() * 18000)::INTEGER LIMIT 1),
    start_dt::DATE,
    (start_dt + (floor(random() * 14 + 1)::INTEGER || ' days')::INTERVAL)::DATE,
    floor(random() * 6 + 1)::INTEGER,
    round((random() * 100000 + 2000)::numeric, 2),
    (ARRAY['pending', 'confirmed', 'completed', 'cancelled'])[floor(random() * 4 + 1)],
    CURRENT_TIMESTAMP - (floor(random() * 730)::INTEGER || ' days')::INTERVAL
FROM generate_series(1, 10000) AS gs,
     LATERAL (SELECT CURRENT_DATE - (floor(random() * 730)::INTEGER || ' days')::INTERVAL AS start_dt) s;




UPDATE listings 
SET price_per_night = price_per_night * 1.1
WHERE listing_id IN (
    SELECT listing_id FROM listings 
    WHERE is_active = TRUE 
    ORDER BY random() 
    LIMIT 10000
);




DROP INDEX IF EXISTS idx_bookings_status_listing;
DROP INDEX IF EXISTS idx_bookings_guest_status_date;
DROP INDEX IF EXISTS idx_bookings_guest_completed;
DROP INDEX IF EXISTS idx_bookings_status_startdate;





INSERT INTO bookings (listing_id, guest_id, start_date, end_date, guest_count, total_price, status, created_at)
SELECT
    (SELECT listing_id FROM listings OFFSET floor(random() * 10000)::INTEGER LIMIT 1),
    (SELECT user_id FROM users WHERE role IN ('guest', 'admin') OFFSET floor(random() * 18000)::INTEGER LIMIT 1),
    start_dt::DATE,
    (start_dt + (floor(random() * 14 + 1)::INTEGER || ' days')::INTERVAL)::DATE,
    floor(random() * 6 + 1)::INTEGER,
    round((random() * 100000 + 2000)::numeric, 2),
    (ARRAY['pending', 'confirmed', 'completed', 'cancelled'])[floor(random() * 4 + 1)],
    CURRENT_TIMESTAMP - (floor(random() * 730)::INTEGER || ' days')::INTERVAL
FROM generate_series(1, 10000) AS gs,
     LATERAL (SELECT CURRENT_DATE - (floor(random() * 730)::INTEGER || ' days')::INTERVAL AS start_dt) s;






UPDATE listings 
SET price_per_night = price_per_night * 1.05
WHERE listing_id IN (
    SELECT listing_id FROM listings 
    WHERE is_active = TRUE 
    ORDER BY random() 
    LIMIT 10000
);






CREATE INDEX IF NOT EXISTS idx_bookings_status_listing 
ON bookings (status, listing_id) INCLUDE (booking_id);

CREATE INDEX IF NOT EXISTS idx_bookings_guest_status_date 
ON bookings (guest_id, status, start_date) INCLUDE (end_date, total_price);

CREATE INDEX IF NOT EXISTS idx_bookings_guest_completed 
ON bookings (guest_id, start_date) INCLUDE (end_date, total_price, status)
WHERE status = 'completed';

CREATE INDEX IF NOT EXISTS idx_bookings_status_startdate 
ON bookings (status, start_date) INCLUDE (end_date, total_price, guest_id, listing_id);