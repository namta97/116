
-- 25/04 : NamTa thêm xử lý xuất dữ liệu theo ngôn ngữ hệ thống. Sửa lại bố cục cho sạch 
ALTER proc dr_ProfileOTByMonth  
@Condition varchar(max) = "  and (Year = 2021) and (Cos.OrderNumber is not null) and (ao.DurationType is not null ) ",
@Username varchar(100) = 'khang.nguyen',
@PageIndex int = 1, 
@PageSize int = 20  
as  
begin  
set nocount on;  

DECLARE @LanguageID VARCHAR(2)
SELECT @LanguageID = CASE WHEN Value1 = 'VN' THEN 0 ELSE 1 END 
FROM dbo.Sys_AllSetting WHERE Value2 = @Username AND Name = 'HRM_SYS_USERSETTING_LANGUAGE' AND IsDelete IS NULL 
ORDER BY DateUpdate DESC OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY

--SET @LanguageID = 1


declare @Top varchar(20) = ' ';  
declare @CurrentEnd bigint;  
declare @Offset tinyint;  
  
-- Tach dieu kien  
declare @TempID varchar(max);  
declare @TempCondition varchar(max);  
declare @YearCondition varchar(max) = '';  
declare @Year varchar(20) = '';  
declare @YearHeader varchar(200) = '';  
declare @YearFiscalHeader varchar(200) = '';  
  
declare @DurationTypeCondition varchar(max) = '';  
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
  
while (select count(*) FROM #SplitCondition ) > 0  
    begin  
		set @TempID = (select	TOP 1  id  
						FROM     #SplitCondition  
						);  
-- Dieu kien @YearCondition  
		IF (SELECT  PATINDEX('%Year%', @TempID)  
		) > 0  
		BEGIN  
				SET @TempCondition = LTRIM(RTRIM(@TempID));  
				SET @YearCondition = REPLACE(@TempCondition, '', '');  
				SET @YearCondition = ('and (' + REPLACE(@YearCondition, '@', ','));  
				SET @Year = SUBSTRING(@YearCondition, PATINDEX('%[0-9]%', @YearCondition), 4);  
				SET @Condition = REPLACE(@Condition, @YearCondition, '');  
		END;  
-- Dieu kien @DurationType  
		IF (SELECT  PATINDEX('%DurationType%', @TempID)  
			) > 0  
			BEGIN  
					SET @TempCondition = LTRIM(RTRIM(@TempID));  
					SET @DurationTypeCondition = REPLACE(@TempCondition, '', '');  
					SET @DurationTypeCondition = ('and (' + REPLACE(@DurationTypeCondition, '@', ','));  
					SET @Condition = REPLACE(@Condition, @DurationTypeCondition, '');  
			END;  
		DELETE  #SplitCondition  
		WHERE   id = @TempID;  
	END; 
	DROP table #SplitCondition;  
  
-- Lay cot Pivot  
declare @ListMonthYear varchar(max);  
declare @ListMonth varchar(max);  
declare @ListFiscal varchar(max);  
declare @firstmonth date = datefromparts(@Year, 01, 01);  
  
declare @YearOT table  
        (  
            MonthYear date  
        , DateStart date  
        , DateEnd date  
        );  

DECLARE @ListAlilas varchar(max);  
declare @Count int = 1;  
        while @firstmonth <= datefromparts(@Year + 1, 03, 01)  
                begin  
                    insert  into @YearOT  
                            (MonthYear)  
                    values  (@firstmonth);  
                    set @ListMonthYear = coalesce(@ListMonthYear + ',', '') + quotename(@firstmonth);  
					SET @ListAlilas = coalesce(@ListAlilas + ',', '') + quotename(@firstmonth) + ' as Month' + convert(varchar(10), @Count);  
                    set @firstmonth = dateadd(month, 1, @firstmonth);  
					SET @Count += 1;  
                end;  
  
UPDATE  @YearOT  
set     DateEnd = dateadd(day, 19, MonthYear);  
UPDATE  @YearOT  
set     DateStart = dateadd(day, 1, dateadd(month, -1, DateEnd));  
  
select  @ListMonth = coalesce(@ListMonth + ' + ', '') + 'isnull(' + quotename(yo.MonthYear) + ',0)'  
from    @YearOT as yo  
where   yo.MonthYear <= datefromparts(@Year, 12, 01);  
select  @ListFiscal = coalesce(@ListFiscal + ' + ', '') + 'isnull(' + +quotename(yo.MonthYear) + ',0)'  
from    @YearOT as yo  
where   yo.MonthYear >= datefromparts(@Year, 04, 01);  
  
        --select  @YearCondition as YearCondition  
        --      , @Year as Year  
        --      , @DurationTypeCondition as DurationTypeCondition  
        --      , @ListFiscal as ListFiscal  
        --      , @ListMonth as ListMonth  
        --      , @ListMonthYear as ListMonthYear  
        --      , @Condition as Condition;  
        --return;  
--dr_ProfileOTByMonth  
set @YearHeader = '01/' + @Year + ' - ' + '12/' + @Year   
set @YearFiscalHeader = '04/' + @Year + ' - ' + '03/' + convert( varchar(4),Year(datefromparts(@Year + 1, 03, 01)))  
  


DECLARE @Getdata VARCHAR(max)
declare @Query varchar(max); 

SET @Getdata = '
  -----Lay Ten tieng Anh Co cau truc thuoc-----------------

SELECT	OrgstructureID,E_BRANCH_CODE, E_UNIT_CODE, E_DIVISION_CODE, E_DEPARTMENT_CODE, E_TEAM_CODE
INTO	#UnitCode 
FROM	dbo.Cat_OrgUnit WHERE IsDelete IS NULL 

SELECT	a.ID AS OrgstructureID ,a.Code,a.OrderNumber, b.OrgStructureName, ROW_NUMBER() OVER(PARTITION BY a.Code ORDER BY a.DateUpdate DESC) AS rk	 
INTO	#NamEnglish1 
FROM	dbo.Cat_OrgStructure a LEFT JOIN dbo.Cat_OrgStructure_Translate b ON a.iD = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL

SELECT * INTO #NamEnglish FROM #NamEnglish1 WHERE rk= 1

SELECT		a.OrgstructureID, b.OrgStructureName AS DivisionName, c.OrgStructureName AS CenterName, d.OrgStructureName AS DepartmentName, e.OrgStructureName AS SectionName, f.OrgStructureName AS UnitName
			, b.OrderNumber AS DivisionOrder,  c.OrderNumber AS CenterOrder,  d.OrderNumber AS DepartmentOrder,  e.OrderNumber AS SectionOrder, f.OrderNumber AS UnitOrder
INTO		#NameEnglishORG
FROM		#UnitCode a
LEFT JOIN	#NamEnglish b
	ON		a.E_BRANCH_CODE = b.Code
LEFT JOIN	#NamEnglish c
	ON		a.E_UNIT_CODE = c.Code
LEFT JOIN	#NamEnglish d
	ON		a.E_DIVISION_CODE = d.Code
LEFT JOIN	#NamEnglish e
	ON		a.E_DEPARTMENT_CODE = e.Code
LEFT JOIN	#NamEnglish f
	ON		a.E_TEAM_CODE = f.Code

'


-- Query chinh  
set @Query = '   
-- ham phan quyen  
create table #TbPermission (ProfileID uniqueidentifier)  
insert into #TbPermission (ProfileID)  
exec Get_Data_Permission_New @UserName = ''' + @Username + ''', @ObjName = ''Att_Overtime''  
  
declare @Year varchar(4) = ' + @Year + ';  
declare @ListMonthYear varchar(max);  
declare @ListMonth varchar(max);  
declare @ListFiscal varchar(max);  
declare @firstmonth date = datefromparts(@Year, 01, 01);  
declare @YearOT table  ( MonthYear date, DateStart date, DateEnd date );  
 
while @firstmonth <= datefromparts(@Year + 1, 03, 01)  
      begin  
            insert  into @YearOT  
					(MonthYear)  
            values  (@firstmonth);  
            set @firstmonth = dateadd(month, 1, @firstmonth);  
      end;  
  
update  @YearOT  
set     DateEnd = dateadd(day, 19, MonthYear);  
update  @YearOT  
set     DateStart = dateadd(day, 1, dateadd(month, -1, DateEnd));  
  
;with    DataOT  
          as (select	ao.ProfileID  
                      , yo.MonthYear  
                      , ao.ConfirmHours  
              from      Att_Overtime as ao  
                        cross join @YearOT as yo  
              where     ao.IsDelete is null  
                        and ao.Status = ''E_CONFIRM''  
                        and ao.WorkDateRoot between yo.DateStart and yo.DateEnd  
						' + @DurationTypeCondition + '  
             )  
     select *  
     into   #TbPivotOT  
     from   DataOT pivot ( sum(ConfirmHours) for MonthYear in (' + @ListMonthYear + ') ) as pvot;  
  
select		hp.ID  
			, hp.CodeEmp  
			, hp.ProfileName  
			'+ CASE WHEN @LanguageID = 0 
			THEN',cou.E_BRANCH AS DivisionName ,cou.E_UNIT AS CenterName,cou.E_DIVISION AS DepartmentName,cou.E_DEPARTMENT AS SectionName,cou.E_TEAM AS UnitName
			'
			ELSE
			'
			,ISNULL(neorg.DivisionName,E_BRANCH) AS DivisionName ,ISNULL(neorg.CenterName,E_UNIT) AS CenterName, ISNULL(neorg.DepartmentName,E_DIVISION) AS DepartmentName 
			,ISNULL(neorg.SectionName,E_DEPARTMENT) AS SectionName,ISNULL(neorg.UnitName,E_TEAM) AS UnitName
			'
			END
			+'
			, csc.SalaryClassName  
			, cp.PositionName  
			, cjt.JobTitleName  
			, cwp.WorkPlaceName  
			, hp.DateHire  
			, hp.DateQuit  
			, ' + @ListAlilas + '  
			, ' + @ListMonth + ' as TotalYearOT  
			, ' + @ListFiscal + ' as TotalFiscalYearOT  
			, null as G2  
			, null as "hp.CodeEmp"  
			, null as "hp.ProfileName"  
			, null as "cos.OrderNumber"  
			, '+@year+' as "Year"  
			, '''+@YearHeader+'''  as YearHeader  
			, '''+@YearFiscalHeader+'''  as YearFiscalHeader  
			, null as "ao.DurationType"  
			, null as "hp.DateHire"  
			, null as "hp.DateQuit"  
			, t.StatusProfile as "t.StatusProfile"
INTO		#Result
from		#TbPivotOT as tpo  
left join	Hre_Profile as hp on hp.ID = tpo.ProfileID and hp.Isdelete is null  
cross apply (select case when hp.DateQuit <= datefromparts(@Year, 12, 31) then ''E_STOP''  
                            else ''E_HIRE''  
                    end as StatusProfile  
            ) as t  
left join	Cat_OrgStructure cos on cos.ID = hp.OrgStructureID  
                                        and cos.IsDelete is null  
left join	Cat_OrgUnit  cou on cou.OrgstructureID = hp.OrgStructureID  
left join	Cat_SalaryClass csc on csc.ID = hp.SalaryClassID  and csc.IsDelete is null  
left join	Cat_Position cp on cp.ID = hp.PositionID  and cp.IsDelete is null  
left join	Cat_JobTitle cjt on cjt.ID = hp.JobTitleID and cjt.IsDelete is null  
left join	Cat_WorkPlace cwp on cwp.ID = hp.WorkPlaceID and cwp.IsDelete is null  
left join	Cat_NameEntity cne on cne.ID = hp.EmployeeGroupID and cne.IsDelete is null  
left join	Cat_EmployeeType cet on cet.ID = hp.EmpTypeID and cet.IsDelete is null 
LEFT JOIN	#NameEnglishORG neorg ON neorg.OrgStructureID = hp.OrgStructureID

where		1 = 1  
	and		exists (select * from #TbPermission as p where p.ProfileID = tpo.ProfileID)  
			' + @Condition + '  
			--and hp.COdeemp= ''20171121003''


SELECT		ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, SalaryClassName, CodeEmp ) as STT,* 
FROM		#Result
ORDER BY	STT

 drop table #TbPivotOT, #TbPermission, #Result
 DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
 ';  
  


DECLARE @Strlang VARCHAR(5) = CAST(@LanguageID AS CHAR(1));  
IF (@LanguageID > 0  AND EXISTS   
	(  
	SELECT 1  
	FROM dbo.Sys_AllSetting  
	WHERE IsDelete IS NULL  
	AND Name = 'HRM_SYS_CATEGORYTRANSLATIONCONFIGURATION'  
	AND Value1 = 'True'  
	)
)
 
BEGIN  
DECLARE @queryWhereLang NVARCHAR(MAX) = @Query;  
BEGIN TRY  

SELECT		ColumnName, TableDefault, TableTranslate  
INTO		#TableColumnTranslate  
FROM		dbo.View_GetTableTranslate

SELECT		ColumnName, TableDefault, TableTranslate  
INTO		#tblTempTranslate  
FROM		#TableColumnTranslate  
WHERE		@Query LIKE '%' + TableDefault + '%'
	AND		TableDefault <> 'Cat_EnumTranslate'

DECLARE @strCondition VARCHAR(MAX) = NULL;  
DECLARE @strConditionTranslate VARCHAR(500) = NULL;  

WHILE (EXISTS (SELECT 1 FROM #tblTempTranslate))  
BEGIN  
DECLARE @i VARCHAR(100) =  
( SELECT TOP (1) TableDefault FROM #tblTempTranslate 
)

SET @strCondition = NULL;  
SET @strConditionTranslate = NULL;  

SELECT		@strConditionTranslate = COALESCE(@strConditionTranslate + ',', '') + cb.ColumnName  
FROM		#tblTempTranslate cb  
WHERE		cb.TableDefault = @i;

--- Lay ít cột cho đỡ rối, nếu cần cột thêm thì làm tương tự bên dưới IF
SET	@strCondition = 'ID, Code, ISNULL(ColumnCustom.' + @strConditionTranslate + ', ColumnDefault.'+@strConditionTranslate+') AS '+@strConditionTranslate+',IsDelete'

IF @i = 'Cat_OrgStructure'
BEGIN
SET @strCondition += ', OrderNumber '
END

DECLARE @sqlQueryCustom VARCHAR(MAX)  

SET @sqlQueryCustom= N' 
(
SELECT	'+ @strCondition + N' 
FROM	dbo.' + @i + ' ColumnDefault WITH(NOLOCK) 
LEFT JOIN (SELECT OriginID, ' + @strConditionTranslate+ ' FROM dbo.' + @i + '_Translate WHERE IsDelete IS NULL AND LanguageID = ' +@Strlang+ ' ) ColumnCustom 
	ON	ColumnCustom.OriginID = ColumnDefault.ID WHERE ColumnDefault.IsDelete IS null 
) ';  
SET @Query = ( SELECT dbo.RegexReplaceTable(@Query, @i, @sqlQueryCustom) );  

DELETE #tblTempTranslate  
WHERE TableDefault = @i;  
END;  
DROP TABLE #tblTempTranslate,  
#TableColumnTranslate;  
END TRY  
BEGIN CATCH  
SET @Query = @queryWhereLang; 
END CATCH; 
END;  

  
exec (@Getdata + @Query);  
PRINT(@Getdata)

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
        --dr_ProfileOTByMonth  
end;  