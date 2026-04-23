ALTER TABLE listings DISABLE TRIGGER trg_price_change_audit;
ALTER TABLE bookings DISABLE TRIGGER trg_booking_status_audit;
ALTER TABLE reviews DISABLE TRIGGER trg_check_review_rules;



DELETE FROM bookings WHERE booking_id > 14;
DELETE FROM listings WHERE listing_id > 9;
DELETE FROM users WHERE user_id > 11;




INSERT INTO users (email, password_hash, full_name, phone, role, is_verified, verification_date, created_at)
SELECT
    'gen_user' || gs || '@airbnb-test.ru',
    'hash_gen_' || gs,
    'GenUser ' || gs,
    '+7' || (9000000000 + gs)::TEXT,
    CASE
        WHEN gs % 10 = 0 THEN 'host'
        WHEN gs % 10 = 1 THEN 'admin'
        ELSE 'guest'
    END,
    CASE WHEN gs % 5 = 0 THEN TRUE ELSE FALSE END,
    CASE WHEN gs % 5 = 0
         THEN CURRENT_TIMESTAMP - (floor(random() * 365)::INTEGER || ' days')::INTERVAL
         ELSE NULL
    END,
    CURRENT_TIMESTAMP - (floor(random() * 730)::INTEGER || ' days')::INTERVAL
FROM generate_series(1, 10000) AS gs;





INSERT INTO listings (host_id, title, description, property_type, price_per_night, max_guests, bedrooms, bathrooms, address, city, country, is_active, created_at)
SELECT
    (SELECT user_id FROM users WHERE role = 'host' OFFSET floor(random() * 1000)::INTEGER LIMIT 1),
    'GenListing #' || gs || ': ' || (ARRAY['Уютная квартира', 'Просторный дом', 'Студия', 'Апартаменты', 'Таунхаус', 'Лофт', 'Комната', 'Коттедж'])[floor(random() * 8 + 1)],
    'Сгенерированное описание объявления номер ' || gs,
    (ARRAY['apartment', 'house', 'private_room', 'apartment', 'house', 'apartment', 'private_room', 'apartment'])[floor(random() * 8 + 1)],
    round((random() * 20000 + 1500)::numeric, 2),
    floor(random() * 8 + 1)::INTEGER,
    floor(random() * 5 + 1)::INTEGER,
    round((random() * 3 + 1)::numeric, 1),
    'ул. ' || (ARRAY['Ленина', 'Мира', 'Пушкина', 'Гагарина', 'Советская', 'Центральная', 'Садовая', 'Лесная'])[floor(random() * 8 + 1)] || ', д. ' || floor(random() * 100 + 1)::TEXT,
    (ARRAY['Москва', 'Санкт-Петербург', 'Сочи', 'Казань', 'Екатеринбург', 'Краснодар', 'Новосибирск', 'Калининград'])[floor(random() * 8 + 1)],
    'Россия',
    random() > 0.15,
    CURRENT_TIMESTAMP - (floor(random() * 500)::INTEGER || ' days')::INTERVAL
FROM generate_series(1, 5000) AS gs;






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
FROM generate_series(1, 1200000) AS gs,
     LATERAL (SELECT CURRENT_DATE - (floor(random() * 730)::INTEGER || ' days')::INTERVAL AS start_dt) s;





SELECT COUNT(*) FROM bookings;
UPDATE bookings 
SET end_date = start_date + (floor(random() * 14 + 1)::INTEGER || ' days')::INTERVAL
WHERE end_date <= start_date;





ANALYZE users;
ANALYZE listings;
ANALYZE bookings;




ALTER TABLE listings ENABLE TRIGGER trg_price_change_audit;
ALTER TABLE bookings ENABLE TRIGGER trg_booking_status_audit;
ALTER TABLE reviews ENABLE TRIGGER trg_check_review_rules;




SELECT 'users' AS tbl, COUNT(*) AS cnt FROM users
UNION ALL
SELECT 'listings', COUNT(*) FROM listings
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings;