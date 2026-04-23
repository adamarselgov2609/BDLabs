CREATE OR REPLACE PROCEDURE create_booking(
    p_listing_id BIGINT,
    p_guest_id BIGINT,
    p_start_date DATE,
    p_end_date DATE,
    p_guest_count INTEGER,
    OUT p_booking_id BIGINT,
    OUT p_message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_price DECIMAL(10,2);
    v_is_available BOOLEAN;
    v_listing_exists BOOLEAN;
    v_guest_exists BOOLEAN;
BEGIN
 
    SELECT EXISTS(SELECT 1 FROM listings WHERE listing_id = p_listing_id AND is_active = TRUE)
    INTO v_listing_exists;
    
    IF NOT v_listing_exists THEN
        RAISE EXCEPTION 'Объявление с ID % не найдено или неактивно', p_listing_id;
    END IF;
    
    
    SELECT EXISTS(SELECT 1 FROM users WHERE user_id = p_guest_id AND role IN ('guest', 'admin'))
    INTO v_guest_exists;
    
    IF NOT v_guest_exists THEN
        RAISE EXCEPTION 'Пользователь с ID % не найден или не является гостем', p_guest_id;
    END IF;
    
    
    IF p_start_date >= p_end_date THEN
        RAISE EXCEPTION 'Дата начала должна быть раньше даты окончания';
    END IF;
    
    IF p_start_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Нельзя бронировать прошедшие даты';
    END IF;
    
    
    v_is_available := check_booking_availability(p_listing_id, p_start_date, p_end_date);
    
    IF NOT v_is_available THEN
        RAISE EXCEPTION 'Выбранные даты уже заняты';
    END IF;
    
    
    v_total_price := calculate_booking_price(p_listing_id, p_start_date, p_end_date, p_guest_count);
    
    
    INSERT INTO bookings (listing_id, guest_id, start_date, end_date, guest_count, total_price, status, created_at)
    VALUES (p_listing_id, p_guest_id, p_start_date, p_end_date, p_guest_count, v_total_price, 'pending', CURRENT_TIMESTAMP)
    RETURNING booking_id INTO p_booking_id;
    
    p_message := 'Бронирование успешно создано. ID: ' || p_booking_id || ', Сумма: ' || v_total_price;
    
EXCEPTION
    WHEN OTHERS THEN
        p_booking_id := NULL;
        p_message := 'Ошибка: ' || SQLERRM;
        RAISE NOTICE '%', p_message;
END;
$$;


CREATE OR REPLACE PROCEDURE cancel_booking(
    p_booking_id BIGINT,
    OUT p_message TEXT,
    p_reason TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR(50);
    v_start_date DATE;
    v_days_until_start INTEGER;
    v_payment_amount DECIMAL(10,2);
    v_refund_amount DECIMAL(10,2);
    v_payment_id BIGINT;
BEGIN
    SELECT status, start_date 
    INTO v_current_status, v_start_date
    FROM bookings 
    WHERE booking_id = p_booking_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Бронирование с ID % не найдено', p_booking_id;
    END IF;
    
    IF v_current_status IN ('cancelled', 'completed') THEN
        RAISE EXCEPTION 'Невозможно отменить бронирование в статусе %', v_current_status;
    END IF;
    
 
    SELECT payment_id, amount 
    INTO v_payment_id, v_payment_amount
    FROM payments 
    WHERE booking_id = p_booking_id AND status = 'completed'
    LIMIT 1;

    v_days_until_start := v_start_date - CURRENT_DATE;
    
    IF v_payment_id IS NULL THEN
        v_refund_amount := 0;
        p_message := 'Оплата не найдена или еще не проведена.';
    ELSE
        IF v_days_until_start >= 14 THEN
            v_refund_amount := v_payment_amount; 
            p_message := 'Полный возврат средств: ' || v_refund_amount;
        ELSIF v_days_until_start >= 7 THEN
            v_refund_amount := v_payment_amount * 0.5; 
            p_message := 'Частичный возврат (50%): ' || v_refund_amount;
        ELSE
            v_refund_amount := 0; 
            p_message := 'Срок бесплатной отмены истек (менее 7 дней). Возврат 0.';
        END IF;
    END IF;
    
    UPDATE bookings 
    SET status = 'cancelled'
    WHERE booking_id = p_booking_id;
    
    IF v_refund_amount > 0 THEN
        UPDATE payments 
        SET status = CASE 
                        WHEN v_refund_amount = v_payment_amount THEN 'refunded' 
                        ELSE 'partially_refunded' 
                     END,
           
            notes = COALESCE(notes, '') || ' Возвращено: ' || v_refund_amount
        WHERE payment_id = v_payment_id;
    END IF;
    
    p_message := 'Бронирование успешно отменено. ' || p_message;

EXCEPTION
    WHEN OTHERS THEN
        p_message := 'Ошибка отмены: ' || SQLERRM;
        RAISE EXCEPTION '%', p_message; 
END;
$$;



CREATE OR REPLACE PROCEDURE refresh_host_statistics()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO host_statistics (host_id, total_listings, active_listings, total_completed_bookings, total_revenue, avg_rating, last_updated)
    SELECT 
        u.user_id,
        COUNT(DISTINCT l.listing_id) AS total_listings,
        COUNT(DISTINCT CASE WHEN l.is_active THEN l.listing_id END) AS active_listings,
        COUNT(CASE WHEN b.status = 'completed' THEN 1 END) AS total_completed_bookings,
        COALESCE(SUM(CASE WHEN b.status = 'completed' THEN b.total_price ELSE 0 END), 0) AS total_revenue,
        COALESCE(AVG(r.rating), 0) AS avg_rating,
        CURRENT_TIMESTAMP
    FROM users u
    LEFT JOIN listings l ON u.user_id = l.host_id
    LEFT JOIN bookings b ON l.listing_id = b.listing_id
    LEFT JOIN reviews r ON b.booking_id = r.booking_id
    WHERE u.role = 'host'
    GROUP BY u.user_id
    ON CONFLICT (host_id) 
    DO UPDATE SET
        total_listings = EXCLUDED.total_listings,
        active_listings = EXCLUDED.active_listings,
        total_completed_bookings = EXCLUDED.total_completed_bookings,
        total_revenue = EXCLUDED.total_revenue,
        avg_rating = EXCLUDED.avg_rating,
        last_updated = EXCLUDED.last_updated;
    
    RAISE NOTICE 'Статистика хостов обновлена. Обработано % хостов.', (SELECT COUNT(*) FROM host_statistics);
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка при обновлении статистики: %', SQLERRM;
		RAISE;
END;
$$;