import os
from datetime import date
from flask import Flask, render_template, request, redirect, url_for, flash, session
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
from dotenv import load_dotenv
import psycopg
import psycopg.rows


load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "dev-secret")

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "dbname": os.getenv("DB_NAME", "restaurant_recs"),
    "user": os.getenv("DB_USER", "appuser"),
    "password": os.getenv("DB_PASSWORD", ""),
    "port": int(os.getenv("DB_PORT", "5432")),
}


def get_conn():
    return psycopg.connect(
        host=DB_CONFIG["host"],
        port=DB_CONFIG["port"],
        dbname=DB_CONFIG["dbname"],
        user=DB_CONFIG["user"],
        password=DB_CONFIG["password"],
        row_factory=psycopg.rows.dict_row,
    )

def current_user():
    uid = session.get("user_id")
    if not uid:
        return None
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            "SELECT id, username, email FROM users WHERE id = %s;",
            (uid,),
        )
        return cur.fetchone()


def login_required(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        if not session.get("user_id"):
            flash("Za ovu radnju moraš biti prijavljen/a.", "error")
            return redirect(url_for("login", next=request.path))
        return fn(*args, **kwargs)
    return wrapper

@app.context_processor
def inject_user():
    return {"current_user": current_user()}


@app.get("/")
def home():
    return redirect(url_for("places"))


@app.get("/places")
def places():
    q = request.args.get("q", "").strip()
    with get_conn() as conn, conn.cursor() as cur:
        if q:
            cur.execute(
                """
                SELECT id, name, address, avg_rating, review_count
                FROM v_place_overview
                WHERE name ILIKE %s OR address ILIKE %s
                ORDER BY avg_rating DESC NULLS LAST, review_count DESC, name ASC;
                """,
                (f"%{q}%", f"%{q}%"),
            )
        else:
            cur.execute(
                """
                SELECT id, name, address, avg_rating, review_count
                FROM v_place_overview
                ORDER BY avg_rating DESC NULLS LAST, review_count DESC, name ASC;
                """
            )
        rows = cur.fetchall()
    return render_template("places.html", places=rows, q=q)



@app.get("/places/<int:place_id>")
def place_detail(place_id: int):
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            """
            SELECT id, name, address, description, avg_rating, review_count, meta
            FROM v_place_overview
            WHERE id = %s;
            """,
            (place_id,),
        )
        place = cur.fetchone()
        if not place:
            flash("Restoran nije pronađen.", "error")
            return redirect(url_for("places"))

        cur.execute(
            """
            SELECT r.id, r.rating, r.comment, r.visited_at, r.created_at,
                   u.username
            FROM reviews r
            JOIN users u ON u.id = r.user_id
            WHERE r.place_id = %s
            ORDER BY r.visited_at DESC, r.created_at DESC;
            """,
            (place_id,),
        )
        reviews = cur.fetchall()

       

    return render_template(
        "place_detail.html",
        place=place,
        reviews=reviews,
    )



@app.route("/add-place", methods=["GET", "POST"])
@login_required
def add_place():
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        address = request.form.get("address", "").strip()
        description = request.form.get("description", "").strip()
        lat = request.form.get("lat", "").strip()
        lon = request.form.get("lon", "").strip()

        if not name or not address:
            flash("Naziv i adresa su obavezni.", "error")
            return redirect(url_for("add_place"))

        lat_f = None
        lon_f = None

        try:
            import requests

            r = requests.get(
                "https://nominatim.openstreetmap.org/search",
                params={
                    "q": address,
                    "format": "json",
                    "limit": 1,
                    "countrycodes": "hr",
                },
                headers={"User-Agent": "restaurant-recs-demo"},
                timeout=5,
            )
            data = r.json()
            if data:
                lat_f = float(data[0]["lat"])
                lon_f = float(data[0]["lon"])
        except Exception:
            pass

        if lat_f is None or lon_f is None:
            if not lat or not lon:
                flash(
                    "Lokacija se nije mogla automatski odrediti iz adrese. "
                    "Molimo unesite lat/lon ručno.",
                    "error",
                )
                return redirect(url_for("add_place"))
            try:
                lat_f = float(lat)
                lon_f = float(lon)
            except ValueError:
                flash("Lat/Lon moraju biti brojevi.", "error")
                return redirect(url_for("add_place"))

        def bool_from(field: str) -> bool:
            return True if request.form.get(field) == "1" else False

        meta = {
            "wifi": bool_from("wifi"),
            "parking": bool_from("parking"),
            "pets_allowed": bool_from("pets_allowed"),
            "delivery": bool_from("delivery"),
            "takeaway": bool_from("takeaway"),
        }

        price_level_raw = request.form.get("price_level", "").strip()
        if price_level_raw:
            try:
                meta["price_level"] = int(price_level_raw)
            except ValueError:
                meta["price_level"] = None

        cuisine_raw = request.form.get("cuisine", "").strip()
        if cuisine_raw:
            meta["cuisine"] = [c.strip() for c in cuisine_raw.split(",") if c.strip()]

        opening_raw = request.form.get("opening_hours", "").strip()
        if opening_raw:
            oh = {}
            parts = []
            for seg in opening_raw.splitlines():
                for piece in seg.split(";"):
                    if piece.strip():
                        parts.append(piece.strip())

            for part in parts:
                if ":" in part:
                    k, v = part.split(":", 1)
                    oh[k.strip()] = v.strip()
                elif "=" in part:
                    k, v = part.split("=", 1)
                    oh[k.strip()] = v.strip()

            if oh:
                meta["opening_hours"] = oh

        import json as _json
        with get_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO places (name, address, description, location, meta)
                VALUES (%s, %s, %s, ST_SetSRID(ST_MakePoint(%s, %s), 4326), %s::jsonb)
                RETURNING id;
                """,
                (name, address, description or None, lon_f, lat_f, _json.dumps(meta)),
            )
            new_id = cur.fetchone()["id"]
            conn.commit()

        flash("Restoran dodan.", "ok")
        return redirect(url_for("place_detail", place_id=new_id))

    meta_example = {
        "wifi": True,
        "parking": False,
        "pets_allowed": True,
        "price_level": 2,
        "cuisine": ["italian", "pizza"],
        "opening_hours": {"mon-fri": "10-22", "sat-sun": "12-23"},
        "takeaway": True,
        "delivery": False,
    }

    import json as _json
    return render_template(
        "add_place.html",
        meta_example=_json.dumps(meta_example, indent=2, ensure_ascii=False),
    )



@app.route("/places/<int:place_id>/add-review", methods=["POST"])
@login_required
def add_review(place_id: int):
    user_id = session["user_id"]

    rating = request.form.get("rating", "").strip()
    comment = request.form.get("comment", "").strip()
    visited_at = request.form.get("visited_at", "").strip()

    try:
        rating_i = int(rating)
        if rating_i < 1 or rating_i > 5:
            raise ValueError()
    except ValueError:
        flash("Ocjena mora biti cijeli broj 1–5.", "error")
        return redirect(url_for("place_detail", place_id=place_id))

    try:
        y, m, d = visited_at.split("-")
        visited = date(int(y), int(m), int(d))
    except Exception:
        flash("visited_at mora biti u formatu YYYY-MM-DD.", "error")
        return redirect(url_for("place_detail", place_id=place_id))

    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO reviews (user_id, place_id, rating, comment, visited_at)
            VALUES (%s, %s, %s, %s, %s);
            """,
            (user_id, place_id, rating_i, comment or None, visited),
        )
        conn.commit()

    flash("Recenzija dodana.", "ok")
    return redirect(url_for("place_detail", place_id=place_id))



@app.get("/search")
def search():
    lat = request.args.get("lat", "").strip()
    lon = request.args.get("lon", "").strip()
    address = request.args.get("address", "").strip()
    radius_m = request.args.get("radius_m", "2000").strip()
    wifi = request.args.get("wifi", "").strip()
    delivery = request.args.get("delivery", "").strip()
    takeaway = request.args.get("takeaway", "").strip()
    pets_allowed = request.args.get("pets_allowed", "").strip()

    rows = []
    err = None

    # geocoding ako je adresa unesena
    if address and not (lat and lon):
        import requests
        try:
            r = requests.get(
                "https://nominatim.openstreetmap.org/search",
                params={
                    "q": address,
                    "format": "json",
                    "limit": 1,
                    "countrycodes": "hr",
                },
                headers={"User-Agent": "restaurant-recs-demo"},
                timeout=5,
            )
            data = r.json()
            if data:
                lat = data[0]["lat"]
                lon = data[0]["lon"]
            else:
                err = "Adresa nije pronađena."
        except Exception:
            err = "Greška pri dohvaćanju lokacije."

    if lat and lon and not err:
        try:
            lat_f = float(lat)
            lon_f = float(lon)
            radius_i = int(radius_m)
        except ValueError:
            err = "Lat/Lon moraju biti brojevi."
        else:
            with get_conn() as conn, conn.cursor() as cur:
                sql = """
                    SELECT
                      v.id, v.name, v.address, v.avg_rating, v.review_count,
                      ROUND(
                        ST_Distance(
                          v.location::geography,
                          ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography
                        )
                      ) AS distance_m
                    FROM v_place_overview v
                    WHERE ST_DWithin(
                      v.location::geography,
                      ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography,
                      %s
                    )
                """

                params = [lon_f, lat_f, lon_f, lat_f, radius_i]

                if wifi == "1":
                    sql += " AND (v.meta->>'wifi')::boolean = true"

                if delivery == "1":
                    sql += " AND (v.meta->>'delivery')::boolean = true"

                if takeaway == "1":
                    sql += " AND (v.meta->>'takeaway')::boolean = true"

                if pets_allowed == "1":
                    sql += " AND (v.meta->>'pets_allowed')::boolean = true"


                sql += """
                    ORDER BY v.avg_rating DESC NULLS LAST, v.review_count DESC, distance_m ASC
                    LIMIT 50;
                """

                cur.execute(sql, params)
                rows = cur.fetchall()

    return render_template(
        "search.html",
        rows=rows,
        lat=lat,
        lon=lon,
        address=address,
        radius_m=radius_m,
        wifi=wifi,
        delivery=delivery,
        takeaway=takeaway,
        pets_allowed=pets_allowed,
        err=err,
    )

@app.get("/trending")
def trending():
    days = request.args.get("days", "30").strip()
    try:
        days_i = int(days)
        if days_i < 1 or days_i > 365:
            raise ValueError()
    except ValueError:
        days_i = 30

    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            """
            SELECT
              p.id,
              p.name,
              COUNT(r.id) AS reviews_last_nd,
              ROUND(AVG(r.rating)::numeric, 2) AS avg_rating_last_nd
            FROM places p
            JOIN reviews r ON r.place_id = p.id
            WHERE r.visited_at >= CURRENT_DATE - (%s * INTERVAL '1 day')
            GROUP BY p.id, p.name
            HAVING COUNT(r.id) >= 1
            ORDER BY reviews_last_nd DESC, avg_rating_last_nd DESC
            LIMIT 50;
            """,
            (days_i,),
        )
        rows = cur.fetchall()

    return render_template("trending.html", rows=rows, days=days_i)

@app.route("/register", methods=["GET", "POST"])
def register():
    if session.get("user_id"):
        return redirect(url_for("places"))

    if request.method == "POST":
        username = request.form.get("username", "").strip()
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")
        password2 = request.form.get("password2", "")

        if not username or not email or not password or not password2:
            flash("Sva polja su obavezna.", "error")
            return redirect(url_for("register"))

        if password != password2:
            flash("Lozinke se ne podudaraju.", "error")
            return redirect(url_for("register"))

        if len(password) < 6:
            flash("Lozinka mora imati barem 6 znakova.", "error")
            return redirect(url_for("register"))

        pw_hash = generate_password_hash(password)

        with get_conn() as conn, conn.cursor() as cur:
            try:
                cur.execute(
                    """
                    INSERT INTO users (username, email, password_hash)
                    VALUES (%s, %s, %s)
                    RETURNING id;
                    """,
                    (username, email, pw_hash),
                )
                uid = cur.fetchone()["id"]
                conn.commit()
            except Exception:
                conn.rollback()
                flash("Korisničko ime ili e-mail već postoje.", "error")
                return redirect(url_for("register"))

        session["user_id"] = uid
        flash("Registracija uspješna. Prijavljen/a si.", "ok")
        return redirect(url_for("places"))

    return render_template("register.html", title="Registracija")

@app.route("/login", methods=["GET", "POST"])
def login():
    if session.get("user_id"):
        return redirect(url_for("places"))

    if request.method == "POST":
        ident = request.form.get("ident", "").strip().lower() 
        password = request.form.get("password", "")

        if not ident or not password:
            flash("Unesi korisničko ime/e-mail i lozinku.", "error")
            return redirect(url_for("login"))

        with get_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, username, email, password_hash
                FROM users
                WHERE lower(username)=%s OR lower(email)=%s;
                """,
                (ident, ident),
            )
            u = cur.fetchone()

        if not u or not check_password_hash(u["password_hash"], password):
            flash("Neispravni podaci za prijavu.", "error")
            return redirect(url_for("login"))

        session["user_id"] = u["id"]
        flash(f"Dobrodošao/la, {u['username']}!", "ok")

        nxt = request.args.get("next")
        return redirect(nxt or url_for("places"))

    return render_template("login.html", title="Prijava")

@app.get("/logout")
def logout():
    session.pop("user_id", None)
    flash("Odjavljen/a si.", "ok")
    return redirect(url_for("places"))


if __name__ == "__main__":
    app.run(debug=True, host="127.0.0.1", port=5000)

