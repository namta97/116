
-- 25/04 : NamTa thêm xử lý xuất dữ liệu theo ngôn ngữ hệ thống. Sửa lại bố cục cho sạch

ALTER PROC [dbo].[dr_LeaveDayList]
       @Condition NVARCHAR(MAX) = " and (condi.Time between ''2022/04/01'' and ''2022/04/02'') "      
     , @Username VARCHAR(100) = 'khang.nguyen'      
     , @PageIndex INT = 1      
     , @PageSize INT = 20      
AS      
BEGIN      

SET NOCOUNT ON;     

DECLARE @LanguageID VARCHAR(2)
SELECT @LanguageID = CASE WHEN Value1 = 'VN' THEN 0 ELSE 1 END 
FROM dbo.Sys_AllSetting WHERE Value2 = @Username AND Name = 'HRM_SYS_USERSETTING_LANGUAGE' AND IsDelete IS NULL 
ORDER BY DateUpdate DESC OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY

--SET @LanguageID = 1



DECLARE @Top VARCHAR(20) = ' ';      
declare @CurrentEnd bigint;      
DECLARE @Offset TINYINT;      

if ltrim(rtrim(@Condition)) = ''      
or @Condition is null      
begin     
        --set @Top = ' top 0'
		SET @Condition = ' and (condi.Time between '''+CONVERT(VARCHAR(4),YEAR(GETDATE()) - 1)+'/04/01'' and '''+CONVERT(varchar(4),YEAR(GETDATE()))+'/03/31'') '
end;



-- Tach dieu kien      
DECLARE @TempID VARCHAR(MAX);      
declare @TempCondition nvarchar(max);      
declare @TimeCondition varchar(max);      
declare @TimeStart varchar(20);      
declare @TimeEnd varchar(20);      
set @TempCondition = replace(@Condition, ',', '@');      
set @TempCondition = replace(@TempCondition, 'and (', ',');      
 DECLARE @index INT

  SET @index = 0

SELECT id      
INTO   #SplitCondition      
FROM   SPLIT_To_VARCHAR(@TempCondition);      
      
WHILE (SELECT  COUNT(*)    FROM    #SplitCondition      
    ) > 0      
    BEGIN      
            SET @TempID = (SELECT TOP 1      
                                id      
                        FROM    #SplitCondition      
                        );      
--Dieu kien @TimeCondition   

IF (SELECT PATINDEX('%condi.Time%', @TempID)      
) > 0      
BEGIN      
        SET @TempCondition = LTRIM(RTRIM(@TempID));      
        SET @TimeCondition = REPLACE(@TempCondition, '', '');      
        SET @TimeCondition = ('and (' + REPLACE(@TimeCondition, '@', ','));      
        SET @TimeStart = SUBSTRING(@TimeCondition, PATINDEX('%[0-9]%', @TimeCondition), 10);      
        SET @TimeEnd = SUBSTRING(@TimeCondition, LEN(@TimeCondition) - PATINDEX('%[0-9]%', REVERSE(@TimeCondition)) - 8, 10);      
        SET @Condition = REPLACE(@Condition, @TimeCondition, '');      
END;      


	SET @index = CHARINDEX('(ProfileName ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
	END

	SET @index = CHARINDEX('(CodeEmp ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(CodeEmp ','(hp.CodeEmp ')
	END


DELETE #SplitCondition      
WHERE  id = @TempID;      
END;      
DROP TABLE #SplitCondition;    


DECLARE @Getdata VARCHAR(MAX)
DECLARE @Query NVARCHAR(MAX)   
DECLARE @Query2 NVARCHAR(MAX) 

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
SET @Query = '
-- ham phan quyen      
create table #TbPermission (ProfileID uniqueidentifier)      
insert into #TbPermission (ProfileID)      
exec Get_Data_Permission_New @UserName = ''' + @Username + ''', @ObjName = ''Att_LeaveDay''      
      
select       '+@Top+'
			ald.ID    
			, hp.CodeEmp, hp.ProfileName
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
			, csc.SalaryClassName, cp.PositionName, cjt.JobTitleName, cwp.WorkPlaceName, hp.DateHire, hp.DateQuit, cldt.LeaveDayTypeName
			, CASE WHEN cldt.IsAnnualLeave = 1 THEN A.Available END  AS LeaveDayBenefitTotal, format(ald.DateStart, ''dd/MM/yyyy'') as DateStart 
			
			, format(ald.DateEnd, ''dd/MM/yyyy'') as DateEnd
			, dbo.GETENUMVALUE(''LeaveDayDurationType'', ald.DurationType, ''' + @Username + ''') as DurationType
			--, cetl.VN  AS DurationType
			, case when ald.DurationType <> ''E_FULLSHIFT'' then format(ald.DateStart, ''HH:mm'') end as TimeStart
			, case when ald.DurationType <> ''E_FULLSHIFT'' then format(ald.DateEnd, ''HH:mm'') end as TimeEnd
			, ald.LeaveDays
			, CASE WHEN cldt.IsAnnualLeave = 1 THEN R.Remain - TLD.TotalLeaveDaysBefore END AS Remain 
			, ald.Comment
			, dbo.GETENUMVALUE(''LeaveDayStatus'', ald.Status, ''' + @Username + ''') as Status
			--, cetl2.VN as Status 
			, l4.ProfileName AS UserApproveName, ald.DateApprove
			, ald.DateStart AS DateStart_Order, null as "cos.OrderNumber", null as "condi.Time", null as "ald.LeaveDayTypeID", null as "hp.DateHire", null as "hp.DateQuit", t.StatusProfile as "t.StatusProfile"  
INTO		#Result
FROM		Att_LeaveDay ald      
left join	Hre_Profile hp on hp.ID = ald.ProfileID
cross apply (select case when hp.DateQuit <= getdate() then ''E_STOP''  else ''E_HIRE'' end as StatusProfile ) t 
left join	Cat_OrgStructure cos on cos.ID = ald.OrgStructureID
left join	Cat_OrgUnit cou on cou.OrgstructureID = ald.OrgStructureID
left join	Cat_SalaryClass csc on csc.ID = ald.SalaryClassID
left join	Cat_Position cp on cp.ID = ald.PositionID and cp.IsDelete is null
left join	Cat_JobTitle cjt on cjt.ID = ald.JobTitleID and cjt.IsDelete is null
left join	Sys_UserInfo s4 on s4.ID = ald.UserApproveID4 and s4.IsDelete is null
left join	Hre_Profile l4 on l4.ID = s4.ProfileID and l4.IsDelete is null
left join	Cat_WorkPlace cwp on cwp.ID = ald.WorkPlaceID and cwp.IsDelete is null
left join	Cat_NameEntity cne on cne.ID = ald.EmployeeGroupID and cne.IsDelete is null
left join	Cat_EmployeeType cet on cet.ID = ald.EmployeeTypeID and cet.IsDelete is null
left join	Cat_LeaveDayType cldt on cldt.ID = ald.LeaveDayTypeID and cldt.IsDelete is null
LEFT JOIN	#NameEnglishORG neorg ON neorg.OrgStructureID = ald.OrgStructureID
outer apply (
				select	coalesce(Remain,0) as Remain
				from	Att_AnnualDetail as aad      
				where	aad.IsDelete is null      
					and	aad.Type = ''E_ANNUAL_LEAVE''      
					and	aad.Year = year(ald.DateStart)      
					and	aad.MonthYear = (	select max(t.MonthYear)
										from   Att_AnnualDetail as t
										where  t.IsDelete is null      
											and t.Type = ''E_ANNUAL_LEAVE''      
											and t.Year = aad.Year      
									)      
					and	aad.ProfileID = ald.ProfileID      
					and	exists (select * from Cat_LeaveDayType p where p.IsDelete is null and p.ID = ald.LeaveDayTypeID and p.IsAnnualLeave = 1)      
			) as R
      
' SET @query2 ='      
outer apply (	select	coalesce(aad.Available, 0) as Available      
                from	Att_AnnualDetail as aad      
                where	aad.IsDelete is null      
                    and aad.Type = ''E_ANNUAL_LEAVE''      
                    and month(aad.MonthYear) = 1      
					and aad.Year = year(ald.DateStart)      
                    and aad.ProfileID = ald.ProfileID      
					--and exists (select * from Cat_LeaveDayType as p where p.IsDelete is null and p.ID = ald.LeaveDayTypeID and p.IsAnnualLeave = 1)      
            ) as A      
outer apply	(	select	coalesce(sum(TLD.LeaveDays), 0) as TotalLeaveDaysBefore      
                from	Att_LeaveDay as TLD      
                where	TLD.IsDelete is null      
                    and TLD.ProfileID = ald.ProfileID      
					and TLD.Status not in (''E_APPROVED'', ''E_REJECTED'', ''E_CANCEL'', ''E_CONFIRM'')      
					and exists (select * from Cat_LeaveDayType as p where p.IsDelete is null and p.ID = TLD.LeaveDayTypeID and p.IsAnnualLeave = 1)      
                    and year(TLD.DateStart) = year(ald.DateStart)      
            ) TLD      
      
outer apply (	select	top(1) cetl.VN 
				from	Cat_EnumTranslate cetl      
				where	cetl.EnumName = ''LeaveDayDurationType'' 
					and cetl.IsDelete is null      
					and cetl.EnumKey = ald.DurationType      
) cetl      
      
outer apply (	select	top(1) cetl.VN from Cat_EnumTranslate cetl      
				where	cetl.EnumName = ''LeaveDayStatus'' 
					and cetl.IsDelete is null      
					and cetl.EnumKey = ald.Status      
) cetl2      
         
where		ald.IsDelete is null      
			and ald.Status = ''E_APPROVED''      
			and ald.DateStart <= ''' + ISNULL(@TimeEnd, '01/01/8888') + '''      
			and ald.DateEnd >= ''' + ISNULL(@TimeStart, '01/01/1990') + '''      
			and exists (select * from #TbPermission as p where p.ProfileID = ald.ProfileID)      
			' + @Condition + ' 
			--and hp.COdeemp= ''20171121003''


SELECT		ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, SalaryClassName, CodeEmp, CONVERT(DATETIME,DateStart_Order,111) DESC ) as STT,* 
FROM		#Result
ORDER BY	STT


drop table #TbPermission, #Result
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

IF @i = 'Cat_LeaveDayType'
BEGIN
SET @strCondition += ', IsAnnualLeave '
END

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


exec (@Getdata + @Query + @query2);   

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
      
set @Query2 = replace(replace(@Query2, char(13) + char(10), char(10)), char(13), char(10));      
             while len(@Query2) > 1      
                   begin      
                         if charindex(char(10), @Query2) between 1 and 4000      
                            begin      
                                  set @CurrentEnd = charindex(char(10), @Query2) - 1;      
                                  set @Offset = 2;      
                            end;      
                         else      
                            begin      
                                  set @CurrentEnd = 4000;      
                                  set @Offset = 1;      
                            end;         
                         print substring(@Query2, 1, @CurrentEnd);       
                         set @Query2 = substring(@Query2, @CurrentEnd + @Offset, len(@Query2));         
                   end;  

        --dr_LeaveDayList      
end; 