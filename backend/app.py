import json
import os
import re
import urllib.error
import urllib.request

from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
CORS(app)

MYSQL_URI = os.environ.get("DATABASE_URL")
SQLITE_URI = "sqlite:///findany.db"

app.config["SQLALCHEMY_DATABASE_URI"] = MYSQL_URI or SQLITE_URI
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)


class Brand(db.Model):
    __tablename__ = "brands"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)
    slug = db.Column(db.String(80), unique=True, nullable=False)
    country = db.Column(db.String(80))
    website = db.Column(db.String(255))


class Phone(db.Model):
    __tablename__ = "phones"

    id = db.Column(db.Integer, primary_key=True)
    brand_id = db.Column(db.Integer, db.ForeignKey("brands.id"), nullable=False)
    name = db.Column(db.String(150), nullable=False)
    slug = db.Column(db.String(150), unique=True)
    img = db.Column(db.String(500))
    badge = db.Column(db.String(20), default="new")
    price = db.Column(db.Integer, nullable=False)
    old_price = db.Column(db.Integer)
    ram = db.Column(db.SmallInteger)
    storage = db.Column(db.SmallInteger)
    camera = db.Column(db.SmallInteger)
    battery = db.Column(db.SmallInteger)
    display = db.Column(db.String(120))
    chipset = db.Column(db.String(60))
    network = db.Column(db.String(10), default="5g")
    rating = db.Column(db.Numeric(2, 1), default=0.0)
    review_count = db.Column(db.Integer, default=0)
    amazon_url = db.Column(db.String(500))
    flipkart_url = db.Column(db.String(500))
    croma_url = db.Column(db.String(500))
    reliance_url = db.Column(db.String(500))

    brand = db.relationship("Brand", backref="phones")


class PhoneCategory(db.Model):
    __tablename__ = "phone_categories"

    phone_id = db.Column(db.Integer, db.ForeignKey("phones.id"), primary_key=True)
    category = db.Column(db.String(40), primary_key=True)


class PhoneSpec(db.Model):
    __tablename__ = "phone_specs"

    id = db.Column(db.Integer, primary_key=True)
    phone_id = db.Column(db.Integer, db.ForeignKey("phones.id"))
    spec_key = db.Column(db.String(100))
    spec_val = db.Column(db.Text)


class PriceHistory(db.Model):
    __tablename__ = "price_history"

    id = db.Column(db.Integer, primary_key=True)
    phone_id = db.Column(db.Integer, db.ForeignKey("phones.id"))
    price = db.Column(db.Integer)
    recorded_at = db.Column(db.DateTime, server_default=db.func.now())


def serialize_phone(phone, cats=None, specs=None, history=None):
    old_price = phone.old_price
    price = phone.price
    discount_pct = (
        round((old_price - price) * 100 / old_price, 1)
        if old_price and old_price > price
        else 0
    )

    return {
        "id": phone.id,
        "brand": phone.brand.name if phone.brand else "",
        "name": phone.name,
        "slug": phone.slug,
        "img": phone.img,
        "badge": phone.badge,
        "price": price,
        "oldPrice": old_price,
        "discount_pct": discount_pct,
        "ram": phone.ram,
        "storage": phone.storage,
        "camera": phone.camera,
        "battery": phone.battery,
        "display": phone.display,
        "chipset": phone.chipset,
        "network": phone.network,
        "rating": float(phone.rating) if phone.rating else 0.0,
        "reviews": phone.review_count,
        "category": cats or [],
        "amazon": phone.amazon_url,
        "flipkart": phone.flipkart_url,
        "croma": phone.croma_url,
        "reliance": phone.reliance_url,
        "specs": specs or {},
        "priceHistory": history or [],
    }


def get_cats(phone_id):
    return [
        row.category
        for row in PhoneCategory.query.filter_by(phone_id=phone_id).all()
    ]


def get_specs(phone_id):
    return {
        row.spec_key: row.spec_val
        for row in PhoneSpec.query.filter_by(phone_id=phone_id).all()
    }


def get_history(phone_id):
    return [
        row.price
        for row in PriceHistory.query.filter_by(phone_id=phone_id)
        .order_by(PriceHistory.recorded_at)
        .all()
    ]


def parse_budget(query):
    text = query.lower().replace(",", "")
    match = re.search(
        r"(?:under|below|less than|upto|up to|within)\s*(?:rs\.?|inr|₹)?\s*(\d+)",
        text,
    )
    return int(match.group(1)) if match else None


def score_phone(phone, query, budget):
    text = query.lower()
    score = float(phone.rating or 0) * 10 + min(phone.review_count or 0, 5000) / 1000

    if budget:
        if phone.price <= budget:
            score += 25
            score += max(0, budget - phone.price) / max(budget, 1) * 8
        else:
            score -= min(40, (phone.price - budget) / max(budget, 1) * 60)

    if "gaming" in text:
        if phone.ram and phone.ram >= 8:
            score += 10
        if phone.chipset and any(
            keyword in phone.chipset.lower()
            for keyword in ["snapdragon", "dimensity"]
        ):
            score += 8

    if "camera" in text or "photo" in text:
        score += min(phone.camera or 0, 200) / 10

    if "battery" in text or "long" in text:
        score += (phone.battery or 0) / 600

    if "5g" in text and phone.network == "5g":
        score += 12

    if "cheap" in text or "budget" in text or "value" in text:
        score += max(0, 150000 - phone.price) / 10000

    return score


def local_recommendation(query):
    budget = parse_budget(query)
    phones = Phone.query.join(Brand).all()
    ranked = sorted(
        phones,
        key=lambda phone: score_phone(phone, query, budget),
        reverse=True,
    )[:3]

    if not ranked:
        return (
            "I could not find matching phones yet. Try asking with a budget, "
            "brand, or use case."
        )

    picks = []
    for phone in ranked:
        reasons = [f"{phone.brand.name} {phone.name} at ₹{phone.price:,}"]
        if phone.ram:
            reasons.append(f"{phone.ram}GB RAM")
        if phone.camera:
            reasons.append(f"{phone.camera}MP camera")
        if phone.battery:
            reasons.append(f"{phone.battery}mAh battery")
        if phone.network:
            reasons.append(phone.network.upper())
        picks.append(", ".join(reasons))

    lead = "Based on your query"
    if budget:
        lead += f" under ₹{budget:,}"

    return (
        f"{lead}, I would shortlist {picks[0]}. Also consider {picks[1]} and "
        f"{picks[2]}. These are ranked from the available FindAny catalog by "
        "price fit, rating, and the specs mentioned in your request."
    )


def claude_recommendation(query):
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        return None

    phones = Phone.query.join(Brand).order_by(Phone.review_count.desc()).limit(20).all()
    summary = "\n".join(
        (
            f"{phone.brand.name} {phone.name}: ₹{phone.price:,}, {phone.ram}GB RAM, "
            f"{phone.storage}GB, {phone.camera}MP, {phone.battery}mAh, "
            f"{phone.chipset}, rating {float(phone.rating or 0)}"
        )
        for phone in phones
    )
    payload = {
        "model": os.environ.get("ANTHROPIC_MODEL", "claude-3-5-sonnet-20241022"),
        "max_tokens": 500,
        "messages": [
            {
                "role": "user",
                "content": (
                    "You are FindAny's AI assistant for Indian smartphone buyers. "
                    f'Query: "{query}"\n\nAvailable phones:\n{summary}\n\n'
                    "Give a concise recommendation in 3-4 sentences. Mention "
                    "specific phones. Use INR prices. Plain text, no markdown."
                ),
            }
        ],
    }
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            data = json.loads(response.read().decode("utf-8"))
            return data.get("content", [{}])[0].get("text")
    except (
        urllib.error.URLError,
        urllib.error.HTTPError,
        TimeoutError,
        KeyError,
        IndexError,
        json.JSONDecodeError,
    ):
        return None


def seed_sqlite():
    if Brand.query.count() > 0:
        return

    seed_path = os.path.join(os.path.dirname(__file__), "..", "database", "phones.json")
    if not os.path.exists(seed_path):
        return

    with open(seed_path, encoding="utf-8") as file_obj:
        data = json.load(file_obj)

    brand_cache = {}
    for phone in data:
        brand_name = phone["brand"]
        if brand_name not in brand_cache:
            brand = Brand(
                name=brand_name,
                slug=brand_name.lower().replace(" ", "-"),
            )
            db.session.add(brand)
            db.session.flush()
            brand_cache[brand_name] = brand.id

        new_phone = Phone(
            brand_id=brand_cache[brand_name],
            name=phone["name"],
            slug=(
                f"{brand_name}-{phone['name']}"
                .lower()
                .replace(" ", "-")
                .replace("/", "-")
            ),
            img=phone.get("img"),
            badge=phone.get("badge", "new"),
            price=phone["price"],
            old_price=phone.get("oldPrice"),
            ram=phone["ram"],
            storage=phone["storage"],
            camera=phone["camera"],
            battery=phone["battery"],
            display=phone.get("display"),
            chipset=phone.get("chipset"),
            network=phone.get("network", "5g"),
            rating=phone.get("rating", 0),
            review_count=phone.get("reviews", 0),
            amazon_url=phone.get("amazon"),
            flipkart_url=phone.get("flipkart"),
            croma_url=phone.get("croma"),
            reliance_url=phone.get("reliance"),
        )
        db.session.add(new_phone)
        db.session.flush()

        for category in phone.get("category", []):
            db.session.add(
                PhoneCategory(phone_id=new_phone.id, category=category)
            )

        for key, value in (phone.get("specs") or {}).items():
            db.session.add(
                PhoneSpec(phone_id=new_phone.id, spec_key=key, spec_val=value)
            )

        for historic_price in phone.get("priceHistory", []):
            db.session.add(
                PriceHistory(phone_id=new_phone.id, price=historic_price)
            )

    db.session.commit()
    print(f"[FindAny] Seeded {len(data)} phones.")


with app.app_context():
    db.create_all()
    if not MYSQL_URI:
        seed_sqlite()


@app.route("/api/phones", methods=["GET"])
def get_phones():
    query = Phone.query.join(Brand)

    price_min = request.args.get("price_min", type=int)
    price_max = request.args.get("price_max", type=int)
    if price_min:
        query = query.filter(Phone.price >= price_min)
    if price_max:
        query = query.filter(Phone.price <= price_max)

    rams = request.args.getlist("ram")
    if rams:
        query = query.filter(Phone.ram.in_([int(ram) for ram in rams]))

    storages = request.args.getlist("storage")
    if storages:
        query = query.filter(Phone.storage.in_([int(storage) for storage in storages]))

    chipsets = request.args.getlist("chipset")
    if chipsets:
        query = query.filter(Phone.chipset.in_(chipsets))

    camera_min = request.args.get("camera_min", type=int)
    if camera_min:
        query = query.filter(Phone.camera >= camera_min)

    battery_min = request.args.get("battery_min", type=int)
    if battery_min:
        query = query.filter(Phone.battery >= battery_min)

    networks = request.args.getlist("network")
    if networks:
        query = query.filter(Phone.network.in_(networks))

    category = request.args.get("category")
    if category and category != "all":
        query = query.join(
            PhoneCategory,
            Phone.id == PhoneCategory.phone_id,
        ).filter(PhoneCategory.category == category)

    search = request.args.get("q", "").strip()
    if search:
        like = f"%{search}%"
        query = query.filter(db.or_(Phone.name.ilike(like), Brand.name.ilike(like)))

    sort = request.args.get("sort", "popular")
    if sort == "price_asc":
        query = query.order_by(Phone.price.asc())
    elif sort == "price_desc":
        query = query.order_by(Phone.price.desc())
    elif sort == "rating":
        query = query.order_by(Phone.rating.desc())
    elif sort == "newest":
        query = query.order_by(Phone.id.desc())
    else:
        query = query.order_by(Phone.review_count.desc())

    phones = query.all()
    return jsonify([serialize_phone(phone, get_cats(phone.id)) for phone in phones])


@app.route("/api/phones/<int:phone_id>", methods=["GET"])
def get_phone(phone_id):
    phone = Phone.query.get_or_404(phone_id)
    return jsonify(
        serialize_phone(
            phone,
            get_cats(phone.id),
            get_specs(phone.id),
            get_history(phone.id),
        )
    )


@app.route("/api/phones/search/suggest", methods=["GET"])
def suggest():
    query = request.args.get("q", "").strip()
    if len(query) < 2:
        return jsonify([])

    like = f"%{query}%"
    phones = (
        Phone.query.join(Brand)
        .filter(db.or_(Phone.name.ilike(like), Brand.name.ilike(like)))
        .limit(6)
        .all()
    )
    return jsonify(
        [{"id": phone.id, "label": f"{phone.brand.name} {phone.name}"} for phone in phones]
    )


@app.route("/api/brands", methods=["GET"])
def get_brands():
    return jsonify(
        [
            {"id": brand.id, "name": brand.name, "slug": brand.slug}
            for brand in Brand.query.order_by(Brand.name).all()
        ]
    )


@app.route("/api/phones/<int:phone_id>/history", methods=["GET"])
def price_history(phone_id):
    rows = (
        PriceHistory.query.filter_by(phone_id=phone_id)
        .order_by(PriceHistory.recorded_at)
        .all()
    )
    return jsonify([{"price": row.price, "date": str(row.recorded_at)} for row in rows])


@app.route("/api/stats", methods=["GET"])
def stats():
    return jsonify(
        {
            "total_phones": Phone.query.count(),
            "total_brands": Brand.query.count(),
            "db_engine": "MySQL" if MYSQL_URI else "SQLite (dev)",
        }
    )


@app.route("/api/ai/recommend", methods=["POST"])
def ai_recommend():
    data = request.get_json(silent=True) or {}
    query = (data.get("query") or "").strip()
    if not query:
        return jsonify({"error": "Query is required"}), 400

    answer = claude_recommendation(query) or local_recommendation(query)
    return jsonify({"answer": answer})


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "app": "FindAny"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
