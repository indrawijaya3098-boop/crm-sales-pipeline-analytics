-- 1. MASTER VIEW CUSTOMERS (Deduplikasi PK, Standarisasi Lokasi & Tanggal Join)
-- Membuat view master baru
create or replace view v_clean_customers as
with ranked_customers as(
	select
		customer_id,
		company_name,
		email,
		province_city,
		join_date,
		row_number() over(
			partition by customer_id
			order by join_date asc nulls last
		) as rn
	from crm_customers
)
select
	customer_id,
	company_name,
	email,
	province_city as original_province,
	case
		when province_city is null or trim(province_city) = '' then 'Unknown'
		when lower(trim(province_city)) like '%jakarta' or lower(trim(province_city)) = 'jkt' then 'DKI Jakarta'
		when lower(trim(province_city)) like '%surabaya' or lower(trim(province_city)) = 'sby' then 'Jawa Timur'
		when lower(trim(province_city)) like '%bandung' or lower(trim(province_city)) = 'bdg' then 'Jawa Barat'
		when lower(trim(province_city)) like '%makassar' then 'Sulawesi Selatan'
		when lower(trim(province_city)) like '%semarang' then 'Jawa Tengah'
		when lower(trim(province_city)) like '%medan' then 'Sumatera Utara'
		else initcap(trim(province_city))
	end as clean_province,
	case
		when join_date is null or trim(join_date) = '' then null
		when join_date like '____-__-__' then to_date(join_date, 'YYYY-MM-DD')
		when join_date like '__/__/____' then to_date(join_date, 'DD/MM/YYYY')
		when join_date like '__-__-____' then to_date(join_date, 'MM-DD-YYYY')
		else null
	end as clean_join_date
from ranked_customers
where rn=1;

select * from v_clean_customers;

-- 2. Master View DEALS (Filter Orphan Key, Standarisasi Stage & Deal Value)
create or replace view v_clean_deals as
select
	d.deal_id,
	d.customer_id,
	-- 1. Standarisasi Stage
	case
		when lower(replace(d.stage, '-', ' ')) in ('closed won', 'won') then 'Closed Won'
		when lower(replace(d.stage, '-', ' ')) in ('closed lost', 'lost') then 'Closed Lost'
		when lower(d.stage) = 'prospecting' then 'Prospecting'
		when lower(d.stage) = 'qualification' then 'Qualification'
		else 'Unknown'
	end as clean_stage,
	-- 2. Cleaning Nilai Deal (Minus diubah ke NULL)
	d.deal_value as original_deal_value,
	case
		when d.deal_value < 0 then null
		else d.deal_value
	end as clean_deal_value,
	-- 3. Standarisasi Tanggal Transaksi
	case
		when d.close_date is null or trim(d.close_date) = '' then null
		when d.close_date like '____-__-__%' then to_date(d.close_date, 'YYYY-MM-DD')
		when d.close_date like '__/__/____%' then to_date(d.close_date, 'DD/MM/YYYY')
		when d.close_date like '__-__-____%' then to_date(d.close_date, 'MM-DD-YYYY')
		else null
	end as clean_close_date	
from crm_deals d
inner join v_clean_customers c 
on d.customer_id = c.customer_id;

select * from v_clean_deals;

-- 3. MASTER VIEW TICKETS (Filter Orphan Key, Standarisasi Status, Category & Date)
drop view if exists v_clean_tickets cascade;

create or replace view v_clean_tickets as
select
	t.ticket_id,
	t.customer_id,
	case
		when lower(t.status) = 'open' then 'Open'
		when lower(t.status) in ('diproses', 'in_progress') then 'In Progress'
		when lower(t.status) in ('closed', 'resolved', 'selesai') then 'Closed'
		else 'Other'
	end as clean_status,
	case
		when lower(t.category) in ('bug', 'bug sistem') then 'Bug Sistem'
		when lower(t.category) in ('kendala tagihan', 'tagihan') then 'Kendala Tagihan'
		when lower(t.category) = 'akses akun' then 'Akses Akun'
		when lower(t.category) = 'permintaan fitur' then 'Permintaan Fitur'
		else initcap(t.category)
	end as clean_category,
	to_date(t.created_at, 'YYYY-MM-DD') as clean_created_at
from crm_support_tickets t
inner join v_clean_customers c
on t.customer_id = c.customer_id;

select * from v_clean_tickets;
	