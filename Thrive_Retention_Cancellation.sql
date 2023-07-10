drop table if exists #ThriveAccts;
select 
UserId, CreatedAt as ApplicationDate,
row_number() over(partition by UserId order by CreatedAt ASC) as row_num
INTO #ThriveAccts
from UserLoanApplications where CreatedAt > '2023-04-01'
and Status in (3,4);

drop table if exists #Thrive_sub_ids;
select 
a.*, UserSubscriptionId, StartDate, EndDate, 
case when datediff(day,StartDate,ApplicationDate) <= 14 then 1 else 0 end as new_user_flag
INTO #Thrive_sub_ids
from #ThriveAccts a 
left join UserSubscription b 
    on a.UserId = b.UserId 
    and StartDate < ApplicationDate 
    and EndDate > ApplicationDate
where row_num = 1;
​
​
drop table if exists #Thrive_retention;
select 
a.*, InvoiceDate, InvoiceStatus
INTO #Thrive_retention
from #Thrive_sub_ids a
left join UserSubscriptionInvoice b 
    on a.UserSubscriptionId = b.UserSubscriptionId 
    and InvoiceDate > dateadd(day,-1,StartDate)
​
drop table if exists #Thrive_retention2;
select 
a.*, 
FIRST_VALUE(InvoiceDate) OVER(PARTITION BY UserId ORDER BY InvoiceDate ASC) AS first_inv_mth,
row_number() over(partition by UserId order by InvoiceDate ASC) as row_num2
INTO #Thrive_retention2
from #Thrive_retention a
​
--Retention
select 
month(ApplicationDate) as app_month,
month(InvoiceDate) as invoice_month,
month(first_inv_mth) as first_inv_month, 
InvoiceStatus,
row_num2 as inv_num,
userid
from #Thrive_retention2 where new_user_flag = 1
​
--Cancellation
select 
month(ApplicationDate) as month_application,
(case when EndDate < dateadd(day,15,StartDate) then 1 else 0 end) as cancel15,
(case when EndDate < dateadd(day,30,StartDate) then 1 else 0 end) as cancel30,
(case when EndDate < dateadd(day,60,StartDate) then 1 else 0 end) as cancel60,
(case when EndDate < dateadd(day,90,StartDate) then 1 else 0 end) as cancel90,
(case when EndDate < '2024-01-01' then 1 else 0 end) as cancel2023,
userid
from #Thrive_sub_ids where new_user_flag = 1