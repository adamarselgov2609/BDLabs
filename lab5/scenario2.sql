
rollback;


BEGIN;

INSERT INTO bookings (listing_id, guest_id, start_date, end_date, guest_count, total_price, status, created_at)
VALUES (1, 5, '2026-12-01', '2026-12-05', 2, 25000.00, 'confirmed', CURRENT_TIMESTAMP);

INSERT INTO payments (booking_id, amount, payment_date, payment_method, status, transaction_id)
VALUES (
    (SELECT MAX(booking_id) FROM bookings),
    25000.00, CURRENT_TIMESTAMP, 'bank_card', 'completed', 'txn_sc2_real'
);

COMMIT;


SELECT MAX(booking_id) AS test_booking_id FROM bookings WHERE start_date = '2026-12-01';





BEGIN;

UPDATE bookings 
SET status = 'cancelled' 
WHERE booking_id = 133478623;


UPDATE payments 
SET status = 'refunded' 
WHERE booking_id = 133478623;

COMMIT;


SELECT booking_id, status FROM bookings WHERE booking_id = 133478623;
SELECT booking_id, status FROM payments WHERE booking_id = 133478623;


UPDATE bookings SET status = 'confirmed' WHERE booking_id = 133478623;
UPDATE payments SET status = 'completed' WHERE booking_id = 133478623;






BEGIN;


UPDATE bookings SET status = 'cancelled' WHERE booking_id = 133478623;


UPDATE payments 
SET amount = amount / 0 
WHERE booking_id = 133478623;


ROLLBACK;

SELECT booking_id, status FROM bookings WHERE booking_id = 133478623;
SELECT booking_id, status FROM payments WHERE booking_id = 133478623;








BEGIN;


UPDATE bookings SET status = 'cancelled' WHERE booking_id = 133478623;

SAVEPOINT booking_cancelled;


UPDATE payments SET status = 'refunded' WHERE booking_id = 133478623;

SAVEPOINT payment_refunded;


UPDATE payments 
SET status = 'error_status' 
WHERE booking_id = 9999999;


INSERT INTO payments (booking_id, amount, payment_method, status, transaction_id)
VALUES (133478623, 1000.00, 'bank_card', 'pending', 'txn_sc2_real');


ROLLBACK TO SAVEPOINT payment_refunded;


UPDATE payments 
SET status = 'refunded'
WHERE booking_id = 133478623;

COMMIT;

SELECT booking_id, status FROM bookings WHERE booking_id = 133478623;
SELECT booking_id, status FROM payments WHERE booking_id = 133478623;




DELETE FROM payments WHERE transaction_id = 'txn_sc2_real';
DELETE FROM bookings WHERE start_date = '2026-12-01';