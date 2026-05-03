from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import os
import json
import urllib.error
import urllib.request

app = Flask(__name__)
CORS(app)

MYSQL_URI = os.environ.get("DATABASE_URL")
SQLITE_URI = "sqlite:///findany.db"
app.config["SQLALCHEMY_DATABASE_URI"] = MYSQL_URI or SQLITE_URI
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)

class Brand(db.Model):
    __tablename__ = "brands"
    id      = db.Column(db.Integer, primary_key=True)
    name    = db.Column(db.String(80), unique=True, nullable=False)
    slug    = db.Column(db.String(80), unique=True, nullable=False)
    country = db.Column(db.String(80))
    website = db.Column(db.String(255))

class Phone(db.Model):
    __tablename__ = "phones"
    id           = db.Column(db.Integer, primary_key=True)
    brand_id     = db.Column(db.Integer, db.ForeignKey("brands.id"), nullable=False)
    name         = db.Column(db.String(150), nullable=False)
    slug         = db.Column(db.String(150), unique=True)
    img          = db.Column(db.String(500))
    badge        = db.Column(db.String(20), default="new")
    price        = db.Column(db.Integer, nullable=False)
    old_price    = db.Column(db.Integer)
    ram          = db.Column(db.SmallInteger)
    storage      = db.Column(db.SmallInteger)
    camera       = db.Column(db.SmallInteger)
    battery      = db.Column(db.SmallInteger)
    display      = db.Column(db.String(120))
    chipset      = db.Column(db.String(60))
    network      = db.Column(db.String(10), default="5g")
    rating       = db.Column(db.Numeric(2,1), default=0.0)
    review_count = db.Column(db.Integer, default=0)
    amazon_url   = db.Column(db.String(500))
    flipkart_url = db.Column(db.String(500))
    croma_url    = db.Column(db.String(500))
    reliance_url = db.Column(db.String(500))
    brand        = db.relationship("Brand", backref="phones")

class PhoneCategory(db.Model):
    __tablename__ = "phone_categories"
    phone_id = db.Column(db.Integer, db.ForeignKey("phones.id"), primary_key=True)
    category = db.Column(db.String(40), primary_key=True)

class PhoneSpec(db.Model):
    __tablename__ = "phone_specs"
    id       = db.Column(db.Integer, primary_key=True)
    phone_id = db.Column(db.Integer, db.ForeignKey("phones.id"))
    spec_key = db.Column(db.String(100))
    spec_val = db.Column(db.Text)

class PriceHistory(db.Model):
    __tablename__ = "price_history"
    id          = db.Column(db.Integer, primary_key=True)
    phone_id    = db.Column(db.Integer, db.ForeignKey("phones.id"))
    price       = db.Column(db.Integer)
    recorded_at = db.Column(db.DateTime, server_default=db.func.now())

def serialize_phone(p, cats=None, specs=None, history=None):
    return {
        "id": p.id, "brand": p.brand.name if p.brand else "",
        "name": p.name, "slug": p.slug, "img": p.img, "badge": p.badge,
        "price": p.price, "oldPrice": p.old_price,
        "discount_pct": round((p.old_price-p.price)*100/p.old_price,1) if p.old_price and p.old_price>p.price else 0,
        "ram": p.ram, "storage": p.storage, "camera": p.camera,
        "battery": p.battery, "display": p.display, "chipset": p.chipset,
        "network": p.network, "rating": float(p.rating) if p.rating else 0.0,
        "reviews": p.review_count, "category": cats or [],
        "amazon": p.amazon_url, "flipkart": p.flipkart_url,
        "croma": p.croma_url, "reliance": p.reliance_url,
        "specs": specs or {}, "priceHistory": history or [],
    }

def get_cats(pid):    return [r.category for r in PhoneCategory.query.filter_by(phone_id=pid).all()]
def get_specs(pid):   return {r.spec_key: r.spec_val for r in PhoneSpec.query.filter_by(phone_id=pid).all()}
def get_history(pid): return [r.price for r in PriceHistory.query.filter_by(phone_id=pid).order_by(PriceHistory.recorded_at).all()]

def parse_budget(query):
    import re
    text = query.lower().replace(",", "")
    match = re.search(r"(?:under|below|less than|upto|up to|within)\s*(?:rs\.?|inr|₹)?\s*(\d+)", text)
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
        if phone.ram and phone.ram >= 8: score += 10
        if phone.chipset and any(k in phone.chipset.lower() for k in ["snapdragon", "dimensity"]): score += 8
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
    ranked = sorted(phones, key=lambda p: score_phone(p, query, budget), reverse=True)[:3]
    if not ranked:
        return "I could not find matching phones yet. Try asking with a budget, brand, or use case."

    picks = []
    for p in ranked:
        reasons = [f"{p.brand.name} {p.name} at ₹{p.price:,}"]
        if p.ram: reasons.append(f"{p.ram}GB RAM")
        if p.camera: reasons.append(f"{p.camera}MP camera")
        if p.battery: reasons.append(f"{p.battery}mAh battery")
        if p.network: reasons.append(p.network.upper())
        picks.append(", ".join(reasons))

    lead = "Based on your query"
    if budget:
        lead += f" under ₹{budget:,}"
    return f"{lead}, I would shortlist {picks[0]}. Also consider {picks[1]} and {picks[2]}. These are ranked from the available FindAny catalog by price fit, rating, and the specs mentioned in your request."

def claude_recommendation(query):
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        return None

    phones = Phone.query.join(Brand).order_by(Phone.review_count.desc()).limit(20).all()
    summary = "\n".join(
        f"{p.brand.name} {p.name}: ₹{p.price:,}, {p.ram}GB RAM, {p.storage}GB, "
        f"{p.camera}MP, {p.battery}mAh, {p.chipset}, rating {float(p.rating or 0)}"
        for p in phones
    )
    payload = {
        "model": os.environ.get("ANTHROPIC_MODEL", "claude-3-5-sonnet-20241022"),
        "max_tokens": 500,
        "messages": [{
            "role": "user",
            "content": (
                "You are FindAny's AI assistant for Indian smartphone buyers. "
                f"Query: \"{query}\"\n\nAvailable phones:\n{summary}\n\n"
                "Give a concise recommendation in 3-4 sentences. Mention specific phones. "
                "Use INR prices. Plain text, no markdown."
            )
        }]
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
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data.get("content", [{}])[0].get("text")
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, KeyError, IndexError, json.JSONDecodeError):
        return None

def seed_sqlite():
    import json
    if Brand.query.count() > 0: return
    seed_path = os.path.join(os.path.dirname(__file__), "..", "database", "phones.json")
    if not os.path.exists(seed_path): return
    with open(seed_path) as f: data = json.load(f)
    brand_cache = {}
    for p in data:
        bname = p["brand"]
        if bname not in brand_cache:
            b = Brand(name=bname, slug=bname.lower().replace(" ","-"))
            db.session.add(b); db.session.flush()
            brand_cache[bname] = b.id
        ph = Phone(brand_id=brand_cache[bname], name=p["name"],
            slug=f"{bname}-{p['name']}".lower().replace(" ","-").replace("/","-"),
            img=p.get("img"), badge=p.get("badge","new"),
            price=p["price"], old_price=p.get("oldPrice"),
            ram=p["ram"], storage=p["storage"], camera=p["camera"],
            battery=p["battery"], display=p.get("display"), chipset=p.get("chipset"),
            network=p.get("network","5g"), rating=p.get("rating",0),
            review_count=p.get("reviews",0),
            amazon_url=p.get("amazon"), flipkart_url=p.get("flipkart"),
            croma_url=p.get("croma"), reliance_url=p.get("reliance"))
        db.session.add(ph); db.session.flush()
        for cat in p.get("category",[]): db.session.add(PhoneCategory(phone_id=ph.id,category=cat))
        for k,v in (p.get("specs") or {}).items(): db.session.add(PhoneSpec(phone_id=ph.id,spec_key=k,spec_val=v))
        for price in p.get("priceHistory",[]): db.session.add(PriceHistory(phone_id=ph.id,price=price))
    db.session.commit()
    print(f"[FindAny] Seeded {len(data)} phones.")

with app.app_context():
    db.create_all()
    if not MYSQL_URI: seed_sqlite()

@app.route("/api/phones", methods=["GET"])
def get_phones():
    q = Phone.query.join(Brand)
    price_min = request.args.get("price_min",type=int)
    price_max = request.args.get("price_max",type=int)
    if price_min: q = q.filter(Phone.price >= price_min)
    if price_max: q = q.filter(Phone.price <= price_max)
    rams = request.args.getlist("ram")
    if rams: q = q.filter(Phone.ram.in_([int(r) for r in rams]))
    storages = request.args.getlist("storage")
    if storages: q = q.filter(Phone.storage.in_([int(s) for s in storages]))
    chipsets = request.args.getlist("chipset")
    if chipsets: q = q.filter(Phone.chipset.in_(chipsets))
    cam_min = request.args.get("camera_min",type=int)
    if cam_min: q = q.filter(Phone.camera >= cam_min)
    bat_min = request.args.get("battery_min",type=int)
    if bat_min: q = q.filter(Phone.battery >= bat_min)
    networks = request.args.getlist("network")
    if networks: q = q.filter(Phone.network.in_(networks))
    category = request.args.get("category")
    if category and category != "all":
        q = q.join(PhoneCategory, Phone.id==PhoneCategory.phone_id).filter(PhoneCategory.category==category)
    search = request.args.get("q","").strip()
    if search:
        like = f"%{search}%"
        q = q.filter(db.or_(Phone.name.ilike(like), Brand.name.ilike(like)))
    sort = request.args.get("sort","popular")
    if sort=="price_asc":    q = q.order_by(Phone.price.asc())
    elif sort=="price_desc": q = q.order_by(Phone.price.desc())
    elif sort=="rating":     q = q.order_by(Phone.rating.desc())
    elif sort=="newest":     q = q.order_by(Phone.id.desc())
    else:                    q = q.order_by(Phone.review_count.desc())
    phones = q.all()
    return jsonify([serialize_phone(p, get_cats(p.id)) for p in phones])

@app.route("/api/phones/<int:phone_id>", methods=["GET"])
def get_phone(phone_id):
    p = Phone.query.get_or_404(phone_id)
    return jsonify(serialize_phone(p, get_cats(p.id), get_specs(p.id), get_history(p.id)))

@app.route("/api/phones/search/suggest", methods=["GET"])
def suggest():
    q = request.args.get("q","").strip()
    if len(q) < 2: return jsonify([])
    like = f"%{q}%"
    phones = Phone.query.join(Brand).filter(db.or_(Phone.name.ilike(like),Brand.name.ilike(like))).limit(6).all()
    return jsonify([{"id":p.id,"label":f"{p.brand.name} {p.name}"} for p in phones])

@app.route("/api/brands", methods=["GET"])
def get_brands():
    return jsonify([{"id":b.id,"name":b.name,"slug":b.slug} for b in Brand.query.order_by(Brand.name).all()])

@app.route("/api/phones/<int:phone_id>/history", methods=["GET"])
def price_history(phone_id):
    rows = PriceHistory.query.filter_by(phone_id=phone_id).order_by(PriceHistory.recorded_at).all()
    return jsonify([{"price":r.price,"date":str(r.recorded_at)} for r in rows])

@app.route("/api/stats", methods=["GET"])
def stats():
    return jsonify({"total_phones":Phone.query.count(),"total_brands":Brand.query.count(),"db_engine":"MySQL" if MYSQL_URI else "SQLite (dev)"})

@app.route("/api/ai/recommend", methods=["POST"])
def ai_recommend():
    data = request.get_json(silent=True) or {}
    query = (data.get("query") or "").strip()
    if not query:
        return jsonify({"error":"Query is required"}), 400

    answer = claude_recommendation(query) or local_recommendation(query)
    return jsonify({"answer": answer})

@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status":"ok","app":"FindAny"})

if __name__ == "__main__":
    app.run(host="0.0.0.0",port=5000,debug=True)
