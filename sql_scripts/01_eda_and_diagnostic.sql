-- 1. Analisis Persentase Gagal Bayar (Default Rate) berdasarkan Gender
--Tujuan: Mengidentifikasi demografi dasar mana yang memiliki risiko lebih tinggi.
SELECT 
    code_gender,
    COUNT(sk_id_curr) AS total_applicant,
    SUM(target) AS total_default,
    ROUND(AVG(target) * 100, 2) AS default_rate_percentage
FROM 
    application_train
WHERE 
    code_gender IN ('M', 'F') -- Mengabaikan data anomali 'XNA'
GROUP BY 
    code_gender
ORDER BY 
    default_rate_percentage DESC;

-- 2. Korelasi Riwayat Penolakan Masa Lalu dengan Kegagalan Bayar Saat Ini
-- Tujuan: Membuktikan hipotesis apakah nasabah yang sering ditolak di masa lalu 
--         memiliki probabilitas gagal bayar yang lebih tinggi saat ini.

WITH PastHistory AS (
    SELECT 
        sk_id_curr,
        COUNT(sk_id_prev) AS total_past_applications,
        SUM(CASE WHEN name_contract_status = 'Refused' THEN 1 ELSE 0 END) AS total_refused,
        -- Menghitung persentase penolakan di masa lalu
        ROUND((SUM(CASE WHEN name_contract_status = 'Refused' THEN 1 ELSE 0 END) * 100.0) / COUNT(sk_id_prev), 2) AS past_refusal_rate
    FROM previous_application
    GROUP BY sk_id_curr
)
SELECT 
    CASE 
        WHEN p.past_refusal_rate = 0 THEN 'A. 0% (Tidak Pernah Ditolak)'
        WHEN p.past_refusal_rate > 0 AND p.past_refusal_rate <= 50 THEN 'B. 1-50% (Jarang Ditolak)'
        WHEN p.past_refusal_rate > 50 THEN 'C. >50% (Sering Ditolak)'
        ELSE 'D. Tidak Punya Riwayat'
    END AS risk_segment,
    COUNT(a.sk_id_curr) AS total_clients,
    SUM(a.target) AS total_defaults,
    -- Menghitung persentase gagal bayar saat ini
    ROUND((SUM(a.target) * 100.0) / COUNT(a.sk_id_curr), 2) AS current_default_rate_percentage
FROM application_train a
LEFT JOIN PastHistory p ON a.sk_id_curr = p.sk_id_curr
GROUP BY risk_segment
ORDER BY risk_segment ASC;