----Nam Ta: Thanh ly thoi viec
ALTER proc rpt_TLTV_MH
@condition nvarchar(max) = "  and (hp.DateQuit between '2022/01/21' and '2022/02/20')  ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'khang.nguyen'
AS
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
		SET @condition =  ' and (hp.DateQuit between ''2022/01/21'' and ''2022/02/20'') '
end;

----Xu ly Condition---
declare @AmountCondittion nvarchar(500) = ''
DECLARE @AccountCompanyNo varchar(100) = 'null'
DECLARE @PayPaidType nvarchar(100) = ''

-- cat dieu kien
set @str = REPLACE(@condition,',','@')
set @str = REPLACE(@str,'and (',',')
SELECT ID into #tableTempCondition FROM SPLIT_To_NVARCHAR (@str)
set @row = (SELECT count(ID) FROM SPLIT_To_NVARCHAR (@str))
set @countrow = 0
set @index = 0
while @row > 0
begin
	set @index = 0
	set @ID = (select top 1 ID from #tableTempCondition)
	set @tempID = replace(@ID,'@',',')

	set @index = charindex('(BankName ','('+@tempID,0) 
	if(@index > 0)
	begin
		set @condition = REPLACE(@condition,'(BankName ','(cb.BankName ')
	END

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

	SET @index = CHARINDEX('(CodeEmp ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(CodeEmp ','(hp.CodeEmp ')
	END

	set @index = charindex('(condi.EmploymentType ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.EmploymentType ','(spt.EmploymentType ')
	END
    
	set @index = charindex('(condi.SalaryClassID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.SalaryClassID ','(spt.SalaryClassID ')
	END

	set @index = charindex('(condi.PositionID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.PositionID ','(spt.PositionID ')
	END
	
	set @index = charindex('(condi.JobTitleID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.JobTitleID ','(spt.JobTitleID ')
	END
	
	set @index = charindex('(condi.WorkPlaceID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.WorkPlaceID ','(spt.WorkPlaceID ')
	END
	
	set @index = charindex('(condi.EmployeeGroupID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.EmployeeGroupID ','(spt.EmployeeGroupID ')
	END
		
	set @index = charindex('(condi.LaborType ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.LaborType ','(spt.LaborType ')
	END
			
	set @index = charindex('(condi.EmpStatus ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.EmpStatus ','(spt.EmpStatus ')
	END
			
	set @index = charindex('(AccountCompanyNo ','('+@tempID,0) 
	if(@index > 0)
	begin
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @AccountCompanyNo = REPLACE(@TempCondition,'and (AccountCompanyNo Like N','')
		set @AccountCompanyNo = REPLACE(@AccountCompanyNo,')','')
		set @AccountCompanyNo = REPLACE(@AccountCompanyNo,'%','')
	end
			
	set @index = charindex('(AmountCondittion ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @AmountCondittion = REPLACE(@TempCondition,'(AmountCondittion in ','')
		set @AmountCondittion = REPLACE(@AmountCondittion,',',' OR ')
		set @AmountCondittion = REPLACE(@AmountCondittion,'))',')')
	END
           
	set @index = charindex('(PayPaidType ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @PayPaidType = @TempCondition
	END

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1
END

-- Gia tri
IF (@AmountCondittion is not null and @AmountCondittion <> '')
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

declare @query nvarchar(max)
declare @query1 nvarchar(max)
declare @query2 varchar(max)
declare @queryPageSize varchar(max)

set @query = '
	select ProfileID,DateEffective,ROW_NUMBER ( ) OVER (PARTITION BY ProfileID order by ProfileID,DateEffective desc) as flag
	into #LenChinhThuc
	from Hre_WorkHistory
	where isdelete is null and TypeOfTransferID in (SELECT id FROM Cat_NameEntity WHERE isdelete IS NULL AND NameEntityType = ''E_Typeoftransfer'' and Code = ''CTOP'')

	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''',''Sal_PayrollTable''

	select	*,ROW_NUMBER ( ) OVER (PARTITION BY ProfileID order by ProfileID,datestop desc) as flag 
	into	#StopWorking 
	from	Hre_StopWorking where isdelete is null and StopWorkType = ''E_STOP''

	select		' +@Top+ N'
				spt.ProfileID AS ID ,spt.ProfileID, hp.ProfileName + ''_'' + hp.CodeEmp as CodeEmp, hp.CodeEmp as E_CodeEmp ,hp.ProfileName, hp.NameEnglish
				,E_BRANCH AS DivisionName,E_UNIT AS CenterName,E_DIVISION AS DepartmentName,E_DEPARTMENT AS SectionName,E_TEAM AS UnitName
				,sc.SalaryClassName,cp.PositionName,cj.JobTitleName, cetl.VN AS EmploymentType,cetl2.VN AS LaborType,cne.NameEntityName AS EmployeeGroupName, cwp.WorkPlaceName
				,hp.DateQuit,hp.DateHire,hp.DateEndProbation,cetl3.vn as EmpStatus, spt.MonthYear
				,cast(dbo.VnrDecrypt(spti.E_Value) as float) as Amount,CASE WHEN spt.IsCash = 1 THEN N''Tiền Mặt'' ELSE N''Chuyển khoản'' END AS PayPaidType
				,spt.AccountNo,cb.BankName, dbo.VnrDecrypt(spti2.E_Value) as BranchName,cb.GroupBank, spt.ID AS PayrollTableID,spt.BankID
	INTO		#Sal_PayrollTable_New
	FROM		Hre_Profile hp
	LEFT JOIN	Sal_PayrollTable spt ON hp.id= spt.ProfileID AND spt.IsDelete IS NULL
	LEFT JOIN	Att_CutOffDuration acd ON	acd.MonthYear = spt.MonthYear
	LEFT JOIN	#StopWorking sto on sto.profileid = spt.profileid and flag = ''1'' 
	LEFT JOIN	Cat_OrgStructure cos on cos.ID = spt.OrgstructureID
	LEFT JOIN	cat_orgunit cosu on cosu.OrgstructureID = cos.id
	LEFT JOIN	Cat_Bank cb ON cb.ID = spt.BankID
	LEFT JOIN	Cat_SalaryClass sc on spt.SalaryClassID = sc.id
	LEFT JOIN	Cat_JobTitle cj on spt.JobTitleID = cj.ID
	LEFT JOIN	Cat_Position cp on spt.PositionID = cp.ID
	LEFT JOIN	Cat_NameEntity cne ON cne.ID = spt.EmployeeGroupID
	LEFT JOIN	Cat_WorkPlace cwp ON cwp.ID = spt.WorkPlaceID
	LEFT JOIN	Sal_PayrollTableItem spti ON Spti.PayrollTableID = spt.ID AND spti.Code = ''AVN_NetIncome''
	LEFT JOIN	Sal_PayrollTableItem spti2 ON Spti2.PayrollTableID = spt.ID AND spti2.Code = ''AVN_Bank_Branch''

	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = spt.EmploymentType 
						AND cetl.EnumName = ''EmploymentType'' AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl

	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = spt.LaborType 
						AND cetl.EnumName = ''LaborType'' AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl2
	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = spt.EmploymentType 
						AND cetl.EnumName = ''PayrollTableProfileStatus'' AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl3
	WHERE		hp.IsDelete is null
				AND hp.DateQuit BETWEEN	acd.DateStart AND acd.DateEnd
				'+ISNULL(@condition,'')+'
'
set @query1 = '

	SELECT		sptn.*, cbr.BranchSortCode
	INTO		#Severance_paymenttransfer
	FROM		#Sal_PayrollTable_New sptn
	OUTER APPLY	
				(
				SELECT TOP(1) BranchSortCode
				FROM Cat_Branch cbr
				WHERE cbr.BranchName = sptn.BranchName AND cbr.BankID = sptn.BankID
				AND cbr.IsDelete IS NULL
				ORDER BY cbr.DateUpdate
				) cbr
	WHERE		ProfileID IS NOT NULL
				'+ISNULL(@AmountCondittion,'')+'
				'+ISNULL(@PayPaidType,'')+' 

	SELECT		* 
	INTO		#Results2 
	FROM 
				(
				select s.*
				,si.Code,cast(dbo.VnrDecrypt(si.E_Value) as float ) as Amount2
				from #Severance_paymenttransfer s
				left join Sal_PayrollTableItem si on s.PayrollTableID=si.PayrollTableID 
				where si.Code in 
				(
					''AVN_TONG_LTC'',''AVN_NCTL'',''AVN_TONGLUONGNGAYCONG'',''AVN_PCTheoLuong_SUM'',''AVN_OT_SUM'',''AVN_NS_SUM'',''AVN_ThuNhapKhac_TrongThang'',''AVN_TongThuong_TrongThang''
					,''AVN_TruyLinh'',''AVN_LuongThuong_SUM'',''AVN_LuongTinh_TCTV'',''AVN_SoThang_AVG'',''AVN_TCTV_Year'',''AVN_TCTV_Month'',''AVN_TCTV_Day'',''AVN_SoNamHuongTCTV'',''AVN_TCTV_NonTaxable''
					,''AVN_TCTV_Taxable'',''AVN_TCTV_Amount'',''AVN_KhoanDuocHuong_TCTV'',''AVN_TT_BHYT_E'',''AVN_BHXH_BHYT_BHTN_E'',''AVN_Deduction_SUM'',''AVN_TruyThu'',''AVN_TongKhoanKhauTru''
					,''AVN_ThuePIT'',''AVN_TCTV_Tax'',''AVN_TongPIT'',''AVN_AdvancePay'',''AVN_NetIncome'',''AVN_ThuNhapChiuThue'',''AVN_ThuNhapKhongChiuThue'',''AVN_OT_NonTax'',''AVN_Thuong_NonTax''
					,''AVN_TruyLinh_NonTax'',''AVN_ThuNhapKhac_TrongThang_NonTax'',''AVN_PIT_Deduction'',''AVN_GiamTruBanThan''
					,''AVN_SoNguoiPhuThuoc'',''AVN_GiamTruPhuThuoc'',''AVN_BH_E'',''AVN_BHXH_E'',''AVN_BHYT_E'',''AVN_BHTN_E'',''AVN_TinhThue'',''AVN_GrossIncome''
				)
				) T

				Pivot 
				(
				sum(Amount2) for code in 
				(
					[AVN_TONG_LTC],[AVN_NCTL],[AVN_TONGLUONGNGAYCONG],[AVN_PCTheoLuong_SUM],[AVN_OT_SUM],[AVN_NS_SUM],[AVN_ThuNhapKhac_TrongThang],[AVN_TongThuong_TrongThang]
					,[AVN_TruyLinh],[AVN_LuongThuong_SUM],[AVN_LuongTinh_TCTV],[AVN_SoThang_AVG],[AVN_TCTV_Year],[AVN_TCTV_Month],[AVN_TCTV_Day],[AVN_SoNamHuongTCTV],[AVN_TCTV_NonTaxable]
					,[AVN_TCTV_Taxable],[AVN_TCTV_Amount],[AVN_KhoanDuocHuong_TCTV],[AVN_TT_BHYT_E],[AVN_BHXH_BHYT_BHTN_E],[AVN_Deduction_SUM],[AVN_TruyThu],[AVN_TongKhoanKhauTru]
					,[AVN_ThuePIT],[AVN_TCTV_Tax],[AVN_TongPIT],[AVN_AdvancePay],[AVN_NetIncome],[AVN_ThuNhapChiuThue],[AVN_ThuNhapKhongChiuThue],[AVN_OT_NonTax],[AVN_Thuong_NonTax]
					,[AVN_TruyLinh_NonTax],[AVN_ThuNhapKhac_TrongThang_NonTax],[AVN_PIT_Deduction],[AVN_GiamTruBanThan]
					,[AVN_SoNguoiPhuThuoc],[AVN_GiamTruPhuThuoc],[AVN_BH_E],[AVN_BHXH_E],[AVN_BHYT_E],[AVN_BHTN_E],[AVN_TinhThue],[AVN_GrossIncome]
				)
				) P
'set @query2 = '
	select		rs.*, CASE WHEN ISNULL(AVN_TongKhoanKhauTru,0) - ISNULL(AVN_TongPIT,0) > 0 THEN ISNULL(AVN_TongKhoanKhauTru,0) - ISNULL(AVN_TongPIT,0) ELSE 0 END AS AVN_TongKhoanKhauTru_Not_PIT
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri1.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri1.E_Value),LEN(dbo.VnrDecrypt(pri1.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri1.E_Value) END as AVN_TONGLUONGNGAYCONG_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri2.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri2.E_Value),LEN(dbo.VnrDecrypt(pri2.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri2.E_Value) END as AVN_PCTheoLuong_SUM_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri3.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri3.E_Value),LEN(dbo.VnrDecrypt(pri3.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri3.E_Value) END as AVN_OT_SUM_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri4.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri4.E_Value),LEN(dbo.VnrDecrypt(pri4.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri4.E_Value) END as AVN_NS_SUM_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri5.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri5.E_Value),LEN(dbo.VnrDecrypt(pri5.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri5.E_Value) END as AVN_ThuNhapKhac_TrongThang_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri6.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri6.E_Value),LEN(dbo.VnrDecrypt(pri6.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri6.E_Value) END as AVN_TongThuong_TrongThang_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri7.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri7.E_Value),LEN(dbo.VnrDecrypt(pri7.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri7.E_Value) END as AVN_TruyLinh_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri8.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri8.E_Value),LEN(dbo.VnrDecrypt(pri8.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri8.E_Value) END as AVN_Deduction_SUM_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri9.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri9.E_Value),LEN(dbo.VnrDecrypt(pri9.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri9.E_Value) END as AVN_TruyThu_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri10.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri10.E_Value),LEN(dbo.VnrDecrypt(pri10.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri10.E_Value) END as AVN_OT_NonTax_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri11.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri11.E_Value),LEN(dbo.VnrDecrypt(pri11.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri11.E_Value) END as AVN_Thuong_NonTax_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri12.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri12.E_Value),LEN(dbo.VnrDecrypt(pri12.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri12.E_Value) END as AVN_TruyLinh_NonTax_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri14.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri14.E_Value),LEN(dbo.VnrDecrypt(pri14.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri14.E_Value) END as AVN_ThuNhapKhac_TrongThang_NonTax_DETAIL
				,CASE WHEN RIGHT(dbo.VnrDecrypt(pri15.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri15.E_Value),LEN(dbo.VnrDecrypt(pri15.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri15.E_Value) END as AVN_NgayThangNamTCTV
				,''('' + CASE WHEN RIGHT(dbo.VnrDecrypt(pri16.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri16.E_Value),LEN(dbo.VnrDecrypt(pri16.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri16.E_Value) END + '')'' as AVN_TONG_LTC_DETAIL

				,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber
				,GETDATE() AS DateExport
				,NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire"
				,NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit"
				,NULL AS "condi.WorkPlaceID",NULL AS "condi.EmpStatus",NULL AS "AmountCondittion",NULL as "sto.PaymentDay", '+@AccountCompanyNo+' AS "AccountCompanyNo"
	INTO		#Results
	FROM		#Results2 rs
	LEFT JOIN	sal_payrolltableitem pri1 on rs.PayrollTableID=pri1.payrolltableid and pri1.code = ''AVN_TONGLUONGNGAYCONG_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri2 on rs.PayrollTableID=pri2.payrolltableid and pri2.code = ''AVN_PCTheoLuong_SUM_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri3 on rs.PayrollTableID=pri3.payrolltableid and pri3.code = ''AVN_OT_SUM_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri4 on rs.PayrollTableID=pri4.payrolltableid and pri4.code = ''AVN_NS_SUM_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri5 on rs.PayrollTableID=pri5.payrolltableid and pri5.code = ''AVN_ThuNhapKhac_TrongThang_DETAIL3''
	LEFT JOIN	sal_payrolltableitem pri6 on rs.PayrollTableID=pri6.payrolltableid and pri6.code = ''AVN_TongThuong_TrongThang_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri7 on rs.PayrollTableID=pri7.payrolltableid and pri7.code = ''AVN_TruyLinh_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri8 on rs.PayrollTableID=pri8.payrolltableid and pri8.code = ''AVN_Deduction_SUM_DETAIL3''
	LEFT JOIN	sal_payrolltableitem pri9 on rs.PayrollTableID=pri9.payrolltableid and pri9.code = ''AVN_TruyThu_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri10 on rs.PayrollTableID=pri10.payrolltableid and pri10.code = ''AVN_OT_NonTax_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri11 on rs.PayrollTableID=pri11.payrolltableid and pri11.code = ''AVN_Thuong_NonTax_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri12 on rs.PayrollTableID=pri12.payrolltableid and pri12.code = ''AVN_TruyLinh_NonTax_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri14 on rs.PayrollTableID=pri14.payrolltableid and pri14.code = ''AVN_ThuNhapKhac_TrongThang_NonTax_DETAIL''
	LEFT JOIN	sal_payrolltableitem pri15 on rs.PayrollTableID=pri15.payrolltableid and pri15.code = ''AVN_NgayThangNamTCTV''
	LEFT JOIN	sal_payrolltableitem pri16 on rs.PayrollTableID=pri16.payrolltableid and pri16.code = ''AVN_TONG_LTC_DETAIL''
	'
set @queryPageSize = ' 
	ALTER TABLE #Results ADD TotalRow int
	declare @totalRow int
	SELECT @totalRow = COUNT(*) FROM #Results
	update #Results set TotalRow = @totalRow

	SELECT		RowNumber AS STT,*
	FROM		#Results 
	WHERE		RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
	ORDER BY	RowNumber



	DROP TABLE #Results,#Results2,#tblPermission,#Sal_PayrollTable_New,#Severance_paymenttransfer,#LenChinhThuc,#StopWorking
'
print (@query)
print (@query1)
print (@query2)
print (@queryPageSize)

exec(@query + @query1 + @query2 + @queryPageSize )
END
--rpt_TLTV_MH
