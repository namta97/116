
alter proc rpt_BangCongHangThang_BV_12052022
@condition VARCHAR(MAX) = " and (at.CutOffDurationID like N'%8520A005-25B2-4583-84C9-F87E81D9FD71%') ", 
@PageIndex INT = 1,
@PageSize INT = 100,
@Username VARCHAR(100) = 'support'
AS
BEGIN


DECLARE @str NVARCHAR(MAX)
DECLARE @countrow INT
DECLARE @row int
DECLARE @index int
DECLARE @ID nvarchar(500)
DECLARE @TempID nvarchar(max)
DECLARE @TempCondition nvarchar(max)
DECLARE @Top varchar(20) = ' '
DECLARE @CurrentEnd bigint
DECLARE @Offset TINYINT


IF @condition = ' '
BEGIN
SET @top = ' Top 0 '
SET @condition = ' and (at.CutOffDurationID like N''%62BAFF6E-1045-4D11-B89F-84B2527F04E2%'') and (at.ProfileID in (''6F6E121B-299E-4BD6-95FC-6E8FBC2C8FC3''))'
END 
SET @condition = ' and (at.CutOffDurationID like N''%62BAFF6E-1045-4D11-B89F-84B2527F04E2%'') and (hp.codeemp in (''00351'',''00648'',''02800'',''00478''))'


IF CHARINDEX('at.CutOffDurationID', @condition,0) = 0  
BEGIN
    SELECT 
	@condition = ' AND at.CutOffDurationID like N''%'+CAST(ID AS NVARCHAR(MAX))+'%'''
	FROM Att_CutOffDuration
	WHERE IsDelete IS NULL AND GETDATE()>= DateStart AND GETDATE()<=DateEnd

END


----Xu ly Condition----
declare  @DateChot DATETIME

DECLARE @_String1 VARCHAR(MAX), @_String2 VARCHAR(MAX), @_String21 VARCHAR(MAX), @_String22 VARCHAR(MAX), @_String23 VARCHAR(MAX), @_String24 VARCHAR(MAX), @_String25 VARCHAR(MAX), @_String26 VARCHAR(MAX), @_String3 VARCHAR(MAX),@_String4 VARCHAR(MAX)

set @DateChot ='2020-09-15'
DECLARE @tblPermission TABLE (id uniqueidentifier primary key )

--DECLARE  @_ProfileID NVARCHAR(MAX), @_OrderNumber NVARCHAR(MAX)
--SET @_ProfileID = ''
--SET @_OrderNumber = ''

-- Condition
DECLARE @CutOffDurationID varchar(200) = ''
DECLARE @CutOffDurationID_ID UNIQUEIDENTIFIER

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
    
	set @index = charindex('at.CutOffDurationID like ',@tempID,0) 
	if(@index > 0)
	begin
		set @tempCondition = 'and ('+@tempID
		SET @CutOffDurationID = REPLACE(@tempCondition, 'and (at.CutOffDurationID like N', '' )
		set @CutOffDurationID = REPLACE(@CutOffDurationID,')','')
		set @CutOffDurationID = REPLACE(@CutOffDurationID,'%','')

	END

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1
	end
	drop table #tableTempCondition

-------------------------
SET @CutOffDurationID_ID = REPLACE(@CutOffDurationID,'''','')

DECLARE @Count INT = 1;
declare @ListCol varchar(max);
declare @ListAlilas varchar(max);
declare @SumWorkDate varchar(max);

DECLARE @DateStart date,  @DateEnd date
SELECT @DateStart = DateStart, @DateEnd = DateEnd from Att_CutOffDuration WHERE IsDelete is NULL AND ID = @CutOffDurationID_ID

DECLARE @FirstDay DATE = @DateStart;
while @FirstDay <= @DateEnd
        begin
            set @ListCol = coalesce(@ListCol + ',', '') + quotename(@FirstDay);
            set @ListAlilas = coalesce(@ListAlilas + ',', '') + quotename(@FirstDay) + ' as D' + convert(varchar(10), @Count);
            set @SumWorkDate = coalesce(@SumWorkDate + '+', '') + 'ISNULL(' + QUOTENAME(@FirstDay) + ',0)'
            set @FirstDay = dateadd(day, 1, @FirstDay);
            SET @Count += 1;
        END;



-- rpt_BangCongHangThang_BV

SET @_String1 = '
 DECLARE @tblPermission TABLE (id uniqueidentifier primary key ) INSERT INTO @tblPermission EXEC Get_Data_Permission_New ''' + @Username+ ''', ' + '''Hre_Profile'''+ '
 
declare @DateStart date = ''' + convert(varchar(20), @DateStart, 111) + ''';
declare @DateEnd date = ''' + convert(varchar(20), @DateEnd, 111) + ''';
declare @DateFromTS datetime = ''' + convert(varchar(20), @DateStart, 111) + ''';
declare @DateToTS datetime = ''' + convert(varchar(20), @DateEnd, 111) + ''';


SELECT		'+@Top+' at.*
INTO		#Att_AttendanceTable
FROM		Att_AttendanceTable at
INNER JOIN  @tblPermission tps 
	ON		tps.ID = at.ProfileID
INNER JOIN	Hre_Profile hp
	ON		hp.ID = at.ProfileID
LEFT JOIN	Cat_OrgStructure cos
	ON		cos.id=at.OrgStructureID
WHERE		at.IsDelete IS NULL
	AND		hp.IsDelete IS NULL
			' + @condition + '

SELECT		at.ProfileID,ati.* 
INTO		#Att_AttendanceTableItem
FROM		#Att_AttendanceTable at
INNER JOIN	Att_AttendanceTableItem ati ON at.id = ati.AttendanceTableID


-- Cong hang ngay
SELECT		at.ProfileID,ati.AttendanceTableID,ati.WorkDate
			,(CASE WHEN cs1.Code=''KT_KyThuatTrucDem_7h_22h'' then ati.WorkPaidHours/15 +  isnull(OvertimeOFFHours1,0)/8
				WHEN ati.WorkHoursShift2 >0 then  ati.WorkHoursShift1/cs1.StdWorkHours*1.0 +ati.WorkHoursShift2/cs2.StdWorkHours*1.0 + isnull(OvertimeOFFHours1,0)/8
				WHEN ati.shiftid is null then isnull(OvertimeOFFHours1,0)/8
				ELSE  (isnull(OvertimeOFFHours1,0)+ati.WorkPaidHours)/NULLIF(cs1.StdWorkHours,0)*1.0 END
			) as Cong
INTO		#KQ_Tmp_Item
FROM		#Att_AttendanceTable at
INNER JOIN	#Att_AttendanceTableItem ati ON at.id = ati.AttendanceTableID
LEFT  JOIN	cat_shift cs1 ON cs1.id = ati.ShiftID
LEFT  JOIN	cat_shift cs2 ON cs2.id = ati.Shift2ID

SELECT		ProfileID as ProfileID_pivot,AttendanceTableID AS AttendanceTableID_pivot, ' + @ListAlilas + ', ' +ISNULL(@SumWorkDate,0)+' AS CongThucTe
INTO		#KQ_Tmp_Item_pivot
FROM		(SELECT profileid,AttendanceTableID,WorkDate,Cong FROM #KQ_Tmp_Item ) D
PIVOT 
			(
				SUM(Cong) for WorkDate in (' + @ListCol + ')
			 ) as pvtbl


---Tien Muon
SELECT		ProfileID,AttendanceTableID,SUM(TienPhatMuon) AS Tien_Muon, SUM(SoLanMuon) AS SoLanMuon,STRING_AGG(CONCAT(DATEPART(DAY,WorkDate),''/'',DATEPART(MONTH,WorkDate)),'','') AS MuonSom  
INTO		#TienMuon
FROM		(
			SELECT		(CASE WHEN ati.LateEarlyMinutes <=3 THEN 0
						WHEN ati.LateEarlyMinutes >3 AND ati.LateEarlyMinutes <10  THEN 30000
						WHEN ati.LateEarlyMinutes >=10 AND ati.LateEarlyMinutes <30 THEN 50000
						WHEN ati.LateEarlyMinutes >=30  THEN 100000
						ELSE 0 END
						) AS TienPhatMuon
						,CASE WHEN ati.LateEarlyMinutes >3 THEN 1 ELSE 0 END AS SoLanMuon,ati.workdate ,at.ProfileID,ati.AttendanceTableID
			FROM		#Att_AttendanceTable at
			INNER JOIN	#Att_AttendanceTableItem ati ON at.id = ati.AttendanceTableID
			WHERE		at.ProfileID IS NOT NULL AND ati.LateEarlyMinutes>0
			) aaa
GROUP BY	ProfileID,AttendanceTableID 

--- Ca dem
SELECT		AttENDanceTableID, SUM((CASE WHEN NightShiftHours>0 THEN 1 ELSE 0 END) )AS SoLanCaDem
INTO		#SoLanCaDem
FROM		#Att_AttendanceTableItem
WHERE		1 = 1 AND  NightShiftHours >0
GROUP BY	AttENDanceTableID	
					
'
SET @_String2 = '
----TienTruc
SELECT		AttENDanceTableID, 
			SUM(
				( CASE  WHEN DateOff IS  NULL AND DATEPART(WEEKDAY,WorkDate) =1 AND AvailableHours>0 AND WorkDate<=DateENDProbation AND DateENDProbation IS NOT NULL THEN 
							CASE WHEN (cou.E_TEAM_CODE NOT IN (''YN_MK'', ''PTM_MK'') AND cou.E_UNIT_CODE NOT IN (''Thuan Hieu'') OR cou.E_TEAM_CODE IS NULL OR cou.E_UNIT_CODE IS NULL ) AND at.monthyear >= ''2022-05-01'' THEN 105000*WorkPaidHours/AvailableHours ELSE 70000*WorkPaidHours/AvailableHours END
				WHEN DateOff IS  NULL AND  DATEPART(WEEKDAY,WorkDate) =1 AND AvailableHours>0 THEN 
							CASE WHEN (cou.E_TEAM_CODE NOT IN (''YN_MK'', ''PTM_MK'') AND cou.E_UNIT_CODE NOT IN (''Thuan Hieu'') OR cou.E_TEAM_CODE IS NULL OR cou.E_UNIT_CODE IS NULL ) AND at.monthyear >= ''2022-05-01'' THEN 150000*WorkPaidHours/AvailableHours ELSE 100000*WorkPaidHours/AvailableHours END
				ELSE 0 END)) AS TrucCN
			,SUM(
				(CASE WHEN DateOff IS NOT NULL AND AvailableHours>0 AND WorkDate<=DateENDProbation AND DateENDProbation IS NOT NULL THEN
							CASE WHEN (cou.E_TEAM_CODE NOT IN (''YN_MK'', ''PTM_MK'') AND cou.E_UNIT_CODE NOT IN (''Thuan Hieu'') OR cou.E_TEAM_CODE IS NULL OR cou.E_UNIT_CODE IS NULL ) AND at.monthyear >= ''2022-05-01'' THEN 105000*WorkPaidHours/AvailableHours ELSE 70000*WorkPaidHours/AvailableHours END
				WHEN DateOff IS NOT NULL AND AvailableHours>0 THEN 
							CASE WHEN (cou.E_TEAM_CODE NOT IN (''YN_MK'', ''PTM_MK'') AND cou.E_UNIT_CODE NOT IN (''Thuan Hieu'') OR cou.E_TEAM_CODE IS NULL OR cou.E_UNIT_CODE IS NULL ) AND at.monthyear >= ''2022-05-01'' THEN 150000*WorkPaidHours/AvailableHours ELSE 100000*WorkPaidHours/AvailableHours END
				ELSE 0 END)) AS TrucNgayLe
INTO		#TienTruc
FROM		#Att_AttendanceTableItem ati
LEFT JOIN	Cat_DayOff b ON ati.WorkDate=b.DateOff AND b.IsDelete IS NULL
LEFT JOIN	#Att_AttendanceTable at ON ati.AttENDanceTableID =at.ID
LEFT JOIN	Hre_Profile d ON d.id= at.ProfileID
LEFT JOIN	Cat_OrgUnit cou on cou.OrgstructureID = at.OrgstructureID
WHERE		ShiftID  IN (SELECT id FROM Cat_Shift WHERE IsDelete IS NULL AND (StANDardHoursAllowanceFomula IS NULL OR StANDardHoursAllowanceFomula=''0''))
	AND		at.GradeAttendanceID NOT IN (SELECT id FROM Cat_GradeAttENDance WHERE Code IN (''KCC_BV'',''BV_TV'',''BV04'',''BV06'',''BV12'',''BV09'',''BV10'',''PTM01'',''BV14'',''BV21'',''BV26'',''BV30''))
	AND		(at.monthyear <=''2021-07-01'' OR at.monthyear >=''2021-11-01'')
GROUP BY AttENDanceTableID
	
----TienTrucTheoCa
	
SELECT		AttenDanceTableID
			,SUM (CASE WHEN WorkDate<DateENDProbation THEN ati.ActualHoursAllowance*0.7 ELSE ati.ActualHoursAllowance END) AS TienTrucTheoCa
INTO		#TienTrucTheoCa
FROM		#Att_AttendanceTableItem ati
LEFT JOIN	Cat_DayOff b ON ati.WorkDate=b.DateOff AND b.IsDelete IS NULL
LEFT JOIN	#Att_AttendanceTable at ON ati.AttENDanceTableID =at.ID
LEFT JOIN	Hre_Profile d ON d.id=at.ProfileID
WHERE		ati.isdelete IS NULL
GROUP BY	AttENDanceTableID


---- Bu cong

--SELECT		at.ProfileID,at.MontYear,apts.note, sum(apts.ActualHours) as BuCong
--INTO		#BuCong
--FROM		#Att_AttendanceTable at
--LEFT JOIN	Att_ProfileTimeSheet apts
--	ON		at.ProfileID = apts.ProfileID and apts.WorkDate Between at.DateStart AND at.DateEnd
--LEFT JOIN	Cat_JobType cjt
--	ON		apts.JobTypeID = cjt.ID
--WHERE		apts.IsDelete IS NULL

--left join	(
--			select	ProfileID,WorkDate as MontYear,note, sum(ActualHours) as TruCong 
--			from	Att_ProfileTimeSheet
--			where	JobTypeID in (select id from Cat_JobType where Code in(''CongThieu''))
--				and IsDelete is null and day(WorkDate)=1
--			group by ProfileID,WorkDate,note
--			) BuCong2 on BuCong2.ProfileID=at.ProfileID and BuCong2.MontYear>=at.DateStart and BuCong2.MontYear<=at.DateEnd

'
SET @_String3 = '
SELECT		'+@top+'
			at.ID AS AttendanceTableID, at.DateStart as NgayBatDau,at.profileid,hp.id,hp.CodeEmp,hp.ProfileName,hpm.OtherName,cp.PositionName,cos.OrgStructureName, hp.CodeEmpClient , hp.DateQuit, hp.DateENDProbation, at.MonthYear, at.CutOffDurationID, cos.OrderNumber
			,at.StdWorkDayCount, (at.Overtime1Hours +at.Overtime2Hours+at.Overtime3Hours+at.Overtime4Hours+at.Overtime5Hours+at.Overtime6Hours)*2/8 as OT
			,
			CASE WHEN cl1.Code IN (''H'',''H1'' ) THEN at.LeaveDay1Days ELSE 0 END +
			CASE WHEN cl2.Code IN (''H'',''H1'' ) THEN at.LeaveDay2Days ELSE 0 END +
			CASE WHEN cl3.Code IN (''H'',''H1'' ) THEN at.LeaveDay3Days ELSE 0 END +
			CASE WHEN cl4.Code IN (''H'',''H1'' ) THEN at.LeaveDay4Days ELSE 0 END +
			CASE WHEN cl5.Code IN (''H'',''H1'' ) THEN at.LeaveDay5Days ELSE 0 END +
			CASE WHEN cl6.Code IN (''H'',''H1'' ) THEN at.LeaveDay6Days ELSE 0 END 
			AS DiHoc
			,
			CASE WHEN cl1.Code NOT IN (''H'',''H1'' ) THEN at.LeaveDay1Days ELSE 0 END +
			CASE WHEN cl2.Code NOT IN (''H'',''H1'' ) THEN at.LeaveDay2Days ELSE 0 END +
			CASE WHEN cl3.Code NOT IN (''H'',''H1'' ) THEN at.LeaveDay3Days ELSE 0 END +
			CASE WHEN cl4.Code NOT IN (''H'',''H1'' ) THEN at.LeaveDay4Days ELSE 0 END +
			CASE WHEN cl5.Code NOT IN (''H'',''H1'' ) THEN at.LeaveDay5Days ELSE 0 END +
			CASE WHEN cl6.Code NOT IN (''H'',''H1'' ) THEN at.LeaveDay6Days ELSE 0 END 
			AS NgayCongKhacHuongLuong
			,
			CASE WHEN cl1.Code IN (''H'',''CT'' ) THEN at.LeaveDay1Days ELSE 0 END +
			CASE WHEN cl2.Code IN (''H'',''CT'' ) THEN at.LeaveDay2Days ELSE 0 END +
			CASE WHEN cl3.Code IN (''H'',''CT'' ) THEN at.LeaveDay3Days ELSE 0 END +
			CASE WHEN cl4.Code IN (''H'',''CT'' ) THEN at.LeaveDay4Days ELSE 0 END +
			CASE WHEN cl5.Code IN (''H'',''CT'' ) THEN at.LeaveDay5Days ELSE 0 END +
			CASE WHEN cl6.Code IN (''H'',''CT'' ) THEN at.LeaveDay6Days ELSE 0 END 
			as NgayCongKhacHuongLuong_TinhPhep
			,
			CASE WHEN cl1.Code IN (''DB'',''CT'' ) THEN at.LeaveDay1Days ELSE 0 END +
			CASE WHEN cl2.Code IN (''DB'',''CT'' ) THEN at.LeaveDay2Days ELSE 0 END +
			CASE WHEN cl3.Code IN (''DB'',''CT'' ) THEN at.LeaveDay3Days ELSE 0 END +
			CASE WHEN cl4.Code IN (''DB'',''CT'' ) THEN at.LeaveDay4Days ELSE 0 END +
			CASE WHEN cl5.Code IN (''DB'',''CT'' ) THEN at.LeaveDay5Days ELSE 0 END +
			CASE WHEN cl6.Code IN (''DB'',''CT'' ) THEN at.LeaveDay6Days ELSE 0 END 
			as NghiHuongNgayThua
			,
			CASE WHEN cl1.Code IN (''CT'' ) THEN at.LeaveDay1Days ELSE 0 END +
			CASE WHEN cl2.Code IN (''CT'' ) THEN at.LeaveDay2Days ELSE 0 END +
			CASE WHEN cl3.Code IN (''CT'' ) THEN at.LeaveDay3Days ELSE 0 END +
			CASE WHEN cl4.Code IN (''CT'' ) THEN at.LeaveDay4Days ELSE 0 END +
			CASE WHEN cl5.Code IN (''CT'' ) THEN at.LeaveDay5Days ELSE 0 END +
			CASE WHEN cl6.Code IN (''CT'' ) THEN at.LeaveDay6Days ELSE 0 END 
			AS P_DAY
			,at.LateEarlyCount as SL_MuonSom ,MissInOut.SL_ThieuInOut
			,CASE WHEN hp.DateENDProbation>= convert(date, DateHire,102) THEN at.ActualHoursAllowance*0.7	
				ELSE at.ActualHoursAllowance END as TienTruc
			,at.DateStart,at.DateEND,ald.DateStart as BatDauTS,ald.DateEND as KetThucTS
			,MissInOut.ThieuInOut ,TienMuon.MuonSom,TienMuon.Tien_Muon
 '
SET @_String4 = 
'			,ISNULL(aal.InitAnlValue,0) AS InitAnlValue ,aal.InitMensesValue,aal.InitAdditionalValue,ISNULL(aal.InitSickValue,0) AS InitSickValue
			,BuCong,TruCong,TrucNgayLe,TrucCN,TienTrucTheoCa
			,PhatKhac.AmountOfFine as TienPhatKhac,PhatKhac.Notes as LyDoPhat,BuCong1.Note as GhiChu_BuCong,BuCong2.Note as GhiChu_TruCong,concat(VPTS.Notes,xl1.Note) as LyDo_VPTS
			,VPTS.AmountOfFine as ViPhamThaiSan,VPTS.NameEntityName,xl.Code as MaXepLoai,xl.Note as GhiChuXepLoai,tt.GhiChuTienTruc,tt.ActualHours
			,GhiChuNhap,convert(float,ale.Note)  as CongKhac, cg.code as MaCheDo,cn.NameEntityName as ChucVuThue
			,at.PaidWorkDayCount + at.PaidLeaveDays as TongCongHuongLuong,at.PaidWorkDayCount +(at.OvertimeOFF1Hours+at.OvertimeOFF2Hours)/8  as CongThucTe
			,hrt.FROMDate as TGBatDauHoc, hrt.ToDate as TGKetThucHoc, hp.DateHire,TruyThu.ActualHours as TruyThu,TruyThu.Note as TruyThuNote, ChiVan.ActualHours as ChiVan,ChiVan.Note as GhiChu_ChiVan
			,SoLanCaDem.SoLanCaDem
			,ald2.DateStart as NAL_DAY, ald3.DateStart as BH_DAY, ald4.DateStart as CH_DAY
			,concat(cl1.LeaveDayTypeName,cl2.LeaveDayTypeName,cl3.LeaveDayTypeName,cl4.LeaveDayTypeName,cl5.LeaveDayTypeName,cl6.LeaveDayTypeName) as LyDoNghi
			,BuCong1.Note as GhiChuBuCong,TS.ActualHours as CongTS,at.Note as ThamNienThangNay,isnull(al1.AnlValue,0)+thamnien.LuyKe_ThamNien as ThamNien,hp.CompanyID
			,TruSoNgayLe, SL1, SL2, DienGiai1, DienGiai2, Cong_HL.ActualHours as CongHL ,cw.Code

INTO		#KQ_Tmp
FROM		dbo.Att_AttendanceTable at

INNER JOIN	@tblPermission tps on tps.ID = at.ProfileID
LEFT JOIN	Cat_GradeAttENDance cg on cg.id=at.GradeAttENDanceID
LEFT JOIN	Hre_Profile hp on hp.ID=at.ProfileID AND hp.isdelete is null
left join	Cat_WorkPlace cw on cw.id=hp.WorkPlaceID
left join	Hre_ProfileMoreInfo hpm on hp.ProfileMoreInfoID=hpm.id and hpm.isdelete is null
LEFT JOIN	Cat_NameEntity cn on cn.id= hp.DistributionChannelID AND cn.isdelete is null AND NameEntityType=''E_CHANNELDISTRIBUTION'' AND EnumType=''E_CHANNELDISTRIBUTION''
--Ly do nghi
left join	Cat_LeaveDayType cl1 on cl1.id=at.LeaveDay1Type and cl1.PaidRate=1
left join	Cat_LeaveDayType cl2 on cl2.id=at.LeaveDay2Type and cl2.PaidRate=1
left join	Cat_LeaveDayType cl3 on cl3.id=at.LeaveDay3Type and cl3.PaidRate=1
left join	Cat_LeaveDayType cl4 on cl4.id=at.LeaveDay4Type and cl4.PaidRate=1
left join	Cat_LeaveDayType cl5 on cl5.id=at.LeaveDay5Type and cl5.PaidRate=1
left join	Cat_LeaveDayType cl6 on cl6.id=at.LeaveDay6Type and cl6.PaidRate=1
--TruNgayLe
left join	(select		at.ProfileID,at.ID, count(cd.id) TruSoNgayLe 
			from		Att_AttendanceTable at
			left join	Hre_Profile hp on hp.id=at.ProfileID
			left join	Cat_DayOff cd on cd.DateOff>=at.DateStart and cd.DateOff<=at.DateEnd
			where		at.IsDelete is null
				and		hp.DateHire >at.DateStart and hp.DateHire <at.DateEnd
			group by	at.ProfileID,at.ID
			) TruNgayLe on TruNgayLe.ProfileID=at.ProfileID and TruNgayLe.ID=at.ID

--Thoi gian hoc
LEFT JOIN	Hre_ResearcchTopic hrt on hrt.profileid=at.profileid AND hrt.isdelete is null AND (( at.DateStart>=hrt.FROMDate AND hrt.ToDate>=at.DateStart) or ( at.DateStart<=hrt.FROMDate AND hrt.FROMDate <= at.DateEND AND hrt.ToDate>=at.DateStart))
----XepLoai
LEFT JOIN	(SELECT		ProfileID,cj.Code,ap.Note,ap.WorkDate 
			FROM		Att_ProfileTimeSheet ap
			LEFT JOIN	Cat_JobType cj on cj.id=ap.JobTypeID
			WHERE		JobTypeID in (SELECT id FROM Cat_JobType WHERE Code in (''Loai1'',''Loai2'',''Loai3'',''Loai B'',''KXL'',''Loai B thieu cong'',''B_ViPhamTS'',''B_thieucong'',''Nghi_KL'',''Nghi_De'')) 
				AND		ap.IsDelete is null
			) xl on xl.profileid=at.profileid AND xl.WorkDate>=at.DateStart AND xl.WorkDate<=at.DateEND
--4
	'
SET @_String21 = '	 
LEFT JOIN	(SELECT		ProfileID,cj.Code,ap.Note,ap.WorkDate 
			FROM		Att_ProfileTimeSheet ap
			LEFT JOIN	Cat_JobType cj on cj.id=ap.JobTypeID
			WHERE		JobTypeID in (SELECT id FROM Cat_JobType WHERE Code in (''B_ViPhamTS'')) AND ap.IsDelete is null
			) xl1 on xl1.profileid=at.profileid AND xl1.WorkDate>=at.DateStart AND xl1.WorkDate<=at.DateEND

---TienTrucNhap
LEFT JOIN	(SELECT		ProfileID,cj.Code,ap.Note as GhiChuTienTruc,ap.WorkDate,ap.ActualHours 
			FROM		Att_ProfileTimeSheet ap
			LEFT JOIN	Cat_JobType cj on cj.id=ap.JobTypeID
			WHERE		JobTypeID in (SELECT id FROM Cat_JobType WHERE Code =''TienTruc'') AND ap.IsDelete is null
			) tt ON tt.profileid = at.profileid AND tt.WorkDate>=at.DateStart AND tt.WorkDate<=at.DateEND
--GhiChuNhap
LEFT JOIN	(SELECT		ProfileID,cj.Code,ap.Note as GhiChuNhap,ap.WorkDate,ap.ActualHours 
			FROM		Att_ProfileTimeSheet ap
			LEFT JOIN	Cat_JobType cj on cj.id = ap.JobTypeID
			WHERE		JobTypeID in (SELECT id FROM Cat_JobType WHERE Code =''GhiChu'') AND ap.IsDelete is null
			) GhiChu on GhiChu.profileid=at.profileid AND GhiChu.WorkDate>=at.DateStart AND GhiChu.WorkDate<=at.DateEND
--ChiVan
LEFT JOIN	(SELECT		ProfileID,cj.Code,ap.Note ,ap.WorkDate,ap.ActualHours 
			FROM		Att_ProfileTimeSheet ap
			LEFT JOIN	Cat_JobType cj on cj.id=ap.JobTypeID
			WHERE		JobTypeID in (SELECT id FROM Cat_JobType WHERE Code =''CA'') AND ap.IsDelete is null
			) ChiVan on ChiVan.profileid=at.profileid AND ChiVan.WorkDate>=at.DateStart AND ChiVan.WorkDate<=at.DateEND

--TS
LEFT JOIN	(select		ProfileID,cj.Code,ap.Note ,ap.WorkDate,ap.ActualHours 
			from		Att_ProfileTimeSheet ap
			LEFT JOIN	Cat_JobType cj on cj.id=ap.JobTypeID
			where		JobTypeID in (select id from Cat_JobType where Code =''TS'') and ap.IsDelete is null
			) TS on TS.profileid=at.profileid and TS.WorkDate>=at.DateStart and TS.WorkDate<=at.DateEnd
--TruyThu
LEFT JOIN	(SELECT		ProfileID,cj.Code,ap.Note ,ap.WorkDate,ap.ActualHours 
			FROM		Att_ProfileTimeSheet ap
			LEFT JOIN	Cat_JobType cj on cj.id=ap.JobTypeID
			WHERE		JobTypeID in (SELECT id FROM Cat_JobType WHERE Code =''TruyThu'') AND ap.IsDelete is NULL
			) TruyThu on TruyThu.profileid = at.profileid AND TruyThu.WorkDate>=at.DateStart AND TruyThu.WorkDate <= at.DateEND

---Cong HL 
LEFT JOIN	(SELECT		ProfileID,cj.Code,ap.Note ,ap.WorkDate,ap.ActualHours 
			FROM		Att_ProfileTimeSheet ap
			LEFT JOIN	Cat_JobType cj on cj.id=ap.JobTypeID
			WHERE		JobTypeID in (SELECT id FROM Cat_JobType WHERE Code =''Cong_HL'') AND ap.IsDelete is NULL
			) Cong_HL  on Cong_HL.profileid = at.profileid AND Cong_HL.WorkDate>=at.DateStart AND Cong_HL.WorkDate <= at.DateEND
--21
'
SET @_String22 = '
--Vi pham thai san và tien phat khac
LEFT JOIN	(SELECT		ProfileID,hd.DateOfEffective,cn.NameEntityName,SUM(hd.AmountOfFine) as AmountOfFine,hd.Notes,DisciplineResonID,DateENDOfViolation 
			FROM		Hre_Discipline hd
			LEFT JOIN	Cat_NameEntity cn on cn.ID=hd.DisciplineResonID AND NameEntityType=''E_DISCIPLINE_REASON''
			WHERE		hd.IsDelete is null AND cn.Code=2
			GROUP BY	ProfileID,hd.DateOfEffective,cn.NameEntityName,hd.Notes,DisciplineResonID,DateENDOfViolation
			) PhatKhac ON at.profileid = PhatKhac.profileid AND at.DateStart>=PhatKhac.DateOfEffective AND at.DateStart<=PhatKhac.DateENDOfViolation

LEFT JOIN	(SELECT		ProfileID,hd.DateOfEffective,cn.NameEntityName,hd.AmountOfFine,hd.Notes,DisciplineResonID,DateENDOfViolation 
			FROM		Hre_Discipline hd
			LEFT JOIN	Cat_NameEntity cn on cn.ID=hd.DisciplineResonID AND NameEntityType=''E_DISCIPLINE_REASON''
			WHERE		hd.IsDelete is null AND cn.Code=1
			) VPTS on at.profileid = VPTS.profileid AND at.DateStart>=VPTS.DateOfEffective AND at.DateStart<=VPTS.DateENDOfViolation
--CongUng
LEFT JOIN	Att_AnnualLeaveExtEND ale on ale.profileid=at.profileid AND ale.monthstart>=at.DateStart AND ale.monthEND<=at.dateEND AND ale.isdelete is null

--Phep thang nay- Phep ton

LEFT JOIN	Att_AnnualLeave aal 
	ON		aal.profileid=at.profileid AND aal.year=year(at.monthyear) AND aal.MonthStart=month(at.monthyear) AND aal.isdelete is null 
			AND ((at.DateEND=''2020-08-31 23:59:59.000'' AND aal.IPCreate=1) or (at.DateEND<>''2020-08-31 23:59:59.000'' AND (aal.IPCreate=0 or aal.IPCreate is null  )))

LEFT JOIN	Cat_OrgStructure cos on cos.id=at.OrgStructureID
LEFT JOIN	Cat_Position cp on cp.id =at.PositionID
LEFT JOIN	(select		* 
			from		Att_LeaveDay 
			where		DateStart between @DateFromTS and @DateToTS or (DateEnd between @DateFromTS and @DateToTS) 
			) ald ON ald.profileid=at.profileid AND ald.LeaveDayTypeID = (SELECT id FROM Cat_LeaveDayType WHERE Code=''TS'')  AND ald.isdelete is null AND ald.DateEND = (SELECT max(dateEND) FROM Att_LeaveDay bl WHERE ald.ProfileID=bl.ProfileID)
			AND ald.ID = (SELECT ID FROM Att_LeaveDay bl WHERE ald.ProfileID=bl.ProfileID ORDER BY dateEND desc OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY   )

LEFT JOIN	Att_LeaveDay ald2 
	ON		ald2.profileid=at.profileid AND ald2.LeaveDayTypeID = (SELECT id FROM Cat_LeaveDayType WHERE Code=''Nald'') 
			AND ald2.isdelete is null
			AND ald2.DateEND = (SELECT max(dateEND) FROM Att_LeaveDay bl WHERE ald2.ProfileID=bl.ProfileID) AND ald2.LeaveDays>=22 AND at.PaidWorkDayCount<4
			AND ald2.ID = (SELECT ID FROM Att_LeaveDay bl WHERE ald2.ProfileID=bl.ProfileID ORDER BY dateEND desc OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY   )

LEFT JOIN	Att_LeaveDay ald3 
	ON		ald3.profileid=at.profileid AND ald3.LeaveDayTypeID = (SELECT id FROM Cat_LeaveDayType WHERE Code=''BH'')  AND ald3.isdelete is null
			AND ald3.DateEND = (SELECT max(dateEND) FROM Att_LeaveDay bl WHERE ald3.ProfileID=bl.ProfileID) AND ald3.LeaveDays>=22 AND at.PaidWorkDayCount<4
			AND ald3.ID = (SELECT ID FROM Att_LeaveDay bl WHERE ald3.ProfileID=bl.ProfileID ORDER BY dateEND desc OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY   )

LEFT JOIN	Att_LeaveDay ald4 
	ON		ald4.profileid=at.profileid AND ald4.LeaveDayTypeID =(SELECT id FROM Cat_LeaveDayType WHERE Code=''CH'')  AND ald4.isdelete is null
			AND ald4.DateEND = (SELECT max(dateEND) FROM Att_LeaveDay bl WHERE ald4.ProfileID=bl.ProfileID) AND ald4.LeaveDays>=22 AND at.PaidWorkDayCount<4
			AND ald4.ID = (SELECT ID FROM Att_LeaveDay bl WHERE ald4.ProfileID=bl.ProfileID ORDER BY dateEND desc OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY   )

LEFT JOIN	(select		ID, sum(SL_ThieuInOut) SL_ThieuInOut,STRING_AGG(concat(DATEPART(DAY,WorkDate),''/'',DATEPART(MONTH,WorkDate)),'','') ThieuInOut   
			from		(select		at.id, 
									(case when aw.MissInOutReasonID1 not in (select id from Cat_TAMScanReasonMiss where Code in(''QCC01'',''QCC04'',''QCC05'',''QCC02'',''QCC06'',''QCC07'')) then 1 else 0 end)+
									(case when aw.MissInOutReasonID2 not in (select id from Cat_TAMScanReasonMiss where Code in(''QCC01'',''QCC04'',''QCC05'',''QCC02'',''QCC06'',''QCC07'')) then 1 else 0 end) 
									as SL_ThieuInOut,aw.WorkDate
						from		Att_AttendanceTable at
						left join	Att_Workday aw on aw.ProfileID =at.ProfileID and aw.WorkDate>=at.DateStart and aw.WorkDate<=at.DateEnd and aw.MissInOutReason is not null and aw.IsDelete is null
						where		at.IsDelete is null
						) a
			Group		by ID
			) MissInOut on at.id=MissInOut.ID

--22
'
SET @_String23 = '

LEFT JOIN	#TienMuon TienMuon on TienMuon.AttendanceTableID=at.id and TienMuon.ProfileID=at.ProfileID
LEFT JOIN	#SoLanCaDem SoLanCaDem on at.id=SoLanCaDem.AttENDanceTableID
left join	(
			select	ProfileID,WorkDate as MontYear,note, sum(ActualHours) as BuCong 
			from	Att_ProfileTimeSheet
			where	JobTypeID in (select id from Cat_JobType where Code in(''CongThua''))
				and	IsDelete is null and day(WorkDate)=1
			group by ProfileID,WorkDate,note
			) BuCong1 on BuCong1.ProfileID=at.ProfileID and BuCong1.MontYear>=at.DateStart and BuCong1.MontYear<=at.DateEnd

left join	(
			select	ProfileID,WorkDate as MontYear,note, sum(ActualHours) as TruCong 
			from	Att_ProfileTimeSheet
			where	JobTypeID in (select id from Cat_JobType where Code in(''CongThieu''))
				and IsDelete is null and day(WorkDate)=1
			group by ProfileID,WorkDate,note
			) BuCong2 on BuCong2.ProfileID=at.ProfileID and BuCong2.MontYear>=at.DateStart and BuCong2.MontYear<=at.DateEnd



----TienTruc
left JOIN	#TienTruc TienTruc on TienTruc.AttENDanceTableID=at.id

----TienTrucTheoCa
LEFT JOIN	#TienTrucTheoCa  aaaa  on aaaa.AttENDanceTableID=at.id

--ThamNien
left join	(select		aa1.ProfileID, aa1.monthyear, aa1.AnlValue 
			from		Att_AnnualLeaveMonthByType aa1
			join		(select		ProfileID, max(monthyear) monthyear 
						from		Att_AnnualLeaveMonthByType 
						group by	ProfileID
						) aa2 on aa1.ProfileID = aa2.ProfileID and aa1.monthyear = aa2.monthyear 
			) al1 on al1.ProfileID=at.ProfileID --and year(al1.monthyear) = Year(at.monthyear)-1 and month(al1.monthyear)=12

left join	(SELECT		Att_AttendanceTable.ProfileID, MonthYear
						,Att_AttendanceTable.Note+isnull(ChiVan.ActualHours,0)/convert(float,nullif(Att_AttendanceTable.StdWorkDayCount,0)) as ThamNien
						,SUM (convert(float,Att_AttendanceTable.Note)+isnull(ChiVan.ActualHours,0)/convert(float,nullif(Att_AttendanceTable.StdWorkDayCount,0))) OVER (PARTITION BY Att_AttendanceTable.ProfileID ORDER BY Att_AttendanceTable.MonthYear) AS LuyKe_ThamNien
			FROM		Att_AttendanceTable 
			left join	Att_ProfileTimeSheet ChiVan on  ChiVan.profileid = Att_AttendanceTable.profileid and ChiVan.WorkDate>=Att_AttendanceTable.DateStart and ChiVan.WorkDate<=Att_AttendanceTable.DateEnd and ChiVan.isdelete is null and ChiVan.JobTypeID = (select id from Cat_JobType where Code=''CA'')
			left join	Att_ProfileTimeSheet CongThua on  CongThua.profileid = Att_AttendanceTable.profileid and CongThua.WorkDate>=Att_AttendanceTable.DateStart and CongThua.WorkDate<=Att_AttendanceTable.DateEnd and CongThua.isdelete is null and CongThua.JobTypeID = (select id from Cat_JobType where Code=''CongThua'')
			where		Att_AttendanceTable.IsDelete is null
				and		Att_AttendanceTable.MonthYear>=''2021-01-01''
			) thamnien on thamnien.ProfileID=at.ProfileID and thamnien.MonthYear=at.MonthYear
--23
	'
	
SET @_String24 = '
----Text thieuinout va muon som	

--Canteen
left join	(select		cms.ProfileID,DATEADD(month, DATEDIFF(month, 0, TimeLog), 0) as Thang,count (cms.id) SL1
						,STRING_AGG(concat(''`'',DATEPART(DAY,TimeLog),''/'',DATEPART(MONTH,TimeLog)),'','') DienGiai1
			from		Can_MealRecord cms
			left join	Can_MealBillEmployee cm on cm.ProfileID=cms.ProfileID and cm.DateMeal=DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) and cm.MealUnitID is null and cm.isdelete is null and (cm.Status is null or cm.Status<>''E_CANCEL'')
			where		cms.IsDelete is null and cm.id is null
				and		cms.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB''))
			group by	cms.ProfileID,DATEADD(month, DATEDIFF(month, 0, TimeLog), 0)
			) KoDK_CoAn on at.MonthYear=KoDK_CoAn.Thang and at.ProfileID=KoDK_CoAn.ProfileID

left join	(select		cm.ProfileID,DATEADD(month, DATEDIFF(month, 0, cm.DateMeal), 0) Thang,count(cm.id) SL2 
						,STRING_AGG(concat(''`'',DATEPART(DAY,DateMeal),''/'',DATEPART(MONTH,DateMeal)),'','') DienGiai2
			from		Can_MealBillEmployee cm
			left join	(select		ProfileID,DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) as Ngay ,TimeLog,MachineCode
						from	Can_MealRecord 
						where	IsDelete is null
						) QuetThe on QuetThe.ProfileID=cm.ProfileID and QuetThe.Ngay=cm.DateMeal
			where		cm.IsDelete is null and QuetThe.TimeLog is null  and cm.MealUnitID is null
				and		(cm.Status is null or cm.Status<>''E_CANCEL'')
				and		cm.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB''))
			group by cm.ProfileID, DATEADD(month, DATEDIFF(month, 0, cm.DateMeal), 0)
			) CoDK_KhongAn on at.MonthYear=CoDK_KhongAn.Thang and at.ProfileID=CoDK_KhongAn.ProfileID

WHERE		at.IsDelete is NULL AND hp.CodeEmp IS NOT NULL 
--24
'+@condition+' '


SET @_String25 = '

SELECT		DISTINCT CodeEmp,OtherName,ProfileName,ChucVuThue as ''PositionName'',OrgStructureName,MonthYear 
			,kqtip.*
			,CongKhac
			,kqtip.CongThucTe + isnull(CongKhac,0) as ThangNay
			,ISNULL(BuCong,0)- isnull(TruCong,0)+ ISNULL(NgayCongKhacHuongLuong,0) as ''NgayCongKhacHuongLuong'' , ISNULL(BuCong,0)- isnull(TruCong,0)+NgayCongKhacHuongLuong_TinhPhep as ''NgayCongKhacHuongLuong_TinhPhep'', NghiHuongNgayThua
			,CodeEmpClient,InitMensesValue,InitAdditionalValue,InitAnlValue,InitSickValue,BuCong,TruCong  
			,CutOffDurationID,OrderNumber
			,(CASE   
			WHEN DateHire> DateStart AND DateHire<DateEND AND (left(CodeEmpClient,2)<>''ZA'' or CodeEmpClient is null) and kqt.CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)>= (DATEDIFF(DAY,DateStart,DateEND)+1)/2 and TruSoNgayLe>0 and MaCheDo<>''BV07''   then 26
			WHEN DateHire> DateStart AND DateHire<DateEND AND (left(CodeEmpClient,2)<>''ZA'' or CodeEmpClient is null) and kqt.CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)>= (DATEDIFF(DAY,DateStart,DateEND)+1)/2 and TruSoNgayLe>0 and MaCheDo=''BV07''  then 22
			WHEN DateHire> DateStart AND DateHire<DateEND AND (left(CodeEmpClient,2)<>''ZA'' or CodeEmpClient is null) and kqt.CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)>= (DATEDIFF(DAY,DateStart,DateEND)+1)/2  then StdWorkDayCount
			WHEN DateHire> DateStart AND DateHire<DateEND AND (left(CodeEmpClient,2)<>''ZA'' or CodeEmpClient is null) and kqt.CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)< (DATEDIFF(DAY,DateStart,DateEND)+1)/2  then 26
			WHEN DateHire> DateStart AND DateHire<DateEND AND left(CodeEmpClient,2)=''ZA'' and kqt.CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)>= (DATEDIFF(DAY,DateStart,DateEND)+1)/2  then StdWorkDayCount
			WHEN DateHire> DateStart AND DateHire<DateEND AND left(CodeEmpClient,2)=''ZA'' and MaCheDo=''BV17'' and kqt.CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)< (DATEDIFF(DAY,DateStart,DateEND)+1)/2  then 26
			WHEN DateHire> DateStart AND DateHire<DateEND AND left(CodeEmpClient,2)=''ZA'' and MaCheDo<>''BV17'' and kqt.CongThucTe+NgayCongKhacHuongLuong+ISNULL(BuCong,0)+isnull(CongKhac,0)< (DATEDIFF(DAY,DateStart,DateEND)+1)/2  then 27
	
			ELSE StdWorkDayCount END
			) as StdWorkDayCount

			,OT,P_DAY,SL_MuonSom,SL_ThieuInOut
			, (case when left(MaCheDo,2)<>''KS''  then isnull(TienTrucTheoCa,0)+isnull(TrucNgayLe,0)+isnull(TrucCN,0) else isnull(TienTrucTheoCa,0) end)   as TienTruc, ActualHours as TienTrucNhap
			,DateQuit,DateStart,DateEND,ID,BatDauTS,KetThucTS
			,ThieuInOut,MuonSom
			,(case when MaXepLoai is not null then MaXepLoai 
			WHen DateEndProbation>= NgayBatDau then ''KXL''
			when NgayBatDau< ''2020-09-15'' then( case
			when kqt.CongThucTe+DiHoc<StdWorkDayCount-4 and kqt.CongThucTe+DiHoc>0 then N''Loai B thieu cong''
			when kqt.CongThucTe+DiHoc=StdWorkDayCount-4 and kqt.CongThucTe+DiHoc>0 then N''Loai3''

	--25
	'
	
	SET @_String26 = 
	'
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
			when kqt.CongThucTe+DiHoc<=StdWorkDayCount-4 and kqt.CongThucTe+DiHoc>0 then N''Loai B thieu cong''
			when isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)>6 then ''Loai B''

			when kqt.CongThucTe+DiHoc<=StdWorkDayCount-4 and kqt.CongThucTe+DiHoc>0 then N''Loai B thieu cong''

			when isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)>=4 and isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)<5 then ''Loai2''
			when isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)>=5 and isnull(SL_ThieuInOut,0)+isnull(SL_MuonSom,0)<=6 then ''Loai3''
			when MaCheDo=''BV07'' and InitAnlValue>0 then ''Loai1''
			when TongCongHuongLuong<=0 then ''''
			else ''Loai1'' end

			) as XepLoai
	
			, ViPhamThaiSan,TienPhatKhac,LyDoPhat,LyDo_VPTS,Concat(LyDoNghi,GhiChuXepLoai,GhiChu_ChiVan,GhiChuTienTruc,TruyThuNote,GhiChuNhap,GhiChu_BuCong,GhiChu_TruCong) as Notes,MaCheDo
			,CASE WHEN  DateENDProbation<=NgayBatDau then null ELSE DateENDProbation 
				END AS DateENDProbation
			,TruyThu,ChiVan,DateHire,SoLanCaDem
			,DiHoc,TGBatDauHoc,TGKetThucHoc 
			,CH_DAY,NAL_DAY,BH_DAY,CongTS
			,isnull(ThamNien,0) as ThamNien, ThamNienThangNay
			,kqt.CongThucTe as CongThucTe1,CompanyID,Tien_Muon, SL1,SL2, DienGiai1, DienGiai2, CongHL,code
			,ROW_NUMBER() OVER ( ORDER BY CodeEmp asc) as RowNumber 
INTO		#Results 
FROM		#KQ_Tmp kqt
LEFT JOIN	#KQ_Tmp_Item_pivot kqtip ON kqt.ProfileID = kqtip.ProfileID_pivot and kqt.AttendanceTableID = kqtip.AttendanceTableID_pivot



  
SELECT		CASE WHEN ISNULL(StdWorkDayCount,0) - ISNULL(ThangNay,0) - NgayCongKhacHuongLuong - ISNULL(DiHoc,0) <=0 THEN ISNULL(StdWorkDayCount,0) - ISNULL(ThangNay,0) - ISNULL(NgayCongKhacHuongLuong,0) ELSE DiHoc END as NgayCongDiHoc
			,CASE WHEN DateQuit IS NULL AND MaCheDo <> ''BV07'' 
			AND ISNULL(ThangNay,0) + NgayCongKhacHuongLuong + CASE WHEN ISNULL(StdWorkDayCount,0) - ISNULL(ThangNay,0) - NgayCongKhacHuongLuong - ISNULL(DiHoc,0) <=0 THEN ISNULL(StdWorkDayCount,0) - ISNULL(ThangNay,0) - ISNULL(NgayCongKhacHuongLuong,0) ELSE DiHoc END
			> 0
			THEN ISNULL(ThangNay,0) + NgayCongKhacHuongLuong
				+ CASE WHEN ISNULL(StdWorkDayCount,0) - ISNULL(ThangNay,0) - ISNULL(NgayCongKhacHuongLuong,0) - ISNULL(DiHoc,0) <=0 THEN ISNULL(StdWorkDayCount,0) - ISNULL(ThangNay,0) - ISNULL(NgayCongKhacHuongLuong,0) ELSE DiHoc END
				- ISNULL(StdWorkDayCount,0) 
			ELSE 0 END AS CongVsCongchuan
			,CASE WHEN ISNULL(CongThucTe,0)  + NgayCongKhacHuongLuong  > ISNULL(StdWorkDayCount,0) - 4 THEN 1 ELSE 0 END AS PhepThangNay
			,*, NULL AS "at.ProfileID", NULL AS "cos.OrderNumber", NULL AS "at.CutOffDurationID" 
INTO		#Results_Cong
FROM		#Results




SELECT		CASE WHEN ( InitAnlValue < 0 AND CongVsCongchuan < 0 AND CongVsCongchuan + InitSickValue + InitAnlValue >=0) OR ( InitAnlValue < 0 AND CongVsCongchuan >= 0 AND InitSickValue + InitAnlValue >0)
					THEN CongVsCongchuan + InitSickValue + InitAnlValue
				WHEN InitAnlValue < 0 AND CongVsCongchuan >= 0 AND InitSickValue + InitAnlValue + PhepThangNay <= 0 AND CongVsCongchuan + InitSickValue + InitAnlValue + PhepThangNay > 0
					THEN CongVsCongchuan + InitSickValue + InitAnlValue + PhepThangNay
				WHEN InitAnlValue < 0 AND CongVsCongchuan >= 0 AND InitSickValue + InitAnlValue + PhepThangNay > 0 
					THEN CongVsCongchuan
				WHEN InitAnlValue >= 0 AND InitSickValue + CongVsCongchuan >=0
					THEN CongVsCongchuan + InitSickValue
				ELSE 0 END AS CongThangSau
			,*
INTO		#Results_CongThangSau
FROm		#Results_Cong


select		CASE WHEN InitAnlValue <0 AND CongVsCongchuan <0 AND CongThangSau > 0
					THEN PhepThangNay
				WHEN InitAnlValue <0 AND CongVsCongchuan <0 AND CongThangSau = 0 AND CongVsCongchuan + InitSickValue + InitAnlValue + PhepThangNay >=0
					THEN CongVsCongchuan + InitSickValue + InitAnlValue + PhepThangNay
				WHEN InitAnlValue <0 AND CongVsCongchuan <0 AND CongThangSau = 0 AND InitSickValue + InitAnlValue + PhepThangNay < 0
					THEN InitSickValue + InitAnlValue + PhepThangNay
				WHEN InitAnlValue <0 AND CongVsCongchuan >= 0
					THEN CongVsCongchuan + InitSickValue + InitAnlValue + PhepThangNay - CongThangSau
				WHEN InitAnlValue >=0 AND CongThangSau > 0 
					THEN InitAnlValue + PhepThangNay
				WHEN InitAnlValue >=0 AND CongThangSau = 0 AND CongVsCongchuan + InitSickValue + InitAnlValue + PhepThangNay > 0
					THEN CongVsCongchuan + InitSickValue + InitAnlValue + PhepThangNay
				ELSE 0 END AS PhepThangSau
			,*
into		#Results_PhepThangSau
from #Results_CongThangSau


select		CASE WHEN InitAnlValue >=0 
					THEN InitAnlValue + PhepThangNay - PhepThangSau
				WHEN InitAnlValue < 0 AND PhepThangSau = 0
					THEN PhepThangNay
				WHEN InitAnlValue < 0 AND PhepThangSau > 0
					THEN PhepThangNay - PhepThangSau
				WHEN InitAnlValue < 0 AND PhepThangSau < 0
					THEN PhepThangNay
				ELSE 0 END AS PhepSuDung
			,* 
from #Results_PhepThangSau

 --26

 drop table #Att_AttENDanceTableItem,#KQ_Tmp_Item, #KQ_Tmp_Item_pivot,#TienMuon,#SoLanCaDem, #TienTruc, #TienTrucTheoCa, #KQ_Tmp, #Results, #Results_Cong

'

PRINT @_String1
PRINT @_String2
PRINT @_String3
PRINT @_String4
PRINT @_String21
PRINT @_String22
PRINT @_String23
PRINT @_String24
PRINT @_String25
PRINT @_String26

EXECUTE( @_String1+ @_String2 +@_String3 + @_String4 +@_String21+@_String22+@_String23+@_String24+@_String25+@_String26)
END


----rpt_BangCongHangThang_BV_12052022_nam