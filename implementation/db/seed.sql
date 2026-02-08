BEGIN;

TRUNCATE TABLE reviews RESTART IDENTITY CASCADE;
TRUNCATE TABLE places  RESTART IDENTITY CASCADE;
TRUNCATE TABLE users   RESTART IDENTITY CASCADE;

INSERT INTO users (username, email, password_hash) VALUES
('ana', 'ana@example.com',
 'scrypt:32768:8:1$km7KvVBoYcndPrMt$5ff54b19ef0a850f2df96ed438c122630faf1b8ca68407ada7581666f1564e602b151c429b6fa3c0d684c7d65ab6f0f73ad732c6245f42dabee145c269294038'),
('marko', 'marko@example.com',
 'scrypt:32768:8:1$km7KvVBoYcndPrMt$5ff54b19ef0a850f2df96ed438c122630faf1b8ca68407ada7581666f1564e602b151c429b6fa3c0d684c7d65ab6f0f73ad732c6245f42dabee145c269294038'),
('iva', 'iva@example.com',
 'scrypt:32768:8:1$km7KvVBoYcndPrMt$5ff54b19ef0a850f2df96ed438c122630faf1b8ca68407ada7581666f1564e602b151c429b6fa3c0d684c7d65ab6f0f73ad732c6245f42dabee145c269294038');



INSERT INTO places (name, address, description, location, meta) VALUES
('Pizzeria Luna','Ilica 12, Zagreb','Neformalna pizzerija s brzom uslugom.',
 ST_SetSRID(ST_MakePoint(15.9722, 45.8129), 4326),
 '{
   "wifi": true, "parking": false, "pets_allowed": true, "price_level": 2,
   "cuisine": ["italian","pizza"],
   "opening_hours": {"pon-pet":"10-22","sub-ned":"12-23"},
   "takeaway": true, "delivery": false
 }'::jsonb
),
('Bistro Zelen','Savska 25, Zagreb','Bistro s dnevnim menijem i vegetarijanskim opcijama.',
 ST_SetSRID(ST_MakePoint(15.9646, 45.8017), 4326),
 '{
   "wifi": true, "parking": true, "pets_allowed": false, "price_level": 2,
   "cuisine": ["croatian","veggie"],
   "opening_hours": {"pon-pet":"08-20","sub":"09-15"},
   "takeaway": true, "delivery": true
 }'::jsonb
),
('Sushi Nami','Radnička 50, Zagreb','Sushi i azijska kuhinja.',
 ST_SetSRID(ST_MakePoint(15.9935, 45.8019), 4326),
 '{
   "wifi": false, "parking": true, "pets_allowed": false, "price_level": 3,
   "cuisine": ["japanese","sushi"],
   "opening_hours": {"pon-ned":"11-22"},
   "takeaway": true, "delivery": true
 }'::jsonb
),
('Burger House','Maksimirska 90, Zagreb','Burgeri i craft pivo.',
 ST_SetSRID(ST_MakePoint(16.0028, 45.8178), 4326),
 '{
   "wifi": true, "parking": false, "pets_allowed": true, "price_level": 2,
   "cuisine": ["american","burger"],
   "opening_hours": {"pon-čet":"12-22","pet-ned":"12-23"},
   "takeaway": true, "delivery": true
 }'::jsonb
),
('Konoba Jadran','Vlaška 40, Zagreb','Riblja jela i mediteranska kuhinja.',
 ST_SetSRID(ST_MakePoint(15.9839, 45.8148), 4326),
 '{
   "wifi": false, "parking": false, "pets_allowed": false, "price_level": 3,
   "cuisine": ["mediterranean","seafood"],
   "opening_hours": {"uto-ned":"12-23"},
   "takeaway": false, "delivery": false
 }'::jsonb
),
('Vegan Corner','Preradovićeva 18, Zagreb','Veganska hrana i zdrave zdjele.',
 ST_SetSRID(ST_MakePoint(15.9773, 45.8123), 4326),
 '{
   "wifi": true, "parking": false, "pets_allowed": true, "price_level": 2,
   "cuisine": ["vegan","healthy"],
   "opening_hours": {"pon-pet":"09-21","sub":"10-18"},
   "takeaway": true, "delivery": false
 }'::jsonb
),
('Taco Fiesta','Tratinska 5, Zagreb','Meksička kuhinja i tacos.',
 ST_SetSRID(ST_MakePoint(15.9448, 45.8069), 4326),
 '{
   "wifi": false, "parking": true, "pets_allowed": true, "price_level": 1,
   "cuisine": ["mexican","tacos"],
   "opening_hours": {"pon-ned":"11-23"},
   "takeaway": true, "delivery": true
 }'::jsonb
),
('Cafe Brunch 9','Frankopanska 9, Zagreb','Brunch i specialty kava.',
 ST_SetSRID(ST_MakePoint(15.9709, 45.8115), 4326),
 '{
   "wifi": true, "parking": false, "pets_allowed": false, "price_level": 2,
   "cuisine": ["brunch","coffee"],
   "opening_hours": {"pon-pet":"07-19","sub-ned":"08-18"},
   "takeaway": true, "delivery": false
 }'::jsonb
),
('Steak & Grill','Heinzelova 33, Zagreb','Roštilj i steakovi.',
 ST_SetSRID(ST_MakePoint(15.9990, 45.8076), 4326),
 '{
   "wifi": false, "parking": true, "pets_allowed": false, "price_level": 3,
   "cuisine": ["grill","steak"],
   "opening_hours": {"pon-ned":"12-23"},
   "takeaway": false, "delivery": false
 }'::jsonb
),
('Bakery & Soup','Dubrava 120, Zagreb','Pekara s juhama i sendvičima.',
 ST_SetSRID(ST_MakePoint(16.0450, 45.8260), 4326),
 '{
   "wifi": false, "parking": true, "pets_allowed": true, "price_level": 1,
   "cuisine": ["bakery","soup"],
   "opening_hours": {"pon-sub":"06-16"},
   "takeaway": true, "delivery": false
 }'::jsonb
)
,
('Varaždinska Pivnica','Kapucinski trg 5, Varaždin','Pivnica s lokalnim jelima i velikim izborom piva.',
 ST_SetSRID(ST_MakePoint(16.3366, 46.3058), 4326),
 '{
   "wifi": true, "parking": false, "pets_allowed": true, "price_level": 2,
   "cuisine": ["croatian","pub"],
   "opening_hours": {"pon-čet":"11-23","pet-sub":"11-01","ned":"12-22"},
   "takeaway": true, "delivery": false
 }'::jsonb
),
('Pasta & Basta Varaždin','Ulica Augusta Cesarca 3, Varaždin','Talijanska tjestenina i pizza u centru grada.',
 ST_SetSRID(ST_MakePoint(16.3352, 46.3064), 4326),
 '{
   "wifi": true, "parking": false, "pets_allowed": false, "price_level": 2,
   "cuisine": ["italian","pasta","pizza"],
   "opening_hours": {"pon-pet":"10-22","sub":"12-23","ned":"12-21"},
   "takeaway": true, "delivery": true
 }'::jsonb
),
('Sushi Varaždinec','Međimurska ulica 10, Varaždin','Sushi i wok jela, brza usluga.',
 ST_SetSRID(ST_MakePoint(16.3435, 46.3049), 4326),
 '{
   "wifi": false, "parking": true, "pets_allowed": false, "price_level": 3,
   "cuisine": ["japanese","sushi","asian"],
   "opening_hours": {"pon-ned":"11-22"},
   "takeaway": true, "delivery": true
 }'::jsonb
),
('Brunch Corner Varaždin','Preradovićeva 2, Varaždin','Brunch, kava i zdrave zdjele.',
 ST_SetSRID(ST_MakePoint(16.3379, 46.3069), 4326),
 '{
   "wifi": true, "parking": false, "pets_allowed": true, "price_level": 2,
   "cuisine": ["brunch","coffee","healthy"],
   "opening_hours": {"pon-pet":"07-19","sub-ned":"08-18"},
   "takeaway": true, "delivery": false
 }'::jsonb
),
('Burger Lab Varaždin','Optujska ulica 30, Varaždin','Burgeri i roštilj, veće porcije.',
 ST_SetSRID(ST_MakePoint(16.3520, 46.3028), 4326),
 '{
   "wifi": true, "parking": true, "pets_allowed": true, "price_level": 2,
   "cuisine": ["american","burger","grill"],
   "opening_hours": {"pon-čet":"12-22","pet-sub":"12-23","ned":"12-21"},
   "takeaway": true, "delivery": true
 }'::jsonb
),
('Vegan VŽ','Trg kralja Tomislava 1, Varaždin','Veganski meni i sezonske salate.',
 ST_SetSRID(ST_MakePoint(16.3360, 46.3076), 4326),
 '{
   "wifi": true, "parking": false, "pets_allowed": true, "price_level": 2,
   "cuisine": ["vegan","healthy"],
   "opening_hours": {"pon-pet":"09-20","sub":"10-16"},
   "takeaway": true, "delivery": false
 }'::jsonb
)
;

INSERT INTO reviews (user_id, place_id, rating, comment, visited_at) VALUES
(1, 1, 5, 'Odlična pizza, tijesto super!', CURRENT_DATE - 3),
(2, 1, 4, 'Brza usluga, malo gužva.', CURRENT_DATE - 15),
(3, 2, 4, 'Dobar dnevni meni, povrće svježe.', CURRENT_DATE - 7),
(1, 3, 5, 'Najbolji sushi u kvartu.', CURRENT_DATE - 20),
(2, 4, 3, 'Burger ok, ali pomfrit prosječan.', CURRENT_DATE - 35),
(3, 5, 5, 'Riba izvrsna, preporuka!', CURRENT_DATE - 10),
(1, 6, 4, 'Fino i zdravo, porcije solidne.', CURRENT_DATE - 5),
(2, 7, 4, 'Tacos top za cijenu.', CURRENT_DATE - 2),
(3, 8, 5, 'Brunch i kava odlični.', CURRENT_DATE - 1),
(1, 9, 4, 'Meso kvalitetno, malo skuplje.', CURRENT_DATE - 12);

COMMIT;
