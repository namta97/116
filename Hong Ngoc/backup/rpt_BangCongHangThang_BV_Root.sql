USE [HONGNGOC]
GO
/****** Object:  StoredProcedure [dbo].[rpt_BangCongHangThang_BV]    Script Date: 5/12/2022 1:10:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	
ALTER proc [dbo].[rpt_BangCongHangThang_BV]
@condition varchar(max) = " 00916 ", 
@PageIndex int = 1,
@PageSize int = 100,
@Username varchar(100) = 'support'
AS
BEGIN

declare @Test NVARCHAR(MAX), @DateChot DATETIME, @_String1 NVARCHAR(MAX), @_String2 NVARCHAR(MAX), @_String21 NVARCHAR(MAX), @_String22 NVARCHAR(MAX), @_String23 NVARCHAR(MAX), @_String24 NVARCHAR(MAX), @_String25 NVARCHAR(MAX), @_String3 NVARCHAR(MAX)
set @DateChot ='2020-09-15'
DECLARE @tblPermission TABLE (id uniqueidentifier primary key )
DECLARE  @_ProfileID NVARCHAR(MAX), @_OrderNumber NVARCHAR(MAX), @_CutOffDurationID NVARCHAR(MAX), @_CutOffDurationID2 NVARCHAR(MAX)
SET @_ProfileID = ''
SET @_OrderNumber = ''
SET @_CutOffDurationID = ''

IF CHARINDEX('ProfileID', @condition,0) <> 0
BEGIN
    SET @_ProfileID ='AND ' +SUBSTRING(@condition, CHARINDEX('ProfileID', @condition, 0), CHARINDEX('))', @condition, CHARINDEX('ProfileID', @condition, 0)) - CHARINDEX('ProfileID', @condition, 0)+1)  
END

--SET @_ProfileID =  ' and (at.ProfileID=''C8553304-952E-4951-AA6D-4EF8ABE3A1BE'') ' 
SET @_ProfileID =  REPLACE(@_ProfileID, 'ProfileID', 'at.ProfileID')
PRINT @_ProfileID

IF CHARINDEX('OrderNumber', @condition,0) <> 0
BEGIN
    SET @_OrderNumber =' AND ' +SUBSTRING(@condition, CHARINDEX('OrderNumber', @condition, 0), CHARINDEX('))))', @condition, CHARINDEX('OrderNumber', @condition, 0)) - CHARINDEX('OrderNumber', @condition, 0) +3) 
END
SET @_OrderNumber = REPLACE(@_OrderNumber, 'OrderNumber', 'co.OrderNumber')
PRINT @_OrderNumber

IF CHARINDEX('CutOffDurationID', @condition,0) <> 0  
BEGIN
    SET @_CutOffDurationID = ' AND ' +SUBSTRING(@condition, CHARINDEX('CutOffDurationID', @condition, 0), CHARINDEX(')', @condition, CHARINDEX('CutOffDurationID', @condition, 0)) - CHARINDEX('CutOffDurationID', @condition, 0) ) 
	SET @_CutOffDurationID2 = REPLACE(@_CutOffDurationID, 'CutOffDurationID', 'att.CutOffDurationID')
	SET @_CutOffDurationID = REPLACE(@_CutOffDurationID, 'CutOffDurationID', 'at.CutOffDurationID')
END
ELSE
BEGIN
    SELECT 
	@_CutOffDurationID = ' AND at.CutOffDurationID like N''%'+CAST(ID AS NVARCHAR(max))+'%'''
	FROM Att_CutOffDuration
	WHERE IsDelete IS NULL AND GETDATE()>= DateStart AND GETDATE()<=DateEnd

	SELECT @_CutOffDurationID2 = ' AND att.CutOffDurationID like N''%'+CAST(ID AS NVARCHAR(max))+'%'''
	FROM Att_CutOffDuration
	WHERE IsDelete IS NULL AND GETDATE()>= DateStart AND GETDATE()<=DateEnd
END

SET @Test = REPLACE(@_CutOffDurationID, 'at.CutOffDurationID', 'ID')

PRINT @_CutOffDurationID


-- rpt_BangCongHangThang_BV

SET @_String2 = '
----2
 DECLARE @tblPermission TABLE (id uniqueidentifier primary key ) INSERT INTO @tblPermission EXEC Get_Data_Permission_New ''' + @Username+ ''', ' + '''Hre_Profile'''+ '
 
---TS
declare @DateFromTS DATETIME, @DateToTS DATETIME
SELECT @DateFromTS = DateStart, @DateToTS = DateEnd FROM Att_CutOffDuration WHERE IsDelete IS NULL ' + @Test + '

SELECT at.DateStart as NgayBatDau,at.profileid,hp.id,hp.CodeEmp,hp.ProfileName,hpm.OtherName,cp.PositionName,co.OrgStructureName, hp.CodeEmpClient , hp.datequit, hp.DateENDProbation, at.MonthYear, at.CutOffDurationID, co.OrderNumber
	,concat(''C'',DATEPART(day,ati.WorkDate)) as Ngay,at.StdWorkDayCount, (at.Overtime1Hours +at.Overtime2Hours+at.Overtime3Hours+at.Overtime4Hours+at.Overtime5Hours+at.Overtime6Hours)*2/8 as OT,
	(CASE WHEN cs1.Code=''KT_KyThuatTrucDem_7h_22h'' then ati.WorkPaidHours/15 +  isnull(OvertimeOFFHours1,0)/8
		WHEN ati.WorkHoursShift2 >0 then  ati.WorkHoursShift1/cs1.StdWorkHours*1.0 +ati.WorkHoursShift2/cs2.StdWorkHours*1.0 + isnull(OvertimeOFFHours1,0)/8
		WHEN ati.shiftid is null then isnull(OvertimeOFFHours1,0)/8
		ELSE  (isnull(OvertimeOFFHours1,0)+ati.WorkPaidHours)/NULLIF(cs1.StdWorkHours,0)*1.0
		END) as Cong
	,( CASE
		WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay1Days
		WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay2Days
		WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay3Days
		WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay4Days
		WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay5Days
		WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay6Days
		ELSE 0
		END
	)+( CASE WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H1'') then at.LeaveDay1Days
		WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H1'') then at.LeaveDay2Days
		WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H1'') then at.LeaveDay3Days
		WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H1'') then at.LeaveDay4Days
		WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H1'') then at.LeaveDay5Days
		WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H1'') then at.LeaveDay6Days
		ELSE 0
		END
	)  as DiHoc 
	,
	(CASE WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay2Days
	WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay1Days
	WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay3Days
	WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay4Days
	WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay5Days
	WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay6Days
	ELSE 0
	END) 
	--2
	'
SET @_String21 = '

--21
+( CASE
	WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''SL'') then at.LeaveDay2Days
	WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''SL'') then at.LeaveDay1Days
	WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''SL'') then at.LeaveDay3Days
	WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''SL'') then at.LeaveDay4Days
	WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''SL'') then at.LeaveDay5Days
	WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''SL'') then at.LeaveDay6Days
	ELSE 0
	END) + ( CASE WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay2Days
	WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay1Days
	WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay3Days
	WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay4Days
	WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay5Days
	WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay6Days
	ELSE 0
	END) 
	+ ( CASE WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CH'') then at.LeaveDay2Days
	WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CH'') then at.LeaveDay1Days
	WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CH'') then at.LeaveDay3Days
	WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CH'') then at.LeaveDay4Days
	WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CH'') then at.LeaveDay5Days
	WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CH'') then at.LeaveDay6Days
	ELSE 0
	END) 
	AS NgayCongKhacHuongLuong,
	(CASE WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay2Days
	WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay1Days
	WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay3Days
	WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay4Days
	WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay5Days
	WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay6Days
	ELSE 0
	END)+
	( CASE WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay1Days
		WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay2Days
		WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay3Days
		WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay4Days
		WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay5Days
		WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''H'') then at.LeaveDay6Days
		ELSE 0
		END)
	as NgayCongKhacHuongLuong_TinhPhep,

	(CASE WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay2Days
	WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay1Days
	WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay3Days
	WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay4Days
	WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay5Days
	WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay6Days
	ELSE 0
	END)+
	(CASE WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay2Days
	WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay1Days
	WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay3Days
	WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay4Days
	WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay5Days
	WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''DB'') then at.LeaveDay6Days
	ELSE 0
	END)
	as NghiHuongNgayThua,

	( CASE WHEN at.LeaveDay2Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay2Days
		WHEN at.LeaveDay1Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay1Days
		WHEN at.LeaveDay3Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay3Days
		WHEN at.LeaveDay4Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay4Days
		WHEN at.LeaveDay5Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay5Days
		WHEN at.LeaveDay6Type in (SELECT id FROM Cat_LeaveDayType WHERE Code=''CT'') then at.LeaveDay6Days
		ELSE 0
		END) AS P_DAY
	, at.LateEarlyCount as SL_MuonSom ,MissInOut.SL_ThieuInOut
	,(CASE WHEN hp.DateENDProbation>= DATEADD(HOUR,0,convert(DATETIME,convert(DATE,at.DateEnd))) then at.ActualHoursAllowance*0.7
	ELSE at.ActualHoursAllowance END) as TienTruc
	,at.DateStart,at.DateEND,al.DateStart as BatDauTS,al.DateEND as KetThucTS
	,ThieuInOut ,MuonSom
	, aa.InitAnlValue ,aa.InitMensesValue,aa.InitAdditionalValue,aa.InitSickValue,BuCong,TruCong,TrucNgayLe,TrucCN,TienTrucTheoCa
	,PhatKhac.AmountOfFine as TienPhatKhac,PhatKhac.Notes as LyDoPhat,BuCong1.Note as GhiChu_BuCong,BuCong2.Note as GhiChu_TruCong,concat(VPTS.Notes,xl1.Note) as LyDo_VPTS
	,VPTS.AmountOfFine as ViPhamThaiSan,VPTS.NameEntityName,xl.Code as MaXepLoai,xl.Note as GhiChuXepLoai,tt.GhiChuTienTruc,tt.ActualHours
	,GhiChuNhap,convert(float,ale.Note)  as CongKhac, cg.code as MaCheDo,cn.NameEntityName as ChucVuThue
	,at.PaidWorkDayCount + at.PaidLeaveDays as TongCongHuongLuong,at.PaidWorkDayCount +(at.OvertimeOFF1Hours+at.OvertimeOFF2Hours)/8  as CongThucTe
	,hrt.FROMDate as TGBatDauHoc, hrt.ToDate as TGKetThucHoc, hp.DateHire,TruyThu.ActualHours as TruyThu,TruyThu.Note as TruyThuNote, ChiVan.ActualHours as ChiVan,ChiVan.Note as GhiChu_ChiVan
	,SoLanCaDem.SoLanCaDem
	,al2.DateStart as NAL_DAY, al3.DateStart as BH_DAY, al4.DateStart as CH_DAY
	,concat(cl1.LeaveDayTypeName,cl2.LeaveDayTypeName,cl3.LeaveDayTypeName,cl4.LeaveDayTypeName,cl5.LeaveDayTypeName,cl6.LeaveDayTypeName) as LyDoNghi
,BuCong1.Note as GhiChuBuCong,TS.ActualHours as CongTS,at.Note as ThamNienThangNay,isnull(al1.AnlValue,0)+thamnien.LuyKe_ThamNien as ThamNien,hp.CompanyID,Tien_Muon
,TruSoNgayLe, SL1, SL2, DienGiai1, DienGiai2, Cong_HL.ActualHours as CongHL ,cw.Code
INTO #KQ_Tmp
FROM dbo.Att_AttendanceTable at

	 INNER JOIN @tblPermission tps on tps.ID = at.ProfileID
	 LEFT JOIN Cat_GradeAttENDance cg on cg.id=at.GradeAttENDanceID
	 LEFT JOIN Att_AttENDanceTableItem ati on at.ID=ati.AttENDanceTableID AND ati.IsDelete is NULL
	 LEFT JOIN Hre_Profile hp on hp.ID=at.ProfileID AND hp.isdelete is null
	 left join Cat_WorkPlace cw on cw.id=hp.WorkPlaceID
	 left join Hre_ProfileMoreInfo hpm on hp.ProfileMoreInfoID=hpm.id and hpm.isdelete is null
	 LEFT JOIN Cat_NameEntity cn on cn.id= hp.DistributionChannelID AND cn.isdelete is null AND NameEntityType=''E_CHANNELDISTRIBUTION'' AND EnumType=''E_CHANNELDISTRIBUTION''
	   --Ly do nghi
	left join Cat_LeaveDayType cl1 on cl1.id=at.LeaveDay1Type and cl1.PaidRate=1
	left join Cat_LeaveDayType cl2 on cl2.id=at.LeaveDay2Type and cl2.PaidRate=1
	left join Cat_LeaveDayType cl3 on cl3.id=at.LeaveDay3Type and cl3.PaidRate=1
	left join Cat_LeaveDayType cl4 on cl4.id=at.LeaveDay4Type and cl4.PaidRate=1
	left join Cat_LeaveDayType cl5 on cl5.id=at.LeaveDay5Type and cl5.PaidRate=1
	left join Cat_LeaveDayType cl6 on cl6.id=at.LeaveDay6Type and cl6.PaidRate=1
--TruNgayLe
   left join (select at.ProfileID,at.ID, count(cd.id)  TruSoNgayLe from Att_AttendanceTable at
left join Hre_Profile hp on hp.id=at.ProfileID
left join Cat_DayOff cd on cd.DateOff>=at.DateStart and cd.DateOff<=at.DateEnd

where at.IsDelete is null
and hp.DateHire >at.DateStart and hp.DateHire <at.DateEnd
group by at.ProfileID,at.ID) TruNgayLe on TruNgayLe.ProfileID=at.ProfileID and TruNgayLe.ID=at.ID
	 
	 --21
  	'
SET @_String22 = '

--22
	  --Thoi gian hoc
	 LEFT JOIN Hre_ResearcchTopic hrt on hrt.profileid=at.profileid AND hrt.isdelete is null AND (( at.DateStart>=hrt.FROMDate AND hrt.ToDate>=at.DateStart) or ( at.DateStart<=hrt.FROMDate AND hrt.FROMDate <= at.DateEND AND hrt.ToDate>=at.DateStart))

	  ----XepLoai
	 LEFT JOIN (SELECT ProfileID,cj.Code,ap.Note,ap.WorkDate FROM Att_ProfileTimeSheet ap
	 LEFT JOIN Cat_JobType cj on cj.id=ap.JobTypeID
	 WHERE JobTypeID in (SELECT id FROM Cat_JobType WHERE Code in (''Loai1'',''Loai2'',''Loai3'',''Loai B'',''KXL'',''Loai B thieu cong'',''B_ViPhamTS'',''B_thieucong'',''Nghi_KL'',''Nghi_De'')) AND ap.IsDelete is null) xl on xl.profileid=at.profileid AND xl.WorkDate>=at.DateStart AND xl.WorkDate<=at.DateEND
	 
	 LEFT JOIN (SELECT ProfileID,cj.Code,ap.Note,ap.WorkDate FROM Att_ProfileTimeSheet ap
	 LEFT JOIN Cat_JobType cj on cj.id=ap.JobTypeID
	 WHERE JobTypeID in (SELECT id FROM Cat_JobType WHERE Code in (''B_ViPhamTS'')) AND ap.IsDelete is null) xl1 on xl1.profileid=at.profileid AND xl1.WorkDate>=at.DateStart AND xl1.WorkDate<=at.DateEND

	---TienTrucNhap
	 LEFT JOIN (SELECT ProfileID,cj.Code,ap.Note as GhiChuTienTruc,ap.WorkDate,ap.ActualHours FROM Att_ProfileTimeSheet ap
	 LEFT JOIN Cat_JobType cj on cj.id=ap.JobTypeID
	 WHERE JobTypeID in (SELECT id FROM Cat_JobType WHERE Code =''TienTruc'') AND ap.IsDelete is null
	 ) tt ON tt.profileid = at.profileid AND tt.WorkDate>=at.DateStart AND tt.WorkDate<=at.DateEND
	--GhiChuNhap
	  LEFT JOIN (SELECT ProfileID,cj.Code,ap.Note as GhiChuNhap,ap.WorkDate,ap.ActualHours FROM Att_ProfileTimeSheet ap
	LEFT JOIN Cat_JobType cj on cj.id = ap.JobTypeID
	WHERE JobTypeID in (SELECT id FROM Cat_JobType WHERE Code =''GhiChu'') AND ap.IsDelete is null) GhiChu on GhiChu.profileid=at.profileid AND GhiChu.WorkDate>=at.DateStart AND GhiChu.WorkDate<=at.DateEND

	--ChiVan
	  LEFT JOIN (SELECT ProfileID,cj.Code,ap.Note ,ap.WorkDate,ap.ActualHours FROM Att_ProfileTimeSheet ap
	LEFT JOIN Cat_JobType cj on cj.id=ap.JobTypeID
	WHERE JobTypeID in (SELECT id FROM Cat_JobType WHERE Code =''CA'') AND ap.IsDelete is null) ChiVan on ChiVan.profileid=at.profileid AND ChiVan.WorkDate>=at.DateStart AND ChiVan.WorkDate<=at.DateEND

	--TS
	left join (select ProfileID,cj.Code,ap.Note ,ap.WorkDate,ap.ActualHours from Att_ProfileTimeSheet ap
	left join Cat_JobType cj on cj.id=ap.JobTypeID
	where JobTypeID in (select id from Cat_JobType where Code =''TS'') and ap.IsDelete is null) TS on TS.profileid=at.profileid and TS.WorkDate>=at.DateStart and TS.WorkDate<=at.DateEnd

	--TruyThu
	  LEFT JOIN (SELECT ProfileID,cj.Code,ap.Note ,ap.WorkDate,ap.ActualHours FROM Att_ProfileTimeSheet ap
					LEFT JOIN Cat_JobType cj on cj.id=ap.JobTypeID
					WHERE JobTypeID in (SELECT id FROM Cat_JobType WHERE Code =''TruyThu'') AND ap.IsDelete is NULL
				) TruyThu on TruyThu.profileid = at.profileid AND TruyThu.WorkDate>=at.DateStart AND TruyThu.WorkDate <= at.DateEND

	---Cong HL 
	LEFT JOIN (SELECT ProfileID,cj.Code,ap.Note ,ap.WorkDate,ap.ActualHours FROM Att_ProfileTimeSheet ap
					LEFT JOIN Cat_JobType cj on cj.id=ap.JobTypeID
					WHERE JobTypeID in (SELECT id FROM Cat_JobType WHERE Code =''Cong_HL'') AND ap.IsDelete is NULL
				) Cong_HL  on Cong_HL.profileid = at.profileid AND Cong_HL.WorkDate>=at.DateStart AND Cong_HL.WorkDate <= at.DateEND

				--22
	'
SET @_String23 = '
--23
	  --Vi pham thai san và tien phat khac
		LEFT JOIN (SELECT ProfileID,hd.DateOfEffective,cn.NameEntityName,SUM(hd.AmountOfFine) as AmountOfFine,hd.Notes,DisciplineResonID,DateENDOfViolation FROM Hre_Discipline hd
				LEFT JOIN Cat_NameEntity cn on cn.ID=hd.DisciplineResonID AND NameEntityType=''E_DISCIPLINE_REASON''
				WHERE hd.IsDelete is null AND cn.Code=2
				GROUP BY ProfileID,hd.DateOfEffective,cn.NameEntityName,hd.Notes,DisciplineResonID,DateENDOfViolation
			) PhatKhac ON at.profileid = PhatKhac.profileid AND ((at.DateStart>=PhatKhac.DateOfEffective AND at.DateStart<=PhatKhac.DateENDOfViolation) 
			------OR (PhatKhac.DateOfEffective>=at.DateStart AND at.DateStart<=PhatKhac.DateENDOfViolation)
			)

		LEFT JOIN (SELECT ProfileID,hd.DateOfEffective,cn.NameEntityName,hd.AmountOfFine,hd.Notes,DisciplineResonID,DateENDOfViolation FROM Hre_Discipline hd
					LEFT JOIN Cat_NameEntity cn on cn.ID=hd.DisciplineResonID AND NameEntityType=''E_DISCIPLINE_REASON''
					WHERE hd.IsDelete is null AND cn.Code=1) VPTS on at.profileid = VPTS.profileid AND at.DateStart>=VPTS.DateOfEffective 
					AND at.DateStart<=VPTS.DateENDOfViolation
	--CongUng
		LEFT JOIN  Att_AnnualLeaveExtEND ale on ale.profileid=at.profileid AND ale.monthstart>=at.DateStart AND ale.monthEND<=at.dateEND AND ale.isdelete is null
	--Phep thang nay- Phep ton
		LEFT JOIN Att_AnnualLeave aa on aa.profileid=at.profileid AND aa.year=year(at.monthyear) AND aa.MonthStart=month(at.monthyear) AND aa.isdelete is null AND ((at.DateEND=''2020-08-31 23:59:59.000'' AND aa.IPCreate=1) or (at.DateEND<>''2020-08-31 23:59:59.000'' AND (aa.IPCreate=0 or aa.IPCreate is null  )))
		LEFT JOIN Cat_OrgStructure co on co.id=at.OrgStructureID
		LEFT JOIN Cat_Position cp on cp.id =at.PositionID
		LEFT OUTER JOIN cat_shift cs1 on cs1.id = ati.ShiftID
		LEFT OUTER JOIN cat_shift cs2 on cs2.id = ati.Shift2ID
		LEFT JOIN (select * from Att_LeaveDay where  (DateStart between @DateFromTS and @DateToTS) or (DateEnd between @DateFromTS and @DateToTS) ) al on al.profileid=at.profileid AND al.LeaveDayTypeID =(SELECT id FROM Cat_LeaveDayType WHERE Code=''TS'')  AND al.isdelete is null
									AND al.DateEND = (SELECT max(dateEND) FROM Att_LeaveDay bl WHERE al.ProfileID=bl.ProfileID)
		LEFT JOIN Att_LeaveDay al2 on al2.profileid=at.profileid AND al2.LeaveDayTypeID =(SELECT id FROM Cat_LeaveDayType WHERE Code=''NAL'')  AND al2.isdelete is null
											AND al2.DateEND = (SELECT max(dateEND) FROM Att_LeaveDay bl WHERE al2.ProfileID=bl.ProfileID) AND al2.LeaveDays>=22 AND at.PaidWorkDayCount<4
		LEFT JOIN Att_LeaveDay al3 on al3.profileid=at.profileid AND al3.LeaveDayTypeID =(SELECT id FROM Cat_LeaveDayType WHERE Code=''BH'')  AND al3.isdelete is null
											AND al3.DateEND = (SELECT max(dateEND) FROM Att_LeaveDay bl WHERE al3.ProfileID=bl.ProfileID) AND al3.LeaveDays>=22 AND at.PaidWorkDayCount<4
		LEFT JOIN Att_LeaveDay al4 on al4.profileid=at.profileid AND al4.LeaveDayTypeID =(SELECT id FROM Cat_LeaveDayType WHERE Code=''CH'')  AND al4.isdelete is null
											AND al4.DateEND = (SELECT max(dateEND) FROM Att_LeaveDay bl WHERE al4.ProfileID=bl.ProfileID) AND al4.LeaveDays>=22 AND at.PaidWorkDayCount<4
		LEFT JOIN (select ID, sum(SL_ThieuInOut) SL_ThieuInOut,STRING_AGG(concat(DATEPART(DAY,WorkDate),''/'',DATEPART(MONTH,WorkDate)),'','') ThieuInOut   from (
										select at.id, 
										(case when aw.MissInOutReasonID1 not in (select id from Cat_TAMScanReasonMiss where Code in(''QCC01'',''QCC04'',''QCC05'',''QCC02'',''QCC06'',''QCC07'')) then 1 else 0 end)+
										(case when aw.MissInOutReasonID2 not in (select id from Cat_TAMScanReasonMiss where Code in(''QCC01'',''QCC04'',''QCC05'',''QCC02'',''QCC06'',''QCC07'')) then 1 else 0 end) 
										as SL_ThieuInOut,aw.WorkDate
 										from Att_AttendanceTable at
										left join Att_Workday aw on aw.ProfileID =at.ProfileID and aw.WorkDate>=at.DateStart and aw.WorkDate<=at.DateEnd and aw.MissInOutReason is not null and aw.IsDelete is null
										where at.IsDelete is null) a
										Group by ID) MissInOut on at.id=MissInOut.ID

		 left join (select ProfileID,AttendanceTableID,sum(TienPhatMuon) as Tien_Muon, sum(SoLanMuon) as SoLanMuon,STRING_AGG(concat(DATEPART(DAY,WorkDate),''/'',DATEPART(MONTH,WorkDate)),'','') as MuonSom  from 
(select   ( case
   when aati.LateEarlyMinutes <=3 then 0
   when aati.LateEarlyMinutes >3 and aati.LateEarlyMinutes <10  then 30000
   when aati.LateEarlyMinutes >=10 and aati.LateEarlyMinutes <30 then 50000
   when aati.LateEarlyMinutes >=30  then 100000
   else 0
   end
  ) as TienPhatMuon
  ,( case when aati.LateEarlyMinutes >3 then 1 else 0 end
  ) as SoLanMuon
 ,aati.workdate 
  
 ,aat.ProfileID,aati.AttendanceTableID
  from Att_AttendanceTableItem aati
left join Att_AttendanceTable aat on aati.AttendanceTableID=aat.ID and aat.IsDelete is null
where aat.ProfileID is not null and aati.LateEarlyMinutes>0) aaa
group by ProfileID,AttendanceTableID) TienMuon on TienMuon.AttendanceTableID=at.id and TienMuon.ProfileID=at.ProfileID

	--23
'
SET @_String24 = '
--24
		LEFT JOIN (SELECT AttENDanceTableID, SUM((CASE WHEN NightShiftHours>0 THEN 1 ELSE 0 END) )AS SoLanCaDem
						FROM Att_AttENDanceTableItem WHERE AttENDanceTableID IN (SELECT id FROM Att_AttENDanceTable WHERE IsDelete is null )
					AND NightShiftHours >0
					GROUP BY AttENDanceTableID) SoLanCaDem on at.id=SoLanCaDem.AttENDanceTableID


left join (
select ProfileID,WorkDate as MontYear,note, sum(ActualHours) as BuCong from Att_ProfileTimeSheet
where JobTypeID in (select id from Cat_JobType where Code in(''CongThua''))
and IsDelete is null and day(WorkDate)=1
group by ProfileID,WorkDate,note) BuCong1 on BuCong1.ProfileID=at.ProfileID and BuCong1.MontYear>=at.DateStart and BuCong1.MontYear<=at.DateEnd

left join (
select ProfileID,WorkDate as MontYear,note, sum(ActualHours) as TruCong from Att_ProfileTimeSheet
where JobTypeID in (select id from Cat_JobType where Code in(''CongThieu''))
and IsDelete is null and day(WorkDate)=1
group by ProfileID,WorkDate,note) BuCong2 on BuCong2.ProfileID=at.ProfileID and BuCong2.MontYear>=at.DateStart and BuCong2.MontYear<=at.DateEnd

	----TienTruc
		LEFT JOIN (SELECT AttENDanceTableID, 
	SUM(
		( CASE  WHEN DateOff is  null and   DATEPART(WEEKDAY,WorkDate) =1 AND AvailableHours>0 AND WorkDate<=DateENDProbation AND DateENDProbation is not null  then 70000*WorkPaidHours/AvailableHours
		WHEN DateOff is  null and  DATEPART(WEEKDAY,WorkDate) =1 AND AvailableHours>0   then 100000*WorkPaidHours/AvailableHours
		ELSE 0 END)) as TrucCN
	,SUM(
		(CASE WHEN DateOff is not null AND AvailableHours>0 AND WorkDate<=DateENDProbation AND DateENDProbation is not null then 70000*WorkPaidHours/AvailableHours
		WHEN DateOff is not null AND AvailableHours>0 then 100000*WorkPaidHours/AvailableHours
		ELSE 0 END)) as TrucNgayLe
	
	FROM dbo.Att_AttendanceTableItem a
	LEFT JOIN Cat_DayOff b on a.WorkDate=b.DateOff AND b.IsDelete is null
	LEFT JOIN dbo.Att_AttendanceTable c on a.AttENDanceTableID =c.ID
	LEFT JOIN Hre_Profile d on d.id=c.ProfileID
	WHERE  ShiftID  in (SELECT id FROM Cat_Shift WHERE IsDelete is null AND (StANDardHoursAllowanceFomula is null or StANDardHoursAllowanceFomula=''0''))
	AND AttENDanceTableID in (SELECT id FROM Att_AttENDanceTable WHERE IsDelete is null AND GradeAttENDanceID not in (SELECT id FROM Cat_GradeAttENDance WHERE Code in (''KCC_BV'',''BV_TV'',''BV03'',''BV04'',''BV06'',''BV12'',''BV09'',''BV10'',''PTM01'',''BV14'',''BV17'',''BV18'',''BV21'',''BV22'',''BV23'',''BV26'',''BV28'',''BV30'',''BV32'')) )
	and (c.monthyear <=''2021-07-01'' or c.monthyear >=''2021-11-01'')
	GROUP BY AttENDanceTableID) TienTruc on TienTruc.AttENDanceTableID=at.id
	'
	
SET @_String25 = '
	----TienTrucTheoCa
	
Left join (SELECT AttENDanceTableID,sum ((CASE WHEN WorkDate<DateENDProbation then a.ActualHoursAllowance*0.7
								ELSE a.ActualHoursAllowance END)) as TienTrucTheoCa
	FROM dbo.Att_AttendanceTableItem a
	LEFT JOIN Cat_DayOff b on a.WorkDate=b.DateOff AND b.IsDelete is null
	LEFT JOIN dbo.Att_AttendanceTable c on a.AttENDanceTableID =c.ID
	LEFT JOIN Hre_Profile d on d.id=c.ProfileID
	WHERE  a.isdelete is null
	GROUP BY AttENDanceTableID
	) aaaa  on aaaa.AttENDanceTableID=at.id
	--ThamNien
left join (select aa1.ProfileID, aa1.monthyear, aa1.AnlValue from Att_AnnualLeaveMonthByType aa1
join (select ProfileID, max(monthyear) monthyear from Att_AnnualLeaveMonthByType group by ProfileID) 
			aa2 on aa1.ProfileID = aa2.ProfileID and aa1.monthyear = aa2.monthyear ) al1 on al1.ProfileID=at.ProfileID --and year(al1.monthyear) = Year(at.monthyear)-1 and month(al1.monthyear)=12
left join (SELECT Att_AttendanceTable.ProfileID, MonthYear
,Att_AttendanceTable.Note+isnull(ChiVan.ActualHours,0)/convert(float,nullif(Att_AttendanceTable.StdWorkDayCount,0)) as ThamNien
,SUM (convert(float,Att_AttendanceTable.Note)+isnull(ChiVan.ActualHours,0)/convert(float,nullif(Att_AttendanceTable.StdWorkDayCount,0))) OVER (PARTITION BY Att_AttendanceTable.ProfileID ORDER BY Att_AttendanceTable.MonthYear) AS LuyKe_ThamNien
FROM Att_AttendanceTable 
left join Att_ProfileTimeSheet ChiVan on  ChiVan.profileid = Att_AttendanceTable.profileid and ChiVan.WorkDate>=Att_AttendanceTable.DateStart and ChiVan.WorkDate<=Att_AttendanceTable.DateEnd and ChiVan.isdelete is null and ChiVan.JobTypeID = (select id from Cat_JobType where Code=''CA'')
left join Att_ProfileTimeSheet CongThua on  CongThua.profileid = Att_AttendanceTable.profileid and CongThua.WorkDate>=Att_AttendanceTable.DateStart and CongThua.WorkDate<=Att_AttendanceTable.DateEnd and CongThua.isdelete is null and CongThua.JobTypeID = (select id from Cat_JobType where Code=''CongThua'')
where Att_AttendanceTable.IsDelete is null
and Att_AttendanceTable.MonthYear>=''2021-01-01'') thamnien on thamnien.ProfileID=at.ProfileID and thamnien.MonthYear=at.MonthYear

----Text thieuinout va muon som	

--Canteen
left join (select cms.ProfileID,DATEADD(month, DATEDIFF(month, 0, TimeLog), 0) as Thang,count (cms.id) SL1
,STRING_AGG(concat(''`'',DATEPART(DAY,TimeLog),''/'',DATEPART(MONTH,TimeLog)),'','') DienGiai1
from Can_MealRecord cms
left join Can_MealBillEmployee cm on cm.ProfileID=cms.ProfileID and cm.DateMeal=DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) and cm.MealUnitID is null and cm.isdelete is null and (cm.Status is null or cm.Status<>''E_CANCEL'')
where cms.IsDelete is null
and cm.id is null
and cms.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB''))
group by cms.ProfileID,DATEADD(month, DATEDIFF(month, 0, TimeLog), 0)
) KoDK_CoAn on at.MonthYear=KoDK_CoAn.Thang and at.ProfileID=KoDK_CoAn.ProfileID

left join (select cm.ProfileID,DATEADD(month, DATEDIFF(month, 0, cm.DateMeal), 0) Thang,count(cm.id) SL2 
,STRING_AGG(concat(''`'',DATEPART(DAY,DateMeal),''/'',DATEPART(MONTH,DateMeal)),'','') DienGiai2
from Can_MealBillEmployee cm
left join (select ProfileID,DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) as Ngay ,TimeLog,MachineCode
			from Can_MealRecord 
			where IsDelete is null) QuetThe on QuetThe.ProfileID=cm.ProfileID and QuetThe.Ngay=cm.DateMeal
where cm.IsDelete is null and QuetThe.TimeLog is null  and cm.MealUnitID is null
and (cm.Status is null or cm.Status<>''E_CANCEL'')
and cm.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB''))
group by cm.ProfileID, DATEADD(month, DATEDIFF(month, 0, cm.DateMeal), 0)
) CoDK_KhongAn on at.MonthYear=CoDK_KhongAn.Thang and at.ProfileID=CoDK_KhongAn.ProfileID



WHERE at.IsDelete is NULL AND hp.CodeEmp IS NOT NULL 
--24,25
'+@_CutOffDurationID+ @_ProfileID+@_OrderNumber



SET @_String3 = '

----3
SELECT DISTINCT CodeEmp,OtherName,ProfileName,ChucVuThue as ''PositionName'',OrgStructureName,MonthYear 
	,[C1],[C2],[C3],[C4],[C5],[C6],[C7],[C8],[C9],[C10],[C11],[C12],[C13],[C14],[C15]
	,[C16],[C17],[C18],[C19],[C20],[C21],[C22],[C23],[C24],[C25],[C26],[C27],[C28],[C29],[C30],[C31]
	,([C16]+[C17]+[C18]+[C19]+[C20]+[C21]+[C22]+[C23]+[C24]+[C25]+[C26]+[C27]+[C28]+[C29]+[C30]+isnull([C31],0)
	+[C1]+[C2]+[C3]+[C4]+[C5]+[C6]+[C7]+[C8]+[C9]+[C10]+[C11]+[C12]+[C13]+[C14]+[C15]) as CongThucTe
	,CongKhac
	,([C16]+[C17]+[C18]+[C19]+[C20]+[C21]+[C22]+[C23]+[C24]+[C25]+[C26]+[C27]+[C28]+[C29]+[C30]+isnull([C31],0)
	+[C1]+[C2]+[C3]+[C4]+[C5]+[C6]+[C7]+[C8]+[C9]+[C10]+[C11]+[C12]+[C13]+[C14]+[C15]+isnull(CongKhac,0)) as ThangNay
	,  ISNULL(BuCong,0)- isnull(TruCong,0)+NgayCongKhacHuongLuong as ''NgayCongKhacHuongLuong'' , ISNULL(BuCong,0)- isnull(TruCong,0)+NgayCongKhacHuongLuong_TinhPhep as ''NgayCongKhacHuongLuong_TinhPhep'', NghiHuongNgayThua
	,0 as NgayCongDiHoc
	,CutOffDurationID,OrderNumber
	,(CASE   
	WHEN DateHire> DateStart AND DateHire<DateEND AND (left(CodeEmpClient,2)<>''ZA'' or CodeEmpClient is null) and CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)>= (DATEDIFF(DAY,DateStart,DateEND)+1)/2 and TruSoNgayLe>0 and MaCheDo<>''BV07''   then 26
	WHEN DateHire> DateStart AND DateHire<DateEND AND (left(CodeEmpClient,2)<>''ZA'' or CodeEmpClient is null) and CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)>= (DATEDIFF(DAY,DateStart,DateEND)+1)/2 and TruSoNgayLe>0 and MaCheDo=''BV07''  then 22
    WHEN DateHire> DateStart AND DateHire<DateEND AND (left(CodeEmpClient,2)<>''ZA'' or CodeEmpClient is null) and CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)>= (DATEDIFF(DAY,DateStart,DateEND)+1)/2  then StdWorkDayCount
	WHEN DateHire> DateStart AND DateHire<DateEND AND (left(CodeEmpClient,2)<>''ZA'' or CodeEmpClient is null) and CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)< (DATEDIFF(DAY,DateStart,DateEND)+1)/2  then 26
	WHEN DateHire> DateStart AND DateHire<DateEND AND left(CodeEmpClient,2)=''ZA'' and CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)>= (DATEDIFF(DAY,DateStart,DateEND)+1)/2  then StdWorkDayCount
	WHEN DateHire> DateStart AND DateHire<DateEND AND left(CodeEmpClient,2)=''ZA'' and MaCheDo=''BV17'' and CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)< (DATEDIFF(DAY,DateStart,DateEND)+1)/2  then 26
	WHEN DateHire> DateStart AND DateHire<DateEND AND left(CodeEmpClient,2)=''ZA'' and MaCheDo<>''BV17'' and CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)< (DATEDIFF(DAY,DateStart,DateEND)+1)/2  then 27
	
	ELSE StdWorkDayCount END
	) as StdWorkDayCount

	,OT,P_DAY,SL_MuonSom,SL_ThieuInOut
	, (case when left(MaCheDo,2)<>''KS''  then isnull(TienTrucTheoCa,0)+isnull(TrucNgayLe,0)+isnull(TrucCN,0) else isnull(TienTrucTheoCa,0) end)   as TienTruc, ActualHours as TienTrucNhap
	,datequit,DateStart,DateEND,ID,BatDauTS,KetThucTS
	,ThieuInOut,MuonSom
	,CodeEmpClient,InitMensesValue,InitAdditionalValue,InitAnlValue,InitSickValue,BuCong,TruCong,profileid  

  , (case when MaXepLoai is not null then MaXepLoai 
  WHen DateEndProbation>= NgayBatDau then ''KXL''
   when NgayBatDau< ''2020-09-15'' then( case
    when CongThucTe+DiHoc<StdWorkDayCount-4 and CongThucTe+DiHoc>0 then N''Loai B thieu cong''
	when CongThucTe+DiHoc=StdWorkDayCount-4 and CongThucTe+DiHoc>0 then N''Loai3''

    when SL_ThieuInOut>=2 and SL_MuonSom>=4 then N''Loai B muon som''
  when  SL_MuonSom>=4 then N''Loai B muon som''
  when SL_ThieuInOut>=2  then N''Loai B QT1C''
  when SL_MuonSom=2 then N''Loai2''
  when SL_MuonSom=3 then N''Loai3''
  when MaCheDo=''BV07'' and InitAnlValue>0 then ''Loai1''
    when TongCongHuongLuong<=0 then ''''
   else N''Loai1''
  end) 
  when isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)>6 then ''Loai B''
  when CongThucTe+DiHoc<=StdWorkDayCount-4 and CongThucTe+DiHoc>0 then N''Loai B thieu cong''
  when isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)>6 then ''Loai B''

  when CongThucTe+DiHoc<=StdWorkDayCount-4 and CongThucTe+DiHoc>0 then N''Loai B thieu cong''

  when isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)>=4 and isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)<5 then ''Loai2''
  when isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)>=5 and isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)<=6 then ''Loai3''
  when MaCheDo=''BV07'' and InitAnlValue>0 then ''Loai1''
  when TongCongHuongLuong<=0 then ''''
  else ''Loai1'' end

  ) as XepLoai
	
	, ViPhamThaiSan,TienPhatKhac,LyDoPhat,LyDo_VPTS,Concat(LyDoNghi,GhiChuXepLoai,GhiChu_ChiVan,GhiChuTienTruc,TruyThuNote,GhiChuNhap,GhiChu_BuCong,GhiChu_TruCong) as Notes,MaCheDo
	,(CASE WHEN  DateENDProbation<=NgayBatDau then null
	ELSE DateENDProbation END) AS DateENDProbation,TruyThu,ChiVan,DateHire,SoLanCaDem
	,DiHoc,TGBatDauHoc,TGKetThucHoc 
	,CH_DAY,NAL_DAY,BH_DAY,CongTS
  ,isnull(ThamNien,0) as ThamNien, ThamNienThangNay
  , CongThucTe as CongThucTe1,CompanyID,Tien_Muon, SL1,SL2, DienGiai1, DienGiai2, CongHL,code
	, ROW_NUMBER() OVER ( ORDER BY CodeEmp asc) as RowNumber 
INTO #Results 
FROM #KQ_Tmp 
PIVOT 
  (
	SUM(Cong ) for Ngay IN ([C16],[C17],[C18],[C19],[C20],[C21],[C22],[C23],[C24],[C25],[C26],[C27],[C28],[C29],[C30],[C31],[C1],[C2],[C3],[C4],[C5],[C6],[C7],[C8],[C9],[C10],[C11],[C12],[C13],[C14],[C15])
  ) as pvtbl
  
 SELECT *, 0 AS ProfileID, 0 AS OrderNumber, 0 AS CutOffDurationID FROM #Results
 --3
'
PRINT @_String2
PRINT @_String21
PRINT @_String22
PRINT @_String23
PRINT @_String24
PRINT @_String25
PRINT @_String3
EXECUTE( @_String2+@_String21+@_String22+@_String23+@_String24+@_String25+@_String3)
END