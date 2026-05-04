ROLLBACK; 





DELETE FROM payments WHERE transaction_id IN ('txn_sc1_success', 'txn_sc1_error');
DELETE FROM bookings WHERE start_date IN ('2026-07-01', '2026-08-01');





BEGIN;


INSERT INTO bookings (listing_id, guest_id, start_date, end_date, guest_count, total_price, status, created_at)
VALUES (1, 5, '2026-07-01', '2026-07-05', 2, 18000.00, 'pending', CURRENT_TIMESTAMP);


INSERT INTO payments (booking_id, amount, payment_date, payment_method, status, transaction_id)
VALUES (
    (SELECT MAX(booking_id) FROM bookings),
    18000.00, CURRENT_TIMESTAMP, 'bank_card', 'pending', 'txn_sc1_success'
);

COMMIT;




SELECT 'ЧАСТЬ 1: ПРОВЕРКА' as info;
SELECT * FROM bookings WHERE start_date = '2026-07-01' AND total_price = 18000.00;
SELECT * FROM payments WHERE transaction_id = 'txn_sc1_success';









BEGIN;

INSERT INTO bookings (listing_id, guest_id, start_date, end_date, guest_count, total_price, status, created_at)
VALUES (1, 5, '2026-08-01', '2026-08-05', 2, 20000.00, 'pending', CURRENT_TIMESTAMP);


INSERT INTO payments (booking_id, amount, payment_date, payment_method, status, transaction_id)
VALUES (9999999, 20000.00, CURRENT_TIMESTAMP, 'bank_card', 'pending', 'txn_sc1_error');

ROLLBACK;

SELECT 'ЧАСТЬ 2: ПРОВЕРКА (должно быть пусто)' as info;
SELECT * FROM bookings WHERE start_date = '2026-08-01';
SELECT * FROM payments WHERE transaction_id = 'txn_sc1_error';









BEGIN;


INSERT INTO bookings (listing_id, guest_id, start_date, end_date, guest_count, total_price, status, created_at)
VALUES (1, 6, '2026-09-01', '2026-09-05', 3, 30000.00, 'pending', CURRENT_TIMESTAMP);

SAVEPOINT booking_created;

INSERT INTO payments (booking_id, amount, payment_date, payment_method, status, transaction_id)
VALUES (
    (SELECT MAX(booking_id) FROM bookings),
    25000.00, CURRENT_TIMESTAMP, 'bank_card', 'pending', 'txn_sc1_sp_1'
);

SAVEPOINT payment_1_ok;

INSERT INTO payments (booking_id, amount, payment_method, status, transaction_id)
VALUES (NULL, 5000.00, 'bank_card', 'pending', 'txn_sc1_sp_error');

ROLLBACK TO SAVEPOINT payment_1_ok;


INSERT INTO payments (booking_id, amount, payment_date, payment_method, status, transaction_id)
VALUES (
    (SELECT MAX(booking_id) FROM bookings),
    5000.00, CURRENT_TIMESTAMP, 'apple_pay', 'pending', 'txn_sc1_sp_2'
);

COMMIT;


SELECT * FROM bookings WHERE start_date = '2026-09-01';
SELECT * FROM payments WHERE transaction_id IN ('txn_sc1_sp_1', 'txn_sc1_sp_2');





ROLLBACK;


BEGIN;                       
                                
INSERT INTO bookings            
(listing_id, guest_id,          
start_date, end_date,           
guest_count, total_price,       
status)                         
VALUES (1, 5, '2026-10-01',     
'2026-10-05', 2, 25000.00,      
'pending');                     

                                 INSERT INTO bookings
                                 (listing_id, guest_id,
                                 start_date, end_date,
                                 guest_count, total_price,
                                 status)
                                 VALUES (1, 6, '2026-10-01',
                                 '2026-10-05', 3, 30000.00,
                                 'pending');
                                
                        
                                
COMMIT;                        


SELECT * FROM bookings WHERE listing_id = 1 AND start_date = '2026-10-01';

DELETE FROM bookings WHERE listing_id = 1 AND start_date = '2026-10-01';



BEGIN;                           
                                
SELECT price_per_night          
FROM listings                   
WHERE listing_id = 1            
FOR UPDATE;                     
                                 UPDATE listings
                                 SET price_per_night = 9999
                                 WHERE listing_id = 1;
                                 -- ЗАВИСЛО! Ждёт Сессию 1
                                
UPDATE listings                 
SET price_per_night = 5000      
WHERE listing_id = 1;           
                                
COMMIT;                         
                               
                            

UPDATE listings SET price_per_night = 4500 WHERE listing_id = 1;


ROLLBACK; 

 
BEGIN TRANSACTION ISOLATION     
LEVEL REPEATABLE READ;          
                                
SELECT price_per_night          
FROM listings                   
WHERE listing_id = 1;           
            
                                 UPDATE listings
                                 SET price_per_night = 9999
                                 WHERE listing_id = 1;
                                 COMMIT;  
                                
SELECT price_per_night          
FROM listings                   
WHERE listing_id = 1;           


COMMIT;                         


SELECT price_per_night FROM listings WHERE listing_id = 1;

UPDATE listings SET price_per_night = 4500 WHERE listing_id = 1;




BEGIN TRANSACTION ISOLATION     
LEVEL SERIALIZABLE;              
                                
INSERT INTO bookings            
(listing_id, guest_id,          
start_date, end_date,           
guest_count, total_price,       
status)                         
VALUES (1, 5, '2026-11-01',     
'2026-11-05', 2, 30000.00,      
'pending');                     
                                 INSERT INTO bookings
                                 (listing_id, guest_id,
                                 start_date, end_date,
                                 guest_count, total_price,
                                 status)
                                 VALUES (1, 6, '2026-11-01',
                                 '2026-11-05', 3, 35000.00,
                                 'pending');
                                
COMMIT;                         
                         



DELETE FROM payments 
WHERE transaction_id LIKE 'txn_sc1%';

DELETE FROM bookings 
WHERE start_date IN ('2026-07-01', '2026-08-01', '2026-09-01', '2026-10-01', '2026-11-01');
