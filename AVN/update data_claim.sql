
---- update claim chi phi

select * from Sal_PaymentCostRegister where ProfileID IN ( SELECT ID FROM dbo.Hre_Profile WHERE CodeEmp ='20220207002'  AND IsDelete IS NULL) and IsDelete is null and RequestMonthYear = '2022-05-01'

select * from Sal_PaymentCost where PaymentCostRegisterID = 'FCA6BB26-95D1-4DBB-96F9-69CD03798E52'


--update Sal_PaymentCostRegister set Status = 'E_APPROVED',SendEmailStatus = 'E_SUBMIT', UserApproveID2 = '1D9E11B6-253B-4497-A729-45B870D22210' where 
--ProfileID IN ( SELECT ID FROM dbo.Hre_Profile WHERE CodeEmp ='20220207002'  AND IsDelete IS NULL) and IsDelete is null and RequestMonthYear = '2022-05-01'

--update Sal_PaymentCostRegister set UserApproveID3 = UserApproveID2, UserApproveID4 = UserApproveID2, UserProcessID2 = UserApproveID2, UserProcessID3 = UserApproveID2, UserProcessID4 = UserApproveID2 where 
--ProfileID IN ( SELECT ID FROM dbo.Hre_Profile WHERE CodeEmp ='20220207002'  AND IsDelete IS NULL) and IsDelete is null and RequestMonthYear = '2022-05-01'



select * from Sal_PaymentCostRegister where ProfileID IN ( SELECT ID FROM dbo.Hre_Profile WHERE CodeEmp ='20220207002'  AND IsDelete IS NULL) and IsDelete is null and RequestMonthYear = '2022-05-01'


