ALTER proc [dbo].[rpt_payroll_banking]
@condition nvarchar(max) = " and (MonthYear = '2021-04-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'hanh.nguyen'
as
begin

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
	DECLARE @Amount NCHAR(100)
	declare @AmountCondittion nvarchar(100) = ''
	DECLARE @MonthYear nvarchar(50) = ' '
	DECLARE @MonthYearSP nvarchar(50) = ' '
	DECLARE @PayPaidType nvarchar(100) = ''

	while @row > 0
	begin
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

			set @index = charindex('(GroupBank ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(Groupbank ','(cb.Groupbank ')
			end

			set @index = charindex('(BankName ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(BankName ','(cb.BankName ')
			end

			set @index = charindex('(ProfileID ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(ProfileID ','(spt.ProfileID ')
			end


			set @index = charindex('(Amount ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
            	--set @condition = REPLACE(@condition,'(Amount ','(spt.Amount ')
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @Amount = @tempCodition
			END
            
			
			set @index = charindex('(AmountCondittion ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @AmountCondittion = REPLACE(@tempCodition,'(AmountCondittion in ','')
				set @AmountCondittion = REPLACE(@AmountCondittion,',',' OR ')
				set @AmountCondittion = REPLACE(@AmountCondittion,'))',')')
			END
            

			set @index = 0
			set @index = charindex('(OrderNumber ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(OrderNumber ','(cos.OrderNumber ')
			end

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

			END

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

-- Export

	declare @query nvarchar(max)
	declare @queryPageSize nvarchar(max)


set @query = '
		CREATE TABLE #tblPermission (id uniqueidentifier primary key )
		INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''',''Sal_PayrollTable''
	
		--- Lay ngay bat dau va ket thuc ky luong
		DECLARE @DateStart DATETIME, @DateEnd DATETIME, @StartMonth  DATETIME
		SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYear+N'


		-----------------------Lay du lieu tu bang Luong--------------------------- [rpt_Advance_payroll]
		;WITH Sal_PayrollTable_New AS
		(
		select 
					spt.ProfileID , hp.CodeEmp,hp.ProfileName, hp.NameEnglish, spt.AccountNo,cb.BankName + '', '' + dbo.VnrDecrypt(spti2.E_Value) AS BankBranhName, cb.BankName, dbo.VnrDecrypt(spti2.E_Value) as BranchName,
					CASE WHEN cb.GroupBank IN(''ICB'', ''BIDV'', ''VCB'',''NN'') THEN ISNULL(cb.BankName,''NULL'') ELSE ISNULL(cb.GroupBank,''NULL'') END AS GroupBankName ,cb.GroupBank,
					cast(dbo.VnrDecrypt(spti.E_Value) as float) as Amount , spt.MonthYear, GETDATE() AS DateExport, CASE WHEN spt.IsCash = 1 THEN N''Tiền Mặt'' ELSE N''Chuyển khoản'' END AS PayPaidType,
					hwh.SalaryClassID, ROW_NUMBER() OVER(PARTITION BY hwh.ProfileID ORDER BY hwh.DateEffective DESC) AS rk
		from		Sal_PayrollTable spt
		LEFT JOIN	Hre_WorkHistory hwh 
			ON		spt.ProfileID = hwh.ProfileID AND  spt.IsDelete is null
		LEFT JOIN	Hre_Profile hp 
			ON		hp.id= spt.ProfileID AND hp.IsDelete is null
		LEFT JOIN	Cat_Bank cb 
			ON		cb.ID = spt.BankID AND cb.IsDelete IS  NULL
		LEFT JOIN	Cat_OrgStructure cos 
			ON		cos.ID = spt.OrgstructureID AND	cos.Isdelete IS NULL
		LEFT JOIN	Sal_PayrollTableItem spti
			ON		Spti.PayrollTableID = spt.ID 
					AND	spti.Code = ''AVN_NetIncome'' AND spti.Isdelete IS NULL
		LEFT JOIN	Sal_PayrollTableItem spti2
			ON		Spti2.PayrollTableID = spt.ID 
					AND	spti2.Code = ''AVN_Bank_Branch'' AND spti2.Isdelete IS NULL
		--INNER JOIN	#tblPermission tbl on tbl.id = spt.ProfileID
		WHERE		hwh.IsDelete is null
			AND		hwh.DateEffective <= @DateEnd
			AND		hwh.Status = ''E_APPROVED''
					'+ISNULL(@condition,'')+'
		)
		Select *
		into #Sal_PayrollTable_New 
		from Sal_PayrollTable_New 
		WHERE rk = 1 
		--'+ISNULL(@Amount,'') +'
		'+ISNULL(@AmountCondittion,'')+'
		'+ISNULL(@PayPaidType,'')+' 


		Update	#Sal_PayrollTable_New 
		Set		GroupBankName = (SELECT DISTINCT BankName FROM dbo.Cat_Bank WHERE GroupBank = ''VCB'' AND IsDelete IS NULL)
		WHERE	GroupBank = ''VCB Others''

		select		*,ROW_NUMBER() OVER ( ORDER BY GroupBankName,BankName,BranchName,BankBranhName asc) as RowNumber
					,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "hwh.EmploymentType",NULL AS "hwh.SalaryClassID" ,NULL AS "hwh.PositionID", NULL AS "hwh.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "hwh.WorkPlaceID",NULL AS "spt.EmpStatus",NULL AS "AmountCondittion"
		INTO		#Results 
		FROM		#Sal_PayrollTable_New 
					
					
		'
set @queryPageSize = ' 

		ALTER TABLE #Results ADD TotalRow int
		declare @totalRow int
		SELECT @totalRow = COUNT(*) FROM #Results
		update #Results set TotalRow = @totalRow
		SELECT *
		FROM #Results 
		WHERE RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
		AND		CodeEmp IS NOT NULL
		ORDER BY RowNumber
						
		DROP TABLE #Results
		drop table #tblPermission
		drop table #Sal_PayrollTable_New
		'
	print (@query +' '+ @queryPageSize )
	exec(@query +' '+ @queryPageSize )
END

--[rpt_payroll_banking]