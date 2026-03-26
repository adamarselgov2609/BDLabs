INSERT INTO users (email, password_hash, full_name, phone, role, is_verified)
VALUES ('new.guest@email.com', 'hash_new123', 'Новый Гость', '+79179999999', 'guest', TRUE);

INSERT INTO listings (host_id, title, description, property_type, price_per_night, max_guests, bedrooms, bathrooms, address, city, country)
VALUES (1, 'Новая студия на Арбате', 'Современная студия в историческом центре', 'apartment', 5200.00, 2, 1, 1.0, 'ул. Арбат, д. 10', 'Москва', 'Россия');

INSERT INTO bookings (listing_id, guest_id, start_date, end_date, guest_count, total_price, status)
VALUES (2, 6, '2024-04-10', '2024-04-15', 2, 34000.00, 'pending');


UPDATE bookings 
SET status = 'confirmed' 
WHERE booking_id = 11;


UPDATE listings 
SET price_per_night = price_per_night * 0.85 
WHERE city = 'Москва' AND is_active = TRUE;


UPDATE users 
SET is_verified = TRUE, verification_date = CURRENT_TIMESTAMP 
WHERE user_id = 12;


UPDATE reviews 
SET host_response = 'Благодарим за отзыв! Рады, что вам понравилось.', 
    response_date = CURRENT_TIMESTAMP 
WHERE review_id = 3;


DELETE FROM bookings 
WHERE status = 'cancelled' 
  AND created_at < CURRENT_DATE - INTERVAL '30 days';


DELETE FROM listings 
WHERE is_active = FALSE 
  AND listing_id NOT IN (SELECT DISTINCT listing_id FROM bookings);


DELETE FROM users 
WHERE is_verified = FALSE 
  AND role = 'guest' 
  AND created_at < CURRENT_DATE - INTERVAL '90 days';