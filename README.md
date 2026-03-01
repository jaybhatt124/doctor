# AI Doctor Analysis — Flask + MySQL Website

A complete healthcare education website with:
- Interactive clickable body map (10 body parts)
- Common illnesses quick access (Fever, Cold, Cough, etc.)
- Separate HTML pages (index, about, tips, contact, illness, admin)
- Full admin panel with CRUD for illnesses & doctors
- Flask backend + MySQL database
- Admin additions instantly visible to users

---

## 📁 Project Structure

```
ai-doctor/
├── app.py                  ← Flask application (all routes + APIs)
├── schema.sql              ← MySQL database + full seed data
├── requirements.txt        ← Python packages
├── templates/
│   ├── index.html          ← Homepage with body map + common illnesses
│   ├── illness.html        ← Body part illness detail page
│   ├── about.html          ← About page
│   ├── tips.html           ← Health tips page
│   ├── contact.html        ← Contact form
│   ├── admin_login.html    ← Admin login page
│   └── admin.html          ← Admin dashboard (CRUD)
├── static/
│   ├── css/style.css       ← Complete stylesheet
│   └── js/shared.js        ← Shared JS utilities
└── uploads/                ← Medicine image uploads (auto-created)
```

---

## ⚙️ Setup Instructions

### Step 1 — Install Python packages
```bash
pip install -r requirements.txt
```

### Step 2 — Set your MySQL password in app.py
Open `app.py` and find this section (around line 20):
```python
DB = dict(
    host="localhost",
    user="root",
    password="",    ← PUT YOUR MYSQL PASSWORD HERE
    db="ai_doctor_db",
    ...
)
```

### Step 3 — Create the database
```bash
# Windows
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < schema.sql

# Mac / Linux
mysql -u root -p < schema.sql
```

Or use **MySQL Workbench**:
1. Open MySQL Workbench
2. File → Open SQL Script → select `schema.sql`
3. Press Ctrl+Shift+Enter to run

### Step 4 — Run the Flask server
```bash
python app.py
```

### Step 5 — Open the website
Open your browser and go to:
```
http://localhost:5000
```

---

## 🔐 Admin Panel

- **URL:** http://localhost:5000/admin-login
- **Email:** admin@gmail.com
- **Password:** admin123

### What admin can do:
- ✅ Add illness to any body part → instantly visible when users click that part
- ✅ Add doctor for any body part → appears on that body part's illness page
- ✅ Edit and delete illnesses and doctors
- ✅ View contact form messages
- ✅ Mark messages as read / delete them

---

## 🌐 Website Pages

| URL | Page |
|-----|------|
| `/` | Homepage with body map |
| `/illness?part=head` | Head illness info (works for all parts) |
| `/about` | About page |
| `/tips` | Health tips (loaded from database) |
| `/contact` | Contact form (saves to database) |
| `/admin-login` | Admin login |
| `/admin` | Admin dashboard |

### Body Part URLs
- `/illness?part=head`
- `/illness?part=neck`
- `/illness?part=shoulders`
- `/illness?part=chest`
- `/illness?part=stomach`
- `/illness?part=arms`
- `/illness?part=back`
- `/illness?part=knees`
- `/illness?part=legs`
- `/illness?part=feet`

---

## 🗄️ Database Tables

| Table | Description |
|-------|-------------|
| `admin_users` | Admin login credentials |
| `body_parts` | 10 body regions (head, neck, etc.) |
| `illnesses` | All illness records |
| `symptoms` | Symptoms linked to illnesses |
| `care_tips` | Care tips linked to illnesses |
| `medicines` | Medicines linked to illnesses |
| `doctors` | Doctors linked to body parts |
| `common_illnesses` | Common illnesses (Fever, Cold, etc.) |
| `common_symptoms` | Symptoms for common illnesses |
| `common_care_tips` | Care tips for common illnesses |
| `common_medicines` | Medicines for common illnesses |
| `health_tips` | Health tips by category |
| `contact_messages` | Contact form submissions |

---

## 🔌 API Endpoints

### Public
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/illness/<slug>` | Get illnesses + doctors for a body part |
| GET | `/api/common-illnesses` | Get all common illness data |
| GET | `/api/health-tips` | Get health tips grouped by category |
| POST | `/api/contact` | Submit contact form |

### Admin (session required)
| Method | URL | Description |
|--------|-----|-------------|
| POST | `/admin/login` | Login |
| POST | `/admin/logout` | Logout |
| GET | `/admin/stats` | Dashboard statistics |
| GET | `/admin/illnesses` | List all illnesses |
| POST | `/admin/illness` | Add illness |
| PUT | `/admin/illness/<id>` | Update illness |
| DELETE | `/admin/illness/<id>` | Delete illness |
| GET | `/admin/doctors` | List all doctors |
| POST | `/admin/doctor` | Add doctor |
| PUT | `/admin/doctor/<id>` | Update doctor |
| DELETE | `/admin/doctor/<id>` | Delete doctor |
| GET | `/admin/messages` | View messages |
| POST | `/admin/message/<id>/read` | Mark as read |
| DELETE | `/admin/message/<id>` | Delete message |

---

## ⚠️ Troubleshooting

**"Access denied for user root"**
→ Update the password in `DB = dict(...)` in `app.py`

**"Unknown database ai_doctor_db"**
→ Run `schema.sql` first (Step 3 above)

**"mysql is not recognized"**
→ Use the full path to mysql.exe or use MySQL Workbench

**Page shows "Could not connect to server"**
→ Make sure `python app.py` is running and visit http://localhost:5000

---

## ⚕️ Medical Disclaimer
This website is for **educational purposes only**. All information is general in nature and should not replace professional medical advice. Always consult a qualified doctor for health concerns.
