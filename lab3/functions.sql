CREATE OR REPLACE FUNCTION check_booking_availability(
    p_listing_id BIGINT,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_conflicting_count INTEGER;
BEGIN
    
    SELECT COUNT(*)
    INTO v_conflicting_count
    FROM bookings
    WHERE listing_id = p_listing_id
      AND status IN ('confirmed', 'completed')
      AND daterange(start_date, end_date, '[]') && daterange(p_start_date, p_end_date, '[]');
    
    IF v_conflicting_count > 0 THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$;


CREATE OR REPLACE FUNCTION calculate_booking_price(
    p_listing_id BIGINT,
    p_start_date DATE,
    p_end_date DATE,
    p_guest_count INTEGER
)
RETURNS DECIMAL(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_base_price DECIMAL(10,2);
    v_nights INTEGER;
    v_season_multiplier DECIMAL(3,2) := 1.0;
    v_extra_guest_charge DECIMAL(10,2) := 0;
    v_total DECIMAL(10,2);
    v_max_guests INTEGER;
BEGIN

    SELECT price_per_night, max_guests 
    INTO v_base_price, v_max_guests
    FROM listings 
    WHERE listing_id = p_listing_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Объявление с ID % не найдено', p_listing_id;
    END IF;
    

    IF p_guest_count > v_max_guests THEN
        RAISE EXCEPTION 'Максимальное количество гостей для этого объявления: %, а запрошено: %', 
                        v_max_guests, p_guest_count;
    END IF;
    

    v_nights := p_end_date - p_start_date;
    

    IF EXTRACT(MONTH FROM p_start_date) BETWEEN 5 AND 9 THEN
        v_season_multiplier := 1.3;
    END IF;
    
  
    IF (EXTRACT(MONTH FROM p_start_date) = 12 AND EXTRACT(DAY FROM p_start_date) >= 20) OR
       (EXTRACT(MONTH FROM p_start_date) = 1 AND EXTRACT(DAY FROM p_start_date) <= 10) THEN
        v_season_multiplier := v_season_multiplier * 1.5;
    END IF;
    
  
    IF p_guest_count > 2 THEN
        v_extra_guest_charge := (p_guest_count - 2) * 500 * v_nights;
    END IF;
    
    
    v_total := (v_base_price * v_nights * v_season_multiplier) + v_extra_guest_charge;
    
    RETURN ROUND(v_total, 2);
END;
$$;


CREATE OR REPLACE FUNCTION get_host_rating(p_host_id BIGINT)
RETURNS TABLE(
    avg_rating NUMERIC(3,2),
    total_reviews BIGINT,
    five_star_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(ROUND(AVG(r.rating), 2), 0)::NUMERIC(3,2),
        COUNT(r.review_id)::BIGINT,
        COUNT(CASE WHEN r.rating = 5 THEN 1 END)::BIGINT
    FROM listings l
    JOIN bookings b ON l.listing_id = b.listing_id
    JOIN reviews r ON b.booking_id = r.booking_id
    WHERE l.host_id = p_host_id
      AND b.status = 'completed';
END;
$$;