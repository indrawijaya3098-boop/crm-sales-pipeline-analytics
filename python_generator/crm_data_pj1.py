import random
from datetime import datetime, timedelta
from supabase import create_client, Client

# --- 1. KONEKSI SUPABASE ---
SUPABASE_URL = # Contoh: "https://xyzcompany.supabase.co"
SUPABASE_KEY = # Masukkan anon/public key dari Supabase

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
random.seed(42)
print("Memulai generate data berkonteks Indonesia & upload ke Supabase...")

# --- 2. GENERATE & INSERT CUSTOMERS (Indonesia Context) ---
locations = [
    "DKI Jakarta",
    "JAKARTA",
    " Jakarta ",
    "Surabaya",
    "SURABAYA",
    "Bandung",
    "BDG",
    "Jawa Barat",
    "Medan",
    "Semarang",
    "Makassar",
    None,
]

companies = [
    "PT Nusantara Tech",
    "CV Maju Bersama",
    "PT Sinar Harapan",
    "Toko Berkah Utama",
    "PT Digital Nusantara",
    "Kopi Sejahtera Group",
    "PT Logistik Jaya",
    "CV Karya Mandiri",
    "PT Solusi Data",
]

customers = []
for i in range(1, 101):
    c_id = f"CUST-{i:03d}"
    comp_base = random.choice(companies)
    comp = f"{comp_base} {random.randint(1, 99)}"

    # Domain email lokal
    clean_comp_name = (
        comp_base.lower().replace("pt ", "").replace("cv ", "").replace(" ", "")
    )
    email = f"kontak@{clean_comp_name}.co.id"

    loc = random.choice(locations)

    base_date = datetime(2023, 1, 1) + timedelta(days=random.randint(0, 500))
    date_fmt = random.choice(["%Y-%m-%d", "%d/%m/%Y", "%m-%d-%Y", "NULL"])
    join_date = base_date.strftime(date_fmt) if date_fmt != "NULL" else None

    customers.append(
        {
            "customer_id": c_id,
            "company_name": comp,
            "email": email,
            "province_city": loc,
            "join_date": join_date,
        }
    )

# Inject Duplicates (PK Violation)
customers.append(
    {
        "customer_id": "CUST-010",
        "company_name": "PT Nusantara Tech Duplicate",
        "email": "dup@nusantara.co.id",
        "province_city": "DKI Jakarta",
        "join_date": "2023-05-10",
    }
)
customers.append(
    {
        "customer_id": "CUST-025",
        "company_name": "CV Maju Bersama Dup",
        "email": "dup@maju.co.id",
        "province_city": "Surabaya",
        "join_date": "2023-06-12",
    }
)

supabase.table("crm_customers").insert(customers).execute()
print(f"✅ {len(customers)} baris berhasil dikirim ke 'crm_customers'")


# --- 3. GENERATE & INSERT DEALS (Nominal Rupiah) ---
stages = [
    "Prospecting",
    "Qualification",
    "Closed Won",
    "closed_won",
    "WON",
    "Closed Lost",
    "CLOSED LOST",
    "lost",
]

deals = []
for i in range(1, 201):
    deal_id = f"DEAL-{i:04d}" if random.random() > 0.03 else None

    # 10% chance of Orphan FK
    if random.random() < 0.10:
        cust_id = f"CUST-{random.randint(900, 999):03d}"
    else:
        cust_id = f"CUST-{random.randint(1, 100):03d}"

    stage = random.choice(stages)

    # Nominal Rupiah (Jutaan) + Anomali
    val_type = random.random()
    if val_type < 0.05:
        deal_val = -15000000  # Anomali refund/retur (Rp -15 juta)
    elif val_type < 0.10:
        deal_val = 0  # Anomali deal Rp 0
    else:
        # Rentang transaksi Rp 5 juta - Rp 250 juta
        deal_val = random.randint(5, 250) * 1000000

    close_date = (
        datetime(2024, 1, 1) + timedelta(days=random.randint(0, 300))
    ).strftime("%Y-%m-%d")

    deals.append(
        {
            "deal_id": deal_id,
            "customer_id": cust_id,
            "stage": stage,
            "deal_value": deal_val,
            "close_date": close_date,
        }
    )

supabase.table("crm_deals").insert(deals).execute()
print(f"✅ {len(deals)} baris berhasil dikirim ke 'crm_deals'")


# --- 4. GENERATE & INSERT SUPPORT TICKETS ---
categories = [
    "Kendala Tagihan",
    "TAGIHAN",
    "Bug Sistem",
    "bug",
    "Permintaan Fitur",
    "Akses Akun",
]
statuses = ["Open", "open", "IN_PROGRESS", "Diproses", "Resolved", "SELESAI", "Closed"]

tickets = []
for i in range(1, 150):
    ticket_id = f"TCK-{i:04d}"
    cust_id = f"CUST-{random.randint(1, 110):03d}"  # Termasuk orphan FK (>100)
    cat = random.choice(categories)
    stat = random.choice(statuses)
    created_at = (
        datetime(2024, 1, 1) + timedelta(days=random.randint(0, 300))
    ).strftime("%Y-%m-%d %H:%M:%S")

    tickets.append(
        {
            "ticket_id": ticket_id,
            "customer_id": cust_id,
            "category": cat,
            "status": stat,
            "created_at": created_at,
        }
    )

supabase.table("crm_support_tickets").insert(tickets).execute()
print(f"✅ {len(tickets)} baris berhasil dikirim ke 'crm_support_tickets'")

print("\n🚀 Selesai! Dataset CRM lokal Indonesia berhasil terisi di Supabase.")
