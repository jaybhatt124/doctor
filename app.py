"""
AI Doctor Analysis — Flask Backend
All HTML pages served as separate templates.
Admin: admin@gmail.com / admin123
"""
from flask import Flask, render_template, request, jsonify, session, redirect, send_from_directory
import pymysql
pymysql.install_as_MySQLdb()

from flask import Flask
import os
from functools import wraps
from werkzeug.utils import secure_filename
from datetime import datetime

app = Flask(__name__)
app.secret_key = "aidoctor-secret-2024"

UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), "uploads")
ALLOWED_EXT = {"png","jpg","jpeg","gif","webp"}
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
app.config["MAX_CONTENT_LENGTH"] = 5 * 1024 * 1024
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ── DB CONFIG — change password to yours ──────────────────────
DB = dict(
    host="localhost", user="root", password="root",
    db="ai_doctor_db", charset="utf8mb4",
    cursorclass=pymysql.cursors.DictCursor, autocommit=True
)

def get_db():
    return pymysql.connect(**DB)

def q(sql, args=(), one=False):
    conn = get_db()
    try:
        with conn.cursor() as c:
            c.execute(sql, args)
            return c.fetchone() if one else c.fetchall()
    finally:
        conn.close()

def ex(sql, args=()):
    conn = get_db()
    try:
        with conn.cursor() as c:
            c.execute(sql, args)
            return c.lastrowid
    finally:
        conn.close()

def admin_only(f):
    @wraps(f)
    def wrap(*a, **kw):
        if not session.get("admin"):
            return jsonify(success=False, message="Unauthorised"), 401
        return f(*a, **kw)
    return wrap

# ═══════════════════════════════════════════════
# PAGE ROUTES — each returns its own HTML file
# ═══════════════════════════════════════════════
@app.route("/")
def pg_home():       return render_template("index.html")

@app.route("/about")
def pg_about():      return render_template("about.html")

@app.route("/tips")
def pg_tips():       return render_template("tips.html")

@app.route("/contact")
def pg_contact():    return render_template("contact.html")

@app.route("/illness")
def pg_illness():    return render_template("illness.html")

@app.route("/admin-login")
def pg_admin_login():
    if session.get("admin"): return redirect("/admin")
    return render_template("admin_login.html")

@app.route("/admin")
def pg_admin():
    if not session.get("admin"): return redirect("/admin-login")
    return render_template("admin.html")

@app.route("/uploads/<path:fn>")
def uploads(fn): return send_from_directory(UPLOAD_FOLDER, fn)

# ═══════════════════════════════════════════════
# PUBLIC APIs
# ═══════════════════════════════════════════════
@app.route("/api/illness/<slug>")
def api_illness(slug):
    part = q("SELECT * FROM body_parts WHERE slug=%s", (slug,), one=True)
    if not part: return jsonify(success=False, message="Not found"), 404
    ills = q("SELECT * FROM illnesses WHERE body_part_id=%s AND is_active=1 ORDER BY id", (part["id"],))
    for ill in ills:
        ill["symptoms"]  = [r["text"] for r in q("SELECT text FROM symptoms  WHERE illness_id=%s ORDER BY sort_order", (ill["id"],))]
        ill["care_tips"] = [r["text"] for r in q("SELECT text FROM care_tips WHERE illness_id=%s ORDER BY sort_order", (ill["id"],))]
        ill["medicines"] = q("SELECT * FROM medicines WHERE illness_id=%s", (ill["id"],))
    docs = q("SELECT * FROM doctors WHERE body_part_id=%s AND is_active=1 ORDER BY experience_years DESC LIMIT 4", (part["id"],))
    return jsonify(success=True, data=dict(part=part, illnesses=ills, doctors=docs))

@app.route("/api/common-illnesses")
def api_common():
    rows = q("SELECT * FROM common_illnesses ORDER BY sort_order")
    for r in rows:
        r["symptoms"]  = [x["text"] for x in q("SELECT text FROM common_symptoms  WHERE illness_id=%s ORDER BY sort_order",(r["id"],))]
        r["care_tips"] = [x["text"] for x in q("SELECT text FROM common_care_tips WHERE illness_id=%s ORDER BY sort_order",(r["id"],))]
        r["medicines"] = q("SELECT * FROM common_medicines WHERE illness_id=%s",(r["id"],))
    return jsonify(success=True, data=rows)

@app.route("/api/health-tips")
def api_tips():
    rows = q("SELECT * FROM health_tips WHERE is_active=1 ORDER BY category, sort_order")
    grouped = {}
    for r in rows: grouped.setdefault(r["category"],[]).append(r)
    return jsonify(success=True, data=grouped)

@app.route("/api/contact", methods=["POST"])
def api_contact():
    d = request.get_json() or {}
    name,email,msg = d.get("name","").strip(),d.get("email","").strip(),d.get("message","").strip()
    if not all([name,email,msg]): return jsonify(success=False, message="All fields required")
    ex("INSERT INTO contact_messages(name,email,message) VALUES(%s,%s,%s)",(name,email,msg))
    return jsonify(success=True, message="Message sent!")

# ═══════════════════════════════════════════════
# ADMIN AUTH
# ═══════════════════════════════════════════════
@app.route("/admin/login", methods=["POST"])
def admin_login():
    d = request.get_json() or {}
    row = q("SELECT * FROM admin_users WHERE email=%s AND password=%s",(d.get("email",""),d.get("password","")),one=True)
    if row:
        session["admin"] = True
        session["admin_name"] = row["name"]
        return jsonify(success=True, name=row["name"])
    return jsonify(success=False, message="Invalid credentials")

@app.route("/admin/logout", methods=["POST"])
def admin_logout():
    session.clear()
    return jsonify(success=True)

@app.route("/admin/check")
def admin_check():
    if session.get("admin"): return jsonify(success=True, name=session.get("admin_name","Admin"))
    return jsonify(success=False)

@app.route("/admin/stats")
@admin_only
def admin_stats():
    return jsonify(success=True, data=dict(
        illnesses = q("SELECT COUNT(*) c FROM illnesses WHERE is_active=1",one=True)["c"],
        doctors   = q("SELECT COUNT(*) c FROM doctors   WHERE is_active=1",one=True)["c"],
        medicines = q("SELECT COUNT(*) c FROM medicines",one=True)["c"],
        messages  = q("SELECT COUNT(*) c FROM contact_messages WHERE is_read=0",one=True)["c"]
    ))

# ── Body parts dropdown ────────────────────────
@app.route("/admin/body-parts")
@admin_only
def admin_bparts():
    return jsonify(success=True, data=q("SELECT * FROM body_parts ORDER BY id"))

@app.route("/admin/illness-list")
@admin_only
def admin_ill_list():
    return jsonify(success=True, data=q("SELECT id,name FROM illnesses WHERE is_active=1 ORDER BY name"))

# ── Illnesses CRUD ─────────────────────────────
@app.route("/admin/illnesses")
@admin_only
def admin_list_ill():
    rows = q("SELECT i.*,bp.name part_name,bp.slug part_slug FROM illnesses i JOIN body_parts bp ON bp.id=i.body_part_id ORDER BY bp.id,i.name")
    return jsonify(success=True, data=rows)

@app.route("/admin/illness", methods=["POST"])
@admin_only
def admin_add_ill():
    d = request.get_json() or {}
    iid = ex("INSERT INTO illnesses(body_part_id,name,description,severity) VALUES(%s,%s,%s,%s)",
             (d["body_part_id"],d["name"],d["description"],d.get("severity","mild")))
    for i,s in enumerate(d.get("symptoms",[])):
        ex("INSERT INTO symptoms(illness_id,text,sort_order) VALUES(%s,%s,%s)",(iid,s,i))
    for i,c in enumerate(d.get("care_tips",[])):
        ex("INSERT INTO care_tips(illness_id,text,sort_order) VALUES(%s,%s,%s)",(iid,c,i))
    for m in d.get("medicines",[]):
        ex("INSERT INTO medicines(illness_id,name,description,dosage,side_effects,is_otc) VALUES(%s,%s,%s,%s,%s,%s)",
           (iid,m["name"],m.get("description",""),m.get("dosage",""),m.get("side_effects",""),m.get("is_otc",0)))
    return jsonify(success=True, id=iid, message="Illness added — users can now see it!")

@app.route("/admin/illness/<int:iid>", methods=["PUT"])
@admin_only
def admin_upd_ill(iid):
    d = request.get_json() or {}
    ex("UPDATE illnesses SET body_part_id=%s,name=%s,description=%s,severity=%s,is_active=%s WHERE id=%s",
       (d["body_part_id"],d["name"],d["description"],d.get("severity","mild"),d.get("is_active",1),iid))
    ex("DELETE FROM symptoms  WHERE illness_id=%s",(iid,))
    ex("DELETE FROM care_tips WHERE illness_id=%s",(iid,))
    for i,s in enumerate(d.get("symptoms",[])): ex("INSERT INTO symptoms(illness_id,text,sort_order) VALUES(%s,%s,%s)",(iid,s,i))
    for i,c in enumerate(d.get("care_tips",[])): ex("INSERT INTO care_tips(illness_id,text,sort_order) VALUES(%s,%s,%s)",(iid,c,i))
    return jsonify(success=True, message="Illness updated")

@app.route("/admin/illness/<int:iid>", methods=["DELETE"])
@admin_only
def admin_del_ill(iid):
    ex("DELETE FROM illnesses WHERE id=%s",(iid,))
    return jsonify(success=True, message="Deleted")

# ── Doctors CRUD ───────────────────────────────
@app.route("/admin/doctors")
@admin_only
def admin_list_doc():
    rows = q("SELECT d.*,bp.name part_name,bp.slug part_slug FROM doctors d LEFT JOIN body_parts bp ON bp.id=d.body_part_id ORDER BY d.name")
    return jsonify(success=True, data=rows)

@app.route("/admin/doctor", methods=["POST"])
@admin_only
def admin_add_doc():
    d = request.get_json() or {}
    did = ex("INSERT INTO doctors(body_part_id,name,specialization,hospital,phone,email,address,experience_years) VALUES(%s,%s,%s,%s,%s,%s,%s,%s)",
             (d.get("body_part_id"),d["name"],d["specialization"],d.get("hospital",""),d.get("phone",""),d.get("email",""),d.get("address",""),d.get("experience_years",0)))
    return jsonify(success=True, id=did, message="Doctor added — visible to users now!")

@app.route("/admin/doctor/<int:did>", methods=["PUT"])
@admin_only
def admin_upd_doc(did):
    d = request.get_json() or {}
    ex("UPDATE doctors SET body_part_id=%s,name=%s,specialization=%s,hospital=%s,phone=%s,email=%s,address=%s,experience_years=%s,is_active=%s WHERE id=%s",
       (d.get("body_part_id"),d["name"],d["specialization"],d.get("hospital",""),d.get("phone",""),d.get("email",""),d.get("address",""),d.get("experience_years",0),d.get("is_active",1),did))
    return jsonify(success=True, message="Doctor updated")

@app.route("/admin/doctor/<int:did>", methods=["DELETE"])
@admin_only
def admin_del_doc(did):
    ex("DELETE FROM doctors WHERE id=%s",(did,))
    return jsonify(success=True, message="Deleted")

# ── Medicines CRUD ─────────────────────────────
@app.route("/admin/medicines")
@admin_only
def admin_list_med():
    rows = q("SELECT m.*,i.name illness_name FROM medicines m JOIN illnesses i ON i.id=m.illness_id ORDER BY i.name,m.name")
    return jsonify(success=True, data=rows)

@app.route("/admin/medicine", methods=["POST"])
@admin_only
def admin_add_med():
    d = request.get_json() or {}
    mid = ex("INSERT INTO medicines(illness_id,name,description,dosage,side_effects,is_otc) VALUES(%s,%s,%s,%s,%s,%s)",
             (d["illness_id"],d["name"],d.get("description",""),d.get("dosage",""),d.get("side_effects",""),d.get("is_otc",0)))
    return jsonify(success=True, id=mid, message="Medicine added")

@app.route("/admin/medicine/<int:mid>", methods=["DELETE"])
@admin_only
def admin_del_med(mid):
    ex("DELETE FROM medicines WHERE id=%s",(mid,))
    return jsonify(success=True)

@app.route("/admin/medicine/upload/<int:mid>", methods=["POST"])
@admin_only
def admin_upload(mid):
    if "image" not in request.files: return jsonify(success=False, message="No file")
    f = request.files["image"]
    if f and "." in f.filename and f.filename.rsplit(".",1)[1].lower() in ALLOWED_EXT:
        fn = secure_filename(f"med_{mid}_{int(datetime.now().timestamp())}.{f.filename.rsplit('.',1)[1]}")
        f.save(os.path.join(UPLOAD_FOLDER, fn))
        ex("UPDATE medicines SET image_path=%s WHERE id=%s",(fn,mid))
        return jsonify(success=True, filename=fn)
    return jsonify(success=False, message="Invalid file")

# ── Messages ───────────────────────────────────
@app.route("/admin/messages")
@admin_only
def admin_msgs():
    return jsonify(success=True, data=q("SELECT * FROM contact_messages ORDER BY created_at DESC"))

@app.route("/admin/message/<int:mid>/read", methods=["POST"])
@admin_only
def admin_mark_read(mid):
    ex("UPDATE contact_messages SET is_read=1 WHERE id=%s",(mid,))
    return jsonify(success=True)

@app.route("/admin/message/<int:mid>", methods=["DELETE"])
@admin_only
def admin_del_msg(mid):
    ex("DELETE FROM contact_messages WHERE id=%s",(mid,))
    return jsonify(success=True)

# ── Health Tips CRUD ───────────────────────────
@app.route("/admin/tips")
@admin_only
def admin_list_tips():
    return jsonify(success=True, data=q("SELECT * FROM health_tips ORDER BY category,sort_order"))

@app.route("/admin/tip", methods=["POST"])
@admin_only
def admin_add_tip():
    d = request.get_json() or {}
    ex("INSERT INTO health_tips(category,title,description,icon,sort_order) VALUES(%s,%s,%s,%s,%s)",
       (d.get("category","home_care"),d["title"],d["description"],d.get("icon","💡"),d.get("sort_order",99)))
    return jsonify(success=True, message="Tip added")

@app.route("/admin/tip/<int:tid>", methods=["DELETE"])
@admin_only
def admin_del_tip(tid):
    ex("DELETE FROM health_tips WHERE id=%s",(tid,))
    return jsonify(success=True)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
