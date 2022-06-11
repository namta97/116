  
alter proc [dbo].[dr_PrenancyRegisterList]  
      @Condition NVARCHAR(MAX) = " and (condi.Time between ''2021/07/01'' and ''2022/07/10'') and (cos.OrderNumber is not null) "  
    --@Condition varchar(max) = N' '  
    , @Username VARCHAR(100) = 'khang.nguyen'  
    , @PageIndex INT = 1  
    , @PageSize INT = 20  
AS  
      BEGIN  
            set nocount on;  

DECLARE @LanguageID VARCHAR(2)
SELECT @LanguageID = CASE WHEN Value1 = 'VN' THEN 0 ELSE 1 END 
FROM dbo.Sys_AllSetting WHERE Value2 = @Username AND Name = 'HRM_SYS_USERSETTING_LANGUAGE' AND IsDelete IS NULL 
ORDER BY DateUpdate DESC OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY

--SET @LanguageID = 1
            DECLARE @Top VARCHAR(20) = ' ';  
            DECLARE @CurrentEnd BIGINT;  
            DECLARE @Offset TINYINT;  
			DECLARE @index INT
-- Tach dieu kien  
            DECLARE @TempID VARCHAR(MAX);  
            DECLARE @TempCondition NVARCHAR(MAX);  
            DECLARE @TimeCondition VARCHAR(MAX);  
            DECLARE @TimeStart VARCHAR(20);  
            DECLARE @TimeEnd VARCHAR(20);  
            SET @TempCondition = REPLACE(@Condition, ',', '@');  
            SET @TempCondition = REPLACE(@TempCondition, 'and (', ',');  
          
            IF LTRIM(RTRIM(@Condition)) = ''  
               OR @Condition IS NULL  
               BEGIN  
                     SET @Top = ' top 0 ';  
               END;  
  
            SELECT  id  
            INTO    #SplitCondition  
            FROM    SPLIT_To_VARCHAR(@TempCondition);  
  
            WHILE (SELECT   COUNT(*)  
                   FROM     #SplitCondition  
                  ) > 0  
                  BEGIN  
                        SET @TempID = (SELECT TOP 1  
                                                id  
                                       FROM     #SplitCondition  
                                      );  
--Dieu kien @TimeCondition  
                        IF (SELECT  PATINDEX('%condi.Time%', @TempID)  
                           ) > 0  
                           BEGIN  
                                 SET @TempCondition = LTRIM(RTRIM(@TempID));  
                                 SET @TimeCondition = REPLACE(@TempCondition, '', '');  
                                 SET @TimeCondition = ('and (' + replace(@TimeCondition, '@', ','));  
                                 set @TimeStart = substring(@TimeCondition, patindex('%[0-9]%', @TimeCondition), 10);  
                                 set @TimeEnd = substring(@TimeCondition, len(@TimeCondition) - patindex('%[0-9]%', reverse(@TimeCondition)) - 8, 10);  
                                 SET @Condition = REPLACE(@Condition, @TimeCondition, '');  
                           END;  
                        DELETE  #SplitCondition  
                        WHERE   id = @TempID;  
                  END;  

				set @index = charindex('(ProfileName ','('+@tempID,0) 
				IF(@index > 0)
				BEGIN
				SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
				END

				SET @index = CHARINDEX('(CodeEmp ','('+@tempID,0) 
				IF(@index > 0)
				BEGIN
				SET @condition = REPLACE(@condition,'(CodeEmp ','(hp.CodeEmp ')
				END

				SET @index = CHARINDEX('(condi.PregnancyType ','('+@tempID,0) 
				IF(@index > 0)
				BEGIN
				SET @condition = REPLACE(@condition,'(condi.PregnancyType ','(apr.Type ')
				END


            drop table #SplitCondition;  
  
            --select  @TimeCondition as TimeCondition  
            --      , @TimeStart as TimeStart  
            --      , @TimeEnd as TimeEnd  
            --      , @Condition as Condition;  
            --return;  
  --dr_PrenancyRegisterList  
  
DECLARE @Getdata VARCHAR(MAX)
DECLARE @Query NVARCHAR(MAX)   

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
            SET @Query = N'   
-- ham phan quyen  
create table #TbPermission (ProfileID uniqueidentifier)  
insert into #TbPermission (ProfileID)  
exec Get_Data_Permission_New @UserName = ''' + @Username + ''', @ObjName = ''Att_PregnancyRegister''  
  
select  apr.ID  
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
		, hp.DateHire  
		, hp.DateQuit  
		, dbo.GETENUMVALUE(''PregnancyTypeRegister'', apr.Type, ''' + @Username + ''') as TypeName  
		, stuff((select   '','' + dbo.GETENUMVALUE(''PregnancyLateEarlyType'', stv.id, ''' + @Username + ''')  
				from     dbo.SPLIT_To_VARCHAR(apr.TypePregnancyEarly) as stv  
				for  
				xml path('''')  
				), 1, 1, '''') as TypePregnancyEarly  
		, apr.DateStart  
		, apr.DateEnd  
		, apr.ChildName  
		, apr.ChildBirthday  
		, lua.ProfileName AS UserApproveName
		, apr.DateApprove  
		, apr.Comment  
		, null as "cos.OrderNumber"  
		, null as "condi.Time"  
		, null as "condi.PregnancyType"  
		, t.StatusProfile as "t.StatusProfile"  
INTO	#Result
from    Att_PregnancyRegister apr  
        left join Hre_Profile hp on hp.ID = apr.ProfileID  
                                       and hp.IsDelete is null  
            cross apply (select case when hp.DateQuit <= getdate() then ''E_STOP''  
                                 else ''E_HIRE''  
                            end as StatusProfile  
                    ) as t  
        left join Cat_OrgStructure cos on cos.ID = apr.OrgStructureID and cos.IsDelete is null  
        left join Cat_OrgUnit cou on cou.OrgstructureID = apr.OrgStructureID  
        left join Cat_SalaryClass csc on csc.ID = apr.SalaryClassID  and csc.IsDelete is null  
        left join Cat_Position cp on cp.ID = apr.PositionID and cp.IsDelete is null  
        left join Cat_JobTitle cjt on cjt.ID = apr.JobTitleID  and cjt.IsDelete is null  
        left join Sys_UserInfo sui on sui.ID = apr.UserApproveID4 and sui.IsDelete is null  
        left join Hre_Profile lua on lua.ID = sui.ProfileID  and lua.IsDelete is null  
        left join Cat_WorkPlace cwp on cwp.ID = apr.WorkPlaceID and cwp.IsDelete is null  
        left join Cat_NameEntity cne on cne.ID = apr.EmployeeGroupID  and cne.IsDelete is null  
        left join Cat_EmployeeType cet on cet.ID = apr.EmployeeTypeID  and cet.IsDelete is null 
		LEFT JOIN #NameEnglishORG neorg ON neorg.OrgStructureID = apr.OrgStructureID

where   apr.IsDelete is null  
        and apr.Status = ''E_APPROVED''  
  and exists (select * from #TbPermission as p where p.ProfileID = apr.ProfileID)  
  and apr.DateStart <= ''' + ISNULL(@TimeEnd, '01/01/8888') + '''  
  and apr.DateEnd >= ''' + ISNULL(@TimeStart, '01/01/1990') + '''  
  ' + @Condition + '  


  
SELECT		ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName, UnitName, SalaryClassName, CodeEmp, DateEnd ) as STT,* 
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
        --dr_PrenancyRegisterList  
      end;  
  