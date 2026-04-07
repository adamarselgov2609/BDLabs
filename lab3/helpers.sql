CREATE TABLE IF NOT EXISTS price_change_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    listing_id BIGINT NOT NULL,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    changed_by VARCHAR(255),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT
);

CREATE TABLE IF NOT EXISTS booking_status_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL,
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    changed_by VARCHAR(255),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS host_statistics (
    host_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    total_listings INTEGER DEFAULT 0,
    active_listings INTEGER DEFAULT 0,
    total_completed_bookings INTEGER DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    avg_rating NUMERIC(3,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);