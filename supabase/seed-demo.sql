-- ============================================================
-- Leonid Studio : données de DÉMONSTRATION (personnes fictives)
-- À exécuter APRÈS schema.sql, dans SQL Editor → New query → Run.
-- Les dates sont calculées par rapport à aujourd'hui, pour que les
-- comptes à rebours d'abonnement restent réalistes.
-- Ré-exécutable : supprime d'abord les 5 adhérents de démo.
-- ============================================================

delete from public.members where email in (
  'david@example.com','daniel@example.com','noa@example.com','michal@example.com','yossi@example.com'
);

with m as (
  insert into public.members (full_name, full_name_ru, email, phone, address, birth_date, activation_code) values
    ('דוד כהן',     'Давид Коэн',    'david@example.com',  '050-000-0101', 'רחוב הרצל 10, קריית מלאכי',  current_date - interval '32 years' - interval '40 days',  'DAVID1'),
    ('דניאל לוי',   'Даниэль Леви',  'daniel@example.com', '050-000-0102', 'שדרות ירושלים 5, קריית מלאכי', current_date - interval '28 years' - interval '100 days', 'DANIEL'),
    ('נועה מזרחי',  'Ноа Мизрахи',   'noa@example.com',    '050-000-0103', 'רחוב הגפן 3, קריית מלאכי',    current_date - interval '26 years' - interval '12 days',  'NOA123'),
    ('מיכל אברהם',  'Михаль Авраам', 'michal@example.com', '050-000-0104', 'רחוב התאנה 8, קריית מלאכי',   current_date - interval '40 years' - interval '200 days', 'MICHAL'),
    ('יוסי פרץ',    'Йоси Перец',    'yossi@example.com',  '050-000-0105', 'רחוב הזית 21, קריית מלאכי',   current_date - interval '35 years' - interval '75 days',  'YOSSI1')
  returning id, email
),
subs as (
  insert into public.subscriptions (member_id, plan, start_date, end_date, price)
  select m.id, s.plan, current_date + s.start_off, current_date + s.end_off, s.price
  from m join (values
    ('david@example.com',  'monthly',   -4,  26, 150.00),
    ('daniel@example.com', 'monthly',  -27,   3, 150.00),
    ('noa@example.com',    'monthly',  -30,   0, 150.00),
    ('michal@example.com', 'quarterly',-97,  -7, 400.00),
    ('yossi@example.com',  'monthly',  -50, -20, 150.00)
  ) as s(email, plan, start_off, end_off, price) on s.email = m.email
  returning member_id
),
meas as (
  insert into public.measurements (member_id, measured_at, height_cm, weight_kg, fat_pct, muscle_kg, water_pct)
  select m.id, current_date + x.day_off, x.h, x.w, x.f, x.mu, x.wa
  from m join (values
    ('david@example.com',  -63, 178, 84.0, 21.0, 34.0, 54.0),
    ('david@example.com',  -33, 178, 83.0, 20.0, 34.5, 55.0),
    ('david@example.com',   -2, 178, 82.0, 19.0, 35.0, 55.0),
    ('daniel@example.com', -27, 180, 79.0, 18.0, 36.0, 57.0),
    ('noa@example.com',    -30, 165, 62.0, 25.0, 25.0, 52.0),
    ('michal@example.com', -36, 169, 68.0, 27.0, 26.0, 51.0),
    ('yossi@example.com',  -49, 174, 77.0, 23.0, 32.0, 54.0)
  ) as x(email, day_off, h, w, f, mu, wa) on x.email = m.email
  returning member_id
)
insert into public.payments (member_id, paid_at, amount, method, description, status, slate_no, slate_url, sent_at)
select m.id, current_date + p.day_off, p.amount, p.method, p.descr, p.status, p.slate_no, p.slate_url,
       case when p.status = 'sent' then current_date + p.day_off end
from m join (values
  ('david@example.com',  -34, 150.00, 'ביט',          'מנוי חודשי', 'sent',    '1001', 'https://www.slate.co.il/document-examples'),
  ('david@example.com',   -4, 150.00, 'מזומן',         'מנוי חודשי', 'sent',    '1004', 'https://www.slate.co.il/document-examples'),
  ('daniel@example.com', -27, 150.00, 'העברה בנקאית',  'מנוי חודשי', 'issued',  '1002', 'https://www.slate.co.il/document-examples'),
  ('noa@example.com',    -30, 150.00, 'מזומן',         'מנוי חודשי', 'toIssue', null,   null),
  ('michal@example.com', -97, 400.00, 'כרטיס',         'מנוי רבעוני','sent',    '1000', 'https://www.slate.co.il/document-examples')
) as p(email, day_off, amount, method, descr, status, slate_no, slate_url) on p.email = m.email;

-- Pour tester avec TON adresse e-mail à la place d'un adhérent fictif :
--   update public.members set email = 'ton.adresse@gmail.com' where email = 'david@example.com';
-- puis crée ton compte dans l'espace adhérent avec cette adresse et le code DAVID1.
