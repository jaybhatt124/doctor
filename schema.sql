-- ================================================================
--  AI Doctor Analysis — MySQL Schema + Full Seed Data
--  Run:  mysql -u root -p < schema.sql
-- ================================================================

CREATE DATABASE IF NOT EXISTS ai_doctor_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ai_doctor_db;

-- ── Drop all tables first (clean slate) ───────────────────────
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS common_medicines;
DROP TABLE IF EXISTS common_care_tips;
DROP TABLE IF EXISTS common_symptoms;
DROP TABLE IF EXISTS common_illnesses;
DROP TABLE IF EXISTS health_tips;
DROP TABLE IF EXISTS contact_messages;
DROP TABLE IF EXISTS medicines;
DROP TABLE IF EXISTS care_tips;
DROP TABLE IF EXISTS symptoms;
DROP TABLE IF EXISTS illnesses;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS body_parts;
DROP TABLE IF EXISTS admin_users;
SET FOREIGN_KEY_CHECKS = 1;

-- ── Admin Users ────────────────────────────────────────────────
CREATE TABLE admin_users (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  email      VARCHAR(255) NOT NULL UNIQUE,
  password   VARCHAR(255) NOT NULL,
  name       VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── Body Parts ─────────────────────────────────────────────────
CREATE TABLE body_parts (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  slug          VARCHAR(50)  NOT NULL UNIQUE,
  name          VARCHAR(100) NOT NULL,
  display_order INT DEFAULT 0
);

-- ── Illnesses ──────────────────────────────────────────────────
CREATE TABLE illnesses (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  body_part_id INT          NOT NULL,
  name         VARCHAR(200) NOT NULL,
  description  TEXT         NOT NULL,
  severity     ENUM('mild','moderate','severe') DEFAULT 'mild',
  is_active    TINYINT(1) DEFAULT 1,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (body_part_id) REFERENCES body_parts(id) ON DELETE CASCADE
);

CREATE TABLE symptoms (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  illness_id INT NOT NULL,
  text       VARCHAR(500) NOT NULL,
  sort_order INT DEFAULT 0,
  FOREIGN KEY (illness_id) REFERENCES illnesses(id) ON DELETE CASCADE
);

CREATE TABLE care_tips (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  illness_id INT NOT NULL,
  text       VARCHAR(500) NOT NULL,
  sort_order INT DEFAULT 0,
  FOREIGN KEY (illness_id) REFERENCES illnesses(id) ON DELETE CASCADE
);

-- ── Medicines ──────────────────────────────────────────────────
CREATE TABLE medicines (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  illness_id  INT          NOT NULL,
  name        VARCHAR(200) NOT NULL,
  description TEXT,
  dosage      VARCHAR(300),
  side_effects TEXT,
  image_path  VARCHAR(500),
  is_otc      TINYINT(1) DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (illness_id) REFERENCES illnesses(id) ON DELETE CASCADE
);

-- ── Doctors ────────────────────────────────────────────────────
CREATE TABLE doctors (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  body_part_id     INT,
  name             VARCHAR(200) NOT NULL,
  specialization   VARCHAR(200) NOT NULL,
  hospital         VARCHAR(300),
  phone            VARCHAR(50),
  email            VARCHAR(255),
  address          TEXT,
  experience_years INT DEFAULT 0,
  is_active        TINYINT(1) DEFAULT 1,
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (body_part_id) REFERENCES body_parts(id) ON DELETE SET NULL
);

-- ── Common Illnesses (Quick Access) ────────────────────────────
CREATE TABLE common_illnesses (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(200) NOT NULL,
  icon        VARCHAR(20)  DEFAULT '🏥',
  description TEXT,
  sort_order  INT DEFAULT 0
);

CREATE TABLE common_symptoms (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  illness_id INT NOT NULL,
  text       VARCHAR(500) NOT NULL,
  sort_order INT DEFAULT 0,
  FOREIGN KEY (illness_id) REFERENCES common_illnesses(id) ON DELETE CASCADE
);

CREATE TABLE common_care_tips (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  illness_id INT NOT NULL,
  text       VARCHAR(500) NOT NULL,
  sort_order INT DEFAULT 0,
  FOREIGN KEY (illness_id) REFERENCES common_illnesses(id) ON DELETE CASCADE
);

CREATE TABLE common_medicines (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  illness_id INT NOT NULL,
  name       VARCHAR(200) NOT NULL,
  info       VARCHAR(400),
  is_otc     TINYINT(1) DEFAULT 1,
  FOREIGN KEY (illness_id) REFERENCES common_illnesses(id) ON DELETE CASCADE
);

-- ── Health Tips ────────────────────────────────────────────────
CREATE TABLE health_tips (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  category    ENUM('home_care','medicine_safety','nutrition','fitness','mental_health') DEFAULT 'home_care',
  title       VARCHAR(300) NOT NULL,
  description TEXT         NOT NULL,
  icon        VARCHAR(20)  DEFAULT '💡',
  is_active   TINYINT(1)   DEFAULT 1,
  sort_order  INT          DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── Contact Messages ───────────────────────────────────────────
CREATE TABLE contact_messages (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(200) NOT NULL,
  email      VARCHAR(255) NOT NULL,
  message    TEXT         NOT NULL,
  is_read    TINYINT(1)   DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
--  SEED DATA
-- ================================================================

-- Admin (password: admin123)
INSERT INTO admin_users (email, password, name)
VALUES ('admin@gmail.com', 'admin123', 'Administrator');

-- Body Parts
INSERT INTO body_parts (slug, name, display_order) VALUES
('head','Head',1),('neck','Neck',2),('shoulders','Shoulders',3),
('chest','Chest',4),('stomach','Stomach',5),('arms','Arms',6),
('back','Back',7),('knees','Knees',8),('legs','Legs',9),('feet','Feet',10);

-- ── HEAD illnesses ────────────────────────────────────────────
INSERT INTO illnesses (body_part_id,name,description,severity) VALUES
(1,'Migraine','A neurological condition causing severe throbbing pain on one side of the head, often with nausea and sensitivity to light and sound.','moderate'),
(1,'Tension Headache','The most common headache — dull, aching pressure around the forehead or back of the head.','mild'),
(1,'Sinusitis','Inflammation of the sinus cavities causing facial pain, nasal congestion, and headache.','mild');

-- Migraine (id=1) symptoms & care
INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(1,'Severe throbbing pain on one side of head',1),(1,'Nausea and vomiting',2),
(1,'Sensitivity to light (photophobia)',3),(1,'Visual aura before attack',4),(1,'Dizziness and fatigue',5);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(1,'Rest in a dark, quiet room',1),(1,'Apply cold compress to forehead',2),
(1,'Stay well hydrated',3),(1,'Avoid known triggers (caffeine, alcohol, stress)',4),(1,'Maintain regular sleep schedule',5);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(1,'Sumatriptan','Triptan drug targeting migraine pain.','25–100mg at onset. Repeat after 2hr if needed.','Dizziness, nausea, chest tightness',0),
(1,'Ibuprofen','NSAID for mild migraines.','400–600mg with food at onset.','Stomach upset, heartburn',1);

-- Tension headache (id=2)
INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(2,'Dull constant aching pain',1),(2,'Pressure around forehead like a band',2),
(2,'Tenderness in scalp and neck',3),(2,'Pain behind the eyes',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(2,'Stay hydrated',1),(2,'Gentle neck and shoulder stretches',2),(2,'Reduce screen time',3),(2,'Practice deep breathing',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(2,'Paracetamol','First-line treatment for tension headaches.','500–1000mg every 4–6hrs. Max 4g/day.','Rare at correct doses',1);

-- Sinusitis (id=3)
INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(3,'Facial pain and pressure around nose/eyes',1),(3,'Nasal congestion',2),
(3,'Thick yellow or green nasal discharge',3),(3,'Reduced sense of smell',4),(3,'Low-grade fever',5);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(3,'Saline nasal rinse twice daily',1),(3,'Warm compress on face',2),(3,'Stay well hydrated',3),(3,'Sleep with head elevated',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(3,'Amoxicillin','Antibiotic for bacterial sinusitis — prescription only.','500mg three times daily for 7–10 days.','Nausea, diarrhea, allergic reactions',0);

-- ── NECK illnesses ────────────────────────────────────────────
INSERT INTO illnesses (body_part_id,name,description,severity) VALUES
(2,'Cervical Spondylosis','Age-related wear of neck vertebrae and discs causing chronic neck pain and stiffness.','moderate'),
(2,'Whiplash / Neck Strain','Muscle and ligament injury from sudden neck jerking, common in accidents.','mild');

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(4,'Chronic neck pain and stiffness',1),(4,'Headaches from the back of neck',2),(4,'Muscle spasm',3),
(4,'Numbness or tingling in arms',4),(4,'Grinding sensation when moving head',5);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(4,'Maintain good posture at desk',1),(4,'Use ergonomic pillow',2),(4,'Gentle neck rotation exercises',3),(4,'Apply heat for 15 min',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(4,'Naproxen','NSAID for neck pain and inflammation.','220mg twice daily with food.','Stomach upset, heartburn',1);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(5,'Neck pain and stiffness',1),(5,'Tenderness along neck muscles',2),(5,'Headache from base of skull',3),(5,'Reduced range of motion',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(5,'Ice pack first 48 hours then heat',1),(5,'Rest but avoid immobility',2),(5,'Gentle range-of-motion exercises',3);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(5,'Ibuprofen','Reduces neck inflammation.','400mg every 6–8hrs with food.','Stomach upset',1);

-- ── SHOULDERS illnesses ───────────────────────────────────────
INSERT INTO illnesses (body_part_id,name,description,severity) VALUES
(3,'Rotator Cuff Injury','Damage to shoulder cuff muscles from overuse or sports injury causing pain and weakness.','moderate'),
(3,'Frozen Shoulder','Progressive shoulder stiffness from joint capsule inflammation. Recovery takes 1–3 years.','moderate');

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(6,'Dull ache deep in the shoulder',1),(6,'Arm weakness',2),(6,'Difficulty reaching behind back',3),(6,'Disturbed sleep on affected side',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(6,'Rest from overhead activities',1),(6,'Ice then heat (20 min each)',2),(6,'Physical therapy exercises',3),(6,'Avoid sleeping on affected shoulder',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(6,'Naproxen','Long-acting NSAID for shoulder inflammation.','220–440mg every 8–12hrs with food.','Stomach upset',1);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(7,'Gradually increasing shoulder stiffness',1),(7,'Dull or aching pain',2),(7,'Pain worse at night',3),(7,'Severely limited range of motion',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(7,'Daily gentle stretching is essential',1),(7,'Physical therapy — key to recovery',2),(7,'Apply heat before stretching',3);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(7,'Ibuprofen','Reduces shoulder joint inflammation.','400–600mg with food.','Stomach upset',1);

-- ── CHEST illnesses ───────────────────────────────────────────
INSERT INTO illnesses (body_part_id,name,description,severity) VALUES
(4,'Costochondritis','Inflammation of rib cartilage causing chest wall pain that can mimic a heart attack.','mild'),
(4,'Acid Reflux (GERD)','Stomach acid flows back into the oesophagus causing burning chest pain.','moderate'),
(4,'Pneumonia','Lung infection causing air sacs to fill with fluid, causing cough, fever, and breathing difficulty.','severe');

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(8,'Sharp chest pain along breastbone',1),(8,'Tenderness when pressing on ribs',2),(8,'Pain worsens with deep breathing',3);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(8,'Rest from physical exertion',1),(8,'Apply ice or heat to chest',2),(8,'Avoid heavy lifting',3);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(8,'Ibuprofen','Reduces rib cartilage inflammation.','400mg with food every 8hrs.','Stomach upset',1);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(9,'Burning sensation in chest after meals',1),(9,'Sour or acid taste in mouth',2),(9,'Regurgitation of food',3),(9,'Chronic cough or hoarse voice',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(9,'Eat smaller more frequent meals',1),(9,'Do not lie down 3 hours after eating',2),(9,'Elevate head of bed',3),(9,'Avoid spicy and fatty foods',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(9,'Omeprazole','Proton pump inhibitor reducing stomach acid.','20–40mg once daily before breakfast.','Headache, diarrhea',1),
(9,'Antacids','Fast relief for heartburn.','1–2 tablets after meals.','Constipation, gas',1);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(10,'Cough with phlegm',1),(10,'Fever and chills',2),(10,'Shortness of breath',3),(10,'Chest pain when breathing',4),(10,'Fatigue and weakness',5);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(10,'Get plenty of rest',1),(10,'Stay well hydrated',2),(10,'Take prescribed antibiotics completely',3),(10,'Seek immediate care if breathing worsens',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(10,'Amoxicillin','Antibiotic for bacterial pneumonia — prescription.','500mg three times daily for 7–10 days.','Nausea, diarrhea',0);

-- ── STOMACH illnesses ─────────────────────────────────────────
INSERT INTO illnesses (body_part_id,name,description,severity) VALUES
(5,'Gastritis','Inflammation of stomach lining from H. pylori, NSAIDs, or alcohol.','moderate'),
(5,'Irritable Bowel Syndrome (IBS)','Chronic functional gut disorder causing pain, bloating, and altered bowel habits.','mild'),
(5,'Appendicitis','Inflammation of the appendix — a medical emergency requiring urgent surgery.','severe');

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(11,'Burning or gnawing stomach pain',1),(11,'Nausea and vomiting',2),(11,'Feeling bloated and full',3),(11,'Loss of appetite',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(11,'Eat smaller meals more frequently',1),(11,'Avoid spicy and acidic foods',2),(11,'Reduce alcohol and caffeine',3);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(11,'Omeprazole','Reduces stomach acid production.','20mg once daily before meals.','Headache, diarrhea',1);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(12,'Crampy abdominal pain',1),(12,'Bloating and excessive gas',2),(12,'Diarrhea or constipation',3),(12,'Urgency to use toilet',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(12,'Keep a food diary to find triggers',1),(12,'Eat regular smaller meals',2),(12,'Increase dietary fibre gradually',3),(12,'Regular moderate exercise',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(12,'Peppermint oil capsules','Reduces gut spasm naturally.','1–2 capsules before meals.','Heartburn, rarely',1);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(13,'Pain starting around navel moving to lower right',1),(13,'Nausea and vomiting',2),(13,'Loss of appetite',3),(13,'Fever',4),(13,'Abdominal tenderness',5);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(13,'SEEK EMERGENCY MEDICAL CARE IMMEDIATELY',1),(13,'Do not eat or drink anything',2),(13,'Do not apply heating pad',3),(13,'Hospitalisation and surgery required',4);

-- ── ARMS illnesses ────────────────────────────────────────────
INSERT INTO illnesses (body_part_id,name,description,severity) VALUES
(6,'Tennis Elbow (Lateral Epicondylitis)','Overuse injury causing tendon tears at outer elbow from repetitive arm movements.','mild'),
(6,'Carpal Tunnel Syndrome','Median nerve compression in the wrist causing hand numbness and weakness.','moderate');

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(14,'Pain on outer side of elbow',1),(14,'Weak grip strength',2),(14,'Pain when lifting objects',3),(14,'Forearm soreness',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(14,'Rest from activities causing pain',1),(14,'Ice the elbow 20 min several times daily',2),(14,'Use a tennis-elbow brace',3);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(14,'Ibuprofen Gel','Topical anti-inflammatory for elbow.','Apply 3–4 times daily to affected area.','Skin irritation',1);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(15,'Numbness in thumb and fingers',1),(15,'Hand weakness and clumsiness',2),(15,'Pain travelling up the forearm',3),(15,'Symptoms worse at night',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(15,'Wear a wrist splint at night',1),(15,'Take frequent breaks from typing',2),(15,'Ice the wrist for 15 minutes',3),(15,'Ergonomic keyboard and mouse setup',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(15,'Ibuprofen','Reduces nerve tunnel inflammation.','400mg with food every 6–8hrs.','Stomach upset',1);

-- ── BACK illnesses ────────────────────────────────────────────
INSERT INTO illnesses (body_part_id,name,description,severity) VALUES
(7,'Lower Back Pain','Pain in the lumbar region from muscle strain, poor posture, or disc problems — extremely common.','moderate'),
(7,'Herniated / Slipped Disc','Spinal disc gel-centre bulges out pressing on nerves causing intense radiating pain.','severe');

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(16,'Dull aching pain in lower back',1),(16,'Sharp pain on bending',2),(16,'Pain radiating down the leg',3),(16,'Limited flexibility',4),(16,'Stiffness after sitting',5);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(16,'Stay active — avoid long bed rest',1),(16,'Apply ice 48hrs then switch to heat',2),(16,'Core-strengthening exercises',3),(16,'Practice good sitting posture',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(16,'Paracetamol','Baseline pain control.','1000mg every 6hrs.','Rare at correct dose',1),
(16,'Diclofenac','Anti-inflammatory for back pain — prescription.','50mg twice daily with food.','Stomach upset',0);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(17,'Radiating pain down one leg (sciatica)',1),(17,'Numbness or tingling in leg',2),(17,'Muscle weakness in leg',3),(17,'Pain worsens with sitting or coughing',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(17,'Stay gently active — short walks',1),(17,'Physical therapy is essential',2),(17,'Ice and heat alternately',3),(17,'Avoid heavy lifting',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(17,'Meloxicam','Prescription NSAID for disc pain.','7.5–15mg once daily with food.','Stomach upset',0);

-- ── KNEES illnesses ───────────────────────────────────────────
INSERT INTO illnesses (body_part_id,name,description,severity) VALUES
(8,'Knee Osteoarthritis','Degenerative knee cartilage breakdown causing pain, swelling, and reduced mobility.','moderate'),
(8,'Knee Ligament Sprain','Overstretching or tearing of knee ligaments from sports or sudden twisting.','moderate');

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(18,'Knee pain during or after movement',1),(18,'Morning stiffness over 30 min',2),(18,'Swelling around the knee joint',3),(18,'Grating or crunching sensation',4),(18,'Reduced range of motion',5);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(18,'Maintain healthy body weight',1),(18,'Low-impact exercise — swimming, cycling',2),(18,'Physical therapy',3),(18,'Apply ice for swelling, heat for stiffness',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(18,'Naproxen','Long-acting NSAID for chronic knee pain.','220–440mg every 8–12hrs with food.','Stomach upset, cardiovascular risk long-term',1);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(19,'Immediate sharp knee pain',1),(19,'Swelling within a few hours',2),(19,'Bruising around the knee',3),(19,'Feeling of instability',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(19,'RICE: Rest, Ice, Compression, Elevation',1),(19,'Use crutches if weight-bearing is painful',2),(19,'Physiotherapy rehabilitation',3);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(19,'Ibuprofen','Reduces pain and swelling after knee injury.','400–600mg every 6–8hrs with food.','Stomach upset',1);

-- ── LEGS illnesses ────────────────────────────────────────────
INSERT INTO illnesses (body_part_id,name,description,severity) VALUES
(9,'Varicose Veins','Enlarged, twisted leg veins from faulty vein valves allowing blood to pool.','mild'),
(9,'Shin Splints','Pain along the inner shinbone from overloading lower leg muscles.','mild');

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(20,'Visible twisted dark-blue veins',1),(20,'Heavy, aching legs',2),(20,'Swelling of ankles by evening',3),(20,'Itching or burning around veins',4),(20,'Cramping in calves at night',5);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(20,'Exercise regularly',1),(20,'Avoid prolonged standing or sitting',2),(20,'Elevate legs when resting',3),(20,'Wear compression stockings',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(20,'Horse Chestnut Extract','Reduces varicose vein swelling.','300mg twice daily with meals.','Nausea, dizziness',1);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(21,'Dull aching pain along inner shin',1),(21,'Tenderness when pressing the shin',2),(21,'Mild swelling of lower leg',3),(21,'Pain during exercise',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(21,'Rest from high-impact activities 2–4 weeks',1),(21,'Apply ice after activity 15–20 min',2),(21,'Wear well-cushioned supportive footwear',3),(21,'Stretch calves before and after exercise',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(21,'Ibuprofen','Reduces shin inflammation.','400mg with food every 6–8hrs.','Stomach upset',1);

-- ── FEET illnesses ────────────────────────────────────────────
INSERT INTO illnesses (body_part_id,name,description,severity) VALUES
(10,'Plantar Fasciitis','Inflammation of the plantar fascia (band under the foot) — the most common cause of heel pain.','mild'),
(10,'Gout','Inflammatory arthritis from uric acid crystals in joints — usually the big toe. Sudden intense attacks.','severe');

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(22,'Sharp stabbing heel pain on first morning steps',1),(22,'Pain after long standing or walking',2),(22,'Stiffness in arch of foot',3),(22,'Tenderness along bottom of heel',4);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(22,'Stretch foot before getting out of bed',1),(22,'Wear supportive shoes with arch support',2),(22,'Use cushioned heel insoles',3),(22,'Ice the heel for 15 min after activity',4),(22,'Avoid barefoot walking on hard surfaces',5);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(22,'Ibuprofen','Reduces plantar fascia inflammation.','400–600mg with food three times daily.','Stomach upset',1);

INSERT INTO symptoms (illness_id,text,sort_order) VALUES
(23,'Sudden intense pain in big toe or foot joint',1),(23,'Extreme swelling and redness',2),(23,'Joint hot to touch',3),(23,'Pain severe even to light touch',4),(23,'Attack peaks within 12–24 hours',5);
INSERT INTO care_tips (illness_id,text,sort_order) VALUES
(23,'Drink 2–3 litres of water daily',1),(23,'Avoid alcohol especially beer',2),(23,'Limit red meat, organ meats, and seafood',3),(23,'Elevate the affected foot during attack',4);
INSERT INTO medicines (illness_id,name,description,dosage,side_effects,is_otc) VALUES
(23,'Colchicine','Specific anti-inflammatory for gout attacks — prescription.','0.6–1.2mg at onset, then 0.6mg after 1hr.','Nausea, vomiting, diarrhea',0),
(23,'Ibuprofen','High-dose for gout attack pain.','600–800mg at first sign with food.','Stomach upset',1);

-- ── DOCTORS ───────────────────────────────────────────────────
INSERT INTO doctors (body_part_id,name,specialization,hospital,phone,email,experience_years) VALUES
(1,'Dr. Sarah Johnson',   'Neurologist',          'City Medical Center',        '+1-555-0101','dr.johnson@citymed.com',    15),
(1,'Dr. Michael Chen',    'Headache Specialist',  'Neurology Associates',       '+1-555-0102','dr.chen@neuroassoc.com',    12),
(2,'Dr. Patricia Williams','Orthopedic Surgeon',  'Spine & Joint Center',       '+1-555-0201','dr.williams@spine.com',     18),
(3,'Dr. Daniel Garcia',   'Sports Orthopaedics',  'Sports Ortho Center',        '+1-555-1001','dr.garcia@sportsortho.com', 14),
(4,'Dr. Robert Martinez', 'Cardiologist',         'Heart & Vascular Institute', '+1-555-0301','dr.martinez@heartinst.com', 20),
(4,'Dr. Emily Davis',     'Pulmonologist',        'Respiratory Care Center',    '+1-555-0302','dr.davis@respcare.com',     10),
(5,'Dr. James Wilson',    'Gastroenterologist',   'Digestive Health Clinic',    '+1-555-0401','dr.wilson@digestive.com',   14),
(6,'Dr. Lisa Anderson',   'Sports Medicine',      'Athletic Health Center',     '+1-555-0501','dr.anderson@athletic.com',  9),
(7,'Dr. Nancy Thompson',  'Spine Specialist',     'Back & Spine Clinic',        '+1-555-0901','dr.thompson@spine.com',     17),
(8,'Dr. Thomas Brown',    'Rheumatologist',       'Arthritis & Joint Clinic',   '+1-555-0601','dr.brown@arthritis.com',    16),
(9,'Dr. Amanda Taylor',   'Vascular Surgeon',     'Vascular Care Institute',    '+1-555-0701','dr.taylor@vascular.com',    13),
(10,'Dr. Kevin Harris',   'Podiatrist',           'Foot & Ankle Specialists',   '+1-555-0801','dr.harris@footankle.com',   11);

-- ── COMMON ILLNESSES ──────────────────────────────────────────
INSERT INTO common_illnesses (name,icon,description,sort_order) VALUES
('Fever','🌡','A temporary rise in body temperature — the body''s natural defence against infection.',1),
('Common Cold','🤧','Viral upper respiratory infection most commonly caused by rhinoviruses. Resolves in 7–10 days.',2),
('Cough','😷','Reflex action to clear airways. Can be dry (no mucus) or productive (with mucus).',3),
('Stomach Pain','🫄','Abdominal pain from indigestion, gas, gastritis, or infections.',4),
('Headache','🤕','Pain anywhere in the head — from tension, dehydration, sinus issues, or poor posture.',5),
('Weakness / Fatigue','😔','Persistent tiredness from poor sleep, anaemia, infection, or nutritional deficiency.',6),
('Vomiting','🤢','Forceful expulsion of stomach contents from gastroenteritis, food poisoning, or motion sickness.',7),
('Diarrhoea','🚽','Frequent loose or watery stools from viral or bacterial infection, or food intolerance.',8);

-- Common Fever
INSERT INTO common_symptoms (illness_id,text,sort_order) VALUES
(1,'Body temperature above 38°C (100.4°F)',1),(1,'Chills and shivering',2),(1,'Sweating',3),(1,'Headache and muscle aches',4),(1,'Weakness and loss of appetite',5),(1,'Dehydration',6);
INSERT INTO common_care_tips (illness_id,text,sort_order) VALUES
(1,'Rest and avoid exertion',1),(1,'Drink plenty of fluids',2),(1,'Apply cool damp cloth to forehead',3),(1,'Wear light clothing',4),(1,'Seek doctor if above 39.5°C or lasting over 3 days',5);
INSERT INTO common_medicines (illness_id,name,info,is_otc) VALUES
(1,'Paracetamol','500–1000mg every 4–6 hours. Max 4g/day.',1),
(1,'Ibuprofen','400mg every 6–8 hours with food.',1);

-- Common Cold
INSERT INTO common_symptoms (illness_id,text,sort_order) VALUES
(2,'Runny or blocked nose',1),(2,'Sneezing',2),(2,'Sore throat',3),(2,'Mild headache',4),(2,'Low-grade fever',5),(2,'Body aches and tiredness',6);
INSERT INTO common_care_tips (illness_id,text,sort_order) VALUES
(2,'Get plenty of rest',1),(2,'Drink warm fluids — honey and lemon tea',2),(2,'Gargle warm salt water',3),(2,'Use saline nasal drops',4),(2,'Wash hands frequently',5);
INSERT INTO common_medicines (illness_id,name,info,is_otc) VALUES
(2,'Paracetamol','For fever and aches — 500–1000mg every 4–6 hours.',1),
(2,'Decongestant Spray','Xylometazoline — max 3 days use.',1);

-- Cough
INSERT INTO common_symptoms (illness_id,text,sort_order) VALUES
(3,'Persistent dry or wet cough',1),(3,'Tickling sensation in throat',2),(3,'Sore or scratchy throat',3),(3,'Chest tightness',4),(3,'Runny nose if due to cold',5);
INSERT INTO common_care_tips (illness_id,text,sort_order) VALUES
(3,'Drink warm fluids — honey, ginger tea',1),(3,'Avoid cold or dusty environments',2),(3,'Use a humidifier',3),(3,'Steam inhalation',4),(3,'Rest your voice',5);
INSERT INTO common_medicines (illness_id,name,info,is_otc) VALUES
(3,'Honey + Ginger','1 tbsp honey with ginger in warm water.',1),
(3,'Dextromethorphan syrup','Cough suppressant — follow label dosage.',1);

-- Stomach Pain
INSERT INTO common_symptoms (illness_id,text,sort_order) VALUES
(4,'Cramping or sharp abdominal pain',1),(4,'Bloating and fullness',2),(4,'Nausea with or without vomiting',3),(4,'Diarrhea or constipation',4),(4,'Heartburn or acid taste',5);
INSERT INTO common_care_tips (illness_id,text,sort_order) VALUES
(4,'Apply warm compress to stomach',1),(4,'Eat bland foods — toast, rice, bananas',2),(4,'Stay hydrated with small frequent sips',3),(4,'Avoid fatty and spicy food',4);
INSERT INTO common_medicines (illness_id,name,info,is_otc) VALUES
(4,'Antacids','Tums, Gaviscon — for acid-related pain.',1),
(4,'Buscopan (Hyoscine)','10–20mg for cramping and spasm.',1);

-- Headache
INSERT INTO common_symptoms (illness_id,text,sort_order) VALUES
(5,'Dull or throbbing pain in head',1),(5,'Pressure around forehead or temples',2),(5,'Pain at back of head or neck',3),(5,'Sensitivity to light or noise',4),(5,'Nausea in severe cases',5);
INSERT INTO common_care_tips (illness_id,text,sort_order) VALUES
(5,'Drink a full glass of water immediately',1),(5,'Rest in a quiet darkened room',2),(5,'Apply cold or warm compress',3),(5,'Gentle scalp massage',4),(5,'Correct your posture',5);
INSERT INTO common_medicines (illness_id,name,info,is_otc) VALUES
(5,'Paracetamol','500–1000mg at onset.',1),
(5,'Ibuprofen','400mg with food.',1);

-- Weakness/Fatigue
INSERT INTO common_symptoms (illness_id,text,sort_order) VALUES
(6,'Persistent tiredness despite rest',1),(6,'Lack of energy or motivation',2),(6,'Muscle weakness',3),(6,'Difficulty concentrating',4),(6,'Dizziness on standing',5),(6,'Pale skin',6);
INSERT INTO common_care_tips (illness_id,text,sort_order) VALUES
(6,'Prioritise 7–9 hours of quality sleep',1),(6,'Eat iron-rich foods — spinach, lentils',2),(6,'Stay hydrated throughout the day',3),(6,'Light exercise improves energy levels',4);
INSERT INTO common_medicines (illness_id,name,info,is_otc) VALUES
(6,'Iron Supplements','Ferrous sulphate 200mg once daily if iron-deficient.',1),
(6,'Vitamin B12 / Multivitamin','Daily supplement if diet is deficient.',1);

-- Vomiting
INSERT INTO common_symptoms (illness_id,text,sort_order) VALUES
(7,'Nausea before vomiting',1),(7,'Repeated vomiting episodes',2),(7,'Stomach cramps',3),(7,'Sweating and pale skin',4),(7,'Dizziness and weakness',5);
INSERT INTO common_care_tips (illness_id,text,sort_order) VALUES
(7,'Stop eating solid food temporarily',1),(7,'Sip small amounts of clear fluids',2),(7,'Try ginger tea for nausea',3),(7,'Rest with head elevated',4),(7,'Seek help if vomiting blood or lasting over 24hrs',5);
INSERT INTO common_medicines (illness_id,name,info,is_otc) VALUES
(7,'ORS (Oral Rehydration Salts)','Dissolve sachet in water — prevents dehydration.',1),
(7,'Domperidone','10mg before meals — antiemetic. Prescription needed.',0);

-- Diarrhoea
INSERT INTO common_symptoms (illness_id,text,sort_order) VALUES
(8,'Frequent watery or loose stools',1),(8,'Abdominal cramping and pain',2),(8,'Urgency to use toilet',3),(8,'Nausea or vomiting',4),(8,'Dehydration signs — dry mouth, dark urine',5);
INSERT INTO common_care_tips (illness_id,text,sort_order) VALUES
(8,'Drink ORS solution regularly',1),(8,'Eat plain foods — rice, toast, bananas',2),(8,'Avoid dairy and fatty food',3),(8,'Wash hands thoroughly after toilet',4),(8,'Seek help if lasting over 48hrs or blood in stool',5);
INSERT INTO common_medicines (illness_id,name,info,is_otc) VALUES
(8,'ORS (Oral Rehydration Salts)','Most important — prevents dangerous dehydration.',1),
(8,'Loperamide','2mg after each loose stool — max 8mg/day.',1);

-- ── HEALTH TIPS ───────────────────────────────────────────────
INSERT INTO health_tips (category,title,description,icon,sort_order) VALUES
('home_care','Stay Hydrated Daily','Drink at least 8 glasses (2 litres) of water per day. Supports organ function, skin health, digestion, and flushes toxins.','💧',1),
('home_care','Exercise Regularly','30 minutes of moderate exercise 5 days a week reduces chronic disease risk and improves mental health.','🏃',2),
('home_care','Prioritise Quality Sleep','Adults need 7–9 hours nightly. Good sleep improves immunity, mental clarity, mood, and metabolism.','😴',3),
('home_care','Maintain a Balanced Diet','Eat a rainbow of fruits, vegetables, whole grains, lean proteins, and healthy fats. Limit processed foods.','🥗',4),
('home_care','Practice Good Posture','Proper posture prevents back pain, neck strain, and affects breathing and digestion.','🧘',5),
('home_care','Manage Stress Effectively','Mindfulness, meditation, deep breathing, or yoga reduces chronic stress and strengthens immunity.','🧠',6),
('medicine_safety','Never Self-Medicate','Always consult a professional before starting medication. Self-medication leads to dangerous interactions.','⚕️',1),
('medicine_safety','Follow Dosage Instructions','Take exactly the prescribed dose. Never double dose. Complete the full antibiotic course.','📋',2),
('medicine_safety','Check Expiry Dates','Expired medicines can be ineffective or harmful. Always check dates before taking.','📅',3),
('medicine_safety','Store Medicines Safely','Cool, dry places away from sunlight. Out of reach of children. Some require refrigeration.','🏠',4),
('medicine_safety','Know Your Allergies','Keep an allergy list and share with all healthcare providers. Use medical alert bracelet for severe allergies.','⚠️',5),
('medicine_safety','Never Share Prescriptions','Prescription drugs are personalised. Sharing is dangerous and illegal.','🚫',6),
('nutrition','Reduce Processed Foods','Excessive sodium, unhealthy fats, and additives cause chronic disease. Cook fresh whenever possible.','🥦',1),
('nutrition','Eat Antioxidant-Rich Foods','Berries, leafy greens, nuts fight oxidative stress and reduce cancer and heart disease risk.','🫐',2),
('fitness','Stretch Every Morning','10 minutes of morning stretching improves flexibility, reduces injury risk, and boosts circulation.','🤸',1),
('fitness','Walk 10,000 Steps Daily','Walking linked to reduced risk of heart disease, diabetes, and depression.','🚶',2),
('mental_health','Limit Screen Time','Avoid screens 1 hour before bedtime. Take regular digital breaks for better sleep and mood.','📱',1),
('mental_health','Maintain Social Connections','Strong social connections linked to better health, longer life, and lower depression rates.','👥',2);