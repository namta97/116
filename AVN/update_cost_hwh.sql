SELECT ID,ProfileID, ROW_NUMBER() OVER(PARTITION BY ProfileID ORDER BY DateEffective DESC,DateUpdate DESC) AS rk
INTO #nam
FROM dbo.Hre_WorkHistory 
WHERE DateEffective <= '2022-03-21'
AND IsDelete IS NULL
AND Status = 'E_APPROVED'


SELECT * 
INTO #nam_fi
FROM #nam WHERE rk =1


--SELECT * FROM #nam_fi


--SELECT b.CostCentreID,* FROM dbo.Hre_WorkHistory a INNER JOIN dbo.Hre_Profile b
--ON a.profileID = b.ID
--WHERE a.id IN ( SELECT ID FROM #nam_fi)


UPDATE a SET a.CostCentreID = b.CostCentreID FROM dbo.Hre_WorkHistory a INNER JOIN dbo.Hre_Profile b
ON a.profileID = b.ID
WHERE a.id IN ( SELECT ID FROM #nam_fi)



SELECT * FROM dbo.Cat_OrgStructure WHERE IsDelete IS NULL 

SELECT * FROM dbo.Cat_OrgStructure WHERE IsDelete IS NULL 



SELECT * FROM dbo.Hre_Profile a LEFT JOIN Cat_OrgStructure b ON a.OrgStructureID = b.ID WHERE a.IsDelete IS NULL AND a.OrgStructureID IS NULL


--UPDATE a SET a.CostCentreID = b.GroupCostCentreID FROM dbo.Hre_Profile a LEFT JOIN Cat_OrgStructure b ON a.OrgStructureID = b.ID WHERE a.IsDelete IS NULL AND a.costcentreid IS NULL and b.GroupCostCentreID is not null
 
 SELECT kkk.ID,* FROM dbo.Hre_Profile a
 OUTER APPLY ( SELECT TOP(1) * FROM dbo.Hre_WorkHistory b
				WHERE b.ProfileID = a.ID AND b.IsDelete IS NULL
				ORDER BY b.DateEffective DESC ) kkk

				WHERE a.IsDelete IS NULL AND a.CodeEmp = '20171121003'


		sELECT  * FROM dbo.Hre_WorkHistory b
				WHERE b.IsDelete IS NULL AND b.ProfileID = 'A2384C5F-F5B8-44D7-9EE4-B861392E53D0'


				

 UPDATE kkk SET kkk.CostCentreID = a.CostCentreID FROM dbo.Hre_Profile a
 OUTER APPLY ( SELECT TOP(1) * FROM dbo.Hre_WorkHistory b
				WHERE b.ProfileID = a.ID AND b.IsDelete IS NULL
				ORDER BY b.DateEffective DESC, b.DateUpdate desc ) kkk

				WHERE a.IsDelete IS NULL AND a.costcentreid  is not null and kkk.CostCentreID is null