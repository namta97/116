ALTER proc [dbo].[rpt_list_severance_paymenttransfer]
@condition nvarchar(max) = "  and (hp.DateQuit between '2021/03/21' and '2021/08/20')  ",
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
	DECLARE @AccountCompanyNo nvarchar(100) = 'null'
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

			set @index = charindex('(AmountCondittion ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @AmountCondittion = REPLACE(@tempCodition,'(AmountCondittion in ','')
				set @AmountCondittion = REPLACE(@AmountCondittion,',',' OR ')
				set @AmountCondittion = REPLACE(@AmountCondittion,'))',')')
			END

			set @index = charindex('(PayPaidType ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @PayPaidType = @tempCodition
			END
            
			set @index = charindex('(AccountCompanyNo ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @AccountCompanyNo = REPLACE(@tempCodition,'and (AccountCompanyNo Like N','')
				set @AccountCompanyNo = REPLACE(@AccountCompanyNo,')','')
				set @AccountCompanyNo = REPLACE(@AccountCompanyNo,'%','')
			end
            
			set @index = charindex('(IsSalary ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
			END

			set @index = charindex('(IsNotSalary ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
			END

			set @index = charindex('(IsSalaryBanking ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
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
		INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''',''Hre_Profile''
	
		----- Lay ngay bat dau va ket thuc ky luong
		--DECLARE @DateStart DATETIME, @DateEnd DATETIME, @StartMonth  DATETIME
		--SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYear+N'


		-----------------------Lay du lieu tu bang Luong--------------------------- [rpt_list_severance_paymenttransfer]

		select 
					spt.ProfileID , hp.CodeEmp,hp.ProfileName, hp.NameEnglish, spt.AccountNo
					,cast(dbo.VnrDecrypt(spti.E_Value) as float) as Amount,CASE WHEN spt.IsCash = 1 THEN N''Tiền Mặt'' ELSE N''Chuyển khoản'' END AS PayPaidType
					,spt.BankID, dbo.VnrDecrypt(spti2.E_Value) as BranchName,spt.MonthYear
		INTO		#Sal_PayrollTable_New
		FROM		Hre_Profile hp 
		LEFT JOIN	Sal_PayrollTable spt
			ON		hp.id= spt.ProfileID AND spt.IsDelete IS NULL
		LEFT JOIN	Att_CutOffDuration acd
			ON		acd.MonthYear = spt.MonthYear
		LEFT JOIN	Cat_Bank cb 
			ON		cb.ID = spt.BankID
		LEFT JOIN	Cat_OrgStructure cos 
			ON		cos.ID = spt.OrgstructureID  AND cos.Isdelete IS NULL
		LEFT JOIN	Cat_SalaryClass csc
			ON		csc.ID = spt.SalaryClassID
		LEFT JOIN	Sal_PayrollTableItem spti
			ON		Spti.PayrollTableID = spt.ID AND spti.Code = ''AVN_NetIncome'' 
		LEFT JOIN	Sal_PayrollTableItem spti2
			ON		Spti2.PayrollTableID = spt.ID AND spti2.Code = ''AVN_Bank_Branch''
		INNER JOIN	#tblPermission tbl on tbl.id = spt.ProfileID
		WHERE		hp.IsDelete is null
					AND hp.DateQuit BETWEEN	acd.DateStart AND acd.DateEnd
					'+ISNULL(@condition,'')+'
		SELECT		sptn.*, cbr.BranchSortCode AS BankBranhName
		INTO		#Severance_paymenttransfer
		FROM		#Sal_PayrollTable_New sptn
		OUTER APPLY	
					(SELECT TOP(1) BranchSortCode
					FROM	Cat_Branch cbr
					WHERE	cbr.BranchName = sptn.BranchName AND cbr.BankID = sptn.BankID
							AND cbr.IsDelete IS NULL
					ORDER	BY cbr.DateUpdate DESC
					) cbr
		WHERE		ProfileID IS NOT NULL
					'+ISNULL(@AmountCondittion,'')+'
					'+ISNULL(@PayPaidType,'')+' 

		select		*
					,'+@AccountCompanyNo+' AS "AccountCompanyNo"
					,ROW_NUMBER() OVER ( ORDER BY BankBranhName) as RowNumber, GETDATE() AS DateExport
					,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "spt.EmploymentType",NULL AS "spt.SalaryClassID" ,NULL AS "spt.PositionID", NULL AS "spt.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "spt.WorkPlaceID"
					,NULL AS "spt.EmployeeGroupID", NULL AS "spt.LaborType", NULL AS "spt.CostCentreID", NULL AS "csc.AbilityTitleID", NULL AS "AmountCondittion"
					,NULL AS "BankName", NULL AS "GroupBank"
					,NULL AS "spt.EmpStatus",NULL AS "IsSalary", NULL AS "IsNotSalary", NULL AS "IsSalaryBanking"
		INTO		#Results 
		FROM		#Severance_paymenttransfer			
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
		drop table #Sal_PayrollTable_New, #Severance_paymenttransfer
		'
	print (@query +' '+ @queryPageSize )
	exec(@query +' '+ @queryPageSize )
END

--[rpt_list_severance_paymenttransfer]