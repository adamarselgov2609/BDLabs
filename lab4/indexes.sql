CREATE INDEX IF NOT EXISTS idx_listings_city_type_price_active 
ON listings (city, property_type, price_per_night, is_active);



CREATE INDEX IF NOT EXISTS idx_bookings_status_listing 
ON bookings (status, listing_id)
INCLUDE (booking_id);



CREATE INDEX IF NOT EXISTS idx_bookings_guest_status_date 
ON bookings (guest_id, status, start_date)
INCLUDE (end_date, total_price);



CREATE INDEX IF NOT EXISTS idx_bookings_guest_completed 
ON bookings (guest_id, start_date)
INCLUDE (end_date, total_price, status)
WHERE status = 'completed';



CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_listings_title_trgm 
ON listings USING gin (title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_listings_description_trgm 
ON listings USING gin (description gin_trgm_ops);



CREATE INDEX IF NOT EXISTS idx_bookings_status_startdate 
ON bookings (status, start_date)
INCLUDE (end_date, total_price, guest_id, listing_id);



ANALYZE listings;
ANALYZE bookings;