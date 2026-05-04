-- ============================================================
-- Лабораторная работа №5. Исследование транзакций в PostgreSQL
-- Сценарий 3: Регистрация нового хоста с первым объявлением
-- Файл: scenario3.sql
-- ============================================================

-- Бизнес-сценарий:
-- Новый пользователь регистрируется как хост и сразу создаёт
-- своё первое объявление. Атомарно:
--   1) создаётся пользователь (users, роль 'host')
--   2) создаётся объявление (listings)
-- Если любая операция падает — откатывается всё.

-- ============================================================
-- ЧАСТЬ 1. УСПЕШНАЯ ТРАНЗАКЦИЯ С COMMIT
-- ============================================================
rollback;


BEGIN;

-- Создаём нового хоста
INSERT INTO users (email, password_hash, full_name, phone, role, is_verified, created_at)
VALUES ('new.host@email.com', 'hash_new_host', 'Новый Хост', '+79990000001', 'host', FALSE, CURRENT_TIMESTAMP);

-- Создаём его первое объявление (хост = только что созданный пользователь)
INSERT INTO listings (host_id, title, description, property_type, price_per_night, max_guests, bedrooms, bathrooms, address, city, country, is_active, created_at)
VALUES (
    (SELECT MAX(user_id) FROM users),
    'Первое объявление нового хоста',
    'Тестовое описание',
    'apartment',
    5000.00,
    4,
    2,
    1.0,
    'ул. Новая, д. 1',
    'Москва',
    'Россия',
    TRUE,
    CURRENT_TIMESTAMP
);

COMMIT;

-- Проверка
SELECT user_id, email, full_name, role FROM users WHERE email = 'new.host@email.com';
SELECT listing_id, host_id, title FROM listings WHERE title = 'Первое объявление нового хоста';

-- ============================================================
-- ЧАСТЬ 2. ОШИБКА И ПОЛНЫЙ ОТКАТ (ROLLBACK)
-- ============================================================

BEGIN;

-- Создаём пользователя (успешно)
INSERT INTO users (email, password_hash, full_name, phone, role, is_verified, created_at)
VALUES ('bad.host@email.com', 'hash_bad_host', 'Плохой Хост', '+79990000002', 'host', FALSE, CURRENT_TIMESTAMP);

-- Намеренная ошибка: NULL в NOT NULL столбец title
INSERT INTO listings (host_id, title, description, property_type, price_per_night, max_guests, bedrooms, bathrooms, address, city, country, is_active, created_at)
VALUES (
    (SELECT MAX(user_id) FROM users),
    NULL,  -- ← ОШИБКА! title NOT NULL
    'Тестовое описание',
    'apartment',
    5000.00, 4, 2, 1.0, 'ул. Плохая, д. 1', 'Москва', 'Россия', TRUE, CURRENT_TIMESTAMP
);

-- Транзакция ABORTED
ROLLBACK;

-- Проверка: ни пользователь, ни объявление не сохранились
SELECT * FROM users WHERE email = 'bad.host@email.com';
SELECT * FROM listings WHERE address = 'ул. Плохая, д. 1';

-- ============================================================
-- ЧАСТЬ 3. SAVEPOINT — ЧАСТИЧНЫЙ ОТКАТ
-- ============================================================

BEGIN;

-- Создаём пользователя (успешно)
INSERT INTO users (email, password_hash, full_name, phone, role, is_verified, created_at)
VALUES ('savepoint.host@email.com', 'hash_sp_host', 'Хост с Savepoint', '+79990000003', 'host', FALSE, CURRENT_TIMESTAMP);

SAVEPOINT user_created;

-- Создаём объявление (успешно)
INSERT INTO listings (host_id, title, description, property_type, price_per_night, max_guests, bedrooms, bathrooms, address, city, country, is_active, created_at)
VALUES (
    (SELECT MAX(user_id) FROM users),
    'Объявление от Savepoint-хоста',
    'Тестовое описание',
    'house',
    12000.00, 6, 3, 2.0, 'ул. Спасённая, д. 42', 'Сочи', 'Россия', TRUE, CURRENT_TIMESTAMP
);

SAVEPOINT listing_created;

-- Пытаемся создать второе объявление с ошибкой (дубликат email пользователя)
INSERT INTO users (email, password_hash, full_name, phone, role, is_verified, created_at)
VALUES ('savepoint.host@email.com', 'hash_dup', 'Дубликат', '+79990000004', 'host', FALSE, CURRENT_TIMESTAMP);

-- Ошибка: нарушение уникальности email
ROLLBACK TO SAVEPOINT listing_created;

-- Создаём второе объявление правильно (с другим адресом)
INSERT INTO listings (host_id, title, description, property_type, price_per_night, max_guests, bedrooms, bathrooms, address, city, country, is_active, created_at)
VALUES (
    (SELECT MAX(user_id) FROM users),
    'Второе объявление от Savepoint-хоста',
    'Ещё одно тестовое описание',
    'apartment',
    8000.00, 4, 2, 1.5, 'ул. Спасённая, д. 43', 'Сочи', 'Россия', TRUE, CURRENT_TIMESTAMP
);

COMMIT;

-- Проверка: хост и оба объявления на месте, дубликата нет
SELECT user_id, email, full_name FROM users WHERE email = 'savepoint.host@email.com';
SELECT listing_id, title FROM listings WHERE host_id = (SELECT user_id FROM users WHERE email = 'savepoint.host@email.com');

-- ============================================================
-- ОЧИСТКА
-- ============================================================
DELETE FROM listings WHERE host_id IN (SELECT user_id FROM users WHERE email IN ('new.host@email.com', 'savepoint.host@email.com'));
DELETE FROM users WHERE email IN ('new.host@email.com', 'savepoint.host@email.com');