-- Menghapus view jika sudah ada sebelumnya agar tidak error saat di-run ulang
DROP VIEW IF EXISTS master_credit_risk_view;

-- Membuat Master View baru
CREATE VIEW master_credit_risk_view AS
WITH BureauSummary AS (
    -- 1. Merangkum riwayat kredit di institusi lain
    SELECT 
        sk_id_curr,
        COUNT(sk_id_bureau) AS total_bureau_loans,
        SUM(CASE WHEN credit_active = 'Active' THEN 1 ELSE 0 END) AS total_active_bureau_loans,
        ROUND(AVG(days_credit), 0) AS avg_days_credit_bureau 
    FROM bureau
    GROUP BY sk_id_curr
),
PrevAppSummary AS (
    -- 2. Merangkum riwayat pengajuan di institusi kita sendiri (berdasarkan query-mu sebelumnya)
    SELECT 
        sk_id_curr,
        COUNT(sk_id_prev) AS total_prev_apps,
        SUM(CASE WHEN name_contract_status = 'Refused' THEN 1 ELSE 0 END) AS total_refused_apps
    FROM previous_application
    GROUP BY sk_id_curr
)
-- 3. Menggabungkan semuanya dengan tabel utama
SELECT 
    a.sk_id_curr,
    a.target AS is_default,
    a.code_gender,
    a.flag_own_car,
    a.flag_own_realty,
    a.cnt_children,
    a.amt_income_total,
    a.amt_credit,
    a.name_education_type,
    a.name_family_status,
    -- Mengubah format hari (negatif) menjadi umur dalam hitungan tahun (positif)
    ROUND(ABS(a.days_birth) / 365.0, 0) AS age_years,
    ROUND(ABS(a.days_employed) / 365.0, 0) AS years_employed,
    
    -- Mengambil fitur agregasi dari Bureau (COALESCE mengubah nilai NULL menjadi 0)
    COALESCE(b.total_bureau_loans, 0) AS total_bureau_loans,
    COALESCE(b.total_active_bureau_loans, 0) AS total_active_bureau_loans,
    COALESCE(b.avg_days_credit_bureau, 0) AS avg_days_credit_bureau,
    
    -- Mengambil fitur agregasi dari Previous Application
    COALESCE(p.total_prev_apps, 0) AS total_prev_apps,
    COALESCE(p.total_refused_apps, 0) AS total_refused_apps
FROM application_train a
LEFT JOIN BureauSummary b ON a.sk_id_curr = b.sk_id_curr
LEFT JOIN PrevAppSummary p ON a.sk_id_curr = p.sk_id_curr;