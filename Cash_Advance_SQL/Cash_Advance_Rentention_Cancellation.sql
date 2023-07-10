----Cash Advance
drop table if exists #recent_advances;
select 
a.UserCashAdvanceId, d.UserId,
Amount, CashAdvanceStatus,
AdvanceDate, RepayDate, OriginalRepayDate, 
d.MLModelScore as Li
INTO #recent_advances
from UserCashAdvance a 
left join UserCashAdvanceCreditVariable b 
    on a.UserCashAdvanceId = b.UserCashAdvanceId
left join UserCreditVariableLithium d 
    on b.UserCreditVariableId = d.UserCreditVariableId
    and d.ActualAnalysisDateUtc > '2023-03-25'
where AdvanceDate > '2023-04-01' 
    and CashAdvanceStatus !=6 
​
​
drop table if exists #CA_activate;
select 
a.UserId, UserSubscriptionId, StartDate, EndDate, Amount
INTO #CA_activate
from UserSubscription a 
left join (select a.UserId, min(AdvanceDate) as adv_dt, max(Amount) as Amount
            from UserSubscription a 
            left join #recent_advances b 
                on a.UserId = b.UserId 
                and StartDate < AdvanceDate 
                and EndDate > AdvanceDate
                and AdvanceDate < dateadd(day,14,StartDate)
            where StartDate > '2023-04-01' group by a.UserId) b 
    on a.UserId = b.UserId
where StartDate > '2023-04-01';
​
​
drop table if exists #CA_activate_resub;
select 
a.*,
case when b.UserSubscriptionId = a.UserSubscriptionId then 0 else 1 end as resub_flag
INTO #CA_activate_resub
from #CA_activate a 
left join (select UserId, min(UserSubscriptionId) as UserSubscriptionId
		  from UserSubscription
		  group by UserId) b
on a.UserId = b.UserId;
​
​
select 
month(StartDate), Amount, resub_flag, 
sum(case when EndDate < dateadd(day,15,StartDate) then 1 else 0 end) as cancel15,
sum(case when EndDate < dateadd(day,30,StartDate) then 1 else 0 end) as cancel30,
sum(case when EndDate < dateadd(day,60,StartDate) then 1 else 0 end) as cancel60,
sum(case when EndDate < dateadd(day,90,StartDate) then 1 else 0 end) as cancel90,
sum(case when EndDate < '2024-01-01' then 1 else 0 end) as cancel2023,
count(distinct UserId)
from #CA_activate_resub 
group by month(StartDate), Amount, resub_flag