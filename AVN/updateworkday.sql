BEGIN TRAN


select *, ROW_NUMBER() OVER(PARTITION BY ProfileID ORDER BY DateEffective DESC) AS rk 
into #hwh
from Hre_WorkHistory where
DateEffective <= '2021-12-20' and IsDelete is null


select * into #hwhfinal
from #hwh a
where rk =1 and ProfileID not in ( select id from Hre_Profile where IsDelete is not null)
and ProfileID in ( select id from Hre_Profile where IsDelete is null and ( DateQuit is null or DateQuit > = '2021-11-21'))



---- Lay ra nhan vien theo co cau
--select c.CodeEmp,c.ProfileName,b.* 
select c.id
into #need
from #hwhfinal a left join Cat_OrgUnit b
on a.OrganizationStructureID = b.OrgstructureID
left join Hre_Profile c on c.id = a.ProfileID
where b.E_DIVISION_CODE = 'QA'



update Att_Workday set status = null  WHERE ProfileID  IN ( SELECT ID FROM 
#need
)
AND IsDelete IS NULL AND WorkDate BETWEEN '2021-11-21' AND '2021-12-20'


------- update co cau, chuc vu , chuc danh, cap bac.....
--- lay ra nhung dong workday can update
SELECT a.id
into #Att_Workday
FROM Att_Workday a
LEFT JOIN dbo.Hre_Profile b ON a.ProfileID = b.id
WHERE a.IsDelete IS NULL AND WorkDate BETWEEN '2022-01-21' AND '2022-02-20'
AND ( a.OrgStructureID IS NULL OR a.SalaryClassID IS NULL )


----backup workday phòng hờ sai
select a.*
into #Att_Workday_bk
from dbo.Att_Workday a inner join #hwhfinal b on a.ProfileID = b.ProfileID  where  a.IsDelete is null and b.IsDelete is NULL
and a.id in ( select id from  #Att_Workday )



update a
set a.OrgStructureID = b.OrganizationStructureID, a.CostCentreID = b.CostCentreID,
a.LaborType = b.LaborType, a.WorkPlaceID = b.WorkPlaceID, a.EmployeeGroupID = b.EmployeeGroupID, a.EmploymentType = b.EmploymentType,
a.PositionID = b.PositionID, a.JobTitleID = b.JobTitleID, a.SalaryClassID = b.SalaryClassID
from dbo.Att_Workday a inner join #hwhfinal b on a.ProfileID = b.ProfileID  where  a.IsDelete is null and b.IsDelete is NULL
and a.id in ( select id from  #Att_Workday )


drop table #hwh,#hwhfinal,#need,#Att_Workday






ROLLBACK