SELECT 'aa' AS Name, NULL AS isdelete INTO #nam1


INSERT INTO #nam1 (Name,
isdelete) VALUES ('bb',NULL), ('cc',1)

SELECT * from #nam1


SELECT 'aa' AS Name,'toan' AS monhoc, NULL AS isdelete INTO #nam2


INSERT INTO #nam2 (Name,monhoc,
isdelete) VALUES ('bb','hoa',1), ('aa','sinh',1)

SELECT * from #nam1 a LEFT JOIN #nam2 b ON a.Name = b.Name 

SELECT * from #nam1 a LEFT JOIN #nam2 b ON a.Name = b.Name -- AND b.isdelete IS NULL
WHERE b.isdelete IS NULL

SELECT * from #nam1 a LEFT JOIN #nam2 b ON a.Name = b.Name  AND b.isdelete IS NULL


SELECT * from #nam1 

SELECT * from #nam2
