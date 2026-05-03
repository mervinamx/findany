-- ============================================================
--  FindAny — Indian Smartphone Finder
--  Database: findany
--  Engine:   MySQL 8+ / PostgreSQL 15+ compatible
-- ============================================================

-- ── DROP & CREATE DB ─────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS findany
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE findany;

-- ============================================================
--  TABLE: brands
-- ============================================================
DROP TABLE IF EXISTS brands;
CREATE TABLE brands (
  id          INT          AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(80)  NOT NULL UNIQUE,
  slug        VARCHAR(80)  NOT NULL UNIQUE,
  logo_url    VARCHAR(500),
  country     VARCHAR(80),
  website     VARCHAR(255),
  created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
--  TABLE: phones
-- ============================================================
DROP TABLE IF EXISTS phones;
CREATE TABLE phones (
  id            INT           AUTO_INCREMENT PRIMARY KEY,
  brand_id      INT           NOT NULL,
  name          VARCHAR(150)  NOT NULL,
  slug          VARCHAR(150)  NOT NULL UNIQUE,
  img           VARCHAR(500),
  badge         ENUM('new','bestseller','deal','upcoming') DEFAULT 'new',

  -- Pricing
  price         INT           NOT NULL,           -- INR
  old_price     INT,

  -- Core specs
  ram           TINYINT       NOT NULL,           -- GB
  storage       SMALLINT      NOT NULL,           -- GB
  camera        SMALLINT      NOT NULL,           -- MP (main)
  battery       SMALLINT      NOT NULL,           -- mAh
  display       VARCHAR(120),
  chipset       VARCHAR(60),                      -- snapdragon | mediatek | apple | exynos | google
  network       VARCHAR(10)   DEFAULT '5g',       -- 5g | 4g

  -- Ratings
  rating        DECIMAL(2,1)  DEFAULT 0.0,
  review_count  INT           DEFAULT 0,

  -- Buy links
  amazon_url    VARCHAR(500),
  flipkart_url  VARCHAR(500),
  croma_url     VARCHAR(500),
  reliance_url  VARCHAR(500),

  -- Timestamps
  created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE CASCADE,
  INDEX idx_price    (price),
  INDEX idx_ram      (ram),
  INDEX idx_storage  (storage),
  INDEX idx_chipset  (chipset),
  INDEX idx_network  (network),
  INDEX idx_rating   (rating),
  INDEX idx_brand    (brand_id)
);

-- ============================================================
--  TABLE: phone_categories
-- ============================================================
DROP TABLE IF EXISTS phone_categories;
CREATE TABLE phone_categories (
  phone_id  INT         NOT NULL,
  category  VARCHAR(40) NOT NULL,     -- budget | mid | flagship | 5g | camera | gaming | battery
  PRIMARY KEY (phone_id, category),
  FOREIGN KEY (phone_id) REFERENCES phones(id) ON DELETE CASCADE
);

-- ============================================================
--  TABLE: phone_specs  (full spec key-value store)
-- ============================================================
DROP TABLE IF EXISTS phone_specs;
CREATE TABLE phone_specs (
  id        INT           AUTO_INCREMENT PRIMARY KEY,
  phone_id  INT           NOT NULL,
  spec_key  VARCHAR(100)  NOT NULL,
  spec_val  TEXT          NOT NULL,
  FOREIGN KEY (phone_id) REFERENCES phones(id) ON DELETE CASCADE,
  INDEX idx_phone_spec (phone_id)
);

-- ============================================================
--  TABLE: price_history
-- ============================================================
DROP TABLE IF EXISTS price_history;
CREATE TABLE price_history (
  id          INT       AUTO_INCREMENT PRIMARY KEY,
  phone_id    INT       NOT NULL,
  price       INT       NOT NULL,
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (phone_id) REFERENCES phones(id) ON DELETE CASCADE,
  INDEX idx_ph_phone (phone_id),
  INDEX idx_ph_date  (recorded_at)
);

-- ============================================================
--  TABLE: wishlists  (user favourites)
-- ============================================================
DROP TABLE IF EXISTS wishlists;
CREATE TABLE wishlists (
  id          INT       AUTO_INCREMENT PRIMARY KEY,
  session_id  VARCHAR(100) NOT NULL,
  phone_id    INT          NOT NULL,
  added_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_session_phone (session_id, phone_id),
  FOREIGN KEY (phone_id) REFERENCES phones(id) ON DELETE CASCADE
);

-- ============================================================
--  TABLE: compare_sessions
-- ============================================================
DROP TABLE IF EXISTS compare_sessions;
CREATE TABLE compare_sessions (
  id          INT       AUTO_INCREMENT PRIMARY KEY,
  session_id  VARCHAR(100) NOT NULL,
  phone_id    INT          NOT NULL,
  added_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (phone_id) REFERENCES phones(id) ON DELETE CASCADE,
  INDEX idx_cs_session (session_id)
);

-- ============================================================
--  SEED DATA — BRANDS
-- ============================================================
INSERT INTO brands (name, slug, country, website) VALUES
  ('Apple',    'apple',    'USA',          'https://apple.com'),
  ('Samsung',  'samsung',  'South Korea',  'https://samsung.com'),
  ('OnePlus',  'oneplus',  'China',        'https://oneplus.com'),
  ('Redmi',    'redmi',    'China',        'https://mi.com'),
  ('Google',   'google',   'USA',          'https://store.google.com'),
  ('Nothing',  'nothing',  'UK',           'https://nothing.tech'),
  ('Motorola', 'motorola', 'USA',          'https://motorola.com'),
  ('iQOO',     'iqoo',     'China',        'https://iqoo.com'),
  ('Vivo',     'vivo',     'China',        'https://vivo.com'),
  ('POCO',     'poco',     'China',        'https://poco.com'),
  ('Realme',   'realme',   'China',        'https://realme.com'),
  ('OPPO',     'oppo',     'China',        'https://oppo.com'),
  ('Infinix',  'infinix',  'Hong Kong',    'https://infinixmobility.com'),
  ('Tecno',    'tecno',    'Hong Kong',    'https://tecno-mobile.com');

-- ============================================================
--  SEED DATA — PHONES
-- ============================================================

-- Samsung Galaxy S26 Ultra
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(2,'Galaxy S26 Ultra','samsung-galaxy-s26-ultra',
 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-s26-ultra5g.jpg',
 'new',139999,149999,12,256,200,5000,'6.9" Dynamic AMOLED 2X','snapdragon','5g',4.8,3200,
 'https://www.amazon.in/s?k=Samsung+Galaxy+S26+Ultra',
 'https://www.flipkart.com/search?q=Samsung+Galaxy+S26+Ultra',
 'https://www.croma.com/searchB?q=Samsung+Galaxy+S26+Ultra',
 'https://www.reliancedigital.in/search?q=Samsung+Galaxy+S26+Ultra');

-- Samsung Galaxy S26 Plus
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(2,'Galaxy S26 Plus','samsung-galaxy-s26-plus',
 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-s26-plus.jpg',
 'new',119999,124999,12,256,50,4900,'6.7" Dynamic AMOLED 2X','snapdragon','5g',4.7,1800,
 'https://www.amazon.in/s?k=Samsung+Galaxy+S26+Plus',
 'https://www.flipkart.com/search?q=Samsung+Galaxy+S26+Plus',
 'https://www.croma.com/searchB?q=Samsung+Galaxy+S26+Plus',
 'https://www.reliancedigital.in/search?q=Samsung+Galaxy+S26+Plus');

-- Samsung Galaxy S26
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(2,'Galaxy S26','samsung-galaxy-s26',
 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-s26.jpg',
 'bestseller',87999,94999,8,128,50,4000,'6.2" Dynamic AMOLED 2X','snapdragon','5g',4.6,4200,
 'https://www.amazon.in/s?k=Samsung+Galaxy+S26',
 'https://www.flipkart.com/search?q=Samsung+Galaxy+S26',
 'https://www.croma.com/searchB?q=Samsung+Galaxy+S26',
 'https://www.reliancedigital.in/search?q=Samsung+Galaxy+S26');

-- iPhone 16 Pro Max
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(1,'iPhone 16 Pro Max','apple-iphone-16-pro-max',
 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-16-pro-max.jpg',
 'bestseller',159900,169900,8,256,48,4685,'6.9" Super Retina XDR OLED','apple','5g',4.8,18500,
 'https://www.amazon.in/s?k=iPhone+16+Pro+Max',
 'https://www.flipkart.com/search?q=iPhone+16+Pro+Max',
 'https://www.croma.com/searchB?q=iPhone+16+Pro+Max',
 'https://www.reliancedigital.in/search?q=iPhone+16+Pro+Max');

-- iPhone 16
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(1,'iPhone 16','apple-iphone-16',
 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-16.jpg',
 'deal',79900,89900,8,128,48,3561,'6.1" Super Retina XDR OLED','apple','5g',4.6,22400,
 'https://www.amazon.in/s?k=iPhone+16',
 'https://www.flipkart.com/search?q=iPhone+16',
 'https://www.croma.com/searchB?q=iPhone+16',
 'https://www.reliancedigital.in/search?q=iPhone+16');

-- OnePlus 13
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(3,'OnePlus 13','oneplus-13',
 'https://fdn2.gsmarena.com/vv/bigpic/oneplus-13.jpg',
 'deal',69999,74999,12,256,50,6000,'6.82" LTPO AMOLED','snapdragon','5g',4.6,8900,
 'https://www.amazon.in/s?k=OnePlus+13',
 'https://www.flipkart.com/search?q=OnePlus+13',
 'https://www.croma.com/searchB?q=OnePlus+13',
 NULL);

-- OnePlus Nord 4
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(3,'Nord 4','oneplus-nord-4',
 'https://fdn2.gsmarena.com/vv/bigpic/oneplus-nord-4.jpg',
 'deal',29999,34999,8,128,50,5500,'6.74" AMOLED','snapdragon','5g',4.4,9600,
 'https://www.amazon.in/s?k=OnePlus+Nord+4',
 'https://www.flipkart.com/search?q=OnePlus+Nord+4',
 NULL,NULL);

-- Redmi Note 13 Pro 5G
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(4,'Note 13 Pro 5G','redmi-note-13-pro-5g',
 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-redmi-note-13-pro-5g.jpg',
 'bestseller',24999,27999,8,256,200,5100,'6.67" AMOLED','snapdragon','5g',4.4,42000,
 'https://www.amazon.in/s?k=Redmi+Note+13+Pro+5G',
 'https://www.flipkart.com/search?q=Redmi+Note+13+Pro+5G',
 NULL,NULL);

-- Redmi 13C 5G
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(4,'13C 5G','redmi-13c-5g',
 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-redmi-13c-5g.jpg',
 'bestseller',8999,11999,4,64,50,5000,'6.74" IPS LCD','mediatek','5g',4.0,48000,
 'https://www.amazon.in/s?k=Redmi+13C+5G',
 'https://www.flipkart.com/search?q=Redmi+13C+5G',
 NULL,NULL);

-- Google Pixel 9
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(5,'Pixel 9','google-pixel-9',
 'https://fdn2.gsmarena.com/vv/bigpic/google-pixel-9.jpg',
 'new',79999,84999,12,128,50,4700,'6.3" Actua OLED','google','5g',4.5,5600,
 'https://www.amazon.in/s?k=Google+Pixel+9',
 'https://www.flipkart.com/search?q=Google+Pixel+9',
 'https://www.croma.com/searchB?q=Google+Pixel+9',
 'https://www.reliancedigital.in/search?q=Google+Pixel+9');

-- Nothing Phone 4a
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(6,'Phone 4a','nothing-phone-4a',
 'https://fdn2.gsmarena.com/vv/bigpic/nothing-phone-2a.jpg',
 'new',31469,35999,8,128,50,5000,'6.7" AMOLED','mediatek','5g',4.3,3800,
 'https://www.amazon.in/s?k=Nothing+Phone+4a',
 'https://www.flipkart.com/search?q=Nothing+Phone+4a',
 'https://www.croma.com/searchB?q=Nothing+Phone+4a',
 NULL);

-- Motorola Edge 70 Fusion
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(7,'Edge 70 Fusion','motorola-edge-70-fusion',
 'https://fdn2.gsmarena.com/vv/bigpic/motorola-edge-50-pro.jpg',
 'deal',24999,28999,8,256,50,5000,'6.7" pOLED','snapdragon','5g',4.2,6100,
 'https://www.amazon.in/s?k=Motorola+Edge+70+Fusion',
 'https://www.flipkart.com/search?q=Motorola+Edge+70+Fusion',
 NULL,
 'https://www.reliancedigital.in/search?q=Motorola+Edge+70+Fusion');

-- Motorola Moto G67 5G
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(7,'Moto G67 5G','motorola-moto-g67-5g',
 'https://fdn2.gsmarena.com/vv/bigpic/motorola-moto-g85.jpg',
 'deal',13999,15999,6,128,50,5000,'6.5" IPS LCD','snapdragon','5g',4.1,14000,
 'https://www.amazon.in/s?k=Moto+G67+5G',
 'https://www.flipkart.com/search?q=Moto+G67+5G',
 NULL,NULL);

-- iQOO 15R
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(8,'iQOO 15R','iqoo-15r',
 'https://fdn2.gsmarena.com/vv/bigpic/vivo-iqoo-12.jpg',
 'deal',44998,49999,8,256,50,6000,'6.77" LTPO AMOLED','snapdragon','5g',4.5,5200,
 'https://www.amazon.in/s?k=iQOO+15R',
 'https://www.flipkart.com/search?q=iQOO+15R',
 NULL,NULL);

-- iQOO Z11x
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(8,'Z11x','iqoo-z11x',
 'https://fdn2.gsmarena.com/vv/bigpic/vivo-iqoo-z9x.jpg',
 'bestseller',18998,21999,8,128,64,6000,'6.72" IPS LCD','snapdragon','5g',4.3,18700,
 'https://www.amazon.in/s?k=iQOO+Z11x',
 'https://www.flipkart.com/search?q=iQOO+Z11x',
 NULL,NULL);

-- Vivo V70
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(9,'V70','vivo-v70',
 'https://fdn2.gsmarena.com/vv/bigpic/vivo-v40.jpg',
 'new',45999,49999,12,256,50,5500,'6.78" AMOLED','mediatek','5g',4.3,4100,
 'https://www.amazon.in/s?k=Vivo+V70',
 'https://www.flipkart.com/search?q=Vivo+V70',
 'https://www.croma.com/searchB?q=Vivo+V70',
 'https://www.reliancedigital.in/search?q=Vivo+V70');

-- Vivo Y500 Pro
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(9,'Y500 Pro','vivo-y500-pro',
 'https://fdn2.gsmarena.com/vv/bigpic/vivo-y200-gt.jpg',
 'new',21999,24999,8,128,64,6000,'6.72" AMOLED','snapdragon','5g',4.2,2800,
 'https://www.amazon.in/s?k=Vivo+Y500+Pro',
 'https://www.flipkart.com/search?q=Vivo+Y500+Pro',
 NULL,NULL);

-- POCO X6 Pro
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(10,'X6 Pro 5G','poco-x6-pro-5g',
 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-poco-x6-pro.jpg',
 'deal',26999,29999,12,256,64,5000,'6.67" AMOLED','mediatek','5g',4.4,14500,
 'https://www.amazon.in/s?k=POCO+X6+Pro',
 'https://www.flipkart.com/search?q=POCO+X6+Pro',
 NULL,NULL);

-- Realme Narzo 60 Pro
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(11,'Narzo 60 Pro','realme-narzo-60-pro',
 'https://fdn2.gsmarena.com/vv/bigpic/realme-narzo-60-pro.jpg',
 'deal',17999,21999,8,128,100,5000,'6.7" AMOLED','mediatek','5g',4.2,11200,
 'https://www.amazon.in/s?k=Realme+Narzo+60+Pro',
 'https://www.flipkart.com/search?q=Realme+Narzo+60+Pro',
 NULL,NULL);

-- Realme C100 5G
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(11,'C100 5G','realme-c100-5g',
 'https://fdn2.gsmarena.com/vv/bigpic/realme-c67-5g.jpg',
 'new',10999,12999,4,64,48,5000,'6.72" IPS LCD','mediatek','5g',3.9,8900,
 'https://www.amazon.in/s?k=Realme+C100+5G',
 'https://www.flipkart.com/search?q=Realme+C100+5G',
 NULL,NULL);

-- OPPO Reno 13 5G
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(12,'Reno 13 5G','oppo-reno-13-5g',
 'https://fdn2.gsmarena.com/vv/bigpic/oppo-reno12.jpg',
 'new',32999,36999,8,256,50,5600,'6.59" AMOLED','mediatek','5g',4.2,3400,
 'https://www.amazon.in/s?k=OPPO+Reno+13+5G',
 'https://www.flipkart.com/search?q=OPPO+Reno+13+5G',
 'https://www.croma.com/searchB?q=OPPO+Reno+13',
 'https://www.reliancedigital.in/search?q=OPPO+Reno+13');

-- Samsung Galaxy A55 5G
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(2,'Galaxy A55 5G','samsung-galaxy-a55-5g',
 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-a55.jpg',
 'bestseller',34999,38999,8,128,50,5000,'6.6" Super AMOLED','exynos','5g',4.3,19800,
 'https://www.amazon.in/s?k=Samsung+Galaxy+A55',
 'https://www.flipkart.com/search?q=Samsung+Galaxy+A55',
 'https://www.croma.com/searchB?q=Samsung+Galaxy+A55',
 'https://www.reliancedigital.in/search?q=Samsung+Galaxy+A55');

-- Infinix Note 40 Pro 5G
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(13,'Note 40 Pro 5G','infinix-note-40-pro-5g',
 'https://fdn2.gsmarena.com/vv/bigpic/infinix-note-40-pro.jpg',
 'deal',19999,24999,8,256,108,5000,'6.78" AMOLED','mediatek','5g',4.1,7800,
 'https://www.amazon.in/s?k=Infinix+Note+40+Pro+5G',
 'https://www.flipkart.com/search?q=Infinix+Note+40+Pro+5G',
 NULL,NULL);

-- Tecno Spark 40
INSERT INTO phones (brand_id,name,slug,img,badge,price,old_price,ram,storage,camera,battery,display,chipset,network,rating,review_count,amazon_url,flipkart_url,croma_url,reliance_url) VALUES
(14,'Spark 40','tecno-spark-40',
 'https://fdn2.gsmarena.com/vv/bigpic/tecno-spark-20-pro.jpg',
 'new',9999,12999,4,64,48,5000,'6.78" IPS LCD','mediatek','4g',3.9,5600,
 'https://www.amazon.in/s?k=Tecno+Spark+40',
 'https://www.flipkart.com/search?q=Tecno+Spark+40',
 NULL,NULL);

-- ============================================================
--  SEED DATA — CATEGORIES (phone_id maps to INSERT order above)
-- ============================================================
INSERT INTO phone_categories (phone_id, category) VALUES
  (1,'flagship'),(1,'5g'),(1,'camera'),
  (2,'flagship'),(2,'5g'),
  (3,'flagship'),(3,'5g'),
  (4,'flagship'),(4,'5g'),(4,'camera'),
  (5,'flagship'),(5,'5g'),
  (6,'flagship'),(6,'5g'),(6,'battery'),(6,'gaming'),
  (7,'mid'),(7,'5g'),(7,'gaming'),
  (8,'mid'),(8,'5g'),(8,'camera'),
  (9,'budget'),(9,'5g'),(9,'battery'),
  (10,'flagship'),(10,'5g'),(10,'camera'),
  (11,'mid'),(11,'5g'),
  (12,'mid'),(12,'5g'),
  (13,'mid'),(13,'5g'),
  (14,'budget'),(14,'5g'),
  (15,'flagship'),(15,'5g'),(15,'battery'),(15,'gaming'),
  (16,'budget'),(16,'5g'),(16,'battery'),(16,'gaming'),
  (17,'mid'),(17,'5g'),(17,'camera'),
  (18,'budget'),(18,'5g'),(18,'battery'),
  (19,'mid'),(19,'5g'),(19,'gaming'),
  (20,'budget'),(20,'5g'),(20,'battery'),
  (21,'mid'),(21,'5g'),(21,'camera'),
  (22,'mid'),(22,'5g'),
  (23,'budget'),(23,'5g'),
  (24,'budget');

-- ============================================================
--  SEED DATA — PRICE HISTORY
-- ============================================================
INSERT INTO price_history (phone_id, price, recorded_at) VALUES
  -- Samsung Galaxy S26 Ultra
  (1,149999,'2025-01-01'),(1,145000,'2025-02-01'),(1,142000,'2025-03-01'),(1,139999,'2025-04-01'),
  -- iPhone 16 Pro Max
  (4,169900,'2025-01-01'),(4,165000,'2025-02-01'),(4,162000,'2025-03-01'),(4,159900,'2025-04-01'),
  -- iPhone 16
  (5,89900,'2025-01-01'),(5,86000,'2025-02-01'),(5,83000,'2025-03-01'),(5,79900,'2025-04-01'),
  -- OnePlus 13
  (6,74999,'2025-01-01'),(6,72999,'2025-02-01'),(6,70999,'2025-03-01'),(6,69999,'2025-04-01'),
  -- Redmi Note 13 Pro
  (8,27999,'2025-01-01'),(8,26999,'2025-02-01'),(8,25999,'2025-03-01'),(8,24999,'2025-04-01'),
  -- Redmi 13C
  (9,11999,'2025-01-01'),(9,10999,'2025-02-01'),(9,9999,'2025-03-01'),(9,8999,'2025-04-01');

-- ============================================================
--  SEED DATA — FULL SPECS (sample for top phones)
-- ============================================================
INSERT INTO phone_specs (phone_id, spec_key, spec_val) VALUES
  -- iPhone 16 Pro Max (id=4)
  (4,'Display','6.9" Super Retina XDR OLED, 2868×1320, ProMotion 120Hz'),
  (4,'Processor','Apple A18 Pro'),
  (4,'RAM','8 GB'),
  (4,'Storage','256 GB / 512 GB / 1 TB'),
  (4,'Main Camera','48 MP Fusion + 48 MP Ultra-wide + 12 MP 5x Tetraprism'),
  (4,'Front Camera','12 MP TrueDepth'),
  (4,'Battery','4685 mAh'),
  (4,'Fast Charging','27W MagSafe 3, 25W wireless'),
  (4,'OS','iOS 18'),
  (4,'SIM','Nano-SIM + eSIM'),
  (4,'Network','5G, Wi-Fi 6E'),
  (4,'Dimensions','163.0 × 77.6 × 8.25 mm'),
  (4,'Weight','227 g'),
  (4,'Colors','Black Titanium, White Titanium, Natural Titanium, Desert Titanium'),

  -- Samsung Galaxy S26 Ultra (id=1)
  (1,'Display','6.9" Dynamic AMOLED 2X, 3088×1440, 120Hz LTPO'),
  (1,'Processor','Snapdragon 8 Elite'),
  (1,'RAM','12 GB LPDDR5X'),
  (1,'Storage','256 GB / 512 GB / 1 TB UFS 4.0'),
  (1,'Main Camera','200 MP OIS + 50 MP + 10 MP 3x + 50 MP 5x'),
  (1,'Front Camera','12 MP'),
  (1,'Battery','5000 mAh'),
  (1,'Fast Charging','45W wired, 15W wireless'),
  (1,'OS','Android 15, One UI 7'),
  (1,'SIM','Nano-SIM + eSIM'),
  (1,'Network','5G, Wi-Fi 7'),
  (1,'Dimensions','162.8 × 79.0 × 8.6 mm'),
  (1,'Weight','218 g'),
  (1,'Colors','Titanium Black, Titanium Silver, Titanium Blue'),

  -- OnePlus 13 (id=6)
  (6,'Display','6.82" LTPO AMOLED, 3168×1440, 1–120Hz'),
  (6,'Processor','Snapdragon 8 Elite'),
  (6,'RAM','12 GB / 16 GB LPDDR5X'),
  (6,'Storage','256 GB / 512 GB UFS 4.0'),
  (6,'Main Camera','50 MP Hasselblad + 50 MP + 50 MP'),
  (6,'Front Camera','32 MP'),
  (6,'Battery','6000 mAh'),
  (6,'Fast Charging','100W SUPERVOOC, 50W AirVOOC'),
  (6,'OS','OxygenOS 15 (Android 15)'),
  (6,'SIM','Nano-SIM + eSIM'),
  (6,'Network','5G, Wi-Fi 7'),
  (6,'Dimensions','162.9 × 76.5 × 8.9 mm'),
  (6,'Weight','210 g'),
  (6,'Colors','Midnight Ocean, Arctic Dawn'),

  -- Redmi Note 13 Pro 5G (id=8)
  (8,'Display','6.67" AMOLED, 2400×1080, 120Hz'),
  (8,'Processor','Snapdragon 7s Gen 2'),
  (8,'RAM','8 GB / 12 GB'),
  (8,'Storage','128 GB / 256 GB'),
  (8,'Main Camera','200 MP OIS + 8 MP + 2 MP'),
  (8,'Front Camera','16 MP'),
  (8,'Battery','5100 mAh'),
  (8,'Fast Charging','67W HyperCharge'),
  (8,'OS','MIUI 14 (Android 13)'),
  (8,'SIM','Nano-SIM × 2'),
  (8,'Network','5G, Wi-Fi 6'),
  (8,'Dimensions','161.1 × 75.0 × 8.0 mm'),
  (8,'Weight','187 g'),
  (8,'Colors','Midnight Black, Arctic White, Ocean Teal');

-- ============================================================
--  USEFUL VIEWS
-- ============================================================

-- Full phone listing with brand name
CREATE OR REPLACE VIEW v_phones AS
SELECT
  p.id,
  b.name        AS brand,
  p.name,
  p.slug,
  p.img,
  p.badge,
  p.price,
  p.old_price,
  ROUND((p.old_price - p.price) * 100.0 / p.old_price, 1) AS discount_pct,
  p.ram,
  p.storage,
  p.camera,
  p.battery,
  p.display,
  p.chipset,
  p.network,
  p.rating,
  p.review_count,
  p.amazon_url,
  p.flipkart_url,
  p.croma_url,
  p.reliance_url,
  p.created_at
FROM phones p
JOIN brands b ON b.id = p.brand_id;

-- Price history per phone with month label
CREATE OR REPLACE VIEW v_price_history AS
SELECT
  ph.phone_id,
  p.name,
  ph.price,
  DATE_FORMAT(ph.recorded_at, '%b %Y') AS month_label,
  ph.recorded_at
FROM price_history ph
JOIN phones p ON p.id = ph.phone_id
ORDER BY ph.phone_id, ph.recorded_at;

-- Best deals (discount > 10%)
CREATE OR REPLACE VIEW v_best_deals AS
SELECT *
FROM v_phones
WHERE old_price IS NOT NULL
  AND old_price > price
  AND (old_price - price) * 100.0 / old_price >= 10
ORDER BY discount_pct DESC;

-- ============================================================
--  USEFUL QUERIES (reference)
-- ============================================================

-- Filter phones by price, RAM, 5G
-- SELECT * FROM v_phones
--   WHERE price BETWEEN 15000 AND 30000
--     AND ram >= 8
--     AND network = '5g'
--   ORDER BY rating DESC;

-- Phones in a category
-- SELECT p.* FROM v_phones p
--   JOIN phone_categories pc ON pc.phone_id = p.id
--   WHERE pc.category = 'gaming';

-- Full specs for a phone
-- SELECT spec_key, spec_val FROM phone_specs WHERE phone_id = 4;

-- Search by brand or name
-- SELECT * FROM v_phones
--   WHERE brand LIKE '%samsung%' OR name LIKE '%s26%';

-- Price history for a phone
-- SELECT * FROM v_price_history WHERE phone_id = 4;
