
ALTER proc [dbo].[dr_BCCongChiTietThang_nam]
      @Condition varchar(max) = " and (MonthYear = ''2021/07/01'') "
    --@Condition varchar(max) = N' and (MonthYear = ''2021/04/01'') and (Cos.OrderNumber is not null) '
    , @Username varchar(100) = 'khang.nguyen'
    , @PageIndex int = 1
    , @PageSize int = 20
as
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
        
            if ltrim(rtrim(@Condition)) = ''
               or @Condition is null
               begin
                     set @Top = ' top 0 ';
                     set @MonthYear = dateadd(day,-day(getdate())+1,convert(date,getdate()));
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
if object_id(''tempdb..#TbWorkHistory'') is not null drop table #TbWorkHistory;
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
into    #TbWorkHistory
from    (select ' + @Top + '
				hwh.ID
              , hwh.ProfileID
              , hwh.OrganizationStructureID
              , hwh.JobTitleID
              , hwh.PositionID
              , hwh.DateEffective
              , hwh.SalaryClassID
              , row_number() over (partition by hwh.ProfileID order by hwh.DateEffective desc) as RN
         from   Hre_WorkHistory as hwh
                left join Cat_OrgUnit as cou on cou.OrgstructureID = hwh.OrganizationStructureID
                left join Cat_OrgStructure as cos on cos.ID = hwh.OrganizationStructureID  and cos.IsDelete is null
         where  hwh.IsDelete is null
                and hwh.Status = ''E_APPROVED''
                and hwh.DateEffective <= @DateEnd
                and exists ( select ProfileID
                             from   #TbPermission as p
                             where  p.ProfileID = hwh.ProfileID )
				' + @Condition + '
        ) as Data
        left join Cat_JobTitle as cjt on cjt.ID = Data.JobTitleID and cjt.IsDelete is null
        left join Cat_SalaryClass as csc on csc.ID = Data.SalaryClassID and csc.IsDelete is null
        left join Hre_Profile as hp on hp.ID = Data.ProfileID and hp.IsDelete is null
        left join Cat_OrgUnit as cou on cou.OrgstructureID = Data.OrganizationStructureID
where   Data.RN = 1;
print (''#TbWorkHistory'');

-- Lay du lieu bang tong hop cong
if object_id(''tempdb..#TbWorkday '') is not null drop table #TbWorkday;
select ' + @Top
                + '
		aw.ID
      , aw.ProfileID
      , aw.WorkDate
      , cs.ShiftCode
      , case when aw.Type = ''E_NORMAL'' and cs.ShiftCode is not null then 1.0 - isnull(LEAVEDETAIL.LeaveDays1, 0) - isnull(LEAVEDETAIL.LeaveDays2, 0)
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
      , LEAVEDETAIL.*
into    #TbWorkday
from    Att_Workday as aw
        left join (select   ID
                          , Code as ShiftCode
                          , LeaveHoursFullShift
                          , LeaveHoursLastHalfShift
                          , LeaveHoursFirstHalfShift
                   from     Cat_Shift
                   where    IsDelete is null
                  ) as cs on cs.ID = aw.ShiftID
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
                          , case when coalesce(ld1.DurationType, tbt1.DurationType) = ''E_FULLSHIFT''
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
                                           when tbt1.DurationType = ''E_FIRSTHALFSHIFT'' then concat(tbt1.DurationType, ''-'', ''0.5'', ''-'', tbt1.BusinessTravelCode)
                                           when tbt2.DurationType = ''E_FIRSTHALFSHIFT'' then concat(tbt2.DurationType, ''-'', ''0.5'', ''-'', tbt2.BusinessTravelCode)
                                      end
                            end as FirstShift
                          , case when ld1.DurationType = ''E_LASTHALFSHIFT'' or lde.DurationType = ''E_LASTHALFSHIFT'' or tbt1.DurationType = ''E_LASTHALFSHIFT'' or tbt2.DurationType = ''E_LASTHALFSHIFT''
                                 then case when ld1.DurationType = ''E_LASTHALFSHIFT''
                                           then concat(ld1.DurationType, ''-'', ld1.LeaveDays, ''-'', ld1.LeaveDayTypeCode)
                                           when lde.DurationType = ''E_LASTHALFSHIFT''
                                           then concat(lde.DurationType, ''-'', lde.LeaveDays, ''-'', lde.LeaveDayTypeCode)
                                           when tbt1.DurationType = ''E_LASTHALFSHIFT'' then concat(tbt1.DurationType, ''-'', ''0.5'', ''-'', tbt1.BusinessTravelCode)
                                           when tbt2.DurationType = ''E_LASTHALFSHIFT'' then concat(tbt2.DurationType, ''-'', ''0.5'', ''-'', tbt2.BusinessTravelCode)
                                      end
                            end as LastShift
                    ) as LD
        cross apply (select case when LD.DayOff is not null then LD.DayOff
                                 when LD.FullShift is not null then LD.FullShift
                                 when LD.FirstShift is not null then LD.FirstShift
                                 when LD.LastShift is not null then LD.LastShift
                            end as StringLeaveCode1
                          , case when LD.DayOff is null
                                      and LD.FullShift is null
                                      and LD.FirstShift is not null then LD.LastShift
                            end as StringLeaveCode2
                    ) LEAVE
        cross apply (select left(LEAVE.StringLeaveCode1, charindex(''-'', LEAVE.StringLeaveCode1) - 1) as DurationType1
                          , left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode2) - 1) as DurationType2
                          , right(LEAVE.StringLeaveCode1, charindex(''-'', reverse(LEAVE.StringLeaveCode1)) - 1) as LeaveCode1
                          , right(LEAVE.StringLeaveCode2, charindex(''-'', reverse(LEAVE.StringLeaveCode2)) - 1) as LeaveCode2
                          , case when left(LEAVE.StringLeaveCode1, charindex(''-'', LEAVE.StringLeaveCode1) - 1) = ''E_FULLSHIFT'' then ''1.0''
								 when left(LEAVE.StringLeaveCode1, charindex(''-'', LEAVE.StringLeaveCode1) - 1) = ''E_FIRSTHALFSHIFT'' 
									  or left(LEAVE.StringLeaveCode1, charindex(''-'', LEAVE.StringLeaveCode1) - 1) = ''E_LASTHALFSHIFT'' then ''0.5''
							end as LeaveDays1
                          , case when left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode2) - 1) = ''E_FULLSHIFT'' then ''1.0'' 
								 when left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode2) - 1) = ''E_FIRSTHALFSHIFT'' 
									  or left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode2) - 1) = ''E_LASTHALFSHIFT'' then ''0.5'' 
							end as LeaveDays2
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
      , (datediff(dd, @DateStart, @DateEnd) + 1) - (datediff(wk, @DateStart, @DateEnd) * 2) - (case when datename(dw, @DateStart) = ''Sunday'' then 1
                                                                                                    else 0
                                                                                               end) - (case when datename(dw, @DateEnd) = ''Saturday'' then 1
                                                                                                            else 0
                                                                                                       end) as "STDWorkingDays"
into    #TbDetail
from    (select pv.ProfileID
              , 1 as OrderNumber
              , ' + @ListAlilas + '
         from   (select tw.ProfileID
                      , tw.WorkDate
                      , tw.Symbol
                 from   #TbWorkday as tw
                 where  1 = 1
                ) as data pivot ( max(Symbol) for WorkDate in (' + @ListCol + ') ) as pv
         union all
         select pv.ProfileID
              , 2 as OrderNumber
              , ' + @ListAlilas + '
         from   (select wd.ProfileID
                      , tov.WorkDateRoot
                      , tov.OvertimeTypeCode
                      , convert(varchar(10), tov.ConfirmHours) as ConfirmHours
                 from   (select distinct
                                ProfileID
                         from   #TbWorkday
                        ) as wd
                        left join #TbOvertime as tov on tov.ProfileID = wd.ProfileID
                 where  1 = 1
                ) as data pivot ( max(ConfirmHours) for WorkDateRoot in (' + @ListCol + ') ) as pv
        ) as D
print (''#TbDetail'');

-- Sum du lieu ngay cong
if object_id(''tempdb..#TbSumShift'') is not null
   drop table #TbSumShift;
select  *
into    #TbSumShift
from    (select tw.ProfileID
              , tw.ShiftCode
              , tw.WorkHours
         from   #TbWorkday as tw
         where  1 = 1
        ) as Data pivot ( sum(WorkHours) for ShiftCode in (' + @ListShiftCode + ') ) as pv;
print (''#TbSumShift'');

-- Sum du lieu cong tac
if object_id(''tempdb..#TbSumBusinessLeave'') is not null
   drop table #TbSumBusinessLeave;
select  *
		, ' + replace(replace(replace(@ListBusinessTravelCode, ',', '+'), '[', 'isnull(['), ']', '],0)')
                + ' as TotalBusinessTravelDays
into    #TbSumBusinessLeave
from    (select tw.ProfileID
              , LD.*
         from   #TbWorkday as tw
                cross apply ( values ( tw.LeaveCode1, convert(float, tw.LeaveDays1)), ( tw.LeaveCode2, convert(float, tw.LeaveDays2)) ) as LD (LeaveCode, LeaveDays)
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
from    (select tw.ProfileID
              , LD.*
         from   #TbWorkday as tw
                cross apply ( values ( tw.LeaveCode1, convert(float, tw.LeaveDays1)), ( tw.LeaveCode2, convert(float, tw.LeaveDays2)) ) as LD (LeaveCode, LeaveDays)
         where  LD.LeaveCode in (' + replace(replace(@ListLeaveDayCode, '[', ''''), ']', '''') + ')
        ) as Data pivot ( sum(LeaveDays) for LeaveCode in (' + @ListLeaveDayCode + ') ) as pv;
print (''#TbSumLeaveDay'');

-- Sum du lieu tang ca
if object_id(''tempdb..#TbSumOT'') is not null
   drop table #TbSumOT;
select  ProfileID
      , isnull(E_WORKDAY, 0) + isnull(E_WORKDAY_NIGHTSHIFT, 0) as OT1
      , isnull(E_WEEKEND, 0) + isnull(pv.E_WEEKEND_NIGHTSHIFT, 0) as OT2
      , isnull(E_HOLIDAY, 0) + isnull(E_HOLIDAY_NIGHTSHIFT, 0) as OT2H
      , isnull(E_HOLIDAY, 0) + isnull(E_WEEKEND_NIGHTSHIFT, 0) + isnull(E_WORKDAY_NIGHTSHIFT, 0) + isnull(E_WORKDAY, 0) + isnull(E_HOLIDAY_NIGHTSHIFT, 0)
        + isnull(E_WEEKEND, 0) as TotalOT
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
select  tw.ProfileID
      , sum(tw.NightShiftHours) as NS1
      , sum(tw.WorkHours) as TotalWorkHours
into    #TbSumWorkDay
from    #TbWorkday as tw
group by tw.ProfileID;
print (''#TbSumWorkDay'');


--select * from #TbDetail

-- Bang ket qua tong

select  twh.*
      , td.*
      , tss.*
      , tsbl.*
      , tsld.*
 	  , isnull(tsld.TotalPaidLeaveDay,0) + isnull(tsld.HLD,0) + isnull(tsbl.TotalBusinessTravelDays,0) + isnull(tswd.TotalWorkHours,0) as TotalPaidDays
      , tso.*
      , tswd.*
      , null as "Cos.OrderNumber"
      , null as "hwh.ProfileID"
      , null as "hwh.SalaryClassID"
      , null as "hwh.JobTitleID"
	  , null as "hwh.PositionID"
      , @MonthYear as "MonthYear"
from    #TbDetail as td
        left join #TbWorkHistory as twh on twh.ProfileID = td.ProfileID and td.OrderNumber = 1
        left join #TbSumShift as tss on tss.ProfileID = td.ProfileID and td.OrderNumber = 1
        left join #TbSumBusinessLeave as tsbl on tsbl.ProfileID = td.ProfileID and td.OrderNumber = 1
        left join #TbSumLeaveDay as tsld on tsld.ProfileID = td.ProfileID and td.OrderNumber = 1
        left join #TbSumOT as tso on tso.ProfileID = td.ProfileID and td.OrderNumber = 2
        left join #TbSumWorkDay as tswd on tswd.ProfileID = td.ProfileID and td.OrderNumber = 1
where 1 = 1
order by td.ProfileID
		, td.OrderNumber

drop table #TbDetail, #TbOvertime, #TbPermission, #TbSumBusinessLeave, #TbSumLeaveDay, #TbSumOT, #TbSumShift, #TbSumWorkDay, #TbWorkday, #TbWorkHistory;
';
			
            exec (@Query);
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
        --dr_BCCongChiTietThang_nam
      end;
