
select * from Cat_Element where ElementCode like 'AVN_dA%' and IsDelete is null

SELECT * FROM  Cat_Element WHERE ElementCode LIKE 'AVN_D_%' AND IsDelete IS NULL AND ID NOT IN (
SELECT id FROM Cat_Element WHERE ElementCode LIKE 'AVN_DA%' AND IsDelete IS NULL
)


SELECT * FROM Cat_Element WHERE ElementCode LIKE 'AVN_IA%' AND IsDelete IS NULL

SELECT * FROM  Cat_Element where ElementCode like 'AVN_I_%' and IsDelete is null AND ID NOT IN (
select id from Cat_Element where ElementCode like 'AVN_IA%' and IsDelete is null
)


select distinct a.* from Cat_Element a
inner join (
select * from Cat_Element where Formula like '%ALLOWANCES_%_BASICSALARY%' and ElementType = 'Payroll'
) b on a.ElementCode like '%' + b.ElementCode + '%'
order by a.ElementCode



----- lay ra khoan them luong khong co phan tu luong
select b.code,* from Cat_Element a right join Cat_UnusualAllowanceCfg b
on a.ElementCode = 'AVN_' + b.Code
where b.IsDelete is null order by a.ElementCode

----lay ra phan tu luong loai phu cap
select * from Cat_Element a inner join Cat_UsualAllowance b
on a.ElementCode = 'AVN_' + b.Code

----- lay ra phan tu luong claim chi phi
select b.code,* from Cat_Element a right join Cat_PaymentAmount b
on a.ElementCode = 'AVN_' + b.Code
where b.IsDelete is null order by a.ElementCode




--update Cat_Element set ElementType = 'Payroll', UserUpdate = 'khang.nguyen', DateUpdate = GETDATE() where id in (

--select a.ID from Cat_Element a inner join Cat_UsualAllowance b
--on a.ElementCode = 'AVN_' + b.Code
--)

select * from Cat_Element where ElementCode like 'AVN_PCTNIEN_BL' 

--update Cat_Element set IsDelete = 1, UserUpdate = 'khang.nguyen', DateUpdate = GETDATE(), IPCreate = 'namta.del.1904' where id  ='C9564830-A6D2-4ABD-8B72-0CAD973553B0'

begin tran
--update Cat_Element set Formula =  REPlace(REPLACE(Formula,'ALLOWANCES_','AVN_'), '_BASICSALARY',''), UserUpdate = 'khang.nguyen', DateUpdate = GETDATE() where id  ='B6F680EB-53F3-4E1C-B766-A3D1E20A5D43'

select * from Cat_Element where id  ='B6F680EB-53F3-4E1C-B766-A3D1E20A5D43'

ROLLBACK