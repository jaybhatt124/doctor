from flask import Flask, render_template, request, jsonify, session, send_from_directory
import pymysql
import os
from functools import wraps
from werkzeug.utils import secure_filename
from datetime import datetime

pymysql.install_as_MySQLdb()

# ✅ VERCEL TEMPLATE & STATIC FIX
app = Flask(
    __name__,
    template_folder="../templates",
    static_folder="../static"
)

app.secret_key = "aidoctor-secret-2024"

# ✅ Upload folder (Vercel allows only /tmp)
UPLOAD_FOLDER = "/tmp"
ALLOWED_EXT = {"png", "jpg", "jpeg", "gif", "webp"}

app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
app.config["MAX_CONTENT_LENGTH"] = 5 * 1024 * 1024


# ───────────────────────────────
# DATABASE CONFIG (SAFE VERSION)
# ───────────────────────────────
def get_db():
    return pymysql.connect(
        host=os.environ.get("DB_HOST"),
        port=4000,
        user=os.environ.get("DB_USER"),
        password=os.environ.get("DB_PASSWORD"),
        database=os.environ.get("DB_NAME"),
        ssl={"ssl": {}},
        cursorclass=pymysql.cursors.DictCursor
    )
    except Exception as e:
        print("DATABASE ERROR:", e)
        return None


def q(sql, args=(), one=False):
    conn = get_db()
    if not conn:
        return None if one else []

    try:
        with conn.cursor() as c:
            c.execute(sql, args)
            return c.fetchone() if one else c.fetchall()
    except Exception as e:
        print("QUERY ERROR:", e)
        return None if one else []
    finally:
        conn.close()


def ex(sql, args=()):
    conn = get_db()
    if not conn:
        return None

    try:
        with conn.cursor() as c:
            c.execute(sql, args)
            return c.lastrowid
    except Exception as e:
        print("EXEC ERROR:", e)
        return None
    finally:
        conn.close()


def admin_only(f):
    @wraps(f)
    def wrap(*a, **kw):
        if not session.get("admin"):
            return jsonify(success=False, message="Unauthorised"), 401
        return f(*a, **kw)
    return wrap


# ───────────────────────────────
# PAGE ROUTES
# ───────────────────────────────

@app.route("/")
def home():
    return render_template("index.html")


@app.route("/about")
def about():
    return render_template("about.html")


@app.route("/tips")
def tips():
    return render_template("tips.html")


@app.route("/contact")
def contact():
    return render_template("contact.html")


@app.route("/illness")
def illness():
    part = request.args.get("part")

    if not part:
        return "No body part selected"

    data = q("SELECT * FROM illnesses WHERE body_part=%s", (part,))
    return render_template("illness.html", illnesses=data, part=part)


@app.route("/health")
def health():
    return jsonify(status="running")


@app.route("/uploads/<path:fn>")
def uploads(fn):
    return send_from_directory(app.config["UPLOAD_FOLDER"], fn)


# ───────────────────────────────
# CONTACT API
# ───────────────────────────────

@app.route("/api/contact", methods=["POST"])
def api_contact():
    data = request.get_json() or {}
    name = data.get("name", "").strip()
    email = data.get("email", "").strip()
    message = data.get("message", "").strip()

    if not all([name, email, message]):
        return jsonify(success=False, message="All fields required")

    ex(
        "INSERT INTO contact_messages(name,email,message) VALUES(%s,%s,%s)",
        (name, email, message)
    )

    return jsonify(success=True, message="Message sent!")


# ───────────────────────────────
# FILE UPLOAD
# ───────────────────────────────

@app.route("/admin/medicine/upload/<int:mid>", methods=["POST"])
@admin_only
def admin_upload(mid):
    if "image" not in request.files:
        return jsonify(success=False, message="No file")

    f = request.files["image"]

    if f and "." in f.filename:
        ext = f.filename.rsplit(".", 1)[1].lower()
        if ext in ALLOWED_EXT:
            filename = secure_filename(
                f"med_{mid}_{int(datetime.now().timestamp())}.{ext}"
            )
            save_path = os.path.join(app.config["UPLOAD_FOLDER"], filename)
            f.save(save_path)

            ex("UPDATE medicines SET image_path=%s WHERE id=%s", (filename, mid))
            return jsonify(success=True, filename=filename)

    return jsonify(success=False, message="Invalid file")


# ───────────────────────────────
if __name__ == "__main__":
    app.run()
