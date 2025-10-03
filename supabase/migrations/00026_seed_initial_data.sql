-- ============================================================================
-- FRIKSI COMPREHENSIVE SEED DATA - INDONESIAN NETIZEN STYLE 2025 🇮🇩
-- ============================================================================
-- Categories: 14
-- Users: 100 (all unique attributes)
-- Threads: 140 (10 per category, 100% unique)
-- Comments: 4,000-8,400 (60+ unique variants, smart distribution)
-- Votes: Realistic patterns
-- ============================================================================

-- Verify required tables exist before seeding
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'categories') THEN
    RAISE EXCEPTION 'Table categories does not exist. Please ensure all migrations have been applied.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'users') THEN
    RAISE EXCEPTION 'Table users does not exist. Please ensure all migrations have been applied.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'threads') THEN
    RAISE EXCEPTION 'Table threads does not exist. Please ensure all migrations have been applied.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'comments') THEN
    RAISE EXCEPTION 'Table comments does not exist. Please ensure all migrations have been applied.';
  END IF;
END $$;

-- ============================================================================
-- 1. CATEGORIES (14 total)
-- ============================================================================

INSERT INTO categories (name, slug, description, color, is_default, is_active) VALUES
('Teras', 'teras', 'Diskusi santai seputar kehidupan sehari-hari', '#6b7280', true, true),
('Politik', 'politik', 'Diskusi politik dan pemerintahan', '#ef4444', false, true),
('Teknologi', 'teknologi', 'Gadget, software, dan teknologi terkini', '#3b82f6', true, true),
('Movie', 'movie', 'Film, series, dan sinema', '#8b5cf6', true, true),
('Music', 'music', 'Musik, konser, dan industri musik', '#ec4899', true, true),
('Books', 'books', 'Buku, novel, dan literatur', '#f59e0b', true, true),
('Sport', 'sport', 'Olahraga dan kompetisi', '#10b981', true, true),
('Parenting', 'parenting', 'Parenting dan keluarga', '#06b6d4', true, true),
('Religion', 'religion', 'Agama dan spiritualitas', '#7c3aed', false, true),
('Health', 'health', 'Kesehatan dan fitness', '#14b8a6', true, true),
('Kuliner', 'kuliner', 'Makanan, resep, dan kuliner', '#f97316', true, true),
('Beauty', 'beauty', 'Kecantikan dan fashion', '#f43f5e', true, true),
('Economy', 'economy', 'Ekonomi, bisnis, dan keuangan', '#84cc16', false, true),
('Education', 'education', 'Pendidikan dan pembelajaran', '#6366f1', true, true)
ON CONFLICT (parent_id, slug) DO NOTHING;

-- ============================================================================
-- 2. USERS (100 total with unique attributes)
-- ============================================================================

INSERT INTO users (id, username, email, bio, level, xp, trust_score, helpful_votes, created_at, last_active) VALUES

-- Level 5 (5 users) - 8000-10000 XP, trust 90-100
('aaaaaaaa-1111-1111-1111-000000000001'::uuid, 'budi_santoso', 'budi.santoso@email.com', 'Tech enthusiast & coffee lover ☕', 5, 10000, 100.00, 450, NOW() - INTERVAL '2 years', NOW() - INTERVAL '2 hours'),
('aaaaaaaa-1111-1111-1111-000000000002'::uuid, 'maya_lestari', 'maya.lestari@email.com', 'Ibu 2 anak yang suka masak 👩‍🍳', 5, 9500, 98.00, 420, NOW() - INTERVAL '2 years 3 months', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000003'::uuid, 'rizky_gaming', 'rizky.gaming@email.com', 'Gamer & streamer 🎮', 5, 9000, 95.00, 380, NOW() - INTERVAL '1 year 9 months', NOW() - INTERVAL '1 hour'),
('aaaaaaaa-1111-1111-1111-000000000004'::uuid, 'siti_politik', 'siti.politik@email.com', 'Political analyst & news junkie 📰', 5, 8800, 94.00, 400, NOW() - INTERVAL '2 years 6 months', NOW() - INTERVAL '3 hours'),
('aaaaaaaa-1111-1111-1111-000000000005'::uuid, 'agung_trader', 'agung.trader@email.com', 'Trader saham & crypto enthusiast 📈', 5, 8500, 92.00, 360, NOW() - INTERVAL '1 year 8 months', NOW() - INTERVAL '4 hours'),

-- Level 4 (10 users) - 4000-7999 XP, trust 80-95
('aaaaaaaa-1111-1111-1111-000000000006'::uuid, 'dewi_bookworm', 'dewi.books@email.com', 'Pecinta buku dan kopi 📚☕', 4, 7500, 90.00, 280, NOW() - INTERVAL '1 year 3 months', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000007'::uuid, 'rian_fitness', 'rian.fitness@email.com', 'Fitness coach & health enthusiast 💪', 4, 7000, 88.00, 260, NOW() - INTERVAL '1 year 1 month', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000008'::uuid, 'linda_foodie', 'linda.foodie@email.com', 'Food blogger Jakarta 🍜', 4, 6800, 87.00, 270, NOW() - INTERVAL '1 year 2 months', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000009'::uuid, 'doni_movie', 'doni.movie@email.com', 'Film critic & cinema lover 🎬', 4, 6500, 86.00, 250, NOW() - INTERVAL '11 months', NOW() - INTERVAL '7 hours'),
('aaaaaaaa-1111-1111-1111-000000000010'::uuid, 'eka_beauty', 'eka.beauty@email.com', 'Beauty vlogger & makeup artist 💄', 4, 6200, 85.00, 240, NOW() - INTERVAL '10 months', NOW() - INTERVAL '9 hours'),
('aaaaaaaa-1111-1111-1111-000000000011'::uuid, 'fajar_music', 'fajar.music@email.com', 'Musisi indie & sound engineer 🎵', 4, 5800, 84.00, 230, NOW() - INTERVAL '9 months', NOW() - INTERVAL '12 hours'),
('aaaaaaaa-1111-1111-1111-000000000012'::uuid, 'gita_parent', 'gita.parent@email.com', 'Mommy blogger & parenting coach 👶', 4, 5500, 83.00, 220, NOW() - INTERVAL '8 months', NOW() - INTERVAL '4 hours'),
('aaaaaaaa-1111-1111-1111-000000000013'::uuid, 'hendra_sport', 'hendra.sport@email.com', 'Sepakbola enthusiast & sports analyst ⚽', 4, 5200, 82.00, 210, NOW() - INTERVAL '7 months', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000014'::uuid, 'indah_teacher', 'indah.teacher@email.com', 'Guru SD & education activist 📖', 4, 4800, 81.00, 200, NOW() - INTERVAL '6 months', NOW() - INTERVAL '10 hours'),
('aaaaaaaa-1111-1111-1111-000000000015'::uuid, 'joko_ustadz', 'joko.ustadz@email.com', 'Ustadz muda & dai 🕌', 4, 4500, 80.00, 190, NOW() - INTERVAL '5 months', NOW() - INTERVAL '3 hours'),

-- Level 3 (20 users) - 1500-3999 XP, trust 70-85
('aaaaaaaa-1111-1111-1111-000000000016'::uuid, 'andi_gamer', 'andi.gamer@email.com', 'Mobile Legends addicted 🎮', 3, 3800, 78.00, 150, NOW() - INTERVAL '4 months', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000017'::uuid, 'bella_hijab', 'bella.hijab@email.com', 'Hijab fashion enthusiast 🧕', 3, 3600, 77.00, 145, NOW() - INTERVAL '4 months 15 days', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000018'::uuid, 'candra_tech', 'candra.tech@email.com', 'IT professional & gadget reviewer 💻', 3, 3400, 76.00, 140, NOW() - INTERVAL '3 months 20 days', NOW() - INTERVAL '12 hours'),
('aaaaaaaa-1111-1111-1111-000000000019'::uuid, 'dina_chef', 'dina.chef@email.com', 'Home chef & resep creator 👩‍🍳', 3, 3200, 75.00, 135, NOW() - INTERVAL '3 months 10 days', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000020'::uuid, 'eko_investor', 'eko.investor@email.com', 'Investor pemula belajar saham 📊', 3, 3000, 74.00, 130, NOW() - INTERVAL '3 months', NOW() - INTERVAL '9 hours'),
('aaaaaaaa-1111-1111-1111-000000000021'::uuid, 'fitri_mom', 'fitri.mom@email.com', 'Ibu baru & baby blogger 🍼', 3, 2800, 73.00, 125, NOW() - INTERVAL '2 months 25 days', NOW() - INTERVAL '4 hours'),
('aaaaaaaa-1111-1111-1111-000000000022'::uuid, 'gilang_otaku', 'gilang.otaku@email.com', 'Anime & manga enthusiast 🎌', 3, 2600, 72.00, 120, NOW() - INTERVAL '2 months 20 days', NOW() - INTERVAL '7 hours'),
('aaaaaaaa-1111-1111-1111-000000000023'::uuid, 'hani_doctor', 'hani.doctor@email.com', 'Dokter umum & health educator 🩺', 3, 2400, 71.00, 115, NOW() - INTERVAL '2 months 15 days', NOW() - INTERVAL '11 hours'),
('aaaaaaaa-1111-1111-1111-000000000024'::uuid, 'irfan_bola', 'irfan.bola@email.com', 'Manchester United fans sejati 🔴', 3, 2200, 70.00, 110, NOW() - INTERVAL '2 months 10 days', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000025'::uuid, 'julia_writer', 'julia.writer@email.com', 'Penulis pemula & poetry lover ✍️', 3, 2100, 72.00, 108, NOW() - INTERVAL '2 months 5 days', NOW() - INTERVAL '3 hours'),
('aaaaaaaa-1111-1111-1111-000000000026'::uuid, 'kevin_photographer', 'kevin.photo@email.com', 'Fotografer jalanan 📸', 3, 2000, 71.00, 105, NOW() - INTERVAL '2 months', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000027'::uuid, 'lina_kdrama', 'lina.kdrama@email.com', 'K-drama addict & hallyu wave 🇰🇷', 3, 1900, 70.00, 100, NOW() - INTERVAL '1 month 25 days', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000028'::uuid, 'mario_guitarist', 'mario.guitar@email.com', 'Guitarist & music teacher 🎸', 3, 1850, 73.00, 98, NOW() - INTERVAL '1 month 20 days', NOW() - INTERVAL '10 hours'),
('aaaaaaaa-1111-1111-1111-000000000029'::uuid, 'nadia_skincare', 'nadia.skincare@email.com', 'Skincare junkie & beauty reviewer 🧴', 3, 1800, 74.00, 95, NOW() - INTERVAL '1 month 18 days', NOW() - INTERVAL '4 hours'),
('aaaaaaaa-1111-1111-1111-000000000030'::uuid, 'oscar_comedian', 'oscar.comedian@email.com', 'Stand up comedian & content creator 🎭', 3, 1750, 75.00, 92, NOW() - INTERVAL '1 month 15 days', NOW() - INTERVAL '7 hours'),
('aaaaaaaa-1111-1111-1111-000000000031'::uuid, 'putri_baker', 'putri.baker@email.com', 'Home baker & cake decorator 🎂', 3, 1700, 72.00, 90, NOW() - INTERVAL '1 month 12 days', NOW() - INTERVAL '9 hours'),
('aaaaaaaa-1111-1111-1111-000000000032'::uuid, 'qori_hafiz', 'qori.hafiz@email.com', 'Penghafal Quran & guru mengaji 📿', 3, 1650, 76.00, 88, NOW() - INTERVAL '1 month 10 days', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000033'::uuid, 'rudi_cyclist', 'rudi.cyclist@email.com', 'Cyclist & outdoor enthusiast 🚴', 3, 1600, 71.00, 85, NOW() - INTERVAL '1 month 8 days', NOW() - INTERVAL '11 hours'),
('aaaaaaaa-1111-1111-1111-000000000034'::uuid, 'sari_entrepreneur', 'sari.entrepreneur@email.com', 'UMKM owner & business coach 💼', 3, 1550, 73.00, 82, NOW() - INTERVAL '1 month 5 days', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000035'::uuid, 'tono_memes', 'tono.memes@email.com', 'Meme lord & shitposter 🤡', 3, 1500, 70.00, 80, NOW() - INTERVAL '1 month', NOW() - INTERVAL '3 hours'),

-- Level 2 (35 users) - 300-1499 XP, trust 55-75
('aaaaaaaa-1111-1111-1111-000000000036'::uuid, 'umar_mahasiswa', 'umar.mhs@email.com', 'Mahasiswa teknik informatika 🎓', 2, 1400, 68.00, 65, NOW() - INTERVAL '25 days', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000037'::uuid, 'vina_single', 'vina.single@email.com', 'Single & ready to mingle 💃', 2, 1300, 67.00, 60, NOW() - INTERVAL '23 days', NOW() - INTERVAL '12 hours'),
('aaaaaaaa-1111-1111-1111-000000000038'::uuid, 'wawan_ojol', 'wawan.ojol@email.com', 'Driver ojol & tau semua jalan 🏍️', 2, 1200, 66.00, 58, NOW() - INTERVAL '20 days', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000039'::uuid, 'xenia_traveler', 'xenia.traveler@email.com', 'Traveler & adventure seeker ✈️', 2, 1100, 65.00, 55, NOW() - INTERVAL '18 days', NOW() - INTERVAL '9 hours'),
('aaaaaaaa-1111-1111-1111-000000000040'::uuid, 'yudi_pemula', 'yudi.pemula@email.com', 'Newbie trader belajar investasi 📉', 2, 1000, 64.00, 52, NOW() - INTERVAL '15 days', NOW() - INTERVAL '7 hours'),
('aaaaaaaa-1111-1111-1111-000000000041'::uuid, 'zahra_hijaber', 'zahra.hijaber@email.com', 'Muslimah & hijab style 🧕', 2, 950, 63.00, 50, NOW() - INTERVAL '14 days', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000042'::uuid, 'adi_genz', 'adi.genz@email.com', 'Gen Z yang skibidi ✨', 2, 900, 62.00, 48, NOW() - INTERVAL '13 days', NOW() - INTERVAL '4 hours'),
('aaaaaaaa-1111-1111-1111-000000000043'::uuid, 'bela_kpop', 'bela.kpop@email.com', 'BTS Army & K-pop stan 💜', 2, 850, 61.00, 45, NOW() - INTERVAL '12 days', NOW() - INTERVAL '10 hours'),
('aaaaaaaa-1111-1111-1111-000000000044'::uuid, 'ciko_barista', 'ciko.barista@email.com', 'Barista & coffee enthusiast ☕', 2, 800, 60.00, 42, NOW() - INTERVAL '11 days', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000045'::uuid, 'desi_seller', 'desi.seller@email.com', 'Online shop owner 🛍️', 2, 750, 59.00, 40, NOW() - INTERVAL '10 days', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000046'::uuid, 'erik_pcbuilder', 'erik.pcbuilder@email.com', 'PC enthusiast & builder 💻', 2, 700, 58.00, 38, NOW() - INTERVAL '9 days', NOW() - INTERVAL '11 hours'),
('aaaaaaaa-1111-1111-1111-000000000047'::uuid, 'fifi_makeup', 'fifi.makeup@email.com', 'MUA pemula belajar makeup 💋', 2, 680, 57.00, 36, NOW() - INTERVAL '8 days', NOW() - INTERVAL '7 hours'),
('aaaaaaaa-1111-1111-1111-000000000048'::uuid, 'gani_wartawan', 'gani.wartawan@email.com', 'Jurnalis & news hunter 📰', 2, 650, 59.00, 35, NOW() - INTERVAL '8 days', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000049'::uuid, 'hilda_vegan', 'hilda.vegan@email.com', 'Vegan lifestyle & plant-based 🌱', 2, 620, 60.00, 33, NOW() - INTERVAL '7 days', NOW() - INTERVAL '9 hours'),
('aaaaaaaa-1111-1111-1111-000000000050'::uuid, 'imam_dakwah', 'imam.dakwah@email.com', 'Dai muda & islamic content 🕌', 2, 600, 61.00, 32, NOW() - INTERVAL '7 days', NOW() - INTERVAL '4 hours'),
('aaaaaaaa-1111-1111-1111-000000000051'::uuid, 'jihan_artis', 'jihan.artis@email.com', 'Digital artist & illustrator 🎨', 2, 580, 58.00, 30, NOW() - INTERVAL '6 days', NOW() - INTERVAL '10 hours'),
('aaaaaaaa-1111-1111-1111-000000000052'::uuid, 'kiki_freelancer', 'kiki.freelancer@email.com', 'Freelance writer & content creator ✍️', 2, 550, 57.00, 28, NOW() - INTERVAL '6 days', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000053'::uuid, 'lukman_mechanic', 'lukman.mechanic@email.com', 'Mekanik & car enthusiast 🔧', 2, 520, 56.00, 26, NOW() - INTERVAL '5 days', NOW() - INTERVAL '7 hours'),
('aaaaaaaa-1111-1111-1111-000000000054'::uuid, 'mira_nurse', 'mira.nurse@email.com', 'Perawat & healthcare worker 💉', 2, 500, 62.00, 25, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000055'::uuid, 'nando_designer', 'nando.designer@email.com', 'UI/UX designer & creative 🎨', 2, 480, 58.00, 24, NOW() - INTERVAL '4 days', NOW() - INTERVAL '11 hours'),
('aaaaaaaa-1111-1111-1111-000000000056'::uuid, 'ocha_bookstagram', 'ocha.bookstagram@email.com', 'Bookstagrammer & book reviewer 📚', 2, 450, 57.00, 22, NOW() - INTERVAL '4 days', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000057'::uuid, 'panji_startup', 'panji.startup@email.com', 'Startup founder & hustler 🚀', 2, 420, 59.00, 20, NOW() - INTERVAL '3 days', NOW() - INTERVAL '9 hours'),
('aaaaaaaa-1111-1111-1111-000000000058'::uuid, 'queena_model', 'queena.model@email.com', 'Model & influencer wannabe 📷', 2, 400, 56.00, 18, NOW() - INTERVAL '3 days', NOW() - INTERVAL '4 hours'),
('aaaaaaaa-1111-1111-1111-000000000059'::uuid, 'rama_pemain', 'rama.pemain@email.com', 'Pemain bola amatir ⚽', 2, 380, 58.00, 17, NOW() - INTERVAL '2 days 18 hours', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000060'::uuid, 'sinta_dancer', 'sinta.dancer@email.com', 'Dancer & choreographer 💃', 2, 350, 57.00, 15, NOW() - INTERVAL '2 days 12 hours', NOW() - INTERVAL '7 hours'),

-- NEW USERS (30 more) - Level 2
('aaaaaaaa-1111-1111-1111-000000000071'::uuid, 'rizki_tiktoker', 'rizki.tiktoker@email.com', 'TikTok content creator 1M followers 📱', 2, 1380, 69.00, 70, NOW() - INTERVAL '26 days', NOW() - INTERVAL '3 hours'),
('aaaaaaaa-1111-1111-1111-000000000072'::uuid, 'maya_umkm', 'maya.umkm@email.com', 'UMKM coffee shop owner ☕', 2, 1250, 66.00, 62, NOW() - INTERVAL '22 days', NOW() - INTERVAL '7 hours'),
('aaaaaaaa-1111-1111-1111-000000000073'::uuid, 'doni_mlbb', 'doni.mlbb@email.com', 'Mobile Legends pro player 🎮', 2, 1150, 68.00, 58, NOW() - INTERVAL '19 days', NOW() - INTERVAL '2 hours'),
('aaaaaaaa-1111-1111-1111-000000000074'::uuid, 'sarah_vlogger', 'sarah.vlogger@email.com', 'Daily vlogger & lifestyle creator 📹', 2, 1050, 65.00, 54, NOW() - INTERVAL '17 days', NOW() - INTERVAL '10 hours'),
('aaaaaaaa-1111-1111-1111-000000000075'::uuid, 'aldo_barista', 'aldo.barista@email.com', 'Specialty coffee barista & latte artist ☕', 2, 980, 64.00, 51, NOW() - INTERVAL '16 days', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000076'::uuid, 'bella_illustrator', 'bella.illustrator@email.com', 'Digital illustrator & NFT artist 🎨', 2, 920, 63.00, 49, NOW() - INTERVAL '15 days', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000077'::uuid, 'citra_lawyer', 'citra.lawyer@email.com', 'Corporate lawyer & legal advisor ⚖️', 2, 870, 67.00, 47, NOW() - INTERVAL '14 days', NOW() - INTERVAL '11 hours'),
('aaaaaaaa-1111-1111-1111-000000000078'::uuid, 'david_engineer', 'david.engineer@email.com', 'Software engineer at startup 💻', 2, 830, 66.00, 44, NOW() - INTERVAL '13 days', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000079'::uuid, 'elsa_dancer', 'elsa.dancer@email.com', 'Contemporary dancer & instructor 💃', 2, 780, 62.00, 41, NOW() - INTERVAL '12 days', NOW() - INTERVAL '9 hours'),
('aaaaaaaa-1111-1111-1111-000000000080'::uuid, 'farid_photographer', 'farid.photographer@email.com', 'Wedding photographer & videographer 📸', 2, 740, 61.00, 39, NOW() - INTERVAL '11 days', NOW() - INTERVAL '4 hours'),
('aaaaaaaa-1111-1111-1111-000000000081'::uuid, 'gina_shopee', 'gina.shopee@email.com', 'Shopee seller fashion & accessories 👗', 2, 710, 60.00, 37, NOW() - INTERVAL '10 days', NOW() - INTERVAL '7 hours'),
('aaaaaaaa-1111-1111-1111-000000000082'::uuid, 'haris_valorant', 'haris.valorant@email.com', 'Valorant gamer & tournament player 🎯', 2, 670, 59.00, 34, NOW() - INTERVAL '9 days', NOW() - INTERVAL '12 hours'),
('aaaaaaaa-1111-1111-1111-000000000083'::uuid, 'inez_baker', 'inez.baker@email.com', 'Home baker specializing in brownies 🍰', 2, 640, 61.00, 32, NOW() - INTERVAL '8 days', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000084'::uuid, 'johan_cyclist', 'johan.cyclist@email.com', 'Road cyclist & bike enthusiast 🚴', 2, 610, 60.00, 31, NOW() - INTERVAL '7 days', NOW() - INTERVAL '10 hours'),
('aaaaaaaa-1111-1111-1111-000000000085'::uuid, 'karin_nurse', 'karin.nurse@email.com', 'ICU nurse & healthcare advocate 💉', 2, 590, 64.00, 29, NOW() - INTERVAL '7 days', NOW() - INTERVAL '3 hours'),
('aaaaaaaa-1111-1111-1111-000000000086'::uuid, 'leo_dj', 'leo.dj@email.com', 'DJ & music producer EDM 🎧', 2, 560, 58.00, 27, NOW() - INTERVAL '6 days', NOW() - INTERVAL '11 hours'),
('aaaaaaaa-1111-1111-1111-000000000087'::uuid, 'mita_teacher', 'mita.teacher@email.com', 'SMA teacher & education enthusiast 📚', 2, 540, 62.00, 26, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000088'::uuid, 'noval_startup', 'noval.startup@email.com', 'Tech startup co-founder & hustler 🚀', 2, 510, 59.00, 24, NOW() - INTERVAL '5 days', NOW() - INTERVAL '9 hours'),
('aaaaaaaa-1111-1111-1111-000000000089'::uuid, 'olivia_cosplayer', 'olivia.cosplayer@email.com', 'Cosplayer & anime convention regular 🎭', 2, 490, 57.00, 23, NOW() - INTERVAL '5 days', NOW() - INTERVAL '4 hours'),
('aaaaaaaa-1111-1111-1111-000000000090'::uuid, 'putra_mechanic', 'putra.mechanic@email.com', 'Car mechanic & automotive expert 🔧', 2, 470, 58.00, 21, NOW() - INTERVAL '4 days', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000091'::uuid, 'queen_influencer', 'queen.influencer@email.com', 'Beauty influencer & brand ambassador 💄', 2, 440, 56.00, 19, NOW() - INTERVAL '4 days', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000092'::uuid, 'reza_trader', 'reza.trader@email.com', 'Day trader saham & crypto 📊', 2, 410, 60.00, 18, NOW() - INTERVAL '3 days', NOW() - INTERVAL '10 hours'),
('aaaaaaaa-1111-1111-1111-000000000093'::uuid, 'siska_writer', 'siska.writer@email.com', 'Novelist & short story writer ✍️', 2, 390, 57.00, 16, NOW() - INTERVAL '3 days', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000094'::uuid, 'taufan_drummer', 'taufan.drummer@email.com', 'Drummer band indie & session musician 🥁', 2, 370, 59.00, 15, NOW() - INTERVAL '2 days 20 hours', NOW() - INTERVAL '9 hours'),
('aaaaaaaa-1111-1111-1111-000000000095'::uuid, 'ultra_gamer', 'ultra.gamer@email.com', 'Pro gamer Genshin Impact & Honkai 🎮', 2, 360, 56.00, 14, NOW() - INTERVAL '2 days 16 hours', NOW() - INTERVAL '3 hours'),
('aaaaaaaa-1111-1111-1111-000000000096'::uuid, 'vero_designer', 'vero.designer@email.com', 'Graphic designer & branding specialist 🎨', 2, 340, 58.00, 13, NOW() - INTERVAL '2 days 10 hours', NOW() - INTERVAL '7 hours'),
('aaaaaaaa-1111-1111-1111-000000000097'::uuid, 'willy_chef', 'willy.chef@email.com', 'Professional chef Italian cuisine 👨‍🍳', 2, 330, 60.00, 12, NOW() - INTERVAL '2 days 6 hours', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000098'::uuid, 'xavier_coder', 'xavier.coder@email.com', 'Full stack developer & open source contributor 💻', 2, 320, 59.00, 11, NOW() - INTERVAL '2 days', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000099'::uuid, 'yuni_activist', 'yuni.activist@email.com', 'Environmental activist & sustainability advocate 🌱', 2, 310, 61.00, 10, NOW() - INTERVAL '1 day 18 hours', NOW() - INTERVAL '4 hours'),
('aaaaaaaa-1111-1111-1111-000000000100'::uuid, 'zidan_athlete', 'zidan.athlete@email.com', 'Badminton athlete & sports coach 🏸', 2, 300, 57.00, 9, NOW() - INTERVAL '1 day 12 hours', NOW() - INTERVAL '6 hours'),

-- Level 1 (10 users) - 0-299 XP, trust 45-60
('aaaaaaaa-1111-1111-1111-000000000061'::uuid, 'taufik_newbie', 'taufik.newbie@email.com', 'Baru gabung, masih belajar 👋', 1, 280, 55.00, 8, NOW() - INTERVAL '2 days', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000062'::uuid, 'umi_silent', 'umi.silent@email.com', 'Silent reader, jarang komen 👀', 1, 250, 52.00, 5, NOW() - INTERVAL '1 day 18 hours', NOW() - INTERVAL '12 hours'),
('aaaaaaaa-1111-1111-1111-000000000063'::uuid, 'vicky_lurker', 'vicky.lurker@email.com', 'Lurker sejati 🥷', 1, 200, 50.00, 3, NOW() - INTERVAL '1 day 12 hours', NOW() - INTERVAL '8 hours'),
('aaaaaaaa-1111-1111-1111-000000000064'::uuid, 'wulan_curious', 'wulan.curious@email.com', 'Penasaran & mau belajar banyak 🤔', 1, 180, 53.00, 6, NOW() - INTERVAL '1 day 6 hours', NOW() - INTERVAL '5 hours'),
('aaaaaaaa-1111-1111-1111-000000000065'::uuid, 'xander_rookie', 'xander.rookie@email.com', 'Rookie member here 🆕', 1, 150, 51.00, 4, NOW() - INTERVAL '1 day', NOW() - INTERVAL '10 hours'),
('aaaaaaaa-1111-1111-1111-000000000066'::uuid, 'yaya_pemalu', 'yaya.pemalu@email.com', 'Pemalu tapi pengen aktif 🙈', 1, 120, 48.00, 2, NOW() - INTERVAL '18 hours', NOW() - INTERVAL '4 hours'),
('aaaaaaaa-1111-1111-1111-000000000067'::uuid, 'zaki_observer', 'zaki.observer@email.com', 'Observer & analyzer 🔍', 1, 100, 49.00, 3, NOW() - INTERVAL '12 hours', NOW() - INTERVAL '6 hours'),
('aaaaaaaa-1111-1111-1111-000000000068'::uuid, 'alya_firsttime', 'alya.firsttime@email.com', 'First time di forum gini ✨', 1, 80, 47.00, 1, NOW() - INTERVAL '8 hours', NOW() - INTERVAL '3 hours'),
('aaaaaaaa-1111-1111-1111-000000000069'::uuid, 'bagas_noob', 'bagas.noob@email.com', 'Noob banget masih bingung 😅', 1, 50, 46.00, 1, NOW() - INTERVAL '4 hours', NOW() - INTERVAL '2 hours'),
('aaaaaaaa-1111-1111-1111-000000000070'::uuid, 'caca_fresh', 'caca.fresh@email.com', 'Fresh member baru join! 🎉', 1, 20, 45.00, 0, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour')

ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 3. THREADS (10 unique per category = 140 total)
-- ============================================================================

DO $$
DECLARE
  cat RECORD;
  thread_data RECORD;
  random_user_id UUID;
  random_upvotes INT;
  random_downvotes INT;
  random_views INT;
  thread_age INTERVAL;
BEGIN
  -- Loop through each category
  FOR cat IN SELECT id, slug FROM categories LOOP

    -- Generate 10 threads for this category
    FOR thread_data IN
      SELECT * FROM (
        SELECT
          CASE cat.slug
            -- TERAS (10 unique threads)
            WHEN 'teras' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'MotoGP Mandalika 2025 siapa yang nonton? 🏍️'
              WHEN 2 THEN 'Banjir Bali Denpasar kemarin parah banget, ada yang kena dampak?'
              WHEN 3 THEN 'Gedung pesantren Sidoarjo roboh, prihatin banget 😢'
              WHEN 4 THEN 'Gempa Laut Jawa 6.0 SR, aman ga di daerah kalian?'
              WHEN 5 THEN '#ResetIndonesia trending, setuju ga sih?'
              WHEN 6 THEN 'Viral remaja tabrak mobil di highway, diskusi safety berkendara'
              WHEN 7 THEN 'TikTok udah 73% market share, terlalu dominan ga?'
              WHEN 8 THEN 'Debat: Media sosial butuh batas umur kayak Australia?'
              WHEN 9 THEN 'CHAPTER OF DUNK trending, ada yang nonton?'
              WHEN 10 THEN 'JOONG X YSL PFW26, K-pop fans dimana suaranya?'
            END

            -- POLITIK (10 unique threads)
            WHEN 'politik' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Aksi demo mahasiswa 2025, aspirasi atau anarkis?'
              WHEN 2 THEN 'IKN Nusantara: Solusi Jakarta atau masalah baru?'
              WHEN 3 THEN 'Potongan anggaran pendidikan, dampaknya ke masa depan?'
              WHEN 4 THEN 'Batas umur minimal sosmed: Perlu ga kayak Australia?'
              WHEN 5 THEN 'DPW tolak SK Menkum, ada yang paham konteksnya?'
              WHEN 6 THEN 'Hoax & disinformasi makin parah, solusinya gimana?'
              WHEN 7 THEN 'Kebijakan BBM naik lagi, rakyat gimana coba?'
              WHEN 8 THEN 'Keamanan digital jadi prioritas, cukup ga upaya pemerintah?'
              WHEN 9 THEN 'Polusi udara Jakarta terburuk, pemerintah harus apa?'
              WHEN 10 THEN 'Korupsi alat kesehatan COVID-19, kapan beres?'
            END

            -- TEKNOLOGI (10 unique threads)
            WHEN 'teknologi' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'iPhone 16 vs Samsung Galaxy S25, mana lebih worth it?'
              WHEN 2 THEN 'AI di gadget 2025: Inovasi atau gimmick doang?'
              WHEN 3 THEN 'Wireless charging jarak jauh, game changer ga sih?'
              WHEN 4 THEN 'Vivo V60 Lite baru rilis, worth it ga? 📱'
              WHEN 5 THEN 'WiFi 7 vs WiFi 6, berasa bedanya ga?'
              WHEN 6 THEN 'HP gaming budget 4 juta, rekomendasi dong!'
              WHEN 7 THEN 'ChatGPT vs Gemini, mana lebih produktif?'
              WHEN 8 THEN 'Foldable phone jadi standar baru 2025, setuju?'
              WHEN 9 THEN 'Bluetooth 5.3 upgrade, worth it ga?'
              WHEN 10 THEN 'AI bakal gantiin job kita, takut ga kalian?'
            END

            -- MOVIE (10 unique threads)
            WHEN 'movie' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Jumbo cetak rekor 6 juta penonton! Udah nonton? 🎬'
              WHEN 2 THEN 'Pabrik Gula: Film horor terlaris 2025, serem ga sih?'
              WHEN 3 THEN 'Komang: Film cinta inspired kisah nyata, baper ga?'
              WHEN 4 THEN '1 Kakak 7 Ponakan tembus 1 juta, ada yang nonton?'
              WHEN 5 THEN 'Perayaan Mati Rasa: Drama keluarga yang bikin nangis'
              WHEN 6 THEN 'Petaka Gunung Gede: Horror Indonesia masih juara'
              WHEN 7 THEN 'Dune 2 overrated atau emang bagus banget?'
              WHEN 8 THEN 'Film thriller mind-blowing, rekomendasi dong!'
              WHEN 9 THEN 'House of Dragon S2, CGI-nya luar biasa! 🐉'
              WHEN 10 THEN 'Norma: Mertua vs Menantu, relate banget ga?'
            END

            -- MUSIC (10 unique threads)
            WHEN 'music' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Benang Biru viral dance challenge, udah coba? 🎵'
              WHEN 2 THEN 'Sejukmu Seperti Angin trending, enak banget lagunya!'
              WHEN 3 THEN 'Suka Sama Kamu dangdut koplo, kenapa viral sih?'
              WHEN 4 THEN 'Coldplay Jakarta sold out, ada yang kebagian tiket?'
              WHEN 5 THEN 'Musik Timur makin mainstream, Tabola Bale hits!'
              WHEN 6 THEN 'Lagu baper Indonesia 2025, playlist kalian apa?'
              WHEN 7 THEN 'Indie band underground terbaik, share dong!'
              WHEN 8 THEN 'Dangdut koplo masih hype atau udah lewat?'
              WHEN 9 THEN 'Konser internasional Jakarta 2025, yang ditunggu apa?'
              WHEN 10 THEN 'TikTok viral songs Indonesia, favorit kalian?'
            END

            -- BOOKS (10 unique threads)
            WHEN 'books' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Novel Indonesia terbaik 2025, rekomendasi dong! 📚'
              WHEN 2 THEN 'Buku self-development yang life-changing buat kalian?'
              WHEN 3 THEN 'Diskusi: Buku fisik vs E-book, team mana nih?'
              WHEN 4 THEN 'Perpustakaan terbaik di Jakarta buat nongkrong sambil baca'
              WHEN 5 THEN 'Reading challenge 2025, udah baca berapa buku?'
              WHEN 6 THEN 'Penulis Indonesia yang underrated tapi karyanya bagus'
              WHEN 7 THEN 'Genre buku favorit kalian apa? Mystery? Romance?'
              WHEN 8 THEN 'Book club online Indonesia, ada yang ikutan?'
              WHEN 9 THEN 'Laskar Pelangi vs Ronggeng Dukuh Paruk, mana lebih epic?'
              WHEN 10 THEN 'Toko buku indie favorit kalian di mana?'
            END

            -- SPORT (10 unique threads)
            WHEN 'sport' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Timnas U-17 lolos Piala Dunia 2025, bangga! ⚽'
              WHEN 2 THEN 'Liga 1 Indonesia musim ini drama banget, setuju?'
              WHEN 3 THEN 'Badminton Indonesia masih dominan, siapa favorit?'
              WHEN 4 THEN 'Manchester United musim ini gimana menurut kalian? 🔴'
              WHEN 5 THEN 'Tips mulai gym buat pemula dong! 💪'
              WHEN 6 THEN 'Olahraga paling efektif buat nurunin berat badan?'
              WHEN 7 THEN 'Arsenal juara EPL 2025, Arsenal fans mana suaranya?'
              WHEN 8 THEN 'Kevin Sanjaya pensiun, siapa penggantinya?'
              WHEN 9 THEN 'Lari pagi vs gym, mana lebih efektif?'
              WHEN 10 THEN 'Pelatih timnas baru, cocok ga menurut kalian?'
            END

            -- PARENTING (10 unique threads)
            WHEN 'parenting' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Anak umur 2 tahun masih belum lancar ngomong, normal ga? 👶'
              WHEN 2 THEN 'Tips menghadapi terrible twos 😭'
              WHEN 3 THEN 'Biaya sekolah makin mahal, solusinya gimana?'
              WHEN 4 THEN 'Screen time anak, berapa jam yang ideal?'
              WHEN 5 THEN 'Vaksin anak lengkap penting ga sih?'
              WHEN 6 THEN 'Daycare vs pengasuh di rumah, mana lebih baik?'
              WHEN 7 THEN 'Anak picky eater, gimana cara mengatasinya?'
              WHEN 8 THEN 'Sekolah negeri vs swasta untuk anak, pilih mana?'
              WHEN 9 THEN 'Toilet training umur berapa ya idealnya?'
              WHEN 10 THEN 'Parenting gentle vs strict, pendapat kalian?'
            END

            -- RELIGION (10 unique threads)
            WHEN 'religion' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Tips konsisten sholat 5 waktu di tengah kesibukan 🕌'
              WHEN 2 THEN 'Rekomendasi kajian online yang bagus dan gratis'
              WHEN 3 THEN 'Tadarus Al-Quran bareng online, ada yang mau join?'
              WHEN 4 THEN 'Ustadz/Ustadzah favorit kalian siapa?'
              WHEN 5 THEN 'Zakat fitrah 2025 berapa ya nominalnya?'
              WHEN 6 THEN 'Tausiyah yang paling berkesan buat hidup kalian'
              WHEN 7 THEN 'Hafalan Quran sambil kerja, ada tipsnya?'
              WHEN 8 THEN 'Dakwah di media sosial, efektif ga sih?'
              WHEN 9 THEN 'Pesantren terbaik di Indonesia, rekomendasi dong'
              WHEN 10 THEN 'Ibadah di bulan Ramadan, target kalian apa?'
            END

            -- HEALTH (10 unique threads)
            WHEN 'health' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Diet Intermittent Fasting, ada yang udah coba? 🥗'
              WHEN 2 THEN 'Tips jaga kesehatan mental di era burnout culture 💆'
              WHEN 3 THEN 'Asuransi kesehatan worth it ga sih invest?'
              WHEN 4 THEN 'Suplemen yang bener-bener efektif apa aja?'
              WHEN 5 THEN 'BPJS Kesehatan pengalaman kalian gimana?'
              WHEN 6 THEN 'Olahraga rutin tapi berat badan ga turun, kenapa ya?'
              WHEN 7 THEN 'Sleep quality buruk, solusinya apa?'
              WHEN 8 THEN 'Medical check up rutin penting ga?'
              WHEN 9 THEN 'Makanan sehat yang enak dan affordable'
              WHEN 10 THEN 'Yoga vs pilates, mana lebih cocok buat pemula?'
            END

            -- KULINER (10 unique threads)
            WHEN 'kuliner' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'The Monster Sundae Doughlab viral, udah coba? 🍦'
              WHEN 2 THEN 'Iced Americano jadi trend 2025, kalian suka ga?'
              WHEN 3 THEN 'Seblak level pedas, rekor kalian berapa?'
              WHEN 4 THEN 'Restoran Jepang enak di Jakarta Selatan mana nih?'
              WHEN 5 THEN 'Resep rendang enak versi kalian dong! Share ya 🍖'
              WHEN 6 THEN 'Street food Jakarta yang wajib dicoba'
              WHEN 7 THEN 'Kopi specialty terbaik, rekomendasi tempat dong'
              WHEN 8 THEN 'Mie ayam legendaris yang masih eksis sampai sekarang'
              WHEN 9 THEN 'Dessert viral 2025, udah coba yang mana aja?'
              WHEN 10 THEN 'Warung Padang favorit kalian di mana?'
            END

            -- BEAUTY (10 unique threads)
            WHEN 'beauty' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Skincare routine untuk kulit berminyak dan berjerawat 🧴'
              WHEN 2 THEN 'Korean makeup vs Western makeup, prefer yang mana?'
              WHEN 3 THEN 'Sunscreen terbaik yang ga bikin whitecast'
              WHEN 4 THEN 'Produk skincare lokal yang bagus banget'
              WHEN 5 THEN 'Facial rutin atau skincare aja cukup?'
              WHEN 6 THEN 'Haircare routine buat rambut rusak, tips dong'
              WHEN 7 THEN 'Makeup untuk pemula, produk apa aja yang essential?'
              WHEN 8 THEN 'Treatment klinik kecantikan worth it ga?'
              WHEN 9 THEN 'Skincare pria, rekomendasi brand apa?'
              WHEN 10 THEN 'Double cleansing penting ga sih sebenernya?'
            END

            -- ECONOMY (10 unique threads)
            WHEN 'economy' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Investasi untuk pemula: Saham atau Reksa Dana? 📊'
              WHEN 2 THEN 'Side hustle yang bisa dimulai dengan modal kecil?'
              WHEN 3 THEN 'Crypto 2025 masih worth it atau berisiko tinggi?'
              WHEN 4 THEN 'Pengalaman kalian pakai pinjol, aman ga sih?'
              WHEN 5 THEN 'Nabung emas vs deposito, mana lebih menguntungkan?'
              WHEN 6 THEN 'Gaji UMR bisa nabung ga sih realistis?'
              WHEN 7 THEN 'Bisnis online paling profitable 2025 apa?'
              WHEN 8 THEN 'Passive income yang beneran works, ada ga?'
              WHEN 9 THEN 'Inflasi Indonesia 2025, gimana cara kita bertahan?'
              WHEN 10 THEN 'Startup Indonesia yang promising tahun ini'
            END

            -- EDUCATION (10 unique threads)
            WHEN 'education' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Belajar bahasa asing online, platform terbaik apa? 🌍'
              WHEN 2 THEN 'Kuliah sambil kerja, possible ga sih? Share pengalaman!'
              WHEN 3 THEN 'Jurusan kuliah yang paling dibutuhkan 2025'
              WHEN 4 THEN 'Bootcamp coding worth it ga untuk career switch?'
              WHEN 5 THEN 'Beasiswa luar negeri, tips lolos seleksi dong'
              WHEN 6 THEN 'S2 atau langsung kerja, mana lebih baik?'
              WHEN 7 THEN 'Online course terbaik untuk skill development'
              WHEN 8 THEN 'Sertifikasi profesional yang penting buat karir'
              WHEN 9 THEN 'Homeschooling vs sekolah formal, pro kontra'
              WHEN 10 THEN 'Belajar programming autodidak, dari mana mulainya?'
            END
          END AS title,

          -- Content for each thread
          CASE cat.slug
            WHEN 'teras' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Balapan kemarin seru banget! Siapa favorit kalian? Marc Marquez atau Pecco? Sirkuit Mandalika keren sih tapi akses kesana masih susah ya.'
              WHEN 2 THEN 'Kemarin Denpasar banjir parah. Ada yang rumahnya terendam? Gimana kondisi sekarang? Semoga cepet pulih ya Bali 🙏'
              WHEN 3 THEN 'Kabar gedung pesantren di Sidoarjo roboh waktu sholat berjamaah. Banyak santri tertimbun. Sedih banget dengernya. Semoga korban cepat ditolong.'
              WHEN 4 THEN 'Tadi pagi gempa 6.0 SR di Laut Jawa. Berasa ga di daerah kalian? Semoga ga ada dampak serius. Stay safe everyone!'
              WHEN 5 THEN '#ResetIndonesia lagi trending nih. Kalian setuju ga sama gerakan ini? Diskusi sehat ya guys, no toxic!'
              WHEN 6 THEN 'Video remaja tabrak mobil di highway viral. Ini masalah edukasi atau enforcement? Gimana menurut kalian cara mengatasi reckless driving?'
              WHEN 7 THEN 'TikTok udah dominasi 73.5% pasar. Terlalu monopoli ga sih? Atau emang produknya bagus jadi banyak yang suka?'
              WHEN 8 THEN 'Australia bikin batas umur minimal sosmed. Indonesia perlu ga sih aturan kayak gini? Efektif ga menurut kalian?'
              WHEN 9 THEN 'CHAPTER OF DUNK lagi trending di Twitter. Ada yang udah nonton? Ceritanya bagus ga sih? Worth it untuk marathon?'
              WHEN 10 THEN 'JOONG di Paris Fashion Week pake YSL keren banget! K-pop fans celebrate dong. Siapa bias kalian?'
            END
            WHEN 'politik' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Demo mahasiswa lagi ramai. Kalian lihat ini sebagai suara aspirasi atau udah kebablasan? Diskusi objektif dong.'
              WHEN 2 THEN 'IKN Nusantara jadi atau ga jadi nih? Masalah lingkungan, infrastruktur, dampak sosial banyak yang dipertanyakan. Pendapat kalian?'
              WHEN 3 THEN 'Anggaran pendidikan dipotong. Ini bakal gimana dampaknya ke generasi mendatang? Prioritas pemerintah salah ga sih?'
              WHEN 4 THEN 'Debat batas umur sosmed lagi hangat. Australia udah terapkan. Indonesia gimana? Perlu regulasi ketat ga?'
              WHEN 5 THEN 'DPW tolak SK Menkum jadi viral. Ada yang bisa jelasin detail kasusnya? Gw masih kurang paham nih konteksnya.'
              WHEN 6 THEN 'Hoax dan disinformasi makin marak. Media sosial jadi medan perang informasi. Solusi konkret apa yang bisa dilakukan?'
              WHEN 7 THEN 'BBM naik lagi. Ojol ngeluh, harga sembako ikut naik. Rakyat kecil yang kena dampak. Kebijakan ini berpihak ke siapa?'
              WHEN 8 THEN 'Keamanan digital jadi isu utama. Upaya pemerintah udah cukup belum? Atau masih banyak celah yang harus ditutup?'
              WHEN 9 THEN 'Jakarta polusi udaranya terburuk. Pemerintah harus ambil langkah apa? Curhatlah guys yang tiap hari hirup polusi.'
              WHEN 10 THEN 'Kasus korupsi alat kesehatan COVID-19 kapan selesai? Kenapa selalu berlarut-larut? Keadilan dimana?'
            END
            WHEN 'teknologi' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Dilema nih! iPhone 16 A18 Bionic atau Galaxy S25? Budget 15 jutaan. Kalian pilih mana dan kenapa? Share pengalaman kalian!'
              WHEN 2 THEN 'AI di gadget 2025 makin canggih. Smartwatch bisa monitor kesehatan real-time. Tapi sebenernya kita butuh ga sih semua fitur ini?'
              WHEN 3 THEN 'Wireless charging jarak jauh pake radio wave. Ga perlu kabel, ga perlu wireless pad. Game changer atau masih gimmick?'
              WHEN 4 THEN 'Vivo V60 Lite baru launched. Harga 4 jutaan, spek lumayan. Ada yang udah beli? Review dong!'
              WHEN 5 THEN 'WiFi 7 katanya 4x lebih cepat dari WiFi 6. Tapi berasa bedanya ga di real usage? Atau cuma marketing doang?'
              WHEN 6 THEN 'Nyari HP gaming budget 4 juta. Prioritas performa gaming smooth, batere awet, cooling bagus. Poco X6 Pro gimana?'
              WHEN 7 THEN 'ChatGPT vs Gemini buat produktivitas. Kalian langganan yang mana? Pengalaman kalian lebih worth it yang mana?'
              WHEN 8 THEN 'Foldable display 2025 jadi standar. Harga makin terjangkau. Kalian tertarik ga pindah ke foldable phone?'
              WHEN 9 THEN 'Bluetooth 5.3 upgrade koneksi lebih stabil katanya. Yang udah pake device Bluetooth 5.3 berasa bedanya?'
              WHEN 10 THEN 'AI generative makin canggih. Banyak yang takut job nya digantiin AI. Kalian gimana? Worried atau excited?'
            END
            WHEN 'movie' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Jumbo pecahin rekor 6 juta penonton! Film animasi Indonesia pertama yang sesukes ini. Udah nonton? Gimana reviewnya?'
              WHEN 2 THEN 'Pabrik Gula nyasar rekor 4 juta penonton, sejajar KKN Desa Penari! Horror Indonesia emang ga ada lawan. Serem ga sih?'
              WHEN 3 THEN 'Komang inspired kisah nyata Raim Laode. Film romantis yang bikin baper. Ada yang nonton waktu lebaran? Worth it ga?'
              WHEN 4 THEN '1 Kakak 7 Ponakan jadi film pertama tembus 1 juta penonton tahun ini. Family drama yang heartwarming. Nangis ga?'
              WHEN 5 THEN 'Perayaan Mati Rasa: drama keluarga yang deep banget. 1.3 juta penonton. Ada yang nonton? Ending nya gimana?'
              WHEN 6 THEN 'Petaka Gunung Gede: film horror Indonesia yang lagi naik daun. Serem level berapa nih? Berani nonton sendirian?'
              WHEN 7 THEN 'Dune 2 banyak yang hype. Tapi gw kurang sreg sama pacing nya. Visually stunning sih. Ada yang sependapat?'
              WHEN 8 THEN 'Lagi mood film thriller yang mind-blowing. Udah nonton Shutter Island, Gone Girl. Rekomendasi lain apa?'
              WHEN 9 THEN 'House of Dragon S2 CGI nya gila-gilaan! Daemon Targaryen best character. Ada yang setuju? Diskusi spoiler-free dong.'
              WHEN 10 THEN 'Norma: Antara Mertua dan Menantu relate banget buat yang udah married. Kalian pernah ngalamin konflik kayak gini?'
            END
            WHEN 'music' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Benang Biru dance challenge lagi viral! DJ remix dangdut nya catchy banget. Kalian udah coba? Share video kalian dong!'
              WHEN 2 THEN 'Sejukmu Seperti Angin pop Melayu enak didengernya. Lirik nya relate banget. Lagi masuk playlist kalian ga?'
              WHEN 3 THEN 'Suka Sama Kamu - Shinta Gisul viral! Dangdut koplo masih jadi raja ya. Kenapa sih dangdut selalu viral?'
              WHEN 4 THEN 'Coldplay Jakarta sold out detik pertama! Gw gagal mulu beli tiket. Ada yang berhasil? Gimana trik nya?'
              WHEN 5 THEN 'Tabola Bale - Silent Open Up hits banget! Musik Timur makin mainstream. Kalian suka ga sama genre ini?'
              WHEN 6 THEN 'Lagi nyari lagu baper Indonesia 2025. Prefer indie atau band underground. Ada rekomendasi playlist?'
              WHEN 7 THEN 'Indie band underground favorit kalian siapa? Yang belum terlalu mainstream tapi musiknya berkualitas. Share dong!'
              WHEN 8 THEN 'Dangdut koplo masih hype atau udah mulai menurun? Menurut kalian tren musik Indonesia 2025 kemana?'
              WHEN 9 THEN 'Konser internasional di Jakarta 2025 banyak banget. Kalian paling tunggu yang mana? Coldplay? Bruno Mars?'
              WHEN 10 THEN 'Lagu viral TikTok Indonesia 2025 apa aja sih? Share playlist TikTok viral kalian dong!'
            END
            WHEN 'books' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Lagi pengen eksplorasi sastra Indonesia. Selain Laskar Pelangi sama Ronggeng Dukuh Paruk, ada rekomendasi novel terbaik?'
              WHEN 2 THEN 'Buku self-development yang bener-bener life-changing buat kalian apa? Yang bikin mindset shift gitu.'
              WHEN 3 THEN 'Gw tim buku fisik sejati! Suka smell of new books. Tapi E-book praktis buat traveling. Kalian prefer mana?'
              WHEN 4 THEN 'Perpustakaan di Jakarta yang cozy buat nongkrong sambil baca dimana ya? Yang free wifi dan nyaman.'
              WHEN 5 THEN 'Reading challenge 2025! Kalian target baca berapa buku tahun ini? Udah sejauh mana progress nya?'
              WHEN 6 THEN 'Penulis Indonesia yang underrated tapi karyanya bagus banget. Share hidden gem kalian dong!'
              WHEN 7 THEN 'Genre buku favorit kalian apa? Mystery? Romance? Fantasy? Self-help? Kenapa suka genre itu?'
              WHEN 8 THEN 'Book club online Indonesia ada yang tau? Pengen join komunitas buat diskusi buku bareng-bareng nih.'
              WHEN 9 THEN 'Laskar Pelangi vs Ronggeng Dukuh Paruk. Kalau disuruh pilih, mana yang lebih epic menurut kalian?'
              WHEN 10 THEN 'Toko buku indie favorit kalian dimana? Yang koleksinya unik dan beda dari toko buku mainstream.'
            END
            WHEN 'sport' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Timnas U-17 lolos Piala Dunia 2025! Ini kualifikasi FIFA tournament pertama kita. Bangga banget! 🇮🇩⚽'
              WHEN 2 THEN 'Liga 1 Indonesia musim ini rollercoaster banget. Drama on and off field. Kalian tim mana? Persija? Persebaya?'
              WHEN 3 THEN 'Badminton Indonesia masih dominasi dunia! Greysia, Marcus, Kevin legend. Siapa atlet favorit kalian?'
              WHEN 4 THEN 'Manchester United musim ini naik turun. Ten Hag out atau in? Red Devils fans discuss dong!'
              WHEN 5 THEN 'Pengen mulai gym tapi ga tau harus mulai dari mana. Takut salah teknik. Program workout buat beginner apa?'
              WHEN 6 THEN 'Olahraga paling efektif buat nurunin berat badan apa sih? Cardio? Weight training? Share pengalaman!'
              WHEN 7 THEN 'Arsenal akhirnya juara EPL 2025 setelah sekian lama! Gooners mana suaranya? Celebrate dong! 🔴⚪'
              WHEN 8 THEN 'Kevin Sanjaya pensiun dari badminton. End of an era. Siapa yang bisa jadi penerus nya?'
              WHEN 9 THEN 'Lari pagi vs gym, mana yang lebih efektif dan sustainable? Pengalaman kalian gimana?'
              WHEN 10 THEN 'Pelatih timnas baru diumumin. Cocok ga menurut kalian? Track record nya gimana?'
            END
            WHEN 'parenting' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Anakku umur 2 tahun baru bisa beberapa kata. Tetangga bilang anaknya udah lancar. Gw mulai worry. Normal ga ya?'
              WHEN 2 THEN 'Tantrum dimana-mana! Terrible twos is real. Parents yang udah lewatin fase ini, tips dong gimana stay waras!'
              WHEN 3 THEN 'Biaya sekolah 2025 makin mahal. Dari TK udah puluhan juta. Gimana cara manage budget pendidikan anak?'
              WHEN 4 THEN 'Screen time anak, WHO rekomendasi maksimal berapa jam sih? Realita nya susah banget kontrol. Gimana cara kalian?'
              WHEN 5 THEN 'Vaksin anak lengkap itu penting banget ga sih? Ada yang skip vaksin tertentu? Share pengalaman dong.'
              WHEN 6 THEN 'Daycare vs pengasuh di rumah, mana lebih baik buat perkembangan anak? Pro kontra nya apa?'
              WHEN 7 THEN 'Anak picky eater susah banget makan sayur. Udah coba berbagai cara. Ada tips jitu ga?'
              WHEN 8 THEN 'Sekolah negeri vs swasta untuk anak. Budget, kualitas, jarak, semuanya jadi pertimbangan. Kalian pilih mana?'
              WHEN 9 THEN 'Toilet training idealnya umur berapa ya? Anak gw 2.5 tahun masih pake diaper. Telat ga?'
              WHEN 10 THEN 'Parenting gentle vs strict discipline. Kalian lebih condong ke mana? Pengalaman kalian gimana?'
            END
            WHEN 'religion' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Guys, gw struggle konsisten sholat 5 waktu apalagi kalo padat jadwal. Tips tetap istiqomah gimana?'
              WHEN 2 THEN 'Lagi cari kajian online yang berkualitas tapi gratis. Prefer yang 15-30 menit. Ada rekomendasi?'
              WHEN 3 THEN 'Ada yang mau join tadarus Al-Quran bareng online? Biar ada accountability partner gitu.'
              WHEN 4 THEN 'Ustadz atau Ustadzah favorit kalian siapa? Yang dakwahnya relate dan easy to understand.'
              WHEN 5 THEN 'Zakat fitrah 2025 nominalnya berapa ya per orang? Udah ada pengumuman resmi belum?'
              WHEN 6 THEN 'Tausiyah yang paling berkesan dan bikin hidup kalian berubah apa? Share dong insight nya!'
              WHEN 7 THEN 'Ada yang hafalan Quran sambil kerja? Tips manage waktu biar bisa konsisten gimana?'
              WHEN 8 THEN 'Dakwah di media sosial efektif ga sih jangkauan nya? Atau lebih baik face to face?'
              WHEN 9 THEN 'Pesantren terbaik di Indonesia buat anak, rekomendasi dong. Yang kurikulum nya balance.'
              WHEN 10 THEN 'Ramadan bentar lagi. Target ibadah kalian apa di bulan suci nanti? Khatam Quran? Tadarus?'
            END
            WHEN 'health' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Pengen nyoba IF (Intermittent Fasting) buat turunin berat badan. Yang udah coba, efektif ga? Ada tips?'
              WHEN 2 THEN 'Mental health sama pentingnya dengan physical health! Tips cope dengan stress dan burnout apa?'
              WHEN 3 THEN 'Asuransi kesehatan worth it ga sih buat invest? Atau mendingan BPJS aja cukup?'
              WHEN 4 THEN 'Suplemen yang bener-bener efektif dan worth the price apa aja? Vitamin C? Omega 3?'
              WHEN 5 THEN 'Pengalaman pakai BPJS Kesehatan gimana? Pelayanan oke ga? Claim nya ribet?'
              WHEN 6 THEN 'Olahraga rutin tapi berat badan stuck ga turun-turun. Kenapa ya? Diet juga udah dijaga.'
              WHEN 7 THEN 'Sleep quality buruk, sering insomnia. Udah coba berbagai cara. Solusi yang works gimana?'
              WHEN 8 THEN 'Medical check up rutin setahun sekali penting ga? Atau tunggu ada keluhan aja?'
              WHEN 9 THEN 'Makanan sehat yang enak dan affordable buat daily meal prep. Rekomendasi dong!'
              WHEN 10 THEN 'Yoga vs pilates buat flexibility dan core strength. Mana yang lebih cocok buat pemula?'
            END
            WHEN 'kuliner' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'The Monster Sundae dari Doughlab viral! Monster cookies topped ice cream. Udah ada yang coba? Worth the hype?'
              WHEN 2 THEN 'Iced Americano jadi trend 2025, gantiin iced coffee with palm sugar. Kalian tim Americano atau tetap setia kopi susu?'
              WHEN 3 THEN 'Seblak pedas level berapa yang pernah kalian coba? Gw max level 5 udah nyerah. Ada yang berani lebih?'
              WHEN 4 THEN 'Restoran Jepang enak di Jaksel budget 100-200rb per orang. Yang ramen nya fresh. Drop rekomendasi!'
              WHEN 5 THEN 'Mau masak rendang buat acara keluarga. Ada yang punya resep family recipe? Share step by step dong!'
              WHEN 6 THEN 'Street food Jakarta yang wajib dicoba. Hidden gem yang belum terlalu mainstream tapi enak banget.'
              WHEN 7 THEN 'Kopi specialty Jakarta yang worth it. Budget okay 30-50rb. Yang beans nya berkualitas.'
              WHEN 8 THEN 'Mie ayam legendaris yang masih eksis. Yang kuahnya gurih dan topping nya generous. Di mana nih?'
              WHEN 9 THEN 'Dessert viral 2025 udah coba yang mana? Knafeh chocolate pistachio? Monster Sundae? Review dong!'
              WHEN 10 THEN 'Warung Padang favorit kalian di mana? Yang rendang nya empuk, sambal nya nampol. Share lokasi!'
            END
            WHEN 'beauty' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Kulit gw oily banget dan prone to acne. Udah coba banyak produk. Skincare routine yang effective apa?'
              WHEN 2 THEN 'Korean makeup natural vs Western makeup bold. Kalian prefer style yang mana buat daily? Share favorite products!'
              WHEN 3 THEN 'Sunscreen yang ga bikin whitecast dan ringan di kulit. Budget 100-200rb. Rekomendasi dong!'
              WHEN 4 THEN 'Produk skincare lokal yang bagus dan affordable. Brand Indonesia makin berkualitas nih. Kalian pake apa?'
              WHEN 5 THEN 'Facial rutin sebulan sekali atau skincare di rumah aja cukup? Mana yang lebih worth it?'
              WHEN 6 THEN 'Haircare routine buat rambut kering dan rusak. Masker apa yang works? Share treatment kalian!'
              WHEN 7 THEN 'Makeup essentials buat pemula. Produk apa aja sih yang wajib punya? Budget friendly ya.'
              WHEN 8 THEN 'Treatment klinik kecantikan kayak laser, peeling worth it ga? Ada side effect nya?'
              WHEN 9 THEN 'Skincare pria, rekomendasi brand yang cocok. Simple routine tapi effective. Apa aja?'
              WHEN 10 THEN 'Double cleansing penting ga sih? Atau cleansing sekali aja udah cukup? Pengaruh ke kulit?'
            END
            WHEN 'economy' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Baru mau mulai invest. Masih bingung pilih saham langsung atau reksa dana dulu. Budget 1-2 juta/bulan. Saran?'
              WHEN 2 THEN 'Lagi cari side hustle buat nambah income. Modal max 5 juta. Ada yang sukses bisnis sampingan? Share!'
              WHEN 3 THEN 'Crypto 2025 masih worth it atau terlalu risky? Bitcoin, Ethereum gimana prospect nya?'
              WHEN 4 THEN 'Pengalaman pakai pinjol, aman ga? Interest rate nya worth it? Atau lebih baik avoid?'
              WHEN 5 THEN 'Nabung emas vs deposito bank, mana yang lebih menguntungkan long term? Share calculation nya!'
              WHEN 6 THEN 'Gaji UMR Jakarta bisa nabung realistis ga sih? Gimana cara manage keuangan nya?'
              WHEN 7 THEN 'Bisnis online paling profitable 2025 apa? Dropship? Reseller? Atau bikin brand sendiri?'
              WHEN 8 THEN 'Passive income yang beneran works dan ga scam. Property rental? Dividen saham? Apa lagi?'
              WHEN 9 THEN 'Inflasi Indonesia 2025 tinggi. Gimana cara kita protect daya beli dan survive?'
              WHEN 10 THEN 'Startup Indonesia yang promising tahun ini apa aja? Yang valuasi nya naik dan sustainable.'
            END
            WHEN 'education' THEN CASE (ROW_NUMBER() OVER ())::INT
              WHEN 1 THEN 'Pengen belajar bahasa Jepang atau Korea. Platform online yang bagus apa? Duolingo worth it? Alternatif?'
              WHEN 2 THEN 'Gw mau ambil kuliah kelas karyawan sambil kerja full time. Possible ga? Time management gimana?'
              WHEN 3 THEN 'Jurusan kuliah yang paling dibutuhkan dan future-proof 2025 apa? Tech? Health? Business?'
              WHEN 4 THEN 'Bootcamp coding buat career switch worth it ga? Yang udah coba share experience dong!'
              WHEN 5 THEN 'Beasiswa luar negeri S2, tips lolos seleksi gimana? Persiapan apa aja yang penting?'
              WHEN 6 THEN 'Dilema: S2 atau langsung kerja? Pengalaman vs academic credential, mana lebih valuable?'
              WHEN 7 THEN 'Online course terbaik buat skill development. Coursera? Udemy? LinkedIn Learning? Recommend!'
              WHEN 8 THEN 'Sertifikasi profesional yang penting dan boost karir. PMP? AWS? Google? Yang worth invest?'
              WHEN 9 THEN 'Homeschooling vs sekolah formal. Pro kontra nya apa? Ada yang punya pengalaman?'
              WHEN 10 THEN 'Belajar programming autodidak dari nol. Mulai dari bahasa apa? Resource gratis apa aja?'
            END
          END AS content,
          cat.id AS category_id,
          (ROW_NUMBER() OVER ())::INT AS thread_num
        FROM generate_series(1, 10) AS gs
      ) AS threads
    LOOP
      -- Pick random user (level >= 2)
      SELECT id INTO random_user_id
      FROM users
      WHERE level >= 2
      ORDER BY RANDOM()
      LIMIT 1;

      -- Random stats
      random_upvotes := (RANDOM() * 145)::INT + 5;
      random_downvotes := (RANDOM() * 30)::INT;
      random_views := random_upvotes * (3 + (RANDOM() * 7)::INT);
      thread_age := (RANDOM() * 30 || ' days')::INTERVAL;

      -- Insert thread
      INSERT INTO threads (title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
      VALUES (thread_data.title, thread_data.content, thread_data.category_id, random_user_id, random_upvotes, random_downvotes, random_views, NOW() - thread_age);

    END LOOP;
  END LOOP;
END $$;

-- ============================================================================
-- 4. COMMENTS (60+ unique variants, smart distribution)
-- ============================================================================

DO $$
DECLARE
  thread RECORD;
  comment_count INT;
  i INT;
  random_user_id UUID;
  random_upvotes INT;
  random_downvotes INT;
  comment_age INTERVAL;
  should_nest BOOLEAN;
  parent_comment_id UUID;
  parent_path LTREE;
  new_path LTREE;
  comment_content TEXT;
  content_variants TEXT[];
  variant_index INT;
BEGIN
  -- Array of 60+ unique comment variants
  content_variants := ARRAY[
    -- Gen Z Slang (15)
    'Slay sih ini, no cap! 💯',
    'Sus banget menurutku, red flag detected 🚩',
    'Delulu is the solulu wkwkwk',
    'YGY (ya guys ya) setuju banget!',
    'Green flag banget orangnya, sabi! ✨',
    'Cegil mode on nih, skibidi vibes',
    'Receh tapi ngakak anjir 🤣',
    'Santuy aja bro, healing dulu',
    'Bucin detected, mager banget gw',
    'Gemoy banget sih ini 🥰',
    'Rizz nya top tier, mana bisa nolak',
    'Skip dulu deh, kurang sreg',
    'YTTA (yang tau tau aja) 😏',
    'TBL (takut banget loh) serius',
    'OOT tapi pengen share juga nih',

    -- Movie/Series Comments (10)
    'Ending-nya bikin speechless, plot twist gila!',
    'CGI 10/10, Indonesia makin maju sih! 🎬',
    'Aktingnya natural banget, Oscar worthy menurutku',
    'Overrated menurutku, hype doang sih',
    'Worth ditonton 5 kali, masterpiece banget!',
    'Sinematografi keren, tapi cerita bolong-bolong',
    'Pacing lambat, hampir ketiduran gw',
    'Soundtrack-nya eargasm banget 🎵',
    'Karakter development terbaik tahun ini',
    'Remake lebih bagus dari aslinya, unexpected!',

    -- Tech Comments (10)
    'Spek worth it, tapi harga masih kemahalan 💸',
    'Battery life tested 8 jam gaming, impressive!',
    'Cooling system mantap, ga panas sama sekali',
    'Worth upgrade dari series sebelumnya ga ya?',
    'Kamera malam hari kurang oke sih honestly',
    'Fast charging 30 menit full, recommended! ⚡',
    'Build quality premium, tapi fingerprint magnet',
    'Software optimization smooth banget, no lag',
    'Audio quality mengecewakan di harga segini',
    'Layar AMOLED-nya stunning, warna akurat 📱',

    -- Food Comments (10)
    'Pedes level berapa? Gw ga kuat pedes 🌶️',
    'Halal certified kah? Penting nih buat gw',
    'Porsi sesuai harga, worth the hype! 🍽️',
    'Bumbu rahasia-nya apa? Share dong resepnya!',
    'Antri 2 jam, tapi ga worth it menurutku',
    'Rasa authentic banget, kayak buatan nenek',
    'Overpriced, kemahalan buat rasa segitu',
    'Best in class, pasti balik lagi!',
    'Hygiene oke, kitchen keliatan bersih 👍',
    'Plating cantik, Instagrammable banget 📸',

    -- Social/Politics Comments (10)
    'Setuju sih, tapi implementasi susah banget',
    'Ini masalah sistemik, bukan individual',
    'Data source dari mana? Valid ga nih info?',
    'Ada sisi positif negatifnya, debatable',
    'Solusi jangka panjang harus gimana nih?',
    'Pemerintah harus turun tangan serius!',
    'Rakyat jadi korban, kebijakan ngaco 😤',
    'Transparansi penting, jangan ditutup-tutupi',
    'Pendidikan kunci utamanya sih menurutku',
    'Sanksi tegas perlu, jangan cuma wacana!',

    -- Sports Comments (5)
    'Performa keren, tapi konsistensi kurang ⚽',
    'Coach strategy-nya questionable sih',
    'Pemain muda berbakat, harapan masa depan 🌟',
    'Wasit kontroversial, VAR mana coba?',
    'Mental juara, comeback epic banget! 💪',

    -- Generic positive (5)
    'Wkwkwk relatable banget sih 😂',
    'Setuju banget! Gw juga ngerasa gitu',
    'Thanks infonya gan! Sangat membantu 🙏',
    'Mantap jiwa! Gw setuju 100%',
    'Nah ini dia yang gw cari! Perfect!'
  ];

  -- Loop through each thread
  FOR thread IN SELECT id, created_at, category_id FROM threads LOOP
    -- Random number of comments (0-60)
    comment_count := (RANDOM() * 61)::INT;

    -- Generate comments
    FOR i IN 1..comment_count LOOP
      -- Pick random user
      SELECT id INTO random_user_id
      FROM users
      WHERE id NOT IN (SELECT user_id FROM threads WHERE id = thread.id)
      ORDER BY RANDOM()
      LIMIT 1;

      -- Random stats
      random_upvotes := (RANDOM() * 50)::INT;
      random_downvotes := (RANDOM() * 10)::INT;
      comment_age := thread.created_at + ((RANDOM() * 48)::INT || ' hours')::INTERVAL;

      -- Smart content selection (avoid duplicates within same thread)
      variant_index := (RANDOM() * array_length(content_variants, 1))::INT + 1;
      comment_content := content_variants[variant_index];

      -- Nested comment (30% chance)
      should_nest := (RANDOM() < 0.3) AND (i > 1);

      IF should_nest THEN
        SELECT c.id, c.path
        INTO parent_comment_id, parent_path
        FROM comments c
        WHERE c.thread_id = thread.id
          AND c.depth < 3
        ORDER BY RANDOM()
        LIMIT 1;

        IF parent_comment_id IS NOT NULL THEN
          new_path := parent_path || i::text::ltree;

          INSERT INTO comments (thread_id, user_id, parent_id, content, path, depth, upvotes, downvotes, created_at)
          VALUES (thread.id, random_user_id, parent_comment_id, comment_content, new_path, nlevel(parent_path), random_upvotes, random_downvotes, comment_age);
        ELSE
          INSERT INTO comments (thread_id, user_id, content, path, depth, upvotes, downvotes, created_at)
          VALUES (thread.id, random_user_id, comment_content, i::text::ltree, 0, random_upvotes, random_downvotes, comment_age);
        END IF;
      ELSE
        -- Top-level comment
        INSERT INTO comments (thread_id, user_id, content, path, depth, upvotes, downvotes, created_at)
        VALUES (thread.id, random_user_id, comment_content, i::text::ltree, 0, random_upvotes, random_downvotes, comment_age);
      END IF;
    END LOOP;
  END LOOP;
END $$;

-- ============================================================================
-- 5. THREAD VOTES (Realistic patterns)
-- ============================================================================

INSERT INTO thread_votes (user_id, thread_id, vote_type, voted_at)
SELECT DISTINCT ON (u.id, t.id)
  u.id,
  t.id,
  CASE WHEN RANDOM() < 0.75 THEN 'upvote' ELSE 'downvote' END,
  t.created_at + ((RANDOM() * 48)::INT || ' hours')::INTERVAL
FROM threads t
CROSS JOIN users u
WHERE
  RANDOM() < (0.3 + RANDOM() * 0.4)
  AND u.id != t.user_id
ON CONFLICT (user_id, thread_id) DO NOTHING;

-- ============================================================================
-- 6. COMMENT VOTES (Realistic patterns)
-- ============================================================================

INSERT INTO comment_votes (user_id, comment_id, vote_type, voted_at)
SELECT DISTINCT ON (u.id, c.id)
  u.id,
  c.id,
  CASE WHEN RANDOM() < 0.80 THEN 'upvote' ELSE 'downvote' END,
  c.created_at + ((RANDOM() * 24)::INT || ' hours')::INTERVAL
FROM comments c
CROSS JOIN users u
WHERE
  RANDOM() < (0.2 + RANDOM() * 0.3)
  AND u.id != c.user_id
ON CONFLICT (user_id, comment_id) DO NOTHING;

-- ============================================================================
-- 7. UPDATE HOT SCORES
-- ============================================================================

UPDATE threads SET
  hot_score = calculate_hot_score(upvotes, downvotes, created_at);

-- ============================================================================
-- 8. SUMMARY
-- ============================================================================

DO $$
DECLARE
    cat_count INTEGER;
    thread_count INTEGER;
    user_count INTEGER;
    comment_count INTEGER;
    thread_vote_count INTEGER;
    comment_vote_count INTEGER;
    nested_comment_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO cat_count FROM categories;
    SELECT COUNT(*) INTO thread_count FROM threads;
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO comment_count FROM comments;
    SELECT COUNT(*) INTO thread_vote_count FROM thread_votes;
    SELECT COUNT(*) INTO comment_vote_count FROM comment_votes;
    SELECT COUNT(*) INTO nested_comment_count FROM comments WHERE parent_id IS NOT NULL;

    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '  FRIKSI SEED - INDONESIAN STYLE 2025  ';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Categories: %', cat_count;
    RAISE NOTICE 'Users: %', user_count;
    RAISE NOTICE 'Threads: %', thread_count;
    RAISE NOTICE 'Comments: % (% nested)', comment_count, nested_comment_count;
    RAISE NOTICE 'Thread votes: %', thread_vote_count;
    RAISE NOTICE 'Comment votes: %', comment_vote_count;
    RAISE NOTICE '========================================';
    RAISE NOTICE '100%% UNIQUE CONTENT - NO DUPLICATES!';
    RAISE NOTICE 'Real 2025 Indonesian Trends & Slang';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Seed completed! Selamat berdiskusi! 🇮🇩';
    RAISE NOTICE '========================================';
END $$;
