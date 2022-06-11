
alter proc dr_BCCongChiTietThang
      @Condition varchar(max) = " and (MonthYear = ''2021/09/01'') "
    --@Condition varchar(max) = N' and (MonthYear = ''2021/09/01'') and (Cos.OrderNumber is not null) '
    , @Username varchar(100) = 'khang.nguyen'
    , @PageIndex int = 1
    , @PageSize int = 20
AS
      begin
            set nocount on;
            declare @Query varchar(max);
            declare @Top varchar(20) = ' ';
            declare @CurrentEnd bigint;
            declare @Offset tinyint;

-- Tach dieu kien
            declare @TempID varchar(max);
            declare @TempCondition varchar(max);
            declare @MonthYearCondition varchar(max);
            declare @MonthYear varchar(20) = '';
            set @TempCondition = replace(@Condition, ',', '@');
            set @TempCondition = replace(@TempCondition, 'and (', ',');
            declare @Count int = 1;
            declare @ListCol varchar(max);
            declare @ListAlilas varchar(max);
            declare @ListShiftCode varchar(max);
            declare @ListOverTimeType varchar(max);
            declare @ListLeaveDayCode varchar(max);
            declare @ListNoPaidLeaveDayCode varchar(max);
            declare @ListPaidLeaveDayCode varchar(max);
            declare @ListBusinessTravelCode varchar(max);
			
			DECLARE @str nvarchar(max)
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
			DECLARE @tempCodition nvarchar(Max)
			DECLARE @NotHaveData NVARCHAR(500) =' '
			DECLARE @IstHaveData NVARCHAR(500) =' '
			DECLARE @CheckData NVARCHAR(500) =' '
			DECLARE @EmStatus NVARCHAR(500) = ' '
			DECLARE @GradeAttendance NVARCHAR(max) = '' 
			DECLARE @TotalPaidDays NVARCHAR(max) = '' 

			WHILE @row > 0
			BEGIN
			set @index = 0
			set @ID = (select top 1 ID from #tableTempCondition)
			set @tempID = replace(@ID,'@',',')
		

			set @index = charindex('(ProfileName ','('+@tempID,0) 
			if(@index > 0)
			begin
     			SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
			END

			set @index = charindex('CheckData ',@tempID,0)
			if(@index > 0)
			BEGIN
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @CheckData = REPLACE(@tempCodition,'CheckData','')
				set @CheckData = REPLACE(@CheckData,'like N','')
				set @CheckData = REPLACE(@CheckData,'%','')
			END

			set @index = charindex('(EmpStatus ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @EmStatus = REPLACE(@tempCodition,'(EmpStatus IN ','')
				set @EmStatus = REPLACE(@EmStatus,',',' OR ')
				set @EmStatus = REPLACE(@EmStatus,'))',')')
			END

			set @index = charindex('(GradeAttendanceID ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @GradeAttendance = @tempCodition

			END

			set @index = charindex('(TotalPaidDays ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @TotalPaidDays = @tempCodition
			END

			DELETE #tableTempCondition WHERE ID = @ID
			set @row = @row - 1

			END

			SET @TempID =''


            if ltrim(rtrim(@Condition)) = ''
               or @Condition is null
               begin
                     set @Top = ' top 0 ';
                     set @MonthYear = dateadd(day, -day(getdate()) + 1, convert(date, getdate()));
               end;

            select  id
            into    #SplitCondition
            from    SPLIT_To_VARCHAR(@TempCondition);

            while (select   count(*)
                   from     #SplitCondition
                  ) > 0
                  begin
                        set @TempID = (select top 1
                                                id
                                       from     #SplitCondition
                                      );
-- Dieu kien @MonthYearCondition
                        if (select  patindex('%MonthYear%', @TempID)
                           ) > 0
                           begin
                                 set @TempCondition = ltrim(rtrim(@TempID));
                                 set @MonthYearCondition = replace(@TempCondition, '', '');
                                 set @MonthYearCondition = ('and (' + replace(@MonthYearCondition, '@', ','));
                                 set @MonthYear = substring(@MonthYearCondition, patindex('%[0-9]%', @MonthYearCondition), 10);
                                 set @Condition = replace(@Condition, @MonthYearCondition, '');
                           end;
                        delete  #SplitCondition
                        where   id = @TempID;
                  end;
            drop table #SplitCondition;


            select  @ListShiftCode = coalesce(@ListShiftCode + ',', '') + quotename(Code)
            from    Cat_Shift
            where   IsDelete is null;

            select  @ListOverTimeType = coalesce(@ListOverTimeType + ',', '') + quotename(Code)
            from    Cat_OvertimeType
            where   IsDelete is null;

            select  @ListLeaveDayCode = coalesce(@ListLeaveDayCode + ',', '') + quotename(Code)
            from    Cat_LeaveDayType
            where   IsDelete is null;

            select  @ListPaidLeaveDayCode = coalesce(@ListPaidLeaveDayCode + ',', '') + quotename(Code)
            from    Cat_LeaveDayType
            where   IsDelete is null
                    and PaidRate = 1
                    and Code not in ('HLD');

            select  @ListNoPaidLeaveDayCode = coalesce(@ListNoPaidLeaveDayCode + ',', '') + quotename(Code)
            from    Cat_LeaveDayType
            where   IsDelete is null
                    and (
                         PaidRate = 0
           or PaidRate is null
                        )
                    and Code not in ('DL');

            select  @ListBusinessTravelCode = coalesce(@ListBusinessTravelCode + ',', '') + quotename(BusinessTravelCode)
            from    Cat_BusinessTravel
            where   IsDelete is null;

            declare @DateStart date = (select top 1
                                                DateStart
                                       from     Att_CutOffDuration
                                       where    IsDelete is null
                                                and MonthYear = @MonthYear
                                      );
            declare @DateEnd date = (select top 1
                                            DateEnd
                                     from   Att_CutOffDuration
                                     where  IsDelete is null
                                            and MonthYear = @MonthYear
                                    );
            declare @FirstDay date = @DateStart;
            while @FirstDay <= @DateEnd
                  begin
                        set @ListCol = coalesce(@ListCol + ',', '') + quotename(@FirstDay);
                        set @ListAlilas = coalesce(@ListAlilas + ',', '') + quotename(@FirstDay) + ' as Data' + convert(varchar(10), @Count);
                        set @FirstDay = dateadd(day, 1, @FirstDay);
                        set @Count += 1;
                  end;

            --select  @ListShiftCode as ListShiftCode
            --      , @ListOverTimeType as ListOverTimeType
            --      , @ListLeaveDayCode as ListLeaveDayCode
            --      , @ListPaidLeaveDayCode as ListPaidLeaveDayCode
            --      , @ListNoPaidLeaveDayCode as ListNoPaidLeaveDayCode
            --      , @ListBusinessTravelCode as ListBusinessTravelCode
            --      , @ListCol as ListCol
            --      , @ListAlilas as ListAlilas
            --      , @MonthYear as MonthYear
            --      , @DateStart as DateStart
            --      , @DateEnd as DateEnd;
            --return;

--IF CHARINDEX('NotHaveData=1',REPLACE(@NotHaveData,' ',''),0) > 0
--BEGIN
--SET @CheckData += ' AND Agr.ProfileID IS NULL '
--END
--IF CHARINDEX('IsHaveData=1',REPLACE(@IstHaveData,' ',''),0) > 0
--BEGIN
--IF LEN(@CheckData) > 2
--BEGIN
--SET @CheckData += ' OR Agr.ProfileID IS NOT NULL '
--END
--ELSE
--SET @CheckData += ' AND Agr.ProfileID IS NOT NULL '
--ENd

IF(@CheckData is not null and @CheckData != '')
BEGIN
	SET @index = charindex('E_POSTS',@CheckData,0) 
	if(@index > 0)
	BEGIN
	SET @CheckData = REPLACE(@CheckData,'''E_POSTS''',' AgrProfileID IS NOT NULL ')
	END
	set @index = charindex('E_UNEXPECTED',@CheckData,0) 
	if(@index > 0)
	BEGIN
	set @CheckData = REPLACE(@CheckData,'''E_UNEXPECTED''',' AgrProfileID IS NULL ')
	END
END

---DK trang thai nhan vien
IF (@EmStatus is not null and @EmStatus != '')
BEGIN
	SET @index = charindex('E_PROFILE_NEW',@EmStatus,0) 
	IF(@index > 0)
	BEGIN
	SET @EmStatus = REPLACE(@EmStatus,'''E_PROFILE_NEW''',' (hp.DateHire <= @DateEnd AND hp.DateHire > @DateStart ) ')
	END
	SET @index = charindex('E_PROFILE_ACTIVE',@EmStatus,0) 
	IF(@index > 0)
	BEGIN
	SET @EmStatus = REPLACE(@EmStatus,'''E_PROFILE_ACTIVE''','(hp.DateQuit IS NULL OR hp.DateQuit >= @DateEnd)')
	END
	SET @index = charindex('E_PROFILE_QUIT',@EmStatus,0)
	IF(@index > 0)
	BEGIN
	SET @EmStatus = REPLACE(@EmStatus,'''E_PROFILE_QUIT''',' (hp.DateQuit <= @DateEnd AND hp.DateQuit >= @DateStart) ')	
	END
END
IF(@TotalPaidDays is not null and @TotalPaidDays != '')
BEGIN
SELECT @TotalPaidDays = ' AND ProfileID IN ( SELECT ProfileID From Results WHERE 1 = 1 ' + @TotalPaidDays + ')'
END

IF(@GradeAttendance is not null and @GradeAttendance != '')
BEGIN
SELECT @GradeAttendance = ' AND ProfileID IN ( SELECT ProfileID From Results WHERE 1 = 1 ' + @GradeAttendance + ')'
END

--SELECT @Condition, @CheckData
-- Query chinh
            set @Query = '	
declare @MonthYear datetime = ''' + @MonthYear + '''
declare @DateStart date = ''' + convert(varchar(20), @DateStart, 111) + ''';
declare @DateEnd date = ''' + convert(varchar(20), @DateEnd, 111) + ''';


-- Ham phan quyen
if object_id(''tempdb..#TbPermission'') is not null
   drop table #TbPermission;
create table #TbPermission(ProfileID uniqueidentifier);
insert  into #TbPermission(ProfileID)
exec Get_Data_Permission_New @UserName = ''' + @Username + ''', @ObjName = ''Hre_Profile'';
print (''#TbPermission'');

-- Lay du lieu qtct moi nhat trong thang
if object_id(''tempdb..#TbWorkHistory'') is not null 
	drop table #TbWorkHistory;
select  Data.ID
      , Data.ProfileID
      , hp.CodeEmp
      , hp.ProfileName
      , cjt.JobTitleName
      , csc.SalaryClassName
      , cou.E_COMPANY
      , cou.E_BRANCH
      , cou.E_UNIT
      , cou.E_DIVISION
      , cou.E_DEPARTMENT
      , cou.E_TEAM
      , cou.E_SECTION
	  , @MonthYear as "MonthYear"
	  --,dbo.fnc_NumberOfExceptWeekends(@DateStart,data.DateHire) as DaysBeforeHire, dbo.fnc_NumberOfExceptWeekends(data.DateQuit,@DateEnd) DaysAfterQuit
	  ,ag.GradeAttendanceID 
into    #TbWorkHistory
from    (select ' + @Top + N'
				hwh.ID
              , hwh.ProfileID
              , hwh.OrganizationStructureID
              , hwh.JobTitleID
              , hwh.PositionID
              , hwh.DateEffective
              , hwh.SalaryClassID
			  , hp.DateHire
			  , hp.DateQuit		
              , row_number() over (partition by hwh.ProfileID order by hwh.DateEffective desc) as RN
         from   Hre_WorkHistory as hwh
                left join Cat_OrgUnit as cou on cou.OrgstructureID = hwh.OrganizationStructureID
                left join Cat_OrgStructure as cos on cos.ID = hwh.OrganizationStructureID  and cos.IsDelete is null
				left join hre_profile hp on hp.Id = hwh.ProfileID
         where  hwh.IsDelete is null
				and hp.isdelete IS NULL
				and hwh.Status = ''E_APPROVED''
                and hwh.DateEffective <= @DateEnd
                and not exists ( select hsw.ID
                                 from   Hre_StopWorking as hsw
                                 where  hsw.IsDelete is null
										and hsw.Status = ''E_APPROVED''
                                        and hsw.DateStop <= @DateStart
                                        and hsw.ProfileID = hwh.ProfileID )
                and exists ( select ProfileID
                             from   #TbPermission as p
                             where  p.ProfileID = hwh.ProfileID )
				' + @Condition + '
				'+ISNULL(@EmStatus,'')+'
        ) as Data
        left join Cat_JobTitle as cjt on cjt.ID = Data.JobTitleID and cjt.IsDelete is null
        left join Cat_SalaryClass as csc on csc.ID = Data.SalaryClassID and csc.IsDelete is null
        left join Hre_Profile as hp on hp.ID = Data.ProfileID and hp.IsDelete is null
        left join Cat_OrgUnit as cou on cou.OrgstructureID = Data.OrganizationStructureID
		OUTER APPLY
		(SELECT TOP(1) ag.GradeAttendanceID 
		FROM	dbo.Att_Grade ag
		WHERE	ag.ProfileID = data.ProfileID
				AND ag.MonthStart <= @DateEnd AND ( ag.MonthEnd IS NULL OR ag.MonthEnd >= @DateStart)
		ORDER BY ag.DateUpdate DESC
		) ag

where   Data.RN = 1;
print (''#TbWorkHistory'');

-- Lay du lieu bang tong hop cong
if object_id(''tempdb..#TbWorkday '') is not null 
	drop table #TbWorkday;
select ' + @Top
                + '
		aw.ID
      , aw.ProfileID
      , aw.WorkDate
      , cs.ShiftCode
      , case when aw.Type = ''E_NORMAL'' and cs.ShiftCode is not null then 1.0 - isnull(LEAVEDETAIL.LeaveDays1, 0) 
        end as WorkHours
      , case when LD.FullShift is not null then coalesce(LEAVEDETAIL.LeaveCode1, LEAVEDETAIL.LeaveCode2)
             when LD.FirstShift is not null
                  and LD.LastShift is null
             then concat(coalesce(LEAVEDETAIL.LeaveDays1, LEAVEDETAIL.LeaveDays2), coalesce(LEAVEDETAIL.LeaveCode1, LEAVEDETAIL.LeaveCode2), ''|'', cs.ShiftCode)
             when LD.FirstShift is null
                  and LD.LastShift is not null
             then concat(coalesce(LEAVEDETAIL.LeaveDays1, LEAVEDETAIL.LeaveDays2), coalesce(LEAVEDETAIL.LeaveCode1, LEAVEDETAIL.LeaveCode2), ''|'', cs.ShiftCode)
             when LD.FirstShift is not null
                  and LD.LastShift is not null
             then concat(LEAVEDETAIL.LeaveDays1 + LEAVEDETAIL.LeaveCode1, ''|'', LEAVEDETAIL.LeaveDays2 + LEAVEDETAIL.LeaveCode2)
             else cs.ShiftCode
        end as Symbol
      , case when cs.ShiftCode = ''2'' then case when LD.FullShift is null
                                                    and aw.Type = ''E_NORMAL'' then 2.5
                                               when LD.FirstShift is null
                                                    and aw.Type = ''E_NORMAL'' then 2.5
                                          end
             when cs.ShiftCode = ''3'' then case when LD.FullShift is null
                                                    and aw.Type = ''E_NORMAL'' then 7.5
                                               when LD.FirstShift is not null
                                                    and LD.LastShift is null
                                                    and aw.Type = ''E_NORMAL'' then 3.5
                                               when LD.FirstShift is null
                                                    and LD.LastShift is not null
                                                    and aw.Type = ''E_NORMAL'' then 4
                                          end
        end as NightShiftHours
	  ,LEAVEDETAIL.DurationType1,LEAVEDETAIL.DurationType2,LEAVEDETAIL.DurationType3
	  ,LEAVEDETAIL.LeaveCode1,LEAVEDETAIL.LeaveCode2,LEAVEDETAIL.LeaveCode3
      --,ISNULL(CONVERT(DECIMAL(12,2),LEAVEDETAIL.LeaveDays1),0) - ISNULL(CONVERT(DECIMAL(12,2),LEAVEDETAIL.LeaveDays3),0) - ISNULL(CONVERT(DECIMAL(12,2),LEAVEDETAIL.LeaveDays2),0) AS LeaveDays1
	  , 1.0 - 1.0 + isnull(LEAVEDETAIL.LeaveDays1, 0) - isnull(LEAVEDETAIL.LeaveDays2, 0) - isnull(LEAVEDETAIL.LeaveDays3, 0)  AS LeaveDays1 
	  ,LEAVEDETAIL.LeaveDays2
	  ,LEAVEDETAIL.LeaveDays3
	  ,LD.*
	  , aw.Status as WorkDayStatus
	  ,ShiftID
into    #TbWorkday
from    Att_Workday as aw
        left join (select   ID
                          , Code as ShiftCode
                          , LeaveHoursFullShift
                          , LeaveHoursLastHalfShift
                          , LeaveHoursFirstHalfShift
                   from     Cat_Shift
                   where    IsDelete is null
                  ) as cs on cs.ID = aw.ShiftID and aw.Status = ''E_CONFIRMED''

        outer apply (select ald.ID
						  , ald.ProfileID
                          , cldt.LeaveDayTypeCode
                          , ald.DurationType
                          , ald.LeaveDays
                          , ald.LeaveHours
                          , cldt.PaidRate
                     from   Att_LeaveDay as ald
                            left join (select   ID
                                              , Code as LeaveDayTypeCode
                                              , PaidRate
                                       from     Cat_LeaveDayType
                                       where    IsDelete is null
                                      ) as cldt on cldt.ID = ald.LeaveDayTypeID
                     where  ald.IsDelete is null
                            and ald.ID = aw.LeaveDayID1
                            and ald.Status = ''E_APPROVED''
                    ) as ld1
        outer apply (select ald.ID
                          , ald.ProfileID
                          , cldt.LeaveDayTypeCode
                          , ald.DurationType
                          , ald.LeaveDays
                          , ald.LeaveHours
                          , cldt.PaidRate
                     from   Att_LeaveDay as ald
                            left join (select   ID
                                              , Code as LeaveDayTypeCode
                                              , PaidRate
                                       from     Cat_LeaveDayType
                                       where    IsDelete is null
                                      ) as cldt on cldt.ID = ald.LeaveDayTypeID
                     where  ald.IsDelete is null
                            and ald.ID = aw.ExtraLeaveDayID
                            and ald.Status = ''E_APPROVED''
                    ) as lde
        outer apply (select abt.ID
                          , abt.ProfileID
                          , abt.DurationType
                          , cbt.BusinessTravelCode
                     from   Att_BussinessTravel as abt
                            left join (select   ID
                                              , BusinessTravelCode
                                       from     Cat_BusinessTravel
                                       where    IsDelete is null
                                      ) as cbt on cbt.ID = abt.BusinessTripTypeID
                     where  abt.IsDelete is null
                            and abt.Status = ''E_APPROVED''
                            and abt.ID = aw.BusinessTravelTypeID1
                    ) as tbt1
        outer apply (select abt.ID
                          , abt.ProfileID
                          , abt.DurationType
                          , cbt.BusinessTravelCode
                     from   Att_BussinessTravel as abt
                            left join (select   ID
                                              , BusinessTravelCode
                                       from     Cat_BusinessTravel
                                       where    IsDelete is null
                                      ) as cbt on cbt.ID = abt.BusinessTripTypeID
                     where  abt.IsDelete is null
                            and abt.Status = ''E_APPROVED''
                            and abt.ID = aw.BusinessTravelTypeID2
                    ) as tbt2
        left join (select   ID
                          , DateOff
                          , ''HLD'' as DayOffCode
                          , ''E_FULLSHIFT'' as DayOffDurationType
                          , 1 as DayOffPaidRate
                          , 1 as DayOffLeaveDays
                   from     Cat_DayOff
                   where    IsDelete is null
                            and Type = ''E_HOLIDAY''
                  ) as cdo on cdo.DateOff = aw.WorkDate
        cross apply (select case when cdo.DateOff is not null then ''E_FULLSHIFT-1.0-HLD''
      end as DayOff
                          , case when ld1.DurationType = ''E_FULLSHIFT'' OR tbt1.DurationType = ''E_FULLSHIFT''
                                 then case when ld1.DurationType = ''E_FULLSHIFT''
                                           then concat(ld1.DurationType, ''-'', ld1.LeaveDays, ''.0'', ''-'', ld1.LeaveDayTypeCode)
                                           when tbt1.DurationType = ''E_FULLSHIFT'' then concat(tbt1.DurationType, ''-'', ''1.0'', ''-'', tbt1.BusinessTravelCode)
                                      end
                            end as FullShift
                          , case when ld1.DurationType = ''E_FIRSTHALFSHIFT'' or lde.DurationType = ''E_FIRSTHALFSHIFT'' or tbt1.DurationType = ''E_FIRSTHALFSHIFT'' or tbt2.DurationType = ''E_FIRSTHALFSHIFT''
                                 then case when ld1.DurationType = ''E_FIRSTHALFSHIFT''
                                           then concat(ld1.DurationType, ''-'', ld1.LeaveDays, ''-'', ld1.LeaveDayTypeCode)
                                           when lde.DurationType = ''E_FIRSTHALFSHIFT''
                                           then concat(lde.DurationType, ''-'', lde.LeaveDays, ''-'', lde.LeaveDayTypeCode)
                                           when tbt1.DurationType = ''E_FIRSTHALFSHIFT'' AND ld1.DurationType <> ''E_FIRSTHALFSHIFT'' AND ld1.DurationType <> ''E_FULLSHIFT''  AND lde.DurationType <> ''E_FIRSTHALFSHIFT''
										   then concat(tbt1.DurationType, ''-'', ''0.5'', ''-'', tbt1.BusinessTravelCode)
                                           when tbt2.DurationType = ''E_FIRSTHALFSHIFT'' AND ld1.DurationType <> ''E_FIRSTHALFSHIFT'' AND ld1.DurationType <> ''E_FULLSHIFT''   AND lde.DurationType <> ''E_FIRSTHALFSHIFT''
										   then concat(tbt2.DurationType, ''-'', ''0.5'', ''-'', tbt2.BusinessTravelCode)
                                      end
                            end as FirstShift
                          , case when ld1.DurationType = ''E_LASTHALFSHIFT'' or lde.DurationType = ''E_LASTHALFSHIFT'' or tbt1.DurationType = ''E_LASTHALFSHIFT'' or tbt2.DurationType = ''E_LASTHALFSHIFT''
                                 then case when ld1.DurationType = ''E_LASTHALFSHIFT''
                                           then concat(ld1.DurationType, ''-'', ld1.LeaveDays, ''-'', ld1.LeaveDayTypeCode)
                                           when lde.DurationType = ''E_LASTHALFSHIFT''
                                           then concat(lde.DurationType, ''-'', lde.LeaveDays, ''-'', lde.LeaveDayTypeCode)
                                           when tbt1.DurationType = ''E_LASTHALFSHIFT'' AND ld1.DurationType <> ''E_LASTHALFSHIFT'' AND ld1.DurationType <> ''E_FULLSHIFT''  AND lde.DurationType <> ''E_LASTHALFSHIFT''
										   then concat(tbt1.DurationType, ''-'', ''0.5'', ''-'', tbt1.BusinessTravelCode)
                                           when tbt2.DurationType = ''E_LASTHALFSHIFT'' AND ld1.DurationType <> ''E_LASTHALFSHIFT'' AND ld1.DurationType <> ''E_FULLSHIFT''  AND lde.DurationType <> ''E_LASTHALFSHIFT''
										   then concat(tbt2.DurationType, ''-'', ''0.5'', ''-'', tbt2.BusinessTravelCode)
                                      end
                            end as LastShift
                    ) as LD
        cross apply (select case when LD.DayOff is not null then LD.DayOff
                                 when LD.FullShift is not null then LD.FullShift
                            end as StringLeaveCode1
                          , LD.FirstShift as StringLeaveCode2
						  ,  LD.LastShift as StringLeaveCode3
                    ) LEAVE
        cross apply (select left(LEAVE.StringLeaveCode1, charindex(''-'', LEAVE.StringLeaveCode1) - 1) as DurationType1
                          , left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode2) - 1) as DurationType2
						   , left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode3) - 1) as DurationType3
                          , right(LEAVE.StringLeaveCode1, charindex(''-'', reverse(LEAVE.StringLeaveCode1)) - 1) as LeaveCode1
                          , right(LEAVE.StringLeaveCode2, charindex(''-'', reverse(LEAVE.StringLeaveCode2)) - 1) as LeaveCode2
						    , right(LEAVE.StringLeaveCode3, charindex(''-'', reverse(LEAVE.StringLeaveCode3)) - 1) as LeaveCode3

                          , case when left(LEAVE.StringLeaveCode1, charindex(''-'', LEAVE.StringLeaveCode1) - 1) = ''E_FULLSHIFT'' then ''1.0''
							end as LeaveDays1
                          , case
								 when left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode2) - 1) = ''E_FIRSTHALFSHIFT'' then ''0.5'' 
							end as LeaveDays2
						 , case
								 when 
									  left(LEAVE.StringLeaveCode3, charindex(''-'', LEAVE.StringLeaveCode3) - 1) = ''E_LASTHALFSHIFT'' then ''0.5''
							end as LeaveDays3
                    ) LEAVEDETAIL
where   aw.IsDelete is null
        and aw.WorkDate between @DateStart and @DateEnd
        and exists ( select *
                     from   #TbWorkHistory as twh
                     where  twh.ProfileID = aw.ProfileID );
print (''#TbWorkday'');

-- Lau du lieu OT
if object_id(''tempdb..#TbOvertime'') is not null
   drop table #TbOvertime;
select  ' + @Top + '
		ao.ID
      , ao.ProfileID
      , ao.WorkDateRoot
      , cot.OvertimeTypeCode
      , ao.ConfirmHours
into    #TbOvertime
from    Att_Overtime as ao
        left join (select   ID
                          , Code as OvertimeTypeCode
                   from     Cat_OvertimeType
                   where    IsDelete is null
                  ) as cot on cot.ID = ao.OvertimeTypeID
where   ao.IsDelete is null
        and ao.Status = ''E_CONFIRM''
        and ao.WorkDateRoot between @DateStart and @DateEnd
        and exists ( select *
                     from   #TbWorkHistory as twh
                     where  twh.ProfileID = ao.ProfileID );
print (''#TbOvertime'');

-- Pivot du lieu chi tiet
if object_id(''tempdb..#TbDetail'') is not null
   drop table #TbDetail;
select  *
into    #TbDetail
from    (select pv.ProfileID AS ProfileID_td
              , 1 as OrderNumber
			  , (datediff(dd, @DateStart, @DateEnd) + 1) - (datediff(wk, @DateStart, @DateEnd) * 2) - (case when datename(dw, @DateStart) = ''Sunday'' then 1
																											else 0
																									   end) - (case when datename(dw, @DateEnd) = ''Saturday'' then 1
																													else 0
																											   end) as "STDWorkingDays"
              , ' + @ListAlilas + '
         from   (select wh.ProfileID
                      , tw.WorkDate
                      , tw.Symbol
                 from (select distinct ProfileID from #TbWorkHistory) as wh
				 left join #TbWorkday as tw on tw.ProfileID = wh.ProfileID
                 where  1 = 1
                ) as data pivot ( max(Symbol) for WorkDate in (' + @ListCol + ') ) as pv
         union all
         select pv.ProfileID
              , 2 as OrderNumber
			  , null as "STDWorkingDays"
              , ' + @ListAlilas + '
         from   (select wh.ProfileID
                      , tov.WorkDateRoot
                      , convert(varchar(10), tov.ConfirmHours) as ConfirmHours
                 from   (select distinct ProfileID from #TbWorkHistory) as wh
                        left join #TbOvertime as tov on tov.ProfileID = wh.ProfileID
                 where  1 = 1
                ) as data pivot ( max(ConfirmHours) for WorkDateRoot in (' + @ListCol + ') ) as pv
        ) as D
print (''#TbDetail'');

-- Sum du lieu ngay cong
if object_id(''tempdb..#TbSumShift'') is not null
   drop table #TbSumShift;
select  *
into    #TbSumShift
from    (select tw.ProfileID AS ProfileID_tss
              , tw.ShiftCode
              , tw.WorkHours
         from   #TbWorkday as tw
         where  1 = 1
        ) as Data pivot ( sum(WorkHours) for ShiftCode in (' + @ListShiftCode + ') ) as pv;
print (''#TbSumShift'');

-- Sum du lieu cong tac
if object_id(''tempdb..#TbSumBusinessLeave'') is not null
   drop table #TbSumBusinessLeave;
select *
		, ' + replace(replace(replace(@ListBusinessTravelCode, ',', '+'), '[', 'isnull(['), ']', '],0)')
                + ' 			
----Update - WFH			
				- isnull([WFH],0) as TotalBusinessTravelDays
into    #TbSumBusinessLeave
from    (select tw.ProfileID AS ProfileID_tsbl
              , LD.*
         from   #TbWorkday as tw
                cross apply ( values ( tw.LeaveCode1, convert(float, tw.LeaveDays1)), ( tw.LeaveCode2, convert(float, tw.LeaveDays2)) , ( tw.LeaveCode3, convert(float, tw.LeaveDays3)) ) as LD (LeaveCode, LeaveDays)
         where  LD.LeaveCode in (' + replace(replace(@ListBusinessTravelCode, '[', ''''), ']', '''') + ')
        ) as Data pivot ( sum(LeaveDays) for LeaveCode in (' + @ListBusinessTravelCode + ') ) as pv;
print (''#TbSumBusinessLeave'');

-- Sum du lieu ngay nghi
if object_id(''tempdb..#TbSumLeaveDay'') is not null
   drop table #TbSumLeaveDay;
select  *
		, ' + replace(replace(replace(@ListPaidLeaveDayCode, ',', '+'), '[', 'isnull(['), ']', '],0)') + ' as TotalPaidLeaveDay
		, ' + replace(replace(replace(@ListNoPaidLeaveDayCode, ',', '+'), '[', 'isnull(['), ']', '],0)')
                + ' as TotalNoPaidLeaveDay
into    #TbSumLeaveDay
from    (select tw.ProfileID AS ProfileID_tsld
              , LD.*
         from   #TbWorkday as tw
                cross apply ( values ( tw.LeaveCode1, convert(float, tw.LeaveDays1)), ( tw.LeaveCode2, convert(float, tw.LeaveDays2))  , ( tw.LeaveCode3, convert(float, tw.LeaveDays3)) ) as LD (LeaveCode, LeaveDays)
         where  LD.LeaveCode in (' + replace(replace(@ListLeaveDayCode, '[', ''''), ']', '''') + ')
        ) as Data pivot ( sum(LeaveDays) for LeaveCode in (' + @ListLeaveDayCode + ') ) as pv;
print (''#TbSumLeaveDay'');


-- Sum du lieu tang ca
if object_id(''tempdb..#TbSumOT'') is not null
   drop table #TbSumOT;
select  ProfileID AS ProfileID_tso
      , nullif(isnull(E_WORKDAY, 0) + isnull(E_WORKDAY_NIGHTSHIFT, 0),0) as OT1
      , nullif(isnull(E_WEEKEND, 0) + isnull(E_WEEKEND_NIGHTSHIFT, 0),0) as OT2
      , nullif(isnull(E_HOLIDAY, 0) + isnull(E_HOLIDAY_NIGHTSHIFT, 0),0) as OT2H
      , nullif(isnull(E_HOLIDAY, 0) + isnull(E_WEEKEND_NIGHTSHIFT, 0) + isnull(E_WORKDAY_NIGHTSHIFT, 0) + isnull(E_WORKDAY, 0) + isnull(E_HOLIDAY_NIGHTSHIFT, 0)
        + isnull(E_WEEKEND, 0),0) as TotalOT
	  , E_WORKDAY_NIGHTSHIFT as NS2
	  , E_WEEKEND_NIGHTSHIFT as NS3
	  , E_HOLIDAY_NIGHTSHIFT as NS4
into    #TbSumOT
from    (select tov.ProfileID
              , tov.OvertimeTypeCode
              , tov.ConfirmHours
         from   #TbOvertime as tov
         where  1 = 1
        ) as Data pivot ( sum(ConfirmHours) for OvertimeTypeCode in (' + @ListOverTimeType + ') ) as pv;

print (''#TbSumOT'');

-- Sum gio lam ca dem, ngay lam viec
if object_id(''tempdb..#TbSumWorkDay'') is not null
   drop table #TbSumWorkDay;
select  tw.ProfileID AS ProfileID_tswd
      , sum(tw.NightShiftHours) as NS1
      , sum(tw.WorkHours) as TotalWorkHours
	  , count(tw.ID) as TotalWD
	  , sum(case when tw.WorkDayStatus = ''E_CONFIRMED'' then 1 end) as TotalWDConfirmed
	  , sum(case when tw.WorkDayStatus = ''E_WAIT_CONFIRMED'' then 1 end) as TotalWDWaitConfirmed
	  , sum(case when tw.WorkDayStatus is null then 1 end) as TotalWDNull
into    #TbSumWorkDay
from    #TbWorkday as tw
group by tw.ProfileID;
print (''#TbSumWorkDay'');

---Count ngay co ca lam viec
if object_id(''tempdb..#TbCountHaveShift'') is not null
   drop table #TbCountHaveShift;

Select	tw.ProfileID,Count(ShiftID) AS CountHaveShift
into    #TbCountHaveShift
from    #TbWorkday as tw
WHERE	ShiftID IS NOT NULL
and tw.WorkDayStatus = ''E_CONFIRMED''
group by tw.ProfileID;
print (''#TbCountHaveShift'');

--select * from #TbWorkday where profileid =''F63270C3-8A29-47C3-A88B-71738B3E9320'' order by workdate

-- Bang ket qua tong
;WITH Results AS
(
select  NULL AS STT
		,twh.*
		, td.*
		, tss.*
		, tsbl.*
		, tsld.*
		, isnull(tsld.TotalPaidLeaveDay,0) + isnull(tsld.HLD,0) + isnull(tsbl.TotalBusinessTravelDays,0) + isnull(tswd.TotalWorkHours,0) + isnull([WFH],0) as TotalPaidDays
		,  isnull(tswd.TotalWorkHours,0) - isnull(tsbl.TotalBusinessTravelDays,0) AS RealWorkDayCount
		, ISNULL(tswd.TotalWD,0) - ISNULL(tchs.CountHaveShift,0) AS TotalLeaveDayWeekly
		, tso.*
		, tswd.*
		, nullif(isnull(tswd.NS1,0) + ISNULL(tso.NS2,0) + ISNULL(tso.NS3,0) + ISNULL(tso.NS4,0) ,0) as TotalNS
		,@DateStart AS DateStart
	  	,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "hwh.EmploymentType",NULL AS "hwh.SalaryClassID" ,NULL AS "hwh.PositionID", NULL AS "hwh.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "hwh.WorkPlaceID"
		,NULL AS "hwh.EmployeeGroupID", NULL AS "hwh.LaborType"
		,NULL AS "EmpStatus",NULL AS "CheckData"
		,Agr.ProfileID AS AgrProfileID
		,row_number() over (order by E_COMPANY, E_BRANCH, E_UNIT,E_DIVISION, E_DEPARTMENT, E_TEAM, E_SECTION, ProfileName,td.OrderNumber ) as RowNumber
		
from    #TbWorkHistory as twh
		left join #TbDetail as td on td.ProfileID_td = twh.ProfileID
        left join #TbSumShift as tss on tss.ProfileID_tss = twh.ProfileID and td.OrderNumber = 1
        left join #TbSumBusinessLeave as tsbl on tsbl.ProfileID_tsbl = twh.ProfileID and td.OrderNumber = 1
        left join #TbSumLeaveDay as tsld on tsld.ProfileID_tsld = twh.ProfileID and td.OrderNumber = 1
        left join #TbSumOT as tso on tso.ProfileID_tso = twh.ProfileID and td.OrderNumber = 2
        left join #TbSumWorkDay as tswd on tswd.ProfileID_tswd = twh.ProfileID and td.OrderNumber = 1
		left join #TbCountHaveShift as tchs on tchs.ProfileID = twh.ProfileID and td.OrderNumber = 1
		OUTER APPLY ( SELECT TOP (1) agr.ProfileID FROM att_grade agr where agr.ProfileID = twh.ProfileID AND agr.MonthStart < @DateEnd AND agr.isdelete IS null ORDER BY agr.MonthStart DESC ) Agr

)
select * 
INTO	#Results
from	Results
where	1 = 1 '+@TotalPaidDays+' '+@GradeAttendance+' '+@CheckData+' 
--and codeemp =''20090514001''
Select	RowNumber, row_number() over (order by E_COMPANY, E_BRANCH, E_UNIT,E_DIVISION, E_DEPARTMENT, E_TEAM, E_SECTION, ProfileName) as STT
INTO	#TempSTT
from	#Results
where	OrderNumber = 1


UPDATE		r
SET			r.STT = temp.STT
FROM		#Results r
INNER JOIN	#TempSTT temp 
	ON		r.RowNumber = temp.RowNumber

SELECT * FROM #Results
order by RowNumber

drop table #TbDetail, #TbOvertime, #TbPermission, #TbSumBusinessLeave, #TbSumLeaveDay, #TbSumOT, #TbSumShift, #TbSumWorkDay, #TbWorkday, #TbWorkHistory, #TempSTT, #Results;

';
			
            exec (@Query);
            select  @ListShiftCode as ListShiftCode
                  , @ListOverTimeType as ListOverTimeType
                  , @ListLeaveDayCode as ListLeaveDayCode
                  , @ListPaidLeaveDayCode as ListPaidLeaveDayCode
                  , @ListNoPaidLeaveDayCode as ListNoPaidLeaveDayCode
                  , @ListBusinessTravelCode as ListBusinessTravelCode
                  , @ListCol as ListCol
                  , @ListAlilas as ListAlilas
                  , @MonthYear as MonthYear
                  , @DateStart as DateStart
                  , @DateEnd as DateEnd;
            set @Query = replace(replace(@Query, char(13) + char(10), char(10)), char(13), char(10));
            while len(@Query) > 1
                  begin
                        if charindex(char(10), @Query) between 1 and 4000
                           begin
                                 set @CurrentEnd = charindex(char(10), @Query) - 1;
                                 set @Offset = 2;
                           end;
                        else
                           begin
                                 set @CurrentEnd = 4000;
                                 set @Offset = 1;
                           end;   
                        print substring(@Query, 1, @CurrentEnd); 
                        set @Query = substring(@Query, @CurrentEnd + @Offset, len(@Query));   
                  end;
        --dr_BCCongChiTietThang
      end;




