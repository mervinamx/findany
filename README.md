# FindAny — Indian Smartphone Finder

> Full-stack mobile finder for the Indian market
> **Tech:** HTML5 Frontend · Python Flask API · MySQL 8 · Docker

---

## Project Structure

```
findany/
├── frontend/
│   ├── index.html        ← Full FindAny UI
│   ├── nginx.conf        ← Nginx with /api proxy
│   └── Dockerfile
│
├── backend/
│   ├── app.py            ← Flask REST API (SQLAlchemy)
│   ├── requirements.txt
│   └── Dockerfile
│
├── database/
│   ├── findany.sql       ← MySQL schema + 24 phones seed data
│   └── phones.json       ← JSON fallback (SQLite dev mode)
│
└── docker-compose.yml    ← MySQL + Flask + Nginx
```

---

## Quick Start (Docker)

```bash
cd findany
docker compose up --build
```

| Service  | URL                       |
|----------|---------------------------|
| App      | http://localhost:3000     |
| API      | http://localhost:5000/api |
| MySQL    | localhost:3306            |

### Stop
```bash
docker compose down
```

### Fresh restart (wipe DB)
```bash
docker compose down -v && docker compose up --build
```

---

## Database — MySQL

The SQL file `database/findany.sql` is auto-loaded by MySQL on first start.

### Tables

| Table              | Description                        |
|--------------------|------------------------------------|
| `brands`           | 14 brands (Apple, Samsung, …)      |
| `phones`           | 24 phones with full specs          |
| `phone_categories` | Category tags per phone            |
| `phone_specs`      | Key-value full spec rows           |
| `price_history`    | Historical price points            |
| `wishlists`        | User session favourites            |
| `compare_sessions` | Compare session tracking           |

### Views

| View             | Description                     |
|------------------|---------------------------------|
| `v_phones`       | Phones joined with brand name   |
| `v_price_history`| Price history with month labels |
| `v_best_deals`   | Phones with ≥10% discount       |

### Connect to MySQL

```bash
docker exec -it findany-mysql mysql -ufindany_user -pfindany_pass findany
```

### Useful SQL queries

```sql
-- Phones under ₹20,000 with 5G
SELECT brand, name, price, rating FROM v_phones
WHERE price <= 20000 AND network = '5g'
ORDER BY rating DESC;

-- Best deals
SELECT brand, name, price, old_price, discount_pct FROM v_best_deals LIMIT 10;

-- Full specs for a phone
SELECT spec_key, spec_val FROM phone_specs WHERE phone_id = 4;

-- Price history
SELECT * FROM v_price_history WHERE phone_id = 4;

-- Gaming phones
SELECT p.brand, p.name, p.price FROM v_phones p
JOIN phone_categories pc ON pc.phone_id = p.id
WHERE pc.category = 'gaming';
```

---

## API Endpoints

| Method | Endpoint                         | Description            |
|--------|----------------------------------|------------------------|
| GET    | `/api/phones`                    | List + filter phones   |
| GET    | `/api/phones/<id>`               | Phone detail + specs   |
| GET    | `/api/phones/<id>/history`       | Price history          |
| GET    | `/api/phones/search/suggest`     | Autocomplete           |
| GET    | `/api/brands`                    | All brands             |
| GET    | `/api/stats`                     | Counts + DB engine     |
| GET    | `/api/health`                    | Health check           |

### Filter params for `/api/phones`

```
?price_min=10000&price_max=30000
&ram=8&ram=12
&storage=128&storage=256
&chipset=snapdragon&chipset=mediatek
&camera_min=64
&battery_min=5000
&network=5g
&category=gaming
&q=redmi
&sort=price_asc   (popular|price_asc|price_desc|rating|newest)
```

---

## Development without Docker

### Backend (SQLite mode — no MySQL needed)

```bash
cd backend
pip install -r requirements.txt
python app.py
# → http://localhost:5000/api
# Auto-seeds from database/phones.json into SQLite
```

### Frontend

Open `frontend/index.html` in a browser.
The app auto-detects localhost and calls `http://localhost:5000/api`.

---

## MySQL Credentials (Docker)

| Field    | Value          |
|----------|----------------|
| Host     | localhost:3306 |
| Database | findany        |
| User     | findany_user   |
| Password | findany_pass   |
| Root pw  | findany_root   |

Change these in `docker-compose.yml` before production deployment.

---

## Features

- 🔍 Search with autocomplete
- 🎛️ Filter by price, RAM, storage, chipset, camera, battery, 5G/4G
- 📱 Category filters: Budget / Mid / Flagship / 5G / Camera / Gaming / Battery
- ⚖️ Compare 2–3 phones side-by-side
- 🤍 Wishlist / favourites
- 📈 Price history chart
- 🛒 Buy links: Amazon India, Flipkart, Croma, Reliance Digital
- 🤖 AI recommendation (Claude API)
- 🌙 Dark / Light mode
