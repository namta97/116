ALTER proc [dbo].[dr_OTComparistion2Year]
      @Condition varchar(max) = "  and (Year = 2021) and (Cos.OrderNumber is not null)  "
    --@Condition varchar(max) = N' '
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
            declare @YearCondition varchar(max);
            declare @Year varchar(20) = '';
            set @TempCondition = replace(@Condition, ',', '@');
            set @TempCondition = replace(@TempCondition, 'and (', ',');
        
            if ltrim(rtrim(@Condition)) = ''
               or @Condition is null
               begin
                     set @Top = ' top 0 ';
                     set @Year = year(getdate());
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
-- Dieu kien @YearCondition
                        if (select  patindex('%Year%', @TempID)
                           ) > 0
                           begin
                                 set @TempCondition = ltrim(rtrim(@TempID));
                                 set @YearCondition = replace(@TempCondition, '', '');
                                 set @YearCondition = ('and (' + replace(@YearCondition, '@', ','));
                                 set @Year = substring(@YearCondition, patindex('%[0-9]%', @YearCondition), 4);
                                 set @Condition = replace(@Condition, @YearCondition, '');
                           end;
                        delete  #SplitCondition
                        where   id = @TempID;
                  end;
            drop table #SplitCondition;

-- Bang du lieu nam hien tai
            declare @FirstMonth date = datefromparts(@Year - 1, 4, 1);
            declare @Count int = 1;
            declare @ListCol varchar(max);
            declare @ListAlilas varchar(max);
            while @Count <= 24
                  begin
                        set @ListCol = coalesce(@ListCol + ',', '') + quotename(@FirstMonth);
                        set @ListAlilas = coalesce(@ListAlilas + ',', '') + quotename(@FirstMonth) + ' as Data' + convert(varchar(10), @Count);
                        set @FirstMonth = dateadd(month, 1, @FirstMonth);
                        set @Count += 1;
                  end;

     --   select  @YearCondition
     --         , @Year
     --         , @Condition
			  --, @ListCol
			  --, @ListAlilas
     --   return;

-- Query chinh
            set @Query = '	
declare @Year int = ' + @Year + '

set nocount on;
-- Bang du lieu nam hien tai
declare @FirstMonth date = datefromparts(@Year - 1, 4, 1);
declare @Count int = 1;
declare @YearOT table
        (
         MonthYear date
       , DateStart date
       , DateEnd date
        );
while @Count <= 24
      begin
            insert  into @YearOT
                    (
                     MonthYear
                   , DateStart
                   , DateEnd
                    )
            values  (
                     @FirstMonth
                   , dateadd(day, 20, dateadd(month, -1, @FirstMonth))
                   , dateadd(day, 19, @FirstMonth)
                    );
            set @FirstMonth = dateadd(month, 1, @FirstMonth);
            set @Count += 1;
      end;

declare @MaxDateEnd date = (select  max(DateEnd)
                            from    @YearOT
                           );
declare @MinDateStart date = (select    min(DateStart)
                              from      @YearOT
                             );

-- Lay du lieu nhom
declare @GroupA varchar(max) = ''P-SSP,P-SUP,P-SST,P-STF,P-ORD,P-SW1,P-SW2,P-WK1,P-WK2,P-WK3,C-STF,C-ORD,C-SWK,C-WKR,S-STF,S-ORD,S-SWK,S-WKR'';
declare @GroupB varchar(max) = ''P-GMR,P-EX1,P-EX2,P-SRE,P-SM1,P-SM2,P-MGR''; 

set nocount off;
-- ham phan quyen
create table #TbPermission (ProfileID uniqueidentifier)
insert into #TbPermission (ProfileID)
exec Get_Data_Permission_New @UserName = ''' + @Username + ''', @ObjName = ''Hre_Profile''
print (''#TbPermission'')

-- Lay du lieu Org
select  ' + @Top + '
		newid() as ID
      , cou.E_BRANCH_E
      , cou.E_DIVISION_E
      , cou.E_DEPARTMENT_E
      , coalesce(space(6) + cou.E_DEPARTMENT_E, space(3) + cou.E_DIVISION_E, cou.E_BRANCH_E) as OrgName
      , cou.E_BRANCH_CODE
      , concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE) as E_DIVISION_CODE
      , concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE + ''\'', cou.E_DEPARTMENT_CODE) as E_DEPARTMENT_CODE
into    #TbOrgUnit
from    Cat_OrgUnit as cou
left join (select ID, OrderNumber from Cat_OrgStructure where IsDelete is null) as cos on cos.ID = cou.OrgstructureID
where   cou.IsDelete is null
		'+@Condition+'
group by cou.E_BRANCH_E
      , cou.E_DIVISION_E
      , cou.E_DEPARTMENT_E
      , coalesce(space(6) + cou.E_DEPARTMENT_E, space(3) + cou.E_DIVISION_E, cou.E_BRANCH_E)
      , cou.E_BRANCH_CODE
      , concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE)
      , concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE + ''\'', cou.E_DEPARTMENT_CODE)
print (''#TbOrgUnit'');

-- Lay du lieu qtct
select  ' + @Top + '
		cou.E_BRANCH_E
      , cou.E_DIVISION_E
      , cou.E_DEPARTMENT_E
      , hwh.ProfileID
      , hwh.DateEffective
      , case when cne.EnumType in (''E_STOP'') then ''InActive'' 
			 else ''Active''
		end as Status
      , case when csc.Code in (select   Result from GetSplitString(@GroupA)) then ''GroupA'' 
			 when csc.Code in (select Result from GetSplitString(@GroupB)) then ''GroupB'' 
			 end as GroupType
      , yo.MonthYear
      , row_number() over (partition by hwh.ProfileID, yo.MonthYear order by hwh.DateEffective desc) as RN
      , hwh.OrganizationStructureID
      , coalesce(space(6) + cou.E_DEPARTMENT_E, space(3) + cou.E_DIVISION_E, cou.E_BRANCH_E) as OrgName
      , cou.E_BRANCH_CODE
      , concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE) as E_DIVISION_CODE
      , concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE + ''\'', cou.E_DEPARTMENT_CODE) as E_DEPARTMENT_CODE
into    #TbWorkhistory
from    Hre_WorkHistory as hwh
        left join Cat_NameEntity as cne on cne.ID = hwh.TypeOfTransferID and cne.IsDelete is null
        left join Cat_SalaryClass as csc on csc.ID = hwh.SalaryClassID and csc.IsDelete is null
        left join Cat_OrgStructure as cos on cos.ID = hwh.OrganizationStructureID and cos.IsDelete is null
        left join Cat_OrgUnit as cou on cou.OrgstructureID = hwh.OrganizationStructureID
        cross apply @YearOT as yo
where   hwh.IsDelete is null
        and hwh.Status = ''E_APPROVED''
        and hwh.DateEffective <= @MaxDateEnd
        and hwh.DateEffective <= yo.DateEnd
        and yo.DateEnd = (select min(t.DateEnd) from @YearOT as t where t.DateEnd >= hwh.DateEffective)
		and exists (select ProfileID from #TbPermission as p where p.ProfileID = hwh.ProfileID)
		' + @Condition + '
print (''#TbWorkhistory'');

-- Lay du hieu OT
select  ' + @Top + '
		ao.ID
      , ao.ProfileID
      , yo.MonthYear
      , ao.ConfirmHours
      , ao.OvertimePlanID
into    #TbOvertime
from    Att_Overtime as ao
        cross apply @YearOT as yo
where   ao.IsDelete is null
        and ao.WorkDateRoot between yo.DateStart and yo.DateEnd
        and ao.Status = ''E_CONFIRM''
        and ao.WorkDateRoot between @MinDateStart and @MaxDateEnd
		and exists (select tw.ProfileID from #TbWorkhistory as tw where tw.ProfileID = ao.ProfileID)
print (''#TbOvertime'');

-- Lay du hieu OTPlan
select  ' + @Top + '
		aop.ID
      , aop.ProfileID
      , yo.MonthYear
      , aop.ApproveHours
into    #TbOvertimePlan
from    Att_OvertimePlan as aop
        cross apply @YearOT as yo
where   aop.IsDelete is null
        and aop.WorkDateRoot between yo.DateStart and yo.DateEnd
        and aop.Status = ''E_APPROVED''
        and aop.WorkDateRoot between @MinDateStart and @MaxDateEnd
        and not exists ( select tov.OvertimePlanID from   #TbOvertime as tov where  tov.OvertimePlanID = aop.ID )
		and exists (select tw.ProfileID from #TbWorkhistory as tw where tw.ProfileID = aop.ProfileID)
print (''#TbOvertimePlan'');

-- Ket du lieu OT
select  DataOT.MonthYear
      , tw.E_BRANCH_E
      , tw.E_DIVISION_E
      , tw.E_DEPARTMENT_E
      , DataOT.ProfileID
      , tw.GroupType
	  , tw.E_BRANCH_CODE
	  , tw.E_DIVISION_CODE
	  , tw.E_DEPARTMENT_CODE
      , sum(DataOT.ConfirmHours) as ConfirmHours
into    #TbDataOT
from    (select tov.ID
              , tov.ProfileID
              , tov.MonthYear
              , tov.ConfirmHours
         from   #TbOvertime as tov
         union all
         select topl.ID
              , topl.ProfileID
              , topl.MonthYear
              , topl.ApproveHours
         from   #TbOvertimePlan as topl
        ) as DataOT
        outer apply (select *
                     from   #TbWorkhistory as tw
                     where  tw.ProfileID = DataOT.ProfileID
                            and tw.MonthYear = 
											(SELECT  max(t.MonthYear)
                                                from    #TbWorkhistory as t
                                                where   t.ProfileID = tw.ProfileID
                                                        and t.MonthYear <= DataOT.MonthYear
														AND t.Rn = 1
                                               )
                            and tw.RN = 1
                    ) as tw
group by DataOT.MonthYear
      , tw.E_BRANCH_E
      , tw.E_DIVISION_E
      , tw.E_DEPARTMENT_E
      , DataOT.ProfileID
      , tw.GroupType
	  , tw.E_BRANCH_CODE
	  , tw.E_DIVISION_CODE
	  , tw.E_DEPARTMENT_CODE;
print (''#TbDataOT'');

-- Headcount nhom A
select  ID
      , E_BRANCH_E
      , E_DIVISION_E
      , E_DEPARTMENT_E
      , ' + @ListAlilas + '
into    #TbHCGroupA
from    (select tou.ID
              , tou.E_BRANCH_E
              , tou.E_DIVISION_E
              , tou.E_DEPARTMENT_E
              , yo.MonthYear
              , case when tou.E_DIVISION_E is null and tou.E_DEPARTMENT_E is null then Branch.HeadCount 
					 when tou.E_DEPARTMENT_E is null then Division.HeadCount 
					 else Deparment.HeadCount end as HeadCount
         from   #TbOrgUnit as tou
                cross apply @YearOT as yo
                cross apply (select count(distinct tw.ProfileID) as HeadCount
                             from   #TbWorkhistory as tw
                             where  tw.E_BRANCH_CODE = tou.E_BRANCH_CODE
                                    and tw.DateEffective <= yo.DateEnd
                                    and tw.GroupType = ''GroupA''
                                    and tw.Status = ''Active''
                                    and tw.DateEffective = (select  max(t.DateEffective)
                                                            from    #TbWorkhistory as t
                                                            where   t.ProfileID = tw.ProfileID
                                                                    and t.DateEffective <= yo.DateEnd
                                                                    and t.GroupType = ''GroupA''
                                                           )
                            ) as Branch
                cross apply (select count(distinct tw.ProfileID) as HeadCount
                             from   #TbWorkhistory as tw
                             where  tw.E_DIVISION_CODE = tou.E_DIVISION_CODE
                                    and tw.DateEffective <= yo.DateEnd
                                    and tw.GroupType = ''GroupA''
                                    and tw.Status = ''Active''
                                    and tw.DateEffective = (select  max(t.DateEffective)
                                                            from    #TbWorkhistory as t
                                                            where   t.ProfileID = tw.ProfileID
                                                                    and t.DateEffective <= yo.DateEnd
                                                                    and t.GroupType = ''GroupA''
                                                           )
                            ) as Division
                cross apply (select count(distinct tw.ProfileID) as HeadCount
                             from   #TbWorkhistory as tw
                             where  tw.E_DEPARTMENT_CODE = tou.E_DEPARTMENT_CODE
                                    and tw.DateEffective <= yo.DateEnd
                                    and tw.GroupType = ''GroupA''
                                    and tw.Status = ''Active''
                                    and tw.DateEffective = (select  max(t.DateEffective)
                                                            from    #TbWorkhistory as t
                                                            where   t.ProfileID = tw.ProfileID
                                                                    and t.DateEffective <= yo.DateEnd
                                                                    and t.GroupType = ''GroupA''
                                                           )
                            ) as Deparment
        ) as DataHC pivot ( max(HeadCount) for MonthYear in (' + @ListCol + ') ) pv;
print (''#TbHCGroupA'');

-- HeacountOT nhom A
select  ID
      , E_BRANCH_E
      , E_DIVISION_E
      , E_DEPARTMENT_E
      , ' + @ListAlilas + '
into    #TbHCOTGroupA
from    (select tou.*
              , yo.MonthYear
              , case when tou.E_DIVISION_E is null and tou.E_DEPARTMENT_E is null then Branch.HeadCountOT
                     when tou.E_DEPARTMENT_E is null then Division.HeadCountOT
                     else Department.HeadCountOT
                end as HeadCountOT
         from   #TbOrgUnit as tou
                cross apply @YearOT as yo
                cross apply (select count(distinct tdo.ProfileID) as HeadCountOT
                             from   #TbDataOT as tdo
                             where  tdo.E_BRANCH_CODE = tou.E_BRANCH_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupA''
                            ) as Branch
                cross apply (select count(distinct tdo.ProfileID) as HeadCountOT
                             from   #TbDataOT as tdo
                             where  tdo.E_DIVISION_CODE = tou.E_DIVISION_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupA''
                            ) as Division
                cross apply (select count(distinct tdo.ProfileID) as HeadCountOT
                             from   #TbDataOT as tdo
                             where  tdo.E_DEPARTMENT_CODE = tou.E_DEPARTMENT_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupA''
                            ) as Department
        ) as DataOT pivot ( sum(HeadCountOT) for MonthYear in (' + @ListCol + ') ) as pv;
print (''#TbHCOTGroupA'');

-- OT nhom A
select  ID
      , E_BRANCH_E
      , E_DIVISION_E
      , E_DEPARTMENT_E
      , ' + @ListAlilas + '
into    #TbOTGroupA
from    (select tou.*
              , yo.MonthYear
              , case when tou.E_DIVISION_E is null and tou.E_DEPARTMENT_E is null then Branch.OTHours
                     when tou.E_DEPARTMENT_E is null then Division.OTHours
                     else Department.OTHours
                end as OTHours
         from   #TbOrgUnit as tou
                cross apply @YearOT as yo
                cross apply (select sum(tdo.ConfirmHours) as OTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_BRANCH_CODE = tou.E_BRANCH_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupA''
                            ) as Branch
                cross apply (select sum(tdo.ConfirmHours) as OTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_DIVISION_CODE = tou.E_DIVISION_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupA''
                            ) as Division
                cross apply (select sum(tdo.ConfirmHours) as OTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_DEPARTMENT_CODE = tou.E_DEPARTMENT_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupA''
                            ) as Department
        ) as DataOT pivot ( sum(OTHours) for MonthYear in (' + @ListCol + ') ) as pv;
print (''#TbOTGroupA'');

-- AVG nhom A
select  ID
      , E_BRANCH_E
      , E_DIVISION_E
      , E_DEPARTMENT_E
      , ' + @ListAlilas + '
into    #TbAvgOTHoursGroupA
from    (select tou.ID
              , tou.E_BRANCH_E
              , tou.E_DIVISION_E
              , tou.E_DEPARTMENT_E
              , yo.MonthYear
              , case when tou.E_DIVISION_E is null and tou.E_DEPARTMENT_E is null then Branch.AvgOTHours
                     when tou.E_DEPARTMENT_E is null then Division.AvgOTHours
                     else Department.AvgOTHours
                end as AvgOTHours
         from   #TbOrgUnit as tou
                cross apply @YearOT as yo
                cross apply (select sum(tdo.ConfirmHours) / count(distinct tdo.ProfileID) as AvgOTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_BRANCH_CODE = tou.E_BRANCH_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupA''
                            ) as Branch
                cross apply (select sum(tdo.ConfirmHours) / count(distinct tdo.ProfileID) as AvgOTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_DIVISION_CODE = tou.E_DIVISION_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupA''
                            ) as Division
                cross apply (select sum(tdo.ConfirmHours) / count(distinct tdo.ProfileID) as AvgOTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_DEPARTMENT_CODE = tou.E_DEPARTMENT_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupA''
                            ) as Department
        ) as DataOT pivot ( max(AvgOTHours) for MonthYear in (' + @ListCol
                + ') ) as pv;
print (''#TbAvgOTHoursGroupA'');

--SUM data nhom A
	SELECT 
			SUM(Data1) AS SUM_HCData1,SUM(Data2) AS SUM_HCData2,SUM(Data3) AS SUM_HCData3,SUM(Data4) AS SUM_HCData4,SUM(Data5) AS SUM_HCData5,SUM(Data6) AS SUM_HCData6
			,SUM(Data7) AS SUM_HCData7,SUM(Data8) AS SUM_HCData8,SUM(Data9) AS SUM_HCData9,SUM(Data10) AS SUM_HCData10,SUM(Data11) AS SUM_HCData11,SUM(Data12) AS SUM_HCData12
			,SUM(Data13) AS SUM_HCData13,SUM(Data14) AS SUM_HCData14,SUM(Data15) AS SUM_HCData15,SUM(Data16) AS SUM_HCData16,SUM(Data17) AS SUM_HCData17,SUM(Data18) AS SUM_HCData18
			,SUM(Data19) AS SUM_HCData19,SUM(Data20) AS SUM_HCData20,SUM(Data21) AS SUM_HCData21,SUM(Data22) AS SUM_HCData22,SUM(Data23) AS SUM_HCData23,SUM(Data24) AS SUM_HCData24
	INTO	#SUM_TbHCGroupA
	FROM	#TbHCGroupA
	WHERE	E_DIVISION_E IS NOT NULL AND E_DEPARTMENT_E IS NULL


	SELECT 
			SUM(Data1) AS SUM_HCOTData1,SUM(Data2) AS SUM_HCOTData2,SUM(Data3) AS SUM_HCOTData3,SUM(Data4) AS SUM_HCOTData4,SUM(Data5) AS SUM_HCOTData5,SUM(Data6) AS SUM_HCOTData6
			,SUM(Data7) AS SUM_HCOTData7,SUM(Data8) AS SUM_HCOTData8,SUM(Data9) AS SUM_HCOTData9,SUM(Data10) AS SUM_HCOTData10,SUM(Data11) AS SUM_HCOTData11,SUM(Data12) AS SUM_HCOTData12
			,SUM(Data13) AS SUM_HCOTData13,SUM(Data14) AS SUM_HCOTData14,SUM(Data15) AS SUM_HCOTData15,SUM(Data16) AS SUM_HCOTData16,SUM(Data17) AS SUM_HCOTData17,SUM(Data18) AS SUM_HCOTData18
			,SUM(Data19) AS SUM_HCOTData19,SUM(Data20) AS SUM_HCOTData20,SUM(Data21) AS SUM_HCOTData21,SUM(Data22) AS SUM_HCOTData22,SUM(Data23) AS SUM_HCOTData23,SUM(Data24) AS SUM_HCOTData24
	INTO	#SUM_TbHCOTGroupA
	FROM	#TbHCOTGroupA
	WHERE	E_DIVISION_E IS NOT NULL AND E_DEPARTMENT_E IS NULL


	SELECT 
			SUM(Data1) AS SUM_OTData1,SUM(Data2) AS SUM_OTData2,SUM(Data3) AS SUM_OTData3,SUM(Data4) AS SUM_OTData4,SUM(Data5) AS SUM_OTData5,SUM(Data6) AS SUM_OTData6
			,SUM(Data7) AS SUM_OTData7,SUM(Data8) AS SUM_OTData8,SUM(Data9) AS SUM_OTData9,SUM(Data10) AS SUM_OTData10,SUM(Data11) AS SUM_OTData11,SUM(Data12) AS SUM_OTData12
			,SUM(Data13) AS SUM_OTData13,SUM(Data14) AS SUM_OTData14,SUM(Data15) AS SUM_OTData15,SUM(Data16) AS SUM_OTData16,SUM(Data17) AS SUM_OTData17,SUM(Data18) AS SUM_OTData18
			,SUM(Data19) AS SUM_OTData19,SUM(Data20) AS SUM_OTData20,SUM(Data21) AS SUM_OTData21,SUM(Data22) AS SUM_OTData22,SUM(Data23) AS SUM_OTData23,SUM(Data24) AS SUM_OTData24
	INTO	#SUM_TbOTGroupA
	FROM	#TbOTGroupA
	WHERE	E_DIVISION_E IS NOT NULL AND E_DEPARTMENT_E IS NULL



-- bang du lieu nhom A nam N
select  ''GroupA_N'' as Type
      , hc.ID
      , hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E
	  , coalesce(char (9) + char (9) + hc.E_DEPARTMENT_E, char(9) + hc.E_DIVISION_E, hc.E_BRANCH_E) as OrgStructureName
      , hc.Data13 as HCData1
      , hc.Data14 as HCData2
      , hc.Data15 as HCData3
      , hc.Data16 as HCData4
      , hc.Data17 as HCData5
      , hc.Data18 as HCData6
      , hc.Data19 as HCData7
      , hc.Data20 as HCData8
      , hc.Data21 as HCData9
      , hc.Data22 as HCData10
      , hc.Data23 as HCData11
      , hc.Data24 as HCData12
      , hcot.Data13 as HCOTData1
      , hcot.Data14 as HCOTData2
      , hcot.Data15 as HCOTData3
      , hcot.Data16 as HCOTData4
      , hcot.Data17 as HCOTData5
      , hcot.Data18 as HCOTData6
      , hcot.Data19 as HCOTData7
      , hcot.Data20 as HCOTData8
      , hcot.Data21 as HCOTData9
      , hcot.Data22 as HCOTData10
      , hcot.Data23 as HCOTData11
      , hcot.Data24 as HCOTData12
      , ot.Data13 as OTData1
      , ot.Data14 as OTData2
      , ot.Data15 as OTData3
      , ot.Data16 as OTData4
      , ot.Data17 as OTData5
      , ot.Data18 as OTData6
      , ot.Data19 as OTData7
      , ot.Data20 as OTData8
      , ot.Data21 as OTData9
      , ot.Data22 as OTData10
      , ot.Data23 as OTData11
      , ot.Data24 as OTData12
      , avghour.Data13 as AvgOTData1
      , avghour.Data14 as AvgOTData2
      , avghour.Data15 as AvgOTData3
      , avghour.Data16 as AvgOTData4
      , avghour.Data17 as AvgOTData5
      , avghour.Data18 as AvgOTData6
      , avghour.Data19 as AvgOTData7
      , avghour.Data20 as AvgOTData8
      , avghour.Data21 as AvgOTData9
      , avghour.Data22 as AvgOTData10
      , avghour.Data23 as AvgOTData11
      , avghour.Data24 as AvgOTData12
	  , Accumulate.AccumulateHC_N
	  , Accumulate.AccumulateHCOT_N
	  , Accumulate.AccumulateOT_N
	  , Accumulate.AccumulateOT_N / 1.0 / nullif(Accumulate.AccumulateHCOT_N,0) as AccumulateAvgOTHours_N
	  , CASE WHEN hc.E_DEPARTMENT_E IS NULL THEN
			CASE
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NOT NULL THEN 1
			WHEN hc.E_DIVISION_E IS NOT NULL AND hc.E_BRANCH_E IS NOT NULL THEN 2
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NULL THEN 0 
			END
		ELSE 3 END AS ConditionFormat
	  , sumhc.SUM_HCData13 as SUM_HCData1
      , sumhc.SUM_HCData14 as SUM_HCData2
      , sumhc.SUM_HCData15 as SUM_HCData3
      , sumhc.SUM_HCData16 as SUM_HCData4
      , sumhc.SUM_HCData17 as SUM_HCData5
      , sumhc.SUM_HCData18 as SUM_HCData6
      , sumhc.SUM_HCData19 as SUM_HCData7
      , sumhc.SUM_HCData20 as SUM_HCData8
      , sumhc.SUM_HCData21 as SUM_HCData9
      , sumhc.SUM_HCData22 as SUM_HCData10
      , sumhc.SUM_HCData23 as SUM_HCData11
      , sumhc.SUM_HCData24 as SUM_HCData12
	  , sumhcot.SUM_HCOTData13 as SUM_HCOTData1
      , sumhcot.SUM_HCOTData14 as SUM_HCOTData2
      , sumhcot.SUM_HCOTData15 as SUM_HCOTData3
      , sumhcot.SUM_HCOTData16 as SUM_HCOTData4
      , sumhcot.SUM_HCOTData17 as SUM_HCOTData5
      , sumhcot.SUM_HCOTData18 as SUM_HCOTData6
      , sumhcot.SUM_HCOTData19 as SUM_HCOTData7
      , sumhcot.SUM_HCOTData20 as SUM_HCOTData8
      , sumhcot.SUM_HCOTData21 as SUM_HCOTData9
      , sumhcot.SUM_HCOTData22 as SUM_HCOTData10
      , sumhcot.SUM_HCOTData23 as SUM_HCOTData11
      , sumhcot.SUM_HCOTData24 as SUM_HCOTData12
	  , sumot.SUM_OTData13 as SUM_OTData1
      , sumot.SUM_OTData14 as SUM_OTData2
      , sumot.SUM_OTData15 as SUM_OTData3
      , sumot.SUM_OTData16 as SUM_OTData4
      , sumot.SUM_OTData17 as SUM_OTData5
      , sumot.SUM_OTData18 as SUM_OTData6
      , sumot.SUM_OTData19 as SUM_OTData7
      , sumot.SUM_OTData20 as SUM_OTData8
      , sumot.SUM_OTData21 as SUM_OTData9
      , sumot.SUM_OTData22 as SUM_OTData10
      , sumot.SUM_OTData23 as SUM_OTData11
      , sumot.SUM_OTData24 as SUM_OTData12
	  , null as "Cos.OrderNumber"
	  , @Year as "Year"
from    #TbHCGroupA as hc
        left join #TbHCOTGroupA as hcot on hcot.ID = hc.ID
        left join #TbOTGroupA as ot on ot.ID = hc.ID
        left join #TbAvgOTHoursGroupA as avghour on avghour.ID = hc.ID
		cross apply (
		 select isnull(hc.Data13,0)+isnull(hc.Data14,0)+isnull(hc.Data15,0)+isnull(hc.Data16,0)+isnull(hc.Data17,0)+isnull(hc.Data18,0)+isnull(hc.Data19,0)+isnull(hc.Data20,0)+isnull(hc.Data21,0)+isnull(hc.Data22,0)+isnull(hc.Data23,0)+isnull(hc.Data24,0) AccumulateHC_N
			  , isnull(hcot.Data13,0)+isnull(hcot.Data14,0)+isnull(hcot.Data15,0)+isnull(hcot.Data16,0)+isnull(hcot.Data17,0)+isnull(hcot.Data18,0)+isnull(hcot.Data19,0)+isnull(hcot.Data20,0)+isnull(hcot.Data21,0)+isnull(hcot.Data22,0)+isnull(hcot.Data23,0)+isnull(hcot.Data24,0) as AccumulateHCOT_N
			  , isnull(ot.Data13,0)+isnull(ot.Data14,0)+isnull(ot.Data15,0)+isnull(ot.Data16,0)+isnull(ot.Data17,0)+isnull(ot.Data18,0)+isnull(ot.Data19,0)+isnull(ot.Data20,0)+isnull(ot.Data21,0)+isnull(ot.Data22,0)+isnull(ot.Data23,0)+isnull(ot.Data24,0) as AccumulateOT_N
					) as Accumulate
		cross apply ( select * from #SUM_TbHCGroupA ) as sumhc
		cross apply ( select * from #SUM_TbHCOTGroupA ) sumhcot
		cross apply ( select * from #SUM_TbOTGroupA ) sumot
order by hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E;


-- bang du lieu nhom A nam N-1
select  ''GroupA_N-1'' as Type
      , hc.ID
      , hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E
	  , coalesce(char (9) + char (9) + hc.E_DEPARTMENT_E, char(9) + hc.E_DIVISION_E, hc.E_BRANCH_E) as OrgStructureName
      , hc.Data1 as HCData1
      , hc.Data2 as HCData2
      , hc.Data3 as HCData3
      , hc.Data4 as HCData4
      , hc.Data5 as HCData5
      , hc.Data6 as HCData6
      , hc.Data7 as HCData7
      , hc.Data8 as HCData8
      , hc.Data9 as HCData9
      , hc.Data10 as HCData10
      , hc.Data11 as HCData11
      , hc.Data12 as HCData12
      , hcot.Data1 as HCOTData1
      , hcot.Data2 as HCOTData2
      , hcot.Data3 as HCOTData3
      , hcot.Data4 as HCOTData4
      , hcot.Data5 as HCOTData5
      , hcot.Data6 as HCOTData6
      , hcot.Data7 as HCOTData7
      , hcot.Data8 as HCOTData8
      , hcot.Data9 as HCOTData9
      , hcot.Data10 as HCOTData10
      , hcot.Data11 as HCOTData11
      , hcot.Data12 as HCOTData12
      , ot.Data1 as OTData1
      , ot.Data2 as OTData2
      , ot.Data3 as OTData3
      , ot.Data4 as OTData4
      , ot.Data5 as OTData5
      , ot.Data6 as OTData6
      , ot.Data7 as OTData7
      , ot.Data8 as OTData8
      , ot.Data9 as OTData9
      , ot.Data10 as OTData10
      , ot.Data11 as OTData11
      , ot.Data12 as OTData12
      , avghour.Data1 as AvgOTData1
      , avghour.Data2 as AvgOTData2
      , avghour.Data3 as AvgOTData3
      , avghour.Data4 as AvgOTData4
      , avghour.Data5 as AvgOTData5
      , avghour.Data6 as AvgOTData6
      , avghour.Data7 as AvgOTData7
      , avghour.Data8 as AvgOTData8
      , avghour.Data9 as AvgOTData9
      , avghour.Data10 as AvgOTData10
      , avghour.Data11 as AvgOTData11
      , avghour.Data12 as AvgOTData12
	  , Accumulate.AccumulateHC_N1
	  , Accumulate.AccumulateHCOT_N1
	  , Accumulate.AccumulateOT_N1
	  , Accumulate.AccumulateOT_N1 / 1.0 / nullif(Accumulate.AccumulateHCOT_N1,0) as AccumulateAvgOTHours_N1
	  , CASE WHEN hc.E_DEPARTMENT_E IS NULL THEN
			CASE
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NOT NULL THEN 1
			WHEN hc.E_DIVISION_E IS NOT NULL AND hc.E_BRANCH_E IS NOT NULL THEN 2
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NULL THEN 0 
			END
		ELSE 3 END AS ConditionFormat
	  , sumhc.*
	  , sumhcot.*
	  , sumot.*
from    #TbHCGroupA as hc
        left join #TbHCOTGroupA as hcot on hcot.ID = hc.ID
        left join #TbOTGroupA as ot on ot.ID = hc.ID
        left join #TbAvgOTHoursGroupA as avghour on avghour.ID = hc.ID
		cross apply (
		 select isnull(hc.Data1,0)+isnull(hc.Data2,0)+isnull(hc.Data3,0)+isnull(hc.Data4,0)+isnull(hc.Data5,0)+isnull(hc.Data6,0)+isnull(hc.Data7,0)+isnull(hc.Data8,0)+isnull(hc.Data9,0)+isnull(hc.Data10,0)+isnull(hc.Data11,0)+isnull(hc.Data12,0) as AccumulateHC_N1
			  , isnull(hcot.Data1,0)+isnull(hcot.Data2,0)+isnull(hcot.Data3,0)+isnull(hcot.Data4,0)+isnull(hcot.Data5,0)+isnull(hcot.Data6,0)+isnull(hcot.Data7,0)+isnull(hcot.Data8,0)+isnull(hcot.Data9,0)+isnull(hcot.Data10,0)+isnull(hcot.Data11,0)+isnull(hcot.Data12,0) as AccumulateHCOT_N1
			  , isnull(ot.Data1,0)+isnull(ot.Data2,0)+isnull(ot.Data3,0)+isnull(ot.Data4,0)+isnull(ot.Data5,0)+isnull(ot.Data6,0)+isnull(ot.Data7,0)+isnull(ot.Data8,0)+isnull(ot.Data9,0)+isnull(ot.Data10,0)+isnull(ot.Data11,0)+isnull(ot.Data12,0) as AccumulateOT_N1
					) as Accumulate
		cross apply ( select * from #SUM_TbHCGroupA ) as sumhc
		cross apply ( select * from #SUM_TbHCOTGroupA ) sumhcot
		cross apply ( select * from #SUM_TbOTGroupA ) sumot
order by hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E;

-- bang du lieu so sanh nhom A
select  ''GroupA_N/N-1'' as Type
      , hc.ID
      , hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E
	  , coalesce(char (9) + char (9) + hc.E_DEPARTMENT_E, char(9) + hc.E_DIVISION_E, hc.E_BRANCH_E) as OrgStructureName
      , hc.Data13 / 1.0 / nullif(hc.Data1, 0) as HCData1
      , hc.Data14 / 1.0 / nullif(hc.Data2, 0) as HCData2
      , hc.Data15 / 1.0 / nullif(hc.Data3, 0) as HCData3
      , hc.Data16 / 1.0 / nullif(hc.Data4, 0) as HCData4
      , hc.Data17 / 1.0 / nullif(hc.Data5, 0) as HCData5
      , hc.Data18 / 1.0 / nullif(hc.Data6, 0) as HCData6
      , hc.Data19 / 1.0 / nullif(hc.Data7, 0) as HCData7
      , hc.Data20 / 1.0 / nullif(hc.Data8, 0) as HCData8
      , hc.Data21 / 1.0 / nullif(hc.Data9, 0) as HCData9
      , hc.Data22 / 1.0 / nullif(hc.Data10, 0) as HCData10
      , hc.Data23 / 1.0 / nullif(hc.Data11, 0) as HCData11
      , hc.Data24 / 1.0 / nullif(hc.Data12, 0) as HCData12
      , hcot.Data13 / 1.0 / nullif(hcot.Data1, 0) as HCOTData1
      , hcot.Data14 / 1.0 / nullif(hcot.Data2, 0) as HCOTData2
      , hcot.Data15 / 1.0 / nullif(hcot.Data3, 0) as HCOTData3
      , hcot.Data16 / 1.0 / nullif(hcot.Data4, 0) as HCOTData4
      , hcot.Data17 / 1.0 / nullif(hcot.Data5, 0) as HCOTData5
      , hcot.Data18 / 1.0 / nullif(hcot.Data6, 0) as HCOTData6
      , hcot.Data19 / 1.0 / nullif(hcot.Data7, 0) as HCOTData7
      , hcot.Data20 / 1.0 / nullif(hcot.Data8, 0) as HCOTData8
      , hcot.Data21 / 1.0 / nullif(hcot.Data9, 0) as HCOTData9
      , hcot.Data22 / 1.0 / nullif(hcot.Data10, 0) as HCOTData10
      , hcot.Data23 / 1.0 / nullif(hcot.Data11, 0) as HCOTData11
      , hcot.Data24 / 1.0 / nullif(hcot.Data12, 0) as HCOTData12
      , ot.Data13 / 1.0 / nullif(ot.Data1, 0) as OTData1
      , ot.Data14 / 1.0 / nullif(ot.Data2, 0) as OTData2
      , ot.Data15 / 1.0 / nullif(ot.Data3, 0) as OTData3
      , ot.Data16 / 1.0 / nullif(ot.Data4, 0) as OTData4
      , ot.Data17 / 1.0 / nullif(ot.Data5, 0) as OTData5
      , ot.Data18 / 1.0 / nullif(ot.Data6, 0) as OTData6
      , ot.Data19 / 1.0 / nullif(ot.Data7, 0) as OTData7
      , ot.Data20 / 1.0 / nullif(ot.Data8, 0) as OTData8
      , ot.Data21 / 1.0 / nullif(ot.Data9, 0) as OTData9
      , ot.Data22 / 1.0 / nullif(ot.Data10, 0) as OTData10
      , ot.Data23 / 1.0 / nullif(ot.Data11, 0) as OTData11
      , ot.Data24 / 1.0 / nullif(ot.Data12, 0) as OTData12
      , avghour.Data13 / 1.0 / nullif(avghour.Data1, 0) as AvgOTData1
      , avghour.Data14 / 1.0 / nullif(avghour.Data2, 0) as AvgOTData2
      , avghour.Data15 / 1.0 / nullif(avghour.Data3, 0) as AvgOTData3
      , avghour.Data16 / 1.0 / nullif(avghour.Data4, 0) as AvgOTData4
      , avghour.Data17 / 1.0 / nullif(avghour.Data5, 0) as AvgOTData5
      , avghour.Data18 / 1.0 / nullif(avghour.Data6, 0) as AvgOTData6
      , avghour.Data19 / 1.0 / nullif(avghour.Data7, 0) as AvgOTData7
      , avghour.Data20 / 1.0 / nullif(avghour.Data8, 0) as AvgOTData8
      , avghour.Data21 / 1.0 / nullif(avghour.Data9, 0) as AvgOTData9
      , avghour.Data22 / 1.0 / nullif(avghour.Data10, 0) as AvgOTData10
      , avghour.Data23 / 1.0 / nullif(avghour.Data11, 0) as AvgOTData11
      , avghour.Data24 / 1.0 / nullif(avghour.Data12, 0) as AvgOTData12
	  , Accumulate.AccumulateHC_N / 1.0 / nullif(Accumulate.AccumulateHC_N1, 0) / 1.0 as AccumulateHC
	  , Accumulate.AccumulateHCOT_N / 1.0 / nullif(Accumulate.AccumulateHCOT_N1, 0) / 1.0 as AccumulateHCOT
	  , Accumulate.AccumulateOT_N / 1.0 / nullif(Accumulate.AccumulateOT_N1, 0) as AccumulateOT
	  , (Accumulate.AccumulateOT_N / 1.0 / nullif(Accumulate.AccumulateHCOT_N,0)) / nullif((Accumulate.AccumulateOT_N1 / 1.0 / nullif(Accumulate.AccumulateHCOT_N1,0)),0) / 1.0 as AccumulateAvgOTHours
	  , CASE WHEN hc.E_DEPARTMENT_E IS NULL THEN
			CASE
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NOT NULL THEN 1
			WHEN hc.E_DIVISION_E IS NOT NULL AND hc.E_BRANCH_E IS NOT NULL THEN 2
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NULL THEN 0 
			END
		ELSE 3 END AS ConditionFormat
from    #TbHCGroupA as hc
        left join #TbHCOTGroupA as hcot on hcot.ID = hc.ID
        left join #TbOTGroupA as ot on ot.ID = hc.ID
        left join #TbAvgOTHoursGroupA as avghour on avghour.ID = hc.ID
		cross apply (
		 select isnull(hc.Data1,0)+isnull(hc.Data2,0)+isnull(hc.Data3,0)+isnull(hc.Data4,0)+isnull(hc.Data5,0)+isnull(hc.Data6,0)+isnull(hc.Data7,0)+isnull(hc.Data8,0)+isnull(hc.Data9,0)+isnull(hc.Data10,0)+isnull(hc.Data11,0)+isnull(hc.Data12,0) as AccumulateHC_N1
			  , isnull(hc.Data13,0)+isnull(hc.Data14,0)+isnull(hc.Data15,0)+isnull(hc.Data16,0)+isnull(hc.Data17,0)+isnull(hc.Data18,0)+isnull(hc.Data19,0)+isnull(hc.Data20,0)+isnull(hc.Data21,0)+isnull(hc.Data22,0)+isnull(hc.Data23,0)+isnull(hc.Data24,0) AccumulateHC_N
			  , isnull(hcot.Data1,0)+isnull(hcot.Data2,0)+isnull(hcot.Data3,0)+isnull(hcot.Data4,0)+isnull(hcot.Data5,0)+isnull(hcot.Data6,0)+isnull(hcot.Data7,0)+isnull(hcot.Data8,0)+isnull(hcot.Data9,0)+isnull(hcot.Data10,0)+isnull(hcot.Data11,0)+isnull(hcot.Data12,0) as AccumulateHCOT_N1
			  , isnull(hcot.Data13,0)+isnull(hcot.Data14,0)+isnull(hcot.Data15,0)+isnull(hcot.Data16,0)+isnull(hcot.Data17,0)+isnull(hcot.Data18,0)+isnull(hcot.Data19,0)+isnull(hcot.Data20,0)+isnull(hcot.Data21,0)+isnull(hcot.Data22,0)+isnull(hcot.Data23,0)+isnull(hcot.Data24,0) as AccumulateHCOT_N
			  , isnull(ot.Data1,0)+isnull(ot.Data2,0)+isnull(ot.Data3,0)+isnull(ot.Data4,0)+isnull(ot.Data5,0)+isnull(ot.Data6,0)+isnull(ot.Data7,0)+isnull(ot.Data8,0)+isnull(ot.Data9,0)+isnull(ot.Data10,0)+isnull(ot.Data11,0)+isnull(ot.Data12,0) as AccumulateOT_N1
			  , isnull(ot.Data13,0)+isnull(ot.Data14,0)+isnull(ot.Data15,0)+isnull(ot.Data16,0)+isnull(ot.Data17,0)+isnull(ot.Data18,0)+isnull(ot.Data19,0)+isnull(ot.Data20,0)+isnull(ot.Data21,0)+isnull(ot.Data22,0)+isnull(ot.Data23,0)+isnull(ot.Data24,0) as AccumulateOT_N
					) as Accumulate
order by hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E;

-- Headcount nhom B
select  ID
      , E_BRANCH_E
      , E_DIVISION_E
      , E_DEPARTMENT_E
      , ' + @ListAlilas + '
into    #TbHCGroupB
from    (select tou.ID
              , tou.E_BRANCH_E
              , tou.E_DIVISION_E
              , tou.E_DEPARTMENT_E
              , yo.MonthYear
              , case when tou.E_DIVISION_E is null and tou.E_DEPARTMENT_E is null then Branch.HeadCount
                     when tou.E_DEPARTMENT_E is null then Division.HeadCount
                     else Deparment.HeadCount
                end as HeadCount
         from   #TbOrgUnit as tou
                cross apply @YearOT as yo
                cross apply (select count(distinct tw.ProfileID) as HeadCount
                             from   #TbWorkhistory as tw
                             where  tw.E_BRANCH_CODE = tou.E_BRANCH_CODE
                                    and tw.DateEffective <= yo.DateEnd
                                    and tw.GroupType = ''GroupB''
                                    and tw.Status = ''Active''
                                    and tw.DateEffective = (select  max(t.DateEffective)
                                                            from    #TbWorkhistory as t
                                                            where   t.ProfileID = tw.ProfileID
                                                                    and t.DateEffective <= yo.DateEnd
                                                                    and t.GroupType = ''GroupB''
                                                           )
                            ) as Branch
                cross apply (select count(distinct tw.ProfileID) as HeadCount
                             from   #TbWorkhistory as tw
                             where  tw.E_DIVISION_CODE = tou.E_DIVISION_CODE
                                    and tw.DateEffective <= yo.DateEnd
                                    and tw.GroupType = ''GroupB''
                                    and tw.Status = ''Active''
                                    and tw.DateEffective = (select  max(t.DateEffective)
                                                            from    #TbWorkhistory as t
                                                            where   t.ProfileID = tw.ProfileID
                                                                    and t.DateEffective <= yo.DateEnd
                                                                    and t.GroupType = ''GroupB''
                                                           )
                            ) as Division
                cross apply (select count(distinct tw.ProfileID) as HeadCount
                             from   #TbWorkhistory as tw
                             where  tw.E_DEPARTMENT_CODE = tou.E_DEPARTMENT_CODE
                                    and tw.DateEffective <= yo.DateEnd
                                    and tw.GroupType = ''GroupB''
                                    and tw.Status = ''Active''
                                    and tw.DateEffective = (select  max(t.DateEffective)
                                                            from    #TbWorkhistory as t
                                                            where   t.ProfileID = tw.ProfileID
                                                                    and t.DateEffective <= yo.DateEnd
                                                                    and t.GroupType = ''GroupB''
                                                           )
                            ) as Deparment
        ) as DataHC pivot ( max(HeadCount) for MonthYear in (' + @ListCol + ') ) pv;
print (''#TbHCGroupB'');

-- HeacountOT nhom B
select  ID
      , E_BRANCH_E
      , E_DIVISION_E
      , E_DEPARTMENT_E
      , ' + @ListAlilas + '
into    #TbHCOTGroupB
from    (select tou.*
              , yo.MonthYear
              , case when tou.E_DIVISION_E is null
                          and tou.E_DEPARTMENT_E is null then Branch.HeadCountOT
                     when tou.E_DEPARTMENT_E is null then Division.HeadCountOT
                     else Department.HeadCountOT
                end as HeadCountOT
         from   #TbOrgUnit as tou
                cross apply @YearOT as yo
                cross apply (select count(distinct tdo.ProfileID) as HeadCountOT
                             from   #TbDataOT as tdo
                             where  tdo.E_BRANCH_CODE = tou.E_BRANCH_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupB''
                            ) as Branch
                cross apply (select count(distinct tdo.ProfileID) as HeadCountOT
                             from   #TbDataOT as tdo
                             where  tdo.E_DIVISION_CODE = tou.E_DIVISION_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupB''
                            ) as Division
                cross apply (select count(distinct tdo.ProfileID) as HeadCountOT
                             from   #TbDataOT as tdo
                             where  tdo.E_DEPARTMENT_CODE = tou.E_DEPARTMENT_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupB''
                            ) as Department
        ) as DataOT pivot ( sum(HeadCountOT) for MonthYear in (' + @ListCol + ') ) as pv;
print (''#TbHCOTGroupB'');

-- OT nhom B
select  ID
      , E_BRANCH_E
      , E_DIVISION_E
      , E_DEPARTMENT_E
      , ' + @ListAlilas + '
into    #TbOTGroupB
from    (select tou.*
              , yo.MonthYear
              , case when tou.E_DIVISION_E is null
                          and tou.E_DEPARTMENT_E is null then Branch.OTHours
                     when tou.E_DEPARTMENT_E is null then Division.OTHours
                     else Department.OTHours
                end as OTHours
         from   #TbOrgUnit as tou
                cross apply @YearOT as yo
                cross apply (select sum(tdo.ConfirmHours) as OTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_BRANCH_CODE = tou.E_BRANCH_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupB''
                            ) as Branch
                cross apply (select sum(tdo.ConfirmHours) as OTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_DIVISION_CODE = tou.E_DIVISION_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupB''
                            ) as Division
                cross apply (select sum(tdo.ConfirmHours) as OTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_DEPARTMENT_CODE = tou.E_DEPARTMENT_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupB''
                            ) as Department
        ) as DataOT pivot ( sum(OTHours) for MonthYear in (' + @ListCol + ') ) as pv;
print (''#TbOTGroupB'');

-- AVG nhom B
select  ID
      , E_BRANCH_E
      , E_DIVISION_E
      , E_DEPARTMENT_E
      , ' + @ListAlilas + '
into    #TbAvgOTHoursGroupB
from    (select tou.ID
              , tou.E_BRANCH_E
              , tou.E_DIVISION_E
              , tou.E_DEPARTMENT_E
              , yo.MonthYear
              , case when tou.E_DIVISION_E is null
                          and tou.E_DEPARTMENT_E is null then Branch.AvgOTHours
                     when tou.E_DEPARTMENT_E is null then Division.AvgOTHours
                     else Department.AvgOTHours
                end as AvgOTHours
         from   #TbOrgUnit as tou
                cross apply @YearOT as yo
                cross apply (select sum(tdo.ConfirmHours) / count(distinct tdo.ProfileID) as AvgOTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_BRANCH_CODE = tou.E_BRANCH_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupB''
                            ) as Branch
                cross apply (select sum(tdo.ConfirmHours) / count(distinct tdo.ProfileID) as AvgOTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_DIVISION_CODE = tou.E_DIVISION_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupB''
                            ) as Division
                cross apply (select sum(tdo.ConfirmHours) / count(distinct tdo.ProfileID) as AvgOTHours
                             from   #TbDataOT as tdo
                             where  tdo.E_DEPARTMENT_CODE = tou.E_DEPARTMENT_CODE
                                    and tdo.MonthYear = yo.MonthYear
                                    and tdo.GroupType = ''GroupB''
                            ) as Department
        ) as DataOT pivot ( max(AvgOTHours) for MonthYear in (' + @ListCol
                + ') ) as pv;
print (''#TbAvgOTHoursGroupB'');


--SUM data nhom B
	SELECT 
			SUM(Data1) AS SUM_HCData1,SUM(Data2) AS SUM_HCData2,SUM(Data3) AS SUM_HCData3,SUM(Data4) AS SUM_HCData4,SUM(Data5) AS SUM_HCData5,SUM(Data6) AS SUM_HCData6
			,SUM(Data7) AS SUM_HCData7,SUM(Data8) AS SUM_HCData8,SUM(Data9) AS SUM_HCData9,SUM(Data10) AS SUM_HCData10,SUM(Data11) AS SUM_HCData11,SUM(Data12) AS SUM_HCData12
			,SUM(Data13) AS SUM_HCData13,SUM(Data14) AS SUM_HCData14,SUM(Data15) AS SUM_HCData15,SUM(Data16) AS SUM_HCData16,SUM(Data17) AS SUM_HCData17,SUM(Data18) AS SUM_HCData18
			,SUM(Data19) AS SUM_HCData19,SUM(Data20) AS SUM_HCData20,SUM(Data21) AS SUM_HCData21,SUM(Data22) AS SUM_HCData22,SUM(Data23) AS SUM_HCData23,SUM(Data24) AS SUM_HCData24
	INTO	#SUM_TbHCGroupB
	FROM	#TbHCGroupB
	WHERE	E_DIVISION_E IS NOT NULL AND E_DEPARTMENT_E IS NULL

	SELECT 
			SUM(Data1) AS SUM_HCOTData1,SUM(Data2) AS SUM_HCOTData2,SUM(Data3) AS SUM_HCOTData3,SUM(Data4) AS SUM_HCOTData4,SUM(Data5) AS SUM_HCOTData5,SUM(Data6) AS SUM_HCOTData6
			,SUM(Data7) AS SUM_HCOTData7,SUM(Data8) AS SUM_HCOTData8,SUM(Data9) AS SUM_HCOTData9,SUM(Data10) AS SUM_HCOTData10,SUM(Data11) AS SUM_HCOTData11,SUM(Data12) AS SUM_HCOTData12
			,SUM(Data13) AS SUM_HCOTData13,SUM(Data14) AS SUM_HCOTData14,SUM(Data15) AS SUM_HCOTData15,SUM(Data16) AS SUM_HCOTData16,SUM(Data17) AS SUM_HCOTData17,SUM(Data18) AS SUM_HCOTData18
			,SUM(Data19) AS SUM_HCOTData19,SUM(Data20) AS SUM_HCOTData20,SUM(Data21) AS SUM_HCOTData21,SUM(Data22) AS SUM_HCOTData22,SUM(Data23) AS SUM_HCOTData23,SUM(Data24) AS SUM_HCOTData24
	INTO	#SUM_TbHCOTGroupB
	FROM	#TbHCOTGroupB
	WHERE	E_DIVISION_E IS NOT NULL AND E_DEPARTMENT_E IS NULL
 
	SELECT 
			SUM(Data1) AS SUM_OTData1,SUM(Data2) AS SUM_OTData2,SUM(Data3) AS SUM_OTData3,SUM(Data4) AS SUM_OTData4,SUM(Data5) AS SUM_OTData5,SUM(Data6) AS SUM_OTData6
			,SUM(Data7) AS SUM_OTData7,SUM(Data8) AS SUM_OTData8,SUM(Data9) AS SUM_OTData9,SUM(Data10) AS SUM_OTData10,SUM(Data11) AS SUM_OTData11,SUM(Data12) AS SUM_OTData12
			,SUM(Data13) AS SUM_OTData13,SUM(Data14) AS SUM_OTData14,SUM(Data15) AS SUM_OTData15,SUM(Data16) AS SUM_OTData16,SUM(Data17) AS SUM_OTData17,SUM(Data18) AS SUM_OTData18
			,SUM(Data19) AS SUM_OTData19,SUM(Data20) AS SUM_OTData20,SUM(Data21) AS SUM_OTData21,SUM(Data22) AS SUM_OTData22,SUM(Data23) AS SUM_OTData23,SUM(Data24) AS SUM_OTData24
	INTO	#SUM_TbOTGroupB
	FROM	#TbOTGroupB
	WHERE	E_DIVISION_E IS NOT NULL AND E_DEPARTMENT_E IS NULL


-- bang du lieu nhom B nam N
select  ''GroupB_N'' as Type
      , hc.ID
      , hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E
	  , coalesce(char (9) + char (9) + hc.E_DEPARTMENT_E, char(9) + hc.E_DIVISION_E, hc.E_BRANCH_E) as OrgStructureName
      , hc.Data13 as HCData1
      , hc.Data14 as HCData2
      , hc.Data15 as HCData3
      , hc.Data16 as HCData4
      , hc.Data17 as HCData5
      , hc.Data18 as HCData6
      , hc.Data19 as HCData7
      , hc.Data20 as HCData8
      , hc.Data21 as HCData9
      , hc.Data22 as HCData10
      , hc.Data23 as HCData11
      , hc.Data24 as HCData12
      , hcot.Data13 as HCOTData1
      , hcot.Data14 as HCOTData2
      , hcot.Data15 as HCOTData3
      , hcot.Data16 as HCOTData4
      , hcot.Data17 as HCOTData5
      , hcot.Data18 as HCOTData6
      , hcot.Data19 as HCOTData7
      , hcot.Data20 as HCOTData8
      , hcot.Data21 as HCOTData9
      , hcot.Data22 as HCOTData10
      , hcot.Data23 as HCOTData11
      , hcot.Data24 as HCOTData12
      , ot.Data13 as OTData1
      , ot.Data14 as OTData2
      , ot.Data15 as OTData3
      , ot.Data16 as OTData4
      , ot.Data17 as OTData5
      , ot.Data18 as OTData6
      , ot.Data19 as OTData7
      , ot.Data20 as OTData8
      , ot.Data21 as OTData9
      , ot.Data22 as OTData10
      , ot.Data23 as OTData11
      , ot.Data24 as OTData12
      , avghour.Data13 as AvgOTData1
      , avghour.Data14 as AvgOTData2
      , avghour.Data15 as AvgOTData3
      , avghour.Data16 as AvgOTData4
      , avghour.Data17 as AvgOTData5
      , avghour.Data18 as AvgOTData6
      , avghour.Data19 as AvgOTData7
      , avghour.Data20 as AvgOTData8
      , avghour.Data21 as AvgOTData9
      , avghour.Data22 as AvgOTData10
      , avghour.Data23 as AvgOTData11
      , avghour.Data24 as AvgOTData12
	  , Accumulate.AccumulateHC_N
	  , Accumulate.AccumulateHCOT_N
	  , Accumulate.AccumulateOT_N
	  , Accumulate.AccumulateOT_N / 1.0 / nullif(Accumulate.AccumulateHCOT_N,0) as AccumulateAvgOTHours_N
	  , CASE WHEN hc.E_DEPARTMENT_E IS NULL THEN
			CASE
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NOT NULL THEN 1
			WHEN hc.E_DIVISION_E IS NOT NULL AND hc.E_BRANCH_E IS NOT NULL THEN 2
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NULL THEN 0 
			END
		ELSE 3 END AS ConditionFormat
	  , sumhc.SUM_HCData13 as SUM_HCData1
      , sumhc.SUM_HCData14 as SUM_HCData2
      , sumhc.SUM_HCData15 as SUM_HCData3
      , sumhc.SUM_HCData16 as SUM_HCData4
      , sumhc.SUM_HCData17 as SUM_HCData5
      , sumhc.SUM_HCData18 as SUM_HCData6
      , sumhc.SUM_HCData19 as SUM_HCData7
      , sumhc.SUM_HCData20 as SUM_HCData8
      , sumhc.SUM_HCData21 as SUM_HCData9
      , sumhc.SUM_HCData22 as SUM_HCData10
      , sumhc.SUM_HCData23 as SUM_HCData11
      , sumhc.SUM_HCData24 as SUM_HCData12
	  , sumhcot.SUM_HCOTData13 as SUM_HCOTData1
      , sumhcot.SUM_HCOTData14 as SUM_HCOTData2
      , sumhcot.SUM_HCOTData15 as SUM_HCOTData3
      , sumhcot.SUM_HCOTData16 as SUM_HCOTData4
      , sumhcot.SUM_HCOTData17 as SUM_HCOTData5
      , sumhcot.SUM_HCOTData18 as SUM_HCOTData6
      , sumhcot.SUM_HCOTData19 as SUM_HCOTData7
      , sumhcot.SUM_HCOTData20 as SUM_HCOTData8
      , sumhcot.SUM_HCOTData21 as SUM_HCOTData9
      , sumhcot.SUM_HCOTData22 as SUM_HCOTData10
      , sumhcot.SUM_HCOTData23 as SUM_HCOTData11
      , sumhcot.SUM_HCOTData24 as SUM_HCOTData12
	  , sumot.SUM_OTData13 as SUM_OTData1
      , sumot.SUM_OTData14 as SUM_OTData2
      , sumot.SUM_OTData15 as SUM_OTData3
      , sumot.SUM_OTData16 as SUM_OTData4
      , sumot.SUM_OTData17 as SUM_OTData5
      , sumot.SUM_OTData18 as SUM_OTData6
      , sumot.SUM_OTData19 as SUM_OTData7
      , sumot.SUM_OTData20 as SUM_OTData8
      , sumot.SUM_OTData21 as SUM_OTData9
      , sumot.SUM_OTData22 as SUM_OTData10
      , sumot.SUM_OTData23 as SUM_OTData11
      , sumot.SUM_OTData24 as SUM_OTData12

from    #TbHCGroupB as hc
        left join #TbHCOTGroupB as hcot on hcot.ID = hc.ID
        left join #TbOTGroupB as ot on ot.ID = hc.ID
        left join #TbAvgOTHoursGroupB as avghour on avghour.ID = hc.ID
		cross apply (
		 select isnull(hc.Data13,0)+isnull(hc.Data14,0)+isnull(hc.Data15,0)+isnull(hc.Data16,0)+isnull(hc.Data17,0)+isnull(hc.Data18,0)+isnull(hc.Data19,0)+isnull(hc.Data20,0)+isnull(hc.Data21,0)+isnull(hc.Data22,0)+isnull(hc.Data23,0)+isnull(hc.Data24,0) AccumulateHC_N
			  , isnull(hcot.Data13,0)+isnull(hcot.Data14,0)+isnull(hcot.Data15,0)+isnull(hcot.Data16,0)+isnull(hcot.Data17,0)+isnull(hcot.Data18,0)+isnull(hcot.Data19,0)+isnull(hcot.Data20,0)+isnull(hcot.Data21,0)+isnull(hcot.Data22,0)+isnull(hcot.Data23,0)+isnull(hcot.Data24,0) as AccumulateHCOT_N
			  , isnull(ot.Data13,0)+isnull(ot.Data14,0)+isnull(ot.Data15,0)+isnull(ot.Data16,0)+isnull(ot.Data17,0)+isnull(ot.Data18,0)+isnull(ot.Data19,0)+isnull(ot.Data20,0)+isnull(ot.Data21,0)+isnull(ot.Data22,0)+isnull(ot.Data23,0)+isnull(ot.Data24,0) as AccumulateOT_N
			) as Accumulate
		cross apply ( select * from #SUM_TbHCGroupB ) as sumhc
		cross apply ( select * from #SUM_TbHCOTGroupB ) sumhcot
		cross apply ( select * from #SUM_TbOTGroupB ) sumot
order by hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E;

-- bang du lieu nhom B nam N-1
select  ''GroupB_N-1'' as Type
      , hc.ID
      , hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E
	  , coalesce(char (9) + char (9) + hc.E_DEPARTMENT_E, char(9) + hc.E_DIVISION_E, hc.E_BRANCH_E) as OrgStructureName
      , hc.Data1 as HCData1
      , hc.Data2 as HCData2
      , hc.Data3 as HCData3
      , hc.Data4 as HCData4
      , hc.Data5 as HCData5
      , hc.Data6 as HCData6
      , hc.Data7 as HCData7
      , hc.Data8 as HCData8
      , hc.Data9 as HCData9
      , hc.Data10 as HCData10
      , hc.Data11 as HCData11
      , hc.Data12 as HCData12
      , hcot.Data1 as HCOTData1
      , hcot.Data2 as HCOTData2
      , hcot.Data3 as HCOTData3
      , hcot.Data4 as HCOTData4
      , hcot.Data5 as HCOTData5
      , hcot.Data6 as HCOTData6
      , hcot.Data7 as HCOTData7
      , hcot.Data8 as HCOTData8
      , hcot.Data9 as HCOTData9
      , hcot.Data10 as HCOTData10
      , hcot.Data11 as HCOTData11
      , hcot.Data12 as HCOTData12
      , ot.Data1 as OTData1
      , ot.Data2 as OTData2
      , ot.Data3 as OTData3
      , ot.Data4 as OTData4
      , ot.Data5 as OTData5
      , ot.Data6 as OTData6
      , ot.Data7 as OTData7
      , ot.Data8 as OTData8
      , ot.Data9 as OTData9
      , ot.Data10 as OTData10
      , ot.Data11 as OTData11
      , ot.Data12 as OTData12
      , avghour.Data1 as AvgOTData1
      , avghour.Data2 as AvgOTData2
      , avghour.Data3 as AvgOTData3
      , avghour.Data4 as AvgOTData4
      , avghour.Data5 as AvgOTData5
      , avghour.Data6 as AvgOTData6
      , avghour.Data7 as AvgOTData7
      , avghour.Data8 as AvgOTData8
      , avghour.Data9 as AvgOTData9
      , avghour.Data10 as AvgOTData10
      , avghour.Data11 as AvgOTData11
      , avghour.Data12 as AvgOTData12
	  , Accumulate.AccumulateHC_N1
	  , Accumulate.AccumulateHCOT_N1
	  , Accumulate.AccumulateOT_N1
	  , Accumulate.AccumulateOT_N1 / 1.0 / nullif(Accumulate.AccumulateHCOT_N1,0) as AccumulateAvgOTHours_N1
	  , CASE WHEN hc.E_DEPARTMENT_E IS NULL THEN
			CASE
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NOT NULL THEN 1
			WHEN hc.E_DIVISION_E IS NOT NULL AND hc.E_BRANCH_E IS NOT NULL THEN 2
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NULL THEN 0 
			END
		ELSE 3 END AS ConditionFormat
	  , sumhc.*
	  , sumhcot.*
	  , sumot.*
from    #TbHCGroupB as hc
        left join #TbHCOTGroupB as hcot on hcot.ID = hc.ID
        left join #TbOTGroupB as ot on ot.ID = hc.ID
        left join #TbAvgOTHoursGroupB as avghour on avghour.ID = hc.ID
		cross apply (
		 select isnull(hc.Data1,0)+isnull(hc.Data2,0)+isnull(hc.Data3,0)+isnull(hc.Data4,0)+isnull(hc.Data5,0)+isnull(hc.Data6,0)+isnull(hc.Data7,0)+isnull(hc.Data8,0)+isnull(hc.Data9,0)+isnull(hc.Data10,0)+isnull(hc.Data11,0)+isnull(hc.Data12,0) as AccumulateHC_N1
			  , isnull(hcot.Data1,0)+isnull(hcot.Data2,0)+isnull(hcot.Data3,0)+isnull(hcot.Data4,0)+isnull(hcot.Data5,0)+isnull(hcot.Data6,0)+isnull(hcot.Data7,0)+isnull(hcot.Data8,0)+isnull(hcot.Data9,0)+isnull(hcot.Data10,0)+isnull(hcot.Data11,0)+isnull(hcot.Data12,0) as AccumulateHCOT_N1
			  , isnull(ot.Data1,0)+isnull(ot.Data2,0)+isnull(ot.Data3,0)+isnull(ot.Data4,0)+isnull(ot.Data5,0)+isnull(ot.Data6,0)+isnull(ot.Data7,0)+isnull(ot.Data8,0)+isnull(ot.Data9,0)+isnull(ot.Data10,0)+isnull(ot.Data11,0)+isnull(ot.Data12,0) as AccumulateOT_N1
					) as Accumulate
		cross apply ( select * from #SUM_TbHCGroupB ) as sumhc
		cross apply ( select * from #SUM_TbHCOTGroupB ) sumhcot
		cross apply ( select * from #SUM_TbOTGroupB ) sumot
order by hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E;

 --bang du lieu so sanh nhom B


select  ''GroupB_N/N-1'' as Type
      , hc.ID
      , hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E
	  , coalesce(char (9) + char (9) + hc.E_DEPARTMENT_E, char(9) + hc.E_DIVISION_E, hc.E_BRANCH_E) as OrgStructureName
      , hc.Data13 / 1.0 / nullif(hc.Data1, 0) as HCData1
      , hc.Data14 / 1.0 / nullif(hc.Data2, 0) as HCData2
      , hc.Data15 / 1.0 / nullif(hc.Data3, 0) as HCData3
      , hc.Data16 / 1.0 / nullif(hc.Data4, 0) as HCData4
      , hc.Data17 / 1.0 / nullif(hc.Data5, 0) as HCData5
      , hc.Data18 / 1.0 / nullif(hc.Data6, 0) as HCData6
      , hc.Data19 / 1.0 / nullif(hc.Data7, 0) as HCData7
      , hc.Data20 / 1.0 / nullif(hc.Data8, 0) as HCData8
      , hc.Data21 / 1.0 / nullif(hc.Data9, 0) as HCData9
      , hc.Data22 / 1.0 / nullif(hc.Data10, 0) as HCData10
      , hc.Data23 / 1.0 / nullif(hc.Data11, 0) as HCData11
      , hc.Data24 / 1.0 / nullif(hc.Data12, 0) as HCData12
      , hcot.Data13 / 1.0 / nullif(hcot.Data1, 0) as HCOTData1
      , hcot.Data14 / 1.0 / nullif(hcot.Data2, 0) as HCOTData2
      , hcot.Data15 / 1.0 / nullif(hcot.Data3, 0) as HCOTData3
      , hcot.Data16 / 1.0 / nullif(hcot.Data4, 0) as HCOTData4
      , hcot.Data17 / 1.0 / nullif(hcot.Data5, 0) as HCOTData5
      , hcot.Data18 / 1.0 / nullif(hcot.Data6, 0) as HCOTData6
      , hcot.Data19 / 1.0 / nullif(hcot.Data7, 0) as HCOTData7
      , hcot.Data20 / 1.0 / nullif(hcot.Data8, 0) as HCOTData8
      , hcot.Data21 / 1.0 / nullif(hcot.Data9, 0) as HCOTData9
      , hcot.Data22 / 1.0 / nullif(hcot.Data10, 0) as HCOTData10
      , hcot.Data23 / 1.0 / nullif(hcot.Data11, 0) as HCOTData11
      , hcot.Data24 / 1.0 / nullif(hcot.Data12, 0) as HCOTData12
      , ot.Data13 / 1.0 / nullif(ot.Data1, 0) as OTData1
      , ot.Data14 / 1.0 / nullif(ot.Data2, 0) as OTData2
      , ot.Data15 / 1.0 / nullif(ot.Data3, 0) as OTData3
      , ot.Data16 / 1.0 / nullif(ot.Data4, 0) as OTData4
      , ot.Data17 / 1.0 / nullif(ot.Data5, 0) as OTData5
      , ot.Data18 / 1.0 / nullif(ot.Data6, 0) as OTData6
      , ot.Data19 / 1.0 / nullif(ot.Data7, 0) as OTData7
      , ot.Data20 / 1.0 / nullif(ot.Data8, 0) as OTData8
      , ot.Data21 / 1.0 / nullif(ot.Data9, 0) as OTData9
      , ot.Data22 / 1.0 / nullif(ot.Data10, 0) as OTData10
      , ot.Data23 / 1.0 / nullif(ot.Data11, 0) as OTData11
      , ot.Data24 / 1.0 / nullif(ot.Data12, 0) as OTData12
      , avghour.Data13 / 1.0 / nullif(avghour.Data1, 0) as AvgOTData1
      , avghour.Data14 / 1.0 / nullif(avghour.Data2, 0) as AvgOTData2
      , avghour.Data15 / 1.0 / nullif(avghour.Data3, 0) as AvgOTData3
      , avghour.Data16 / 1.0 / nullif(avghour.Data4, 0) as AvgOTData4
      , avghour.Data17 / 1.0 / nullif(avghour.Data5, 0) as AvgOTData5
      , avghour.Data18 / 1.0 / nullif(avghour.Data6, 0) as AvgOTData6
      , avghour.Data19 / 1.0 / nullif(avghour.Data7, 0) as AvgOTData7
      , avghour.Data20 / 1.0 / nullif(avghour.Data8, 0) as AvgOTData8
      , avghour.Data21 / 1.0 / nullif(avghour.Data9, 0) as AvgOTData9
      , avghour.Data22 / 1.0 / nullif(avghour.Data10, 0) as AvgOTData10
      , avghour.Data23 / 1.0 / nullif(avghour.Data11, 0) as AvgOTData11
      , avghour.Data24 / 1.0 / nullif(avghour.Data12, 0) as AvgOTData12
	  , Accumulate.AccumulateHC_N / 1.0 / nullif(Accumulate.AccumulateHC_N1, 0) as AccumulateHC
	  , Accumulate.AccumulateHCOT_N / 1.0 / nullif(Accumulate.AccumulateHCOT_N1, 0) as AccumulateHCOT
	  , Accumulate.AccumulateOT_N / 1.0 / nullif(Accumulate.AccumulateOT_N1, 0) as AccumulateOT
	  , (Accumulate.AccumulateOT_N / 1.0 / nullif(Accumulate.AccumulateHCOT_N,0)) / nullif((Accumulate.AccumulateOT_N1 / 1.0 / nullif(Accumulate.AccumulateHCOT_N1,0)),0) as AccumulateAvgOTHours
	  , CASE WHEN hc.E_DEPARTMENT_E IS NULL THEN
			CASE
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NOT NULL THEN 1
			WHEN hc.E_DIVISION_E IS NOT NULL AND hc.E_BRANCH_E IS NOT NULL THEN 2
			WHEN hc.E_DIVISION_E IS NULL AND hc.E_BRANCH_E IS NULL THEN 0 
			END
		ELSE 3 END AS ConditionFormat
from    #TbHCGroupB as hc
        left join #TbHCOTGroupB as hcot on hcot.ID = hc.ID
        left join #TbOTGroupB as ot on ot.ID = hc.ID
        left join #TbAvgOTHoursGroupB as avghour on avghour.ID = hc.ID
		cross apply (
		 select isnull(hc.Data1,0)+isnull(hc.Data2,0)+isnull(hc.Data3,0)+isnull(hc.Data4,0)+isnull(hc.Data5,0)+isnull(hc.Data6,0)+isnull(hc.Data7,0)+isnull(hc.Data8,0)+isnull(hc.Data9,0)+isnull(hc.Data10,0)+isnull(hc.Data11,0)+isnull(hc.Data12,0) as AccumulateHC_N1
			  , isnull(hc.Data13,0)+isnull(hc.Data14,0)+isnull(hc.Data15,0)+isnull(hc.Data16,0)+isnull(hc.Data17,0)+isnull(hc.Data18,0)+isnull(hc.Data19,0)+isnull(hc.Data20,0)+isnull(hc.Data21,0)+isnull(hc.Data22,0)+isnull(hc.Data23,0)+isnull(hc.Data24,0) AccumulateHC_N
			  , isnull(hcot.Data1,0)+isnull(hcot.Data2,0)+isnull(hcot.Data3,0)+isnull(hcot.Data4,0)+isnull(hcot.Data5,0)+isnull(hcot.Data6,0)+isnull(hcot.Data7,0)+isnull(hcot.Data8,0)+isnull(hcot.Data9,0)+isnull(hcot.Data10,0)+isnull(hcot.Data11,0)+isnull(hcot.Data12,0) as AccumulateHCOT_N1
			  , isnull(hcot.Data13,0)+isnull(hcot.Data14,0)+isnull(hcot.Data15,0)+isnull(hcot.Data16,0)+isnull(hcot.Data17,0)+isnull(hcot.Data18,0)+isnull(hcot.Data19,0)+isnull(hcot.Data20,0)+isnull(hcot.Data21,0)+isnull(hcot.Data22,0)+isnull(hcot.Data23,0)+isnull(hcot.Data24,0) as AccumulateHCOT_N
			  , isnull(ot.Data1,0)+isnull(ot.Data2,0)+isnull(ot.Data3,0)+isnull(ot.Data4,0)+isnull(ot.Data5,0)+isnull(ot.Data6,0)+isnull(ot.Data7,0)+isnull(ot.Data8,0)+isnull(ot.Data9,0)+isnull(ot.Data10,0)+isnull(ot.Data11,0)+isnull(ot.Data12,0) as AccumulateOT_N1
			  , isnull(ot.Data13,0)+isnull(ot.Data14,0)+isnull(ot.Data15,0)+isnull(ot.Data16,0)+isnull(ot.Data17,0)+isnull(ot.Data18,0)+isnull(ot.Data19,0)+isnull(ot.Data20,0)+isnull(ot.Data21,0)+isnull(ot.Data22,0)+isnull(ot.Data23,0)+isnull(ot.Data24,0) as AccumulateOT_N
					) as Accumulate
order by hc.E_BRANCH_E
      , hc.E_DIVISION_E
      , hc.E_DEPARTMENT_E;

drop table #TbPermission, #TbOrgUnit, #TbWorkhistory, #TbOvertime, #TbOvertimePlan, #TbDataOT, #TbHCGroupA, #TbHCOTGroupA, #TbOTGroupA, #TbAvgOTHoursGroupA, #TbHCGroupB, #TbHCOTGroupB, #TbOTGroupB, #TbAvgOTHoursGroupB;

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
        --dr_OTComparistion2Year
      end;

	  --dr_OTComparistion2Year
