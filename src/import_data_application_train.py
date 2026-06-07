import pandas as pd
from sqlalchemy import create_engine
import time

# 1. Setup koneksi 
db_uri = 'postgresql+psycopg2://postgres:YOUR_PASSWORD@localhost:5433/home_credit_risk'
engine = create_engine(db_uri)

# 2. Target file ketiga
file_path = 'data/application_train.csv'

print("Membaca file CSV ke dalam Pandas... (Tunggu sebentar)")
start_time = time.time()

df = pd.read_csv(file_path)
# Membersihkan nama kolom
df.columns = [col.lower() for col in df.columns]

print(f"Total data yang akan diproses: {len(df)} baris.")
print("Mengirim data ke PostgreSQL dengan teknik chunking...")

# 3. Eksekusi pengiriman bertahap
with engine.begin() as conn:
    # chunksize=50000 berarti mengirim 50.000 baris per transaksi
    df.to_sql('application_train', con=conn, if_exists='replace', index=False, chunksize=50000)

end_time = time.time()
print(f"Berhasil! Tabel 'application_train' sudah masuk.")
print(f"Total waktu eksekusi: {round(end_time - start_time, 2)} detik.")