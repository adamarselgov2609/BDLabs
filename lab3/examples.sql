DO $$
DECLARE
    v_booking_id BIGINT;
    v_message TEXT;
BEGIN
    CALL create_booking(
        p_listing_id := 1,
        p_guest_id := 5,
        p_start_date := '2024-06-15',
        p_end_date := '2024-06-20',
        p_guest_count := 2,
        p_booking_id := v_booking_id,
        p_message := v_message
    );
    RAISE NOTICE 'Результат: %', v_message;
END;
$$;

DO $$
DECLARE
    v_booking_id BIGINT;
    v_message TEXT;
BEGIN
    CALL create_booking(
        p_listing_id := 1,
        p_guest_id := 5,
        p_start_date := '2026-06-15',
        p_end_date := '2026-06-20',
        p_guest_count := 2,
        p_booking_id := v_booking_id,
        p_message := v_message
    );
    RAISE NOTICE 'Результат: %', v_message;
END;
$$;


DO $$
DECLARE
    v_booking_id BIGINT;
    v_message TEXT;
BEGIN
    CALL create_booking(
        p_listing_id := 1,
        p_guest_id := 6,
        p_start_date := '2024-06-16',
        p_end_date := '2024-06-22',
        p_guest_count := 2,
        p_booking_id := v_booking_id,
        p_message := v_message
    );
    RAISE NOTICE 'Результат: %', v_message;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ожидаемая ошибка: %', SQLERRM;
END;
$$;

DO $$
DECLARE
    v_booking_id BIGINT;
    v_message TEXT;
BEGIN
    CALL create_booking(
        p_listing_id := 1,
        p_guest_id := 6,
        p_start_date := '2026-04-28',
        p_end_date := '2026-05-20',
        p_guest_count := 2,
        p_booking_id := v_booking_id,
        p_message := v_message
    );
    RAISE NOTICE 'Результат: %', v_message;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ожидаемая ошибка: %', SQLERRM;
END;
$$;


DO $$
DECLARE
    v_message TEXT;
BEGIN
    CALL cancel_booking(
        p_booking_id := 14, 
        p_reason := 'Передумали',
        p_message := v_message
    );
    RAISE NOTICE '%', v_message;
END;
$$;


UPDATE listings 
SET price_per_night = 6000 
WHERE listing_id = 1 AND title = 'Уютная студия в центре Москвы';


SELECT * FROM price_change_audit ORDER BY audit_id DESC LIMIT 5;


UPDATE bookings 
SET status = 'confirmed' 
WHERE booking_id = 14;


SELECT * FROM booking_status_audit ORDER BY audit_id DESC LIMIT 5;


DO $$
BEGIN
    INSERT INTO reviews (booking_id, rating, comment, created_at)
    VALUES (14, 5, 'Отличное место!', CURRENT_TIMESTAMP);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка (ожидаемо): %', SQLERRM;
END;
$$;


UPDATE bookings SET status = 'completed' WHERE booking_id = 14;

DELETE FROM reviews WHERE booking_id = 14;

INSERT INTO reviews (booking_id, rating, comment, created_at)
VALUES (14, 5, 'Отличное место, всё понравилось!', CURRENT_TIMESTAMP);


CALL refresh_host_statistics();


SELECT * FROM host_statistics ORDER BY total_revenue DESC;


SELECT 
    listing_id,
    title,
    price_per_night,
    (get_host_rating(host_id)).* 
FROM listings 
WHERE listing_id = 1;


SELECT 
    check_booking_availability(1, '2024-07-01', '2024-07-05') AS is_available_july,
    check_booking_availability(1, '2024-06-16', '2024-06-22') AS is_available_june;


SELECT 
    calculate_booking_price(1, '2024-06-15', '2024-06-20', 2) AS summer_price,
    calculate_booking_price(1, '2024-12-25', '2025-01-05', 2) AS new_year_price;


DO $$
DECLARE
    v_booking_id BIGINT;
    v_message TEXT;
BEGIN
    CALL create_booking(
        p_listing_id := 999, 
        p_guest_id := 5,
        p_start_date := '2024-07-01',
        p_end_date := '2024-07-05',
        p_guest_count := 10, 
        p_booking_id := v_booking_id,
        p_message := v_message
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Перехвачена ошибка: %', SQLERRM;
END;
$$;


SELECT * FROM active_listings_with_rating WHERE avg_rating >= 4 ORDER BY price_per_night;


SELECT * FROM host_financial_summary WHERE total_revenue > 0 ORDER BY total_revenue DESC;


SELECT * FROM guest_activity_analytics WHERE total_bookings > 0 ORDER BY total_spent DESC;


SELECT * FROM price_change_audit ORDER BY change_date DESC;


SELECT * FROM booking_status_audit ORDER BY change_date DESC;