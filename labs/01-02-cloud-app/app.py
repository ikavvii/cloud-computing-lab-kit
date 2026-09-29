"""Small authenticated CRUD lab. PostgreSQL can be local or a hosted provider."""
import hmac
import os
import secrets
from decimal import Decimal, InvalidOperation
from pathlib import Path
import psycopg
from psycopg.rows import dict_row
from flask import Flask, abort, redirect, render_template, request, session, url_for

app = Flask(__name__)
app.secret_key = os.environ["SECRET_KEY"]
password = os.environ["APP_PASSWORD"]
if len(password) < 12 or len(app.secret_key) < 24:
    raise RuntimeError("Set APP_PASSWORD (12+ characters) and SECRET_KEY (24+ characters)")
app.config.update(SESSION_COOKIE_HTTPONLY=True, SESSION_COOKIE_SAMESITE="Lax",
                  SESSION_COOKIE_SECURE=os.getenv("COOKIE_SECURE", "true").lower() == "true",
                  MAX_CONTENT_LENGTH=16384)

def connect():
    return psycopg.connect(os.environ["DATABASE_URL"], connect_timeout=10, row_factory=dict_row)

# Startup failure is explicit if the real database is unreachable.
with connect() as db:
    db.execute(Path(__file__).with_name("schema.sql").read_text())

@app.before_request
def protect():
    if request.endpoint == "health":
        return
    if "csrf" not in session:
        session["csrf"] = secrets.token_hex(24)
    if request.method == "POST":
        if not hmac.compare_digest(request.form.get("csrf", ""), session["csrf"]):
            abort(400, "Invalid form token. Reload the page.")
    if request.endpoint != "login" and not session.get("logged_in"):
        return redirect(url_for("login"))

@app.get("/health")
def health():
    with connect() as db:
        db.execute("SELECT 1")
    return {"status": "ok"}

@app.route("/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        if hmac.compare_digest(request.form.get("password", ""), password):
            session.clear()
            session.update(logged_in=True, csrf=secrets.token_hex(24))
            return redirect(url_for("index"))
        error = "Incorrect password"
    return render_template("login.html", error=error)

@app.post("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))

@app.get("/")
def index():
    with connect() as db:
        rows = db.execute("SELECT id, name, price FROM products ORDER BY id").fetchall()
    return render_template("index.html", products=rows)

def product_values():
    name = request.form.get("name", "").strip()
    if not name or len(name) > 100:
        abort(400, "Name must contain 1-100 characters")
    try:
        price = Decimal(request.form.get("price", ""))
        if not price.is_finite() or price < 0 or price > Decimal("99999999.99"):
            raise ValueError()
        if price != price.quantize(Decimal("0.01")):
            raise ValueError()
    except (InvalidOperation, ValueError):
        abort(400, "Price must be nonnegative, with at most two decimal places")
    return name, price

@app.post("/products")
def create():
    name, price = product_values()
    with connect() as db:
        db.execute("INSERT INTO products(name, price) VALUES (%s, %s)", (name, price))
    return redirect(url_for("index"), code=303)

@app.post("/products/<int:product_id>/update")
def update(product_id):
    name, price = product_values()
    with connect() as db:
        if db.execute("UPDATE products SET name=%s, price=%s WHERE id=%s",
                      (name, price, product_id)).rowcount == 0:
            abort(404)
    return redirect(url_for("index"), code=303)

@app.post("/products/<int:product_id>/delete")
def delete(product_id):
    with connect() as db:
        if db.execute("DELETE FROM products WHERE id=%s", (product_id,)).rowcount == 0:
            abort(404)
    return redirect(url_for("index"), code=303)
