  
  
  
ALTER proc [dbo].[dr_TimeLogList]  
      @Condition varchar(max) = " and (condi.TimeLog between '2022/04/06' and '2022/04/07')  "  
    , @Username varchar(100) = 'hrms_test03'  
    , @PageIndex int = 1  
    , @PageSize int = 20  
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
			DECLARE @index INT
-- Tach dieu kien  
            declare @TempID varchar(max);  
            declare @TempCondition varchar(max);  
            declare @TimeLogCondition varchar(max) = '';  
            declare @TypeCondition varchar(max) = '';  
            set @TempCondition = replace(@Condition, ',', '@');  
            set @TempCondition = replace(@TempCondition, 'and (', ',');  
			DECLARE @CodeEmp varchar(max) = '';  
  
            if ltrim(rtrim(@Condition)) = ''  
               or @Condition is null  
               begin  
                     set @Top = ' top 0 ';  
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
--Dieu kien @TimeLogCondition  
                        if (select  patindex('%condi.TimeLog%', @TempID)  
                           ) > 0  
                           begin  
                                 set @TempCondition = ltrim(rtrim(@TempID));  
                                 set @TimeLogCondition = replace(@TempCondition, '', '');  
                                 set @TimeLogCondition = ('and (' + replace(@TimeLogCondition, '@', ','));  
                                 set @Condition = replace(@Condition, @TimeLogCondition, '');  
                                 set @TimeLogCondition = replace(@TimeLogCondition, 'condi.TimeLog', 'Convert(date,TimeLog)');  
                           end;  

--Dieu kien @TypeCondition  
                        if (select  patindex('%TamScanLogType%', @TempID)  
                           ) > 0  
                           begin  
                                 set @TempCondition = ltrim(rtrim(@TempID));  
                                 set @TypeCondition = replace(@TempCondition, '', '');  
                                 set @TypeCondition = ('and (' + replace(@TypeCondition, '@', ','));  
                                 set @Condition = replace(@Condition, @TypeCondition, '');  
                           end;  

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
  
                        delete  #SplitCondition  
                        where   id = @TempID;  
                  end;  

            drop table #SplitCondition;  
  
            --select  @TimeLogCondition as TimeLogCondition  
            --      , @TypeCondition as TypeCondition  
            --      , @Condition as Condition;  
            --return;  
  --dr_TimeLogList  
  
  
  --select @TimeLogCondition, @TypeCondition , @Condition, @CodeEmp  


    
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
            set @Query = '   
-- ham phan quyen  
create table #TbPermission (ProfileID uniqueidentifier)  
insert into #TbPermission (ProfileID)  
exec Get_Data_Permission_New @UserName = ''' + @Username + ''', @ObjName = ''Hre_Profile''  
  
;  
with    TbTimeLog  
          as (select    ' + @Top + '  
      atsl.ID  
   , atsl.ProfileID  
                      , dbo.GETENUMVALUE(''TamScanLogType'', atsl.Type, ''' + @Username + ''') as TamScanLogType  
                      , format(atsl.TimeLog, ''dd/MM/yyyy'') as Date  
                      , format(atsl.TimeLog, ''HH:mm'') as Time  
					, atsl.TimeLog as realDate  
                      , CASE WHEN atsl.Status = ''E_LOADED'' THEN ''Machine'' ELSE ''Wifi'' END as "Mahine_Wifi"  
                      , atsl.MachineNo  
                      , null as WifiName  
                      , atsl.UserCreate  
                      , atsl.DateCreate  
              from      Att_TAMScanLog as atsl  
     left join hre_profile hp  
    on  hp.ID = atsl.ProfileID  
              where     atsl.IsDelete is null  
                        and (  
                             atsl.Status = ''E_LOADED''  
                             or atsl.Status is null  
                            )  
        ' + @TimeLogCondition + '  
        ' + @TypeCondition + '  
        '+ @CodeEmp+'  
              union all  
              select    ' + @Top + '  
      atsa.ID  
                      , atsa.ProfileID  
                      , dbo.GETENUMVALUE(''TamScanLogType'', atsa.Type, ''' + @Username + ''') as TamScanLogType  
                      , format(atsa.Timelog, ''dd/MM/yyyy'')  
                      , format(atsa.Timelog, ''HH:mm'')  
       , atsa.Timelog  
                      , ''Wifi'' as "Mahine_Wifi"  
                      , null as MachineNo  
                      , cw.WifiName  
                      , atsa.UserCreate  
                      , atsa.DateCreate  
              from      Att_TamScanApp as atsa  
                        left join Cat_Wifi cw on cw.ID = atsa.WifiID  
                                                    and cw.IsDelete is null  
     left join hre_profile hp  
    on  hp.ID = atsa.ProfileID  
              where     atsa.IsDelete is null  
        ' + @TimeLogCondition + '  
        ' + @TypeCondition + '  
        '+ @CodeEmp+'  
             )  
     select tl.ID  
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
			+N'          
		, csc.SalaryClassName  
          , cp.PositionName  
          , cjt.JobTitleName  
          , hp.DateHire  
          , hp.DateQuit  
          , tl.TamScanLogType   
          , tl.Date  
          , tl.Time  
          , tl.Mahine_Wifi  
          , tl.MachineNo  
          , tl.WifiName  
          , tl.UserCreate  
          , tl.DateCreate  
          , null as "cos.OrderNumber"  
          , null as "condi.TimeLog" 
    , tl.realDate 
    , t.StatusProfile as "t.StatusProfile" 

	INTO #Result
     from   TbTimeLog as tl  
            left join Hre_Profile hp on hp.ID = tl.ProfileID  
                                           and hp.IsDelete is null  
             cross apply (select case when hp.DateQuit <= getdate() then ''E_STOP''  
                                 else ''E_HIRE''  
                            end as StatusProfile  
                    ) as t  
            left join Cat_OrgStructure cos on cos.ID = hp.OrgStructureID   and cos.IsDelete is null
            left join Cat_OrgUnit cou on cou.OrgstructureID = hp.OrgStructureID
            left join Cat_SalaryClass csc on csc.ID = hp.SalaryClassID  and csc.IsDelete is null 
            left join Cat_Position cp on cp.ID = hp.PositionID   and cp.IsDelete is null
            left join Cat_JobTitle cjt on cjt.ID = hp.JobTitleID   and cjt.IsDelete is null  
			left join Cat_WorkPlace cwp on cwp.ID = hp.WorkPlaceID   and cwp.IsDelete is null  
            left join Cat_NameEntity cne on cne.ID = hp.EmployeeGroupID   and cne.IsDelete is null  
            left join Cat_EmployeeType cet on cet.ID = hp.EmpTypeID  and cet.IsDelete is null  
			LEFT JOIN #NameEnglishORG neorg ON neorg.OrgStructureID = hp.OrgStructureID
     where  1 = 1  
            and exists ( select * from   #TbPermission as p where  p.ProfileID = tl.ProfileID )  
   ' + @Condition + '  

   
SELECT		ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName, UnitName, SalaryClassName, CodeEmp, realDate desc) as STT,* 
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
            exec (@Getdata + @Query );  
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
        --dr_TimeLogList  
      end;  
  
  
  