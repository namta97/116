USE [HRMPro9_AVN_TEST]
GO
/****** Object:  StoredProcedure [dbo].[rpt_PayrollMonthlyV2]    Script Date: 14/09/2021 2:50:16 CH ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [dbo].[rpt_PayrollMonthlyV2]
--@condition nvarchar(max) =  " and (MonthYear = '2021-04-01') and (CheckData like N'%E_UNEXPECTED%') ",
@condition nvarchar(max) =  " and (MonthYear = '2021-04-01') ",
@PageIndex int = 1,
@PageSize int = 5000,
@Username varchar(100) = 'sal.hr'
as
begin

IF @condition = ' ' 
begin
set @condition =  ' and (MonthYear = ''2021-04-01'') '
END

declare @query nvarchar(max)
declare @queryPageSize nvarchar(max)	

declare @conditionCutOffDurationID varchar(100)
declare @Settlement varchar(100)
declare @StatusPay varchar(100)
 declare @str varchar(max)
 declare @countrow int
 declare @row int
 declare @index int
 declare @ID varchar(200)
 declare @query2 nvarchar(max)
 ----Xu ly Amount Condition----
declare @tempID nvarchar(Max)
declare @tempCodition nvarchar(Max)
declare @AmountCondittion nvarchar(100) = ''
DECLARE @MonthYear nvarchar(50) = ' '
DECLARE @CheckData nvarchar(50) = ' '
 -- xử lý tách dk

	 set @conditionCutOffDurationID = ''
	 set @Settlement = ''
	 set @StatusPay = ''
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
		set @index = charindex('MonthYear = ',@tempID,0) 
		if(@index > 0)
		begin
			--set @condition = REPLACE(@condition,'(MonthYear = ','(a.MonthYear = ')
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

		set @index = charindex('(AmountCondittion ','('+@tempID,0)
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @AmountCondittion = REPLACE(@tempCodition,'(AmountCondittion in ','')
			set @AmountCondittion = REPLACE(@AmountCondittion,',',' OR ')
			set @AmountCondittion = REPLACE(@AmountCondittion,'))',')')
		end
		set @index = 0
		set @ID = (select top 1 ID from #tableTempCondition)
		set @index = charindex('hs.Settlement',@ID,0) 
		if(@index > 0)
		begin
			set @Settlement = ' and (' +  @ID + ' '
		end

		set @index = 0
		set @ID = (select top 1 ID from #tableTempCondition)
		set @index = charindex('StatusPay',@ID,0) 
		if(@index > 0)
		begin
			set @StatusPay = ' and (' +  @ID + ' '
		end

		DELETE #tableTempCondition WHERE ID = @ID
		set @row = @row - 1
	 end
	 --select  @conditionCutOffDurationID,@Settlement,@StatusPay

	 if len(@Settlement)=0 
	 begin 
	 set @condition=@condition+' and (hs.Settlement is null)'
	 end

	 drop table #tableTempCondition
	 --select REPLACE(REPLACE(@condition,ltrim(rtrim(@conditionCutOffDurationID)),''),ltrim(rtrim(@StatusPay)),'')
if(@AmountCondittion is not null and @AmountCondittion != '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondittion,0) 
	if(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_EqualToZero''','AVN_NetIncome = 0')
	END
	set @index = charindex('E_LessThanZero',@AmountCondittion,0) 
	if(@index > 0)
	BEGIN
	set @AmountCondittion = REPLACE(@AmountCondittion,'''E_LessThanZero''','AVN_NetIncome < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondittion,0) 
	if(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_GreaterThanZero''','AVN_NetIncome > 0')
	END
end
if(@CheckData is not null and @CheckData != '')
BEGIN
	SET @index = charindex('E_POSTS',@CheckData,0) 
	if(@index > 0)
	BEGIN
	SET @CheckData = REPLACE(@CheckData,'''E_POSTS''','rs.id is not null')
	END
	set @index = charindex('E_UNEXPECTED',@CheckData,0) 
	if(@index > 0)
	BEGIN
	set @CheckData = REPLACE(@CheckData,'''E_UNEXPECTED''','rs.id is null')
	END
end
--[rpt_PayrollMonthlyv2]
set @query = N'
DECLARE @tblPermission TABLE (id uniqueidentifier primary key )
INSERT INTO @tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'
print(''@tblPermission'')
----Lay bang luong chinh
select s.* into #PayrollTable from Sal_PayrollTable s join @tblPermission tb on s.ProfileID = tb.ID
where isdelete is null '+@MonthYear+'
print(''#PayrollTable'')
----Ngay len chinh thuc
select ProfileID,DateEffective,ROW_NUMBER ( ) OVER (PARTITION BY ProfileID order by ProfileID,DateEffective desc) as flag
into #LenChinhThuc
from Hre_WorkHistory
where isdelete is null and TypeOfTransferID in (SELECT id FROM Cat_NameEntity WHERE isdelete IS NULL AND NameEntityType = ''E_Typeoftransfer'' and Code = ''CTOP'')

----Bang luong
select * into 
#Results from 
(
----Ham pivot
select
E_BRANCH,E_UNIT,E_DIVISION,E_DEPARTMENT,E_TEAM,sc.SalaryClassName,PositionName,JobTitleName,h.DateHire,DateEndProbation,ct.DateEffective as LenChinhThuc,DateQuit
,h.IDNo,s.MonthYear
,a.DateStart,a.DateEnd
,cost.Code+''_''+OrgStructureName as OrgStructureNameGroup,OrgStructureName
,et.EmployeeTypeName,case when h.Gender = ''E_FEMALE'' then N''Female'' else N''Male'' end as Gender
,case 
	when h.MarriageStatus = ''E_MARRIED'' then N''Married'' 
	when h.MarriageStatus = ''E_SINGLE'' then N''Single'' 
	when h.MarriageStatus = ''E_WIDOW'' then N''Widow''
	when h.MarriageStatus = ''E_DIVORCE'' then N''Divorce''
	else N''Other'' end as MarriageStatus
,E_COMPANY
,E_COMPANY_CODE,E_UNIT_CODE,E_DIVISION_CODE,E_DEPARTMENT_CODE,E_TEAM_CODE,E_SECTION_CODE,
case when s.IsCash is not null then ''Cash'' else ''Transfer'' end StatusPay,s.AccountNo,CompBankCode,hs.Settlement as "hs.Settlement"
,si.Code,cast(dbo.VnrDecrypt(E_Value) as float ) as Amount,sai.AccountName
,cost.OrderNumber as "cost.OrderNumber",s.CutOffDurationID as "s.CutOffDurationID",
s.PositionID,s.JobTitleID,s.SalaryClassID,h.WorkplaceID,s.EmpStatus,s.EmploymentType,h.ID
from #PayrollTable s
left join Hre_Profile h on s.profileid=h.id 
left join Sal_PayrollTableItem si on s.ID=si.PayrollTableID 
left join Att_CutOffDuration a on s.CutOffDurationID=a.ID 
left join Cat_SalaryClass sc on s.SalaryClassID = sc.id and sc.IsDelete is null
left join Cat_JobTitle cj on s.JobTitleID = cj.ID and cj.IsDelete is null
left join #LenChinhThuc ct on s.ProfileID = ct.ProfileID and ct.flag = ''1''
left join Cat_OrgStructure cost on s.OrgStructureID = cost.ID and cost.IsDelete is null
left join Cat_OrgUnit cu on s.OrgStructureID = cu.OrgStructureID and cu.IsDelete is null
left join Cat_Position cp on s.PositionID = cp.ID and cp.IsDelete is null
left join Cat_EmployeeType et on h.EmpTypeID = et.ID and et.IsDelete is null
left join Cat_Bank cb on s.BankID = cb.ID and cb.IsDelete is null
left join Sal_SalaryInformation sai on sai.ProfileID = s.ProfileID and sai.IsDelete is null
left join Hre_StopWorking hs on s.ProfileID = hs.profileID and hs.isdelete is null and hs.Status=''E_APPROVED''
where h.isdelete is null
'+REPLACE(@condition,ltrim(rtrim(@StatusPay)),'')+'
and si.Code in 
'set @query2 = N'
(
''AVN_LCB'',''AVN_PCGD'',''AVN_PCNL'',''AVN_SMAA'',''AVN_PCCVU'',''AVN_PCCV'',''AVN_PCLCB'',''AVN_PCTH'',''AVN_PCTNIEN_BL'',''AVN_PCCVBL'',''AVN_PCLT'',''AVN_PCDV'',''AVN_PCNO'',''AVN_PCNO2'',''AVN_TCDL'',''AVN_TONG_LTC'',''AVN_LCB_Tinh_TCTV_BHXHBHYTBHTN'',''AVN_SAL_HISTORY'',''AVN_Luong_BHXHYT'',''AVN_Luong_BHTN'',''AVN_NCC'',''AVN_NCTT'',''AVN_WFH'',''AVN_BizInShift'',''AVN_BizLongDay'',''AVN_BizLongDay_Broad'',''AVN_HOLIDAY'',''AVN_AL'',''AVN_PaidLeave_Other'',''AVN_DL'',''AVN_UnPaidLeave'',''AVN_NCTL'',''AVN_LCB_LNC'',''AVN_LNV'',''AVN_TONGLUONGNGAYCONG'',''AVN_PCGD_Amount'',''AVN_PCNL_Amount'',''AVN_SMAA_Amount'',''AVN_PCCVU_Amount'',''AVN_PCCV_Amount'',''AVN_PCLCB_Amount'',''AVN_PCTH_Amount'',''AVN_PCTNIEN_BL_Amount'',''AVN_PCCVBL_Amount'',''AVN_PCLT_Amount'',''AVN_PCDV_Amount'',''AVN_PCNO_Amount'',''AVN_PCNO2_Amount'',''AVN_TCDL_Amount'',''AVN_PCTheoLuong_SUM'',''AVN_OT1_Hours'',''AVN_OT2_Hours'',''AVN_OT2H_Hours'',''AVN_OT_Hours'',''AVN_OT1_Tax'',''AVN_OT1_NonTax'',''AVN_OT2_Tax'',''AVN_OT2_NonTax'',''AVN_OT2_H'',''AVN_OT_SUM'',''AVN_NS1_Hours'',''AVN_NS2_Hours'',''AVN_NS3_Hours'',''AVN_NS4_Hours'',''AVN_NS_Hours'',''AVN_NS1'',''AVN_NS2'',''AVN_NS3'',''AVN_NS4'',''AVN_NS_SUM'',''AVN_I_AUVP1'',''AVN_I_AUVP1_OT'',''AVN_I_AUVP2'',''AVN_I_AUVP2_OT'',''AVN_I_AUCT1'',''AVN_I_AUCT1_OT'',''AVN_I_AUCT2'',''AVN_I_AUCT2_OT'',''AVN_I_AUWFH'',''AVN_I_AUWFH_OT'',''AVN_I_GXE'',''AVN_I_LTRU''
,''AVN_I_TCCTP'',''AVN_I_DLCT'',''AVN_I_KSK'',''AVN_I_SFSUPPORT'',''AVN_I_WEDA'',''AVN_I_BIRA'',''AVN_I_FURA'',''AVN_I_OTC'',''AVN_I_TCCC'',''AVN_I_TCKC'',''AVN_I_DCCT1'',''AVN_I_DCCT2'',''AVN_I_KSKDK'',''AVN_I_KSKDB'',''AVN_I_GIFT'',''AVN_I_THEDT'',''AVN_I_DPHUC'',''AVN_I_GIFT_CD'',''AVN_I_DLCV'',''AVN_I_DLGD'',''AVN_I_NMAT'',''AVN_I_TCTT'',''AVN_I_INTAX'',''AVN_I_AN'',''AVN_I_TNRR'',''AVN_I_OTHER'',''AVN_ThuNhapKhac_TrongThang'',''AVN_I_TETBONUS'',''AVN_I_SLR13'',''AVN_I_S_BONUS'',''AVN_I_TL_2_9'',''AVN_I_TL_1_1'',''AVN_I_LT_REWARD_10'',''AVN_I_LT_REWARD_15_20_25_30'',''AVN_TongThuong_TrongThang'',''AVN_IA_LCB'',''AVN_IA_LNV'',''AVN_IA_LNC'',''AVN_IA_PCGD'',''AVN_IA_PCNO'',''AVN_IA_PCNO2'',''AVN_IA_PCNL'',''AVN_IA_SMAA'',''AVN_IA_PCCVU'',''AVN_IA_PCCV'',''AVN_IA_PCLCB'',''AVN_IA_PCTH'',''AVN_IA_TCDL'',''AVN_IA_PCDV'',''AVN_IA_PCTNIEN_BL'',''AVN_IA_PCCVBL'',''AVN_IA_PCLT'',''AVN_IA_PC_TC'',''AVN_IA_OT1_Tax'',''AVN_IA_OT1_NonTax'',''AVN_IA_OT2_Tax'',''AVN_IA_OT2_NonTax'',''AVN_IA_OT2H'',''AVN_IA_OT'',''AVN_IA_NS1'',''AVN_IA_NS2'',''AVN_IA_NS3'',''AVN_IA_NS4'',''AVN_IA_NS'',''AVN_IA_DCCT1'',''AVN_IA_DCCT2'',''AVN_IA_TCCC'',''AVN_IA_TCKC'',''AVN_IA_SLR13'',''AVN_IA_S_BONUS'',''AVN_IA_TETBONUS'',''AVN_IA_TL1_1'',''AVN_IA_TL2_9'',''AVN_IA_LT_REWARD_10'',''AVN_IA_LT_REWARD_15_20_25_30'',''AVN_IA_BHXH_BHYT_BHTN'',''AVN_IA_TU_BHYT'',''AVN_IA_PCTT'',''AVN_IA_OTC'',''AVN_IA_INTAX'',''AVN_IA_AN''
,''AVN_IA_TNRR'',''AVN_IA_Other'',''AVN_TruyLinh'',''AVN_LuongThuong_SUM'',''AVN_ThuNhapKhongChiuThue'',''AVN_ThuNhapChiuThue'',''AVN_PCD'',''AVN_D_THENV'',''AVN_D_PCTT'',''AVN_D_INTAX'',''AVN_D_AN'',''AVN_D_OTHER'',''AVN_Deduction_SUM'',''AVN_DA_LCB'',''AVN_DA_LNV'',''AVN_DA_LNC'',''AVN_DA_PCGD'',''AVN_DA_PCNO'',''AVN_DA_PCNO2'',''AVN_DA_PCNL'',''AVN_DA_SMAA'',''AVN_DA_PCCVU'',''AVN_DA_PCCV'',''AVN_DA_PCLCB'',''AVN_DA_PCTH'',''AVN_DA_TCDL'',''AVN_DA_PCDV'',''AVN_DA_PCTNIEN_BL'',''AVN_DA_PCCVBL'',''AVN_DA_PCLT'',''AVN_DA_PC_TC'',''AVN_DA_OT1_Tax'',''AVN_DA_OT1_NonTax'',''AVN_DA_OT2_Tax'',''AVN_DA_OT2_NonTax'',''AVN_DA_OT2H'',''AVN_DA_OT'',''AVN_DA_NS1'',''AVN_DA_NS2'',''AVN_DA_NS3'',''AVN_DA_NS4'',''AVN_DA_NS'',''AVN_DA_DCCT1'',''AVN_DA_DCCT2'',''AVN_DA_OTC'',''AVN_DA_TCCC'',''AVN_DA_TCKC'',''AVN_DA_SLR13'',''AVN_DA_S_BONUS'',''AVN_DA_TETBONUS'',''AVN_DA_TL1_1'',''AVN_DA_TL2_9'',''AVN_DA_LT_REWARD_10'',''AVN_DA_LT_REWARD_15_20_25_30'',''AVN_DA_BHXH_BHYT_BHTN'',''AVN_DA_TT_BHYT'',''AVN_DA_AUVP1'',''AVN_DA_AUVP1_OT'',''AVN_DA_AUVP2'',''AVN_DA_AUVP2_OT'',''AVN_DA_AUCT1'',''AVN_DA_AUCT1_OT'',''AVN_DA_AUCT2'',''AVN_DA_AUCT2_OT'',''AVN_DA_AUWFH'',''AVN_DA_AUWFH_OT'',''AVN_DA_SFSUPPORT'',''AVN_DA_WEDA'',''AVN_DA_BIRA'',''AVN_DA_FURA'',''AVN_DA_GXE'',''AVN_DA_LTRU'',''AVN_DA_TCCTP'',''AVN_DA_DLCT'',''AVN_DA_KSK'',''AVN_DA_KSKDK'',''AVN_DA_KSKDB'',''AVN_DA_GIFT''
,''AVN_DA_THEDT'',''AVN_DA_DPHUC'',''AVN_DA_GIFT_CD'',''AVN_DA_DLCV'',''AVN_DA_DLGD'',''AVN_DA_NMAT'',''AVN_DA_TCTT'',''AVN_DA_INTAX'',''AVN_DA_AN'',''AVN_DA_TNRR'',''AVN_DA_Other'',''AVN_TruyThu'',''AVN_BHXH_C'',''AVN_BHYT_C'',''AVN_BHTN_C'',''AVN_BHXH_E'',''AVN_BHYT_E'',''AVN_BHTN_E'',''AVN_TT_BHYT_E'',''AVN_NguoiPhuThuoc'',''AVN_GiamTruPhuThuoc'',''AVN_GiamTruBanThan'',''AVN_TinhThue'',''AVN_ThuePIT'',''AVN_LuongTinh_TCTV'',''AVN_SoNamHuongTCTV'',''AVN_TCTV_NonTaxable'',''AVN_TCTV_Taxable'',''AVN_TCTV_Tax'',''AVN_TongKhoanKhauTru'',''AVN_GrossIncome'',''AVN_AdvancePay'',''AVN_NetIncome''
)
) T

Pivot 
(
sum(Amount) for code  in (
[AVN_LCB],[AVN_PCGD],[AVN_PCNL],[AVN_SMAA],[AVN_PCCVU],[AVN_PCCV],[AVN_PCLCB],[AVN_PCTH],[AVN_PCTNIEN_BL],[AVN_PCCVBL],[AVN_PCLT],[AVN_PCDV],[AVN_PCNO],[AVN_PCNO2],[AVN_TCDL],[AVN_TONG_LTC],[AVN_LCB_Tinh_TCTV_BHXHBHYTBHTN],[AVN_SAL_HISTORY],[AVN_Luong_BHXHYT],[AVN_Luong_BHTN],[AVN_NCC],[AVN_NCTT],[AVN_WFH],[AVN_BizInShift],[AVN_BizLongDay],[AVN_BizLongDay_Broad],[AVN_HOLIDAY],[AVN_AL],[AVN_PaidLeave_Other],[AVN_DL],[AVN_UnPaidLeave],[AVN_NCTL],[AVN_LCB_LNC],[AVN_LNV],[AVN_TONGLUONGNGAYCONG],[AVN_PCGD_Amount],[AVN_PCNL_Amount],[AVN_SMAA_Amount],[AVN_PCCVU_Amount],[AVN_PCCV_Amount],[AVN_PCLCB_Amount],[AVN_PCTH_Amount],[AVN_PCTNIEN_BL_Amount],[AVN_PCCVBL_Amount],[AVN_PCLT_Amount],[AVN_PCDV_Amount],[AVN_PCNO_Amount],[AVN_PCNO2_Amount],[AVN_TCDL_Amount],[AVN_PCTheoLuong_SUM],[AVN_OT1_Hours],[AVN_OT2_Hours],[AVN_OT2H_Hours],[AVN_OT_Hours],[AVN_OT1_Tax],[AVN_OT1_NonTax],[AVN_OT2_Tax],[AVN_OT2_NonTax],[AVN_OT2_H],[AVN_OT_SUM],[AVN_NS1_Hours],[AVN_NS2_Hours],[AVN_NS3_Hours],[AVN_NS4_Hours],[AVN_NS_Hours],[AVN_NS1],[AVN_NS2],[AVN_NS3],[AVN_NS4],[AVN_NS_SUM],[AVN_I_AUVP1],[AVN_I_AUVP1_OT],[AVN_I_AUVP2],[AVN_I_AUVP2_OT],[AVN_I_AUCT1],[AVN_I_AUCT1_OT],[AVN_I_AUCT2],[AVN_I_AUCT2_OT],[AVN_I_AUWFH],[AVN_I_AUWFH_OT],[AVN_I_GXE],[AVN_I_LTRU],[AVN_I_TCCTP],[AVN_I_DLCT],[AVN_I_KSK],[AVN_I_SFSUPPORT],[AVN_I_WEDA],[AVN_I_BIRA],[AVN_I_FURA],[AVN_I_OTC],[AVN_I_TCCC],[AVN_I_TCKC],[AVN_I_DCCT1],[AVN_I_DCCT2],[AVN_I_KSKDK],[AVN_I_KSKDB],[AVN_I_GIFT],[AVN_I_THEDT],[AVN_I_DPHUC],[AVN_I_GIFT_CD],[AVN_I_DLCV],[AVN_I_DLGD],[AVN_I_NMAT],[AVN_I_TCTT],[AVN_I_INTAX],[AVN_I_AN],[AVN_I_TNRR],[AVN_I_OTHER],[AVN_ThuNhapKhac_TrongThang],[AVN_I_TETBONUS],[AVN_I_SLR13],[AVN_I_S_BONUS],[AVN_I_TL_2_9],[AVN_I_TL_1_1],[AVN_I_LT_REWARD_10],[AVN_I_LT_REWARD_15_20_25_30],[AVN_TongThuong_TrongThang],[AVN_IA_LCB],[AVN_IA_LNV],[AVN_IA_LNC],[AVN_IA_PCGD],[AVN_IA_PCNO],[AVN_IA_PCNO2],[AVN_IA_PCNL],[AVN_IA_SMAA],[AVN_IA_PCCVU],[AVN_IA_PCCV],[AVN_IA_PCLCB],[AVN_IA_PCTH],[AVN_IA_TCDL],[AVN_IA_PCDV],[AVN_IA_PCTNIEN_BL],[AVN_IA_PCCVBL],[AVN_IA_PCLT],[AVN_IA_PC_TC],[AVN_IA_OT1_Tax],[AVN_IA_OT1_NonTax],[AVN_IA_OT2_Tax],[AVN_IA_OT2_NonTax],[AVN_IA_OT2H],[AVN_IA_OT],[AVN_IA_NS1],[AVN_IA_NS2],[AVN_IA_NS3],[AVN_IA_NS4],[AVN_IA_NS],[AVN_IA_DCCT1],[AVN_IA_DCCT2],[AVN_IA_TCCC],[AVN_IA_TCKC],[AVN_IA_SLR13],[AVN_IA_S_BONUS],[AVN_IA_TETBONUS],[AVN_IA_TL1_1],[AVN_IA_TL2_9],[AVN_IA_LT_REWARD_10],[AVN_IA_LT_REWARD_15_20_25_30],[AVN_IA_BHXH_BHYT_BHTN],[AVN_IA_TU_BHYT],[AVN_IA_PCTT],[AVN_IA_OTC],[AVN_IA_INTAX],[AVN_IA_AN],[AVN_IA_TNRR],[AVN_IA_Other],[AVN_TruyLinh],[AVN_LuongThuong_SUM],[AVN_ThuNhapKhongChiuThue],[AVN_ThuNhapChiuThue],[AVN_PCD],[AVN_D_THENV],[AVN_D_PCTT],[AVN_D_INTAX],[AVN_D_AN],[AVN_D_OTHER],[AVN_Deduction_SUM],[AVN_DA_LCB],[AVN_DA_LNV],[AVN_DA_LNC],[AVN_DA_PCGD],[AVN_DA_PCNO],[AVN_DA_PCNO2],[AVN_DA_PCNL],[AVN_DA_SMAA],[AVN_DA_PCCVU],[AVN_DA_PCCV],[AVN_DA_PCLCB],[AVN_DA_PCTH],[AVN_DA_TCDL],[AVN_DA_PCDV],[AVN_DA_PCTNIEN_BL],[AVN_DA_PCCVBL],[AVN_DA_PCLT],[AVN_DA_PC_TC],[AVN_DA_OT1_Tax],[AVN_DA_OT1_NonTax],[AVN_DA_OT2_Tax],[AVN_DA_OT2_NonTax],[AVN_DA_OT2H],[AVN_DA_OT],[AVN_DA_NS1],[AVN_DA_NS2],[AVN_DA_NS3],[AVN_DA_NS4],[AVN_DA_NS],[AVN_DA_DCCT1],[AVN_DA_DCCT2],[AVN_DA_OTC],[AVN_DA_TCCC],[AVN_DA_TCKC],[AVN_DA_SLR13],[AVN_DA_S_BONUS],[AVN_DA_TETBONUS],[AVN_DA_TL1_1],[AVN_DA_TL2_9],[AVN_DA_LT_REWARD_10],[AVN_DA_LT_REWARD_15_20_25_30],[AVN_DA_BHXH_BHYT_BHTN],[AVN_DA_TT_BHYT],[AVN_DA_AUVP1],[AVN_DA_AUVP1_OT],[AVN_DA_AUVP2],[AVN_DA_AUVP2_OT],[AVN_DA_AUCT1],[AVN_DA_AUCT1_OT],[AVN_DA_AUCT2],[AVN_DA_AUCT2_OT],[AVN_DA_AUWFH],[AVN_DA_AUWFH_OT],[AVN_DA_SFSUPPORT],[AVN_DA_WEDA],[AVN_DA_BIRA],[AVN_DA_FURA],[AVN_DA_GXE],[AVN_DA_LTRU],[AVN_DA_TCCTP],[AVN_DA_DLCT],[AVN_DA_KSK],[AVN_DA_KSKDK],[AVN_DA_KSKDB],[AVN_DA_GIFT],[AVN_DA_THEDT],[AVN_DA_DPHUC],[AVN_DA_GIFT_CD],[AVN_DA_DLCV],[AVN_DA_DLGD],[AVN_DA_NMAT],[AVN_DA_TCTT],[AVN_DA_INTAX],[AVN_DA_AN],[AVN_DA_TNRR],[AVN_DA_Other],[AVN_TruyThu],[AVN_BHXH_C],[AVN_BHYT_C],[AVN_BHTN_C],[AVN_BHXH_E],[AVN_BHYT_E],[AVN_BHTN_E],[AVN_TT_BHYT_E],[AVN_NguoiPhuThuoc],[AVN_GiamTruPhuThuoc],[AVN_GiamTruBanThan],[AVN_TinhThue],[AVN_ThuePIT],[AVN_LuongTinh_TCTV],[AVN_SoNamHuongTCTV],[AVN_TCTV_NonTaxable],[AVN_TCTV_Taxable],[AVN_TCTV_Tax],[AVN_TongKhoanKhauTru],[AVN_GrossIncome],[AVN_AdvancePay],[AVN_NetIncome]
)
) P
'

set @queryPageSize = N'
DECLARE @DateStart datetime
DECLARE @DateEnd datetime
SET @DateStart = (select datestart from Att_CutOffDuration where isdelete is null '+@MonthYear+')
SET @DateEnd = (select dateend from Att_CutOffDuration where isdelete is null '+@MonthYear+')

select row_number() over (partition by rs.MonthYear
order by h.CodeEmp) as RNCK
,h.CodeEmp,h.ProfileName
,rs.*
,getdate() as ExportDate
,NULL as "s.PositionID"
,NULL as "s.JobTitleID"
,NULL as "s.SalaryClassID"
,NULL as "h.WorkplaceID"
,NULL as "s.EmpStatus"
,NULL as "s.EmploymentType"
,NULL as "h.DateHire"
,NULL as "DateEndProbation"
,NULL as "DateQuit"
,NULL as "AmountCondittion"
,NULL as "CheckData"
,NULL as "MonthYear"
,NULL as "h.LaborType"
,NULL as "h.EmployeeGroupID"
from Hre_Profile h
left join #Results rs on h.id = rs.id
where 
(h.DateQuit is null or h.DateQuit >= @DateStart)
and h.DateHire <= @DateEnd and h.isdelete is null
'+@StatusPay+' '+@AmountCondittion+' '+@CheckData+'
order by rs.MonthYear,rs.E_COMPANY_CODE,rs.E_UNIT_CODE,rs.E_DIVISION_CODE,rs.E_DEPARTMENT_CODE,rs.E_TEAM_CODE,rs.E_SECTION_CODE,h.CodeEmp

drop table #PayrollTable
drop table #Results
'
print(@query) 
print(@query2)
print(@queryPageSize)
exec(@query + @query2+' ' + @queryPageSize)

END
--[rpt_PayrollMonthlyV2]