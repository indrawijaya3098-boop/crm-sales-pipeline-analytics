# 📊 End-to-End CRM Sales Analytics & Executive Power BI Dashboard

![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)

## 📌 Project Overview
Proyek ini merupakan solusi **End-to-End Business Intelligence & Data Analytics** untuk menganalisis performa penjualan, pola *seasonality*, kebocoran *pipeline*, hingga eskalasi tiket operasional pada sistem CRM berkonteks perusahaan di Indonesia.

Seluruh siklus data dibangun dari hulunya:
`Python Data Generator` ➔ `Supabase Cloud PostgreSQL` ➔ `SQL Data Cleaning & Base Views (DBeaver)` ➔ `DAX & Power BI Interactive Dashboard`.

---

## 🏗️ End-to-End Architecture & Pipeline

1. **Data Generation (Python):** Menggenerasi *synthetic raw dataset* berkonteks lokal Indonesia (`crm_customers`, `crm_deals`, `crm_support_tickets`) dan di-injeksi otomatis via API ke Supabase.
2. **Cloud Data Warehouse (Supabase PostgreSQL):** Menampung data mentah di cloud database secara terpusat.
3. **Data Cleaning & Modeling (SQL/DBeaver):** 
   * Audit integritas data (*deduplication* via `ROW_NUMBER()`).
   * Standarisasi format tanggal (`TO_DATE`) & penanganan *missing values* pada wilayah (`TRIM/UPPER` & `CASE WHEN`).
   * Pembentukan *Base Views* (`v_clean_customers`, `v_clean_deals`, `v_clean_tickets`) untuk menjaga integritas data mentah.
4. **Data Visualization & Analytics (Power BI & DAX):**
   * Pembangunan *Star Schema Data Model*.
   * Kalkulasi ukuran bisnis menggunakan *DAX Measures* (`MoM Growth %`, `Closed Lost Value`, `Pipeline Loss Rate %`).
   * Penyusunan *5-Page Executive Interactive Dashboard*.

---

## 📈 Key Business Insights & Highlights

* 💰 **Revenue Realization:** Total pencapaian omzet berada di angka **Rp4,775 Miliar** dari **46 transaksi sukses** (*won deals*).
* 🚀 **Seasonality Spike (Q3 Rush):** Penjualan melonjak tajam pada Kuartal 3 dengan puncak tertinggi di **Agustus 2024 (Rp1,092 Miliar / +143,75% MoM)**.
* 🚨 **Pipeline Leakage Risk:** Terdapat kebocoran transaksi di *stage Closed Lost* sebesar **Rp9,29 Miliar** (**43,86% Loss Rate**) serta aset berisiko sebesar **Rp2,23 Miliar** di kategori *Unknown*.
* 🏙️ **Regional Dominance:** Wilayah Jawa (Jawa Timur & Jawa Barat) mendominasi pendapatan bisnis sebesar **58,85%**.
* ⚠️ **Operational Tickets:** Terdeteksi **74 tiket komplain aktif** dengan porsi terbesar pada **Kendala Tagihan (31,08%)**.

---

## 🎯 Executive Dashboard Overview

### 1. Executive Sales Summary
*Tampilan makro indikator performa utama bisnis.*
<img width="743" height="416" alt="Page 1 — Executive Sales Overview" src="https://github.com/user-attachments/assets/a163f4d4-a6c9-4c10-a455-431099518746" />

---

### 2. Strategic Action Plan (4 Pilar Rekomendasi)
*   **Pilar 1 (Revenue):** Meratakan target penjualan bulanan untuk menstabilkan arus kas akibat *Q3 Closing Rush*.
*   **Pilar 2 (Pipeline):** Mengawal Rp4,87 Miliar *active pipeline* agar tidak berujung *Closed Lost*.
*   **Pilar 3 (Data Governance):** Mengunci entri data CRM untuk menghapus kategori *Unknown*.
*   **Pilar 4 (Operations):** Memprioritaskan penanganan 23 tiket *Kendala Tagihan* pada akun-akun bernilai besar.
<img width="748" height="416" alt="Page 5 — Strategic Action Plan" src="https://github.com/user-attachments/assets/c832e0a1-3cc6-43e5-8fff-ad12104fabf7" />

---

## 📂 Repository Structure

```text
├── python_generator/
│   └── crm_data_pj1.py
├── sql_queries/
│   ├── 01_data_cleaning_views.sql
│   └── 02_business_questions.sql
├── power_bi/
│   └── Executive_Sales_Dashboard.pbix
└── README.md
