-- Разведка: что у нас есть сейчас
SELECT 'users' AS tbl, COUNT(*) AS cnt FROM users
UNION ALL
SELECT 'listings', COUNT(*) FROM listings
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;

SELECT '--- индексы ---' AS info;

SELECT indexname, tablename FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename, indexname;

SELECT '--- висящие процессы ---' AS info;

SELECT pid, state, wait_event, now() - query_start AS dur, left(query, 80) AS q
FROM pg_stat_activity
WHERE state != 'idle' AND pid != pg_backend_pid()
ORDER BY query_start;

SELECT pg_terminate_backend(60161);
SELECT pg_terminate_backend(60295);

SELECT 'users' AS tbl, COUNT(*) AS cnt FROM users
UNION ALL
SELECT 'listings', COUNT(*) FROM listings
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings;

SELECT pid, state, wait_event, now() - query_start AS dur, left(query, 100) AS q
FROM pg_stat_activity
WHERE state != 'idle' AND pid != pg_backend_pid()
ORDER BY query_start;

SELECT pg_cancel_backend(60691);
SELECT pg_terminate_backend(61245);

SELECT 'users' AS tbl, COUNT(*) AS cnt FROM users
UNION ALL
SELECT 'listings', COUNT(*) FROM listings
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings;


SELECT pid, state, wait_event, now() - query_start AS dur, left(query, 80) AS q
FROM pg_stat_activity
WHERE state != 'idle' AND pid != pg_backend_pid()
ORDER BY query_start;



SELECT pg_terminate_backend(62668);
SELECT pg_terminate_backend(62822);





