
alter proc rpt_PayrollMonthlyV2
--@condition nvarchar(max) =  " and (MonthYear = '2021-04-01') and (CheckData like N'%E_UNEXPECTED%') ",
@condition nvarchar(max) =  " and (MonthYear = '2021-09-01') ",
@PageIndex int = 1,
@PageSize int = 5000,
@Username varchar(100) = 'khang.nguyen'
as
begin

IF @condition = ' ' 
begin
set @condition =  ' and (MonthYear = ''2021-09-01'') '
END

declare @conditionCutOffDurationID varchar(100)
declare @Settlement varchar(100)
declare @PayPaidType varchar(100) = ''
declare @str varchar(max)
declare @countrow int
declare @row int
declare @index int
declare @ID varchar(200)

 ----Xu ly Amount Condition----
declare @tempID nvarchar(Max)
declare @tempCodition nvarchar(Max)
declare @AmountCondition nvarchar(100) = ''
DECLARE @MonthYear nvarchar(50) = ' '
DECLARE @CheckData nvarchar(50) = ' '
 -- xử lý tách dk

	 set @conditionCutOffDurationID = ''
	 set @Settlement = ''
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

		set @index = charindex('MonthYear = ',@tempID,0) 
		if(@index > 0)
		begin
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @MonthYear = @tempCodition
		end

		set @index = charindex('CheckData ',@tempID,0)
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @CheckData = REPLACE(@tempCodition,'CheckData','')
			set @CheckData = REPLACE(@CheckData,'like N','')
			set @CheckData = REPLACE(@CheckData,'%','')
		end

		set @index = charindex('(AmountCondition ','('+@tempID,0)
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @AmountCondition = REPLACE(@tempCodition,'(AmountCondition in ','')
			set @AmountCondition = REPLACE(@AmountCondition,',',' OR ')
			set @AmountCondition = REPLACE(@AmountCondition,'))',')')
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


if(@AmountCondition is not null and @AmountCondition != '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondition,0) 
	if(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_EqualToZero''','SalaryAmount = 0')
	END
	set @index = charindex('E_LessThanZero',@AmountCondition,0) 
	if(@index > 0)
	BEGIN
	set @AmountCondition = REPLACE(@AmountCondition,'''E_LessThanZero''','SalaryAmount < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondition,0) 
	if(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_GreaterThanZero''','SalaryAmount > 0')
	END
end

if(@CheckData is not null and @CheckData != '')
BEGIN
	SET @index = charindex('E_POSTS',@CheckData,0) 
	if(@index > 0)
	BEGIN
	SET @CheckData = REPLACE(@CheckData,'''E_POSTS''','PayrollTableID is not null')
	END
	set @index = charindex('E_UNEXPECTED',@CheckData,0) 
	if(@index > 0)
	BEGIN
	set @CheckData = REPLACE(@CheckData,'''E_UNEXPECTED''','PayrollTableID is null')
	END
end
--[rpt_PayrollMonthlyv2]

DECLARE @getdata nvarchar(max)
DECLARE @query nvarchar(MAX)
DECLARE @query2 nvarchar(MAX)
DECLARE @pivot NVARCHAR(max)
DECLARE @querybonus nvarchar(MAX)
DECLARE @queryPageSize nvarchar(max)


DECLARE @Element NVARCHAR(max)
DECLARE @ElementPivot NVARCHAR(max)

DECLARE @ElementPayslip NVARCHAR(max)
DECLARE @ElementPayslipPivot NVARCHAR(max)

SET @Element = ' AND spti.Code IN(''NotHaveSalary'',''AVN_LCB'',''AVN_PCGD'',''AVN_PCNL'',''AVN_SMAA'',''AVN_PCCVU'',''AVN_PCCV'',''AVN_PCLCB'',''AVN_PCTH'',''AVN_PCTNIEN_BL'',''AVN_PCCVBL'',''AVN_PCLT'',''AVN_PCDV'',''AVN_PCNO'',''AVN_PCNO2'',''AVN_TCDL'',''AVN_TONG_LTC'',''AVN_LCB_Tinh_TCTV_BHXHBHYTBHTN'',''AVN_SAL_HISTORY'',''AVN_Luong_BHXHYT'',''AVN_Luong_BHTN'',''AVN_NCC'',''AVN_NCTT'',''AVN_WFH'',''AVN_BizInShift'',''AVN_BizLongDay'',''AVN_BizLongDay_Broad'',''AVN_HOLIDAY'',''AVN_AL'',''AVN_PaidLeave_Other'',''AVN_DL'',''AVN_UnPaidLeave'',''AVN_NCTL'',''AVN_LCB_LNC'',''AVN_LNV'',''AVN_TONGLUONGNGAYCONG'',''AVN_PCGD_Amount'',''AVN_PCNL_Amount'',''AVN_SMAA_Amount'',''AVN_PCCVU_Amount'',''AVN_PCCV_Amount'',''AVN_PCLCB_Amount'',''AVN_PCTH_Amount'',''AVN_PCTNIEN_BL_Amount'',''AVN_PCCVBL_Amount'',''AVN_PCLT_Amount'',''AVN_PCDV_Amount'',''AVN_PCNO_Amount'',''AVN_PCNO2_Amount'',''AVN_TCDL_Amount'',''AVN_PCTheoLuong_SUM'',''AVN_OT1_Hours'',''AVN_OT2_Hours'',''AVN_OT2H_Hours'',''AVN_OT_Hours'',''AVN_OT1_Tax'',''AVN_OT1_NonTax'',''AVN_OT2_Tax'',''AVN_OT2_NonTax'',''AVN_OT2_H'',''AVN_OT_SUM'',''AVN_NS1_Hours'',''AVN_NS2_Hours'',''AVN_NS3_Hours'',''AVN_NS4_Hours'',''AVN_NS_Hours'',''AVN_NS1'',''AVN_NS2'',''AVN_NS3'',''AVN_NS4'',''AVN_NS_SUM'',''AVN_I_AUVP1'',''AVN_I_AUVP1_OT'',''AVN_I_AUVP2'',''AVN_I_AUVP2_OT'',''AVN_I_AUCT1'',''AVN_I_AUCT1_OT'',''AVN_I_AUCT2'',''AVN_I_AUCT2_OT'',''AVN_I_AUWFH'',''AVN_I_AUWFH_OT'',''AVN_I_GXE'',''AVN_I_LTRU''
,''AVN_I_TCCTP'',''AVN_I_DLCT'',''AVN_I_KSK'',''AVN_I_SFSUPPORT'',''AVN_I_WEDA'',''AVN_I_BIRA'',''AVN_I_FURA'',''AVN_I_OTC'',''AVN_I_TCCC'',''AVN_I_TCKC'',''AVN_I_DCCT1'',''AVN_I_DCCT2'',''AVN_I_KSKDK'',''AVN_I_KSKDB'',''AVN_I_GIFT'',''AVN_I_THEDT'',''AVN_I_DPHUC'',''AVN_I_GIFT_CD'',''AVN_I_DLCV'',''AVN_I_DLGD'',''AVN_I_NMAT'',''AVN_I_TCTT'',''AVN_I_INTAX'',''AVN_I_AN'',''AVN_I_TNRR'',''AVN_I_OTHER'',''AVN_ThuNhapKhac_TrongThang'',''AVN_I_TETBONUS'',''AVN_I_SLR13'',''AVN_I_S_BONUS'',''AVN_I_TL_2_9'',''AVN_I_TL_1_1'',''AVN_I_LT_REWARD_10'',''AVN_I_LT_REWARD_15_20_25_30'',''AVN_TongThuong_TrongThang'',''AVN_IA_LCB'',''AVN_IA_LNV'',''AVN_IA_LNC'',''AVN_IA_PCGD'',''AVN_IA_PCNO'',''AVN_IA_PCNO2'',''AVN_IA_PCNL'',''AVN_IA_SMAA'',''AVN_IA_PCCVU'',''AVN_IA_PCCV'',''AVN_IA_PCLCB'',''AVN_IA_PCTH'',''AVN_IA_TCDL'',''AVN_IA_PCDV'',''AVN_IA_PCTNIEN_BL'',''AVN_IA_PCCVBL'',''AVN_IA_PCLT'',''AVN_IA_PC_TC'',''AVN_IA_OT1_Tax'',''AVN_IA_OT1_NonTax'',''AVN_IA_OT2_Tax'',''AVN_IA_OT2_NonTax'',''AVN_IA_OT2H'',''AVN_IA_OT'',''AVN_IA_NS1'',''AVN_IA_NS2'',''AVN_IA_NS3'',''AVN_IA_NS4'',''AVN_IA_NS'',''AVN_IA_DCCT1'',''AVN_IA_DCCT2'',''AVN_IA_TCCC'',''AVN_IA_TCKC'',''AVN_IA_SLR13'',''AVN_IA_S_BONUS'',''AVN_IA_TETBONUS'',''AVN_IA_TL1_1'',''AVN_IA_TL2_9'',''AVN_IA_LT_REWARD_10'',''AVN_IA_LT_REWARD_15_20_25_30'',''AVN_IA_BHXH_BHYT_BHTN'',''AVN_IA_TU_BHYT'',''AVN_IA_PCTT'',''AVN_IA_OTC'',''AVN_IA_INTAX'',''AVN_IA_AN''
,''AVN_IA_TNRR'',''AVN_IA_Other'',''AVN_TruyLinh'',''AVN_LuongThuong_SUM'',''AVN_ThuNhapKhongChiuThue'',''AVN_ThuNhapChiuThue'',''AVN_PCD'',''AVN_D_THENV'',''AVN_D_PCTT'',''AVN_D_INTAX'',''AVN_D_AN'',''AVN_D_OTHER'',''AVN_Deduction_SUM'',''AVN_DA_LCB'',''AVN_DA_LNV'',''AVN_DA_LNC'',''AVN_DA_PCGD'',''AVN_DA_PCNO'',''AVN_DA_PCNO2'',''AVN_DA_PCNL'',''AVN_DA_SMAA'',''AVN_DA_PCCVU'',''AVN_DA_PCCV'',''AVN_DA_PCLCB'',''AVN_DA_PCTH'',''AVN_DA_TCDL'',''AVN_DA_PCDV'',''AVN_DA_PCTNIEN_BL'',''AVN_DA_PCCVBL'',''AVN_DA_PCLT'',''AVN_DA_PC_TC'',''AVN_DA_OT1_Tax'',''AVN_DA_OT1_NonTax'',''AVN_DA_OT2_Tax'',''AVN_DA_OT2_NonTax'',''AVN_DA_OT2H'',''AVN_DA_OT'',''AVN_DA_NS1'',''AVN_DA_NS2'',''AVN_DA_NS3'',''AVN_DA_NS4'',''AVN_DA_NS'',''AVN_DA_DCCT1'',''AVN_DA_DCCT2'',''AVN_DA_OTC'',''AVN_DA_TCCC'',''AVN_DA_TCKC'',''AVN_DA_SLR13'',''AVN_DA_S_BONUS'',''AVN_DA_TETBONUS'',''AVN_DA_TL1_1'',''AVN_DA_TL2_9'',''AVN_DA_LT_REWARD_10'',''AVN_DA_LT_REWARD_15_20_25_30'',''AVN_DA_BHXH_BHYT_BHTN'',''AVN_DA_TT_BHYT'',''AVN_DA_AUVP1'',''AVN_DA_AUVP1_OT'',''AVN_DA_AUVP2'',''AVN_DA_AUVP2_OT'',''AVN_DA_AUCT1'',''AVN_DA_AUCT1_OT'',''AVN_DA_AUCT2'',''AVN_DA_AUCT2_OT'',''AVN_DA_AUWFH'',''AVN_DA_AUWFH_OT'',''AVN_DA_SFSUPPORT'',''AVN_DA_WEDA'',''AVN_DA_BIRA'',''AVN_DA_FURA'',''AVN_DA_GXE'',''AVN_DA_LTRU'',''AVN_DA_TCCTP'',''AVN_DA_DLCT'',''AVN_DA_KSK'',''AVN_DA_KSKDK'',''AVN_DA_KSKDB'',''AVN_DA_GIFT''
,''AVN_DA_THEDT'',''AVN_DA_DPHUC'',''AVN_DA_GIFT_CD'',''AVN_DA_DLCV'',''AVN_DA_DLGD'',''AVN_DA_NMAT'',''AVN_DA_TCTT'',''AVN_DA_INTAX'',''AVN_DA_AN'',''AVN_DA_TNRR'',''AVN_DA_Other'',''AVN_TruyThu'',''AVN_BHXH_C'',''AVN_BHYT_C'',''AVN_BHTN_C'',''AVN_BHXH_E'',''AVN_BHYT_E'',''AVN_BHTN_E'',''AVN_TT_BHYT_E'',''AVN_SoNguoiPhuThuoc'',''AVN_GiamTruPhuThuoc'',''AVN_GiamTruBanThan'',''AVN_TinhThue'',''AVN_ThuePIT'',''AVN_LuongTinh_TCTV'',''AVN_SoNamHuongTCTV'',''AVN_TCTV_NonTaxable'',''AVN_TCTV_Taxable'',''AVN_TCTV_Tax'',''AVN_TongKhoanKhauTru'',''AVN_GrossIncome'',''AVN_AdvancePay'',''AVN_NetIncome'')'



SET @ElementPivot = '[NotHaveSalary],[AVN_LCB],[AVN_PCGD],[AVN_PCNL],[AVN_SMAA],[AVN_PCCVU],[AVN_PCCV],[AVN_PCLCB],[AVN_PCTH],[AVN_PCTNIEN_BL],[AVN_PCCVBL],[AVN_PCLT],[AVN_PCDV],[AVN_PCNO],[AVN_PCNO2],[AVN_TCDL],[AVN_TONG_LTC],[AVN_LCB_Tinh_TCTV_BHXHBHYTBHTN],[AVN_SAL_HISTORY],[AVN_Luong_BHXHYT],[AVN_Luong_BHTN],[AVN_NCC],[AVN_NCTT],[AVN_WFH],[AVN_BizInShift],[AVN_BizLongDay],[AVN_BizLongDay_Broad],[AVN_HOLIDAY],[AVN_AL],[AVN_PaidLeave_Other],[AVN_DL],[AVN_UnPaidLeave],[AVN_NCTL],[AVN_LCB_LNC],[AVN_LNV],[AVN_TONGLUONGNGAYCONG],[AVN_PCGD_Amount],[AVN_PCNL_Amount],[AVN_SMAA_Amount],[AVN_PCCVU_Amount],[AVN_PCCV_Amount],[AVN_PCLCB_Amount],[AVN_PCTH_Amount],[AVN_PCTNIEN_BL_Amount],[AVN_PCCVBL_Amount],[AVN_PCLT_Amount],[AVN_PCDV_Amount],[AVN_PCNO_Amount],[AVN_PCNO2_Amount],[AVN_TCDL_Amount],[AVN_PCTheoLuong_SUM],[AVN_OT1_Hours],[AVN_OT2_Hours],[AVN_OT2H_Hours],[AVN_OT_Hours],[AVN_OT1_Tax],[AVN_OT1_NonTax],[AVN_OT2_Tax],[AVN_OT2_NonTax],[AVN_OT2_H],[AVN_OT_SUM],[AVN_NS1_Hours],[AVN_NS2_Hours],[AVN_NS3_Hours],[AVN_NS4_Hours],[AVN_NS_Hours],[AVN_NS1],[AVN_NS2],[AVN_NS3],[AVN_NS4],[AVN_NS_SUM],[AVN_I_AUVP1],[AVN_I_AUVP1_OT],[AVN_I_AUVP2],[AVN_I_AUVP2_OT],[AVN_I_AUCT1],[AVN_I_AUCT1_OT],[AVN_I_AUCT2],[AVN_I_AUCT2_OT],[AVN_I_AUWFH],[AVN_I_AUWFH_OT],[AVN_I_GXE],[AVN_I_LTRU],[AVN_I_TCCTP],[AVN_I_DLCT],[AVN_I_KSK],[AVN_I_SFSUPPORT],[AVN_I_WEDA],[AVN_I_BIRA],[AVN_I_FURA],[AVN_I_OTC],[AVN_I_TCCC],[AVN_I_TCKC],[AVN_I_DCCT1],[AVN_I_DCCT2]
,[AVN_I_KSKDK],[AVN_I_KSKDB],[AVN_I_GIFT],[AVN_I_THEDT],[AVN_I_DPHUC],[AVN_I_GIFT_CD],[AVN_I_DLCV],[AVN_I_DLGD],[AVN_I_NMAT],[AVN_I_TCTT],[AVN_I_INTAX],[AVN_I_AN],[AVN_I_TNRR],[AVN_I_OTHER],[AVN_ThuNhapKhac_TrongThang],[AVN_I_TETBONUS],[AVN_I_SLR13],[AVN_I_S_BONUS],[AVN_I_TL_2_9],[AVN_I_TL_1_1],[AVN_I_LT_REWARD_10],[AVN_I_LT_REWARD_15_20_25_30],[AVN_TongThuong_TrongThang],[AVN_IA_LCB],[AVN_IA_LNV],[AVN_IA_LNC],[AVN_IA_PCGD],[AVN_IA_PCNO],[AVN_IA_PCNO2],[AVN_IA_PCNL],[AVN_IA_SMAA],[AVN_IA_PCCVU],[AVN_IA_PCCV],[AVN_IA_PCLCB],[AVN_IA_PCTH],[AVN_IA_TCDL],[AVN_IA_PCDV],[AVN_IA_PCTNIEN_BL],[AVN_IA_PCCVBL],[AVN_IA_PCLT],[AVN_IA_PC_TC],[AVN_IA_OT1_Tax],[AVN_IA_OT1_NonTax],[AVN_IA_OT2_Tax],[AVN_IA_OT2_NonTax],[AVN_IA_OT2H],[AVN_IA_OT],[AVN_IA_NS1],[AVN_IA_NS2],[AVN_IA_NS3],[AVN_IA_NS4],[AVN_IA_NS],[AVN_IA_DCCT1],[AVN_IA_DCCT2],[AVN_IA_TCCC],[AVN_IA_TCKC],[AVN_IA_SLR13],[AVN_IA_S_BONUS],[AVN_IA_TETBONUS],[AVN_IA_TL1_1],[AVN_IA_TL2_9],[AVN_IA_LT_REWARD_10],[AVN_IA_LT_REWARD_15_20_25_30],[AVN_IA_BHXH_BHYT_BHTN],[AVN_IA_TU_BHYT],[AVN_IA_PCTT],[AVN_IA_OTC],[AVN_IA_INTAX],[AVN_IA_AN],[AVN_IA_TNRR],[AVN_IA_Other],[AVN_TruyLinh],[AVN_LuongThuong_SUM],[AVN_ThuNhapKhongChiuThue],[AVN_ThuNhapChiuThue],[AVN_PCD],[AVN_D_THENV],[AVN_D_PCTT],[AVN_D_INTAX],[AVN_D_AN],[AVN_D_OTHER],[AVN_Deduction_SUM],[AVN_DA_LCB],[AVN_DA_LNV],[AVN_DA_LNC],[AVN_DA_PCGD],[AVN_DA_PCNO],[AVN_DA_PCNO2],[AVN_DA_PCNL],[AVN_DA_SMAA],[AVN_DA_PCCVU],[AVN_DA_PCCV],[AVN_DA_PCLCB]
,[AVN_DA_PCTH],[AVN_DA_TCDL],[AVN_DA_PCDV],[AVN_DA_PCTNIEN_BL],[AVN_DA_PCCVBL],[AVN_DA_PCLT],[AVN_DA_PC_TC],[AVN_DA_OT1_Tax],[AVN_DA_OT1_NonTax],[AVN_DA_OT2_Tax],[AVN_DA_OT2_NonTax],[AVN_DA_OT2H],[AVN_DA_OT],[AVN_DA_NS1],[AVN_DA_NS2],[AVN_DA_NS3],[AVN_DA_NS4],[AVN_DA_NS],[AVN_DA_DCCT1],[AVN_DA_DCCT2],[AVN_DA_OTC],[AVN_DA_TCCC],[AVN_DA_TCKC],[AVN_DA_SLR13],[AVN_DA_S_BONUS],[AVN_DA_TETBONUS],[AVN_DA_TL1_1],[AVN_DA_TL2_9],[AVN_DA_LT_REWARD_10],[AVN_DA_LT_REWARD_15_20_25_30],[AVN_DA_BHXH_BHYT_BHTN],[AVN_DA_TT_BHYT],[AVN_DA_AUVP1],[AVN_DA_AUVP1_OT],[AVN_DA_AUVP2],[AVN_DA_AUVP2_OT],[AVN_DA_AUCT1],[AVN_DA_AUCT1_OT],[AVN_DA_AUCT2],[AVN_DA_AUCT2_OT],[AVN_DA_AUWFH],[AVN_DA_AUWFH_OT],[AVN_DA_SFSUPPORT],[AVN_DA_WEDA],[AVN_DA_BIRA],[AVN_DA_FURA],[AVN_DA_GXE],[AVN_DA_LTRU],[AVN_DA_TCCTP],[AVN_DA_DLCT],[AVN_DA_KSK],[AVN_DA_KSKDK],[AVN_DA_KSKDB],[AVN_DA_GIFT],[AVN_DA_THEDT],[AVN_DA_DPHUC],[AVN_DA_GIFT_CD],[AVN_DA_DLCV],[AVN_DA_DLGD],[AVN_DA_NMAT],[AVN_DA_TCTT],[AVN_DA_INTAX],[AVN_DA_AN],[AVN_DA_TNRR],[AVN_DA_Other],[AVN_TruyThu],[AVN_BHXH_C],[AVN_BHYT_C],[AVN_BHTN_C],[AVN_BHXH_E],[AVN_BHYT_E],[AVN_BHTN_E],[AVN_TT_BHYT_E],[AVN_SoNguoiPhuThuoc],[AVN_GiamTruPhuThuoc],[AVN_GiamTruBanThan],[AVN_TinhThue],[AVN_ThuePIT],[AVN_LuongTinh_TCTV],[AVN_SoNamHuongTCTV],[AVN_TCTV_NonTaxable],[AVN_TCTV_Taxable],[AVN_TCTV_Tax],[AVN_TongKhoanKhauTru],[AVN_GrossIncome],[AVN_AdvancePay],[AVN_NetIncome]
' 

SET @ElementPayslip = ' AND spti.Code IN( ''AVN_TONGLUONGNGAYCONG_DETAIL2'',''AVN_PCTheoLuong_SUM_DETAIL2'',''AVN_OT_SUM_DETAIL2'',''AVN_NS_SUM_DETAIL2'',''AVN_ThuNhapKhac_TrongThang_DETAIL2'',''AVN_TongThuong_TrongThang_DETAIL2'',''AVN_TruyLinh_DETAIL2'',''AVN_Deduction_SUM_DETAIL2'',''AVN_TruyThu_DETAIL2'',''AVN_Deduction_SUM_Payslip'') '

SET @ElementPayslipPivot = ' [AVN_TONGLUONGNGAYCONG_DETAIL2],[AVN_PCTheoLuong_SUM_DETAIL2],[AVN_OT_SUM_DETAIL2],[AVN_NS_SUM_DETAIL2],[AVN_ThuNhapKhac_TrongThang_DETAIL2],[AVN_TongThuong_TrongThang_DETAIL2],[AVN_TruyLinh_DETAIL2],[AVN_Deduction_SUM_DETAIL2],[AVN_TruyThu_DETAIL2],[AVN_Deduction_SUM_Payslip] '


set @getdata = '
	DECLARE @tblPermission TABLE (id uniqueidentifier primary key )
	INSERT INTO @tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'

	----Lay bang luong chinh
	select s.* into #PayrollTable from Sal_PayrollTable s join @tblPermission tb on s.ProfileID = tb.ID
	where isdelete is null '+@MonthYear+'

	----Ngay len chinh thuc
	select ProfileID,DateEffective,ROW_NUMBER ( ) OVER (PARTITION BY ProfileID order by ProfileID,DateEffective desc) as flag
	into #LenChinhThuc
	from Hre_WorkHistory
	where isdelete is null and TypeOfTransferID in (SELECT id FROM Cat_NameEntity WHERE isdelete IS NULL AND NameEntityType = ''E_Typeoftransfer'' and Code = ''CTOP'')

	--- Lay ngay bat dau va ket thuc ky luong
	DECLARE @DateStart DATETIME, @DateEnd DATETIME, @StartMonth  DATETIME
	SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYear+'

'
SET @query= N'
	----Bang luong
	;WITH Sal_PayrollTable_New AS
	(
	select 
	hp.ID AS ID,hp.ID AS ProfileID , hp.CodeEmp, hp.ProfileName
	,E_BRANCH AS DivisionName,E_UNIT AS CenterName,E_DIVISION AS DepartmentName,E_DEPARTMENT AS SectionName,E_TEAM AS UnitName
	,sc.SalaryClassName,cp.PositionName,cj.JobTitleName, cetl.VN AS EmploymentType,cetl2.VN AS LaborType,cne.NameEntityName AS EmployeeGroupName, cwp.WorkPlaceName
	,hp.DateHire,hp.DateEndProbation, ct.DateEffective as LenChinhThuc, hp.DateQuit, cetl3.VN AS EmpStatus,spt.MonthYear
	,ISNULL(cast(dbo.VnrDecrypt(spti.E_Value) as float),0) as SalaryAmount
	,CASE WHEN spt.IsCash = 1 THEN N''Tiền Mặt'' ELSE N''Chuyển khoản'' END AS PayPaidType
	, ROW_NUMBER() OVER(PARTITION BY hwh.ProfileID ORDER BY hwh.DateEffective DESC) AS rk,spt.ID AS PayrollTableID
	from Hre_Profile hp
	LEFT JOIN Hre_WorkHistory hwh ON hp.ID = hwh.ProfileID
	left join #PayrollTable spt on spt.profileid=hp.id 
	left join Att_CutOffDuration a on spt.CutOffDurationID=a.ID 
	left join Cat_SalaryClass sc on hwh.SalaryClassID = sc.id
	left join Cat_JobTitle cj on hwh.JobTitleID = cj.ID
	left join #LenChinhThuc ct on hwh.ProfileID = ct.ProfileID and ct.flag = ''1''
	left join Cat_OrgStructure cos on hwh.OrganizationStructureID = cos.ID
	left join Cat_OrgUnit cu on hwh.OrganizationStructureID = cu.OrgStructureID
	left join Cat_Position cp on hwh.PositionID = cp.ID
	left join Cat_EmployeeType et on hp.EmpTypeID = et.ID
	left join Cat_Bank cb on spt.BankID = cb.ID
	left join Sal_SalaryInformation sai on sai.ProfileID = hwh.ProfileID and sai.IsDelete is null
	left join Hre_StopWorking hs on hwh.ProfileID = hs.profileID and hs.isdelete is null and hs.Status=''E_APPROVED''
	LEFT JOIN Cat_WorkPlace cwp ON cwp.ID = hwh.WorkPlaceID
	LEFT JOIN Cat_NameEntity cne ON cne.ID = hwh.EmployeeGroupID
	LEFT JOIN	Sal_PayrollTableItem spti
		ON		Spti.PayrollTableID = spt.ID 
				AND spti.Code = ''AVN_NetIncome'' AND spti.Isdelete IS NULL
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
				WHERE	cetl.EnumKey = spt.EmpStatus 
						AND cetl.EnumKey in (''E_PROFILE_ACTIVE'',''E_PROFILE_QUIT'',''E_PROFILE_NEW'') AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl3
	WHERE		hwh.IsDelete is null
		AND		hwh.DateEffective <= @DateEnd
		AND		hwh.Status = ''E_APPROVED''
		AND		hp.IsDelete is null
		AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart)
		AND		hp.DateHire <= @DateEnd
				'+ISNULL(@condition,'')+'
	) 
	Select *
	into #Sal_Payrolltable_New
	from Sal_PayrollTable_New 
	where rk = 1
	'+ISNULL(@PayPaidType,'')+'
	'+ISNULL(@CheckData,'')+ ' 
	'+ISNULL(@AmountCondition,'')+'
	print(''#Sal_Payrolltable_New'');

'
SET @pivot= N'

	SELECT		* 
	INTO		#Sal_Payrolltable_Pivot
	FROM	
			(
			SELECT * 
			FROM (
					SELECT		sptn.*,ISNULL(spti.Code,''NotHaveSalary'') AS Code, CASE WHEN spti.Code IS NOT NULL THEN cast(dbo.VnrDecrypt(E_Value) as float) ELSE 1  END as AmountSPTI
					FROM		#Sal_Payrolltable_New sptn
					LEFT JOIN	Sal_PayrollTableItem spti
						ON		sptn.PayrollTableID = spti.PayrollTableID
								AND	spti.Isdelete  IS NULL
				) spti
				WHERE	1 = 1 '+@Element+'
			) T

	PIVOT		(
			sum(AmountSPTI) for code  in ( '+@ElementPivot+' )
			) p

	SELECT		* 
	INTO		#Sal_Payrolltable_Payslip_Pivot
	FROM	
			(
			SELECT * 
			FROM (
					--SELECT		sptn.ProfileID as ProfileID_Payslip ,spti.Code, CASE WHEN RIGHT(dbo.VnrDecrypt(spti.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(spti.E_Value),LEN(dbo.VnrDecrypt(spti.E_Value)) - 1) ELSE dbo.VnrDecrypt(spti.E_Value) END as AmountSPTI
					SELECT		sptn.ProfileID as ProfileID_Payslip ,spti.Code, dbo.VnrDecrypt(spti.E_Value)  as DetailSPTI
					FROM		#Sal_Payrolltable_New sptn
					LEFT JOIN	Sal_PayrollTableItem spti
						ON		sptn.PayrollTableID = spti.PayrollTableID
								AND	spti.Isdelete  IS NULL
				) spti
				WHERE	1 = 1 '+@ElementPayslip+'
			) T

	PIVOT		(
			Max(DetailSPTI) for code  in ( '+@ElementPayslipPivot+' )
			) p


'
SET @querybonus= N'

	SELECT		spp.*,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber
				,sppp.*
				--,CASE WHEN RIGHT(dbo.VnrDecrypt(pri1.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri1.E_Value),LEN(dbo.VnrDecrypt(pri1.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri1.E_Value) END as AVN_TONGLUONGNGAYCONG_DETAIL
				--,CASE WHEN RIGHT(dbo.VnrDecrypt(pri2.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri2.E_Value),LEN(dbo.VnrDecrypt(pri2.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri2.E_Value) END as AVN_PCTheoLuong_SUM_DETAIL
				--,CASE WHEN RIGHT(dbo.VnrDecrypt(pri3.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri3.E_Value),LEN(dbo.VnrDecrypt(pri3.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri3.E_Value) END as AVN_OT_SUM_DETAIL
				--,CASE WHEN RIGHT(dbo.VnrDecrypt(pri4.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri4.E_Value),LEN(dbo.VnrDecrypt(pri4.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri4.E_Value) END as AVN_NS_SUM_DETAIL
				--,CASE WHEN RIGHT(dbo.VnrDecrypt(pri5.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri5.E_Value),LEN(dbo.VnrDecrypt(pri5.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri5.E_Value) END as AVN_ThuNhapKhac_TrongThang_DETAIL
				--,CASE WHEN RIGHT(dbo.VnrDecrypt(pri6.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri6.E_Value),LEN(dbo.VnrDecrypt(pri6.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri6.E_Value) END as AVN_TongThuong_TrongThang_DETAIL
				--,CASE WHEN RIGHT(dbo.VnrDecrypt(pri7.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri7.E_Value),LEN(dbo.VnrDecrypt(pri7.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri7.E_Value) END as AVN_TruyLinh_DETAIL
				--,CASE WHEN RIGHT(dbo.VnrDecrypt(pri8.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri8.E_Value),LEN(dbo.VnrDecrypt(pri8.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri8.E_Value) END as AVN_Deduction_SUM_DETAIL
				--,CASE WHEN RIGHT(dbo.VnrDecrypt(pri9.E_Value),2) = ''; '' THEN  LEFT(dbo.VnrDecrypt(pri9.E_Value),LEN(dbo.VnrDecrypt(pri9.E_Value)) - 1) ELSE dbo.VnrDecrypt(pri9.E_Value) END as AVN_TruyThu_DETAIL
				,getdate() as ExportDate
				,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL as "hwh.PositionID",NULL as "hwh.JobTitleID",NULL as "hwh.SalaryClassID"
				,NULL as "hwh.WorkPlaceID",NULL as "spt.EmpStatus",NULL as "hwh.EmploymentType",NULL as "hp.DateHire",NULL as "hp.DateEndProbation",NULL as "hp.DateQuit"
				,NULL as "AmountCondition",NULL as "CheckData",NULL as "hwh.LaborType",NULL as "hwh.EmployeeGroupID"
	INTO		#Results
	FROM		#Sal_Payrolltable_Pivot spp
	--left join sal_payrolltableitem pri1 on spp.PayrollTableID=pri1.payrolltableid and pri1.code = ''AVN_TONGLUONGNGAYCONG_DETAIL''
	--left join sal_payrolltableitem pri2 on spp.PayrollTableID=pri2.payrolltableid and pri2.code = ''AVN_PCTheoLuong_SUM_DETAIL''
	--left join sal_payrolltableitem pri3 on spp.PayrollTableID=pri3.payrolltableid and pri3.code = ''AVN_OT_SUM_DETAIL''
	--left join sal_payrolltableitem pri4 on spp.PayrollTableID=pri4.payrolltableid and pri4.code = ''AVN_NS_SUM_DETAIL''
	--left join sal_payrolltableitem pri5 on spp.PayrollTableID=pri5.payrolltableid and pri5.code = ''AVN_ThuNhapKhac_TrongThang_DETAIL''
	--left join sal_payrolltableitem pri6 on spp.PayrollTableID=pri6.payrolltableid and pri6.code = ''AVN_TongThuong_TrongThang_DETAIL''
	--left join sal_payrolltableitem pri7 on spp.PayrollTableID=pri7.payrolltableid and pri7.code = ''AVN_TruyLinh_DETAIL''
	--left join sal_payrolltableitem pri8 on spp.PayrollTableID=pri8.payrolltableid and pri8.code = ''AVN_Deduction_SUM_DETAIL''
	--left join sal_payrolltableitem pri9 on spp.PayrollTableID=pri9.payrolltableid and pri9.code = ''AVN_TruyThu_DETAIL''
	left join	#Sal_Payrolltable_Payslip_Pivot sppp on spp.ProfileID = sppp.ProfileID_Payslip

'

set @queryPageSize = N'
	ALTER TABLE #Results ADD TotalRow int
	declare @totalRow int
	SELECT @totalRow = COUNT(*) FROM #Results
	update #Results set TotalRow = @totalRow

	SELECT		RowNumber AS STT,*
	FROM		#Results 
	WHERE		RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
	ORDER BY	RowNumber


drop table #PayrollTable
drop table #Results,#Sal_Payrolltable_Pivot , #Sal_Payrolltable_New, #LenChinhThuc

drop table #Sal_Payrolltable_Payslip_Pivot
'

--print (@getdata)
--print (@query)
--print (@query2)
--print (@pivot)
--print (@querybonus)
--print (@queryPageSize)

exec( @getdata +@query+ @query2 + @pivot+ @querybonus  + @queryPageSize )


END
--rpt_PayrollMonthlyV2