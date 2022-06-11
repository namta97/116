alter proc [dbo].[rpt_payroll_monthly]

@condition nvarchar(max) = " and (MonthYear = '2021-04-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'Khang.Nguyen'
as
BEGIN
	
	 IF @condition = ' ' 
	begin
	set @condition =  ' and (MonthYear = ''2021-04-01'') '
	END


	declare @IsExport bit
	if (@condition is null or @condition = '')
	set @IsExport = 0


	declare @str nvarchar(max)
	declare @countrow int
	declare @row int
	declare @index int
	declare @ID nvarchar(500)
	set @str = REPLACE(@condition,',','@')
	set @str = REPLACE(@str,'and (',',')
	SELECT ID into #tableTempCondition FROM SPLIT_To_NVARCHAR (@str)
	set @row = (SELECT count(ID) FROM SPLIT_To_NVARCHAR (@str))
	set @countrow = 0
	set @index = 0
	declare @tempID nvarchar(Max)
	declare @tempCodition nvarchar(Max)
	declare @conditionCutOffDurationID varchar(100)
	set @conditionCutOffDurationID = ''
	DECLARE @MonthYear nvarchar(50) = ' '
	DECLARE @MonthYearSP nvarchar(50) = ' '
	DECLARE @AmountCondittion nvarchar(100) = ''
	DECLARE @PayPaidType nvarchar(100) = ''

    
	 while @row > 0
	 BEGIN
     	set @index = 0
		set @ID = (select top 1 ID from #tableTempCondition)
		set @tempID = replace(@ID,'@',',')

		set @index = 0
		set @index = charindex('MonthYear = ',@tempID,0) 
		if(@index > 0)
		begin
			set @condition = REPLACE(@condition,'(MonthYear = ','(spt.MonthYear = ')
			set @tempCodition = 'and ('+@tempID
			set @MonthYear = @tempCodition
			SET @MonthYearSP = REPLACE(@tempCodition,'''','''''')
		end
      
        
		set @index = charindex('(AmountCondittion ','('+@tempID,0) 
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @AmountCondittion = REPLACE(@tempCodition,'(AmountCondittion in ','')
			set @AmountCondittion = REPLACE(@AmountCondittion,',',' OR ')
			set @AmountCondittion = REPLACE(@AmountCondittion,'))',')')
		END
		
		set @index = charindex('(ProfileName ','('+@tempID,0) 
		if(@index > 0)
		begin
     		SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
		END

		set @index = charindex('(PayPaidType ','('+@tempID,0) 
		if(@index > 0)
		BEGIN
			set @tempCodition = 'AND ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @PayPaidType = @tempCodition
		END

		DELETE #tableTempCondition WHERE ID = @ID
		set @row = @row - 1
	 end
	 --select  @conditionCutOffDurationID,@Settlement,@StatusPay
	 --if len(@Settlement)=0 
	 --begin 
	 --set @condition=@condition+' and (hs.Settlement is null)'
	 --end
	 drop table #tableTempCondition

--- Giá trị
IF (@AmountCondittion is not null and @AmountCondittion != '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondittion,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_EqualToZero''','Amount = 0')
	END
	SET @index = charindex('E_LessThanZero',@AmountCondittion,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_LessThanZero''','Amount < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondittion,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_GreaterThanZero''','Amount > 0')	
	END
END

-- Hình thức thanh toán
IF (@PayPaidType is not null AND @PayPaidType != '')
BEGIN
	SET @index = charindex('Cash',@PayPaidType,0) 
	IF(@index > 0)
	BEGIN
	SET @PayPaidType = REPLACE(@PayPaidType,'Cash',N'Tiền mặt')
	END
	SET @index = charindex('Transfer',@PayPaidType,0) 
	IF(@index > 0)
	BEGIN
	SET @PayPaidType = REPLACE(@PayPaidType,'Transfer',N'Chuyển khoản')
	END
END


declare @query nvarchar(max)
declare @queryPageSize nvarchar(max)	
DECLARE @getdata NVARCHAR(max)

DECLARE @Element NVARCHAR(max)
DECLARE @ElementPivot NVARCHAR(max)

SET @Element = ' AND spti.Code IN( ''AVN_LCB'',''AVN_NCTL'',''AVN_TONGLUONGNGAYCONG'',''AVN_PCTheoLuong_SUM'',''AVN_OT_SUM'',''AVN_NS_SUM'',''AVN_ThuNhapKhac_TrongThang'',''AVN_TongThuong_TrongThang'',''AVN_TruyLinh'',''AVN_BHXH_C'',''AVN_BHYT_C'',''AVN_BHTN_C'',''AVN_BHXH_BHYT_BHTN_C'',''AVN_Deduction_SUM'',''AVN_TruyThu'',''AVN_BHXH_E'',''AVN_BHYT_E'',''AVN_BHTN_E'',''AVN_TT_BHYT_E'',''AVN_ThuePIT'',''AVN_LuongThuong_SUM'',''AVN_ThuNhapChiuThue'',''AVN_GiamTruTax'',''AVN_TinhThue'',''AVN_GrossIncome'',''AVN_AdvancePay'',''AVN_NetIncome'' )'

SET @ElementPivot = '[AVN_LCB],[AVN_NCTL],[AVN_TONGLUONGNGAYCONG],[AVN_PCTheoLuong_SUM],[AVN_OT_SUM],[AVN_NS_SUM],[AVN_ThuNhapKhac_TrongThang],[AVN_TongThuong_TrongThang],[AVN_TruyLinh],[AVN_BHXH_C],[AVN_BHYT_C],[AVN_BHTN_C],[AVN_BHXH_BHYT_BHTN_C],[AVN_Deduction_SUM],[AVN_TruyThu],[AVN_BHXH_E],[AVN_BHYT_E],[AVN_BHTN_E],[AVN_TT_BHYT_E],[AVN_ThuePIT],[AVN_LuongThuong_SUM],[AVN_ThuNhapChiuThue],[AVN_GiamTruTax],[AVN_TinhThue],[AVN_GrossIncome],[AVN_AdvancePay],[AVN_NetIncome]'

SET @getdata ='


-----Lay Ten tieng Anh Co cau truc thuoc-----------------

SELECT	OrgstructureID,E_BRANCH_CODE, E_UNIT_CODE, E_DIVISION_CODE, E_DEPARTMENT_CODE, E_TEAM_CODE
INTO	#UnitCode 
FROM	dbo.Cat_OrgUnit WHERE IsDelete IS NULL 

SELECT	a.ID AS OrgstructureID ,a.Code,a.OrderNumber, b.OrgStructureName, ROW_NUMBER() OVER(PARTITION BY a.Code ORDER BY a.DateUpdate DESC) AS rk	 
INTO	#NamEnglish1 
FROM	dbo.Cat_OrgStructure a LEFT JOIN dbo.Cat_OrgStructure_Translate b ON a.iD = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL

SELECT * INTO #NamEnglish FROM #NamEnglish1 WHERE rk= 1

SELECT		a.OrgstructureID, b.OrgStructureName AS DivisionName, c.OrgStructureName AS CenterName, d.OrgStructureName AS DepartmentName, e.OrgStructureName AS SectionName, f.OrgStructureName AS UnitName
			, b.OrderNumber AS DivisionOrder,  c.OrderNumber AS CenterOrder,  d.OrderNumber AS DepartmentOrder,  e.OrderNumber AS SectionOrder, f.OrderNumber AS UnitOrder
INTO		#NameEnglishORG
FROM		#UnitCode a
LEFT JOIN	#NamEnglish b
	ON		a.E_BRANCH_CODE = b.Code
LEFT JOIN	#NamEnglish c
	ON		a.E_UNIT_CODE = c.Code
LEFT JOIN	#NamEnglish d
	ON		a.E_DIVISION_CODE = d.Code
LEFT JOIN	#NamEnglish e
	ON		a.E_DEPARTMENT_CODE = e.Code
LEFT JOIN	#NamEnglish f
	ON		a.E_TEAM_CODE = f.Code


CREATE TABLE #tblPermission (id uniqueidentifier primary key )
INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Sal_PayrollTable'''+'

--------------------------------Lay bang luong chinh-------------------------------------
select spt.* into #PayrollTable from Sal_PayrollTable spt join #tblPermission tb on spt.ProfileID = tb.ID
where isdelete is null '+@MonthYear+'

--- Lay ngay bat dau va ket thuc ky luong
DECLARE @DateStart DATETIME, @DateEnd DATETIME, @StartMonth  DATETIME
SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYear+'


'
SET @query = N'
------------------------------------Bang luong-------------------------------------------

select * into #Results from 
(
-------Ham pivot-------------------
select		hp.ID,CodeEmp,ProfileName,NameEnglish,DateHire,hp.IDNo,spt.MonthYear,  GETDATE() AS DateExport
			,ISNULL(cetl.EN,'' '') as EmploymentType
			, ISNULL(csct.SalaryClassName,'' '') AS SalaryClassName
			, ISNULL(neorg.DivisionName,'' '') AS DivisionName, ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
			, ISNULL(neorg.DivisionOrder,'' '') AS DivisionOrder, ISNULL(neorg.CenterOrder,'' '') AS CenterOrder , ISNULL(neorg.DepartmentOrder,'' '') AS DepartmentOrder ,ISNULL(neorg.SectionOrder,'' '') AS SectionOrder,ISNULL(neorg.UnitOrder,'' '') AS UnitOrder
			, ISNULL(cetl.EN,''NULL'') as EmploymentTypeGroup
			,spt.AccountNo,spti.Code,cast(dbo.VnrDecrypt(E_Value) as float) as Amount, CASE WHEN spt.IsCash = 1 THEN N''Tiền Mặt'' ELSE N''Chuyển khoản'' END AS PayPaidType
			,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "spt.EmploymentType", NULL AS "spt.PositionID", NULL AS "spt.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "AmountCondittion"
			,NULL AS "spt.WorkPlaceID", NULL AS "spt.SalaryClassID",NULL AS "sup.EmpStatus"
FROM		#PayrollTable spt 
LEFT JOIN	Sal_PayrollTableItem spti 
	ON		spt.ID = spti.PayrollTableID AND spti.Isdelete IS NULL
LEFT JOIN	Hre_Profile hp 
	ON		spt.profileid= hp.id 
LEFT JOIN	Cat_OrgStructure cos 
	ON		spt.OrgStructureID = cos.ID
LEFT JOIN	Cat_OrgUnit cou 
	ON		spt.OrgStructureID = cou.OrgStructureID
LEFT JOIN	Cat_Position cp 
	ON		spt.PositionID = cp.ID and cp.IsDelete is null
LEFT JOIN	#NameEnglishORG neorg 
	ON		neorg.OrgStructureID = spt.OrgStructureID
LEFT JOIN	Cat_SalaryClass_Translate csct 
	ON		csct.OriginID = spt.SalaryClassID
OUTER APPLY (
			SELECT	TOP(1) cetl.EN, cetl.VN
			FROM	Cat_EnumTranslate cetl
			WHERE	cetl.EnumKey = spt.EmploymentType 
					AND cetl.EnumName = ''EmploymentType'' AND cetl.IsDelete is null
			ORDER BY DateUpdate
			) cetl
--LEFT JOIN	Cat_Bank cb on spt.BankID = cb.ID and cb.IsDelete is null
WHERE		spt.isdelete is null 
			AND hp.isdelete is null 
			AND ( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart )
			'+@condition+' '+@Element+'
) T

Pivot 
(
sum(Amount) for code  in ( '+@ElementPivot+' )
) P
----------Ham Pivot------------------------------------

'

set @queryPageSize = N'

select	*
from	#Results
where	CodeEmp IS NOT NULL
		'+ISNULL(@PayPaidType,'')+' 

order by DivisionName,DivisionOrder, CenterName,CenterOrder,DepartmentName,DepartmentOrder, SectionName,SectionOrder, EmploymentType,UnitName,UnitOrder,SalaryClassName, ProfileName


drop table #PayrollTable
drop table #Results
DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG

'
print(@getdata)
PRINT (@query)
PRINT(@queryPageSize)
exec(@getdata + @query + ' ' + @queryPageSize)

END

--[rpt_payroll_monthly]