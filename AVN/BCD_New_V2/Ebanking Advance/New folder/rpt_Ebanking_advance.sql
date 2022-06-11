
ALTER proc [dbo].[rpt_Ebanking_advance]
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
	
	declare @yearCondittion nvarchar(100) = ''
	declare @AmountCondittion nvarchar(100) = ''
	declare @AbilityTitleIDCondittion nvarchar(max) =''
	declare @EmployeeGroupIDCondittion nvarchar(max)=''

	declare @DateHeader nvarchar(100) = 'null'
	declare @BankNameHeader nvarchar(100) = 'null'
	declare @CommentHeader nvarchar(200)
	DECLARE @Monthyeartemp VARCHAR(50) = ''
	DECLARE @GroupName nvarchar(100)
	DECLARE @ValueDateHeader nvarchar(100)
	DECLARE @ValueDate DATE
	DECLARE @AccountCompanyNo nvarchar(50)


	while @row > 0
	begin
			set @index = 0
			set @ID = (select top 1 ID from #tableTempCondition)
			set @tempID = replace(@ID,'@',',')


			set @index = 0
			set @index = charindex('MonthYear = ',@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(MonthYear = ','(sup.MonthYear <= ')
			end

			set @index = charindex('(EmployeeTypeID ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(EmployeeTypeID ','(sup.EmployeeTypeID ')
			end


			set @index = charindex('(GroupBank ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(Groupbank ','(cb.Groupbank ')
			end

			set @index = charindex('(ProfileID ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(ProfileID ','(sup.ProfileID ')
			end

			set @index = charindex('(Amount ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
            	set @condition = REPLACE(@condition,'(Amount ','(sup.Amount ')
			end

			set @index = charindex('(SalaryClassID ','('+@tempID,0) 
			if(@index > 0)
			begin
     			SET @condition = REPLACE(@condition,'(SalaryClassID ','(hwh.SalaryClassID ')
			end
			
			set @index = charindex('(DateHeader ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @DateHeader = REPLACE(@tempCodition,'and (DateHeader = ','')
				set @DateHeader = REPLACE(@DateHeader,')','')
			end

			set @index = charindex('(BankNameHeader ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @BankNameHeader = REPLACE(@tempCodition,'and (BankNameHeader like N','')
				set @BankNameHeader = REPLACE(@BankNameHeader,')','')
				set @BankNameHeader = REPLACE(@BankNameHeader,'%','')
			end
		
			set @index = charindex('(CommentHeader ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @CommentHeader = REPLACE(@tempCodition,'and (CommentHeader like ','')
				set @CommentHeader = REPLACE(@CommentHeader,')','')
				set @CommentHeader = REPLACE(@CommentHeader,'%','')
			end

			set @index = 0
			set @index = charindex('(OrderNumber ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(OrderNumber ','(cos.OrderNumber ')
			end

			set @index = charindex('(GroupName ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @GroupName = REPLACE(@tempCodition,'and (GroupName like N','')
				set @GroupName = REPLACE(@GroupName,')','')
				set @GroupName = REPLACE(@GroupName,'%','')
			END
            
						
			set @index = charindex('(ValueDateHeader ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @ValueDateHeader = REPLACE(@tempCodition,'and (ValueDateHeader = ','')
				set @ValueDateHeader = REPLACE(@ValueDateHeader,')','')

			end

			DELETE #tableTempCondition WHERE ID = @ID
			set @row = @row - 1
	end
	IF @ValueDateHeader <> 'null'
	BEGIN
	SET @ValueDate = CONVERT(DATETIME,SUBSTRING(@ValueDateHeader,2,10))
	SET @ValueDateHeader = CONVERT(VARCHAR(20), @ValueDate, 112)
	END
  


SET @CommentHeader = ISNULL(@CommentHeader,'')
----SET @CommentHeader = '"' + @CommentHeader + '"'
SET @GroupName = ISNULL(@GroupName,'')
--SET @GroupName = '"' + @GroupName + '"'
SET @ValueDateHeader = ISNULL(@ValueDateHeader,'')
--SET @ValueDateHeader = '"' + @ValueDateHeader + '"'


--if(@AmountCondittion is not null and @AmountCondittion != '')
--begin
--	if (@AmountCondittion = 'E_EqualToZero')
--		set @AmountCondittion = ' and supi.Amount = 0'
--	else if (@AmountCondittion = 'E_LessThanZero')
--		set @AmountCondittion = ' and supi.Amount < 0'
--	else if(@AmountCondittion = 'E_GreaterThanZero')
--		set @AmountCondittion = ' and supi.Amount > 0'
--end

--select @yearCondittion
--select @condition
--select @AmountCondittion
--select @AbilityTitleIDCondittion
--select @EmployeeGroupIDCondittion



if (@yearCondittion is null)
	set @yearCondittion = ''



-- Export
declare @Top0 nvarchar(max) = ''
if (@IsExport = 0 )
begin
	set  @Top0 = ' top 0 '

	set @condition = ' '
	set @yearCondittion = ''
	set @AmountCondittion = ''
	set @AbilityTitleIDCondittion = ''
	set @EmployeeGroupIDCondittion = ''
end

	declare @query nvarchar(max)
	declare @queryPageSize nvarchar(max)


set @query = '
		CREATE TABLE #tblPermission (id uniqueidentifier primary key )
		INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''',''Sal_UnusualPay''
							
		-----------------------Lay du lieu tu bang Luong---------------------------
		;WITH Sal_PayrollTable_New AS
		(
		select 
					'+@Top0+' sup.ProfileID , hp.CodeEmp, hp.NameEnglish, sup.ID, sup.AccountNo, cb.GroupBank,
					hwh.SalaryClassID, ROW_NUMBER() OVER(PARTITION BY sup.ProfileID ORDER BY hwh.DateEffective DESC) AS rk,
					sup.Amount as Amount , sup.BankID, Sup.MonthYear, supi2.Amount as BranchName
		from		Sal_UnusualPay sup
		RIGHT JOIN Hre_WorkHistory hwh on sup.ProfileID = hwh.ProfileID and  sup.IsDelete is null
		LEFT JOIN	Hre_Profile hp on hp.id= sup.ProfileID and hp.IsDelete is null
		LEFT JOIN	Cat_Bank cb on cb.ID = sup.BankID
		LEFT JOIN	Cat_OrgStructure cos on cos.ID = sup.OrgstructureID
		--INNER JOIN	#tblPermission tbl on tbl.id = spt.ProfileID
		LEFT JOIN	Sal_UnusualPayItem supi2
			ON		supi2.UnusualPayID = sup.ID AND supi2.Code = ''SAL_SALARYINFORMATION_BRANCHNAME1''
		where hwh.IsDelete is null
		and hwh.DateEffective <= sup.MonthYear
		and hwh.Status = ''E_APPROVED''
		and sup.Amount > 0
		and sup.ID IS NOT NULL
		and supi2.Isdelete IS NULL
		AND cos.Isdelete IS NULL
		'+ISNULL(@condition,'')+'
		)
		Select *
		into #Sal_UnusualPay_New 
		from Sal_PayrollTable_New 
		where rk = 1 
		'+ISNULL(@AbilityTitleIDCondittion,'')+'
		'+ISNULL(@EmployeeGroupIDCondittion,'')+'



		-----------------------Tao 2 dong header va do du lieu vao cac cot---------------------------
					
		select
		'''+'0100'+''' as A,
		--CONVERT(Varchar(10),"0100") AS A,
		CONVERT(Varchar(10),''00001'') AS B,
		''"''+ CONVERT(NVarchar(200), RIGHT(1000000 + ROW_NUMBER() OVER ( ORDER BY supn.ProfileID asc),5 )) + ''"'' AS C,
		CONVERT(NVarchar(200),''"99"'') AS D,
		''"''+ Convert(varchar(100),CONVERT(Decimal(20,0),Amount)) +''"'' AS E,
		CONVERT(NVarchar(200), ''"''+ ISNULL(supn.CodeEmp,'''') +''"'') AS F,
		CONVERT(NVarchar(200), ''"''+ ISNULL(supn.AccountNo,'''') +''"'') AS G,
		CONVERT(NVarchar(200), ''"''+ ISNULL(supn.NameEnglish,'''') +''"'') AS H,
		CONVERT(NVarchar(20),''""'') AS I,
		CONVERT(NVarchar(20),''""'') AS J,
		CONVERT(NVarchar(20), ''"''+ ISNULL(cbr.BranchSwiftCode,'''') +''"'') AS K,
		CONVERT(NVarchar(20),''""'') AS L,
		CONVERT(NVarchar(20),''""'') AS M,
		CONVERT(NVarchar(20),''""'') AS N,
		CONVERT(NVarchar(20),''""'') AS O,
		CONVERT(NVarchar(20),''""'') AS P,
		CONVERT(NVarchar(20),''""'') AS Q,
		CONVERT(NVarchar(20),''""'') AS R,
		CONVERT(NVarchar(20),''""'') AS S,
		CONVERT(NVarchar(20),''""'') AS T,
		''"''+ '+@CommentHeader+' + ''"'' AS U,
		NULL AS STT,
		supn.ProfileID AS ProfileID,
		supn.CodeEmp as CodeEmp,
		--''"''+supn.NameEnglish+''"'' as NameEnglish,
		supn.AccountNo,
		supn.GroupBank,
		supn.BankID,
		cb.BankName,
		Amount,
		supn.MonthYear,
		null as OrderNumber,
		supn.SalaryClassID,
		--''"''+ ISNULL(Convert(Varchar(100),'+@CommentHeader+'),'''') + ''"'' AS CommentHeader,
		--''"''+ '+@CommentHeader+' + ''"'' AS CommentHeader,
		ROW_NUMBER() OVER ( ORDER BY supn.ProfileID asc) as RowNumber,
		NULL AS "hwh.EmploymentType",
		NULL AS "hp.DateHire",
		NULL AS "hp.DateEndProbation",
		NULL AS "hp.DateQuit",
		NULL AS "hwh.WorkingPlaceID",
		NULL AS "GroupName",
		NULL AS "ValueDateHeader",
		NULL AS "CommentHeader"

		into #Results
		from #Sal_UnusualPay_New supn
		LEFT JOIN cat_bank cb on supn.BankID = cb.ID
		LEFT JOIN	Cat_Branch cbr
			ON		cbr.BranchName = supn.BranchName AND cbr.BankID = supn.BankID

		WHERE cbr.IsDelete IS NULL

		DECLARE @CountProfile INT
		DECLARE @SumAmount DECIMAL

		SELECT @CountProfile = COUNT(ProfileID) , @SumAmount= SUM(Amount)
		FROM #Results

		-- Tao 2 dong header--
		--INSERT INTO #Results ( A, B, C, D,E,F,G,H,I,J, STT, U )
		--VALUES (''0001'',''"''+ RIGHT(CONVERT(VARCHAR(10),GETDATE(),112),6)+''"'', ''"0001"'', NULL,NULL, NULL,NULL, NULL,NULL, NULL,1, ''"''+'+@CommentHeader+'+''"'')
		--, (''"0010'',''"00001"'',''"''+'+@GroupName+'+''"'',''"''+ '+@ValueDateHeader+'+''"'',''"0"'',''"1"'',''"3640VNDORD041076"'',''"VND"'',''"''+Convert(varchar(10),@CountProfile)+''""'',''"''+Convert(varchar(20),@SumAmount)+''"'',0,''"''+'+@CommentHeader+'+''"'')

		'
set @queryPageSize = ' 

		ALTER TABLE #Results ADD TotalRow int
		declare @totalRow int
		SELECT @totalRow = COUNT(*) FROM #Results
		update #Results set TotalRow = @totalRow
		SELECT *
		FROM #Results 
		WHERE RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
		OR STT IN (1,0)
		ORDER BY STT DESC, RowNumber
						
		DROP TABLE #Results
		drop table #tblPermission
		drop table #Sal_UnusualPay_New
		'
	print (@query +' '+ @queryPageSize )
	exec(@query +' '+ @queryPageSize )
END
