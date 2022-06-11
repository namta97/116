---Nam Ta: 4/8/2021: BC Luong tam ung
ALTER proc rpt_salary_report

@condition nvarchar(max) = " and (MonthYear = '2022-03-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'Khang.Nguyen'
as
BEGIN
	
DECLARE @str nvarchar(max)
DECLARE @countrow int
DECLARE @row int
DECLARE @index int
DECLARE @ID nvarchar(500)
DECLARE @TempID nvarchar(max)
DECLARE @TempCondition nvarchar(max)
DECLARE @Top varchar(20) = ' '

if ltrim(rtrim(@Condition)) = '' OR @Condition is null
begin
		set @Top = ' top 0 ';
		SET @condition =  ' and (MonthYear = ''2022-03-01'') '
end;

----Condition----
DECLARE @MonthYearCondition VARCHAR(100) = ' '
DECLARE @AmountCondition nvarchar(100) = ''
DECLARE @PayPaidType nvarchar(100) = ''

-- cat dieu kien
set @str = REPLACE(@condition,',','@')
set @str = REPLACE(@str,'and (',',')
SELECT ID into #tableTempCondition FROM SPLIT_To_NVARCHAR (@str)
set @row = (SELECT count(ID) FROM SPLIT_To_NVARCHAR (@str))
set @countrow = 0
set @index = 0
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
		set @TempCondition = 'and ('+@tempID
		set @MonthYearCondition = @TempCondition
	end
         
	SET @index = charindex('(GroupBank ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @condition = REPLACE(@condition,'(Groupbank ','(cb.Groupbank ')
	END
            
	set @index = charindex('(BankName ','('+@tempID,0) 
	if(@index > 0)
	begin
		set @condition = REPLACE(@condition,'(BankName ','(cb.BankName ')
	END

	set @index = charindex('(ProfileName ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
	END

	SET @index = CHARINDEX('(CodeEmp ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(CodeEmp ','(hp.CodeEmp ')
	END

	SET @index = CHARINDEX('(condi.EmploymentType ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.EmploymentType ','(hwh.EmploymentType ')
	END
    
	SET @index = CHARINDEX('(condi.SalaryClassID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.SalaryClassID ','(hwh.SalaryClassID ')
	END

	SET @index = CHARINDEX('(condi.PositionID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.PositionID ','(hwh.PositionID ')
	END
	
	SET @index = CHARINDEX('(condi.JobTitleID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.JobTitleID ','(hwh.JobTitleID ')
	END
	
	SET @index = CHARINDEX('(condi.WorkPlaceID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.WorkPlaceID ','(hwh.WorkPlaceID ')
	END
	
	SET @index = CHARINDEX('(condi.EmployeeGroupID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.EmployeeGroupID ','(hwh.EmployeeGroupID ')
	END
		
	SET @index = CHARINDEX('(condi.LaborType ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.LaborType ','(hwh.LaborType ')
	END

	SET @index = CHARINDEX('(condi.EmpStatus ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.EmpStatus ','(spt.EmpStatus ')
	END
	
	SET @index = CHARINDEX('(condi.CostCentreID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.CostCentreID ','(hwh.CostCentreID ')
	END

	SET @index = charindex('(PayPaidType ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @PayPaidType = @TempCondition
	END

	set @index = charindex('(AmountCondition ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @AmountCondition = REPLACE(@TempCondition,'(AmountCondition in ','')
		set @AmountCondition = REPLACE(@AmountCondition,',',' OR ')
		set @AmountCondition = REPLACE(@AmountCondition,'))',')')
	END

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1
	END
     
	drop table #tableTempCondition


--- Giá trị
IF (@AmountCondition is not null and @AmountCondition <> '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_EqualToZero''','NetInCome = 0')
	END
	SET @index = charindex('E_LessThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_LessThanZero''','NetInCome < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_GreaterThanZero''','NetInCome > 0')	
	END
END

-- Hình thức thanh toán
IF (@PayPaidType is not null AND @PayPaidType <> '')
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


DECLARE @getdata VARCHAR(max)
declare @query nvarchar(max)
declare @UnionData varchar(max)
DECLARE @pivot VARCHAR(max)
declare @queryPageSize varchar(max)	

DECLARE @Element VARCHAR(max)
DECLARE @ElementPivot VARCHAR(max)

SET @Element = ' AND spti.Code IN( ''AVN_NCTL'',''AVN_LCB'',''AVN_GROSS_SALARY'',''AVN_OT_SUM_DEDUCT'',''AVN_NS_SUM_DEDUCT'',''AVN_PC_SUM_DEDUCTION'',''AVN_PC_SUM_DEDUCTION_MAU3'',''AVN_PCCV_DEDUCTION'',''AVN_PCGD_DEDUCTION'',''AVN_PCLCB_DEDUCTION''
,''AVN_PCCVU_DEDUCTION'',''AVN_PCCVBL_DEDUCTION'',''AVN_PCLT_DEDUCTION'',''AVN_PCNO2_DEDUCTION'',''AVN_PCNO_DEDUCTION'',''AVN_PCTH_DEDUCTION'',''AVN_PCTNIEN_BL_DEDUCTION'',''AVN_PCNL_DEDUCTION'',''AVN_TCDL_DEDUCTION'',''AVN_SMAA_DEDUCTION'',''AVN_PCDV_DEDUCTION''
,''AVN_Other_Income_Total'',''AVN_AUVP_SUM'',''AVN_AUCT_SUM'',''AVN_GXE'',''AVN_LTRU'',''AVN_TCCTP'',''AVN_DLCT'',''AVN_KSK'',''AVN_SFSUPPORT'',''AVN_WEDA'',''AVN_BIRA'',''AVN_FURA'',''AVN_OTC'',''AVN_TCCC'',''AVN_TCKC'',''AVN_DCCT1''
,''AVN_DCCT2'',''AVN_KSKDK'',''AVN_KSKDB'',''AVN_GIFT'',''AVN_THEDT'',''AVN_DPHUC'',''AVN_GIFT_CD'',''AVN_DLCV'',''AVN_DLGD'',''AVN_NMAT'',''AVN_TCTT'',''AVN_INTAX'',''AVN_AN'',''AVN_TNRR'',''AVN_F0SUPPORT'',''AVN_Other'',''AVN_IA_BHXH_BHYT_BHTN'',''AVN_IA_TU_BHYT''
,''AVN_TETBONUS'',''AVN_SLR13'',''AVN_S_BONUS'',''AVN_TL_2_9'',''AVN_TL_1_1'',''AVN_LT_REWARD_10_15_20_25_30'',''AVN_BHXH_C'',''AVN_BHYT_C'',''AVN_BHTN_C'',''AVN_TOTAL_AMOUNT'',''AVN_DEDUCTION_TOTAL'',''AVN_PCD'',''AVN_D_THENV'',''AVN_D_PCTT''
,''AVN_D_INTAX'',''AVN_D_AN'',''AVN_D_OTHER'',''AVN_DA_BHXH_BHYT_BHTN'',''AVN_DA_TT_BHYT'',''AVN_BHXH_E'',''AVN_BHYT_E'',''AVN_BHTN_E'',''AVN_TT_BHYT_E'',''AVN_TongPIT'',''AVN_GrossIncome'',''AVN_AdvancePay'',''AVN_NetIncome'')'

SET @ElementPivot = ' [AVN_NCTL],[AVN_LCB],[AVN_GROSS_SALARY],[AVN_OT_SUM_DEDUCT],[AVN_NS_SUM_DEDUCT],[AVN_PC_SUM_DEDUCTION],[AVN_PC_SUM_DEDUCTION_MAU3],[AVN_PCCV_DEDUCTION],[AVN_PCGD_DEDUCTION],[AVN_PCLCB_DEDUCTION],[AVN_PCCVU_DEDUCTION],[AVN_PCCVBL_DEDUCTION]
,[AVN_PCLT_DEDUCTION],[AVN_PCNO2_DEDUCTION],[AVN_PCNO_DEDUCTION],[AVN_PCTH_DEDUCTION],[AVN_PCTNIEN_BL_DEDUCTION],[AVN_PCNL_DEDUCTION],[AVN_TCDL_DEDUCTION],[AVN_SMAA_DEDUCTION],[AVN_PCDV_DEDUCTION],[AVN_Other_Income_Total],[AVN_AUVP_SUM]
,[AVN_AUCT_SUM],[AVN_GXE],[AVN_LTRU],[AVN_TCCTP],[AVN_DLCT],[AVN_KSK],[AVN_SFSUPPORT],[AVN_WEDA],[AVN_BIRA],[AVN_FURA],[AVN_OTC],[AVN_TCCC],[AVN_TCKC],[AVN_DCCT1],[AVN_DCCT2],[AVN_KSKDK],[AVN_KSKDB],[AVN_GIFT],[AVN_THEDT],[AVN_DPHUC]
,[AVN_GIFT_CD],[AVN_DLCV],[AVN_DLGD],[AVN_NMAT],[AVN_TCTT],[AVN_INTAX],[AVN_AN],[AVN_TNRR],[AVN_F0SUPPORT],[AVN_Other],[AVN_IA_BHXH_BHYT_BHTN],[AVN_IA_TU_BHYT],[AVN_TETBONUS],[AVN_SLR13],[AVN_S_BONUS],[AVN_TL_2_9],[AVN_TL_1_1],[AVN_LT_REWARD_10_15_20_25_30]
,[AVN_BHXH_C],[AVN_BHYT_C],[AVN_BHTN_C],[AVN_TOTAL_AMOUNT],[AVN_DEDUCTION_TOTAL],[AVN_PCD],[AVN_D_THENV],[AVN_D_PCTT],[AVN_D_INTAX],[AVN_D_AN],[AVN_D_OTHER],[AVN_DA_BHXH_BHYT_BHTN],[AVN_DA_TT_BHYT],[AVN_BHXH_E],[AVN_BHYT_E],[AVN_BHTN_E]
,[AVN_TT_BHYT_E],[AVN_TongPIT],[AVN_GrossIncome],[AVN_AdvancePay],[AVN_NetIncome] '

SET @getdata ='

	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'

	--------------------------------Lay bang luong chinh-------------------------------------
	select spt.* into #Sal_PayrollTable from Sal_PayrollTable spt join #tblPermission tb on spt.ProfileID = tb.ID
	where isdelete is null '+@MonthYearCondition+'


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


	--- Lay ngay bat dau va ket thuc ky luong
	DECLARE @DateStart DATE, @DateEnd DATE, @StartMonth  DATE
	SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYearCondition+'

	--- split costcentre of orgstructure
 	SELECT		cos.ID as OrgstructureID,spl.CostCentreID 
	INTO		#OrgSplitCost
	FROM		dbo.Cat_OrgStructure cos
	OUTER APPLY ( SELECT id AS CostCentreID FROM SPLIT_To_NVARCHAR( cos.GroupCostCentreID) ) spl

	-- Lay du lieu qtct moi nhat trong thang
	if object_id(''tempdb..#Hre_WorkHistory'') is not null 
		drop table #Hre_WorkHistory;

	;WITH WorkHistory AS
	(
	select		' +@Top+ ' 
				*,ROW_NUMBER() OVER(PARTITION BY hwh.ProfileID ORDER BY hwh.DateEffective DESC) AS rk
	from		Hre_WorkHistory as hwh
	WHERE		hwh.IsDelete is null
				AND	hwh.DateEffective <= @DateEnd
				AND	hwh.Status = ''E_APPROVED''
	) 
	SELECT	*
	INTO	#Hre_WorkHistory
	FROM	WorkHistory 
	WHERE	rk = 1
	print(''#Hre_WorkHistory'');

'
SET @query = '
	------------------------------------Bang luong-------------------------------------------
	;WITH Sal_PayrollTable_new AS
	(
	select		' +@Top+ N'
				hp.ID AS ProfileID,hp.CodeEmp,hp.ProfileName,hp.NameEnglish,hp.DateHire
				--,ISNULL(neorg.DivisionName,'' '') AS DivisionName, ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
				,cou.E_BRANCH AS DivisionName, cou.E_UNIT AS CenterName, cou.E_DIVISION AS DepartmentName, cou.E_DEPARTMENT AS SectionName, cou.E_TEAM AS UnitName
				,ISNULL(neorg.DivisionOrder,-881507) AS DivisionOrder, ISNULL(neorg.CenterOrder,-771507) AS CenterOrder , ISNULL(neorg.DepartmentOrder,-661507) AS DepartmentOrder ,ISNULL(neorg.SectionOrder,-551507) AS SectionOrder
				,ISNULL(neorg.UnitOrder,-441507) AS UnitOrder
				,cost.Code AS CostCentreCode, cne.Code AS Group_CostCentreCode, cat.Code AS CostTypeCode
				,ISNULL(cast(dbo.VnrDecrypt(spti.E_Value) as float),0) as NetInCome, CASE WHEN spt.IsCash = 1 THEN N''Tiền Mặt'' ELSE N''Chuyển khoản'' END AS PayPaidType, spt.ID as PayrollTableID
				,spt.MonthYear
	FROM		#Sal_PayrollTable spt 
	INNER JOIN	Hre_Profile hp
		ON		spt.profileid= hp.id
	LEFT JOIN	#Hre_WorkHistory hwh 
		ON		hp.ID = hwh.ProfileID
	LEFT JOIN	#OrgSplitCost osc
		ON		osc.CostCentreID = hwh.CostCentreID
	LEFT JOIN	Cat_OrgStructure cos 
		ON		cos.ID = osc.OrgstructureID
	LEFT JOIN	Cat_OrgUnit cou
		ON		cou.OrgstructureID = osc.OrgstructureID
	LEFT JOIN	#NameEnglishORG neorg 
		ON		neorg.OrgStructureID = osc.OrgstructureID
	LEFT JOIN	Cat_CostCentre cost
		ON		Cost.ID = hwh.CostcentreID
	LEFT JOIN	Cat_NameEntity cne
		ON		cne.ID = cost.CostCentreGroupID
	LEFT JOIN	Cat_Position cp 
		ON		hwh.PositionID = cp.ID and cp.IsDelete is null
	LEFT JOIN	Cat_SalaryClass csc
		ON		csc.ID = hwh.SalaryClassID
	LEFT JOIN	Cat_AbilityTile cat
		ON		cat.ID = csc.AbilityTitleID
	LEFT JOIN	Sal_PayrollTableItem spti
		ON		Spti.PayrollTableID = spt.ID 
				AND spti.Code = ''AVN_NetIncome'' AND spti.Isdelete IS NULL
	WHERE		hp.IsDelete is null
		AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart )
		AND		hp.DateHire <= @DateEnd
		AND		exists (Select * from #tblPermission tpm where id = hp.id )
				'+@condition+' 
	)
	Select *
	into #Sal_PayrollTable_new
	from Sal_PayrollTable_new
	where 1 = 1
	'+ISNULL(@AmountCondition,'')+'
	'+ISNULL(@PayPaidType,'')+' 		

'
SET @UnionData = '			
	---Union DS phan bo chi phi		
	SELECT		*, CONVERT(DECIMAL(12,2),1) AS Rate, 0 AS LevelRoot, CONVERT(DECIMAL(12,2),1) AS NoEmployee
	INTO		#List_emp_costcentre_share
	FROM		#Sal_PayrollTable_new
	UNION		(
				SELECT		' +@Top+ N'
							sccs.ProfileID,ptn.CodeEmp,ptn.ProfileName,ptn.NameEnglish,ptn.DateHire
							--,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
							,cou.E_BRANCH AS DivisionName, cou.E_UNIT AS CenterName, cou.E_DIVISION AS DepartmentName, cou.E_DEPARTMENT AS SectionName, cou.E_TEAM AS UnitName
							,ISNULL(neorg.DivisionOrder,-881507) AS DivisionOrder, ISNULL(neorg.CenterOrder,-771507) AS CenterOrder , ISNULL(neorg.DepartmentOrder,-661507) AS DepartmentOrder ,ISNULL(neorg.SectionOrder,-551507) AS SectionOrder
							,ISNULL(neorg.UnitOrder,-441507) AS UnitOrder
							,cost.Code AS CostCentreCode,cne.Code AS Group_CostCentreCode, ptn.CostTypeCode AS CostTypeCode,ptn.NetInCome,ptn.PayPaidType, ptn.PayrollTableID,ptn.MonthYear
							,CONVERT(DECIMAL(12,2),sccs.Rate / 100) AS Rate,ROW_NUMBER() OVER(PARTITION BY sccs.ProfileID ORDER BY sccs.Rate DESC) AS LevelRoot, CONVERT(DECIMAL(12,2),1) AS NoEmployee
				FROM		Sal_CostCentreSal sccs
				LEFT JOIN	Cat_CostCentre Cost
					ON		Cost.ID = sccs.CostcentreID
				LEFT JOIN	Cat_NameEntity cne
					ON		cne.ID = cost.CostCentreGroupID
				LEFT JOIN	Cat_OrgUnit cou
					ON		cou.OrgstructureID = sccs.OrgstructureID
				LEFT JOIN	#NameEnglishORG neorg
					ON		neorg.OrgStructureID = sccs.OrgStructureID
				INNER JOIN	#Sal_PayrollTable_new ptn
					ON		ptn.ProfileID = sccs.ProfileID
				WHERE		sccs.DateStart <= @DateEnd AND ( sccs.DateEnd >= @DateStart OR sccs.DateEnd IS NULL )
							AND sccs.IsDelete IS NULL	
				)
	
	---Tinh tong Phan bo Rate cua tung nguoi
	SELECT		ProfileID, Sum(Rate) AS SumRateShare
	INTO		#SumRateShare
	FROM		#List_emp_costcentre_share
	WHERE		LevelRoot <> 0
	GROUP BY	ProfileID

	----Update lai rate cho dong thong tin goc
	UPDATE		r
	SET			r.Rate =  CASE WHEN 1 - ISNULL(s.SumRateShare,0) > 0 THEN 1 - ISNULL(s.SumRateShare,0) ELSE 0 END
	FROM		#List_emp_costcentre_share r
	INNER JOIN	#SumRateShare s
		ON		r.ProfileID = s.ProfileID
	WHERE		r.LevelRoot = 0

	---- Xoa dong goc neu Rate = 0
	DELETE		#List_emp_costcentre_share WHERE LevelRoot = 0 AND Rate = 0

	--Update NoEmployee theo Rate
	UPDATE		#List_emp_costcentre_share
	SET			NoEmployee = NoEmployee * Rate

	-- Dem so luong nv theo co cau truc thuoc
	SELECT		DivisionOrder,DivisionName, CenterOrder,CenterName,DepartmentOrder,DepartmentName,SectionOrder, SectionName,UnitOrder,UnitName,CostCentreCode,Group_CostCentreCode,CostTypeCode, SUM(NoEmployee) As NoEmployee
	INTO		#Group_Org_countemp
	FROM		#List_emp_costcentre_share lecs
	GROUP BY	DivisionOrder,DivisionName, CenterOrder,CenterName,DepartmentOrder,DepartmentName,SectionOrder, SectionName,UnitOrder,UnitName,CostCentreCode,Group_CostCentreCode,CostTypeCode

'
SET @pivot = N'
	SELECT		lecs.*
				,spti.Code,lecs.Rate * cast(dbo.VnrDecrypt(spti.E_Value) as float) as SalaryAmount
	INTO		#PayrollTable_share
	FROM		#List_emp_costcentre_share lecs
	LEFT JOIN	Sal_PayrollTableItem spti 
		ON		lecs.PayrollTableID = spti.PayrollTableID
	WHERE		spti.Isdelete IS NULL
				'+@Element+'

	----------Ham Pivot-----------
	SELECT		*
	INTO		#PayrollTable_pivot
	FROM
			(	
			SELECT		DivisionOrder,DivisionName,CenterOrder,CenterName,DepartmentOrder,DepartmentName,SectionOrder, SectionName,UnitOrder,UnitName,CostCentreCode,Group_CostCentreCode,CostTypeCode,MonthYear,Code,SalaryAmount, CONVERT(DECIMAL(12,2),0) AS NoEmployee
			FROM		#PayrollTable_share
			) U
	Pivot 
			(
			SUM(SalaryAmount) FOR Code IN ( '+@ElementPivot+' )
			) P

	--- Update NoEmployee
	UPDATE		ptp
	SET			ptp.NoEmployee = goc.NoEmployee
	FROM		#PayrollTable_pivot ptp
	INNER JOIN	#Group_Org_countemp goc
		ON		ptp.DivisionOrder = goc.DivisionOrder
				AND ptp.CenterOrder = goc.CenterOrder		
				AND ptp.DepartmentOrder = goc.DepartmentOrder
				AND ptp.SectionOrder = goc.SectionOrder			
				AND ptp.UnitOrder = goc.UnitOrder
				AND ISNULL(ptp.CostCentreCode,'''') = ISNULL(goc.CostCentreCode,'''')
				AND ISNULL(ptp.Group_CostCentreCode,'''') = ISNULL(goc.Group_CostCentreCode,'''')
				AND ptp.CostTypeCode = goc.CostTypeCode

	--- Lay ra bang results
	SELECT		*
				,ISNULL(AVN_GROSS_SALARY,0) + ISNULL(AVN_PC_SUM_DEDUCTION_MAU3,0) + ISNULL(AVN_TCCTP,0) - ISNULL(AVN_D_AN,0) AS SALARY
				,ISNULL(AVN_GXE,0) + ISNULL(AVN_TCDL_DEDUCTION,0) + ISNULL(AVN_DLCT,0) AS COMMUTING_FEE
				,ISNULL(AVN_OT_SUM_DEDUCT,0) + ISNULL(AVN_TCCC,0) + ISNULL(AVN_DCCT1,0) + ISNULL(AVN_DCCT2,0) + ISNULL(AVN_OTC,0) + ISNULL(AVN_TCKC,0) AS OVERTIME_TOTAL
				,ISNULL(AVN_WEDA,0) + ISNULL(AVN_BIRA,0) + ISNULL(AVN_FURA,0) + ISNULL(AVN_NMAT,0) + ISNULL(AVN_LT_REWARD_10_15_20_25_30,0) + ISNULL(AVN_GIFT,0) AS WELFARE
				,ISNULL(AVN_LT_REWARD_10_15_20_25_30,0) AS LT_REWARD
				,GETDATE() AS DateExport ,ROW_NUMBER() OVER ( ORDER BY DivisionName,DivisionOrder, CenterName,CenterOrder,DepartmentName,DepartmentOrder, SectionName,SectionOrder,UnitName,UnitOrder,CostTypeCode,Group_CostCentreCode,CostCentreCode ) as RowNumber
				,NULL AS "CodeEmp",NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit"
				,NULL AS "condi.WorkPlaceID",NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType", NULL AS "AmountCondition", NULL AS "condi.CostCentreID", NULL AS "csc.AbilityTitleID", NULL AS "cost.CostCentreGroupID"
				,NULL AS "ProfileName",NULL AS "condi.EmpStatus"	
	INTO		#Results
	FROM		#PayrollTable_pivot
'
set @queryPageSize = N'

	SELECT		RowNumber AS STT,*
	FROM		#Results	
	WHERE		RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
	ORDER BY	RowNumber

	drop table #Results,#Hre_WorkHistory
	DROP TABLE #tblPermission,#UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
	DROP TABLE #Sal_PayrollTable,#Sal_PayrollTable_new,  #List_emp_costcentre_share, #Group_Org_countemp, #PayrollTable_share, #PayrollTable_pivot
	DROP TABLE  #SumRateShare, #OrgSplitCost

'
print(@getdata)
PRINT (@query)
PRINT (@UnionData)
PRINT (@pivot)
PRINT(@queryPageSize)
exec(@getdata + @query + @UnionData + @pivot + @queryPageSize)

END

--rpt_salary_report

