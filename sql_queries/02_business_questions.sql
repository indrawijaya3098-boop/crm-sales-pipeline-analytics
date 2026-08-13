-- Level 1: Pertanyaan Operasional Sehari-Hari
-- === 1. Sales/Revenue === --
-- Berapa total pendapatan (Revenue) yang berhasil kita bukukan dari seluruh trx?
-- Dan berapa jumlah transaksi (Closed Won) tersebut?
-- Hint: v_clean_deals
select
	sum(clean_deal_value) as Total_Pendapatan_Revenue
from v_clean_deals;
-- hasil total revenue
select
	clean_stage as Stage_Khusus,
	sum(clean_deal_value) as Total_Revenue,
	count(deal_id) as Total_Deals
from v_clean_deals
where clean_stage = 'Closed Won'
group by clean_stage;
-- hasil revenue hanya 'Closed Won'

select
	sum(clean_deal_value) as Total_Revenue,
	sum(case
			when clean_stage = 'Closed Won' then clean_deal_value else 0
		end
	) as Hanya_Closed_Won,
	count(case
			when clean_stage = 'Closed Won' then deal_id
		end
	) as Closed_Won_Deals,
	round(
		sum(case 
				when clean_stage = 'Closed Won' then clean_deal_value else 0
		end
		) * 100/
		nullif(sum(clean_deal_value), 0), 2
	) as Win_Rate_Percentage
from v_clean_deals;
-- Penggabungan semua total revenue dan hanya revenue 'Closed Won' 

-- Contoh Pertanyaan lain
-- Kalau Pakai Window Function
-- Jika stakeholder minta: "Tolong tampilkan revenue masing-masing stage, tapi di sampingnya kasih kolom Total Pipeline perusahaan buat pembanding" 
-- gunakan Window Function (OVER()):

select
	clean_stage,
	sum(clean_deal_value) as Stage_Revenue,
	count(deal_id) as Stage_Deals,
	sum(sum(clean_deal_value)) over () as Total_Pipeline_ALL_Stages,
	-- Menghitung % Kontribusi Revenue Stage terhadap total pipeline
	round(
		sum(clean_deal_value) * 100.0 / nullif
		(sum(sum(clean_deal_value)) over(), 0), 2)
	as Contribution
from v_clean_deals
group by clean_stage 
order by Stage_Revenue desc;

-- Hasil query yang benar untuk mencari tambahan nilai % kontribusi tiap stage
-- Fungsi dan logika tiap query:

-- 1. Over() untuk mendapatkan total keseluruhan(Grand Total)
-- Menyuruh sql untuk menghitung agg diseluruh baris hasil tanpa terpengaruh oleh pengelompokkan group by clean_stage
-- Kenapa Sum 2x? 
-- Sum(clean_deal_value) yg pertama untuk menghitung total revenue per-stage (Karena ada group by clean_stage)
-- Sum(..) over() yang luar menjumlahkan seluruh total revenue per-stage tsb menjadi Grand Total Pipeline (21.18M)
-- Hasilnya pada baris Closed Won dsb, nilai sum(sum(clean_deal_value)) over() akan selalu bernilai 21.18M di tiap baris
-- 2. NULLIF(..., 0) penyelamat dari error division by zero
-- NULLIF(A,B) Jika nila A = B maka kembalikan NULL, jika A Tidak Sama Dengan B kembalikan nilai A
-- Kenapa di isi 0 dibelakang NULLIF? untuk pembanding "Jika Grand Total Revenue 0 ubah jadi NULL"
-- Tujuannya agar tidak menjadi angka 0 tapi jadinya NULL agar tidak error saat pembagian
-- 3. ROUND(..,2) membatasi angka desimal
-- 4. * 100.0? untuk mengubah pecahan desimal menjadi persentase

-- === 2. Marketing/Demografi === --
-- Berapa sebaran jumlah pelanggan terbanyak berdasarkan wilayah (clean_province)?
-- Urutkan dari provinsi dengan pelanggan terbanyak.
-- Tujuan Bisnis: Menentukan fokus wilayah untuk kampanye marketing/ekspansi tim sales regional
-- Hint: v_clean_customers

select
	clean_province as Wilayah,
	count(company_name) as Total_Sebaran_Pelanggan
from v_clean_customers
group by Wilayah
order by Total_Sebaran_Pelanggan desc;

-- === 3. Customer Support/Backlog === --
-- Berapa jumlah tiket dukungan yg statusnya masih menggantung (Open atau In Progress)
-- per masing-masing kategori tiket?
-- Tujuan Bisnis: Memantau beban kerja (workload) tim CS dan mendeteksi kategori yg paling sering dikeluhkan pelanggan
-- Hint: v_clean_tickets

select
	clean_category, 
	clean_status,
	count(ticket_id) as Status_Ticket
from v_clean_tickets
where clean_status in ('Open', 'In Progress')
group by clean_category, clean_status
order by clean_category, Status_Ticket desc;

-- ===== Level 2, Masuk ke analisis lintas departmen (Multi-Table JOIN) ===== --
-- === 1. Sales & Marketing === --
-- Berapa total revenue (Closed Won) dan rata-rata nilai deal (clean_deal_value)
-- yang disumbangkan oleh masing2 provinsi? (clean_province).
-- urutkan dari provinsi penyumbang omzet terbesar.
-- Tujuan: Mengetahui Revenue Per Region untuk alokasi budget marketing&kuota tim sales daerah
-- Hint: Join v_clean_customers dan v_clean_deals dengan INNER

SELECT 
    c.clean_province AS provinsi,
    SUM(d.clean_deal_value) AS total_revenue,
    ROUND(AVG(d.clean_deal_value), 2) AS avg_deal_value,
    ROUND(
        SUM(d.clean_deal_value) * 100.0 / NULLIF(SUM(SUM(d.clean_deal_value)) OVER(), 0), 2
    ) AS pct_contribution
FROM v_clean_customers c
INNER JOIN v_clean_deals d ON c.customer_id = d.customer_id
WHERE d.clean_stage = 'Closed Won'
GROUP BY c.clean_province
ORDER BY total_revenue DESC;

-- === 2. Risk & Churn Analysis === --
-- Siapa saja nama perusahaan yang gagal memenangkan kesepakatan (Closed Lost)
-- sekaligus memiliki jumlah tiket komplain terbanyak? tampilkan nama perusahaan,
-- total nilai deal yg lost dan jumlah tiketnya
-- Tujuan: Mengindentifikasi root case gagal closing, apa karena layanan buruk/masalah teknis
-- Hint: JOIN pada ketiga view

WITH ticket_summary AS (
    SELECT 
        customer_id,
        COUNT(ticket_id) AS total_tickets
    FROM v_clean_tickets
    GROUP BY customer_id
)
SELECT 
    c.company_name AS nama_perusahaan,
    d.clean_stage AS status_stage,
    SUM(d.clean_deal_value) AS total_nilai_deal_lost,
    COALESCE(SUM(t.total_tickets), 0) AS jumlah_tiket
FROM v_clean_customers c
INNER JOIN v_clean_deals d ON c.customer_id = d.customer_id
LEFT JOIN ticket_summary t ON c.customer_id = t.customer_id
WHERE d.clean_stage = 'Closed Lost'
GROUP BY c.company_name, d.clean_stage
ORDER BY total_nilai_deal_lost DESC;

-- === 3. Sales Cycle Velocity === --
-- Berapa rata2 durasi hari yg dibutuhkan tim sales dari saat pelanggan bergabung (clean_join_date)
-- hingga trx mereka berhasil dimenangkan (clean_close_date pada stage closed won)
-- Tujuan: Mengukur kecepatan konversi trx (Sales Velocity) perusahaan
-- Hint: Gabungkan v_clean_customers & v_clean_deals, lalu gunakan pengurangan tanggal
-- (clean_close_date - clean_join_date) didalam fungsi AVG()

SELECT 
    ROUND(AVG(d.clean_close_date - c.clean_join_date), 2) AS avg_sales_cycle_days,
    COUNT(d.deal_id) AS total_deals_analyzed
FROM v_clean_customers c
INNER JOIN v_clean_deals d ON c.customer_id = d.customer_id
WHERE d.clean_stage = 'Closed Won'
  AND c.clean_join_date IS NOT NULL 
  AND d.clean_close_date IS NOT NULL;
-- Ini query untuk rata2 keseluruhan perusahaan

SELECT 
    c.company_name,
    COUNT(d.deal_id) AS total_deals_won,
    ROUND(AVG(d.clean_close_date - c.clean_join_date), 2) AS avg_sales_cycle_days
FROM v_clean_customers c
INNER JOIN v_clean_deals d ON c.customer_id = d.customer_id
WHERE d.clean_stage = 'Closed Won'
  AND c.clean_join_date IS NOT NULL 
  AND d.clean_close_date IS NOT NULL
GROUP BY c.company_name
ORDER BY avg_sales_cycle_days DESC;
-- ini query rata2 per perusahaan

SELECT 
    c.company_name AS nama_perusahaan,
    c.clean_join_date AS tanggal_gabung,
    d.clean_close_date AS tanggal_closed,
    d.clean_stage AS status_stage,
    d.clean_deal_value AS nilai_deal,
    -- 1. Hitung total durasi hari per transaksi
    (d.clean_close_date - c.clean_join_date) AS total_hari,
    -- 2. Hitung rata-rata hari keseluruhan (Grand Total Average) di setiap baris
    ROUND(
        AVG(d.clean_close_date - c.clean_join_date) OVER (), 2
    ) AS rata2_hari_overall
FROM v_clean_customers c
INNER JOIN v_clean_deals d ON c.customer_id = d.customer_id
WHERE d.clean_stage = 'Closed Won'
  AND c.clean_join_date IS NOT NULL 
  AND d.clean_close_date IS NOT null
  -- Membuang baris data kotor yg tgl gabungnya kosong agar tidak null dihasil akhir
ORDER BY total_hari DESC;
-- Hasil query
-- Penyebab nilai NULL merupakan hasil dari logika pembersihan View yang dibuat sebelumnya
-- angka transaksi anomali/minus diubah menjadi NULL agar tidak merusak laporan keuangan
-- Round() sendiri bukan aggregasi, menghitung agregasi global dilatar belakang,
-- lalu menyisipkan hasilnya ke setiap baris detail tanpa mengompress/menggabungkan baris data
-- Makanya gaperlu GROUP BY

-- Dampak NULL terhadap laporan revenue & kerugian
-- Nilai negatif pada deal_value di sistem CRM biasanya disebabkan 3 hal:
-- 1. Human Error: Tim sales gasengaja ketik -50000000 padahal maksudnya 50jt
-- 2. Refund/Diskon/Retur: Nilai pengembalian dana/potongan harga di input secara asal ke kolom deal_value sebagai angka minus
-- 3. Pembatalan/Adjusment: Penyesuaian tagihan akibat pembatalan  layanan ditengah jalan

-- Apakah ini terdeteksi sebagai kerugian dalam laporan Revenue?
-- Secara Pipeline Revenue(CRM Analytics):
-- Langkah kita mengubah menjadi NULL sudah tepat, sebuah kesepakatan penjualan(deal) tidak mungkin bernilai negatif
-- Jika angka minus dibiarkan masuk ke hitungan SUM(deal_value) total Gross Revenue perusahaan akan terdistorsi
-- Secara Laporan Keuangan:
-- Jika angka minus tersebut ternyata adalah Refund/Diskon Resmi, maka angka itu tidak dibuang/di NULL kan begitu saja
-- melainkan dicatat dikolom terpisah sebagai pengurangan Revenue:
-- Net Revenue = Gross Sales - (Refunds + Discounts)

-- Cara menyampaikan temuan ke stakeholder
-- Gross Revenue(Closed Won Murni): Total pendapatan yg berhasil kita bukukan adalah Rp.4,77M dari trx bernilai valid
-- Catatan Audit Data: Terdapat 3 trx Closed Won yg memiliki nilai awal negatif/anomali
-- Untuk menjaga keakuratan agg nilai deal, trx tersebut di isolasikan dari total revenue
-- dan direkomendasikan kepada tim sales ops/finance untuk diverifikasikan ulang apakah
-- terjadi kesalahan input atau retur.

-- ====== Level 3 Stategic & Executive Insights (Advanced Analytics) ====== --
-- Biasanya menu utama saat membuat laporan strategi, dashboad executive atau analisis alur konversi untuk C-Suite(CEO/VP Sales)
-- === 1. Sales Pipeline Funnel Analysis === ---
-- Berapa jumlah deal dan total potensi nilai deal di setiap stage penjualan (Prospecting, Qualification, Closed Won&Lost)
-- Di stage mana tingkat kebocoran (drop-off rate) nilai trx terbesar terjadi?
-- Tujuan: Menemukan bottleneck utama dalam alur proses penjualan tim sales
-- Hint: Agg, CASE WHEN, dan perhitungan persentase terhadap total pipeline

select
	clean_stage as Stage_penjualan,
	count(deal_id) as total_deals,
	sum(clean_deal_value) as stage_value,
	-- % Porsi Nilai Stage terhadap total Pipeline Perusahaan
	round(
		sum(clean_deal_value) * 100.0 /
		nullif(
			sum(sum(clean_deal_value)) over (), 0), 2
		) as pct_pipeline
from v_clean_deals 
group by clean_stage 
order by stage_value desc;
-- Hasil query ini mendapati titik kebocoran terbesar (Drop-Off/Loss)
-- Kebocoran terbesar ada di stage Closed Lost, dimana perusahaan kehilangan potensi
-- pendapatan sebesar 9,29M (43,86%) dari total 21,8M. hampir separuh uang di pipeline gagal diubah jadi omzet
-- Berhasil di Closing (Closed_Won) 4,77M (22,54%) dari 44 trx
-- Gagal di Closing (Closed_Lost) 9,29M (43,86%) dari 71 trx
-- At-Risk Active Funnel (Peluang yg harus diselamatkan)
-- Masih ada 4,87M (~23%) trx yg menggantung di stage Qualification dan Prospecting
-- Tim Sales lead wajib memprioritaskan stage ini agar tidak menyusul pindah ke Closed_Lost
-- Terdapat data Unknown, tidak boleh langsung dimasukkan secara sepihak ke stage lain.
-- Jika masuk Closed_Won: Terjadi overstating revenue (penggelembungan omzet fiktif)
-- management mengira ada uang masuk 2,23M padahal kas riil tidak ada
-- Jika masuk Closed_Lost: Terjadi Understanding Sales Performance
-- Kinerja tim sales terlihat buruk, padahal ada kemungkinan trx tsb sebenarnya berhasil tp lupa diperbarui di CRM
-- Jika masuk Trx Gantung: Merusak Revenue Forecasting
-- Management akan membuat keputusan ekspansi yg salah karena mengharapkan potensi omzet mendatang dari deal yg sebenernya udah mati/batal

-- Rekomendasi Aksi untuk Data Analyst
-- Sajikan transparan sebagai "Unmapped/Unknown Pipeline"
-- Dalam Dashboard, tetap tampilkan sebagai baris tersendiri. berikan catatan khusus
-- bahwa angka 2,23M merupakan potensi nilai yg tertahan akibat isu kualitas input data
-- Lakukan Reconsiliasi Data (Data Reconciliation)
-- Tarik daftar deal_id yg berstatus Unknown, lalu minta verifikasi ke tim sales ops/finance dengan aturan
-- Ada bukti pembayaran/invoicing di finance? (masuk Closed_Won)
-- Pelanggan menolak/batal/tidak ada kabar >90Hari? (masuk Closed_Lost)
-- Masih dalam tahap negosiasi aktif? (Masuk Prospecting atau Qualification)
-- Rekomendasikan ke tim IT/CRM agar kolom stage di apk penjualan diubah menjadi
-- Mandatory Dropdown (wajib pilih) dan melaran penggunaan input teks bebas
-- agar masalah data Unknown tidak terulang di masa depan.

-- === 2. VIP Customer Health Check/LTV vs Risk === --
-- Siapa 5 perusahaan teratas, yg menyumbangkan total revenue (Closed Won) terbesar?
-- Brp tiket komplain yg sudah mereka ajukan dan bagaimana status tiketnya saat ini?
-- Tujuan: Key-Account Management, memastikan klien bernilai tinggi mendapat penganan prioritas
-- agar tidak pindah ke kompetitor (churn)
-- Hint: CTE multi table (v_clean_deals + v_clean_tickets), LEFT JOIN, ORDER BY total_revenue desc limit 5

with vip_customers as (
	-- CTE 1: Cari Top 5 customer_id dengan total revenue (Closed Won) terbesar 	
	select
		customer_id,
		sum(clean_deal_value) as total_revenue
	from v_clean_deals
	where clean_stage = 'Closed Won'
	group by customer_id
	order by total_revenue desc
	limit 5
),
ticket_summary as (
	-- CTE 2: Ringkas jumlah tiket dan statusnya per customer
	select
		customer_id,
		count(ticket_id) as total_tiket,
		count(case when clean_status = 'Open' then 1 end) as tiket_open,
		count(case when clean_status = 'In Progress' then 1 end ) as tiket_in_progress,
		count(case when clean_status = 'Closed' then 1 end ) as tiket_closed
	from v_clean_tickets
	group by customer_id
)
select
	c.company_name as nama_perusahaan,
	c.clean_province as provinsi,
	v.total_revenue,
	coalesce(t.total_tiket, 0) as total_tiket,
	coalesce(t.tiket_open, 0) as tiket_open,
	coalesce(t.tiket_in_progress, 0) as tiket_in_progress,
	coalesce(t.tiket_closed, 0) as tiket_closed
from vip_customers v
inner join v_clean_customers c
on v.customer_id = c.customer_id
left join ticket_summary t
on v.customer_id = t.customer_id 
order by v.total_revenue desc;

-- === 3. Monthly Revenue Trend & Seasonality === --
-- Bagaimana tren pendapatan bulanan (Closed Won) berdasarkan bulan closing (clean_close_date)?
-- tampilkan nama bulan/tahun beserta total revenuenya
-- Tujuan: Evaluasi performa omzet antar-bulan (month-over-month) dan mendeteksi pola musim penjualan (seasonality)
-- Hint: Ekstraksi bulan/tahun (TO_CHAR/DATE_TRUNC), GROUP BY,
-- dan Window Function LAG() jika ingin menghitung pertumbuhan persentase bulanan (MoM Growth)

WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', d.clean_close_date) AS month_date,
        TO_CHAR(d.clean_close_date, 'Mon YYYY') AS bulan_tahun,
        SUM(d.clean_deal_value) AS total_revenue,
        COUNT(d.deal_id) AS total_deals
    FROM v_clean_deals d
    WHERE d.clean_stage = 'Closed Won'
      AND d.clean_close_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', d.clean_close_date), TO_CHAR(d.clean_close_date, 'Mon YYYY')
)
SELECT 
    bulan_tahun,
    total_revenue,
    total_deals,
    -- Menghitung Pertumbuhan Bulanan / Month-over-Month (MoM) Growth (%)
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY month_date)) * 100.0 / 
        NULLIF(LAG(total_revenue) OVER (ORDER BY month_date), 0), 2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month_date ASC;
-- Komponen Penting Query Ini
-- DATE_TRUNC('month', d.clean_close_date): Membulatkan tanggal ke hari pertama di bulan tersebut (misal 2024-05-14 jadi 2024-05-01). 
-- Ini kunci utama agar data bisa di-GROUP BY dan diurutkan secara kronologis (ORDER BY month_date ASC).
-- TO_CHAR(..., 'Mon YYYY'): Mengubah tampilan format tanggal menjadi teks yang enak dibaca di laporan eksekutif (contoh: Jan 2024, Feb 2024).
-- LAG(total_revenue) OVER (ORDER BY month_date): Window Function khusus untuk mengambil nilai total_revenue bulan sebelumnya.
-- mom_growth_pct: Mengukur persentase kenaikan/penurunan omzet dibanding bulan sebelumnya dengan rumus: