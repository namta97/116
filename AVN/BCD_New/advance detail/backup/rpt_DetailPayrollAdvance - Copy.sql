ALTER proc rpt_DetailPayrollAdvance
@condition nvarchar(max) =  " and (MonthYear = '2021-09-01')",
@PageIndex int = 1,
@PageSize int = 5000,
@Username varchar(100) = 'khang.nguyen'
as
begin

IF @condition = ' ' 
begin
set @condition =  ' and (MonthYear = ''2021-09-01'') '
END
declare @query nvarchar(max)
declare @query1 nvarchar(max)
declare @query2 nvarchar(max)
declare @query3 nvarchar(max)
declare @queryPageSize nvarchar(max)

declare @str varchar(max)
declare @countrow int
declare @row int
declare @index int
declare @ID varchar(200)
 ----Xu ly Amount Condition----
declare @tempID nvarchar(Max)
declare @tempCodition nvarchar(Max)
DECLARE @MonthYear nvarchar(50) = ' '
DECLARE @CheckData nvarchar(50) = ' '
declare @AmountCondition nvarchar(100) = ''
declare @PayPaidType varchar(100) = ''
 -- xử lý tách dk
	 set @str = REPLACE(@condition,',','@')
	 set @str = REPLACE(@str,'and (',',')
	 SELECT ID into #tableTempCondition FROM SPLIT_To_VARCHAR (@str)
	 set @row = (SELECT count(ID) FROM SPLIT_To_VARCHAR (@str))
	 set @countrow = 0
	 set @index = 0

	 while @row > 0
	 begin
		set @index = 0
		set @ID = (select top 1 ID from #tableTempCondition)
		set @tempID = replace(@ID,'@',',')
		set @index = 0
		-------
		set @index = charindex('MonthYear = ',@tempID,0) 
		if(@index > 0)
		begin
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @MonthYear = @tempCodition
		end
		-------
		set @index = charindex('CheckData ',@tempID,0)
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @CheckData = REPLACE(@tempCodition,'CheckData','')
			set @CheckData = REPLACE(@CheckData,'like N','')
			set @CheckData = REPLACE(@CheckData,'%','')
		end
		-------
		set @index = charindex('(AmountCondition ','('+@tempID,0)
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @AmountCondition = REPLACE(@tempCodition,'(AmountCondition in ','')
			set @AmountCondition = REPLACE(@AmountCondition,',',' OR ')
			set @AmountCondition = REPLACE(@AmountCondition,'))',')')
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
	 drop table #tableTempCondition

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

if(@CheckData is not null and @CheckData != '')
BEGIN
	SET @index = charindex('E_POSTS',@CheckData,0) 
	if(@index > 0)
	BEGIN
	SET @CheckData = REPLACE(@CheckData,'''E_POSTS''','UnusualPayID is not null')
	END
	set @index = charindex('E_UNEXPECTED',@CheckData,0) 
	if(@index > 0)
	BEGIN
	set @CheckData = REPLACE(@CheckData,'''E_UNEXPECTED''','UnusualPayID is null')
	END
END

if(@AmountCondition is not null and @AmountCondition != '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondition,0) 
	if(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_EqualToZero''','AdvanceAmount = 0')
	END
	set @index = charindex('E_LessThanZero',@AmountCondition,0) 
	if(@index > 0)
	BEGIN
	set @AmountCondition = REPLACE(@AmountCondition,'''E_LessThanZero''','AdvanceAmount < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondition,0) 
	if(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_GreaterThanZero''','AdvanceAmount > 0')
	END
end
--[rpt_DetailPayrollAdvance]
set @query = N'
	DECLARE @tblPermission TABLE (id uniqueidentifier primary key )
	INSERT INTO @tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'
	
	----Bang luong
	select s.* into #UnusualPay from Sal_UnusualPay s join @tblPermission tb on s.ProfileID = tb.ID
	where isdelete is null '+@MonthYear+'

	----Ngay len chinh thuc
	select ProfileID,DateEffective,ROW_NUMBER ( ) OVER (PARTITION BY ProfileID order by ProfileID,DateEffective desc) as flag
	into #LenChinhThuc
	from Hre_WorkHistory
	where isdelete is null and TypeOfTransferID in (SELECT id FROM Cat_NameEntity WHERE isdelete IS NULL AND NameEntityType = ''E_Typeoftransfer'' and Code = ''CTOP'')

	--- Lay ngay bat dau va ket thuc ky luong
	DECLARE @DateStart DATETIME, @DateEnd DATETIME, @StartMonth  DATETIME
	SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYear+'

	---Ngay ket thuc ky ung
	DECLARE @UnusualDay INT
	DECLARE @DateEndAdvance DATETIME

	SELECT @UnusualDay = value1 from Sys_AllSetting where isdelete is null and Name like ''%AL_Unusualpay_DaykeepUnusualpay%''
	SET @DateEndAdvance = DATEADD(DAY,@UnusualDay -1,@StartMonth)


'
set @query1 = N'
	;WITH Sal_UnusualPay_New AS
	(
	select 
	hp.ID AS ProfileID , hp.CodeEmp, hp.ProfileName
	,E_BRANCH AS DivisionName,E_UNIT AS CenterName,E_DIVISION AS DepartmentName,E_DEPARTMENT AS SectionName,E_TEAM AS UnitName
	,sc.SalaryClassName,cp.PositionName,cj.JobTitleName, cetl.VN AS EmploymentType,cetl2.VN AS LaborType,cne.NameEntityName AS EmployeeGroupName, cwp.WorkPlaceName
	,hp.DateHire,hp.DateEndProbation , ct.DateEffective as LenChinhThuc, hp.DateQuit
	,dbo.fnc_NumberOfExceptWeekends(@DateStart,DateHire-1) as DaysBeforeHire,dbo.fnc_NumberOfExceptWeekends(DateQuit,@DateEndAdvance) DaysAfterQuit
	,cetl3.VN AS EmpStatus,sup.MonthYear
	,ISNULL(sup.Amount,0) AS AdvanceAmount,dn.VN as ReasonNotAdvance
	,supi.Amount AS PayPaidType
	, ROW_NUMBER() OVER(PARTITION BY hwh.ProfileID ORDER BY hwh.DateEffective DESC) AS rk,sup.ID AS UnusualPayID
	from Hre_Profile hp
	LEFT JOIN Hre_WorkHistory hwh ON hp.ID = hwh.ProfileID
	left join #UnusualPay sup on sup.profileid=hp.id 
	left join Att_CutOffDuration a on sup.CutOffDurationID=a.ID 
	left join Cat_SalaryClass sc on hwh.SalaryClassID = sc.id
	left join Cat_JobTitle cj on hwh.JobTitleID = cj.ID
	left join #LenChinhThuc ct on hwh.ProfileID = ct.ProfileID and ct.flag = ''1''
	left join Cat_OrgStructure cos on hwh.OrganizationStructureID = cos.ID
	left join Cat_OrgUnit cu on hwh.OrganizationStructureID = cu.OrgStructureID
	left join Cat_Position cp on hwh.PositionID = cp.ID
	left join Cat_EmployeeType et on hp.EmpTypeID = et.ID
	left join Cat_Bank cb on sup.BankID = cb.ID
	left join Sal_SalaryInformation sai on sai.ProfileID = hwh.ProfileID and sai.IsDelete is null
	left join Hre_StopWorking hs on hwh.ProfileID = hs.profileID and hs.isdelete is null and hs.Status=''E_APPROVED''
	LEFT JOIN Cat_WorkPlace cwp ON cwp.ID = hwh.WorkPlaceID
	LEFT JOIN Cat_NameEntity cne ON cne.ID = hwh.EmployeeGroupID
	left join Cat_DataNote dn on sup.ReasonNotPayAdvance = dn.EnumKey
	LEFT JOIN	Sal_UnusualPayItem supi
		ON		supi.UnusualPayID = sup.ID 
				AND supi.Code = ''SAL_SALARYINFORMATION_ISCASH_BYUNUSUALPAY'' AND supi.Isdelete IS NULL

	'
SET @query2= N'
	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = hwh.EmploymentType 
						AND cetl.EnumName = ''EmploymentType'' AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl

	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = hwh.LaborType 
						AND cetl.EnumName = ''LaborType'' AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl2

	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = sup.EmpStatus 
						AND cetl.EnumKey in (''E_PROFILE_ACTIVE'',''E_PROFILE_QUIT'',''E_PROFILE_NEW'') AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl3
	WHERE		hwh.IsDelete is null
		AND		hwh.DateEffective <= @DateEndAdvance
		AND		hwh.Status = ''E_APPROVED''
		AND		hp.IsDelete is null
		AND		( hp.DateQuit IS NULL OR hp.DateQuit > @DateEndAdvance)
		AND		hp.DateHire <= @DateEndAdvance
				'+ISNULL(@condition,'')+'
	) 
	Select *
	into #Sal_UnusualPay_New
	from Sal_UnusualPay_New 
	where rk = 1
	'+ISNULL(@PayPaidType,'')+'
	'+ISNULL(@CheckData,'')+ ' 
	'+ISNULL(@AmountCondition,'')+'
	print(''#Sal_Payrolltable_New'');

	SELECT sup.*
	,usi41.Amount as ''PaidWorkDayP'',usi1.Amount as ''BasicAdvanceAmount'',dbo.fnc_NumberOfExceptWeekends(@DateStart,@DateEndAdvance) as ''ATT_STD_DAY'',usi3.Amount as ''COUNT_DAY_BEFORE_JOIN''
	,usi4.Amount as ''HLD'',usi5.Amount as ''A'',usi6.Amount as ''AN'',usi7.Amount as ''AN1'',usi8.Amount as ''ADV'',usi9.Amount as ''OTC'',usi10.Amount as ''F'',usi11.Amount as ''M'',usi12.Amount as ''CM'',usi13.Amount as ''ML'',usi14.Amount as ''MLT'',usi15
	.Amount as ''C'',usi16.Amount as ''MH1'',usi17.Amount as ''MH2'',usi18.Amount as ''DS1'',usi19.Amount as ''DS2'',usi20.Amount as ''SIB7'',usi21.Amount as ''SIB6'',usi22.Amount as ''SS'',usi23.Amount as ''NAT'',usi24.Amount as ''CS3'',usi25.Amount as ''CS7''
	,usi26.Amount as ''SIB4'',usi27.Amount as ''LS'',usi28.Amount as ''SM'',usi29.Amount as ''RA'',usi30.Amount as ''FP'',usi31.Amount as ''DL'',usi32.Amount as ''NP'',usi33.Amount as ''WP'',usi34.Amount as ''WP1''
	,usi35.Amount as ''BTOL'',usi36.Amount as ''BTOS'',usi37.Amount as ''BTL'',usi38.Amount as ''BTS1'',usi39.Amount as ''BTS2'',usi40.Amount as ''WTH'',usi43.amount as ''ATT_ATTENDANCETABLEITEM_SUM_ACTUALWORKINGHOURS_BYUNUSUALPAY''
	,usi44.Amount as ''ATTI_SUM_TOTAL_LEAVE_UNPAIDDAY_BYUNUSUALPAY'',usi40.Amount as ''WFH'',usi41.Amount as ''ATTI_SUM_TOTAL_LEAVE_PAIDDAY_BYUNUSUALPAY''
	,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber
	into #Results
	from #Sal_UnusualPay_New sup
'
set @query3 = N'
	left join Sal_UnusualPayItem usi1 on sup.UnusualPayID = usi1.UnusualPayID and usi1.code = ''SAL_BASIC_ADVANCESALARY''
	left join Sal_UnusualPayItem usi3 on sup.UnusualPayID = usi3.UnusualPayID and usi3.code = ''COUNT_DAY_BEFORE_JOIN''
	left join Sal_UnusualPayItem usi4 on sup.UnusualPayID = usi4.UnusualPayID and usi4.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_HLD_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi5 on sup.UnusualPayID = usi5.UnusualPayID and usi5.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_A_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi6 on sup.UnusualPayID = usi6.UnusualPayID and usi6.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_AN_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi7 on sup.UnusualPayID = usi7.UnusualPayID and usi7.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_AN1_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi8 on sup.UnusualPayID = usi8.UnusualPayID and usi8.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_ADV_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi9 on sup.UnusualPayID = usi9.UnusualPayID and usi9.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_OTC_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi10 on sup.UnusualPayID = usi10.UnusualPayID and usi10.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_F_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi11 on sup.UnusualPayID = usi11.UnusualPayID and usi11.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_M_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi12 on sup.UnusualPayID = usi12.UnusualPayID and usi12.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_CM_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi13 on sup.UnusualPayID = usi13.UnusualPayID and usi13.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_ML_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi14 on sup.UnusualPayID = usi14.UnusualPayID and usi14.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_MLT_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi15 on sup.UnusualPayID = usi15.UnusualPayID and usi15.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_C_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi16 on sup.UnusualPayID = usi16.UnusualPayID and usi16.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_MH1_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi17 on sup.UnusualPayID = usi17.UnusualPayID and usi17.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_MH2_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi18 on sup.UnusualPayID = usi18.UnusualPayID and usi18.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_DS1_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi19 on sup.UnusualPayID = usi19.UnusualPayID and usi19.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_DS2_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi20 on sup.UnusualPayID = usi20.UnusualPayID and usi20.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_SIB7_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi21 on sup.UnusualPayID = usi21.UnusualPayID and usi21.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_SIB6_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi22 on sup.UnusualPayID = usi22.UnusualPayID and usi22.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_SS_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi23 on sup.UnusualPayID = usi23.UnusualPayID and usi23.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_NAT_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi24 on sup.UnusualPayID = usi24.UnusualPayID and usi24.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_CS3_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi25 on sup.UnusualPayID = usi25.UnusualPayID and usi25.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_CS7_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi26 on sup.UnusualPayID = usi26.UnusualPayID and usi26.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_SIB4_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi27 on sup.UnusualPayID = usi27.UnusualPayID and usi27.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_LS_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi28 on sup.UnusualPayID = usi28.UnusualPayID and usi28.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_SM_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi29 on sup.UnusualPayID = usi29.UnusualPayID and usi29.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_RA_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi30 on sup.UnusualPayID = usi30.UnusualPayID and usi30.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_FP_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi31 on sup.UnusualPayID = usi31.UnusualPayID and usi31.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_DL_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi32 on sup.UnusualPayID = usi32.UnusualPayID and usi32.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_NP_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi33 on sup.UnusualPayID = usi33.UnusualPayID and usi33.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_WP_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi34 on sup.UnusualPayID = usi34.UnusualPayID and usi34.code = ''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_WP1_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi35 on sup.UnusualPayID = usi35.UnusualPayID and usi35.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_BTOL''
	left join Sal_UnusualPayItem usi36 on sup.UnusualPayID = usi36.UnusualPayID and usi36.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_BTOS''
	left join Sal_UnusualPayItem usi37 on sup.UnusualPayID = usi37.UnusualPayID and usi37.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_BTL''
	left join Sal_UnusualPayItem usi38 on sup.UnusualPayID = usi38.UnusualPayID and usi38.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_BTS1''
	left join Sal_UnusualPayItem usi39 on sup.UnusualPayID = usi39.UnusualPayID and usi39.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_BTS2''
	left join Sal_UnusualPayItem usi40 on sup.UnusualPayID = usi40.UnusualPayID and usi40.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_WFH''
	left join Sal_UnusualPayItem usi41 on sup.UnusualPayID = usi41.UnusualPayID and usi41.code = ''ATTI_SUM_TOTAL_LEAVE_PAIDDAY_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi43 on sup.UnusualPayID = usi43.UnusualPayID and usi43.code = ''ATT_ATTENDANCETABLEITEM_SUM_ACTUALWORKINGHOURS_BYUNUSUALPAY''
	left join Sal_UnusualPayItem usi44 on sup.UnusualPayID = usi44.UnusualPayID and usi44.code = ''ATTI_SUM_TOTAL_LEAVE_UNPAIDDAY_BYUNUSUALPAY''
'

set @queryPageSize = N'
	SELECT
	RowNumber AS STT
	,ProfileID,CodeEmp,ProfileName
	,DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName
	,SalaryClassName,PositionName,JobTitleName, EmploymentType,LaborType,EmployeeGroupName,WorkPlaceName
	,DateHire,DateEndProbation,LenChinhThuc,DateQuit,DaysBeforeHire,DaysAfterQuit
	,EmpStatus,MonthYear,ReasonNotAdvance,PayPaidType
	,CAST(BasicAdvanceAmount AS int) as "BasicAdvanceAmount",AdvanceAmount,ATT_STD_DAY
	,CAST(COUNT_DAY_BEFORE_JOIN AS float) as COUNT_DAY_BEFORE_JOIN,CAST(PaidWorkDayP AS float) as PaidWorkDayP,CAST(HLD AS float) as HLD
	--,CAST(ATTI_SUM_TOTAL_LEAVE_PAIDDAY_BYUNUSUALPAY AS float)-CAST(WFH AS float)-CAST(BTS1 AS float)-CAST(BTS2 AS float)-CAST(BTL AS float)-CAST(BTOS AS float)-CAST(BTOL AS float)-CAST(M AS float)-CAST(CM AS float)-CAST(F AS float)-CAST(ML AS float)-CAST(MLT AS float)-CAST(C AS float)-CAST(OTC AS float)-CAST(A AS float)-CAST(AN AS float)-CAST(AN1 AS float)-CAST(ADV AS float) as ATT_ATTENDANCETABLEITEM_SUM_ACTUALWORKINGHOURS_BYUNUSUALPAY
	,ATT_ATTENDANCETABLEITEM_SUM_ACTUALWORKINGHOURS_BYUNUSUALPAY
	,CAST(WFH AS float) as WFH
	,CAST(BTS1 AS float)+CAST(BTS2 AS float)+CAST(BTL AS float)+CAST(BTOS AS float)+CAST(BTOL AS float) as "TongSoNgayCongTacP"
	,CAST(BTS1 AS float) as BTS1,CAST(BTS2 AS float) as BTS2,CAST(BTL AS float) as BTL,CAST(BTOS AS float) as BTOS,CAST(BTOL AS float) as BTOL
	,CAST(AN AS float)+CAST(AN1 AS float)+CAST(ADV AS float) as "TongSoNgayPhepNamP"
	,CAST(AN AS float) as AN,CAST(AN1 AS float) as AN1,CAST(ADV AS float) as ADV
	,CAST(M AS float)+CAST(CM AS float)+CAST(F AS float)+CAST(ML AS float)+CAST(MLT AS float)+CAST(C AS float)+CAST(OTC AS float)+CAST(A AS float) as "PhepHuongLuongKhac"
	,CAST(M AS float) as M,CAST(CM AS float) as CM,CAST(F AS float) as F,CAST(ML AS float) as ML,CAST(MLT AS float) as MLT,CAST(C AS float) as C,CAST(OTC AS float) as OTC,CAST(A AS float) as A,CAST(DL AS float) as DL
	,CAST(ATTI_SUM_TOTAL_LEAVE_UNPAIDDAY_BYUNUSUALPAY AS float) + CAST(DL AS float) as "ATTI_SUM_TOTAL_LEAVE_UNPAIDDAY_BYUNUSUALPAY"
	,CAST(NP AS float) as NP,CAST(WP AS float) as WP,CAST(WP1 AS float) as WP1,CAST(RA AS float) as RA,CAST(SS AS float) as SS,CAST(LS AS float) as LS,CAST(CS3 AS float) as CS3,CAST(CS7 AS float) as CS7,CAST(MH1 AS float) as MH1,CAST(DS1 AS float) as DS1,CAST(DS2 AS float) as DS2,CAST(NAT AS float) as NAT,CAST(FP AS float) as FP,CAST(SM AS float) as SM,CAST(SIB4 AS float) as SIB4,CAST(SIB6 AS float) as SIB6,CAST(SIB7 AS float) as SIB7
	,getdate() as DateExport
	,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL as "hwh.PositionID",NULL as "hwh.JobTitleID",NULL as "hwh.SalaryClassID"
	,NULL as "hwh.WorkPlaceID",NULL as "spt.EmpStatus",NULL as "hwh.EmploymentType",NULL as "hp.DateHire",NULL as "hp.DateEndProbation",NULL as "hp.DateQuit"
	,NULL as "AmountCondition",NULL as "CheckData",NULL as "hwh.LaborType",NULL as "hwh.EmployeeGroupID"
	from #Results rs
	ORDER BY STT

	drop table #UnusualPay,#LenChinhThuc,#Results, #Sal_UnusualPay_New
'
print(@query)
print(@query1) 
print(@query2) 
print(@query3) 
print(@queryPageSize)
exec(@query + @query1 + @query2 + @query3 + @queryPageSize)

END
--rpt_DetailPayrollAdvance