CREATE OR REPLACE FUNCTION audit_price_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.price_per_night IS DISTINCT FROM NEW.price_per_night THEN
        INSERT INTO price_change_audit (listing_id, old_price, new_price, changed_by, reason)
        VALUES (NEW.listing_id, OLD.price_per_night, NEW.price_per_night, CURRENT_USER, 'Автоматический аудит');
    END IF;
    
    RETURN NEW;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка аудита цен: %', SQLERRM;
        RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_price_change_audit ON listings;
CREATE TRIGGER trg_price_change_audit
    AFTER UPDATE OF price_per_night ON listings
    FOR EACH ROW
    EXECUTE FUNCTION audit_price_change();

CREATE OR REPLACE FUNCTION audit_booking_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO booking_status_audit (booking_id, old_status, new_status, changed_by, change_date)
        VALUES (NEW.booking_id, OLD.status, NEW.status, CURRENT_USER, CURRENT_TIMESTAMP);
    END IF;
    
    RETURN NEW;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка аудита статуса бронирования: %', SQLERRM;
        RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_booking_status_audit ON bookings;
CREATE TRIGGER trg_booking_status_audit
    AFTER UPDATE OF status ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION audit_booking_status_change();


CREATE OR REPLACE FUNCTION check_review_business_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_booking_status VARCHAR(50);
    v_booking_end_date DATE;
BEGIN

    SELECT status, end_date INTO v_booking_status, v_booking_end_date
    FROM bookings 
    WHERE booking_id = NEW.booking_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Бронирование с ID % не найдено', NEW.booking_id;
    END IF;
    
    IF v_booking_status != 'completed' THEN
        RAISE EXCEPTION 'Отзыв можно оставить только для завершённого бронирования. Текущий статус: %', v_booking_status;
    END IF;
    

    IF v_booking_end_date > CURRENT_DATE THEN
        RAISE EXCEPTION 'Отзыв можно оставить только после завершения проживания (после %)', v_booking_end_date;
    END IF;
    
    IF NEW.rating < 1 OR NEW.rating > 5 THEN
        RAISE EXCEPTION 'Рейтинг должен быть от 1 до 5. Получено: %', NEW.rating;
    END IF;
    
    RETURN NEW;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка при создании отзыва: %', SQLERRM;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_review_rules ON reviews;
CREATE TRIGGER trg_check_review_rules
    BEFORE INSERT ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION check_review_business_rules();


CREATE OR REPLACE FUNCTION auto_refresh_host_statistics()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    PERFORM refresh_host_statistics();
    RETURN NULL;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка автообновления статистики: %', SQLERRM;
        RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_refresh_host_stats ON bookings;
CREATE TRIGGER trg_auto_refresh_host_stats
    AFTER UPDATE OF status ON bookings  
    FOR EACH STATEMENT                    
    EXECUTE FUNCTION auto_refresh_host_statistics();