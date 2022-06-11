using HRM.Business.Attendance.Models;
using HRM.Business.Category.Models;
using HRM.Business.Hr.Models;
using HRM.Business.HrmSystem.Models;
using HRM.Business.Main.Domain;
using HRM.Business.Payroll.Models;
using HRM.Data.BaseRepository;
using HRM.Data.Entity;
using HRM.Infrastructure.Utilities;
using System;
using System.Collections.Generic;
using System.Linq;
using HRM.Infrastructure.Utilities.Helper;
using HRM.Business.Insurance.Models;
using HRM.Business.Evaluation.Models;
using VnResource.Helper.Data;
using HRM.Business.HrmSystem.Domain;
using VnResource.Helper.Setting;
using VnResource.Helper.Linq;
using System.Threading.Tasks;
using VnResource.Helper.Ado;
using VnResource.AdoHelper;
using HRM.Business.Canteen.Models;
using HRM.Business.Category.Domain;
using HRM.Business.Hr.Domain;
using HRM.Business.Attendance.Domain;
using System.Threading;
using System.Data;

namespace HRM.Business.Payroll.Domain
{
    public class Sal_GetStaticValuesKZServices : BaseService
    {
        ElementFormula item = new ElementFormula();

        private Sal_GetDataComputePayrollKZServices dataComputeSer = new Sal_GetDataComputePayrollKZServices();
        private Sal_ComputePayrollKZServices computePayrollSer = new Sal_ComputePayrollKZServices();

        #region Tinh giá trị cho các phần tử sử dụng enum ngày
        public List<ElementFormula> ParseElementFormulaByDay(
            ComputePayrollDataModelKZAll TotalDataAll
            , List<ElementFormula> listElementFormulaByDay
            , List<Cat_ElementEntity> listGradeElementByDay
            , ComputePayrollDataModelKZ TotalData
            , Hre_ProfileEntity profileItem
            , Att_CutOffDurationEntity CutOffDuration
            , Att_CutOffDurationEntity CutOffDurationPayBack
            , Sal_GradeEntity GradeElement
            , Dictionary<Guid, ValueCount> listTmpDeduction
            , bool ComputeOrderNumber
            )
        {
            //lấy bảng công của nv trong tháng tính lương
            Att_AttendanceTableEntity objAttendanceTableProCut = new Att_AttendanceTableEntity();

            objAttendanceTableProCut = TotalDataAll.dicAttendanceTable
            .GetValueOrNew(profileItem.ID)
            .Where(m => ((m.CutOffDurationID == CutOffDuration.ID) || (m.CutOffDurationID == null && m.DateStart <= CutOffDuration.DateEnd && m.DateEnd >= CutOffDuration.DateStart)))
            .FirstOrDefault();

            //Lấy các phần tử tính lương nằm trong Grade của nhân viên
            if (GradeElement == null)
            {
                GradeElement = computePayrollSer.FindGradePayrollByProfileAndMonthYear(TotalDataAll.dicGrade, profileItem.ID, CutOffDuration.DateStart, CutOffDuration.DateEnd);
            }

            #region Cho các phần tử ngày gọi lại với nhau
            //lấy all enum trong công thức ngày => rồi đi lấy giá trị 1 lần => sau đó tính cho từng công thức 
            List<string> ListFormula = new List<string>();
            foreach (var elementItem in listGradeElementByDay)
            {
                try
                {
                    string strFormula = elementItem.Formula.Replace("[Source]", "").Replace("[Value]", "");
                    //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                    ListFormula.AddRange(Common.ParseFormulaToList(strFormula).Where(m => m.IndexOf('[') != -1 && m.IndexOf(']') != -1).ToList());
                }
                catch (Exception ex)
                {
                    TotalData.strErrMesageByDay += "ParseFormulaToList: Code employee: " + profileItem.CodeEmp
                              + "; Code Emlement: " + elementItem.ElementCode
                              + "; Fomular: " + elementItem.Formula
                              + "; error: " + ex.Message + ex.StackTrace;
                }
            }
            //Các phần tử tính lương chưa có kết quả
            ListFormula = ListFormula.Select(s => s = s.Replace("[", "").Replace("]", "")).Distinct().ToList();

            //tính cho các enum hệ thống trước (enum theo tháng)
            listElementFormulaByDay = computePayrollSer.GetStaticValues(
                TotalDataAll,
                TotalData,
                listElementFormulaByDay,
                profileItem,
                CutOffDuration,
                CutOffDurationPayBack,
                ListFormula,
                GradeElement.GradePayrollID,
                objAttendanceTableProCut,
                listTmpDeduction,
                null);

            //tinh gia tri cho cong thuc theo ngay
            listElementFormulaByDay = GetStaticValuesByDay(
                TotalDataAll
                , TotalData
                , listElementFormulaByDay
                , profileItem
                , CutOffDuration
                , ListFormula
                , GradeElement.GradePayrollID
                , objAttendanceTableProCut
                , listTmpDeduction
                );

            if (ComputeOrderNumber)
            {
                listGradeElementByDay = listGradeElementByDay.OrderBy(m => m.OrderNumber).ToList();
                foreach (var elementItem in listGradeElementByDay)
                {
                    try
                    {
                        //tính cho công thức dạng mảng
                        var result = FormulaHelper.ParseFormula(elementItem.Formula, listElementFormulaByDay);
                        //them kết quả để dùng lại tính cho các phần tử thường
                        listElementFormulaByDay.Add(new ElementFormula(elementItem.ElementCode, result.Value, 0, result.ErrorMessage));
                    }
                    catch (Exception ex)
                    {
                        TotalData.strErrMesageByDay += "ComputeOrderNumber ParseFormula: Code employee: " + profileItem.CodeEmp
                              + "; Code Emlement: " + elementItem.ElementCode
                              + "; Fomular: " + elementItem.Formula
                              + "; error: " + ex.Message + ex.StackTrace;
                    }
                }
            }
            else
            {
                foreach (var elementItem in listGradeElementByDay)
                {
                    try
                    {
                        listElementFormulaByDay = ParseFormulaByDay(elementItem, listElementFormulaByDay, TotalData, profileItem, CutOffDuration, GradeElement.GradePayrollID, objAttendanceTableProCut, listTmpDeduction);
                    }
                    catch (Exception ex)
                    {
                        TotalData.strErrMesageByDay += "ParseFormulaByDay: Code employee: " + profileItem.CodeEmp
                            + "; Code Emlement: " + elementItem.ElementCode
                            + "; Fomular: " + elementItem.Formula
                            + "; error: " + ex.Message + ex.StackTrace;
                    }
                }
            }
            #endregion

            return listElementFormulaByDay.Where(s => s.VariableName != "Source").Distinct().ToList();
        }

        public List<ElementFormula> ParseFormulaByDay(Cat_ElementEntity formula, List<ElementFormula> listElementFormulaByDay, ComputePayrollDataModelKZ TotalData, Hre_ProfileEntity profileItem, Att_CutOffDurationEntity CutOffDuration, Guid? GradePayrollID, Att_AttendanceTableEntity objAttendanceTableProCut, Dictionary<Guid, ValueCount> listTmpDeduction)
        {
            string strFormula = formula.Formula.Replace("[Source]", "").Replace("[Value]", "");

            //Các phần tử tính lương tách ra từ 1 chuỗi công thức
            List<string> ListFormula = Common.ParseFormulaToList(strFormula).Where(m => m.IndexOf('[') != -1 && m.IndexOf(']') != -1).ToList();

            //Các phần tử tính lương chưa có kết quả
            ListFormula = ListFormula.Select(s => s = s.Replace("[", "").Replace("]", "")).ToList();
            List<string> ListFormulaNotValue = ListFormula.Where(m => !TotalData.listAllColumnInSource.Contains(m) && !listElementFormulaByDay.Any(t => t.VariableName == m)).ToList();

            //có phần tử chưa được tính trước đó
            if (ListFormulaNotValue != null && ListFormulaNotValue.Count > 0)
            {
                //Các phần tử tính lương chưa có kết quả
                List<string> ListEnumNotValue = ListFormulaNotValue.ToList();

                foreach (string elementNotValue in ListFormulaNotValue)
                {
                    //kiểm tra phần tử đó là phần tử Enum hay là phần tử công thức
                    if (TotalData.listElementByDay.Any(m => m.ElementCode == elementNotValue))//là phần tử công thức
                    {
                        listElementFormulaByDay = ParseFormulaByDay(TotalData.listElementByDay.Where(m => m.ElementCode == elementNotValue).FirstOrDefault(), listElementFormulaByDay, TotalData, profileItem, CutOffDuration, GradePayrollID, objAttendanceTableProCut, listTmpDeduction);
                    }
                    else//là phần tử enum
                    {
                        try
                        {
                            var resultByEnum = FormulaHelper.ParseFormula(formula.Formula, listElementFormulaByDay.Distinct().ToList());
                            listElementFormulaByDay.Add(new ElementFormula(formula.ElementCode, resultByEnum.Value, 0, resultByEnum.ErrorMessage));
                        }
                        catch (Exception ex)
                        {
                            throw new Exception(elementNotValue + "," + ex.Message);
                        }
                    }
                }
            }

            var result = FormulaHelper.ParseFormula(formula.Formula, listElementFormulaByDay.Distinct().ToList());
            listElementFormulaByDay.Add(new ElementFormula(formula.ElementCode, result.Value, 0, result.ErrorMessage));
            return listElementFormulaByDay.Distinct().ToList();
        }


        //Ham tinh gia tri cho các phần tử sử dụng hàm và enum ngày để tính
        public List<ElementFormula> GetStaticValuesByDay(
            ComputePayrollDataModelKZAll TotalDataAll
            , ComputePayrollDataModelKZ TotalData
            , List<ElementFormula> listElementFormulaByDay
            , Hre_ProfileEntity profileItem
            , Att_CutOffDurationEntity CutOffDuration
            , List<string> formula
            , Guid? GradePayrollID
            , Att_AttendanceTableEntity objAttendanceTableProCut
            , Dictionary<Guid, ValueCount> listTmpDeduction
            )
        {
            if (objAttendanceTableProCut == null)
            {
                objAttendanceTableProCut = new Att_AttendanceTableEntity();
            }
            //ds tất cả các enum và giá trị từng ngày cho từng enum
            List<ColumnByDay> listColumnByDay = new List<ColumnByDay>();
            string strDouble = "Double";
            string strDateTime = "DateTime";
            string strString = "String";
            List<Att_AttendanceTableItemEntity> listAttendanceTableItem = new List<Att_AttendanceTableItemEntity>();

            listAttendanceTableItem = TotalDataAll.dicAttendanceTableItem
                .GetValueOrNew(objAttendanceTableProCut.ID)
                .OrderBy(s => s.WorkDate)
                .ToList();
            //tổng số dòng trong table
            int totalRowInDataSoure = listAttendanceTableItem.Count;

            #region Enum

            #region so phu tre som 96183
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EARLYOUTMINUTES_BYDAY.ToString(), PayrollElementByDay.LATEINMINUTES_BYDAY.ToString() }))
            {
                string columnEARLYOUTMINUTES_BYDAY = PayrollElementByDay.EARLYOUTMINUTES_BYDAY.ToString();
                string columLATEINMINUTES_BYDAY = PayrollElementByDay.LATEINMINUTES_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columnEARLYOUTMINUTES_BYDAY;
                objColumnByDay.ValueType = "Double";
                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                ColumnByDay objColumnByDayEarly = new ColumnByDay();
                objColumnByDayEarly.ColumnName = columLATEINMINUTES_BYDAY;
                objColumnByDayEarly.ValueType = strDouble;
                Dictionary<int, string> listValueByDayEarly = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, objAttendanceTableItem.EarlyOutMinutes.ToString());
                    }
                    if (!listValueByDayEarly.ContainsKey(indexRow))
                    {
                        listValueByDayEarly.Add(indexRow, objAttendanceTableItem.LateInMinutes.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueByDay;
                objColumnByDayEarly.ListValueByDay = listValueByDayEarly;
                listColumnByDay.Add(objColumnByDay);
                listColumnByDay.Add(objColumnByDayEarly);
            }
            #endregion

            #region Thu trong tuần 
            //[09/07/2018][bang.nguyen][96518][modify]
            //Thứ trong tuần theo quy định (CN, T2, T3, T4, T5, T6, T7) tương ứng (0, 1, 2, 3, 4, 5, 6, 7)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.INDEXDAYOFWEEK_BYDAY.ToString()))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.INDEXDAYOFWEEK_BYDAY.ToString();
                objColumnByDay.ValueType = "Double";
                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                int indexRow = 0;
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string strIndexDayOfWeek = string.Empty;
                    if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Sunday)
                    {
                        strIndexDayOfWeek = "1";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Monday)
                    {
                        strIndexDayOfWeek = "2";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Tuesday)
                    {
                        strIndexDayOfWeek = "3";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Wednesday)
                    {
                        strIndexDayOfWeek = "4";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Thursday)
                    {
                        strIndexDayOfWeek = "5";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Friday)
                    {
                        strIndexDayOfWeek = "6";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Saturday)
                    {
                        strIndexDayOfWeek = "7";
                    }
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, strIndexDayOfWeek);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region nhom nhan vien 96518
            //[09/07/2018][bang.nguyen][96518][modify]
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EMPLOYEETYPE_BYDAY.ToString()))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.EMPLOYEETYPE_BYDAY.ToString();
                objColumnByDay.ValueType = strString;
                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                int indexRow = 0;
                var listWorkHistory = TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID);
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string employeeTypeCode = string.Empty;
                    var objWorkHistory = listWorkHistory.Where(s => s.DateEffective <= objAttendanceTableItem.WorkDate).OrderByDescending(s => s.DateEffective).FirstOrDefault();
                    if (objWorkHistory != null && !string.IsNullOrEmpty(objWorkHistory.EmployeeTypeCode))
                    {
                        employeeTypeCode = objWorkHistory.EmployeeTypeCode;
                    }
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, employeeTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion
            #region Nghia.Dang [06102020][0119559] Modify thêm enum tính lương theo ngày 
            //[6/10/2020][nghia.dang][119559][modify] 
            // Khoa.nguyen [07/10/2020] 119675 Enum Loại lao động: phần tử ngày
            //[14/12/2020][nghia.dang] [122090] [modify] 0122090: [OCEAN] Modify lấy thêm phần tử lương tính theo ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.ORGANIZATIONSTRCTURECODE_BYDAY.ToString(),
                PayrollElementByDay.HRE_WORKHISTORY_LABORTYPE_BYDAY.ToString(),
                PayrollElementByDay.HRE_WORKHISTORY_POSITIONNAME_BYDAY.ToString(),
                PayrollElementByDay.HRE_WORKHISTORY_POSITIONCODE_BYDAY.ToString(),
                }))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.ORGANIZATIONSTRCTURECODE_BYDAY.ToString();
                objColumnByDay.ValueType = strString;

                ColumnByDay objColumnLaborTypeByDay = new ColumnByDay();
                objColumnLaborTypeByDay.ColumnName = PayrollElementByDay.HRE_WORKHISTORY_LABORTYPE_BYDAY.ToString();
                objColumnLaborTypeByDay.ValueType = strString;
                //[14/12/2020][nghia.dang] [122090] [modify] 0122090: [OCEAN] Modify lấy thêm phần tử lương tính theo ngày
                ColumnByDay objColumnPositionNameByDay = new ColumnByDay();
                objColumnPositionNameByDay.ColumnName = PayrollElementByDay.HRE_WORKHISTORY_POSITIONNAME_BYDAY.ToString();
                objColumnPositionNameByDay.ValueType = strString;

                ColumnByDay objColumnPositionCodeByDay = new ColumnByDay();
                objColumnPositionCodeByDay.ColumnName = PayrollElementByDay.HRE_WORKHISTORY_POSITIONCODE_BYDAY.ToString();
                objColumnPositionCodeByDay.ValueType = strString;
                //end

                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                Dictionary<int, string> listLaborTypeValueByDay = new Dictionary<int, string>();

                Dictionary<int, string> listPositionNameValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listPositionCodeValueByDay = new Dictionary<int, string>();

                int indexRow = 0;
                var listWorkHistory = TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID);
                var listOrg = TotalDataAll.listOrgStructure;
                var listPosition = TotalDataAll.listPosition;
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string orgStructureCode = string.Empty;
                    string laborType = string.Empty;
                    string positionName = string.Empty;
                    string positionCode = string.Empty;
                    var objWorkHistory = listWorkHistory.Where(s => s.DateEffective <= objAttendanceTableItem.WorkDate && s.Status == "E_APPROVED").OrderByDescending(s => s.DateEffective).FirstOrDefault();

                    #region Kiểm tra dữ liệu từng phần tử
                    if (objWorkHistory != null && objWorkHistory.OrganizationStructureID != Guid.Empty && objWorkHistory.OrganizationStructureID != null)
                    {
                        var orgStructure = listOrg.Where(x => x.ID == objWorkHistory.OrganizationStructureID).FirstOrDefault();
                        if (orgStructure != null && orgStructure.Code != null)
                        {
                            orgStructureCode = orgStructure.Code;
                        }
                    }
                    if (objWorkHistory != null && !string.IsNullOrEmpty(objWorkHistory.LaborType))
                    {
                        laborType = objWorkHistory.LaborType;
                    }
                    //[14/12/2020][nghia.dang] [122090] [modify] 0122090: [OCEAN] Modify lấy thêm phần tử lương tính theo ngày
                    if (objWorkHistory != null && objWorkHistory.PositionID != Guid.Empty && objWorkHistory.PositionID != null)
                    {
                        var objPosition = listPosition.Where(x => x.ID == objWorkHistory.PositionID).FirstOrDefault();
                        if (objPosition != null && objPosition.Code != null)
                        {
                            positionCode = objPosition.Code;
                        }
                        if (objPosition != null && objPosition.PositionName != null)
                        {
                            positionName = objPosition.PositionName;
                        }
                    }
                    //end
                    #endregion

                    #region Lưu từng phần tử
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, orgStructureCode);
                    }

                    if (!listLaborTypeValueByDay.ContainsKey(indexRow))
                    {
                        listLaborTypeValueByDay.Add(indexRow, laborType);
                    }
                    //[14/12/2020][nghia.dang] [122090] [modify] 0122090: [OCEAN] Modify lấy thêm phần tử lương tính theo ngày
                    if (!listPositionNameValueByDay.ContainsKey(indexRow))
                    {
                        listPositionNameValueByDay.Add(indexRow, positionName);
                    }

                    if (!listPositionCodeValueByDay.ContainsKey(indexRow))
                    {
                        listPositionCodeValueByDay.Add(indexRow, positionCode);
                    }
                    //end
                    #endregion

                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueByDay;
                listColumnByDay.Add(objColumnByDay);

                objColumnLaborTypeByDay.ListValueByDay = listLaborTypeValueByDay;
                listColumnByDay.Add(objColumnLaborTypeByDay);

                objColumnPositionNameByDay.ListValueByDay = listPositionNameValueByDay;
                listColumnByDay.Add(objColumnPositionNameByDay);

                objColumnPositionCodeByDay.ListValueByDay = listPositionCodeValueByDay;
                listColumnByDay.Add(objColumnPositionCodeByDay);


            }

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.SAL_BASICSALARY_GROSSAMOUNT_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT1_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT2_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT3_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT4_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT5_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT6_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT7_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT8_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT9_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT10_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT11_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT12_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT13_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT14_BYDAY.ToString(),
                PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT15_BYDAY.ToString()
                }))
            {


                ColumnByDay objColumnGrossAmountByDay = new ColumnByDay();
                objColumnGrossAmountByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_GROSSAMOUNT_BYDAY.ToString();
                objColumnGrossAmountByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount1ByDay = new ColumnByDay();
                objColumnAllownanceAmount1ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT1_BYDAY.ToString();
                objColumnAllownanceAmount1ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount2ByDay = new ColumnByDay();
                objColumnAllownanceAmount2ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT2_BYDAY.ToString();
                objColumnAllownanceAmount2ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount3ByDay = new ColumnByDay();
                objColumnAllownanceAmount3ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT3_BYDAY.ToString();
                objColumnAllownanceAmount3ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount4ByDay = new ColumnByDay();
                objColumnAllownanceAmount4ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT4_BYDAY.ToString();
                objColumnAllownanceAmount4ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount5ByDay = new ColumnByDay();
                objColumnAllownanceAmount5ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT5_BYDAY.ToString();
                objColumnAllownanceAmount5ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount6ByDay = new ColumnByDay();
                objColumnAllownanceAmount6ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT6_BYDAY.ToString();
                objColumnAllownanceAmount6ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount7ByDay = new ColumnByDay();
                objColumnAllownanceAmount7ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT7_BYDAY.ToString();
                objColumnAllownanceAmount7ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount8ByDay = new ColumnByDay();
                objColumnAllownanceAmount8ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT8_BYDAY.ToString();
                objColumnAllownanceAmount8ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount9ByDay = new ColumnByDay();
                objColumnAllownanceAmount9ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT9_BYDAY.ToString();
                objColumnAllownanceAmount9ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount10ByDay = new ColumnByDay();
                objColumnAllownanceAmount10ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT10_BYDAY.ToString();
                objColumnAllownanceAmount10ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount11ByDay = new ColumnByDay();
                objColumnAllownanceAmount11ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT11_BYDAY.ToString();
                objColumnAllownanceAmount11ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount12ByDay = new ColumnByDay();
                objColumnAllownanceAmount12ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT12_BYDAY.ToString();
                objColumnAllownanceAmount12ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount13ByDay = new ColumnByDay();
                objColumnAllownanceAmount13ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT13_BYDAY.ToString();
                objColumnAllownanceAmount13ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount14ByDay = new ColumnByDay();
                objColumnAllownanceAmount14ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT14_BYDAY.ToString();
                objColumnAllownanceAmount14ByDay.ValueType = strDouble;

                ColumnByDay objColumnAllownanceAmount15ByDay = new ColumnByDay();
                objColumnAllownanceAmount15ByDay.ColumnName = PayrollElementByDay.SAL_BASICSALARY_ALLOWANCEAMOUNT15_BYDAY.ToString();
                objColumnAllownanceAmount15ByDay.ValueType = strDouble;
                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listGrossAmountValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount1ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount2ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount3ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount4ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount5ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount6ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount7ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount8ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount9ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount10ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount11ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount12ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount13ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount14ValueByDay = new Dictionary<int, string>();
                Dictionary<int, string> listAllowanceAmount15ValueByDay = new Dictionary<int, string>();

                var listBasicSalary = TotalDataAll.dicBasicSalary.GetValueOrNew(profileItem.ID);
                int indexRow = 0;

                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    #region Lấy từng phần tử
                    string grossAmount = string.Empty;
                    string allowanceAmount1 = string.Empty;
                    string allowanceAmount2 = string.Empty;
                    string allowanceAmount3 = string.Empty;
                    string allowanceAmount4 = string.Empty;
                    string allowanceAmount5 = string.Empty;
                    string allowanceAmount6 = string.Empty;
                    string allowanceAmount7 = string.Empty;
                    string allowanceAmount8 = string.Empty;
                    string allowanceAmount9 = string.Empty;
                    string allowanceAmount10 = string.Empty;
                    string allowanceAmount11 = string.Empty;
                    string allowanceAmount12 = string.Empty;
                    string allowanceAmount13 = string.Empty;
                    string allowanceAmount14 = string.Empty;
                    string allowanceAmount15 = string.Empty;

                    var objBasicSalary = listBasicSalary.Where(s => s.DateOfEffect <= objAttendanceTableItem.WorkDate && s.Status == "E_APPROVED").OrderByDescending(s => s.DateOfEffect).FirstOrDefault();

                    if (objBasicSalary != null)
                    {
                        if (!string.IsNullOrEmpty(objBasicSalary.GrossAmount))
                        {
                            grossAmount = objBasicSalary.GrossAmount;
                        }
                        if (objBasicSalary.AllowanceAmount1 != null)
                        {
                            allowanceAmount1 = objBasicSalary.AllowanceAmount1.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount2 != null)
                        {
                            allowanceAmount2 = objBasicSalary.AllowanceAmount2.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount3 != null)
                        {
                            allowanceAmount3 = objBasicSalary.AllowanceAmount3.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount4 != null)
                        {
                            allowanceAmount4 = objBasicSalary.AllowanceAmount4.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount5 != null)
                        {
                            allowanceAmount5 = objBasicSalary.AllowanceAmount5.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount6 != null)
                        {
                            allowanceAmount6 = objBasicSalary.AllowanceAmount6.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount7 != null)
                        {
                            allowanceAmount7 = objBasicSalary.AllowanceAmount7.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount8 != null)
                        {
                            allowanceAmount8 = objBasicSalary.AllowanceAmount8.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount9 != null)
                        {
                            allowanceAmount9 = objBasicSalary.AllowanceAmount9.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount10 != null)
                        {
                            allowanceAmount10 = objBasicSalary.AllowanceAmount10.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount11 != null)
                        {
                            allowanceAmount11 = objBasicSalary.AllowanceAmount11.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount12 != null)
                        {
                            allowanceAmount12 = objBasicSalary.AllowanceAmount12.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount13 != null)
                        {
                            allowanceAmount13 = objBasicSalary.AllowanceAmount13.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount14 != null)
                        {
                            allowanceAmount14 = objBasicSalary.AllowanceAmount14.ToString();
                        }
                        if (objBasicSalary.AllowanceAmount15 != null)
                        {
                            allowanceAmount15 = objBasicSalary.AllowanceAmount15.ToString();
                        }
                    }
                    #endregion

                    #region Lưu từng phần tử
                    if (!listGrossAmountValueByDay.ContainsKey(indexRow))
                    {
                        listGrossAmountValueByDay.Add(indexRow, grossAmount);
                    }
                    if (!listAllowanceAmount1ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount1ValueByDay.Add(indexRow, allowanceAmount1);
                    }
                    if (!listAllowanceAmount2ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount2ValueByDay.Add(indexRow, allowanceAmount2);
                    }
                    if (!listAllowanceAmount3ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount3ValueByDay.Add(indexRow, allowanceAmount3);
                    }
                    if (!listAllowanceAmount4ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount4ValueByDay.Add(indexRow, allowanceAmount4);
                    }
                    if (!listAllowanceAmount5ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount5ValueByDay.Add(indexRow, allowanceAmount5);
                    }
                    if (!listAllowanceAmount6ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount6ValueByDay.Add(indexRow, allowanceAmount6);
                    }
                    if (!listAllowanceAmount7ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount7ValueByDay.Add(indexRow, allowanceAmount7);
                    }
                    if (!listAllowanceAmount8ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount8ValueByDay.Add(indexRow, allowanceAmount8);
                    }
                    if (!listAllowanceAmount9ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount9ValueByDay.Add(indexRow, allowanceAmount9);
                    }
                    if (!listAllowanceAmount10ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount10ValueByDay.Add(indexRow, allowanceAmount10);
                    }
                    if (!listAllowanceAmount11ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount11ValueByDay.Add(indexRow, allowanceAmount11);
                    }
                    if (!listAllowanceAmount12ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount12ValueByDay.Add(indexRow, allowanceAmount12);
                    }
                    if (!listAllowanceAmount13ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount13ValueByDay.Add(indexRow, allowanceAmount13);
                    }
                    if (!listAllowanceAmount14ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount14ValueByDay.Add(indexRow, allowanceAmount14);
                    }
                    if (!listAllowanceAmount15ValueByDay.ContainsKey(indexRow))
                    {
                        listAllowanceAmount15ValueByDay.Add(indexRow, allowanceAmount15);
                    }

                    #endregion

                    indexRow += 1;
                }
                objColumnGrossAmountByDay.ListValueByDay = listGrossAmountValueByDay;
                listColumnByDay.Add(objColumnGrossAmountByDay);

                objColumnAllownanceAmount1ByDay.ListValueByDay = listAllowanceAmount1ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount1ByDay);
                objColumnAllownanceAmount2ByDay.ListValueByDay = listAllowanceAmount2ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount2ByDay);
                objColumnAllownanceAmount3ByDay.ListValueByDay = listAllowanceAmount3ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount3ByDay);
                objColumnAllownanceAmount4ByDay.ListValueByDay = listAllowanceAmount4ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount4ByDay);
                objColumnAllownanceAmount5ByDay.ListValueByDay = listAllowanceAmount5ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount5ByDay);
                objColumnAllownanceAmount6ByDay.ListValueByDay = listAllowanceAmount6ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount6ByDay);
                objColumnAllownanceAmount7ByDay.ListValueByDay = listAllowanceAmount7ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount7ByDay);
                objColumnAllownanceAmount8ByDay.ListValueByDay = listAllowanceAmount8ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount8ByDay);
                objColumnAllownanceAmount9ByDay.ListValueByDay = listAllowanceAmount9ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount9ByDay);
                objColumnAllownanceAmount10ByDay.ListValueByDay = listAllowanceAmount10ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount10ByDay);
                objColumnAllownanceAmount11ByDay.ListValueByDay = listAllowanceAmount11ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount11ByDay);
                objColumnAllownanceAmount12ByDay.ListValueByDay = listAllowanceAmount12ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount12ByDay);
                objColumnAllownanceAmount13ByDay.ListValueByDay = listAllowanceAmount13ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount13ByDay);
                objColumnAllownanceAmount14ByDay.ListValueByDay = listAllowanceAmount14ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount14ByDay);
                objColumnAllownanceAmount15ByDay.ListValueByDay = listAllowanceAmount15ValueByDay;
                listColumnByDay.Add(objColumnAllownanceAmount15ByDay);

            }

            #endregion

            #region Tung.Tran [15082018][0097380] Thêm phần tử ngày:  Lấy field (WorkDate)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.WORKDAY_BYDAY.ToString() }))
            {
                string columWORKDAY_BYDAY = PayrollElementByDay.WORKDAY_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columWORKDAY_BYDAY;
                objColumnByDay.ValueType = strDateTime;
                Dictionary<int, string> listValueWorkDayByDay = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var workDate = DateTime.MinValue;
                    if (objAttendanceTableItem.WorkDate != null)
                    {
                        workDate = objAttendanceTableItem.WorkDate;
                    }
                    if (!listValueWorkDayByDay.ContainsKey(indexRow))
                    {
                        listValueWorkDayByDay.Add(indexRow, workDate.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueWorkDayByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:  Lấy field (ActualWorkHour)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.ACTUALWORKHOUR_BYDAY.ToString() }))
            {
                string columACTUALWORKHOUR_BYDAY = PayrollElementByDay.ACTUALWORKHOUR_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columACTUALWORKHOUR_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueAcTualWorkHourByDay = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var actualWorkHour = 0.0;
                    if (objAttendanceTableItem.ActualWorkHour != null)
                    {
                        actualWorkHour = objAttendanceTableItem.ActualWorkHour.Value;
                    }
                    if (!listValueAcTualWorkHourByDay.ContainsKey(indexRow))
                    {
                        listValueAcTualWorkHourByDay.Add(indexRow, actualWorkHour.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueAcTualWorkHourByDay;
                listColumnByDay.Add(objColumnByDay);
            }


            #endregion

            #region Khoa.nguyen[0111498] Thêm phần tử ngày:  Enum phần tử lương tổng số giờ quẹt thẻ dư ra trong tháng trước đổi lương và tổng số giờ dư quẹt thẻ dư ra trong tháng sau đổi lương 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EARLYINMINUTES_BYDAY.ToString(), PayrollElementByDay.LATEOUTMINUTES_BYDAY.ToString() }))
            {
                string columEARLYINMINUTES_BYDAY = PayrollElementByDay.EARLYINMINUTES_BYDAY.ToString();
                string columLATEOUTMINUTES_BYDAY = PayrollElementByDay.LATEOUTMINUTES_BYDAY.ToString();

                ColumnByDay objColumnEarlyMinutesByDay = new ColumnByDay();
                objColumnEarlyMinutesByDay.ColumnName = columEARLYINMINUTES_BYDAY;
                objColumnEarlyMinutesByDay.ValueType = strDouble;
                Dictionary<int, string> listValueSumEarlyMinutesByDayByDay = new Dictionary<int, string>();

                ColumnByDay objColumnLateOutMinutesByDay = new ColumnByDay();
                objColumnLateOutMinutesByDay.ColumnName = columLATEOUTMINUTES_BYDAY;
                objColumnLateOutMinutesByDay.ValueType = strDouble;
                Dictionary<int, string> listValueSumLateOutMinutesByDay = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var sumearlyInMinutes = 0;
                    var sumelateOutMinutes = 0;
                    if (objAttendanceTableItem.EarlyInMinutes != null)
                    {
                        sumearlyInMinutes = objAttendanceTableItem.EarlyInMinutes.Value;
                    }
                    if (objAttendanceTableItem.LateOutMinutes != null)
                    {
                        sumelateOutMinutes = objAttendanceTableItem.LateOutMinutes.Value;
                    }
                    if (!listValueSumEarlyMinutesByDayByDay.ContainsKey(indexRow))
                    {
                        listValueSumEarlyMinutesByDayByDay.Add(indexRow, sumearlyInMinutes.ToString());
                    }
                    if (!listValueSumLateOutMinutesByDay.ContainsKey(indexRow))
                    {
                        listValueSumLateOutMinutesByDay.Add(indexRow, sumelateOutMinutes.ToString());
                    }
                    indexRow += 1;
                }
                objColumnEarlyMinutesByDay.ListValueByDay = listValueSumEarlyMinutesByDayByDay;
                objColumnLateOutMinutesByDay.ListValueByDay = listValueSumLateOutMinutesByDay;
                listColumnByDay.Add(objColumnEarlyMinutesByDay);
                listColumnByDay.Add(objColumnLateOutMinutesByDay);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:  Att_LeaveDay.HaveMeal
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.LEAVETYPEHAVEMEAL_BYDAY.ToString(),
                PayrollElementByDay.EXTRALEAVETYPEHAVEMEAL_BYDAY.ToString(),
                PayrollElementByDay.EXTRALEAVETYPE3HAVEMEAL_BYDAY.ToString(),
                PayrollElementByDay.EXTRALEAVETYPE4HAVEMEAL_BYDAY.ToString(),
                PayrollElementByDay.EXTRALEAVETYPE5HAVEMEAL_BYDAY.ToString(),
                PayrollElementByDay.EXTRALEAVETYPE6HAVEMEAL_BYDAY.ToString(),
                PayrollElementByDay.LEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ToString(),

            }))
            {
                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }

                #region Khai báo các cột
                string columLEAVETYPEHAVEMEAL_BYDAY = PayrollElementByDay.LEAVETYPEHAVEMEAL_BYDAY.ToString();
                string columEXTRALEAVETYPEHAVEMEAL_BYDAY = PayrollElementByDay.EXTRALEAVETYPEHAVEMEAL_BYDAY.ToString();
                string columEXTRALEAVETYPE3HAVEMEAL_BYDAY = PayrollElementByDay.EXTRALEAVETYPE3HAVEMEAL_BYDAY.ToString();
                string columEXTRALEAVETYPE4HAVEMEAL_BYDAY = PayrollElementByDay.EXTRALEAVETYPE4HAVEMEAL_BYDAY.ToString();
                string columEXTRALEAVETYPE5HAVEMEAL_BYDAY = PayrollElementByDay.EXTRALEAVETYPE5HAVEMEAL_BYDAY.ToString();
                string columEXTRALEAVETYPE6HAVEMEAL_BYDAY = PayrollElementByDay.EXTRALEAVETYPE6HAVEMEAL_BYDAY.ToString();
                string columLEAVEWORKDAYTYPEHAVEMEAL_BYDAY = PayrollElementByDay.LEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ToString();

                ColumnByDay objColumnLEAVETYPEHAVEMEAL_BYDAY = new ColumnByDay();
                objColumnLEAVETYPEHAVEMEAL_BYDAY.ColumnName = columLEAVETYPEHAVEMEAL_BYDAY;
                objColumnLEAVETYPEHAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPEHAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnEXTRALEAVETYPEHAVEMEAL_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPEHAVEMEAL_BYDAY.ColumnName = columEXTRALEAVETYPEHAVEMEAL_BYDAY;
                objColumnEXTRALEAVETYPEHAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPEHAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnEXTRALEAVETYPE3HAVEMEAL_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE3HAVEMEAL_BYDAY.ColumnName = columEXTRALEAVETYPE3HAVEMEAL_BYDAY;
                objColumnEXTRALEAVETYPE3HAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE3HAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnEXTRALEAVETYPE4HAVEMEAL_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE4HAVEMEAL_BYDAY.ColumnName = columEXTRALEAVETYPE4HAVEMEAL_BYDAY;
                objColumnEXTRALEAVETYPE4HAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE4HAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnEXTRALEAVETYPE5HAVEMEAL_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE5HAVEMEAL_BYDAY.ColumnName = columEXTRALEAVETYPE5HAVEMEAL_BYDAY;
                objColumnEXTRALEAVETYPE5HAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE5HAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnEXTRALEAVETYPE6HAVEMEAL_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE6HAVEMEAL_BYDAY.ColumnName = columEXTRALEAVETYPE6HAVEMEAL_BYDAY;
                objColumnEXTRALEAVETYPE6HAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE6HAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnLEAVEWORKDAYTYPEHAVEMEAL_BYDAY = new ColumnByDay();
                objColumnLEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ColumnName = columLEAVEWORKDAYTYPEHAVEMEAL_BYDAY;
                objColumnLEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueLEAVEWORKDAYTYPEHAVEMEAL_BYDAY = new Dictionary<int, string>();
                #endregion

                var listLeaveDayByProfileDic = TotalDataAll.dicLeaveDay.GetValueOrNew(profileItem.ID);

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {

                    #region HaveMeal 1
                    var leaveDay1 = listLeaveDayByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.LeaveTypeID).FirstOrDefault();
                    var haveMeal1 = string.Empty;
                    if (leaveDay1 != null && !string.IsNullOrEmpty(leaveDay1.HaveMeal))
                    {
                        haveMeal1 = leaveDay1.HaveMeal;
                    }
                    if (!listValueLEAVETYPEHAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPEHAVEMEAL_BYDAY.Add(indexRow, haveMeal1);
                    }
                    #endregion

                    #region HaveMeal 2
                    var leaveDay2 = listLeaveDayByProfileDic.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveTypeID).FirstOrDefault();
                    var haveMeal2 = string.Empty;
                    if (leaveDay2 != null && !string.IsNullOrEmpty(leaveDay2.HaveMeal))
                    {
                        haveMeal2 = leaveDay2.HaveMeal;
                    }
                    if (!listValueEXTRALEAVETYPEHAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPEHAVEMEAL_BYDAY.Add(indexRow, haveMeal2);
                    }
                    #endregion

                    #region HaveMeal 3
                    var leaveDay3 = listLeaveDayByProfileDic.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType3ID).FirstOrDefault();
                    var haveMeal3 = string.Empty;
                    if (leaveDay3 != null && !string.IsNullOrEmpty(leaveDay3.HaveMeal))
                    {
                        haveMeal3 = leaveDay3.HaveMeal;
                    }
                    if (!listValueEXTRALEAVETYPE3HAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE3HAVEMEAL_BYDAY.Add(indexRow, haveMeal3);
                    }
                    #endregion

                    #region HaveMeal 4
                    var leaveDay4 = listLeaveDayByProfileDic.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType4ID).FirstOrDefault();
                    var haveMeal4 = string.Empty;
                    if (leaveDay4 != null && !string.IsNullOrEmpty(leaveDay4.HaveMeal))
                    {
                        haveMeal4 = leaveDay4.HaveMeal;
                    }
                    if (!listValueEXTRALEAVETYPE4HAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE4HAVEMEAL_BYDAY.Add(indexRow, haveMeal4);
                    }
                    #endregion

                    #region HaveMeal 5
                    var leaveDay5 = listLeaveDayByProfileDic.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType5ID).FirstOrDefault();
                    var haveMeal5 = string.Empty;
                    if (leaveDay5 != null && !string.IsNullOrEmpty(leaveDay5.HaveMeal))
                    {
                        haveMeal5 = leaveDay5.HaveMeal;
                    }
                    if (!listValueEXTRALEAVETYPE5HAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE5HAVEMEAL_BYDAY.Add(indexRow, haveMeal5);
                    }
                    #endregion

                    #region HaveMeal 6
                    var leaveDay6 = listLeaveDayByProfileDic.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType6ID).FirstOrDefault();
                    var haveMeal6 = string.Empty;
                    if (leaveDay6 != null && !string.IsNullOrEmpty(leaveDay6.HaveMeal))
                    {
                        haveMeal6 = leaveDay6.HaveMeal;
                    }
                    if (!listValueEXTRALEAVETYPE6HAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE6HAVEMEAL_BYDAY.Add(indexRow, haveMeal6);
                    }
                    #endregion

                    #region HaveMeal 7 ( Cột LeaveWorkDayType)
                    var leaveDay7 = listLeaveDayByProfileDic.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.LeaveWorkDayType).FirstOrDefault();
                    var haveMeal7 = string.Empty;
                    if (leaveDay7 != null && !string.IsNullOrEmpty(leaveDay7.HaveMeal))
                    {
                        haveMeal7 = leaveDay7.HaveMeal;
                    }
                    if (!listValueLEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVEWORKDAYTYPEHAVEMEAL_BYDAY.Add(indexRow, haveMeal7);
                    }
                    #endregion

                    indexRow += 1;
                }
                objColumnLEAVETYPEHAVEMEAL_BYDAY.ListValueByDay = listValueLEAVETYPEHAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnLEAVETYPEHAVEMEAL_BYDAY);

                objColumnEXTRALEAVETYPEHAVEMEAL_BYDAY.ListValueByDay = listValueEXTRALEAVETYPEHAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPEHAVEMEAL_BYDAY);

                objColumnEXTRALEAVETYPE3HAVEMEAL_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE3HAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE3HAVEMEAL_BYDAY);

                objColumnEXTRALEAVETYPE4HAVEMEAL_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE4HAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE4HAVEMEAL_BYDAY);

                objColumnEXTRALEAVETYPE5HAVEMEAL_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE5HAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE5HAVEMEAL_BYDAY);

                objColumnEXTRALEAVETYPE6HAVEMEAL_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE6HAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE6HAVEMEAL_BYDAY);

                objColumnLEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ListValueByDay = listValueLEAVEWORKDAYTYPEHAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnLEAVEWORKDAYTYPEHAVEMEAL_BYDAY);

            }
            #endregion

            #region Tung.Tran [21082018][97292] AVAILABLEHOURS_BYDAY (Att_AttendanceTableItem.AVAILABLEHOURS

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.AVAILABLEHOURS_BYDAY.ToString() }))
            {
                string columAVAILABLEHOURS_BYDAY = PayrollElementByDay.AVAILABLEHOURS_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columAVAILABLEHOURS_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueAVAILABLEHOURS_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {

                    if (!listValueAVAILABLEHOURS_BYDAY.ContainsKey(indexRow))
                    {
                        listValueAVAILABLEHOURS_BYDAY.Add(indexRow, objAttendanceTableItem.AvailableHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueAVAILABLEHOURS_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region [08/03/2019][bang.nguyen][103613][modify] (Att_AttendanceTableItem.ShiftID,Att_AttendanceTableItem.Shift2ID)
            //lay giờ công chuẩn theo ca 1 cho từng ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.SHIFT1_STDWORKHOURS_BYDAY.ToString() }))
            {
                string columSHIFT1_STDWORKHOURS_BYDAY = PayrollElementByDay.SHIFT1_STDWORKHOURS_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columSHIFT1_STDWORKHOURS_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueSHIFT1_STDWORKHOURS_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string shift1StdWorkHours = "0";
                    if (objAttendanceTableItem.ShiftID != null)
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null && objShift.StdWorkHours != null)
                        {
                            shift1StdWorkHours = objShift.StdWorkHours.Value.ToString();
                        }
                    }
                    if (!listValueSHIFT1_STDWORKHOURS_BYDAY.ContainsKey(indexRow))
                    {
                        listValueSHIFT1_STDWORKHOURS_BYDAY.Add(indexRow, shift1StdWorkHours);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueSHIFT1_STDWORKHOURS_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }

            //lay giờ công chính theo ca 1 cho từng ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.SHIFT1_WORKHOURS_BYDAY.ToString() }))
            {
                string columSHIFT1_WORKHOURS_BYDAY = PayrollElementByDay.SHIFT1_WORKHOURS_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columSHIFT1_WORKHOURS_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueSHIFT1_WORKHOURS_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string shift1WorkHours = "0";
                    if (objAttendanceTableItem.ShiftID != null)
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null && objShift.WorkHours != null)
                        {
                            shift1WorkHours = objShift.WorkHours.Value.ToString();
                        }
                    }
                    if (!listValueSHIFT1_WORKHOURS_BYDAY.ContainsKey(indexRow))
                    {
                        listValueSHIFT1_WORKHOURS_BYDAY.Add(indexRow, shift1WorkHours);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueSHIFT1_WORKHOURS_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }

            //lay gio công chuẩn theo ca 2 cho từng ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.SHIFT2_STDWORKHOURS_BYDAY.ToString() }))
            {
                string columSHIFT2_STDWORKHOURS_BYDAY = PayrollElementByDay.SHIFT2_STDWORKHOURS_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columSHIFT2_STDWORKHOURS_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueSHIFT2_STDWORKHOURS_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string shift2StdWorkHours = "0";
                    if (objAttendanceTableItem.ShiftID != null)
                    {
                        var objShift2 = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == objAttendanceTableItem.Shift2ID);
                        if (objShift2 != null && objShift2.StdWorkHours != null)
                        {
                            shift2StdWorkHours = objShift2.StdWorkHours.Value.ToString();
                        }
                    }
                    if (!listValueSHIFT2_STDWORKHOURS_BYDAY.ContainsKey(indexRow))
                    {
                        listValueSHIFT2_STDWORKHOURS_BYDAY.Add(indexRow, shift2StdWorkHours);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueSHIFT2_STDWORKHOURS_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }

            //lay giờ công chính theo ca 2 cho từng ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.SHIFT2_WORKHOURS_BYDAY.ToString() }))
            {
                string columSHIFT2_WORKHOURS_BYDAY = PayrollElementByDay.SHIFT2_WORKHOURS_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columSHIFT2_WORKHOURS_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueSHIFT2_WORKHOURS_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string shift2WorkHours = "0";
                    if (objAttendanceTableItem.ShiftID != null)
                    {
                        var objShift2 = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == objAttendanceTableItem.Shift2ID);
                        if (objShift2 != null && objShift2.WorkHours != null)
                        {
                            shift2WorkHours = objShift2.WorkHours.Value.ToString();
                        }
                    }
                    if (!listValueSHIFT2_WORKHOURS_BYDAY.ContainsKey(indexRow))
                    {
                        listValueSHIFT2_WORKHOURS_BYDAY.Add(indexRow, shift2WorkHours);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueSHIFT2_WORKHOURS_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] SHIFTCODE1_BYDAY (Att_AttendanceTableItem.ShiftID.Code)

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.SHIFTCODE1_BYDAY.ToString() }))
            {
                string columSHIFTCODE1_BYDAY = PayrollElementByDay.SHIFTCODE1_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columSHIFTCODE1_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueSHIFTCODE1_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var shiftCode = string.Empty;
                    if (objAttendanceTableItem.ShiftID != null)
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null && objShift.Code != null)
                        {
                            shiftCode = objShift.Code;
                        }
                    }
                    if (!listValueSHIFTCODE1_BYDAY.ContainsKey(indexRow))
                    {
                        listValueSHIFTCODE1_BYDAY.Add(indexRow, shiftCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueSHIFTCODE1_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] SHIFTCODE2_BYDAY (Att_AttendanceTableItem.ShiftID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.SHIFTCODE2_BYDAY.ToString() }))
            {
                string columSHIFTCODE2_BYDAY = PayrollElementByDay.SHIFTCODE2_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columSHIFTCODE2_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueSHIFTCODE2_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var shiftCode = string.Empty;
                    if (objAttendanceTableItem.Shift2ID != null)
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == objAttendanceTableItem.Shift2ID);
                        if (objShift != null && objShift.Code != null)
                        {
                            shiftCode = objShift.Code;
                        }
                    }
                    if (!listValueSHIFTCODE2_BYDAY.ContainsKey(indexRow))
                    {
                        listValueSHIFTCODE2_BYDAY.Add(indexRow, shiftCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueSHIFTCODE2_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE1_BYDAY (Att_AttendanceTableItem.LeaveTypeID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE1_BYDAY.ToString() }))
            {
                string columLEAVETYPECODE1_BYDAY = PayrollElementByDay.LEAVETYPECODE1_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE1_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE1_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.LeaveTypeID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.LeaveTypeID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE1_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE1_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE1_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS1_BYDAY (Att_AttendanceTableItem.LeaveHours)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS1_BYDAY.ToString() }))
            {
                string columEXTRALEAVEHOURS1_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS1_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS1_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS1_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValueEXTRALEAVEHOURS1_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS1_BYDAY.Add(indexRow, objAttendanceTableItem.LeaveHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS1_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE2_BYDAY (Att_AttendanceTableItem.ExtraLeaveTypeID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE2_BYDAY.ToString() }))
            {
                string columLEAVETYPECODE2_BYDAY = PayrollElementByDay.LEAVETYPECODE2_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE2_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE2_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.ExtraLeaveTypeID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.ExtraLeaveTypeID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE2_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE2_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE2_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS2_BYDAY (Att_AttendanceTableItem.ExtraLeaveHours)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS2_BYDAY.ToString() }))
            {
                string columEXTRALEAVEHOURS2_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS2_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS2_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS2_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValueEXTRALEAVEHOURS2_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS2_BYDAY.Add(indexRow, objAttendanceTableItem.ExtraLeaveHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS2_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE3_BYDAY (Att_AttendanceTableItem.ExtraLeaveType3ID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE3_BYDAY.ToString() }))
            {
                string columLEAVETYPECODE3_BYDAY = PayrollElementByDay.LEAVETYPECODE3_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE3_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE3_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.ExtraLeaveType3ID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.ExtraLeaveType3ID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE3_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE3_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE3_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS3_BYDAY (Att_AttendanceTableItem.ExtraLeaveHours3)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS3_BYDAY.ToString() }))
            {
                string columEXTRALEAVEHOURS3_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS3_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS3_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS3_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var extraLeaveHours3 = 0.0;
                    if (objAttendanceTableItem.ExtraLeaveHours3 != null)
                    {
                        extraLeaveHours3 = objAttendanceTableItem.ExtraLeaveHours3.Value;
                    }

                    if (!listValueEXTRALEAVEHOURS3_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS3_BYDAY.Add(indexRow, extraLeaveHours3.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS3_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE4_BYDAY (Att_AttendanceTableItem.ExtraLeaveType4ID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE4_BYDAY.ToString() }))
            {
                string columLEAVETYPECODE4_BYDAY = PayrollElementByDay.LEAVETYPECODE4_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE4_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE4_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.ExtraLeaveType4ID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.ExtraLeaveType4ID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE4_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE4_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE4_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS4_BYDAY (Att_AttendanceTableItem.ExtraLeaveHours4)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS4_BYDAY.ToString() }))
            {
                string columEXTRALEAVEHOURS4_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS4_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS4_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS4_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var extraLeaveHours4 = 0.0;
                    if (objAttendanceTableItem.ExtraLeaveHours4 != null)
                    {
                        extraLeaveHours4 = objAttendanceTableItem.ExtraLeaveHours4.Value;
                    }

                    if (!listValueEXTRALEAVEHOURS4_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS4_BYDAY.Add(indexRow, extraLeaveHours4.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS4_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE5_BYDAY (Att_AttendanceTableItem.ExtraLeaveType5ID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE5_BYDAY.ToString() }))
            {
                string columLEAVETYPECODE5_BYDAY = PayrollElementByDay.LEAVETYPECODE5_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE5_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE5_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.ExtraLeaveType5ID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.ExtraLeaveType5ID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE5_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE5_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE5_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS5_BYDAY (Att_AttendanceTableItem.ExtraLeaveHours5)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS5_BYDAY.ToString() }))
            {
                string columEXTRALEAVEHOURS5_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS5_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS5_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS5_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var extraLeaveHours5 = 0.0;
                    if (objAttendanceTableItem.ExtraLeaveHours5 != null)
                    {
                        extraLeaveHours5 = objAttendanceTableItem.ExtraLeaveHours5.Value;
                    }
                    if (!listValueEXTRALEAVEHOURS5_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS5_BYDAY.Add(indexRow, extraLeaveHours5.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS5_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE6_BYDAY (Att_AttendanceTableItem.ExtraLeaveType6ID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE6_BYDAY.ToString() }))
            {
                string columLEAVETYPECODE6_BYDAY = PayrollElementByDay.LEAVETYPECODE6_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE6_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE6_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.ExtraLeaveType6ID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.ExtraLeaveType6ID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE6_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE6_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE6_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS6_BYDAY (Att_AttendanceTableItem.ExtraLeaveHours6)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS6_BYDAY.ToString() }))
            {
                string columEXTRALEAVEHOURS6_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS6_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS6_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS6_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var extraLeaveHours6 = 0.0;
                    if (objAttendanceTableItem.ExtraLeaveHours6 != null)
                    {
                        extraLeaveHours6 = objAttendanceTableItem.ExtraLeaveHours6.Value;
                    }
                    if (!listValueEXTRALEAVEHOURS6_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS6_BYDAY.Add(indexRow, extraLeaveHours6.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS6_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.LeaveTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.LEAVETYPEDURATIONTYPE_BYDAY.ToString(),
            }))
            {
                var listLeaveDayByProfileDic = TotalDataAll.dicLeaveDay.GetValueOrNew(profileItem.ID);

                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columLEAVETYPEDURATIONTYPE_BYDAY = PayrollElementByDay.LEAVETYPEDURATIONTYPE_BYDAY.ToString();

                ColumnByDay objColumnLEAVETYPEDURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnLEAVETYPEDURATIONTYPE_BYDAY.ColumnName = columLEAVETYPEDURATIONTYPE_BYDAY;
                objColumnLEAVETYPEDURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPEDURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {

                    var leaveDay = listLeaveDayByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.LeaveDayTypeID == objAttendanceTableItem.LeaveTypeID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueLEAVETYPEDURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPEDURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnLEAVETYPEDURATIONTYPE_BYDAY.ListValueByDay = listValueLEAVETYPEDURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnLEAVETYPEDURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.ExtraLeaveTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.EXTRALEAVETYPEDURATIONTYPE_BYDAY.ToString(),
            }))
            {
                var listLeaveDayByProfileDic = TotalDataAll.dicLeaveDay.GetValueOrNew(profileItem.ID);

                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columEXTRALEAVETYPEDURATIONTYPE_BYDAY = PayrollElementByDay.EXTRALEAVETYPEDURATIONTYPE_BYDAY.ToString();

                ColumnByDay objColumnEXTRALEAVETYPEDURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPEDURATIONTYPE_BYDAY.ColumnName = columEXTRALEAVETYPEDURATIONTYPE_BYDAY;
                objColumnEXTRALEAVETYPEDURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPEDURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveDay = listLeaveDayByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveTypeID).FirstOrDefault();
                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueEXTRALEAVETYPEDURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPEDURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnEXTRALEAVETYPEDURATIONTYPE_BYDAY.ListValueByDay = listValueEXTRALEAVETYPEDURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPEDURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.ExtraLeaveType3ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.EXTRALEAVETYPE3DURATIONTYPE_BYDAY.ToString(),
            }))
            {
                var listLeaveDayByProfileDic = TotalDataAll.dicLeaveDay.GetValueOrNew(profileItem.ID);

                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columEXTRALEAVETYPE3DURATIONTYPE_BYDAY = PayrollElementByDay.EXTRALEAVETYPE3DURATIONTYPE_BYDAY.ToString();

                ColumnByDay objColumnEXTRALEAVETYPE3DURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE3DURATIONTYPE_BYDAY.ColumnName = columEXTRALEAVETYPE3DURATIONTYPE_BYDAY;
                objColumnEXTRALEAVETYPE3DURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE3DURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveDay = listLeaveDayByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType3ID).FirstOrDefault();
                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueEXTRALEAVETYPE3DURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE3DURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnEXTRALEAVETYPE3DURATIONTYPE_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE3DURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE3DURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.ExtraLeaveType4ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.EXTRALEAVETYPE4DURATIONTYPE_BYDAY.ToString(),
            }))
            {
                var listLeaveDayByProfileDic = TotalDataAll.dicLeaveDay.GetValueOrNew(profileItem.ID);

                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columEXTRALEAVETYPE4DURATIONTYPE_BYDAY = PayrollElementByDay.EXTRALEAVETYPE4DURATIONTYPE_BYDAY.ToString();

                ColumnByDay objColumnEXTRALEAVETYPE4DURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE4DURATIONTYPE_BYDAY.ColumnName = columEXTRALEAVETYPE4DURATIONTYPE_BYDAY;
                objColumnEXTRALEAVETYPE4DURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE4DURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveDay = listLeaveDayByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType4ID).FirstOrDefault();
                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueEXTRALEAVETYPE4DURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE4DURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnEXTRALEAVETYPE4DURATIONTYPE_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE4DURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE4DURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.ExtraLeaveType5ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.EXTRALEAVETYPE5DURATIONTYPE_BYDAY.ToString(),
            }))
            {
                var listLeaveDayByProfileDic = TotalDataAll.dicLeaveDay.GetValueOrNew(profileItem.ID);

                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columEXTRALEAVETYPE5DURATIONTYPE_BYDAY = PayrollElementByDay.EXTRALEAVETYPE5DURATIONTYPE_BYDAY.ToString();

                ColumnByDay objColumnEXTRALEAVETYPE5DURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE5DURATIONTYPE_BYDAY.ColumnName = columEXTRALEAVETYPE5DURATIONTYPE_BYDAY;
                objColumnEXTRALEAVETYPE5DURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE5DURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveDay = listLeaveDayByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType5ID).FirstOrDefault();
                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueEXTRALEAVETYPE5DURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE5DURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnEXTRALEAVETYPE5DURATIONTYPE_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE5DURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE5DURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.ExtraLeaveType6ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.EXTRALEAVETYPE6DURATIONTYPE_BYDAY.ToString(),
            }))
            {
                var listLeaveDayByProfileDic = TotalDataAll.dicLeaveDay.GetValueOrNew(profileItem.ID);

                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columEXTRALEAVETYPE6DURATIONTYPE_BYDAY = PayrollElementByDay.EXTRALEAVETYPE6DURATIONTYPE_BYDAY.ToString();

                ColumnByDay objColumnEXTRALEAVETYPE6DURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE6DURATIONTYPE_BYDAY.ColumnName = columEXTRALEAVETYPE6DURATIONTYPE_BYDAY;
                objColumnEXTRALEAVETYPE6DURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE6DURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveDay = listLeaveDayByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType6ID).FirstOrDefault();
                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueEXTRALEAVETYPE6DURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE6DURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnEXTRALEAVETYPE6DURATIONTYPE_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE6DURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE6DURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [03092018][0098109] WorkDate có tồn tại trong ngày nghỉ Cat_DayOff  ? (Trả về 1 or 0) (Chưa hỗ trợ true / false)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.ISHOLIDAYWORKDATE_BYDAY.ToString()))
            {
                string columIsHoliday = PayrollElementByDay.ISHOLIDAYWORKDATE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = columIsHoliday;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var isDayOff = 0;

                    var dayOff = TotalDataAll.listDayOff.Where(a => a.DateOff != null && (a.DateOff.Date == objAttendanceTableItem.WorkDate.Date)).FirstOrDefault();
                    if (dayOff != null)
                    {
                        isDayOff = 1;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, isDayOff.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Công chuẩn theo ngày < Att_AttendanceTableItem.StdWorkDayCount >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.STDWORKDAYCOUNT_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.STDWORKDAYCOUNT_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double stdWorkDayCount = 0;
                    if (objAttendanceTableItem.StdWorkDayCount != null)
                    {
                        stdWorkDayCount = objAttendanceTableItem.StdWorkDayCount.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, stdWorkDayCount.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Số giờ đi làm tính lương < Att_AttendanceTableItem.WorkPaidHours >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.WORKPAIDHOURS_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.WORKPAIDHOURS_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.WorkPaidHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Số giờ nghỉ tính lương < Att_AttendanceTableItem.PaidLeaveHours >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.PAIDLEAVEHOURS_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.PAIDLEAVEHOURS_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.PaidLeaveHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Số giờ nghỉ không tính lương < Att_AttendanceTableItem.UnpaidLeaveHours >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.UNPAIDLEAVEHOURS_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.UNPAIDLEAVEHOURS_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.UnpaidLeaveHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Số phút muộn sớm < Att_AttendanceTableItem.LateEarlyMinutes >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.LATEEARLYMINUTES_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.LATEEARLYMINUTES_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.LateEarlyMinutes.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Số giờ ca đêm < Att_AttendanceTableItem.NightShiftHours >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.NIGHTSHIFTHOURS_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.NIGHTSHIFTHOURS_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.NightShiftHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 1 : Att_AttendanceTableItem.OvertimeTypeID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMETYPECODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMETYPECODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overTimeCode = string.Empty;

                    if (objAttendanceTableItem.OvertimeTypeID != null && objAttendanceTableItem.OvertimeTypeID != Guid.Empty)
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.OvertimeTypeID).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 2 : Att_AttendanceTableItem.ExtraOvertimeTypeID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPECODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMETYPECODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overTimeCode = string.Empty;

                    if (objAttendanceTableItem.ExtraOvertimeTypeID != null && objAttendanceTableItem.ExtraOvertimeTypeID != Guid.Empty)
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.ExtraOvertimeTypeID).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 3 : Att_AttendanceTableItem.ExtraOvertimeType2ID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE2CODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE2CODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overTimeCode = string.Empty;

                    if (objAttendanceTableItem.ExtraOvertimeType2ID != null && objAttendanceTableItem.ExtraOvertimeType2ID != Guid.Empty)
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.ExtraOvertimeType2ID).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 4 : Att_AttendanceTableItem.ExtraOvertimeType3ID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE3CODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE3CODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overTimeCode = string.Empty;

                    if (objAttendanceTableItem.ExtraOvertimeType3ID != null && objAttendanceTableItem.ExtraOvertimeType3ID != Guid.Empty)
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.ExtraOvertimeType3ID).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 5 : Att_AttendanceTableItem.ExtraOvertimeType4ID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE4CODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE4CODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overTimeCode = string.Empty;

                    if (objAttendanceTableItem.ExtraOvertimeType4ID != null && objAttendanceTableItem.ExtraOvertimeType4ID != Guid.Empty)
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.ExtraOvertimeType4ID).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Số giờ OT 1: Att_AttendanceTableItem.OvertimeHours
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEHOURS_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMEHOURS_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.OvertimeHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Số giờ OT 2: Att_AttendanceTableItem.ExtraOvertimeHours
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMEHOURS_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMEHOURS_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.ExtraOvertimeHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Số giờ OT 3: Att_AttendanceTableItem.ExtraOvertimeHours2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMEHOURS2_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMEHOURS2_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.ExtraOvertimeHours2.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Số giờ OT 4: Att_AttendanceTableItem.ExtraOvertimeHours3
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMEHOURS3_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMEHOURS3_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.ExtraOvertimeHours3.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Số giờ OT 5: Att_AttendanceTableItem.ExtraOvertimeHours4
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMEHOURS4_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMEHOURS4_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double extraOvertimeHours4 = 0;

                    if (objAttendanceTableItem.ExtraOvertimeHours4 != null)
                    {
                        extraOvertimeHours4 = objAttendanceTableItem.ExtraOvertimeHours4.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, extraOvertimeHours4.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.InTime của loại OT Att_AttendanceTableItem.OvertimeTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMETYPEINTIME_BYDAY.ToString()))
            {
                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.OVERTIMETYPEINTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime = null;

                    var overTime = lisOverTimeByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.OvertimeTypeID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.OvertimeTypeID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.InTime != null)
                    {
                        inTime = overTime.InTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, inTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.InTime của loại OT Att_AttendanceTableItem.ExtraOvertimeTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPEINTIME_BYDAY.ToString()))
            {
                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPEINTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime = null;

                    var overTime = lisOverTimeByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeTypeID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeTypeID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.InTime != null)
                    {
                        inTime = overTime.InTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, inTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.InTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType2ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE2INTIME_BYDAY.ToString()))
            {

                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE2INTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime = null;

                    var overTime = lisOverTimeByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType2ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType2ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.InTime != null)
                    {
                        inTime = overTime.InTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, inTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.InTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType3ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE3INTIME_BYDAY.ToString()))
            {

                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE3INTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime = null;

                    var overTime = lisOverTimeByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType3ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType3ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.InTime != null)
                    {
                        inTime = overTime.InTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, inTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.InTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType4ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE4INTIME_BYDAY.ToString()))
            {

                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE4INTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime = null;

                    var overTime = lisOverTimeByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType4ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType4ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.InTime != null)
                    {
                        inTime = overTime.InTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, inTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.OutTime của loại OT Att_AttendanceTableItem.OvertimeTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMETYPEOUTTIME_BYDAY.ToString()))
            {
                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.OVERTIMETYPEOUTTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? outTime = null;

                    var overTime = lisOverTimeByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.OvertimeTypeID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.OvertimeTypeID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.OutTime != null)
                    {
                        outTime = overTime.OutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, outTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.OutTime của loại OT Att_AttendanceTableItem.ExtraOvertimeTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPEOUTTIME_BYDAY.ToString()))
            {
                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPEOUTTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? outTime = null;

                    var overTime = lisOverTimeByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeTypeID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeTypeID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.OutTime != null)
                    {
                        outTime = overTime.OutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, outTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.OutTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType2ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE2OUTTIME_BYDAY.ToString()))
            {
                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE2OUTTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? outTime = null;

                    var overTime = lisOverTimeByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType2ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType2ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.OutTime != null)
                    {
                        outTime = overTime.OutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, outTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.OutTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType3ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE3OUTTIME_BYDAY.ToString()))
            {
                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE3OUTTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? outTime = null;

                    var overTime = lisOverTimeByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType3ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType3ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.OutTime != null)
                    {
                        outTime = overTime.OutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, outTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.OutTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType4ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE4OUTTIME_BYDAY.ToString()))
            {
                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE4OUTTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? outTime = null;

                    var overTime = lisOverTimeByProfileDic.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType4ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType4ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.OutTime != null)
                    {
                        outTime = overTime.OutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, outTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran  [24/09/2018][0098656][Modify Func] ATT_WORKDAY.SRCTYPE  (ATTWORKDAYSRCTYPE_BYDAY)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.ATTWORKDAYSRCTYPE_BYDAY.ToString()))
            {
                //Lấy data WorkDay nếu chưa được lấy trước đó
                string status = string.Empty;
                string nameTableGetData = "listAttWorkday";
                if (!TotalData.dicTableGetDataByProfileIDs.ContainsKey(nameTableGetData))
                {
                    TotalData.listAttWorkday = dataComputeSer.GetListAttWorkDay(TotalData.strOrderByProfile, CutOffDuration, ref status);
                    TotalData.dicTableGetDataByProfileIDs.Add(nameTableGetData, "");
                }
                //Trường hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông lưu store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.ATTWORKDAYSRCTYPE_BYDAY.ToString() + ") ";
                }
                else
                {
                    string colum = PayrollElementByDay.ATTWORKDAYSRCTYPE_BYDAY.ToString();
                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = colum;
                    objColumn.ValueType = strString;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();

                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        string srcType = string.Empty;
                        var objWorkDate = TotalData.listAttWorkday.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date
                        ).FirstOrDefault();
                        if (objWorkDate != null && !string.IsNullOrEmpty(objWorkDate.SrcType))
                        {
                            srcType = objWorkDate.SrcType;
                        }
                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, srcType.ToString());
                        }
                        indexRow += 1;
                    }

                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion

            #region Tung.Tran [26/09/2018][98838][Modify Func] Enum mã chế độ công : Att_AttendanceTableItem.GradeAttendanceID.Code tương ứng từng ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.GRADEATTENDANCECODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.GRADEATTENDANCECODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string gradeAttendanceCode = string.Empty;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.GradeAttendanceID))
                    {
                        var objGradeAttendance = TotalDataAll.ListCat_GradeAttendance.Where(a => a.ID == objAttendanceTableItem.GradeAttendanceID).FirstOrDefault();
                        if (objGradeAttendance != null && !string.IsNullOrEmpty(objGradeAttendance.Code))
                        {
                            gradeAttendanceCode = objGradeAttendance.Code;
                        }
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, gradeAttendanceCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [29/09/2018][98920][Modify Func] Số phút muộn chuyên cần sau làm tròn: LateInMinutes2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.LATEINMINUTES2_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.LATEINMINUTES2_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double lateInMinutes2 = 0;
                    if (objAttendanceTableItem.LateInMinutes2 != null)
                    {
                        lateInMinutes2 = objAttendanceTableItem.LateInMinutes2.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, lateInMinutes2.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [29/09/2018][98920][Modify Func] Số phút muộn chuyên cần sau làm tròn: LateInMinutes2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EARLYOUTMINUTES2_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.EARLYOUTMINUTES2_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double earlyOutMinutes2 = 0;
                    if (objAttendanceTableItem.EarlyOutMinutes2 != null)
                    {
                        earlyOutMinutes2 = objAttendanceTableItem.EarlyOutMinutes2.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, earlyOutMinutes2.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [29/09/2018][98920][Modify Func] Số phút muộn chuyên cần sau làm tròn: LateEarlyMinutes2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.LATEEARLYMINUTES2_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.LATEEARLYMINUTES2_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double lateEarlyMinutes2 = 0;
                    if (objAttendanceTableItem.LateEarlyMinutes2 != null)
                    {
                        lateEarlyMinutes2 = objAttendanceTableItem.LateEarlyMinutes2.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, lateEarlyMinutes2.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [15/10/2018][99513][Modify Func] Enum Giờ vào: FistInTime
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.FIRSTINTIME_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.FIRSTINTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? firstInTime = null;
                    if (objAttendanceTableItem.FirstInTime != null)
                    {
                        firstInTime = objAttendanceTableItem.FirstInTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, firstInTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [15/10/2018][99513][Modify Func] Enum Giờ vào: LastOutTime
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.LASTOUTTIME_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.LASTOUTTIME_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? lastOutTime = null;
                    if (objAttendanceTableItem.LastOutTime != null)
                    {
                        lastOutTime = objAttendanceTableItem.LastOutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, lastOutTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [16/10/2018][100008][Modify Func] Ngày thay đổi lương trong tháng : BASICSALARYDATEOFEFFECT_BYDAY
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.BASICSALARYDATEOFEFFECT_BYDAY.ToString()))
            {
                var listBasicSalaryByProfileDic = TotalDataAll.dicBasicSalary.GetValueOrNew(profileItem.ID);
                string colum = PayrollElementByDay.BASICSALARYDATEOFEFFECT_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                List<Sal_BasicSalaryEntity> SalaryProfile = new List<Sal_BasicSalaryEntity>();
                DateTime? dateChangeSalary = null;
                // Lấy lương cơ bản tương ứng của nhân viên
                SalaryProfile = listBasicSalaryByProfileDic.Where(m => m.ProfileID == profileItem.ID && m.DateOfEffect <= CutOffDuration.DateEnd).OrderByDescending(m => m.DateOfEffect).ToList();
                // Kiểm tra có thay đổi lương hay không
                if (SalaryProfile != null && SalaryProfile.Any() && computePayrollSer.CheckIsChangeBasicSalary(listBasicSalaryByProfileDic.Where(m => m.DateOfEffect <= CutOffDuration.DateEnd).ToList(), CutOffDuration.DateStart, CutOffDuration.DateEnd, profileItem.ID))
                {// Có thay đổi lương trong tháng
                    dateChangeSalary = SalaryProfile.FirstOrDefault().DateOfEffect; // Lấy ra ngày thay đổi lương
                }

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dateChangeSalary.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Mã loại OT OFF 1 Att_AttendanceTableItem.OvertimeOFFTypeID1.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFTYPE1CODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFTYPE1CODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var overTimeOffTypeCode = string.Empty;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.OvertimeOFFTypeID1))
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.OvertimeOFFTypeID1).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeOffTypeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeOffTypeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Mã loại OT OFF 2 Att_AttendanceTableItem.OvertimeOFFTypeID2.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFTYPE2CODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFTYPE2CODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var overTimeOffTypeCode = string.Empty;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.OvertimeOFFTypeID2))
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.OvertimeOFFTypeID2).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeOffTypeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeOffTypeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Mã loại OT OFF 3 Att_AttendanceTableItem.OvertimeOFFTypeID3.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFTYPE3CODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFTYPE3CODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var overTimeOffTypeCode = string.Empty;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.OvertimeOFFTypeID3))
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.OvertimeOFFTypeID3).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeOffTypeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeOffTypeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func]  Số giờ OT OFF 1 : Att_AttendanceTableItem.OvertimeOFFHours1
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFHOURS1_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFHOURS1_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double overtimeOFFHours = 0;


                    if (objAttendanceTableItem.OvertimeOFFHours1 != null)
                    {
                        overtimeOFFHours = objAttendanceTableItem.OvertimeOFFHours1.Value;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func]  Số giờ OT OFF 2 : Att_AttendanceTableItem.OvertimeOFFHours2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFHOURS2_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFHOURS2_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double overtimeOFFHours = 0;


                    if (objAttendanceTableItem.OvertimeOFFHours2 != null)
                    {
                        overtimeOFFHours = objAttendanceTableItem.OvertimeOFFHours2.Value;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func]  Số giờ OT OFF 3 : Att_AttendanceTableItem.OvertimeOFFHours3
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFHOURS3_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFHOURS3_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double overtimeOFFHours = 0;


                    if (objAttendanceTableItem.OvertimeOFFHours3 != null)
                    {
                        overtimeOFFHours = objAttendanceTableItem.OvertimeOFFHours3.Value;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Loại đăng ký OT 1: Att_AttendanceTableItem.OvertimeOFFDurationType1
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFDURATIONTYPE1_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFDURATIONTYPE1_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overtimeOFFDurationType = string.Empty;

                    if (!string.IsNullOrEmpty(objAttendanceTableItem.OvertimeOFFDurationType1))
                    {
                        overtimeOFFDurationType = objAttendanceTableItem.OvertimeOFFDurationType1;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFDurationType.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Loại đăng ký OT 1: Att_AttendanceTableItem.OvertimeOFFDurationType2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFDURATIONTYPE2_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFDURATIONTYPE2_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overtimeOFFDurationType = string.Empty;

                    if (!string.IsNullOrEmpty(objAttendanceTableItem.OvertimeOFFDurationType2))
                    {
                        overtimeOFFDurationType = objAttendanceTableItem.OvertimeOFFDurationType2;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFDurationType.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Loại đăng ký OT 1: Att_AttendanceTableItem.OvertimeOFFDurationType3
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFDURATIONTYPE3_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFDURATIONTYPE3_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overtimeOFFDurationType = string.Empty;

                    if (!string.IsNullOrEmpty(objAttendanceTableItem.OvertimeOFFDurationType3))
                    {
                        overtimeOFFDurationType = objAttendanceTableItem.OvertimeOFFDurationType3;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFDurationType.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [03/11/2018][0100158][Modify Func] Enum DutyCode
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DUTYCODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.DUTYCODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string dutyCode = string.Empty;
                    if (!string.IsNullOrEmpty(objAttendanceTableItem.DutyCode))
                    {
                        dutyCode = objAttendanceTableItem.DutyCode;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dutyCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [14/11/2018][0100555][Modify Func] Enum đếm số ngày nghỉ từng ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.COUNTLEAVEDAY_BYDAY.ToString()))
            {
                var listLeaveDayByProfileDic = TotalDataAll.dicLeaveDay.GetValueOrNew(profileItem.ID);

                string colum = PayrollElementByDay.COUNTLEAVEDAY_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double countLeaveDay = 0;
                    var lstLeaveDay = listLeaveDayByProfileDic.Where(
                      s => s.ProfileID == profileItem.ID
                      && s.Status == strLeaveDayStatus
                      && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                      && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                      ).ToList();
                    if (lstLeaveDay != null)
                    {
                        countLeaveDay = lstLeaveDay.Count;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, countLeaveDay.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [23/11/2018][101188][Modify Func] Enum lấy ca làm việc từ hàm GetdailyShift 
            // TH: Nhân viên nghỉ việc, nhân viên mới vào làm vẫn có ca làm việc nhưng tính công chưa lưu thông tin vào bảng công.
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.GETDAILYSHIFTCODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.GETDAILYSHIFTCODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                var listRosterByProfileDic = TotalDataAll.dicRoster.GetValueOrNew(profileItem.ID);

                // Ds ca Roster theo profileID và kỳ công
                var listRosterByProfile = listRosterByProfileDic.Where(m => m.ProfileID == profileItem.ID && m.DateStart <= CutOffDuration.DateEnd && m.DateEnd >= CutOffDuration.DateStart && m.Status == RosterStatus.E_APPROVED.ToString()).ToList();

                //DS RosterGroup của kỳ công
                var listRosterGroup = TotalDataAll.ListRosterGroup.Where(s => s.Status == RosterStatus.E_APPROVED.ToString() && s.DateStart <= CutOffDuration.DateEnd && s.DateEnd >= CutOffDuration.DateStart).ToList();

                //Lịch làm việc của tháng N
                var lstDailyShift = Att_AttendanceLib.GetDailyShifts(
                    CutOffDuration.DateStart,
                    CutOffDuration.DateEnd,
                    profileItem.ID, 
                    listRosterByProfile,
                    listRosterGroup,
                    TotalDataAll.listRosterGroupByOrganization,
                    TotalDataAll.listRosterGroupType,
                    TotalDataAll.listOrgStructure,
                    TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID)
                            .Where(s => s.ProfileID == profileItem.ID 
                            && s.DateEffective <= CutOffDuration.DateEnd
                            && s.Status == WorkHistoryStatus.E_APPROVED.ToString())
                            .FirstOrDefault());

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var shiftCode = string.Empty;
                    if (lstDailyShift.ContainsKey(objAttendanceTableItem.WorkDate) && lstDailyShift[objAttendanceTableItem.WorkDate] != null && lstDailyShift[objAttendanceTableItem.WorkDate].Count > 0)
                    {
                        try
                        {
                            // Lấy ca đầu tiên
                            var shiftID = lstDailyShift[objAttendanceTableItem.WorkDate][0];
                            var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == shiftID);
                            if (objShift != null && objShift.Code != null)
                            {
                                shiftCode = objShift.Code;
                            }
                        }
                        catch (Exception ex)
                        {

                        }
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, shiftCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [06/12/2018][0101574] Phần tử ngày kiểm tra có tồn tại dòng chi phí hồ sơ (Chưa hỗ trợ true/false, dùng 1,0 để xác định)

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.UNUSUALALLOWANCE_COSTCV_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.UNUSUALALLOWANCE_COSTCV_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                string status = string.Empty;
                dataComputeSer.GetListSalUnusualAllowance(TotalData, CutOffDuration, ref status);
                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.UNUSUALALLOWANCE_COSTCV_BYDAY.ToString() + ") ";
                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, 0.ToString());
                        }
                        indexRow += 1;
                    }
                }
                else
                {
                    var listUnusualAllowanceProfile = TotalData.dicSalUnusualAllowance.GetValueOrNew(profileItem.ID);
                    // Lấy danh sách loại phụ cấp chi phí hồ sơ
                    var listUnusualCfgCostCvIDs = TotalDataAll.listUnusualAllowanceCfg.Where(x => x.UnusualAllowanceGroup == UnusualAllowanceGroup.E_COSTCV.ToString()).Select(x => x.ID).ToArray(); ;

                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        var isIncludeCostCV = 0;
                        var objUnusualCostCv = listUnusualAllowanceProfile.FirstOrDefault(x =>
                        x.ProfileID == profileItem.ID
                        && x.MonthStart != null && x.MonthEnd != null && !Common.IsNullOrGuidEmpty(x.UnusualEDTypeID)
                        && x.MonthStart.Value.Date <= objAttendanceTableItem.WorkDate.Date
                        && x.MonthEnd.Value.Date >= objAttendanceTableItem.WorkDate.Date
                        && listUnusualCfgCostCvIDs.Contains(x.UnusualEDTypeID.Value));

                        if (objUnusualCostCv != null)
                        {
                            isIncludeCostCV = 1;
                        }
                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, isIncludeCostCV.ToString());
                        }
                        indexRow += 1;
                    }
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [06/12/2018][0101574] Phần tử ngày lấy ra số giờ nghỉ giải lao của nhân viên trong ngày

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.SUMSHIFTBREAKHOUR_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.SUMSHIFTBREAKHOUR_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                // Lấy data nếu chưa được lấy trước đó
                string status = string.Empty;
                string nameTableGetData = "listCat_ShiftItem";
                if (!TotalData.dicTableGetDataCategory.ContainsKey(nameTableGetData))
                {
                    TotalData.listCat_ShiftItem = dataComputeSer.GetShiftItem(ShiftItemType.E_SHIFTBREAK.ToString(), ref status);
                    TotalData.dicTableGetDataCategory.Add(nameTableGetData, "");
                }

                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.SUMSHIFTBREAKHOUR_BYDAY.ToString() + ") ";
                    int indexRow = 0;
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, 0.ToString());
                        }
                        indexRow += 1;
                    }
                }
                else
                {
                    if (TotalData.listCat_ShiftItem.Count > 0)
                    {
                        #region Xử lý lấy dữ liệu

                        var listShiftID = TotalData.listCat_ShiftItem.Select(s => s.ShiftID).Distinct().ToList();

                        listShiftID = listAttendanceTableItem.Where(s => s.ShiftID != null).Select(s => s.ShiftID.Value).Distinct().ToList();
                        var listShiftItem = TotalData.listCat_ShiftItem.Where(s => listShiftID.Contains(s.ShiftID)).ToList();

                        var listLeaveDayInDate = TotalDataAll.dicLeaveDayNotStatus.GetValueOrNew(profileItem.ID)
                            .Where(s => s.DateStart <= CutOffDuration.DateEnd
                                && s.DateEnd >= CutOffDuration.DateStart)
                            .ToList();

                        var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                        string statusLeaveday = string.Empty;
                        if (objAllSetting != null && !string.IsNullOrEmpty(objAllSetting.Value1))
                        {
                            statusLeaveday = objAllSetting.Value1;
                            listLeaveDayInDate = listLeaveDayInDate.Where(s => s.Status == statusLeaveday).ToList();
                        }
                        //lay ds ngày nghỉ sau khi tách ra từng ngày
                        Att_LeavedayServices leavedayServices = new Att_LeavedayServices();
                        var listLeaveDayForDate = new List<Att_LeaveDayEntity>();
                        if (listLeaveDayInDate.Count > 0)
                        {
                            var listRosterByPro = TotalDataAll.dicRoster.GetValueOrNew(profileItem.ID);
                            listLeaveDayForDate = leavedayServices.SplitLeaveByDayNotGetData(listLeaveDayInDate, ModifyType.E_EDIT.ToString(), listRosterByPro, TotalDataAll.ListRosterGroup.ToList(), TotalDataAll.listCat_Shift.ToList() , new List<Att_RosterGroupByOrganizationEntity>(), new List<Cat_RosterGroupTypeEntity>(), new List<Cat_OrgStructureEntity>(), new Dictionary<Guid, List<Hre_WorkHistoryEntity>>());
                        }

                        #endregion

                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {

                            double _SHIFTBREAK_HOUR = 0;

                            #region Xử lý tính thời gian nghỉ giải lao
                            if (objAttendanceTableItem.FirstInTime != null && objAttendanceTableItem.LastOutTime != null)
                            {
                                //neu có đăng ký nghỉ full ca => không tính giờ nghỉ ngày này
                                var countFULLSHIFT = listLeaveDayForDate
                                    .Where(s => s.DateStart.Date == objAttendanceTableItem.WorkDate.Date && s.DurationType == LeaveDayType.E_FULLSHIFT.ToString()).Count();
                                if (countFULLSHIFT == 0)
                                {
                                    DateTime firstInTime = objAttendanceTableItem.FirstInTime.Value;
                                    DateTime lastOutTime = objAttendanceTableItem.LastOutTime.Value;

                                    var objShift = TotalDataAll.listCat_Shift.Where(s => s.ID == objAttendanceTableItem.ShiftID).FirstOrDefault();
                                    if (objShift != null)
                                    {
                                        DateTime inTimeByShift = new DateTime(
                                                    objAttendanceTableItem.WorkDate.Year,
                                                    objAttendanceTableItem.WorkDate.Month,
                                                    objAttendanceTableItem.WorkDate.Day,
                                                    objShift.InTime.Hour,
                                                    objShift.InTime.Minute,
                                                    objShift.InTime.Second
                                                );

                                        DateTime outTimeByShift = inTimeByShift.AddHours(objShift.CoOut);

                                        var listShiftItemByWorkDate = listShiftItem.Where(s => s.ShiftID == objAttendanceTableItem.ShiftID).ToList();
                                        //có loại nghỉ trong ngày thi trừ giờ nghỉ nếu trùng
                                        if (listShiftItemByWorkDate.Count > 0)
                                        {
                                            //khong tru gio nghi giai lao khi nghi ngoai ca
                                            var listLeaveDayByWorkDate = listLeaveDayForDate
                                                .Where(s => s.DateStart.Date == objAttendanceTableItem.WorkDate
                                                    && s.DurationType != LeaveDayDurationType.E_FULLSHIFT.ToString()
                                                    && s.DurationType != LeaveDayDurationType.E_OUT_OF_SHIFT.ToString())
                                                .OrderBy(s => s.DateStart)
                                                .ToList();
                                            foreach (var objShiftItemByWorkDate in listShiftItemByWorkDate)
                                            {
                                                bool isCheck = true;
                                                DateTime dateFromShiftBreak = inTimeByShift.AddHours(objShiftItemByWorkDate.CoFrom);
                                                DateTime dateToShiftBreak = inTimeByShift.AddHours(objShiftItemByWorkDate.CoTo);

                                                //[19/12/2018][bang.nguyen][102046][bug]
                                                //logic ban dau tin.nguyen dua xu lý thiếu trường hợp ca đêm
                                                // đối với ca đêm xác định giờ nghỉ giữa ca => cộng thêm 1 ngày
                                                if (objShift.IsNightShift)
                                                {
                                                    if (objShiftItemByWorkDate.CoFrom < 0)
                                                    {
                                                        dateFromShiftBreak = dateFromShiftBreak.AddDays(1);
                                                    }
                                                    if (objShiftItemByWorkDate.CoTo < 0)
                                                    {
                                                        dateToShiftBreak = dateToShiftBreak.AddDays(1);
                                                    }
                                                }

                                                //không tính giờ nghỉ giải lao: neu giờ bắt đầu nghỉ <= giờ bắt đầu giữa ca và giờ kết thúc nghỉ >= giờ kết thúc giữa ca
                                                foreach (var objLeaveDayByWorkDate in listLeaveDayByWorkDate)
                                                {
                                                    DateTime dateStartLeave = objLeaveDayByWorkDate.DateStart;
                                                    DateTime dateEndLeave = objLeaveDayByWorkDate.DateEnd;
                                                    //neu datastart  ngay nghi nam ngoai in out của ca => + thêm 1 ngày 
                                                    if (objShift.IsNightShift)
                                                    {
                                                        if (dateStartLeave < inTimeByShift || dateStartLeave > outTimeByShift)
                                                        {
                                                            dateStartLeave = dateStartLeave.AddDays(1);
                                                        }
                                                        //neu dateend  ngay nghi nam ngoai in out của ca => + thêm 1 ngày 
                                                        if (dateEndLeave < inTimeByShift || dateEndLeave > outTimeByShift)
                                                        {
                                                            dateEndLeave = dateEndLeave.AddDays(1);
                                                        }
                                                    }

                                                    // neu giờ bắt đầu nghỉ <= giờ bắt đầu giữa ca và giờ kết thúc nghỉ >= giờ kết thúc giữa ca
                                                    //=> không được tính giờ nghỉ giải lao
                                                    if (dateStartLeave <= dateFromShiftBreak && dateEndLeave >= dateToShiftBreak)
                                                    {
                                                        isCheck = false;
                                                        break;
                                                    }
                                                }
                                                if (isCheck)
                                                {
                                                    //giờ quẹt thẻ vao ra có giao giờ giải lao => mới được tính giờ nghỉ giải lao ngày đó
                                                    if (firstInTime <= dateToShiftBreak && lastOutTime >= dateFromShiftBreak)
                                                    {
                                                        DateTime tempDateFrom = dateFromShiftBreak;
                                                        DateTime tempDateTo = dateToShiftBreak;
                                                        //giờ quẹt thẻ vao > giờ bắt đầu nghỉ giải lao
                                                        if (firstInTime > tempDateFrom)
                                                        {
                                                            tempDateFrom = firstInTime;
                                                        }
                                                        //giờ quẹt thẻ ra < giờ kết thúc nghỉ giải lao
                                                        if (lastOutTime < tempDateTo)
                                                        {
                                                            tempDateTo = lastOutTime;
                                                        }
                                                        _SHIFTBREAK_HOUR += (tempDateTo - tempDateFrom).TotalHours;
                                                        //nếu có giao => loại trừ khoảng giờ nghỉ có giao
                                                        double totalHourLeaveDay = 0;
                                                        foreach (var objLeaveDayByWorkDate in listLeaveDayByWorkDate)
                                                        {
                                                            DateTime dateStartLeave = objLeaveDayByWorkDate.DateStart;
                                                            DateTime dateEndLeave = objLeaveDayByWorkDate.DateEnd;
                                                            //neu datastart  ngay nghi nam ngoai in out của ca => + thêm 1 ngày 
                                                            if (objShift.IsNightShift)
                                                            {
                                                                if (dateStartLeave < inTimeByShift || dateStartLeave > outTimeByShift)
                                                                {
                                                                    dateStartLeave = dateStartLeave.AddDays(1);
                                                                }
                                                                //neu dateend  ngay nghi nam ngoai in out của ca => + thêm 1 ngày 
                                                                if (dateEndLeave < inTimeByShift || dateEndLeave > outTimeByShift)
                                                                {
                                                                    dateEndLeave = dateEndLeave.AddDays(1);
                                                                }
                                                            }
                                                            // có giao giữa giờ nghỉ giải lao và giờ nghỉ thì mới trừ
                                                            if (tempDateFrom <= dateEndLeave && tempDateTo >= dateStartLeave)
                                                            {
                                                                if (dateStartLeave < tempDateFrom)
                                                                {
                                                                    dateStartLeave = tempDateFrom;
                                                                }
                                                                if (dateEndLeave > tempDateTo)
                                                                {
                                                                    dateEndLeave = tempDateTo;
                                                                }
                                                                totalHourLeaveDay += (dateEndLeave - dateStartLeave).TotalHours;
                                                            }
                                                        }
                                                        if (totalHourLeaveDay >= 0)
                                                        {
                                                            _SHIFTBREAK_HOUR -= totalHourLeaveDay;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            #endregion

                            if (!listValue.ContainsKey(indexRow))
                            {
                                listValue.Add(indexRow, _SHIFTBREAK_HOUR.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                }

                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [22/12/2018][102060] Enum Loại chế độ từng ngày

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.PREGNANCYTYPE_BYDAY.ToString() }))
            {
                string colum = PayrollElementByDay.PREGNANCYTYPE_BYDAY.ToString();

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = colum;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var pregnancyType = string.Empty;

                    if (!string.IsNullOrEmpty(objAttendanceTableItem.PregnancyType))
                    {
                        pregnancyType = objAttendanceTableItem.PregnancyType;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, pregnancyType);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValue;
                listColumnByDay.Add(objColumnByDay);
            }

            #endregion

            #region [24/12/2018][102024]: Enum giờ bắt đầu nghỉ ca 1
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.CATSHIFT_COBREAKIN_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.CATSHIFT_COBREAKIN_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? dateTimeCoBreakIn = null;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.ShiftID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null)
                        {
                            dateTimeCoBreakIn = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                        objAttendanceTableItem.WorkDate.Month,
                                        objAttendanceTableItem.WorkDate.Day,
                                        objShift.InTime.Hour,
                                        objShift.InTime.Minute,
                                        objShift.InTime.Second
                                        ).AddHours(objShift.CoBreakIn);
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dateTimeCoBreakIn.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region [24/12/2018][102024]: Enum giờ bắt đầu nghỉ ca 2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.CATSHIFT2_COBREAKIN_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.CATSHIFT2_COBREAKIN_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? dateTimeCoBreakIn = null;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.Shift2ID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.Shift2ID);
                        if (objShift != null)
                        {

                            dateTimeCoBreakIn = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                       objAttendanceTableItem.WorkDate.Month,
                                       objAttendanceTableItem.WorkDate.Day,
                                       objShift.InTime.Hour,
                                       objShift.InTime.Minute,
                                       objShift.InTime.Second
                                       ).AddHours(objShift.CoBreakIn);
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dateTimeCoBreakIn.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region [24/12/2018][102024]: Enum giờ kết thúc nghỉ ca 1
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.CATSHIFT_COBREAKOUT_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.CATSHIFT_COBREAKOUT_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? dateTimeCoBreakOut = null;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.ShiftID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null)
                        {

                            dateTimeCoBreakOut = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                       objAttendanceTableItem.WorkDate.Month,
                                       objAttendanceTableItem.WorkDate.Day,
                                       objShift.InTime.Hour,
                                       objShift.InTime.Minute,
                                       objShift.InTime.Second
                                       ).AddHours(objShift.CoBreakOut);
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dateTimeCoBreakOut.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region [24/12/2018][102024]: Enum giờ kết thúc nghỉ ca 2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.CATSHIFT2_COBREAKOUT_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.CATSHIFT2_COBREAKOUT_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? dateTimeCoBreakOut = null;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.Shift2ID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.Shift2ID);
                        if (objShift != null)
                        {
                            dateTimeCoBreakOut = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                        objAttendanceTableItem.WorkDate.Month,
                                        objAttendanceTableItem.WorkDate.Day,
                                        objShift.InTime.Hour,
                                        objShift.InTime.Minute,
                                        objShift.InTime.Second
                                        ).AddHours(objShift.CoBreakOut);

                        }
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dateTimeCoBreakOut.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [19/02/2019][102996]
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new[]
           {
                PayrollElementByDay.ATT_OVERTIMETYPE1_TAXTOTAL_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMETYPE2_TAXTOTAL_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMETYPE3_TAXTOTAL_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMETYPE4_TAXTOTAL_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMETYPE5_TAXTOTAL_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMEHOUR1_TAXTOTAL_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMEHOUR2_TAXTOTAL_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMEHOUR3_TAXTOTAL_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMEHOUR4_TAXTOTAL_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMEHOUR5_TAXTOTAL_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMETYPE1_TAXPROPORTION_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMETYPE2_TAXPROPORTION_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMETYPE3_TAXPROPORTION_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMETYPE4_TAXPROPORTION_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMETYPE5_TAXPROPORTION_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMEHOUR1_TAXPROPORTION_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMEHOUR2_TAXPROPORTION_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMEHOUR3_TAXPROPORTION_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMEHOUR4_TAXPROPORTION_BYDAY.ToString(),
                PayrollElementByDay.ATT_OVERTIMEHOUR5_TAXPROPORTION_BYDAY.ToString(),
            }
           ))
            {

                #region Get data
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }

                //lay data nếu chưa được lấy trước đó
                string status = string.Empty;
                string nameTableGetData = "listOverTimeByDateApprove";
                if (!TotalData.dicTableGetDataByProfileIDs.ContainsKey(nameTableGetData))
                {
                    TotalData.listOverTimeByDateApprove = dataComputeSer.GetListOverTimeTimeLineByDateApprove(TotalData.strOrderByProfile, CutOffDuration, ref status);
                    TotalData.dicTableGetDataByProfileIDs.Add(nameTableGetData, "");
                }

                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông lưu store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.ATT_OVERTIMETYPE1_TAXTOTAL_BYDAY.ToString() + ") ";
                }
                #endregion
                else
                {
                    #region Khai báo

                    #region ATT_OVERTIMETYPE1_TAXTOTAL_BYDAY
                    ColumnByDay objColumnTypeTotal1 = new ColumnByDay();
                    objColumnTypeTotal1.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE1_TAXTOTAL_BYDAY.ToString();
                    objColumnTypeTotal1.ValueType = strString;
                    Dictionary<int, string> listValueTypeTotal1 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE2_TAXTOTAL_BYDAY
                    ColumnByDay objColumnTypeTotal2 = new ColumnByDay();
                    objColumnTypeTotal2.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE2_TAXTOTAL_BYDAY.ToString();
                    objColumnTypeTotal2.ValueType = strString;
                    Dictionary<int, string> listValueTypeTotal2 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE3_TAXTOTAL_BYDAY
                    ColumnByDay objColumnTypeTotal3 = new ColumnByDay();
                    objColumnTypeTotal3.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE3_TAXTOTAL_BYDAY.ToString();
                    objColumnTypeTotal3.ValueType = strString;
                    Dictionary<int, string> listValueTypeTotal3 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE4_TAXTOTAL_BYDAY
                    ColumnByDay objColumnTypeTotal4 = new ColumnByDay();
                    objColumnTypeTotal4.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE4_TAXTOTAL_BYDAY.ToString();
                    objColumnTypeTotal4.ValueType = strString;
                    Dictionary<int, string> listValueTypeTotal4 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE5_TAXTOTAL_BYDAY
                    ColumnByDay objColumnTypeTotal5 = new ColumnByDay();
                    objColumnTypeTotal5.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE5_TAXTOTAL_BYDAY.ToString();
                    objColumnTypeTotal5.ValueType = strString;
                    Dictionary<int, string> listValueTypeTotal5 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR1_TAXTOTAL_BYDAY
                    ColumnByDay objColumnHourTotal1 = new ColumnByDay();
                    objColumnHourTotal1.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR1_TAXTOTAL_BYDAY.ToString();
                    objColumnHourTotal1.ValueType = strDouble;
                    Dictionary<int, string> listValueHourTotal1 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR2_TAXTOTAL_BYDAY
                    ColumnByDay objColumnHourTotal2 = new ColumnByDay();
                    objColumnHourTotal2.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR2_TAXTOTAL_BYDAY.ToString();
                    objColumnHourTotal2.ValueType = strDouble;
                    Dictionary<int, string> listValueHourTotal2 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR3_TAXTOTAL_BYDAY
                    ColumnByDay objColumnHourTotal3 = new ColumnByDay();
                    objColumnHourTotal3.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR3_TAXTOTAL_BYDAY.ToString();
                    objColumnHourTotal3.ValueType = strDouble;
                    Dictionary<int, string> listValueHourTotal3 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR4_TAXTOTAL_BYDAY
                    ColumnByDay objColumnHourTotal4 = new ColumnByDay();
                    objColumnHourTotal4.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR4_TAXTOTAL_BYDAY.ToString();
                    objColumnHourTotal4.ValueType = strDouble;
                    Dictionary<int, string> listValueHourTotal4 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR5_TAXTOTAL_BYDAY
                    ColumnByDay objColumnHourTotal5 = new ColumnByDay();
                    objColumnHourTotal5.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR5_TAXTOTAL_BYDAY.ToString();
                    objColumnHourTotal5.ValueType = strDouble;
                    Dictionary<int, string> listValueHourTotal5 = new Dictionary<int, string>();
                    #endregion

                    ///////////////////////////////////

                    #region ATT_OVERTIMETYPE1_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnTypeProportion1 = new ColumnByDay();
                    objColumnTypeProportion1.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE1_TAXPROPORTION_BYDAY.ToString();
                    objColumnTypeProportion1.ValueType = strString;
                    Dictionary<int, string> listValueTypeProportion1 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE2_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnTypeProportion2 = new ColumnByDay();
                    objColumnTypeProportion2.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE2_TAXPROPORTION_BYDAY.ToString();
                    objColumnTypeProportion2.ValueType = strString;
                    Dictionary<int, string> listValueTypeProportion2 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE3_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnTypeProportion3 = new ColumnByDay();
                    objColumnTypeProportion3.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE3_TAXPROPORTION_BYDAY.ToString();
                    objColumnTypeProportion3.ValueType = strString;
                    Dictionary<int, string> listValueTypeProportion3 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE4_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnTypeProportion4 = new ColumnByDay();
                    objColumnTypeProportion4.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE4_TAXPROPORTION_BYDAY.ToString();
                    objColumnTypeProportion4.ValueType = strString;
                    Dictionary<int, string> listValueTypeProportion4 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE5_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnTypeProportion5 = new ColumnByDay();
                    objColumnTypeProportion5.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE5_TAXPROPORTION_BYDAY.ToString();
                    objColumnTypeProportion5.ValueType = strString;
                    Dictionary<int, string> listValueTypeProportion5 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR1_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnHourProportion1 = new ColumnByDay();
                    objColumnHourProportion1.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR1_TAXPROPORTION_BYDAY.ToString();
                    objColumnHourProportion1.ValueType = strDouble;
                    Dictionary<int, string> listValueHourProportion1 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR2_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnHourProportion2 = new ColumnByDay();
                    objColumnHourProportion2.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR2_TAXPROPORTION_BYDAY.ToString();
                    objColumnHourProportion2.ValueType = strDouble;
                    Dictionary<int, string> listValueHourProportion2 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR3_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnHourProportion3 = new ColumnByDay();
                    objColumnHourProportion3.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR3_TAXPROPORTION_BYDAY.ToString();
                    objColumnHourProportion3.ValueType = strDouble;
                    Dictionary<int, string> listValueHourProportion3 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR4_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnHourProportion4 = new ColumnByDay();
                    objColumnHourProportion4.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR4_TAXPROPORTION_BYDAY.ToString();
                    objColumnHourProportion4.ValueType = strDouble;
                    Dictionary<int, string> listValueHourProportion4 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR5_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnHourProportion5 = new ColumnByDay();
                    objColumnHourProportion5.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR5_TAXPROPORTION_BYDAY.ToString();
                    objColumnHourProportion5.ValueType = strDouble;
                    Dictionary<int, string> listValueHourProportion5 = new Dictionary<int, string>();
                    #endregion

                    var listOTGroup = TotalData.listOverTimeByDateApprove.Where(x => x.ProfileID == profileItem.ID
                                                && x.DateApprove != null
                                                && x.DateApprove.Value.Date >= CutOffDuration.DateStart.Date
                                                && x.DateApprove.Value.Date <= CutOffDuration.DateEnd.Date
                                                ).GroupBy(x => x.OvertimeTypeID).Select(x => x.Key).ToList();

                    #endregion

                    // Chỉ hỗ trợ 5 nhóm OT
                    int indexGroup = 1;
                    foreach (var itemGroup in listOTGroup.Take(5))
                    {

                        #region get Code
                        var overTimeCode = string.Empty;
                        var objOverTime = TotalDataAll.listOvertimeType.FirstOrDefault(x => x.ID == itemGroup);
                        if (objOverTime != null)
                        {
                            overTimeCode = objOverTime.Code;
                        }
                        #endregion

                        int indexRow = 0;
                        double sumOverTimeHourTotal = 0;
                        double sumOverTimeHourProportion = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {

                            #region E_TOTAL
                            var listOTProfileTaxByToTal = TotalData.listOverTimeByDateApprove.Where(
                                   x => x.ProfileID == profileItem.ID
                                   && x.OvertimeTypeID != null
                                   && x.DateApprove != null
                                   && x.DateApprove.Value.Date == objAttendanceTableItem.WorkDate.Date
                                   && x.Status == strOTStatus
                                   && x.TaxType == "E_TOTAL"
                                   ).ToList();

                            #region get sum Hour

                            if (strOTStatus == EnumDropDown.OverTimeStatus.E_APPROVED.ToString())
                            {
                                sumOverTimeHourTotal = listOTProfileTaxByToTal.Where(x => x.ApproveHours != null && x.OvertimeTypeID == itemGroup).Sum(x => x.ApproveHours.Value);
                            }
                            else if (strOTStatus == EnumDropDown.OverTimeStatus.E_CONFIRM.ToString())
                            {
                                sumOverTimeHourTotal = listOTProfileTaxByToTal.Where(x => x.OvertimeTypeID == itemGroup).Sum(x => x.ConfirmHours);
                            }
                            else if (strOTStatus == EnumDropDown.OverTimeStatus.E_SUBMIT.ToString())
                            {
                                sumOverTimeHourTotal = listOTProfileTaxByToTal.Where(x => x.OvertimeTypeID == itemGroup).Sum(x => x.RegisterHours);
                            }
                            #endregion

                            #region Set value
                            if (!listValueTypeTotal1.ContainsKey(indexRow) && indexGroup == 1)
                            {
                                listValueTypeTotal1.Add(indexRow, overTimeCode);
                                listValueHourTotal1.Add(indexRow, sumOverTimeHourTotal.ToString());
                            }
                            else if (!listValueTypeTotal2.ContainsKey(indexRow) && indexGroup == 2)
                            {
                                listValueTypeTotal2.Add(indexRow, overTimeCode);
                                listValueHourTotal2.Add(indexRow, sumOverTimeHourTotal.ToString());
                            }

                            else if (!listValueTypeTotal3.ContainsKey(indexRow) && indexGroup == 3)
                            {
                                listValueTypeTotal3.Add(indexRow, overTimeCode);
                                listValueHourTotal3.Add(indexRow, sumOverTimeHourTotal.ToString());
                            }
                            else if (!listValueTypeTotal4.ContainsKey(indexRow) && indexGroup == 4)
                            {
                                listValueTypeTotal4.Add(indexRow, overTimeCode);
                                listValueHourTotal4.Add(indexRow, sumOverTimeHourTotal.ToString());
                            }
                            else if (!listValueTypeTotal5.ContainsKey(indexRow) && indexGroup == 5)
                            {
                                listValueTypeTotal5.Add(indexRow, overTimeCode);
                                listValueHourTotal5.Add(indexRow, sumOverTimeHourTotal.ToString());
                            }
                            #endregion

                            #endregion

                            #region E_PROPORTION

                            var listOTProfileTaxByProportion = TotalData.listOverTimeByDateApprove.Where(
                                 x => x.ProfileID == profileItem.ID
                                 && x.OvertimeTypeID != null
                                 && x.DateApprove != null
                                 && x.DateApprove.Value.Date == objAttendanceTableItem.WorkDate.Date
                                 && x.Status == strOTStatus
                                 && x.TaxType == "E_PROPORTION"
                                 ).ToList();

                            #region get sum Hour

                            if (strOTStatus == EnumDropDown.OverTimeStatus.E_APPROVED.ToString())
                            {
                                sumOverTimeHourProportion = listOTProfileTaxByProportion.Where(x => x.ApproveHours != null && x.OvertimeTypeID == itemGroup).Sum(x => x.ApproveHours.Value);
                            }
                            else if (strOTStatus == EnumDropDown.OverTimeStatus.E_CONFIRM.ToString())
                            {
                                sumOverTimeHourProportion = listOTProfileTaxByProportion.Where(x => x.OvertimeTypeID == itemGroup).Sum(x => x.ConfirmHours);
                            }
                            else if (strOTStatus == EnumDropDown.OverTimeStatus.E_SUBMIT.ToString())
                            {
                                sumOverTimeHourProportion = listOTProfileTaxByProportion.Where(x => x.OvertimeTypeID == itemGroup).Sum(x => x.RegisterHours);
                            }
                            #endregion

                            #region Set value
                            if (!listValueTypeProportion1.ContainsKey(indexRow) && indexGroup == 1)
                            {
                                listValueTypeProportion1.Add(indexRow, overTimeCode);
                                listValueHourProportion1.Add(indexRow, sumOverTimeHourProportion.ToString());
                            }
                            else if (!listValueTypeProportion2.ContainsKey(indexRow) && indexGroup == 2)
                            {
                                listValueTypeProportion2.Add(indexRow, overTimeCode);
                                listValueHourProportion2.Add(indexRow, sumOverTimeHourProportion.ToString());
                            }
                            else if (!listValueTypeProportion3.ContainsKey(indexRow) && indexGroup == 3)
                            {
                                listValueTypeProportion3.Add(indexRow, overTimeCode);
                                listValueHourProportion3.Add(indexRow, sumOverTimeHourProportion.ToString());
                            }
                            else if (!listValueTypeProportion4.ContainsKey(indexRow) && indexGroup == 4)
                            {
                                listValueTypeProportion4.Add(indexRow, overTimeCode);
                                listValueHourProportion4.Add(indexRow, sumOverTimeHourProportion.ToString());
                            }
                            else if (!listValueTypeProportion5.ContainsKey(indexRow) && indexGroup == 5)
                            {
                                listValueTypeProportion5.Add(indexRow, overTimeCode);
                                listValueHourProportion5.Add(indexRow, sumOverTimeHourProportion.ToString());
                            }
                            #endregion

                            #endregion

                            indexRow += 1;
                        }
                        indexGroup++;
                    }

                    #region Set Value
                    objColumnTypeTotal1.ListValueByDay = listValueTypeTotal1;
                    listColumnByDay.Add(objColumnTypeTotal1);

                    objColumnTypeTotal2.ListValueByDay = listValueTypeTotal2;
                    listColumnByDay.Add(objColumnTypeTotal2);

                    objColumnTypeTotal3.ListValueByDay = listValueTypeTotal3;
                    listColumnByDay.Add(objColumnTypeTotal3);

                    objColumnTypeTotal4.ListValueByDay = listValueTypeTotal4;
                    listColumnByDay.Add(objColumnTypeTotal4);

                    objColumnTypeTotal5.ListValueByDay = listValueTypeTotal5;
                    listColumnByDay.Add(objColumnTypeTotal5);

                    objColumnHourTotal1.ListValueByDay = listValueHourTotal1;
                    listColumnByDay.Add(objColumnHourTotal1);

                    objColumnHourTotal2.ListValueByDay = listValueHourTotal2;
                    listColumnByDay.Add(objColumnHourTotal2);

                    objColumnHourTotal3.ListValueByDay = listValueHourTotal3;
                    listColumnByDay.Add(objColumnHourTotal3);

                    objColumnHourTotal4.ListValueByDay = listValueHourTotal4;
                    listColumnByDay.Add(objColumnHourTotal4);

                    objColumnHourTotal5.ListValueByDay = listValueHourTotal5;
                    listColumnByDay.Add(objColumnHourTotal5);


                    objColumnTypeProportion1.ListValueByDay = listValueTypeProportion1;
                    listColumnByDay.Add(objColumnTypeProportion1);

                    objColumnTypeProportion2.ListValueByDay = listValueTypeProportion2;
                    listColumnByDay.Add(objColumnTypeProportion2);

                    objColumnTypeProportion3.ListValueByDay = listValueTypeProportion3;
                    listColumnByDay.Add(objColumnTypeProportion3);

                    objColumnTypeProportion4.ListValueByDay = listValueTypeProportion4;
                    listColumnByDay.Add(objColumnTypeProportion4);

                    objColumnTypeProportion5.ListValueByDay = listValueTypeProportion5;
                    listColumnByDay.Add(objColumnTypeProportion5);

                    objColumnHourProportion1.ListValueByDay = listValueHourProportion1;
                    listColumnByDay.Add(objColumnHourProportion1);

                    objColumnHourProportion2.ListValueByDay = listValueHourProportion2;
                    listColumnByDay.Add(objColumnHourProportion2);

                    objColumnHourProportion3.ListValueByDay = listValueHourProportion3;
                    listColumnByDay.Add(objColumnHourProportion3);

                    objColumnHourProportion4.ListValueByDay = listValueHourProportion4;
                    listColumnByDay.Add(objColumnHourProportion4);

                    objColumnHourProportion5.ListValueByDay = listValueHourProportion5;
                    listColumnByDay.Add(objColumnHourProportion5);
                    #endregion
                }
            }

            #endregion

            #region Tung.Tran [26/03/2019][103784] Enum tính tổng số giờ tích lũy tăng ca theo từng ngày (Theo trạng thái tính lũy tiến)

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.ATT_OVERTIME_PROGRESSIVE_BYDAY.ToString()))
            {
                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                // Lấy cấu hình tính lũy tiến
                var strProgressive = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUSPROGRESSIVE.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strProgressive = objAllSetting.Value1;
                }

                string colum = PayrollElementByDay.ATT_OVERTIME_PROGRESSIVE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();
                var arrayStatusCancel = new List<string>() { EnumDropDown.OverTimeStatus.E_CANCEL.ToString(), EnumDropDown.OverTimeStatus.E_REJECTED.ToString() };
                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double sumHoursOT = 0;

                    var listOverTime = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID).Where(
                                       s => s.WorkDateRoot != null
                                       //[Hien.Le][02/04/2019] 0104336 Kiểm tra cấu hình trạng thái tính luỹ tiến là null
                                       && ((string.IsNullOrEmpty(strProgressive) && !arrayStatusCancel.Contains(s.Status))
                                          || (!string.IsNullOrEmpty(strProgressive) && strProgressive.Contains(s.Status)))
                                       && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date).ToList();

                    if (listOverTime != null && listOverTime.Count > 0)
                    {
                        listOverTime.ForEach(itemOverTime =>
                        {
                            if (itemOverTime.Status == "E_CONFIRM")
                            {
                                // Trạng thái xác nhận lấy cột ConfirmHours
                                sumHoursOT += itemOverTime.ConfirmHours;
                            }
                            else if (itemOverTime.Status == "E_APPROVED")
                            {
                                // Trạng thái duyệt lấy cột ApproveHours
                                sumHoursOT += itemOverTime.ApproveHours != null ? itemOverTime.ApproveHours.Value : 0;
                            }
                            else
                            {
                                // Ngược lại lấy cột RegisterHours
                                sumHoursOT += itemOverTime.RegisterHours;
                            }
                        });
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, sumHoursOT.ToString());
                    }
                    indexRow += 1;
                }


                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }


            #endregion

            #region Tung.Tran [26/03/2019][103855]: Thêm phần tử lương ngày: nhóm nhân viên	
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.HR_WORKHISTORY_EMPLOYEEGROUPCODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.HR_WORKHISTORY_EMPLOYEEGROUPCODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;

                var listWorkHistory = TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID)
                            .Where(s => s.ProfileID == profileItem.ID && s.DateEffective <= CutOffDuration.DateEnd && s.Status == WorkHistoryStatus.E_APPROVED.ToString()).ToList();



                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string codeEmployeeGroupCode = string.Empty;

                    var objWorkHistory = listWorkHistory.Where(s =>
                                         s.DateEffective <= objAttendanceTableItem.WorkDate.Date
                                         && s.Status == WorkHistoryStatus.E_APPROVED.ToString()).OrderByDescending(s => s.DateEffective).FirstOrDefault();

                    if (objWorkHistory != null && !string.IsNullOrEmpty(objWorkHistory.EmployeeGroupCode))
                    {
                        codeEmployeeGroupCode = objWorkHistory.EmployeeGroupCode;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, codeEmployeeGroupCode);
                    }
                    indexRow += 1;
                }


                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [03/04/2019][0104014]
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[]
            {
                 PayrollElementByDay.LATECOUNT_BYDAY.ToString(),
                 PayrollElementByDay.EARLYCOUNT_BYDAY.ToString(),
                 PayrollElementByDay.LATEEARLYCOUNT_BYDAY.ToString(),

            }))
            {
                ColumnByDay objColumnLateCount = new ColumnByDay();
                objColumnLateCount.ColumnName = PayrollElementByDay.LATECOUNT_BYDAY.ToString();
                objColumnLateCount.ValueType = strDouble;

                ColumnByDay objColumnEarlyCount = new ColumnByDay();
                objColumnEarlyCount.ColumnName = PayrollElementByDay.EARLYCOUNT_BYDAY.ToString();
                objColumnEarlyCount.ValueType = strDouble;

                ColumnByDay objColumnLateEarlyCount = new ColumnByDay();
                objColumnLateEarlyCount.ColumnName = PayrollElementByDay.LATEEARLYCOUNT_BYDAY.ToString();
                objColumnLateEarlyCount.ValueType = strDouble;


                Dictionary<int, string> listValueLateCount = new Dictionary<int, string>();
                Dictionary<int, string> listValueEarylyCount = new Dictionary<int, string>();
                Dictionary<int, string> listValueLateEarlyCount = new Dictionary<int, string>();

                int indexRow = 0;

                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    int lateCount = 0;
                    int earlyCount = 0;
                    int lateEarlyCount = 0;

                    if (objAttendanceTableItem.LateCount != null)
                    {
                        lateCount = objAttendanceTableItem.LateCount.Value;
                    }

                    if (objAttendanceTableItem.EarlyCount != null)
                    {
                        earlyCount = objAttendanceTableItem.EarlyCount.Value;
                    }

                    if (objAttendanceTableItem.LateEarlyCount != null)
                    {
                        lateEarlyCount = objAttendanceTableItem.LateEarlyCount.Value;
                    }

                    if (!listValueLateCount.ContainsKey(indexRow))
                    {
                        listValueLateCount.Add(indexRow, lateCount.ToString());
                        listValueEarylyCount.Add(indexRow, earlyCount.ToString());
                        listValueLateEarlyCount.Add(indexRow, lateEarlyCount.ToString());
                    }
                    indexRow += 1;
                }
                objColumnLateCount.ListValueByDay = listValueLateCount;
                listColumnByDay.Add(objColumnLateCount);

                objColumnEarlyCount.ListValueByDay = listValueEarylyCount;
                listColumnByDay.Add(objColumnEarlyCount);

                objColumnLateEarlyCount.ListValueByDay = listValueLateEarlyCount;
                listColumnByDay.Add(objColumnLateEarlyCount);
            }
            #endregion

            #region Hien.Le [04/04/2019][104191] Enum tính lương trường hợp đi làm đêm ngày thứ 7 sang chủ nhật
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[]
         {
                    PayrollElementByDay.TYPEOFDATE_TRANSFER_BYDAY.ToString(),
                    PayrollElementByDay.WORKINGNIGHTHOURSBEFORE_BYDAY.ToString(),
                    PayrollElementByDay.WORKINGNIGHTHOURSAFTER_BYDAY.ToString(),
         }))
            {
                ColumnByDay objColumnTypeOfTransfer = new ColumnByDay();
                objColumnTypeOfTransfer.ColumnName = PayrollElementByDay.TYPEOFDATE_TRANSFER_BYDAY.ToString();
                objColumnTypeOfTransfer.ValueType = strDouble;

                ColumnByDay objColumnWorkingNightHoursBefore = new ColumnByDay();
                objColumnWorkingNightHoursBefore.ColumnName = PayrollElementByDay.WORKINGNIGHTHOURSBEFORE_BYDAY.ToString();
                objColumnWorkingNightHoursBefore.ValueType = strDouble;

                ColumnByDay objColumnWorkingNightHoursAfter = new ColumnByDay();
                objColumnWorkingNightHoursAfter.ColumnName = PayrollElementByDay.WORKINGNIGHTHOURSAFTER_BYDAY.ToString();
                objColumnWorkingNightHoursAfter.ValueType = strDouble;

                Dictionary<int, string> listValueTypeOfTransfer = new Dictionary<int, string>();
                Dictionary<int, string> listValueWorkingNightHoursBefore = new Dictionary<int, string>();
                Dictionary<int, string> listValueWorkingNightHoursAfter = new Dictionary<int, string>();

                int indexRow = 0;

                //gán dữ liệu cho từng ngày cho các enum

                // Nếu có thay đổi => Phần tử đi tính
                var listRosterByProfile = TotalDataAll.dicRoster.GetValueOrNew(profileItem.ID).Where(m => m.DateStart <= CutOffDuration.DateEnd.AddDays(1) && m.DateEnd >= CutOffDuration.DateStart && m.Status == RosterStatus.E_APPROVED.ToString()).ToList();

                //rostergroup thang N
                var listRosterGroup = TotalDataAll.ListRosterGroup.Where(s => s.Status == RosterStatus.E_APPROVED.ToString() && s.DateStart <= CutOffDuration.DateEnd.AddDays(1) && s.DateEnd >= CutOffDuration.DateStart).ToList();

                // B2: Hàm này dùng để lấy ca làm việc của nhân viên từ ngày đến ngày truyền vào
                var lstDailyShift = Att_AttendanceLib.GetDailyShifts(
                    CutOffDuration.DateStart, 
                    CutOffDuration.DateEnd.AddDays(1),
                    profileItem.ID, 
                    listRosterByProfile,
                    listRosterGroup,
                    TotalDataAll.listRosterGroupByOrganization,
                    TotalDataAll.listRosterGroupType,
                    TotalDataAll.listOrgStructure,
                    TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID)
                            .Where(s => s.ProfileID == profileItem.ID
                            && s.DateEffective <= CutOffDuration.DateEnd
                            && s.Status == WorkHistoryStatus.E_APPROVED.ToString())
                            .FirstOrDefault());

                string[] listType = new string[]
                {
                     Infrastructure.Utilities.EnumDropDown.DayOffType.E_HOLIDAY.ToString(),
                     Infrastructure.Utilities.EnumDropDown.DayOffType.E_HOLIDAY_HLD.ToString(),
                };

                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double workingNightHoursBefore = 0;
                    double workingNightHoursAfter = 0;
                    int resultTypeOfDay = 0;

                    #region Set Today
                    var typeToDay = string.Empty;
                    var isHolidayToday = TotalDataAll.listDayOff.FirstOrDefault(
                                p => (p.DateOff.Date == objAttendanceTableItem.WorkDate.Date
                                          && listType.Contains(p.Type.ToString()))
                                         );
                    if (isHolidayToday != null)
                    {
                        // Ngày Lễ
                        typeToDay = "HOLIDAY";
                    }
                    else
                    {
                        // Ngày Thường
                        if (lstDailyShift.ContainsKey(objAttendanceTableItem.WorkDate)
                            && lstDailyShift[objAttendanceTableItem.WorkDate] != null
                            && lstDailyShift[objAttendanceTableItem.WorkDate].Count > 0)
                        {
                            typeToDay = "SHIFT_NORMALDAY";
                        }
                        else
                        {
                            typeToDay = "NOSHIFT_NORMALDAY";
                        }
                    }

                    #endregion

                    #region Set Tomorrow

                    var typeTomorrow = string.Empty;
                    var isHolidayTomorrow = TotalDataAll.listDayOff.FirstOrDefault(
                                        p => (p.DateOff.Date == objAttendanceTableItem.WorkDate.AddDays(1).Date
                                                && listType.Contains(p.Type.ToString()))
                                         );
                    if (isHolidayTomorrow != null)
                    {
                        // Ngày Lễ
                        typeTomorrow = "HOLIDAY";
                    }
                    else
                    {
                        // Ngày Thường
                        if (lstDailyShift.ContainsKey(objAttendanceTableItem.WorkDate.AddDays(1))
                            && lstDailyShift[objAttendanceTableItem.WorkDate.AddDays(1)] != null
                            && lstDailyShift[objAttendanceTableItem.WorkDate.AddDays(1)].Count > 0)
                        {
                            typeTomorrow = "SHIFT_NORMALDAY";
                        }
                        else
                        {
                            typeTomorrow = "NOSHIFT_NORMALDAY";
                        }
                    }
                    #endregion

                    // Từ ngày Thường (Có ca) -> Ngày Nghỉ (Ngày không ca) 
                    if (typeToDay == "SHIFT_NORMALDAY" && typeTomorrow == "NOSHIFT_NORMALDAY")
                    {
                        resultTypeOfDay = 1;
                    }
                    //•	Từ ngày Thường (Có ca) -> Ngày lễ
                    if (typeToDay == "SHIFT_NORMALDAY" && typeTomorrow == "HOLIDAY")
                    {
                        resultTypeOfDay = 2;
                    }
                    //•	Ngày Nghỉ (Ngày không ca) -> Từ ngày Thường (Có ca)
                    if (typeToDay == "NOSHIFT_NORMALDAY" && typeTomorrow == "SHIFT_NORMALDAY")
                    {
                        resultTypeOfDay = 3;
                    }
                    //•	Ngày Nghỉ (Ngày không ca)  -> Ngày lễ 
                    if (typeToDay == "NOSHIFT_NORMALDAY" && typeTomorrow == "HOLIDAY")
                    {
                        resultTypeOfDay = 4;
                    }
                    //•	Ngày lễ -> ngày Thường (Có ca)
                    if (typeToDay == "HOLIDAY" && typeTomorrow == "SHIFT_NORMALDAY")
                    {
                        resultTypeOfDay = 5;
                    }
                    //•	Ngày lễ -> Ngày Nghỉ (Ngày không ca) 
                    if (typeToDay == "HOLIDAY" && typeTomorrow == "NOSHIFT_NORMALDAY")
                    {
                        resultTypeOfDay = 6;
                    }
                    //================================================================
                    if (objAttendanceTableItem.WorkingNightHoursBefore != null)
                    {
                        workingNightHoursBefore = objAttendanceTableItem.WorkingNightHoursBefore.Value;
                    }
                    if (objAttendanceTableItem.WorkingNightHoursAfter != null)
                    {
                        workingNightHoursAfter = objAttendanceTableItem.WorkingNightHoursAfter.Value;
                    }

                    if (!listValueTypeOfTransfer.ContainsKey(indexRow))
                    {
                        listValueTypeOfTransfer.Add(indexRow, resultTypeOfDay.ToString());
                        listValueWorkingNightHoursBefore.Add(indexRow, workingNightHoursBefore.ToString());
                        listValueWorkingNightHoursAfter.Add(indexRow, workingNightHoursAfter.ToString());
                    }
                    indexRow += 1;
                }
                objColumnTypeOfTransfer.ListValueByDay = listValueTypeOfTransfer;
                listColumnByDay.Add(objColumnTypeOfTransfer);

                objColumnWorkingNightHoursBefore.ListValueByDay = listValueWorkingNightHoursBefore;
                listColumnByDay.Add(objColumnWorkingNightHoursBefore);

                objColumnWorkingNightHoursAfter.ListValueByDay = listValueWorkingNightHoursAfter;
                listColumnByDay.Add(objColumnWorkingNightHoursAfter);
            }

            #endregion

            #region Hien.Le [08/04/2019] [104519] Giờ bắt đầu 1, giờ kết thúc 1 , Giờ bắt đầu 2, giờ kết thúc 2

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula,
               new string[] {
                    PayrollElementByDay.SHIFT_INTIME1_BYDAY.ToString(),
                    PayrollElementByDay.SHIFT_INTIME2_BYDAY.ToString(),
                    PayrollElementByDay.SHIFT_OUTTIME1_BYDAY.ToString(),
                    PayrollElementByDay.SHIFT_OUTTIME2_BYDAY.ToString(),
               }))
            {
                ColumnByDay objColumnInTime1 = new ColumnByDay();
                objColumnInTime1.ColumnName = PayrollElementByDay.SHIFT_INTIME1_BYDAY.ToString();
                objColumnInTime1.ValueType = strDateTime;
                Dictionary<int, string> listValueInTime1 = new Dictionary<int, string>();

                ColumnByDay objColumnInTime2 = new ColumnByDay();
                objColumnInTime2.ColumnName = PayrollElementByDay.SHIFT_INTIME2_BYDAY.ToString();
                objColumnInTime2.ValueType = strDateTime;
                Dictionary<int, string> listValueInTime2 = new Dictionary<int, string>();

                ColumnByDay objColumnOutTime1 = new ColumnByDay();
                objColumnOutTime1.ColumnName = PayrollElementByDay.SHIFT_OUTTIME1_BYDAY.ToString();
                objColumnOutTime1.ValueType = strDateTime;
                Dictionary<int, string> listValueOutTime1 = new Dictionary<int, string>();

                ColumnByDay objColumnOutTime2 = new ColumnByDay();
                objColumnOutTime2.ColumnName = PayrollElementByDay.SHIFT_OUTTIME2_BYDAY.ToString();
                objColumnOutTime2.ValueType = strDateTime;
                Dictionary<int, string> listValueOutTime2 = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime1 = null;
                    DateTime? inTime2 = null;
                    DateTime? outTime1 = null;
                    DateTime? outTime2 = null;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.ShiftID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null)
                        {

                            inTime1 = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                       objAttendanceTableItem.WorkDate.Month,
                                       objAttendanceTableItem.WorkDate.Day,
                                       objShift.InTime.Hour,
                                       objShift.InTime.Minute,
                                       objShift.InTime.Second
                                       );

                            outTime1 = inTime1.Value.AddHours(objShift.CoOut);
                        }
                    }
                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.Shift2ID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.Shift2ID);
                        if (objShift != null)
                        {

                            inTime2 = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                      objAttendanceTableItem.WorkDate.Month,
                                      objAttendanceTableItem.WorkDate.Day,
                                      objShift.InTime.Hour,
                                      objShift.InTime.Minute,
                                      objShift.InTime.Second
                                      );
                            outTime2 = inTime2.Value.AddHours(objShift.CoOut);
                        }
                    }
                    if (!listValueInTime1.ContainsKey(indexRow))
                    {
                        listValueInTime1.Add(indexRow, inTime1.ToString());
                        listValueOutTime1.Add(indexRow, outTime1.ToString());
                        listValueInTime2.Add(indexRow, inTime2.ToString());
                        listValueOutTime2.Add(indexRow, outTime2.ToString());
                    }
                    indexRow += 1;
                }
                objColumnInTime1.ListValueByDay = listValueInTime1;
                listColumnByDay.Add(objColumnInTime1);

                objColumnInTime2.ListValueByDay = listValueInTime2;
                listColumnByDay.Add(objColumnInTime2);

                objColumnOutTime1.ListValueByDay = listValueOutTime1;
                listColumnByDay.Add(objColumnOutTime1);

                objColumnOutTime2.ListValueByDay = listValueOutTime2;
                listColumnByDay.Add(objColumnOutTime2);
            }
            #endregion

            #region Hien.Le [22/04/2019] [0104658] Lấy enum lương đếm số phụ cấp ca 2 và ca 3 từ enum đã lấy lên trên bảng công
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula,
             new string[] {
                    PayrollElementByDay.ACTUALHOURSALLOWANCE_BYDAY.ToString(),
             }))
            {
                ColumnByDay objColumnActualHoursAllowance = new ColumnByDay();
                objColumnActualHoursAllowance.ColumnName = PayrollElementByDay.ACTUALHOURSALLOWANCE_BYDAY.ToString();
                objColumnActualHoursAllowance.ValueType = strDouble;

                Dictionary<int, string> listValueActualHoursAllowance = new Dictionary<int, string>();

                int indexRow = 0;

                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double actualHoursAllowance = 0;

                    if (objAttendanceTableItem.ActualHoursAllowance != null)
                    {
                        actualHoursAllowance = objAttendanceTableItem.ActualHoursAllowance.Value;
                    }

                    if (!listValueActualHoursAllowance.ContainsKey(indexRow))
                    {
                        listValueActualHoursAllowance.Add(indexRow, actualHoursAllowance.ToString());
                    }
                    indexRow += 1;
                }
                objColumnActualHoursAllowance.ListValueByDay = listValueActualHoursAllowance;
                listColumnByDay.Add(objColumnActualHoursAllowance);
            }
            #endregion

            #region Tung.Tran [13/05/2019][105303]: Loại ca làm việc từng ngày, độ ưu tiên như hàm Getdailyshift bên chấm công
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.ROSTERTYPE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.ROSTERTYPE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                var listRosterByProfileDic = TotalDataAll.dicRoster.GetValueOrNew(profileItem.ID);

                // Ds ca Roster theo profileID và kỳ công
                //[Tin.Nguyen - 202020903][117967]Lấy dữ roster theo cấu hình trạng thái dc tính
                var commonServices = new Att_CommonServices();
                var listStatus = commonServices.GetConfigStatusRosterCompute();
                var listRosterByProfile = listRosterByProfileDic.Where(m => m.ProfileID == profileItem.ID
                    && m.DateStart <= CutOffDuration.DateEnd
                    && m.DateEnd >= CutOffDuration.DateStart
                    && listStatus.Contains(m.Status)).ToList();

                //DS RosterGroup của kỳ công
                var listRosterGroup = TotalDataAll.ListRosterGroup.Where(s => s.Status == RosterStatus.E_APPROVED.ToString()
                    && s.DateStart <= CutOffDuration.DateEnd
                    && s.DateEnd >= CutOffDuration.DateStart).ToList();

                //Lịch làm việc của tháng N
                var lstDailyType = Att_AttendanceLib.GetDailyRosterType(CutOffDuration.DateStart, CutOffDuration.DateEnd, profileItem.ID, listRosterByProfile, listRosterGroup, new List<Att_RosterGroupByOrganizationEntity>(), new List<Cat_RosterGroupTypeEntity>(), new List<Cat_OrgStructureEntity>(), null);

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var rosterType = string.Empty;

                    if (lstDailyType != null && lstDailyType.ContainsKey(objAttendanceTableItem.WorkDate.Date))
                    {
                        rosterType = lstDailyType[objAttendanceTableItem.WorkDate.Date];
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, rosterType.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [14/05/2019] [105095]: Mã ca của dòng top 1 OT từng ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.FIRST_ATT_OVERTIME_SHIFTCODE_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.FIRST_ATT_OVERTIME_SHIFTCODE_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.FirstOrDefault(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString());
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var shiftCode = string.Empty;

                    var objOverTime = lisOverTimeByProfileDic.FirstOrDefault(
                                        s => s.Status == strOTStatus
                                        && (s.WorkDateRoot != null && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date));

                    if (objOverTime != null && !Common.IsNullOrGuidEmpty(objOverTime.ShiftID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objOverTime.ShiftID);
                        if (objShift != null)
                        {
                            shiftCode = objShift.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, shiftCode);
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Hien.Le [02/07/2019] [106673] Lấy danh sách enum hỗ trợ đặt công thức Tính lương
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula,
                new string[] {
                PayrollElementByDay.ATT_WORKHISTORY_PAYROLLGROUPCODE_BYDAY.ToString(),
                PayrollElementByDay.ATT_WORKHISTORY_SATURDAYALLOWANCE_BYDAY.ToString(),
                PayrollElementByDay.ATT_WORKHISTORY_INSURANCETYPEALLOWANCE_BYDAY.ToString()}))
            {
                ColumnByDay objColumnPayrollGroupCodeByDay = new ColumnByDay();
                objColumnPayrollGroupCodeByDay.ColumnName = PayrollElementByDay.ATT_WORKHISTORY_PAYROLLGROUPCODE_BYDAY.ToString();
                objColumnPayrollGroupCodeByDay.ValueType = strString;

                ColumnByDay objColumnSaturdayAllowanceByDay = new ColumnByDay();
                objColumnSaturdayAllowanceByDay.ColumnName = PayrollElementByDay.ATT_WORKHISTORY_SATURDAYALLOWANCE_BYDAY.ToString();
                objColumnSaturdayAllowanceByDay.ValueType = strDouble;

                ColumnByDay objColumnInsuranceTypeAllowanceByDay = new ColumnByDay();
                objColumnInsuranceTypeAllowanceByDay.ColumnName = PayrollElementByDay.ATT_WORKHISTORY_INSURANCETYPEALLOWANCE_BYDAY.ToString();
                objColumnInsuranceTypeAllowanceByDay.ValueType = strDouble;

                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValuePayrollGroupCodeByDay = new Dictionary<int, string>();
                Dictionary<int, string> listValueSaturdayAllowanceByDay = new Dictionary<int, string>();
                Dictionary<int, string> listValueInsuranceTypeAllowanceByDay = new Dictionary<int, string>();
                int indexRow = 0;

                var listWorkHistory = TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID);

                var listCatLeaveDayType = TotalDataAll.listLeavedayType.Where(p => !string.IsNullOrEmpty(p.InsuranceType)).ToList();

                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string payrollGroupCode = string.Empty;
                    int saturdayAllowance = 0;
                    int insuranceTypeAllowance = 0;

                    var objWorkHistory = listWorkHistory.Where(s => s.DateEffective <= objAttendanceTableItem.WorkDate).OrderByDescending(s => s.DateEffective).FirstOrDefault();
                    //Mã nhóm lương
                    if (!string.IsNullOrEmpty(objWorkHistory.PayrollGroupID.ToString()))
                    {
                        var payrollGroup = TotalDataAll.listPayrollGroup.FirstOrDefault(p => p.ID == objWorkHistory.PayrollGroupID);
                        if (payrollGroup != null)
                        {
                            payrollGroupCode = payrollGroup.Code;
                        }
                    }
                    //Có hưởng trợ cấp thứ 7
                    var objCatDayOff = TotalDataAll.listDayOff.FirstOrDefault(p => p.DateOff.Date == objAttendanceTableItem.WorkDate.Date && p.IsAllowanceBonus != null);
                    if (objCatDayOff != null)
                    {
                        saturdayAllowance = 1;
                    }
                    else
                    {
                        saturdayAllowance = 0;
                    }
                    //Có nghỉ thai sản/ ốm BHXH:
                    var objCatInsuranceType = listCatLeaveDayType.FirstOrDefault(p => p.ID == objAttendanceTableItem.LeaveTypeID ||
                                                                                                                                    p.ID == objAttendanceTableItem.ExtraLeaveTypeID ||
                                                                                                                                    p.ID == objAttendanceTableItem.ExtraLeaveType3ID ||
                                                                                                                                    p.ID == objAttendanceTableItem.ExtraLeaveType4ID ||
                                                                                                                                    p.ID == objAttendanceTableItem.ExtraLeaveType5ID ||
                                                                                                                                    p.ID == objAttendanceTableItem.ExtraLeaveType6ID);
                    if (objCatInsuranceType != null)
                    {
                        insuranceTypeAllowance = 1;
                    }
                    else
                    {
                        insuranceTypeAllowance = 0;
                    }

                    if (!listValuePayrollGroupCodeByDay.ContainsKey(indexRow))
                    {
                        listValuePayrollGroupCodeByDay.Add(indexRow, payrollGroupCode);
                        listValueSaturdayAllowanceByDay.Add(indexRow, saturdayAllowance.ToString());
                        listValueInsuranceTypeAllowanceByDay.Add(indexRow, insuranceTypeAllowance.ToString());
                    }
                    indexRow += 1;
                }
                objColumnPayrollGroupCodeByDay.ListValueByDay = listValuePayrollGroupCodeByDay;
                objColumnSaturdayAllowanceByDay.ListValueByDay = listValueSaturdayAllowanceByDay;
                objColumnInsuranceTypeAllowanceByDay.ListValueByDay = listValueInsuranceTypeAllowanceByDay;

                listColumnByDay.Add(objColumnPayrollGroupCodeByDay);
                listColumnByDay.Add(objColumnSaturdayAllowanceByDay);
                listColumnByDay.Add(objColumnInsuranceTypeAllowanceByDay);
            }
            #endregion

            #region Tung.Tran [26/09/2019][106673] Lấy danh sách enum hỗ trợ đặt công thức Tính lương
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[]
            {
                  PayrollElementByDay.COUNT_TAMSCANLOG_BYDAY.ToString(),
            }))
            {
                string status = string.Empty;
                dataComputeSer.GetDicTAMScanLog(TotalData, CutOffDuration, ref status);
                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.COUNT_TAMSCANLOG_BYDAY.ToString() + ") ";

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = PayrollElementByDay.COUNT_TAMSCANLOG_BYDAY.ToString(); ;
                    objColumnByDay.ValueType = strDouble;
                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    for (int i = 0; i < totalRowInDataSoure; i++)
                    {
                        if (!listValueByDay.ContainsKey(i))
                        {
                            listValueByDay.Add(i, "0");
                        }
                    }

                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                }
                else
                {
                    var listTamScanLogByProfile = TotalData.dicTamScanLog.GetValueOrNew(profileItem.ID);

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = PayrollElementByDay.COUNT_TAMSCANLOG_BYDAY.ToString(); ;
                    objColumnByDay.ValueType = strDouble;
                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        int countTamScanLog = 0;

                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null)
                        {
                            // Giờ bắt đầu ca
                            var inTime = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                objAttendanceTableItem.WorkDate.Month,
                                objAttendanceTableItem.WorkDate.Day,
                                objShift.InTime.Hour,
                                objShift.InTime.Minute,
                                objShift.InTime.Second
                                );

                            // Giờ kết thúc ca
                            var outTime = new DateTime(objAttendanceTableItem.WorkDate.Year,
                               objAttendanceTableItem.WorkDate.Month,
                               objAttendanceTableItem.WorkDate.Day,
                               objShift.InTime.Hour,
                               objShift.InTime.Minute,
                               objShift.InTime.Second
                               ).AddHours(objShift.CoOut);
                            countTamScanLog = listTamScanLogByProfile.Where(x => x.TimeLog >= inTime && x.TimeLog <= outTime).Count();
                        }

                        if (!listValueByDay.ContainsKey(indexRow))
                        {
                            listValueByDay.Add(indexRow, countTamScanLog.ToString());
                        }
                        indexRow += 1;
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                }
            }
            #endregion

            #region Hien.Le [11/11/2019] [110030] Thêm enum số giờ tính lương của 2 ca (Att_AttendanceTableItem.WorkPaidHoursShift1, Att_AttendanceTableItem.WorkPaidHoursShift2)
            //if (!dicTimeComputeElement.ContainsKey(threadIdTimeComputeElement + "_" + "WORKPAIDHOURSSHIFT1_BYDAY"))
            //dicTimeComputeElement.Add(threadIdTimeComputeElement + "_" + "WORKPAIDHOURSSHIFT1_BYDAY", 0);
            //watchTimeComputeElement.Restart();
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.WORKPAIDHOURSSHIFT1_BYDAY.ToString()))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.WORKPAIDHOURSSHIFT1_BYDAY.ToString();
                objColumnByDay.ValueType = strDouble;

                Dictionary<int, string> listValueWorkPaidHoursShift1ByDay = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValueWorkPaidHoursShift1ByDay.ContainsKey(indexRow))
                    {
                        listValueWorkPaidHoursShift1ByDay.Add(indexRow, objAttendanceTableItem.WorkPaidHoursShift1.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueWorkPaidHoursShift1ByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            //dicTimeComputeElement[threadIdTimeComputeElement + "_" + "WORKPAIDHOURSSHIFT1_BYDAY"] += watchTimeComputeElement.Elapsed.TotalSeconds;

            //if (!dicTimeComputeElement.ContainsKey(threadIdTimeComputeElement + "_" + "WORKPAIDHOURSSHIFT2_BYDAY"))
            //dicTimeComputeElement.Add(threadIdTimeComputeElement + "_" + "WORKPAIDHOURSSHIFT2_BYDAY", 0);
            //watchTimeComputeElement.Restart();
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.WORKPAIDHOURSSHIFT2_BYDAY.ToString()))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.WORKPAIDHOURSSHIFT2_BYDAY.ToString();
                objColumnByDay.ValueType = strDouble;

                Dictionary<int, string> listValueWorkPaidHoursShift2ByDay = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValueWorkPaidHoursShift2ByDay.ContainsKey(indexRow))
                    {
                        listValueWorkPaidHoursShift2ByDay.Add(indexRow, objAttendanceTableItem.WorkPaidHoursShift2.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueWorkPaidHoursShift2ByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            //dicTimeComputeElement[threadIdTimeComputeElement + "_" + "WORKPAIDHOURSSHIFT1_BYDAY"] += watchTimeComputeElement.Elapsed.TotalSeconds;

            #endregion

            #region Khoa.nguyen [06/04/2020] 0113038: Thêm phần tử lương ngày lấy số lần đổi ca, đổi ngày làm việc trong chu kỳ lương (mh Tính lương)	
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula,
            new string[] {
                    PayrollElementByDay.CHANGESHIFTTYPE_BYDAY.ToString(),
            }))
            {
                ColumnByDay objColumnChangeShiftType = new ColumnByDay();
                objColumnChangeShiftType.ColumnName = PayrollElementByDay.CHANGESHIFTTYPE_BYDAY.ToString();
                objColumnChangeShiftType.ValueType = strString;

                Dictionary<int, string> listValueChangeShiftType = new Dictionary<int, string>();

                int indexRow = 0;

                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string changeShiftType = string.Empty;

                    if (objAttendanceTableItem.ChangeShiftType != null)
                    {
                        changeShiftType = objAttendanceTableItem.ChangeShiftType;
                    }

                    if (!listValueChangeShiftType.ContainsKey(indexRow))
                    {
                        listValueChangeShiftType.Add(indexRow, changeShiftType.ToString());
                    }
                    indexRow += 1;
                }
                objColumnChangeShiftType.ListValueByDay = listValueChangeShiftType;
                listColumnByDay.Add(objColumnChangeShiftType);
            }

            #endregion

            #region Hien.Le [0117803]: Thêm enum phần tử lương lấy ra lương SP theo chi tiết SP
            //Phần tử Lương sản phẩm theo ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[]
            {
                PayrollElementByDay.SAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY.ToString(),
                PayrollElementByDay.SAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY.ToString()
            }))
            {
                #region Khai báo các cột
                ColumnByDay objColumnSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY = new ColumnByDay();
                objColumnSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY.ColumnName = PayrollElementByDay.SAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY.ToString();
                objColumnSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY.ValueType = strDouble;

                ColumnByDay objColumnSAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY = new ColumnByDay();
                objColumnSAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY.ColumnName = PayrollElementByDay.SAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY.ToString();
                objColumnSAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY.ValueType = strDouble;

                Dictionary<int, string> listValueSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY = new Dictionary<int, string>();
                Dictionary<int, string> listValueSAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY = new Dictionary<int, string>();
                #endregion

                string status = string.Empty;
                dataComputeSer.GetdicSalProductSalaryOverOffset(TotalData, CutOffDuration, ref status);
                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.SAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY.ToString() + ") ";
                    int indexRow = 0;
                    for (int i = 0; i < totalRowInDataSoure; i++)
                    {
                        if (!listValueSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY.ContainsKey(indexRow))
                        {
                            listValueSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY.Add(indexRow, 0.ToString());
                        }
                        indexRow += 1;
                    }
                }
                else
                {
                    int indexRow = 0;
                    var listSalProductSalaryOverOffsetProfile = TotalData.dicSalProductSalaryOverOffset.GetValueOrNew(profileItem.ID);
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        #region SAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY
                        var totalAmount = 0.0;
                        var listSalProductSalaryOverOffsetTotalAmount = listSalProductSalaryOverOffsetProfile.Where(x =>
                        x.ProfileID == profileItem.ID
                        && x.WorkDate == objAttendanceTableItem.WorkDate).ToList();
                        if (listSalProductSalaryOverOffsetTotalAmount.Count > 0)
                        {
                            totalAmount = listSalProductSalaryOverOffsetTotalAmount.Where(p => p.TotalAmount != null).Sum(p => p.TotalAmount.Value);
                        }
                        if (!listValueSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY.ContainsKey(indexRow))
                        {
                            listValueSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY.Add(indexRow, totalAmount.ToString());
                        }
                        #endregion

                        #region SAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY
                        var isHaveQuantity = 0;
                        var listSalProductSalaryOverOffsetHaveQuantity = listSalProductSalaryOverOffsetProfile.Where(x =>
                        x.ProfileID == profileItem.ID
                        && x.WorkDate == objAttendanceTableItem.WorkDate
                        && x.Quantity != null && x.Quantity != 0).ToList();

                        if (listSalProductSalaryOverOffsetHaveQuantity.Count > 0)
                        {
                            isHaveQuantity = 1;
                        }
                        if (!listValueSAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY.ContainsKey(indexRow))
                        {
                            listValueSAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY.Add(indexRow, isHaveQuantity.ToString());
                        }
                        #endregion

                        indexRow += 1;
                    }
                }
                objColumnSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY.ListValueByDay = listValueSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY;
                listColumnByDay.Add(objColumnSAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_BYDAY);
                objColumnSAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY.ListValueByDay = listValueSAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY;
                listColumnByDay.Add(objColumnSAL_PRODUCTSALARYOVEROFFSET_HAVE_QUANTITY_BYDAY);
            }
            #endregion

            #region Hien.Le [10/08/2020] 0116699: Thêm phần tử lương ngày Lấy tổng số lần bổ sung quẹt thẻ trong ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[]
            {
                PayrollElementByDay.ATTWORKDAYSRCTYPEINTIME1_BYDAY.ToString(),
                PayrollElementByDay.ATTWORKDAYSRCTYPEOUTTIME1_BYDAY.ToString(),
                PayrollElementByDay.ATTWORKDAYSRCTYPEINTIME2_BYDAY.ToString(),
                PayrollElementByDay.ATTWORKDAYSRCTYPEOUTTIME2_BYDAY.ToString()
            }))
            {
                //Lấy data WorkDay nếu chưa được lấy trước đó
                string status = string.Empty;
                string nameTableGetData = "listAttWorkday";
                if (!TotalData.dicTableGetDataByProfileIDs.ContainsKey(nameTableGetData))
                {
                    TotalData.listAttWorkday = dataComputeSer.GetListAttWorkDay(TotalData.strOrderByProfile, CutOffDuration, ref status);
                    TotalData.dicTableGetDataByProfileIDs.Add(nameTableGetData, "");
                }
                //Trường hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông lưu store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.ATTWORKDAYSRCTYPEINTIME1_BYDAY.ToString() + ") ";
                }
                else
                {
                    #region Khai báo cột
                    string columnATTWORKDAYSRCTYPEINTIME1_BYDAY = PayrollElementByDay.ATTWORKDAYSRCTYPEINTIME1_BYDAY.ToString();
                    ColumnByDay objColumnATTWORKDAYSRCTYPEINTIME1_BYDAY = new ColumnByDay();
                    objColumnATTWORKDAYSRCTYPEINTIME1_BYDAY.ColumnName = columnATTWORKDAYSRCTYPEINTIME1_BYDAY;
                    objColumnATTWORKDAYSRCTYPEINTIME1_BYDAY.ValueType = strString;

                    string columnATTWORKDAYSRCTYPEOUTTIME1_BYDAY = PayrollElementByDay.ATTWORKDAYSRCTYPEOUTTIME1_BYDAY.ToString();
                    ColumnByDay objColumnATTWORKDAYSRCTYPEOUTTIME1_BYDAY = new ColumnByDay();
                    objColumnATTWORKDAYSRCTYPEOUTTIME1_BYDAY.ColumnName = columnATTWORKDAYSRCTYPEOUTTIME1_BYDAY;
                    objColumnATTWORKDAYSRCTYPEOUTTIME1_BYDAY.ValueType = strString;

                    string columnATTWORKDAYSRCTYPEINTIME2_BYDAY = PayrollElementByDay.ATTWORKDAYSRCTYPEINTIME2_BYDAY.ToString();
                    ColumnByDay objColumnATTWORKDAYSRCTYPEINTIME2_BYDAY = new ColumnByDay();
                    objColumnATTWORKDAYSRCTYPEINTIME2_BYDAY.ColumnName = columnATTWORKDAYSRCTYPEINTIME2_BYDAY;
                    objColumnATTWORKDAYSRCTYPEINTIME2_BYDAY.ValueType = strString;

                    string columnATTWORKDAYSRCTYPEOUTTIME2_BYDAY = PayrollElementByDay.ATTWORKDAYSRCTYPEOUTTIME2_BYDAY.ToString();
                    ColumnByDay objColumnATTWORKDAYSRCTYPEOUTTIME2_BYDAY = new ColumnByDay();
                    objColumnATTWORKDAYSRCTYPEOUTTIME2_BYDAY.ColumnName = columnATTWORKDAYSRCTYPEOUTTIME2_BYDAY;
                    objColumnATTWORKDAYSRCTYPEOUTTIME2_BYDAY.ValueType = strString;

                    Dictionary<int, string> listValueATTWORKDAYSRCTYPEINTIME1_BYDAY = new Dictionary<int, string>();
                    Dictionary<int, string> listValueATTWORKDAYSRCTYPEOUTTIME1_BYDAY = new Dictionary<int, string>();
                    Dictionary<int, string> listValueATTWORKDAYSRCTYPEINTIME2_BYDAY = new Dictionary<int, string>();
                    Dictionary<int, string> listValueATTWORKDAYSRCTYPEOUTTIME2_BYDAY = new Dictionary<int, string>();
                    #endregion

                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        #region SrcTypeInTime1
                        string srcTypeInTime1 = string.Empty;
                        var objAttWorkDay1 = TotalData.listAttWorkday.FirstOrDefault(
                            s => s.ProfileID == profileItem.ID
                              && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date);
                        if (objAttWorkDay1 != null && !string.IsNullOrEmpty(objAttWorkDay1.SrcTypeInTime1))
                        {
                            srcTypeInTime1 = objAttWorkDay1.SrcTypeInTime1;
                        }
                        if (!listValueATTWORKDAYSRCTYPEINTIME1_BYDAY.ContainsKey(indexRow))
                        {
                            listValueATTWORKDAYSRCTYPEINTIME1_BYDAY.Add(indexRow, srcTypeInTime1.ToString());
                        }
                        #endregion

                        #region SrcTypeOutTime1
                        string srcTypeOutTime1 = string.Empty;
                        var objAttWorkDay2 = TotalData.listAttWorkday.FirstOrDefault(
                            s => s.ProfileID == profileItem.ID
                              && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date);
                        if (objAttWorkDay2 != null && !string.IsNullOrEmpty(objAttWorkDay2.SrcTypeOutTime1))
                        {
                            srcTypeOutTime1 = objAttWorkDay2.SrcTypeOutTime1;
                        }
                        if (!listValueATTWORKDAYSRCTYPEOUTTIME1_BYDAY.ContainsKey(indexRow))
                        {
                            listValueATTWORKDAYSRCTYPEOUTTIME1_BYDAY.Add(indexRow, srcTypeOutTime1.ToString());
                        }
                        #endregion

                        #region SrcTypeInTime2
                        string srcTypeInTime2 = string.Empty;
                        var objAttWorkDay3 = TotalData.listAttWorkday.FirstOrDefault(
                            s => s.ProfileID == profileItem.ID
                              && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date);
                        if (objAttWorkDay3 != null && !string.IsNullOrEmpty(objAttWorkDay3.SrcTypeInTime2))
                        {
                            srcTypeInTime2 = objAttWorkDay3.SrcTypeInTime2;
                        }
                        if (!listValueATTWORKDAYSRCTYPEINTIME2_BYDAY.ContainsKey(indexRow))
                        {
                            listValueATTWORKDAYSRCTYPEINTIME2_BYDAY.Add(indexRow, srcTypeInTime2.ToString());
                        }
                        #endregion

                        #region SrcTypeOutTime2
                        string srcTypeOutTime2 = string.Empty;
                        var objAttWorkDay4 = TotalData.listAttWorkday.FirstOrDefault(
                            s => s.ProfileID == profileItem.ID
                              && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date);
                        if (objAttWorkDay4 != null && !string.IsNullOrEmpty(objAttWorkDay4.SrcTypeOutTime2))
                        {
                            srcTypeOutTime2 = objAttWorkDay4.SrcTypeOutTime2;
                        }
                        if (!listValueATTWORKDAYSRCTYPEOUTTIME2_BYDAY.ContainsKey(indexRow))
                        {
                            listValueATTWORKDAYSRCTYPEOUTTIME2_BYDAY.Add(indexRow, srcTypeOutTime2.ToString());
                        }
                        #endregion

                        indexRow += 1;
                    }
                    objColumnATTWORKDAYSRCTYPEINTIME1_BYDAY.ListValueByDay = listValueATTWORKDAYSRCTYPEINTIME1_BYDAY;
                    listColumnByDay.Add(objColumnATTWORKDAYSRCTYPEINTIME1_BYDAY);

                    objColumnATTWORKDAYSRCTYPEOUTTIME1_BYDAY.ListValueByDay = listValueATTWORKDAYSRCTYPEOUTTIME1_BYDAY;
                    listColumnByDay.Add(objColumnATTWORKDAYSRCTYPEOUTTIME1_BYDAY);

                    objColumnATTWORKDAYSRCTYPEINTIME2_BYDAY.ListValueByDay = listValueATTWORKDAYSRCTYPEINTIME2_BYDAY;
                    listColumnByDay.Add(objColumnATTWORKDAYSRCTYPEINTIME2_BYDAY);

                    objColumnATTWORKDAYSRCTYPEOUTTIME2_BYDAY.ListValueByDay = listValueATTWORKDAYSRCTYPEOUTTIME2_BYDAY;
                    listColumnByDay.Add(objColumnATTWORKDAYSRCTYPEOUTTIME2_BYDAY);
                }
            }
            #endregion

            #region Nghia.Dang [30/11/2020][0121603] thêm phần tử lương ngày đếm số ngày làm HDT
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.HDTJOB_BYDAY.ToString() }))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.HDTJOB_BYDAY.ToString();
                objColumnByDay.ValueType = strString;

                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                int indexRow = 0;
                string status = string.Empty;
                dataComputeSer.GetListHre_HDTJob_All(TotalData, CutOffDuration, ref status);
                var listHDTJob = TotalData.dicHre_HDTJob_All.GetValueOrNew(profileItem.ID);
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string valueHDTJob = "0";
                    var objHDTJob = listHDTJob.Where(s => s.DateFrom <= objAttendanceTableItem.WorkDate && s.DateTo >= objAttendanceTableItem.WorkDate).FirstOrDefault();
                    if (objHDTJob != null)
                    {
                        valueHDTJob = "1";
                    }
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, valueHDTJob);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Hien.Le [25/11/2021] [123090] [Spindex] Thêm phần tử lương: Đếm lên số lần bổ sung in out theo loại lý do thiếu in out trong kỳ công
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[]
            {
                PayrollElementByDay.ATT_WORKDAY_MISSINOUTREASON1_BYDAY.ToString(),
                PayrollElementByDay.ATT_WORKDAY_MISSINOUTREASON2_BYDAY.ToString(),
                PayrollElementByDay.ATT_WORKDAY_MISSINOUTREASON3_BYDAY.ToString(),
                PayrollElementByDay.ATT_WORKDAY_MISSINOUTREASON4_BYDAY.ToString(),
            }))
            {
                //Lấy data WorkDay nếu chưa được lấy trước đó
                string status = string.Empty;
                string nameTableGetData = "listAttWorkday";
                if (!TotalData.dicTableGetDataByProfileIDs.ContainsKey(nameTableGetData))
                {
                    TotalData.listAttWorkday = dataComputeSer.GetListAttWorkDay(TotalData.strOrderByProfile, CutOffDuration, ref status);
                    TotalData.dicTableGetDataByProfileIDs.Add(nameTableGetData, "");
                }
                //Trường hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông lưu store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.ATT_WORKDAY_MISSINOUTREASON1_BYDAY.ToString() + ") ";
                }
                else
                {
                    #region Khai báo
                    #region ATT_WORKDAY_MISSINOUTREASON1_BYDAY
                    ColumnByDay objColumnByDayMISSINOUTREASON1 = new ColumnByDay();
                    objColumnByDayMISSINOUTREASON1.ColumnName = PayrollElementByDay.ATT_WORKDAY_MISSINOUTREASON1_BYDAY.ToString();
                    objColumnByDayMISSINOUTREASON1.ValueType = strString;
                    #endregion
                    #region ATT_WORKDAY_MISSINOUTREASON2_BYDAY
                    ColumnByDay objColumnByDayMISSINOUTREASON2 = new ColumnByDay();
                    objColumnByDayMISSINOUTREASON2.ColumnName = PayrollElementByDay.ATT_WORKDAY_MISSINOUTREASON2_BYDAY.ToString();
                    objColumnByDayMISSINOUTREASON2.ValueType = strString;
                    #endregion
                    #region ATT_WORKDAY_MISSINOUTREASON3_BYDAY
                    ColumnByDay objColumnByDayMISSINOUTREASON3 = new ColumnByDay();
                    objColumnByDayMISSINOUTREASON3.ColumnName = PayrollElementByDay.ATT_WORKDAY_MISSINOUTREASON3_BYDAY.ToString();
                    objColumnByDayMISSINOUTREASON3.ValueType = strString;
                    #endregion
                    #region ATT_WORKDAY_MISSINOUTREASON4_BYDAY
                    ColumnByDay objColumnByDayMISSINOUTREASON4 = new ColumnByDay();
                    objColumnByDayMISSINOUTREASON4.ColumnName = PayrollElementByDay.ATT_WORKDAY_MISSINOUTREASON4_BYDAY.ToString();
                    objColumnByDayMISSINOUTREASON4.ValueType = strString;
                    #endregion
                    #endregion
                    #region DS dữ liệu cho từng ngày
                    Dictionary<int, string> listMissInOutReason1ValueByDay = new Dictionary<int, string>();
                    Dictionary<int, string> listMissInOutReason2ValueByDay = new Dictionary<int, string>();
                    Dictionary<int, string> listMissInOutReason3ValueByDay = new Dictionary<int, string>();
                    Dictionary<int, string> listMissInOutReason4ValueByDay = new Dictionary<int, string>();
                    #endregion
                    int indexRow = 0;
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        #region MissInOutReason1
                        string missInOutReason1Code = string.Empty;
                        var objAttWorkDay1 = TotalData.listAttWorkday.FirstOrDefault(
                                s => s.ProfileID == profileItem.ID
                              && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date);
                        if (objAttWorkDay1 != null && !Common.IsNullOrGuidEmpty(objAttWorkDay1.MissInOutReasonID1))
                        {
                            missInOutReason1Code = TotalDataAll.listTAMScanReasonMiss.FirstOrDefault(p => p.ID == objAttWorkDay1.MissInOutReasonID1)?.Code ?? string.Empty;
                        }
                        if (!listMissInOutReason1ValueByDay.ContainsKey(indexRow))
                        {
                            listMissInOutReason1ValueByDay.Add(indexRow, missInOutReason1Code);
                        }
                        #endregion
                        #region MissInOutReason2
                        string missInOutReason2Code = string.Empty;
                        var objAttWorkDay2 = TotalData.listAttWorkday.FirstOrDefault(
                                s => s.ProfileID == profileItem.ID
                              && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date);
                        if (objAttWorkDay2 != null && !Common.IsNullOrGuidEmpty(objAttWorkDay2.MissInOutReasonID2))
                        {
                            missInOutReason2Code = TotalDataAll.listTAMScanReasonMiss.FirstOrDefault(p => p.ID == objAttWorkDay2.MissInOutReasonID2)?.Code ?? string.Empty;
                        }
                        if (!listMissInOutReason2ValueByDay.ContainsKey(indexRow))
                        {
                            listMissInOutReason2ValueByDay.Add(indexRow, missInOutReason2Code);
                        }
                        #endregion
                        #region MissInOutReason3
                        string missInOutReason3Code = string.Empty;
                        var objAttWorkDay3 = TotalData.listAttWorkday.FirstOrDefault(
                                s => s.ProfileID == profileItem.ID
                              && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date);
                        if (objAttWorkDay3 != null && !Common.IsNullOrGuidEmpty(objAttWorkDay3.MissInOutReasonID3))
                        {
                            missInOutReason3Code = TotalDataAll.listTAMScanReasonMiss.FirstOrDefault(p => p.ID == objAttWorkDay3.MissInOutReasonID3)?.Code ?? string.Empty;
                        }
                        if (!listMissInOutReason3ValueByDay.ContainsKey(indexRow))
                        {
                            listMissInOutReason3ValueByDay.Add(indexRow, missInOutReason3Code);
                        }
                        #endregion
                        #region MissInOutReason4
                        string missInOutReason4Code = string.Empty;
                        var objAttWorkDay4 = TotalData.listAttWorkday.FirstOrDefault(
                                s => s.ProfileID == profileItem.ID
                              && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date);
                        if (objAttWorkDay4 != null && !Common.IsNullOrGuidEmpty(objAttWorkDay4.MissInOutReasonID4))
                        {
                            missInOutReason4Code = TotalDataAll.listTAMScanReasonMiss.FirstOrDefault(p => p.ID == objAttWorkDay4.MissInOutReasonID4)?.Code ?? string.Empty;
                        }
                        if (!listMissInOutReason4ValueByDay.ContainsKey(indexRow))
                        {
                            listMissInOutReason4ValueByDay.Add(indexRow, missInOutReason4Code);
                        }
                        #endregion
                        indexRow += 1;
                    }
                    objColumnByDayMISSINOUTREASON1.ListValueByDay = listMissInOutReason1ValueByDay;
                    listColumnByDay.Add(objColumnByDayMISSINOUTREASON1);

                    objColumnByDayMISSINOUTREASON2.ListValueByDay = listMissInOutReason2ValueByDay;
                    listColumnByDay.Add(objColumnByDayMISSINOUTREASON2);

                    objColumnByDayMISSINOUTREASON3.ListValueByDay = listMissInOutReason3ValueByDay;
                    listColumnByDay.Add(objColumnByDayMISSINOUTREASON3);

                    objColumnByDayMISSINOUTREASON4.ListValueByDay = listMissInOutReason4ValueByDay;
                    listColumnByDay.Add(objColumnByDayMISSINOUTREASON4);
                }
            }
            #endregion

            #region Khoa.nguyen [11/03/2021] 0124481: [HOT FIX IVC_V8.8.36.01.11] Bổ sung thêm Enums Số ngày công tác trong nước và số ngày công tác ngoài nước	
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.ATT_LEAVEDAY_ISHAVECPOST_BYDAY.ToString(),
            }))
            {
                var strLeaveDayStatus = AttendanceDataStatus.E_APPROVED.ToString();
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYBUSSINESSSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null && objAllSetting.Value1 != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columLEAVETYPEDURATIONTYPE_BYDAY = PayrollElementByDay.ATT_LEAVEDAY_ISHAVECPOST_BYDAY.ToString();

                ColumnByDay objColumnLEAVETYPEDURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnLEAVETYPEDURATIONTYPE_BYDAY.ColumnName = columLEAVETYPEDURATIONTYPE_BYDAY;
                objColumnLEAVETYPEDURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPEDURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum

                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    int isHaveCost = 0;
                    var leaveDay = TotalDataAll.dicLeaveDayNotStatus.GetValueOrNew(profileItem.ID).Where( s =>
                       s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.IsBusinessTravel == true
                        ).FirstOrDefault();

                    if (leaveDay != null)
                    {
                        isHaveCost = leaveDay.IsHaveCosts == true ? 1 : 0;
                    }
                    if (!listValueLEAVETYPEDURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPEDURATIONTYPE_BYDAY.Add(indexRow, isHaveCost.ToString());
                    }
                    indexRow += 1;
                }
                objColumnLEAVETYPEDURATIONTYPE_BYDAY.ListValueByDay = listValueLEAVETYPEDURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnLEAVETYPEDURATIONTYPE_BYDAY);
            }
            #endregion

            #region Nghia.Dang[127090] Thêm phân từ ngày: tính công đi làm ngày lễ  
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.ATT_WORK_PAID_HOUR_BYDAY.ToString(),
                PayrollElementByDay.ATT_NIGHT_SHIFT_HOUR_BYDAY.ToString() }))
            {
                string columWorkPaidHourHLD = PayrollElementByDay.ATT_WORK_PAID_HOUR_BYDAY.ToString();
                string columNightShiftHourHLD = PayrollElementByDay.ATT_NIGHT_SHIFT_HOUR_BYDAY.ToString();

                ColumnByDay objColumnWorkPaidHourHLDByDay = new ColumnByDay();
                objColumnWorkPaidHourHLDByDay.ColumnName = columWorkPaidHourHLD;
                objColumnWorkPaidHourHLDByDay.ValueType = strDouble;
                Dictionary<int, string> listValueWorkPaidHourHLDByDay = new Dictionary<int, string>();

                ColumnByDay objColumnNightShiftHourHLDByDay = new ColumnByDay();
                objColumnNightShiftHourHLDByDay.ColumnName = columNightShiftHourHLD;
                objColumnNightShiftHourHLDByDay.ValueType = strDouble;
                Dictionary<int, string> listValueNightShiftHourHLDByDay = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double WorkPaidHourHLD = 0;
                    double NightShiftHourHLD = 0;
                    if (objAttendanceTableItem.WorkPaidHourHLD != null)
                    {
                        WorkPaidHourHLD = objAttendanceTableItem.WorkPaidHourHLD.Value;
                    }
                    if (objAttendanceTableItem.NightShiftHourHLD != null)
                    {
                        NightShiftHourHLD = objAttendanceTableItem.NightShiftHourHLD.Value;
                    }
                    if (!listValueWorkPaidHourHLDByDay.ContainsKey(indexRow))
                    {
                        listValueWorkPaidHourHLDByDay.Add(indexRow, WorkPaidHourHLD.ToString());
                    }
                    if (!listValueNightShiftHourHLDByDay.ContainsKey(indexRow))
                    {
                        listValueNightShiftHourHLDByDay.Add(indexRow, NightShiftHourHLD.ToString());
                    }
                    indexRow += 1;
                }
                objColumnWorkPaidHourHLDByDay.ListValueByDay = listValueWorkPaidHourHLDByDay;
                objColumnNightShiftHourHLDByDay.ListValueByDay = listValueNightShiftHourHLDByDay;
                listColumnByDay.Add(objColumnWorkPaidHourHLDByDay);
                listColumnByDay.Add(objColumnNightShiftHourHLDByDay);
            }
            #endregion

            #region Minh.NguyenVan[0127378] [07/05/2021]Thêm phân từ ngày:Mã khu vực đóng bảo hiểm
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.ATT_REGION_CODE_BYDAY.ToString(),
                PayrollElementByDay.ATT_SALARY_KPI_BYDAY.ToString() }))
            {
                string colunmcodeArea = PayrollElementByDay.ATT_REGION_CODE_BYDAY.ToString();
                string colunmsalaryKpi = PayrollElementByDay.ATT_SALARY_KPI_BYDAY.ToString();

                ColumnByDay objColumnCodeArea = new ColumnByDay();
                objColumnCodeArea.ColumnName = colunmcodeArea;
                objColumnCodeArea.ValueType = strString;
                Dictionary<int, string> listValueCodeArea = new Dictionary<int, string>();

                ColumnByDay objColumnSalaryKpi = new ColumnByDay();
                objColumnSalaryKpi.ColumnName = colunmsalaryKpi;
                objColumnSalaryKpi.ValueType = strDouble;
                Dictionary<int, string> listValueSalatyKpi = new Dictionary<int, string>();

                int indexRow = 0;
                string status = string.Empty;
                var listWorkHistory = TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID)
                         .Where(s => s.Status == WorkHistoryStatus.E_APPROVED.ToString()).ToList();
                var listBasicSalary = TotalDataAll.dicBasicSalary.GetValueOrNew(profileItem.ID)
                    .Where(s => s.Status == WorkHistoryStatus.E_APPROVED.ToString()).ToList();

                var listCatRegion = TotalData.listRegionDetail = dataComputeSer.GetListRegionDetail(ref status);

                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string codeAreaForInsurance = string.Empty;
                    double salaryKpi = 0;
                    var objWorkHistory = listWorkHistory.Where(s =>
                                         s.DateEffective <= objAttendanceTableItem.WorkDate.Date
                                         ).OrderByDescending(s => s.DateEffective).FirstOrDefault();
                    var objBasicSalary = listBasicSalary.Where(s =>
                                         s.DateOfEffect <= objAttendanceTableItem.WorkDate.Date
                                         ).OrderByDescending(s => s.DateOfEffect).FirstOrDefault();

                    var objRegion = listCatRegion.Where(s =>
                                        s.RegionID == objWorkHistory.RegionID).FirstOrDefault();

                    if (objRegion != null && !string.IsNullOrEmpty(objRegion.Code))
                    {
                        codeAreaForInsurance = objRegion.Code;
                    }
                    if (!listValueCodeArea.ContainsKey(indexRow))
                    {
                        listValueCodeArea.Add(indexRow, codeAreaForInsurance);
                    }

                    if (objBasicSalary != null && objBasicSalary.KPIAmount != null)
                    {
                        salaryKpi = objBasicSalary.KPIAmount.Value;
                    }
                    if (!listValueSalatyKpi.ContainsKey(indexRow))
                    {
                        listValueSalatyKpi.Add(indexRow, salaryKpi.ToString());
                    }

                    indexRow += 1;
                }

                objColumnCodeArea.ListValueByDay = listValueCodeArea;
                listColumnByDay.Add(objColumnCodeArea);
                objColumnSalaryKpi.ListValueByDay = listValueSalatyKpi;
                listColumnByDay.Add(objColumnSalaryKpi);
            }
            #endregion

            #region Nghia.Dang  [17/5/2021] [0127348]: [Hotifix _Murata_v8.9.08.01.08.06] Thêm PTL lấy giờ công chuẩn theo ngày của những ca thực nhận trong bảng Att_Workday
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.ATTWORKDAYS_STDWORKHOURS_BYDAY.ToString()))
            {
                //Lấy data WorkDay nếu chưa được lấy trước đó
                string status = string.Empty;
                string nameTableGetData = "listAttWorkday";
                if (!TotalData.dicTableGetDataByProfileIDs.ContainsKey(nameTableGetData))
                {
                    TotalData.listAttWorkday = dataComputeSer.GetListAttWorkDay(TotalData.strOrderByProfile, CutOffDuration, ref status);
                    TotalData.dicTableGetDataByProfileIDs.Add(nameTableGetData, "");
                }
                //Trường hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông lưu store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.ATTWORKDAYS_STDWORKHOURS_BYDAY.ToString() + ") ";
                }
                else
                {
                    string colum = PayrollElementByDay.ATTWORKDAYS_STDWORKHOURS_BYDAY.ToString();
                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = colum;
                    objColumn.ValueType = strDouble;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();

                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        double srcType = 0;
                        var objWorkDate = TotalData.listAttWorkday.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date
                        ).FirstOrDefault();
                        if (objWorkDate != null && objWorkDate.ShiftActual != null)
                        {
                            var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == objWorkDate.ShiftActual);
                            if (objShift != null && objShift.StdWorkHours != null)
                            {
                                srcType = objShift.StdWorkHours.Value;
                            }
                        }
                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, srcType.ToString());
                        }
                        indexRow += 1;
                    }

                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 3 : Att_AttendanceTableItem.ExtraOvertimeType2ID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.ATTOVERTIME_ADDITIONALHOUR_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.ATTOVERTIME_ADDITIONALHOUR_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();
               
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }
                var listOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID).Where(x => x.Status == strOTStatus);
                int indexRow = 0;
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double total = 0;
                    var objOverTime = listOverTimeByProfileDic.Where(x=> x.WorkDateRoot!= null && x.WorkDateRoot.Value == objAttendanceTableItem.WorkDate && x.AdditionalHours != null).ToList();
                    if(objOverTime != null)
                    {
                        total = objOverTime.Sum(x=>x.AdditionalHours.Value);
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, total.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Minh.NguyenVan[0129028] [17/06/2021]Thêm phân từ ngày: lấy số giờ làm them trog ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.ATT_COUNT_OVERTIME_HOUR_BYDAY.ToString()})) 
            {
                string colunmNumberOfHour = PayrollElementByDay.ATT_COUNT_OVERTIME_HOUR_BYDAY.ToString();

                ColumnByDay objColumnNumberOfHour = new ColumnByDay();
                objColumnNumberOfHour.ColumnName = colunmNumberOfHour;
                objColumnNumberOfHour.ValueType = strDouble;
                Dictionary<int, string> listValueNumberOfHour = new Dictionary<int, string>();

                int indexRow = 0;
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double NumberOfHour = 0;
                
                    if (objAttendanceTableItem != null && objAttendanceTableItem.OTPregnancyHours != null)
                    {
                        NumberOfHour = objAttendanceTableItem.OTPregnancyHours.Value;
                    }
                    if (!listValueNumberOfHour.ContainsKey(indexRow))
                    {
                        listValueNumberOfHour.Add(indexRow, NumberOfHour.ToString());
                    }

                    indexRow += 1;
                }

                objColumnNumberOfHour.ListValueByDay = listValueNumberOfHour;
                listColumnByDay.Add(objColumnNumberOfHour);
            }
            #endregion
            #region kiet.nguyen[09/08/2021]--129930-- Thêm phần tử lương ngày lấy thời gian đăng ký tăng ca
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula,
             new string[] {
                    PayrollElementByDay.ATT_OVERTIME_WORKDATE_EARLY_BYDAY.ToString()
             }))
            {
                ColumnByDay objColumnWorkDate = new ColumnByDay();
                objColumnWorkDate.ColumnName = PayrollElementByDay.ATT_OVERTIME_WORKDATE_EARLY_BYDAY.ToString();
                objColumnWorkDate.ValueType = strDateTime;
                #region Trạng thái theo cấu hình "Giờ tăng ca được tính ở trạng thái" 
                var statusOT = string.Empty;
                var objSysAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objSysAllSetting != null)
                {
                    statusOT = objSysAllSetting.Value1;
                }
                #endregion
                Dictionary<int, string> listValueWorkDateEarly = new Dictionary<int, string>();
                var dicOTByProfile = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID)
                                                             .Where(m => m.DurationType == EnumDropDown.OvertimeDurationType.E_OT_EARLY.ToString() 
                                                                   &&  m.Status == statusOT)
                                                             .ToList();
                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var objAttOvertimeWorkDateEarly = dicOTByProfile
                        .Where(m => m.WorkDateRoot == objAttendanceTableItem.WorkDate &&  m.Status == statusOT
                                && m.DurationType == EnumDropDown.OvertimeDurationType.E_OT_EARLY.ToString())
                        .OrderBy(m => m.WorkDate).FirstOrDefault();

                    string workDate = string.Empty;
                    if (objAttOvertimeWorkDateEarly != null && objAttOvertimeWorkDateEarly.WorkDate != null)
                    {
                        workDate = objAttOvertimeWorkDateEarly.WorkDate.ToString();
                    }
                    if (!listValueWorkDateEarly.ContainsKey(indexRow))
                    {
                        listValueWorkDateEarly.Add(indexRow, workDate);
                    }
                    indexRow += 1;
                }
                objColumnWorkDate.ListValueByDay = listValueWorkDateEarly;
                listColumnByDay.Add(objColumnWorkDate);
            }
            #endregion

            #region Nghia.dang 131323 [23/8/2021] phân tử lương lấy thông tin trong danh sách phòng ban
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.HRE_STOPWORKING_CHECK_E_TEAM_BYDAY.ToString()))
            {
                string colum = PayrollElementByDay.HRE_STOPWORKING_CHECK_E_TEAM_BYDAY.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                var listWorkHistoryByProfileDic = TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID).Where(x =>x.DateEffective<= CutOffDuration.DateEnd && x.Status == WorkHistoryStatus.E_APPROVED.ToString());
                int indexRow = 0;

                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double isE_TEAM = 0;
                    var objWorkHistory = listWorkHistoryByProfileDic.Where(x => x.DateEffective <= objAttendanceTableItem.WorkDate).OrderByDescending(x=>x.DateEffective).FirstOrDefault();
                    if (objWorkHistory != null)
                    {
                        var objOrgUnit = TotalDataAll.ListOrgUnit.Where(x => x.OrgstructureID == objWorkHistory.OrganizationStructureID).FirstOrDefault();
                        if(objOrgUnit != null)
                        {
                            var objOrgStructure = TotalDataAll.listOrgStructure.Where(x => x.Code == objOrgUnit.E_TEAM_CODE).FirstOrDefault();
                            if(objOrgStructure!= null && objOrgStructure.FoundationDate <= objAttendanceTableItem.WorkDate && objOrgStructure.TerminationDate >= objAttendanceTableItem.WorkDate)
                            {
                                isE_TEAM = 1;
                            }
                        }
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, isE_TEAM.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Kiet.nguyen [06/09/2021] 132310 

            #region Phần tử ngày số ngày công tác trước thay đổi LEAVEWORKDAYDAYS_BYDAY
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVEWORKDAYDAYS_BYDAY.ToString() }))
            {

                string columLEAVEWORKDAYDAYS_BYDAY = PayrollElementByDay.LEAVEWORKDAYDAYS_BYDAY.ToString();
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVEWORKDAYDAYS_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueLEAVEWORKDAYDAYS_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double LeaveWorkDayDays = 0;
                    if (!listValueLEAVEWORKDAYDAYS_BYDAY.ContainsKey(indexRow))
                    {
                        if (objAttendanceTableItem.LeaveWorkDayDays != null)
                        {
                            LeaveWorkDayDays = objAttendanceTableItem.LeaveWorkDayDays.Value;
                        }
                        listValueLEAVEWORKDAYDAYS_BYDAY.Add(indexRow, LeaveWorkDayDays.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVEWORKDAYDAYS_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }

            #endregion

            #region Phần tử ngày trả ra mã cửa hàng từng ngày SHOPCODE_BYDAY
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.SHOPCODE_BYDAY.ToString() }))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.SHOPCODE_BYDAY.ToString();
                objColumnByDay.ValueType = strString;

                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                int indexRow = 0;
                string status = string.Empty;
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var listCatShop = TotalDataAll.listShop.Where(m => m.ID == objAttendanceTableItem.ShopID).FirstOrDefault();
                    string objshopcode = string.Empty;

                    if (listCatShop != null && listCatShop.Code != null)
                    {
                        objshopcode = listCatShop.Code;
                    }
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, objshopcode);
                    }
                    indexRow += 1;

                }
                objColumnByDay.ListValueByDay = listValueByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Phần tử ngày số ngày công tác trước thay đổi WORKHOURS_BYDAY
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.WORKHOURS_BYDAY.ToString() }))
            {
                string columWORKHOURS_BYDAY = PayrollElementByDay.WORKHOURS_BYDAY.ToString();
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columWORKHOURS_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueWORKHOURS_BYDAY = new Dictionary<int, string>();
                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValueWORKHOURS_BYDAY.ContainsKey(indexRow))
                    {
                        listValueWORKHOURS_BYDAY.Add(indexRow, objAttendanceTableItem.WorkHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueWORKHOURS_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }

            #endregion
            #endregion

            #region Kiet.Nguyen [23/10/2021] 133296: [Hotfix_MAPLife_v8.8.43.01.07] Thêm phần tử lương ngày : Kiêm nhiệm
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula,
             new string[] {
                    PayrollElementByDay.CONCURRENTALLOWANCE_BYDAY.ToString(),
             }))
            {
                ColumnByDay objColumnConcurrentAllowance = new ColumnByDay();
                objColumnConcurrentAllowance.ColumnName = PayrollElementByDay.CONCURRENTALLOWANCE_BYDAY.ToString();
                Dictionary<int, string> listValueNullCONCURRENTALLOWANCE_BYDAY = new Dictionary<int, string>();

                objColumnConcurrentAllowance.ValueType = strDouble;
                string status = string.Empty;
                dataComputeSer.GetListConCurrentSalary(TotalData, CutOffDuration, ref status);
                Dictionary<int, string> listValueConCurrentAllowance = new Dictionary<int, string>();
                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.CONCURRENTALLOWANCE_BYDAY.ToString() + ") ";
                    int indexRow = 0;
                    for (int i = 0; i < totalRowInDataSoure; i++)
                    {
                        if (!listValueNullCONCURRENTALLOWANCE_BYDAY.ContainsKey(indexRow))
                        {
                            listValueNullCONCURRENTALLOWANCE_BYDAY.Add(indexRow, 0.ToString());
                        }
                        indexRow += 1;
                    }
                }
                else
                {
                    int indexRow = 0;
                    var listConCurrent = TotalData.dicConCurrentSalary.GetValueOrNew(profileItem.ID).Where(s => s.Status == EnumDropDown.OverTimeStatus.E_APPROVED.ToString()).ToList();

                    double conCurrentAllowance = 0;
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {

                        var listobj = listConCurrent.Where(s => s.DateEffective == objAttendanceTableItem.WorkDate)
                            .OrderBy(s => s.DateEffective).FirstOrDefault();
    
                        if (listobj != null && listobj.ConcurrentAllowance != null)
                        {
                            conCurrentAllowance = listobj.ConcurrentAllowance.Value;
                        }

                        if (!listValueConCurrentAllowance.ContainsKey(indexRow))
                        {
                            listValueConCurrentAllowance.Add(indexRow, conCurrentAllowance.ToString());
                        }
                        indexRow += 1;
                    }
                }
                objColumnConcurrentAllowance.ListValueByDay = listValueConCurrentAllowance;
                listColumnByDay.Add(objColumnConcurrentAllowance);
            }
            #endregion

            #region Kiet.nguyen [15/11/2021] 134604 

            #region Thêm phần tử lương ngày trả về mã nơi làm việc 1
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.CODEWORKPLACE1ID_BYDAY.ToString() }))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.CODEWORKPLACE1ID_BYDAY.ToString();
                objColumnByDay.ValueType = strString;
                string status = string.Empty;
             
                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                int indexRow = 0;
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var listCatWorkPlace = TotalDataAll.lstWorkPlace.Where(m => m.ID == objAttendanceTableItem.WorkPlace1ID).FirstOrDefault();
                    string objWorkPlacecode = string.Empty;

                    if (listCatWorkPlace != null && listCatWorkPlace.Code != null)
                    {
                        objWorkPlacecode = listCatWorkPlace.Code;
                    }
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, objWorkPlacecode);
                    }
                    indexRow += 1;

                }
                objColumnByDay.ListValueByDay = listValueByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Thêm phần tử lương ngày trả về mã nơi làm việc 2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.CODEWORKPLACE2ID_BYDAY.ToString() }))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.CODEWORKPLACE2ID_BYDAY.ToString();
                objColumnByDay.ValueType = strString;

                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                int indexRow = 0;
                string status = string.Empty;
              
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var listCatWorkPlace = TotalDataAll.lstWorkPlace.Where(m => m.ID == objAttendanceTableItem.WorkPlace2ID).FirstOrDefault();
                    string objWorkPlacecode = string.Empty;

                    if (listCatWorkPlace != null && listCatWorkPlace.Code != null)
                    {
                        objWorkPlacecode = listCatWorkPlace.Code;
                    }
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, objWorkPlacecode);
                    }
                    indexRow += 1;

                }
                objColumnByDay.ListValueByDay = listValueByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Thêm phần tử lương ngày trả về giờ làm timesheet 1          
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.TIMESHEETHOURS1_BYDAY.ToString() }))
            {

                string columTIMESHEETHOURS1_BYDAY = PayrollElementByDay.TIMESHEETHOURS1_BYDAY.ToString();
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columTIMESHEETHOURS1_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueTIMESHEETHOURS1_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double objTimesheetHours1 = 0;
                    if (!listValueTIMESHEETHOURS1_BYDAY.ContainsKey(indexRow))
                    {
                        if (objAttendanceTableItem.TimesheetHours1 != null)
                        {
                            objTimesheetHours1 = objAttendanceTableItem.TimesheetHours1.Value;
                        }
                        listValueTIMESHEETHOURS1_BYDAY.Add(indexRow, objTimesheetHours1.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueTIMESHEETHOURS1_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Thêm phần tử lương ngày trả về giờ làm timesheet 2         
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.TIMESHEETHOURS2_BYDAY.ToString() }))
            {

                string columTIMESHEETHOURS2_BYDAY = PayrollElementByDay.TIMESHEETHOURS2_BYDAY.ToString();
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columTIMESHEETHOURS2_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueTIMESHEETHOURS2_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double objTimesheetHours2 = 0;
                    if (!listValueTIMESHEETHOURS2_BYDAY.ContainsKey(indexRow))
                    {
                        if (objAttendanceTableItem.TimesheetHours2 != null)
                        {
                            objTimesheetHours2 = objAttendanceTableItem.TimesheetHours2.Value;
                        }
                        listValueTIMESHEETHOURS2_BYDAY.Add(indexRow, objTimesheetHours2.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueTIMESHEETHOURS2_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #endregion
            #region Nghia.Dang [11/8/2021] [135000] Số phút vào trễ chuyên cần đầu ca 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.ATT_ATTTABLEITEM_LATEINMINUTES4_BYDAY.ToString() }))
            {
                ColumnByDay objColumnLateInMinutes4 = new ColumnByDay();
                objColumnLateInMinutes4.ColumnName = PayrollElementByDay.ATT_ATTTABLEITEM_LATEINMINUTES4_BYDAY.ToString();
                objColumnLateInMinutes4.ValueType = strDouble;

                Dictionary<int, string> listValueLateInMinutes4 = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double LateInMinutes4 = 0;

                    if (objAttendanceTableItem.LateInMinutes4 != null)
                    {
                        LateInMinutes4 = objAttendanceTableItem.LateInMinutes4.Value;
                    }

                    if (!listValueLateInMinutes4.ContainsKey(indexRow))
                    {
                        listValueLateInMinutes4.Add(indexRow, LateInMinutes4.ToString());
                    }
                    indexRow += 1;
                }
                objColumnLateInMinutes4.ListValueByDay = listValueLateInMinutes4;
                listColumnByDay.Add(objColumnLateInMinutes4);
            }
            #endregion
            #region Nghia.Dang [11/8/2021] [135000] Số phút vào trễ chuyên cần đầu ca 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.ATT_ATTTABLEITEM_LATEINMINUTES5_BYDAY.ToString() }))
            {
                ColumnByDay objColumnLateInMinutes5 = new ColumnByDay();
                objColumnLateInMinutes5.ColumnName = PayrollElementByDay.ATT_ATTTABLEITEM_LATEINMINUTES5_BYDAY.ToString();
                objColumnLateInMinutes5.ValueType = strDouble;

                Dictionary<int, string> listValueLateInMinutes5 = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double LateInMinutes5 = 0;

                    if (objAttendanceTableItem.LateInMinutes5 != null)
                    {
                        LateInMinutes5 = objAttendanceTableItem.LateInMinutes5.Value;
                    }

                    if (!listValueLateInMinutes5.ContainsKey(indexRow))
                    {
                        listValueLateInMinutes5.Add(indexRow, LateInMinutes5.ToString());
                    }
                    indexRow += 1;
                }
                objColumnLateInMinutes5.ListValueByDay = listValueLateInMinutes5;
                listColumnByDay.Add(objColumnLateInMinutes5);
            }
            #endregion
            #region Nghia.Dang [11/8/2021] [135000] Số phút vào trễ chuyên cần đầu ca 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.ATT_ATTTABLEITEM_LATEOUTMINUTES4_BYDAY.ToString() }))
            {
                ColumnByDay objColumnEarlyOutMinutes4 = new ColumnByDay();
                objColumnEarlyOutMinutes4.ColumnName = PayrollElementByDay.ATT_ATTTABLEITEM_LATEOUTMINUTES4_BYDAY.ToString();
                objColumnEarlyOutMinutes4.ValueType = strDouble;

                Dictionary<int, string> listValueEarlyOutMinutes4 = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double EarlyOutMinutes4 = 0;

                    if (objAttendanceTableItem.LateOutMinutes4 != null)
                    {
                        EarlyOutMinutes4 = objAttendanceTableItem.LateOutMinutes4.Value;
                    }

                    if (!listValueEarlyOutMinutes4.ContainsKey(indexRow))
                    {
                        listValueEarlyOutMinutes4.Add(indexRow, EarlyOutMinutes4.ToString());
                    }
                    indexRow += 1;
                }
                objColumnEarlyOutMinutes4.ListValueByDay = listValueEarlyOutMinutes4;
                listColumnByDay.Add(objColumnEarlyOutMinutes4);
            }
            #endregion
            #region Nghia.Dang [11/8/2021] [135000] Số phút vào trễ chuyên cần đầu ca 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.ATT_ATTTABLEITEM_LATEOUTMINUTES5_BYDAY.ToString() }))
            {
                ColumnByDay objColumnEarlyOutMinutes5 = new ColumnByDay();
                objColumnEarlyOutMinutes5.ColumnName = PayrollElementByDay.ATT_ATTTABLEITEM_LATEOUTMINUTES5_BYDAY.ToString();
                objColumnEarlyOutMinutes5.ValueType = strDouble;

                Dictionary<int, string> listValueEarlyOutMinutes5 = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double EarlyOutMinutes5 = 0;

                    if (objAttendanceTableItem.LateOutMinutes5 != null)
                    {
                        EarlyOutMinutes5 = objAttendanceTableItem.LateOutMinutes5.Value;
                    }

                    if (!listValueEarlyOutMinutes5.ContainsKey(indexRow))
                    {
                        listValueEarlyOutMinutes5.Add(indexRow, EarlyOutMinutes5.ToString());
                    }
                    indexRow += 1;
                }
                objColumnEarlyOutMinutes5.ListValueByDay = listValueEarlyOutMinutes5;
                listColumnByDay.Add(objColumnEarlyOutMinutes5);
            }
            #endregion

            #region Nghia.Dang [11/8/2021] [135000] Mã loại nghỉ lễ 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.ATT_ATTTABLEITEM_DATEOFF_BYDAY.ToString() }))
            {
                ColumnByDay objColumnDayOff = new ColumnByDay();
                objColumnDayOff.ColumnName = PayrollElementByDay.ATT_ATTTABLEITEM_DATEOFF_BYDAY.ToString();
                objColumnDayOff.ValueType = strString;

                Dictionary<int, string> listValuedayOffType = new Dictionary<int, string>();

                int indexRow = 0;
                var listDateOff = TotalDataAll.listDayOff.ToList();
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string dayOffType = string.Empty;

                    if (objAttendanceTableItem.IsHoliday)
                    {
                        var objDayOff = listDateOff.Where(x => x.DateOff == objAttendanceTableItem.WorkDate).FirstOrDefault();
                        if (objDayOff != null && !string.IsNullOrEmpty(objDayOff.Type))
                        {
                            dayOffType = objDayOff.Type;
                        }
                    }
                    if (!listValuedayOffType.ContainsKey(indexRow))
                    {
                        listValuedayOffType.Add(indexRow, dayOffType);
                    }
                    indexRow += 1;
                }
                objColumnDayOff.ListValueByDay = listValuedayOffType;
                listColumnByDay.Add(objColumnDayOff);
            }
            #endregion
            #region Nghia.Dang [11/8/2021] [135000] Mã chức danh của nhân viên theo Hre_WorkHistory 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.HRE_WORKHISTORY_JOBTITLE_CODE_BYDAY.ToString() }))
            {
                ColumnByDay objJobTitlCode = new ColumnByDay();
                objJobTitlCode.ColumnName = PayrollElementByDay.HRE_WORKHISTORY_JOBTITLE_CODE_BYDAY.ToString();
                objJobTitlCode.ValueType = strString;

                Dictionary<int, string> listValueJobTitlCode = new Dictionary<int, string>();

                int indexRow = 0;
                var listWorkHistory = TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID).Where(x => x.DateEffective <= CutOffDuration.DateEnd && x.Status == WorkHistoryStatus.E_APPROVED.ToString());
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string JobTitlCode = string.Empty;

                    var objWorkHistory = listWorkHistory.Where(x => x.DateEffective <= objAttendanceTableItem.WorkDate).OrderByDescending(x => x.DateEffective).FirstOrDefault();
                    if (objWorkHistory != null)
                    {
                        JobTitlCode = objWorkHistory.JobTitleCode;
                    }
                    if (!listValueJobTitlCode.ContainsKey(indexRow))
                    {
                        listValueJobTitlCode.Add(indexRow, JobTitlCode);
                    }
                    indexRow += 1;
                }
                objJobTitlCode.ListValueByDay = listValueJobTitlCode;
                listColumnByDay.Add(objJobTitlCode);
            }
            #endregion
            #region Nghia.Dang [11/8/2021] [135000] Mã HD
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.HRE_CONTRACT_CODE_BYDAY.ToString() }))
            {
                ColumnByDay objContractCode = new ColumnByDay();
                objContractCode.ColumnName = PayrollElementByDay.HRE_CONTRACT_CODE_BYDAY.ToString();
                objContractCode.ValueType = strString;

                Dictionary<int, string> listValueContractCode = new Dictionary<int, string>();
                string status = string.Empty;
                dataComputeSer.GetDicContract(TotalData, CutOffDuration, ref status);

                int indexRow = 0;
                var listContract = TotalData.dicContract.GetValueOrNew(profileItem.ID).Where(x => x.DateStart <= CutOffDuration.DateEnd &&( x.DateEnd != null ? x.DateEnd.Value : CutOffDuration.DateStart) >= CutOffDuration.DateStart && x.Status == WorkHistoryStatus.E_APPROVED.ToString());
                var listContractType = TotalDataAll.lstContractType.ToList();

                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string ContractCode = string.Empty;

                    var objContract = listContract.Where(x => x.DateStart <= objAttendanceTableItem.WorkDate && (x.DateEnd != null ? x.DateEnd.Value : objAttendanceTableItem.WorkDate) >= objAttendanceTableItem.WorkDate).OrderByDescending(x => x.DateStart).FirstOrDefault();
                    if (objContract != null)
                    {
                        ContractCode = objContract.ContractTypeCode;
                    }
                    if (!listValueContractCode.ContainsKey(indexRow))
                    {
                        listValueContractCode.Add(indexRow, ContractCode);
                    }
                    indexRow += 1;
                }
                objContractCode.ListValueByDay = listValueContractCode;
                listColumnByDay.Add(objContractCode);
            }
            #endregion
            #region Nghia.Dang [11/8/2021] [135000] Mã phụ lục HD 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.HRE_CONTRACTEXTEND_CODE_BYDAY.ToString() }))
            {
                ColumnByDay objContractCode = new ColumnByDay();
                objContractCode.ColumnName = PayrollElementByDay.HRE_CONTRACTEXTEND_CODE_BYDAY.ToString();
                objContractCode.ValueType = strString;

                Dictionary<int, string> listValueContractCode = new Dictionary<int, string>();
                string status = string.Empty;
                dataComputeSer.GetListContactExtend(TotalData, new Hre_ContractExtendEntity(), ref status);

                int indexRow = 0;
                var listContract = TotalData.dicHreContractExtend.GetValueOrNew(profileItem.ID).Where(x => x.DateStart <= CutOffDuration.DateEnd &&( x.DateEnd != null ? x.DateEnd : CutOffDuration.DateStart) >= CutOffDuration.DateStart && x.Status == WorkHistoryStatus.E_APPROVED.ToString());
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string ContractCode = string.Empty;

                    var objContract = listContract.Where(x => x.DateStart <= objAttendanceTableItem.WorkDate && (x.DateEnd != null ? x.DateEnd : objAttendanceTableItem.WorkDate) >= objAttendanceTableItem.WorkDate).OrderByDescending(x => x.DateStart).FirstOrDefault();
                    if (objContract != null)
                    {
                        ContractCode = objContract.AppendixContractTypeCode;
                    }
                    if (!listValueContractCode.ContainsKey(indexRow))
                    {
                        listValueContractCode.Add(indexRow, ContractCode);
                    }
                    indexRow += 1;
                }
                objContractCode.ListValueByDay = listValueContractCode;
                listColumnByDay.Add(objContractCode);
            }
            #endregion 
            #region Nghia.Dang [11/8/2021] [135000] mã hình thức kỷ luật
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.HRE_DISCIPLINE_CODE_BYDAY.ToString() }))
            {
                string status = string.Empty;
                dataComputeSer.GetListDiscipline(TotalData, CutOffDuration, ref status);
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.HRE_DISCIPLINE_CODE_BYDAY.ToString() + ") ";
                    item = new ElementFormula(PayrollElementByDay.HRE_DISCIPLINE_CODE_BYDAY.ToString(), 0, 0);
                    listElementFormulaByDay.Add(item);
                }
                else
                {
                    ColumnByDay objContractCode = new ColumnByDay();
                    objContractCode.ColumnName = PayrollElementByDay.HRE_DISCIPLINE_CODE_BYDAY.ToString();
                    objContractCode.ValueType = strString;

                    Dictionary<int, string> listValueContractCode = new Dictionary<int, string>();
                    int indexRow = 0;
                    var listContract = TotalData.dicDiscipline.GetValueOrNew(profileItem.ID).Where(x => x.DateOfEffective <= CutOffDuration.DateEnd && (x.DateEndOfViolation != null ? x.DateEndOfViolation.Value.Date : CutOffDuration.DateStart.Date) >= CutOffDuration.DateStart.Date && x.ApproveStatus == WorkHistoryStatus.E_APPROVED.ToString());
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        string ContractCode = string.Empty;

                        var objContract = listContract.Where(x => x.DateOfEffective <= objAttendanceTableItem.WorkDate && (x.DateEndOfViolation != null ? x.DateEndOfViolation.Value.Date : objAttendanceTableItem.WorkDate.Date) >= objAttendanceTableItem.WorkDate.Date).OrderByDescending(x => x.DateOfEffective).FirstOrDefault();
                        if (objContract != null)
                        {
                            ContractCode = objContract.DisciplinedTypeCode;
                        }
                        if (!listValueContractCode.ContainsKey(indexRow))
                        {
                            listValueContractCode.Add(indexRow, ContractCode);
                        }
                        indexRow += 1;
                    }
                    objContractCode.ListValueByDay = listValueContractCode;
                    listColumnByDay.Add(objContractCode);
                }
            }
            #endregion
            #region minhnguyenvan-22/12/2021 0136839: Hot fix source [TOYOTA_v8.9.44.01.12] thêm phần tử lương ngày tính phụ cấp bữa ăn nhẹ
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.CATSHIFT_ISHAVEMEAL_BYDAY.ToString()}))
            {
                string colunmIsHaveMeal = PayrollElementByDay.CATSHIFT_ISHAVEMEAL_BYDAY.ToString();

                ColumnByDay objColumnIsHaveMeal = new ColumnByDay();
                objColumnIsHaveMeal.ColumnName = colunmIsHaveMeal;
                objColumnIsHaveMeal.ValueType = strDouble;
                Dictionary<int, string> listValueIsHaveMeal = new Dictionary<int, string>();

                int indexRow = 0;
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double IsHaveMeal = 0;

                    if (objAttendanceTableItem != null && objAttendanceTableItem.ShiftID != null)
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null && objShift.IsHaveMeal != null && objShift.IsHaveMeal == true)
                        {
                            IsHaveMeal = 1;
                        }
                    }
                    if (!listValueIsHaveMeal.ContainsKey(indexRow))
                    {
                        listValueIsHaveMeal.Add(indexRow, IsHaveMeal.ToString());
                    }

                    indexRow += 1;
                }

                objColumnIsHaveMeal.ListValueByDay = listValueIsHaveMeal;
                listColumnByDay.Add(objColumnIsHaveMeal);
            }
            #endregion
            #endregion
            #region Enum động

            #region Tung.Tran [11/11/2021][135001]: Truyền động tên cột cần lấy trong bảng Cat_OrgUnit để tra về mã phòng ban theo ngày trong bảng Hre_WorkHistory 

            if (computePayrollSer.CheckIsExistFormula(
                listElementFormulaByDay,
                ref formula,
                PayrollElementByDay.DYN70_CAT_ORGUNIT_BY_.ToString(),
                "_BYDAY"))
            {
                var listWorkHistory = TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID);
                var strStartsWith = PayrollElementByDay.DYN70_CAT_ORGUNIT_BY_.ToString();
                var strEndWith = "_BYDAY";
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var itemFormula in ListFormula)
                {
                    var columnName = itemFormula
                        .Replace(PayrollElementByDay.DYN70_CAT_ORGUNIT_BY_.ToString(), "")
                        .Replace("_BYDAY", "");

                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = itemFormula;
                    objColumn.ValueType = strString;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();

                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        string strValue = "";
                        var objWorkHistory = listWorkHistory
                                        .Where(s => s.DateEffective <= objAttendanceTableItem.WorkDate.Date
                                                && s.Status == WorkHistoryStatus.E_APPROVED.ToString())
                                        .OrderByDescending(s => s.DateEffective)
                                        .FirstOrDefault();
                        if (objWorkHistory != null && !Common.IsNullOrGuidEmpty(objWorkHistory.OrganizationStructureID))
                        {
                            var objOrgUnit = TotalDataAll.ListOrgUnit
                                .Where(x => x.OrgstructureID == objWorkHistory.OrganizationStructureID)
                                .FirstOrDefault();

                            if (objOrgUnit != null && objOrgUnit.HasProperty(columnName) && objOrgUnit.GetPropertyValue(columnName) != null)
                            {
                                strValue = objOrgUnit.GetPropertyValue(columnName).ToString();
                            }
                        }
                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, strValue.ToString());
                        }
                        indexRow += 1;
                    }
                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion

            #region Tung.Tran [11/11/2021][135001]: Truyền động mã phụ cấp để trả về số tiền phụ cấp tương ứng trong bảng lương cơ bản

            if (computePayrollSer.CheckIsExistFormula(
                listElementFormulaByDay,
                ref formula,
                PayrollElementByDay.DYN69_BASICSALARY_SUMAMOUNT_BY_.ToString(),
                "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN69_BASICSALARY_SUMAMOUNT_BY_.ToString();
                var strEndWith = "_BYDAY";
                var listBasicSalary = TotalDataAll.dicBasicSalary.GetValueOrNew(profileItem.ID);
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var itemFormula in ListFormula)
                {
                    var unusualTypeCode = itemFormula
                        .Replace(PayrollElementByDay.DYN69_BASICSALARY_SUMAMOUNT_BY_.ToString(), "")
                        .Replace("_BYDAY", "");

                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = itemFormula;
                    objColumn.ValueType = strDouble;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();

                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        double totalAmount = 0;

                        var objUnusualAllowance = TotalDataAll.listUsualAllowance.FirstOrDefault(x => x.Code == unusualTypeCode);
                        if (objUnusualAllowance != null)
                        {
                            var objBasicSalary = listBasicSalary
                                   .Where(s => s.DateOfEffect <= objAttendanceTableItem.WorkDate && s.Status == "E_APPROVED")
                                   .OrderByDescending(s => s.DateOfEffect)
                                   .FirstOrDefault();

                            if (objBasicSalary != null)
                            {
                                if (objBasicSalary.AllowanceType1ID == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount1 ?? 0;
                                }
                                if (objBasicSalary.AllowanceType2ID == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount2 ?? 0;
                                }
                                if (objBasicSalary.AllowanceType3ID == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount3 ?? 0;
                                }
                                if (objBasicSalary.AllowanceType4ID == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount4 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID5 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount5 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID6 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount6 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID7 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount7 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID8 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount8 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID9 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount9 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID10 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount10 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID11 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount11 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID12 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount12 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID13 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount13 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID14 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount14 ?? 0;
                                }
                                if (objBasicSalary.AllowanceTypeID15 == objUnusualAllowance.ID)
                                {
                                    totalAmount += objBasicSalary.AllowanceAmount15 ?? 0;
                                }
                            }
                        }

                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, totalAmount.ToString());
                        }
                        indexRow += 1;
                    }
                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion
            #region Tung.Tran [30/10/2021][134423]: Số giờ tăng ca liên tiếp theo loại tăng ca (Trước ca, sau ca ...)

            if (computePayrollSer.CheckIsExistFormula(
                listElementFormulaByDay,
                ref formula,
                PayrollElementByDay.DYN68_ATT_OVERTIME_SUM_HOUROT_BY_.ToString(),
                "_BYDAY"))
            {
                var listOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }

                var strStartsWith = PayrollElementByDay.DYN68_ATT_OVERTIME_SUM_HOUROT_BY_.ToString();
                var strEndWith = "_BYDAY";
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var itemFormula in ListFormula)
                {
                    // Tách lấy chuỗi các giá trị số chặn đầu, chặn cuối
                    var strDurationType = itemFormula
                        .Replace(PayrollElementByDay.DYN68_ATT_OVERTIME_SUM_HOUROT_BY_.ToString(), "")
                        .Replace("_BYDAY", "");

                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = itemFormula;
                    objColumn.ValueType = strDouble;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();

                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        //Giờ tăng ca liên tiếp theo DurationType
                        double hourOT = 0;
                        // Lấy danh sách OT
                        var listOverTime = listOverTimeByProfileDic.Where(x =>
                             x.WorkDateRoot != null
                             && x.ShiftID != null
                             && x.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date
                             && x.Status == strOTStatus
                             && x.DurationType == strDurationType )
                            .OrderBy(x => x.WorkDate)
                            .ToList();

                        if (listOverTime.Any())
                        {
                            #region Xác định giờ bắt đầu, kết thúc tăng ca giao nhau của các lần dk tăng ca
                            var objOverTimeFirst = listOverTime.FirstOrDefault();
                            DateTime hourStartOT = objOverTimeFirst.WorkDate;
                            DateTime hourEndOT = objOverTimeFirst.WorkDate;

                            if (strOTStatus == EnumDropDown.OverTimeStatus.E_APPROVED.ToString() && objOverTimeFirst.ApproveHours != null)
                            {
                                hourEndOT = hourStartOT.AddHours(objOverTimeFirst.ApproveHours.Value);
                            }
                            else if (strOTStatus == EnumDropDown.OverTimeStatus.E_CONFIRM.ToString())
                            {
                                hourEndOT = hourStartOT.AddHours(objOverTimeFirst.ConfirmHours);
                            }
                            else if (strOTStatus == EnumDropDown.OverTimeStatus.E_SUBMIT.ToString())
                            {
                                hourEndOT = hourStartOT.AddHours(objOverTimeFirst.RegisterHours);
                            }
                            #endregion

                            foreach (var itemOverTime in listOverTime)
                            {
                                var objOTNext = listOverTime.FirstOrDefault(x => x.WorkDate == hourEndOT);
                                if (objOTNext != null)
                                {
                                    if (strOTStatus == EnumDropDown.OverTimeStatus.E_APPROVED.ToString() && objOTNext.ApproveHours != null)
                                    {
                                        hourEndOT = hourEndOT.AddHours(objOTNext.ApproveHours.Value);
                                    }
                                    else if (strOTStatus == EnumDropDown.OverTimeStatus.E_CONFIRM.ToString())
                                    {
                                        hourEndOT = hourEndOT.AddHours(objOTNext.ConfirmHours);
                                    }
                                    else if (strOTStatus == EnumDropDown.OverTimeStatus.E_SUBMIT.ToString())
                                    {
                                        hourEndOT = hourEndOT.AddHours(objOTNext.RegisterHours);
                                    }
                                }
                            }
                            hourOT = (hourEndOT - hourStartOT).TotalHours;
                        }

                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, hourOT.ToString());
                        }
                        indexRow += 1;
                    }
                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion

            #region Tung.Tran [17/06/2019][106331]: Tung.Tran [17/06/2019][106331]: Tăng ca ngày có ca làm việc nếu số giờ tăng ca xác nhận thỏa điều kiện chặn đầu chặn cuối , số giờ đăng ký thỏa điều kiện chặn đầu chặn cuối 
            /// DYN40_COUNT_ATT_OVERTIME_BYCONFIRMHOURS + "Chặn đầu" + "_" + Chặn cuối + _REGISTERHOURS + "Chặn đầu" + "_" + Chặn cuối 

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN40_COUNT_ATT_OVERTIME_BYCONFIRMHOURS_.ToString(), "_BYDAY"))
            {
                var listOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }

                var strStartsWith = PayrollElementByDay.DYN40_COUNT_ATT_OVERTIME_BYCONFIRMHOURS_.ToString();
                var strEndWith = "_BYDAY";
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                // Lọc lấy các enum đặt đúng, chỗ kiểm tra công thức đã kiểm tra, ở đây kiểm tra thêm 1 lần phòng trường hợp import sai
                ListFormula = ListFormula.Where(x => {

                    var strNumber = x.Replace(PayrollElementByDay.DYN40_COUNT_ATT_OVERTIME_BYCONFIRMHOURS_.ToString(), "")
                                       .Replace("REGISTERHOURS_", "")
                                       .Replace("_BYDAY", "");
                    // Tách lấy list các giá trị số chặn đầu, chặn cuối
                    var listNumber = strNumber.Split("_");
                    // Cấu hình đúng: Có 2 giá trị chặn đầu, 2 giá trị chặn cuối, và đúng kiểu double
                    double a;
                    if (listNumber.Count == 4
                        && double.TryParse(listNumber[0], out a)
                        && double.TryParse(listNumber[1], out a)
                        && double.TryParse(listNumber[2], out a)
                        && double.TryParse(listNumber[3], out a)
                    )
                    {
                        return true;
                    }
                    return false;
                }).ToList();

                foreach (var itemFormula in ListFormula)
                {
                    // Tách lấy chuỗi các giá trị số chặn đầu, chặn cuối
                    var strNumber = itemFormula.Replace(PayrollElementByDay.DYN40_COUNT_ATT_OVERTIME_BYCONFIRMHOURS_.ToString(), "")
                                        .Replace("REGISTERHOURS_", "")
                                        .Replace("_BYDAY", "");
                    // Tách lấy list các giá trị số chặn đầu, chặn cuối
                    var listNumber = strNumber.Split("_");

                    double confirmHoursFrom = double.Parse(listNumber[0]);
                    double confirmHoursTo = double.Parse(listNumber[1]);
                    double RegisterHoursFrom = double.Parse(listNumber[2]);
                    double RegisterHoursTo = double.Parse(listNumber[3]);


                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = itemFormula;
                    objColumn.ValueType = strDouble;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();


                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        int countOT = 0;

                        if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.ShiftID) || !Common.IsNullOrGuidEmpty(objAttendanceTableItem.Shift2ID))
                        {

                            countOT = listOverTimeByProfileDic.Where(x =>
                                    x.WorkDateRoot != null
                                    && x.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date
                                    && x.Status == strOTStatus
                                    && x.ConfirmHours >= confirmHoursFrom
                                    && x.ConfirmHours <= confirmHoursTo
                                    && x.RegisterHours >= RegisterHoursFrom
                                    && x.RegisterHours <= RegisterHoursTo
                                ).Count();
                        }

                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, countOT.ToString());
                        }
                        indexRow += 1;
                    }
                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion

            #region Tung.Tran [17/06/2019][106331]: Tung.Tran [17/06/2019][106331]: Số lần tăng ca trong khung giờ ca, ngày KHÔNG ca làm việc 
            // DYN41_COUNT_ATT_OVERTIME_HOURS_INSHIFT_ + "Chặn đầu" + "_" + Chặn cuối 

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN41_COUNT_ATT_OVERTIME_HOURS_INSHIFT_.ToString(), "_BYDAY"))
            {
                var listOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }

                var strStartsWith = PayrollElementByDay.DYN41_COUNT_ATT_OVERTIME_HOURS_INSHIFT_.ToString();
                var strEndWith = "_BYDAY";
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                // Lọc lấy các enum đặt đúng, chỗ kiểm tra công thức đã kiểm tra, ở đây kiểm tra thêm 1 lần phòng trường hợp import sai
                ListFormula = ListFormula.Where(x => {

                    var strNumber = x.Replace(PayrollElementByDay.DYN41_COUNT_ATT_OVERTIME_HOURS_INSHIFT_.ToString(), "").Replace("_BYDAY", "");

                    // Tách lấy list các giá trị số chặn đầu, chặn cuối
                    var listNumber = strNumber.Split("_");
                    // Cấu hình đúng: Có 2 giá trị chặn đầu, chặn cuối, và đúng kiểu double
                    double a;
                    if (listNumber.Count == 2
                        && double.TryParse(listNumber[0], out a)
                        && double.TryParse(listNumber[1], out a)
                    )
                    {
                        return true;
                    }
                    return false;
                }).ToList();

                foreach (var itemFormula in ListFormula)
                {
                    // Tách lấy chuỗi các giá trị số chặn đầu, chặn cuối
                    var strNumber = itemFormula.Replace(PayrollElementByDay.DYN41_COUNT_ATT_OVERTIME_HOURS_INSHIFT_.ToString(), "").Replace("_BYDAY", "");

                    // Tách lấy list các giá trị số chặn đầu, chặn cuối
                    var listNumber = strNumber.Split("_");

                    double hoursFrom = double.Parse(listNumber[0]);
                    double hoursTo = double.Parse(listNumber[1]);


                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = itemFormula;
                    objColumn.ValueType = strDouble;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();


                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        int countOT = 0;

                        if (Common.IsNullOrGuidEmpty(objAttendanceTableItem.ShiftID) && Common.IsNullOrGuidEmpty(objAttendanceTableItem.Shift2ID))
                        {
                            // Lấy danh sách OT
                            var listOverTime = listOverTimeByProfileDic.Where(x =>
                                 x.WorkDateRoot != null
                                 && x.ShiftID != null
                                 && x.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date
                                 && x.Status == strOTStatus
                             ).ToList();

                            // For từng dòng OT kiểm tra số giờ giao nhau
                            foreach (var itemOverTime in listOverTime)
                            {
                                double totalHours = 0;
                                // Lấy thông tin ca làm việc
                                var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == itemOverTime.ShiftID);
                                if (objShift != null && itemOverTime.InTime != null && itemOverTime.OutTime != null)
                                {
                                    // Giờ bắt đầu ca
                                    var inTime = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                        objAttendanceTableItem.WorkDate.Month,
                                        objAttendanceTableItem.WorkDate.Day,
                                        objShift.InTime.Hour,
                                        objShift.InTime.Minute,
                                        objShift.InTime.Second
                                        );

                                    // Giờ kết thúc ca
                                    var outTime = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                       objAttendanceTableItem.WorkDate.Month,
                                       objAttendanceTableItem.WorkDate.Day,
                                       objShift.InTime.Hour,
                                       objShift.InTime.Minute,
                                       objShift.InTime.Second
                                       ).AddHours(objShift.CoOut);

                                    // Xác định khoảng thời gian giao nhau giữa thời gian nghỉ và giờ nghỉ giữa ca
                                    // Nếu có giao dic = true và trả về điểm bắt đầu giao và điểm kết thúc giao
                                    var dic = Common.GetStartEndTimeLine(inTime, outTime, itemOverTime.InTime.Value, itemOverTime.OutTime.Value);
                                    if (dic.ContainsKey(true))
                                    {
                                        // Lấy ra số giờ giao nhau
                                        totalHours = (dic[true].LastOrDefault() - dic[true].FirstOrDefault()).TotalHours;

                                        // kiểm tra có thỏa điều kiện chặn đầu, chặn cuối hay không ?
                                        if (totalHours >= hoursFrom && totalHours <= hoursTo)
                                        {
                                            countOT++;
                                        }
                                    }
                                }
                            }
                        }

                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, countOT.ToString());
                        }
                        indexRow += 1;
                    }
                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion

            #region Tung.Tran [17/06/2019][106331]: Tung.Tran [17/06/2019][106331]: Số lần tăng ca ngoài khung giờ ca, ngày KHÔNG ca làm việc 
            // DYN42_COUNT_ATT_OVERTIME_HOURS_OUTSHIFT_ + "Chặn đầu" + "_" + Chặn cuối 

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN42_COUNT_ATT_OVERTIME_HOURS_OUTSHIFT_.ToString(), "_BYDAY"))
            {
                var listOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }

                var strStartsWith = PayrollElementByDay.DYN42_COUNT_ATT_OVERTIME_HOURS_OUTSHIFT_.ToString();
                var strEndWith = "_BYDAY";
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                // Lọc lấy các enum đặt đúng, chỗ kiểm tra công thức đã kiểm tra, ở đây kiểm tra thêm 1 lần phòng trường hợp import sai
                ListFormula = ListFormula.Where(x => {

                    var strNumber = x.Replace(PayrollElementByDay.DYN42_COUNT_ATT_OVERTIME_HOURS_OUTSHIFT_.ToString(), "").Replace("_BYDAY", "");

                    // Tách lấy list các giá trị số chặn đầu, chặn cuối
                    var listNumber = strNumber.Split("_");
                    // Cấu hình đúng: Có 2 giá trị chặn đầu, chặn cuối, và đúng kiểu double
                    double a;
                    if (listNumber.Count == 2
                        && double.TryParse(listNumber[0], out a)
                        && double.TryParse(listNumber[1], out a)
                    )
                    {
                        return true;
                    }
                    return false;
                }).ToList();

                foreach (var itemFormula in ListFormula)
                {
                    // Tách lấy chuỗi các giá trị số chặn đầu, chặn cuối
                    var strNumber = itemFormula.Replace(PayrollElementByDay.DYN42_COUNT_ATT_OVERTIME_HOURS_OUTSHIFT_.ToString(), "").Replace("_BYDAY", "");

                    // Tách lấy list các giá trị số chặn đầu, chặn cuối
                    var listNumber = strNumber.Split("_");

                    double hoursFrom = double.Parse(listNumber[0]);
                    double hoursTo = double.Parse(listNumber[1]);


                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = itemFormula;
                    objColumn.ValueType = strDouble;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();


                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        int countOT = 0;

                        if (Common.IsNullOrGuidEmpty(objAttendanceTableItem.ShiftID) && Common.IsNullOrGuidEmpty(objAttendanceTableItem.Shift2ID))
                        {
                            // Lấy danh sách OT
                            var listOverTime = listOverTimeByProfileDic.Where(x =>
                                 x.WorkDateRoot != null
                                 && x.ShiftID != null
                                 && x.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date
                                 && x.Status == strOTStatus
                             ).ToList();

                            // For từng dòng OT kiểm tra số giờ giao nhau
                            foreach (var itemOverTime in listOverTime)
                            {
                                double totalHours = 0;
                                // Lấy thông tin ca làm việc
                                var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == itemOverTime.ShiftID);
                                if (objShift != null && itemOverTime.InTime != null && itemOverTime.OutTime != null)
                                {
                                    var hoursOT = (itemOverTime.OutTime.Value - itemOverTime.InTime.Value).TotalHours;

                                    // Giờ bắt đầu ca
                                    var inTime = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                        objAttendanceTableItem.WorkDate.Month,
                                        objAttendanceTableItem.WorkDate.Day,
                                        objShift.InTime.Hour,
                                        objShift.InTime.Minute,
                                        objShift.InTime.Second
                                        );

                                    // Giờ kết thúc ca
                                    var outTime = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                       objAttendanceTableItem.WorkDate.Month,
                                       objAttendanceTableItem.WorkDate.Day,
                                       objShift.InTime.Hour,
                                       objShift.InTime.Minute,
                                       objShift.InTime.Second
                                       ).AddHours(objShift.CoOut);

                                    // Xác định khoảng thời gian giao nhau giữa thời gian nghỉ và giờ nghỉ giữa ca
                                    // Nếu có giao dic = true và trả về điểm bắt đầu giao và điểm kết thúc giao
                                    var dic = Common.GetStartEndTimeLine(inTime, outTime, itemOverTime.InTime.Value, itemOverTime.OutTime.Value);
                                    if (dic.ContainsKey(true))
                                    {
                                        // Lấy ra số giờ giao nhau
                                        totalHours = (dic[true].LastOrDefault() - dic[true].FirstOrDefault()).TotalHours;
                                    }

                                    if ((hoursOT - totalHours) >= hoursFrom && (hoursOT - totalHours) <= hoursTo)
                                    {
                                        countOT++;
                                    }

                                }
                            }
                        }

                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, countOT.ToString());
                        }
                        indexRow += 1;
                    }
                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion

            #region tong gio nghi theo loai nghi 96183
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN9_SUM_LEAVEDAY_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN9_SUM_LEAVEDAY_.ToString();
                var strEndWith = "_BYDAY";
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeLeaveDayType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objLeaveDayType = TotalDataAll.listLeavedayType.FirstOrDefault(s => s.Code == codeLeaveDayType);
                    if (objLeaveDayType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumValue = 0;
                            if (objAttendanceTableItem.LeaveTypeID == objLeaveDayType.ID && objAttendanceTableItem.LeaveDays != null)
                            {
                                sumValue += objAttendanceTableItem.LeaveDays.Value;
                            }
                            if (objAttendanceTableItem.ExtraLeaveTypeID == objLeaveDayType.ID && objAttendanceTableItem.ExtraLeaveDays != null)
                            {
                                sumValue += objAttendanceTableItem.ExtraLeaveDays.Value;
                            }
                            if (objAttendanceTableItem.LeaveWorkDayType == objLeaveDayType.ID && objAttendanceTableItem.LeaveWorkDayDays != null)
                            {
                                sumValue += objAttendanceTableItem.LeaveWorkDayDays.Value;
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumValue.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region tong gio tang ca theo loai ot 96518
            //[09/07/2018][bang.nguyen][96518][Modify Func]
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN10_SUM_OVERTIMEHOURS_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN10_SUM_OVERTIMEHOURS_.ToString();
                var strEndWith = "_BYDAY";
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeOverTimeType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objOverTimeType = TotalDataAll.listOvertimeType.FirstOrDefault(s => s.Code == codeOverTimeType);
                    if (objOverTimeType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumOverTimeHour = 0;
                            if (objAttendanceTableItem.OvertimeTypeID == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.OvertimeHours;
                            }
                            if (objAttendanceTableItem.ExtraOvertimeTypeID == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.ExtraOvertimeHours;
                            }
                            if (objAttendanceTableItem.ExtraOvertimeType2ID == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.ExtraOvertimeHours2;
                            }
                            if (objAttendanceTableItem.ExtraOvertimeType3ID == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.ExtraOvertimeHours3;
                            }
                            if (objAttendanceTableItem.ExtraOvertimeType4ID == objOverTimeType.ID && objAttendanceTableItem.ExtraOvertimeHours4 != null)
                            {
                                sumOverTimeHour += objAttendanceTableItem.ExtraOvertimeHours4.Value;
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumOverTimeHour.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region Tung.Tran [16/10/2018][100008][Modify Func] Enum động Tổng ActualHours từng ngày (Att_ProfileTimeSheet.ActualHours theo Cat_JobType.Code) 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN12_SUM_ACTUALHOURS_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN12_SUM_ACTUALHOURS_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeJobType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objJobType = TotalDataAll.listCat_JobType.Where(s => s.Code == codeJobType).FirstOrDefault();
                    if (objJobType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumActualHours = 0;

                            var listTimeSheetByDate = TotalDataAll.ListAtt_ProfileTimeSheet.Where(
                            x => x.ActualHours != null
                            && x.JobTypeID != null
                            && x.WorkDate != null
                            && x.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                            && x.ProfileID == profileItem.ID
                            && x.JobTypeID == objJobType.ID).ToList();

                            if (listTimeSheetByDate != null)
                            {
                                sumActualHours = listTimeSheetByDate.Sum(x => x.ActualHours.Value);
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumActualHours.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region Tung.Tran [20/10/2018][99473][Modify Func] Tổng số tiền phụ cấp từng ngày theo loại phụ cấp: DYN13_UNUSUALALLOWANCE_SUM_AMOUNT_ + "Cat_UnusualAllowanceCfg.Code" + _BYDAY
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN13_UNUSUALALLOWANCE_SUM_AMOUNT_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN13_UNUSUALALLOWANCE_SUM_AMOUNT_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();


                string status = string.Empty;
                dataComputeSer.GetListSalUnusualAllowance(TotalData, CutOffDuration, ref status);
                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.DYN13_UNUSUALALLOWANCE_SUM_AMOUNT_.ToString() + ") ";
                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");
                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;
                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }

                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
                else
                {
                    var listUnusualAllowanceProfile = TotalData.dicSalUnusualAllowance.GetValueOrNew(profileItem.ID);

                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");

                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;

                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                        var unusualAllowanceCfgCode = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                        var objUnusualAllowanceCfg = TotalDataAll.listUnusualAllowanceCfg.FirstOrDefault(s => s.Code == unusualAllowanceCfgCode);

                        if (objUnusualAllowanceCfg != null)
                        {
                            int indexRow = 0;
                            foreach (var objAttendanceTableItem in listAttendanceTableItem)
                            {
                                double sumAmount = 0;
                                var listSalUnusualAllowanceByProfile = listUnusualAllowanceProfile.Where(
                                            x => x.ProfileID == profileItem.ID
                                            && x.IsFollowDay == true
                                            && (x.MonthStart != null && x.MonthStart.Value.Date <= objAttendanceTableItem.WorkDate.Date)
                                            && (x.MonthEnd != null && x.MonthEnd.Value.Date >= objAttendanceTableItem.WorkDate.Date || x.MonthEnd == null)
                                            && x.UnusualEDTypeID == objUnusualAllowanceCfg.ID
                                            ).ToList();

                                if (listSalUnusualAllowanceByProfile != null && listSalUnusualAllowanceByProfile.Any())
                                {
                                    sumAmount = listSalUnusualAllowanceByProfile.Where(x => x.Amount != null).Sum(x => x.Amount.Value);
                                }

                                if (!listValueByDay.ContainsKey(indexRow))
                                {
                                    listValueByDay.Add(indexRow, sumAmount.ToString());
                                }
                                indexRow += 1;
                            }
                        }
                        else
                        {
                            for (int i = 0; i < totalRowInDataSoure; i++)
                            {
                                if (!listValueByDay.ContainsKey(i))
                                {
                                    listValueByDay.Add(i, "0");
                                }
                            }
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
            }
            #endregion

            #region Tung.Tran [05/12/2018][101500] Enum động Số tiền phụ cấp động theo chức vụ 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN16_POSITION_USUALALLOWANCEGROUP_.ToString(), "_BYDAY"))
            {

                //Lấy All dữ liệu danh mục chi tiết thiết bị
                string status = string.Empty;
                var nameTableGetData = "listUsualAllowanceGroup";
                if (!TotalData.dicTableGetDataCategory.ContainsKey(nameTableGetData))
                {
                    TotalData.listUsualAllowanceGroup = dataComputeSer.GetUsualAllowanceGroup(ref status);
                    TotalData.dicTableGetDataCategory.Add(nameTableGetData, "");
                }
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.DYN16_POSITION_USUALALLOWANCEGROUP_.ToString() + ") ";
                }
                else
                {
                    var strStartsWith = PayrollElementByDay.DYN16_POSITION_USUALALLOWANCEGROUP_.ToString();
                    var strEndWith = "_BYDAY";
                    List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");

                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;
                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                        // Lấy ra mã loại phụ cấp cấu hình
                        var unusualAllowanceCode = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                        // Lấy thông tin Loại phụ cấp theo mã
                        var objUnusualAllowance = TotalDataAll.listUsualAllowance.FirstOrDefault(s => s.Code == unusualAllowanceCode);

                        if (objUnusualAllowance != null)
                        {
                            int indexRow = 0;
                            foreach (var objAttendanceTableItem in listAttendanceTableItem)
                            {
                                double sumAmount = 0;

                                // For từng ngày công kiểm tra có chức vụ thì xử lý 
                                if (objAttendanceTableItem != null && !Common.IsNullOrGuidEmpty(objAttendanceTableItem.PositionID))
                                {
                                    var objPosition = TotalDataAll.listPosition.FirstOrDefault(x => x.ID == objAttendanceTableItem.PositionID);
                                    if (objPosition != null && !string.IsNullOrEmpty(objPosition.UsualAllowanceGroupID))
                                    {
                                        //Hien.Le [19/02/2020] 0112318: điều chỉnh một số màn hình bên lương có control nhóm phụ cấp load theo chức vụ
                                        var listUsualAllowanceGroupID = new List<string>();
                                        if (objPosition.UsualAllowanceGroupID.Contains(","))
                                        {
                                            listUsualAllowanceGroupID = objPosition.UsualAllowanceGroupID.Split(",").ToList();
                                        }
                                        else
                                        {
                                            listUsualAllowanceGroupID.Add(objPosition.UsualAllowanceGroupID);
                                        }

                                        foreach (var itemUsualAllowanceGroupID in listUsualAllowanceGroupID)
                                        {
                                            var sGuidUsualAllowanceGroupID = Guid.Parse(itemUsualAllowanceGroupID);

                                            var objUsualAllowanceGroup = TotalData.listUsualAllowanceGroup.Where(
                                            x => x.ID == sGuidUsualAllowanceGroupID
                                            && (
                                            x.AllowanceTypeID1 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID2 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID3 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID4 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID5 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID6 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID7 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID8 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID9 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID10 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID11 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID12 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID13 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID14 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID15 == objUnusualAllowance.ID
                                            )).FirstOrDefault();
                                            if (objUsualAllowanceGroup != null)
                                            {
                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID1)
                                                    && objUsualAllowanceGroup.AllowanceTypeID1 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount1 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount1.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID2)
                                                   && objUsualAllowanceGroup.AllowanceTypeID2 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount2 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount2.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID3)
                                                   && objUsualAllowanceGroup.AllowanceTypeID3 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount3 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount3.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID4)
                                                   && objUsualAllowanceGroup.AllowanceTypeID4 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount4 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount4.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID5)
                                                   && objUsualAllowanceGroup.AllowanceTypeID5 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount5 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount5.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID6)
                                                   && objUsualAllowanceGroup.AllowanceTypeID6 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount6 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount6.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID7)
                                                   && objUsualAllowanceGroup.AllowanceTypeID7 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount7 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount7.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID8)
                                                   && objUsualAllowanceGroup.AllowanceTypeID8 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount8 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount8.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID9)
                                                   && objUsualAllowanceGroup.AllowanceTypeID9 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount9 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount9.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID10)
                                                   && objUsualAllowanceGroup.AllowanceTypeID10 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount10 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount10.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID11)
                                                   && objUsualAllowanceGroup.AllowanceTypeID11 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount11 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount11.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID12)
                                                   && objUsualAllowanceGroup.AllowanceTypeID12 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount12 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount12.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID13)
                                                   && objUsualAllowanceGroup.AllowanceTypeID13 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount13 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount13.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID14)
                                                   && objUsualAllowanceGroup.AllowanceTypeID14 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount14 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount14.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID15)
                                                   && objUsualAllowanceGroup.AllowanceTypeID15 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount15 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount15.Value;
                                                }
                                            }
                                        }
                                    }
                                }

                                if (!listValueByDay.ContainsKey(indexRow))
                                {
                                    listValueByDay.Add(indexRow, sumAmount.ToString());
                                }
                                indexRow += 1;
                            }
                        }
                        else
                        {
                            for (int i = 0; i < totalRowInDataSoure; i++)
                            {
                                if (!listValueByDay.ContainsKey(i))
                                {
                                    listValueByDay.Add(i, "0");
                                }
                            }
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
            }
            #endregion

            #region Tung.Tran [21/12/2018][102060]: Enum ngày nghỉ theo loại ca đêm
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN23_SUMLEAVEDAYNIGHT_.ToString(), "_BYDAY"))
            {
                #region Xử lý
                string colum = PayrollElementByDay.DYN23_SUMLEAVEDAYNIGHT_.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();


                #region Xử lý cắt trả ngày nghỉ
                var listLeaveDayInDate = TotalDataAll.dicLeaveDayNotStatus.GetValueOrNew(profileItem.ID)
                                    .Where(s => s.DateStart <= CutOffDuration.DateEnd
                                        && s.DateEnd >= CutOffDuration.DateStart)
                                    .ToList();

                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                string statusLeaveday = string.Empty;
                if (objAllSetting != null && !string.IsNullOrEmpty(objAllSetting.Value1))
                {
                    statusLeaveday = objAllSetting.Value1;
                    listLeaveDayInDate = listLeaveDayInDate.Where(s => s.Status == statusLeaveday).ToList();
                }

                Att_LeavedayServices leavedayServices = new Att_LeavedayServices();
                var listLeaveDayForDate = new List<Att_LeaveDayEntity>();
                if (listLeaveDayInDate.Count > 0)
                {
                    var listRosterByPro = TotalDataAll.dicRoster.GetValueOrNew(profileItem.ID);
                    listLeaveDayForDate = leavedayServices.SplitLeaveByDayNotGetData(listLeaveDayInDate, ModifyType.E_EDIT.ToString(), listRosterByPro, TotalDataAll.ListRosterGroup.ToList(), TotalDataAll.listCat_Shift.ToList(), new List<Att_RosterGroupByOrganizationEntity>(), new List<Cat_RosterGroupTypeEntity>(), new List<Cat_OrgStructureEntity>(), new Dictionary<Guid, List<Hre_WorkHistoryEntity>>());
                }
                #endregion

                #region Xử lý tính toán phần tử
                var strStartsWith = PayrollElementByDay.DYN23_SUMLEAVEDAYNIGHT_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;
                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    // Lấy ra mã loại phụ cấp cấu hình
                    var lLeavedayTypeCode = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    // Lấy thông tin Loại phụ cấp theo mã
                    var objLeavedayType = TotalDataAll.listLeavedayType.Where(s => s.Code == lLeavedayTypeCode).FirstOrDefault();
                    if (objLeavedayType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            // Số giờ nghỉ trong 1 ngày đang tính
                            double totalHoursLeave = 0;

                            // Lấy danh sách ngày nghỉ thuộc ngày đang xét
                            var listLeaveDayByWorkDate = listLeaveDayForDate
                                .Where(s => s.DateStart.Date == objAttendanceTableItem.WorkDate
                                        && s.ProfileID == profileItem.ID
                                        && s.DurationType != LeaveDayDurationType.E_OUT_OF_SHIFT.ToString()
                                        && s.LeaveDayTypeID == objLeavedayType.ID)
                                .OrderBy(s => s.DateStart)
                                .ToList();

                            if (listLeaveDayByWorkDate != null && listLeaveDayByWorkDate.Count > 0)
                            {
                                // For qua từng dòng nghỉ
                                foreach (var itemLeaveDayByWorkDate in listLeaveDayByWorkDate)
                                {
                                    if (!Common.IsNullOrGuidEmpty(itemLeaveDayByWorkDate.ShiftID))
                                    {
                                        // Giờ bắt đầu nghỉ giao với ca đêm
                                        var nightTimeOffStart = DateTime.MinValue;

                                        // Giờ kết thúc nghỉ giao với ca đêm
                                        var nightTimeOffEnd = DateTime.MinValue;

                                        // Khoảng thời gian giao nhau giữa thời gian nghỉ và giờ nghỉ giữa ca
                                        double hoursCoBreakInOut = 0;

                                        // Lấy ca làm việc của dòng đăng ký nghỉ
                                        var objShift = TotalDataAll.listCat_Shift.Where(s => s.ID == itemLeaveDayByWorkDate.ShiftID).FirstOrDefault();
                                        if (objShift != null && objShift.NightTimeStart != null && objShift.NightTimeEnd != null)
                                        {
                                            #region Xác định giờ bắt đầu -> Giờ kết thúc của ca
                                            // Xác định giờ bắt đầu của ca 
                                            DateTime inTimeByShift = new DateTime(
                                                        objAttendanceTableItem.WorkDate.Year,
                                                        objAttendanceTableItem.WorkDate.Month,
                                                        objAttendanceTableItem.WorkDate.Day,
                                                        objShift.InTime.Hour,
                                                        objShift.InTime.Minute,
                                                        objShift.InTime.Second
                                                    );
                                            // Xác định giờ kết thúc của ca
                                            DateTime outTimeByShift = inTimeByShift.AddHours(objShift.CoOut);
                                            #endregion

                                            #region Xác định giờ bắt đầu ca đêm -> giờ kết thúc ca đêm
                                            //gio bat dat va kết thúc ca đêm thực tế
                                            DateTime inTimenightReal = new DateTime(
                                                 objAttendanceTableItem.WorkDate.Year,
                                                 objAttendanceTableItem.WorkDate.Month,
                                                 objAttendanceTableItem.WorkDate.Day,
                                                 objShift.NightTimeStart.Value.Hour,
                                                 objShift.NightTimeStart.Value.Minute,
                                                 objShift.NightTimeStart.Value.Second
                                                 );

                                            DateTime outTimenightReal = new DateTime(
                                                objAttendanceTableItem.WorkDate.Year,
                                                objAttendanceTableItem.WorkDate.Month,
                                                objAttendanceTableItem.WorkDate.Day,
                                                objShift.NightTimeEnd.Value.Hour,
                                                objShift.NightTimeEnd.Value.Minute,
                                                objShift.NightTimeEnd.Value.Second
                                                );

                                            //neu gio ket thuc ca đêm < giờ bắt đầu ca đêm => +1 ngày
                                            if (outTimenightReal < inTimenightReal)
                                            {
                                                outTimenightReal = outTimenightReal.AddDays(1);
                                            }
                                            #endregion

                                            #region xac dinh gio nghi
                                            // Giờ bắt đầu nghỉ
                                            DateTime dateStartLeave = itemLeaveDayByWorkDate.DateStart;
                                            // Giờ kết thúc nghỉ
                                            DateTime dateEndLeave = itemLeaveDayByWorkDate.DateEnd;

                                            if (itemLeaveDayByWorkDate.DurationType == LeaveDayDurationType.E_FULLSHIFT.ToString())
                                            {
                                                //gio bat dau nghi và giờ kết
                                                dateStartLeave = inTimeByShift;
                                                dateEndLeave = outTimeByShift;
                                            }
                                            else
                                            {
                                                // Nếu DateStart ngày nghỉ nằm ngoài in out của ca => + thêm 1 ngày 
                                                if (objShift.IsNightShift)
                                                {
                                                    if (dateStartLeave < inTimeByShift || dateStartLeave > outTimeByShift)
                                                    {
                                                        dateStartLeave = dateStartLeave.AddDays(1);
                                                    }
                                                    // Nếu DateEnd  ngày nghỉ nằm ngoài in out của ca => + thêm 1 ngày 
                                                    if (dateEndLeave < inTimeByShift || dateEndLeave > outTimeByShift)
                                                    {
                                                        dateEndLeave = dateEndLeave.AddDays(1);
                                                    }
                                                }
                                            }
                                            #endregion

                                            #region giao giữa giờ nghỉ và khung giờ ca đêm
                                            var dicStartEndTimeOff = Common.GetStartEndTimeLine(dateStartLeave, dateEndLeave, inTimenightReal, outTimenightReal);
                                            if (dicStartEndTimeOff.ContainsKey(true))
                                            {
                                                nightTimeOffStart = dicStartEndTimeOff[true].FirstOrDefault();
                                                nightTimeOffEnd = dicStartEndTimeOff[true].LastOrDefault();
                                            }
                                            #endregion

                                            #region Xác định giờ bắt đầu nghỉ giữa ca -> Giờ kết thúc nghỉ giữa ca
                                            DateTime startCoBreakIn = inTimeByShift.AddHours(objShift.CoBreakIn);
                                            DateTime startCoBreakOut = inTimeByShift.AddHours(objShift.CoBreakOut);
                                            #endregion

                                            #region Tính toán số giờ giao nhau giữa giờ ca đêm và giờ nghỉ giữa ca (hoursCoBreakInOut)
                                            // Xác định khoảng thời gian giao nhau giữa thời gian nghỉ và giờ nghỉ giữa ca
                                            // Nếu có giao dic = true và trả về điểm bắt đầu giao và điểm kết thúc giao
                                            var dicCoBreakInOut = Common.GetStartEndTimeLine(inTimenightReal, outTimenightReal, startCoBreakIn, startCoBreakOut);
                                            if (dicCoBreakInOut.ContainsKey(true))
                                            {
                                                hoursCoBreakInOut = (dicCoBreakInOut[true].LastOrDefault() - dicCoBreakInOut[true].FirstOrDefault()).TotalHours;
                                            }
                                            #endregion
                                        }

                                        #region Tính toán số giờ nghỉ
                                        // (Giờ kết thúc nghỉ - Giờ bắt đầu nghỉ) - hoursCoBreakInOut
                                        if (nightTimeOffEnd != DateTime.MinValue && nightTimeOffStart != DateTime.MinValue)
                                        {
                                            totalHoursLeave = (nightTimeOffEnd - nightTimeOffStart).TotalHours - hoursCoBreakInOut;
                                        }
                                        #endregion
                                    }
                                }
                            }

                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, totalHoursLeave.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
                #endregion

                #endregion
            }

            #endregion

            #region Tung.Tran [21/12/2018][102060]: Enum ngày nghỉ theo loại ca ngày
            // khung gio ca ngày được xác đinh = khung giờ của ca - khung giờ ca đêm nếu có
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN24_SUMLEAVEDAYDAY_.ToString(), "_BYDAY"))
            {
                #region Xử lý

                string colum = PayrollElementByDay.DYN24_SUMLEAVEDAYDAY_.ToString();
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                #region Xử lý cắt trả ngày nghỉ
                var listLeaveDayInDate = TotalDataAll.dicLeaveDayNotStatus.GetValueOrNew(profileItem.ID)
                                    .Where(s => s.DateStart <= CutOffDuration.DateEnd
                                        && s.DateEnd >= CutOffDuration.DateStart)
                                    .ToList();

                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                string statusLeaveday = string.Empty;
                if (objAllSetting != null && !string.IsNullOrEmpty(objAllSetting.Value1))
                {
                    statusLeaveday = objAllSetting.Value1;
                    listLeaveDayInDate = listLeaveDayInDate.Where(s => s.Status == statusLeaveday).ToList();
                }

                Att_LeavedayServices leavedayServices = new Att_LeavedayServices();
                var listLeaveDayForDate = new List<Att_LeaveDayEntity>();
                if (listLeaveDayInDate.Count > 0)
                {
                    var listRosterByPro = TotalDataAll.dicRoster.GetValueOrNew(profileItem.ID);
                    listLeaveDayForDate = leavedayServices.SplitLeaveByDayNotGetData(listLeaveDayInDate, ModifyType.E_EDIT.ToString(), listRosterByPro, TotalDataAll.ListRosterGroup.ToList(), TotalDataAll.listCat_Shift.ToList(), new List<Att_RosterGroupByOrganizationEntity>(), new List<Cat_RosterGroupTypeEntity>(), new List<Cat_OrgStructureEntity>(), new Dictionary<Guid, List<Hre_WorkHistoryEntity>>());
                }
                #endregion

                #region Xử lý tính toán phần tử
                var strStartsWith = PayrollElementByDay.DYN24_SUMLEAVEDAYDAY_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;
                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    // Lấy ra mã loại phụ cấp cấu hình
                    var lLeavedayTypeCode = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    // Lấy thông tin Loại phụ cấp theo mã
                    var objLeavedayType = TotalDataAll.listLeavedayType.Where(s => s.Code == lLeavedayTypeCode).FirstOrDefault();
                    if (objLeavedayType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            // Số giờ nghỉ trong 1 ngày đang tính
                            double totalHoursLeave = 0;

                            // Lấy danh sách ngày nghỉ thuộc ngày đang xét
                            var listLeaveDayByWorkDate = listLeaveDayForDate
                                .Where(s => s.DateStart.Date == objAttendanceTableItem.WorkDate
                                        && s.ProfileID == profileItem.ID
                                        && s.DurationType != LeaveDayDurationType.E_OUT_OF_SHIFT.ToString()
                                        && s.LeaveDayTypeID == objLeavedayType.ID)
                                .OrderBy(s => s.DateStart)
                                .ToList();

                            if (listLeaveDayByWorkDate != null && listLeaveDayByWorkDate.Count > 0)
                            {
                                // For qua từng dòng nghỉ
                                foreach (var itemLeaveDayByWorkDate in listLeaveDayByWorkDate)
                                {
                                    if (!Common.IsNullOrGuidEmpty(itemLeaveDayByWorkDate.ShiftID))
                                    {
                                        //gio bat dau nghi sau khi đã xét giao
                                        var dayTimeOffStart = DateTime.MinValue;

                                        // Giờ kết thúc nghỉ sau khi đã xet giao
                                        var dayTimeOffEnd = DateTime.MinValue;

                                        // Khoảng thời gian giao nhau giữa thời gian nghỉ và giờ nghỉ giữa ca
                                        double hoursCoBreakInOut = 0;

                                        // Lấy ca làm việc của dòng đăng ký nghỉ
                                        var objShift = TotalDataAll.listCat_Shift.Where(s => s.ID == itemLeaveDayByWorkDate.ShiftID).FirstOrDefault();
                                        if (objShift != null)
                                        {
                                            #region Giờ bắt đầu và kết thúc của ca
                                            // Xác định giờ bắt đầu của ca
                                            DateTime inTimeByShift = new DateTime(
                                                        objAttendanceTableItem.WorkDate.Year,
                                                        objAttendanceTableItem.WorkDate.Month,
                                                        objAttendanceTableItem.WorkDate.Day,
                                                        objShift.InTime.Hour,
                                                        objShift.InTime.Minute,
                                                        objShift.InTime.Second
                                                    );
                                            // Xác định giờ kết thúc của ca
                                            DateTime outTimeByShift = inTimeByShift.AddHours(objShift.CoOut);
                                            #endregion

                                            #region Xác định giờ bắt đầu -> Giờ kết thúc của ca ngày thực tế
                                            //Gio bat dau ca ngày thực tế
                                            DateTime inTimeReal = inTimeByShift;
                                            DateTime outTimeReal = outTimeByShift;

                                            //truong hop không có khung giờ ca ngày => thì giờ nghỉ ca ngày của dong =0
                                            if (objShift.NightTimeStart != null)
                                            {
                                                //xac dinh gio bắt đầu khung gio ca dem
                                                DateTime nightTimeStart = new DateTime(
                                                           objAttendanceTableItem.WorkDate.Year,
                                                           objAttendanceTableItem.WorkDate.Month,
                                                           objAttendanceTableItem.WorkDate.Day,
                                                           objShift.NightTimeStart.Value.Hour,
                                                           objShift.NightTimeStart.Value.Minute,
                                                           objShift.NightTimeStart.Value.Second
                                                       );
                                                if (inTimeByShift >= nightTimeStart)
                                                {
                                                    continue;
                                                }
                                                //xác định giờ kết thúc thực tế ca ngày
                                                // Nếu trường hợp ca ngày ca có cả ngày lẫn đêm
                                                // VD: Ca từ 20h > 4h sáng (Bắt đầu ca đêm là 22h) => Ca ngày từ 20h > 22h
                                                if (outTimeReal > nightTimeStart)
                                                {
                                                    outTimeReal = nightTimeStart;
                                                }
                                            }
                                            #endregion

                                            #region Xác định chính xác thời gian nghỉ
                                            // Giờ bắt đầu nghỉ
                                            DateTime dateStartLeave = itemLeaveDayByWorkDate.DateStart;
                                            // Giờ kết thúc nghỉ
                                            DateTime dateEndLeave = itemLeaveDayByWorkDate.DateEnd;

                                            // Trường hợp nghỉ full ca
                                            //==> gio nghi = gio in va out thuc te cua ca
                                            if (itemLeaveDayByWorkDate.DurationType == LeaveDayDurationType.E_FULLSHIFT.ToString())
                                            {
                                                dateStartLeave = inTimeByShift;
                                                dateEndLeave = outTimeByShift;
                                            }
                                            else
                                            {
                                                // Nếu DateStart ngày nghỉ nằm ngoài in out của ca => + thêm 1 ngày 
                                                if (objShift.IsNightShift)
                                                {
                                                    if (dateStartLeave < inTimeByShift || dateStartLeave > outTimeByShift)
                                                    {
                                                        dateStartLeave = dateStartLeave.AddDays(1);
                                                    }
                                                    // Nếu DateEnd  ngày nghỉ nằm ngoài in out của ca => + thêm 1 ngày 
                                                    if (dateEndLeave < inTimeByShift || dateEndLeave > outTimeByShift)
                                                    {
                                                        dateEndLeave = dateEndLeave.AddDays(1);
                                                    }
                                                }
                                            }
                                            #endregion

                                            #region xác định giao giữa giờ nghỉ và khung giờ ca ngày
                                            var dicStartEndTimeOff = Common.GetStartEndTimeLine(dateStartLeave, dateEndLeave, inTimeReal, outTimeReal);
                                            if (dicStartEndTimeOff.ContainsKey(true))
                                            {
                                                // Thời gian bắt đầu nghỉ
                                                dayTimeOffStart = dicStartEndTimeOff[true].FirstOrDefault();
                                                // Thời gian kết thúc nghỉ
                                                dayTimeOffEnd = dicStartEndTimeOff[true].LastOrDefault();
                                            }
                                            #endregion

                                            #region Xác định giờ bắt đầu nghỉ giữa ca -> Giờ kết thúc nghỉ giữa ca
                                            DateTime startCoBreakIn = inTimeByShift.AddHours(objShift.CoBreakIn);
                                            DateTime startCoBreakOut = inTimeByShift.AddHours(objShift.CoBreakOut);
                                            #endregion

                                            #region Tính toán số giờ giao nhau giữa giờ đăng ký nghỉ và giờ nghỉ giữa ca (hoursCoBreakInOut)
                                            // Xác định khoảng thời gian giao nhau giữa giờ đăng ký nghỉ và giờ nghỉ giữa ca
                                            // Nếu có giao dic = true và trả về điểm bắt đầu giao và điểm kết thúc giao
                                            var dicCoBreakInOut = Common.GetStartEndTimeLine(dayTimeOffStart, dayTimeOffEnd, startCoBreakIn, startCoBreakOut);
                                            if (dicCoBreakInOut.ContainsKey(true))
                                            {
                                                hoursCoBreakInOut = (dicCoBreakInOut[true].LastOrDefault() - dicCoBreakInOut[true].FirstOrDefault()).TotalHours;
                                            }
                                            #endregion
                                        }

                                        #region Tính toán số giờ nghỉ
                                        // (Giờ kết thúc nghỉ - Giờ bắt đầu nghỉ) - hoursCoBreakInOut
                                        if (dayTimeOffEnd != DateTime.MinValue && dayTimeOffStart != DateTime.MinValue)
                                        {
                                            totalHoursLeave = (dayTimeOffEnd - dayTimeOffStart).TotalHours - hoursCoBreakInOut;
                                        }
                                        #endregion
                                    }
                                }
                            }

                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, totalHoursLeave.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
                #endregion

                #endregion
            }

            #endregion

            #region Tung.Tran [10/04/2019][0103856]: Thêm phần tử lương ngày: số giờ tăng ca theo loại công việc	
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay,
                ref formula,
                PayrollElementByDay.DYN34_SUM_ATT_OVERTIME_HOURS_.ToString(),
                "_BYDAY"))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }

                var strStartsWith = PayrollElementByDay.DYN34_SUM_ATT_OVERTIME_HOURS_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var itemFormula in ListFormula)
                {
                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = itemFormula;
                    objColumn.ValueType = strDouble;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();


                    var codeJobType = itemFormula.Replace(PayrollElementByDay.DYN34_SUM_ATT_OVERTIME_HOURS_.ToString(), "").Replace("_BYDAY", "");
                    var objJobType = TotalDataAll.listCat_JobType.FirstOrDefault(x => x.Code == codeJobType);
                    if (objJobType != null)
                    {
                        int indexRow = 0;
                        //gán dữ liệu cho từng ngày cho các enum
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumHoursOT = 0;

                            var listOverTimeByProfile = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID).Where(
                                x => x.WorkDateRoot != null
                                && x.JobTypeID != null
                                && x.JobTypeID == objJobType.ID
                                && x.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date
                                && strOTStatus == x.Status
                                ).ToList();

                            if (listOverTimeByProfile != null && listOverTimeByProfile.Count > 0)
                            {
                                sumHoursOT += listOverTimeByProfile.Where(x =>
                                            x.ApproveHours != null
                                             && x.Status == EnumDropDown.OverTimeStatus.E_APPROVED.ToString())
                                            .Sum(x => x.ApproveHours.Value);
                                sumHoursOT += listOverTimeByProfile.Where(x =>
                                            x.Status == EnumDropDown.OverTimeStatus.E_CONFIRM.ToString())
                                            .Sum(x => x.ConfirmHours);
                                sumHoursOT += listOverTimeByProfile.Where(x =>
                                            (x.Status != EnumDropDown.OverTimeStatus.E_APPROVED.ToString() && x.Status != EnumDropDown.OverTimeStatus.E_CONFIRM.ToString()))
                                            .Sum(x => x.RegisterHours);
                            }
                            if (!listValue.ContainsKey(indexRow))
                            {
                                listValue.Add(indexRow, sumHoursOT.ToString());
                            }
                            indexRow += 1;
                        }
                    }

                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion

            #region Tung.Tran [17/04/2019][0104582]: Thêm phần tử lương ngày: Đếm những lần tăng ca theo mã ca truyền vào + có số giờ đăng ký > số giờ truyền vào
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay,
                ref formula,
                PayrollElementByDay.DYN35_COUNT_ATT_OVERTIME_.ToString(),
                "_BYDAY"))
            {

                var strStartsWith = PayrollElementByDay.DYN35_COUNT_ATT_OVERTIME_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                var lisOverTimeByProfileDic = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);

                foreach (var itemFormula in ListFormula)
                {
                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = itemFormula;
                    objColumn.ValueType = strDouble;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();

                    double hours = 0;

                    // Chuỗi chứa mã ca cấu hình + số giờ cấu hình
                    var strShiftAndHours = itemFormula.Replace(PayrollElementByDay.DYN35_COUNT_ATT_OVERTIME_.ToString(), "").Replace("_BYDAY", "");
                    // Tách lấy số giờ cấu hình
                    var hoursConfig = strShiftAndHours.Substring(strShiftAndHours.LastIndexOf("_") + 1, strShiftAndHours.Length - (strShiftAndHours.LastIndexOf("_") + 1));

                    // Tách lấy mã ca cấu hình
                    var codeShift = strShiftAndHours.Substring(0, strShiftAndHours.LastIndexOf("_"));
                    // Lấy ca 
                    var objShiftByCode = TotalDataAll.listCat_Shift.Where(s => s.Code == codeShift).FirstOrDefault();

                    if (objShiftByCode != null && double.TryParse(hoursConfig, out hours))
                    {

                        int indexRow = 0;
                        //gán dữ liệu cho từng ngày cho các enum
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            int countHoursOT = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID).Where(
                                x => x.WorkDateRoot != null
                                && x.OutTime != null
                                && x.InTime != null
                                && x.ShiftID == objShiftByCode.ID
                                && x.ProfileID == profileItem.ID
                                && x.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date
                                && (x.OutTime.Value - x.InTime.Value).TotalHours >= hours
                                ).Count();

                            if (!listValue.ContainsKey(indexRow))
                            {
                                listValue.Add(indexRow, countHoursOT.ToString());
                            }
                            indexRow += 1;
                        }
                    }

                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion

            #region Tung.Tran [10/04/2019][0103856]: Thêm phần tử lương ngày: Sum BreakConfirmHours theo loại tăng ca
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay,
                ref formula,
                PayrollElementByDay.DYN64_SUM_OVERTIME_BY_.ToString(),
                "_BYDAY"))
            {
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }
                var strStartsWith = PayrollElementByDay.DYN64_SUM_OVERTIME_BY_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var itemFormula in ListFormula)
                {
                    ColumnByDay objColumn = new ColumnByDay();
                    objColumn.ColumnName = itemFormula;
                    objColumn.ValueType = strDouble;
                    Dictionary<int, string> listValue = new Dictionary<int, string>();
                    var codeOvertimeType = itemFormula.Replace(PayrollElementByDay.DYN64_SUM_OVERTIME_BY_.ToString(), "").Replace("_BYDAY", "");
                    var objOvertimeType = TotalDataAll.listOvertimeType.FirstOrDefault(x => x.Code == codeOvertimeType);
                    if (objOvertimeType != null)
                    {
                        int indexRow = 0;
                        //gán dữ liệu cho từng ngày cho các enum
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumValue = 0;
                            var listOverTimeByProfile = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID).Where(
                                x => x.WorkDateRoot != null
                                && x.OvertimeTypeID != null
                                && x.OvertimeTypeID == objOvertimeType.ID
                                && x.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date
                                && strOTStatus == x.Status
                                ).ToList();

                            if (listOverTimeByProfile != null && listOverTimeByProfile.Count > 0)
                            {
                                sumValue += listOverTimeByProfile.Where(x => x.BreakConfirmHours != null).Sum(x => x.BreakConfirmHours.Value);
                            }
                            if (!listValue.ContainsKey(indexRow))
                            {
                                listValue.Add(indexRow, sumValue.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    objColumn.ListValueByDay = listValue;
                    listColumnByDay.Add(objColumn);
                }
            }
            #endregion

            #region Hien.Le [13/02/2020] 0112114: Thêm Enum phần tử lương ngày lấy số giờ công/Tăng ca điều chuyển Theo loại
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN43_SUM_ACTUALHOURS_PROFILETIMESHEET_.ToString(),
              "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN43_SUM_ACTUALHOURS_PROFILETIMESHEET_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var payrollFormTransfer = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");

                    int indexRow = 0;
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        double sumActualHours = 0;
                        var listAttProfileTimeSheet = TotalDataAll.dicAtt_ProfileTimeSheet.GetValueOrNew(profileItem.ID);
                        var listTimeSheetByDate = listAttProfileTimeSheet.Where(
                        x => x.ActualHours != null
                        && x.WorkDate != null
                        && x.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                        && x.PayrollFormTransfer == payrollFormTransfer).ToList();

                        if (listTimeSheetByDate != null)
                        {
                            sumActualHours = listTimeSheetByDate.Sum(x => x.ActualHours.Value);
                        }
                        if (!listValueByDay.ContainsKey(indexRow))
                        {
                            listValueByDay.Add(indexRow, sumActualHours.ToString());
                        }
                        indexRow += 1;
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region Hien.Le [13/02/2020] 0112114: Thêm Enum phần tử lương ngày lấy số giờ công/Tăng ca điều chuyển Theo loại
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN44_SUM_OT_PROFILETIMESHEET_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN44_SUM_OT_PROFILETIMESHEET_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var strPayrollFormTransfer_OvertimeType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var payrollFormTransfer = strPayrollFormTransfer_OvertimeType.Split("_AND_").FirstOrDefault();
                    var overtimeType = strPayrollFormTransfer_OvertimeType.Split("_AND_").LastOrDefault();

                    int indexRow = 0;
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        double sumOvertimeHours = 0;
                        double? overtimeHours1 = 0;
                        double? overtimeHours2 = 0;
                        double? overtimeHours3 = 0;

                        var listAttProfileTimeSheet = TotalDataAll.dicAtt_ProfileTimeSheet.GetValueOrNew(profileItem.ID);

                        var listTimeSheetByDate = listAttProfileTimeSheet.Where(
                        x => x.ActualHours != null
                        && x.WorkDate != null
                        && x.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                        && x.PayrollFormTransfer == payrollFormTransfer).ToList();

                        var objOvertimeType = TotalDataAll.listOvertimeTypeAll.Where(p => p.Code == overtimeType).FirstOrDefault();

                        if (objOvertimeType != null)
                        {
                            overtimeHours1 = listTimeSheetByDate.Where(p => p.OvertimeTypeID1 == objOvertimeType.ID && p.OvertimeHours1 != null).Sum(p => p.OvertimeHours1);

                            overtimeHours2 = listTimeSheetByDate.Where(p => p.OvertimeTypeID2 == objOvertimeType.ID && p.OvertimeHours2 != null).Sum(p => p.OvertimeHours2);

                            overtimeHours3 = listTimeSheetByDate.Where(p => p.OvertimeTypeID3 == objOvertimeType.ID && p.OvertimeHours3 != null).Sum(p => p.OvertimeHours3);

                            sumOvertimeHours = overtimeHours1.Value + overtimeHours2.Value + overtimeHours3.Value;
                        }
                        if (!listValueByDay.ContainsKey(indexRow))
                        {
                            listValueByDay.Add(indexRow, sumOvertimeHours.ToString());
                        }
                        indexRow += 1;
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region Hien.Le [02/03/2020] [0113046] [New Func] Thêm phần tử lương ngày Lấy số lần khen thưởng theo từng mã loại khen thưởng
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN45_HRE_REWARD_REWARDEDTYPE_CODE_.ToString(), "_BYDAY"))
            {
                string status = string.Empty;
                //Lấy danh sách khen thưởng theo nhân viên
                dataComputeSer.GetDicReward(TotalData, CutOffDuration, ref status);
                //Lấy All dữ liệu danh mục loại khen thưởng
                var nameTableGetData = "listCatRewardedType";
                if (!TotalDataAll.dicTableGetDataCategory.ContainsKey(nameTableGetData))
                {
                    TotalDataAll.listRewardedType = dataComputeSer.GetListRewardedType(ref status);
                    TotalDataAll.dicTableGetDataCategory.Add(nameTableGetData, "");
                }
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.DYN45_HRE_REWARD_REWARDEDTYPE_CODE_.ToString() + ") ";
                    item = new ElementFormula(PayrollElementByDay.DYN45_HRE_REWARD_REWARDEDTYPE_CODE_.ToString(), 0, 0);
                    listElementFormulaByDay.Add(item);
                }
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.DYN45_HRE_REWARD_REWARDEDTYPE_CODE_.ToString() + ") ";
                }
                else
                {
                    var strStartsWith = PayrollElementByDay.DYN45_HRE_REWARD_REWARDEDTYPE_CODE_.ToString();
                    var strEndWith = "_BYDAY";

                    List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");

                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;

                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                        var rewardedTypeCode = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");

                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            var objCatRewardedType = TotalDataAll.listRewardedType.Where(p => p.Code == rewardedTypeCode).FirstOrDefault();

                            int IsExistsHreReward = 0;
                            if (objCatRewardedType != null)
                            {
                                var objHreReward = TotalData.dicReward.GetValueOrNew(profileItem.ID)
                                    .FirstOrDefault(p => p.DateOfEffective == objAttendanceTableItem.WorkDate
                                    && p.RewardedTypeID == objCatRewardedType.ID
                                    && p.Status == EnumDropDown.Status.E_APPROVED.ToString());

                                if (objHreReward != null)
                                {
                                    IsExistsHreReward = 1;
                                }
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, IsExistsHreReward.ToString());
                            }
                            indexRow += 1;
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
            }
            #endregion

            #region Hien.Le [02/03/2020] [0113045]: Thêm phần tử lương ngày Lấy số lần kỷ luật theo từng mã lý do kỷ luật
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN46_HRE_DISCIPLINE_DISCIPLINE_REASON_.ToString(), "_BYDAY"))
            {
                string status = string.Empty;
                dataComputeSer.GetListDiscipline(TotalData, CutOffDuration, ref status);
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.DYN46_HRE_DISCIPLINE_DISCIPLINE_REASON_.ToString() + ") ";
                    item = new ElementFormula(PayrollElementByDay.DYN46_HRE_DISCIPLINE_DISCIPLINE_REASON_.ToString(), 0, 0);
                    listElementFormulaByDay.Add(item);
                }
                else
                {
                    var strStartsWith = PayrollElementByDay.DYN46_HRE_DISCIPLINE_DISCIPLINE_REASON_.ToString();
                    var strEndWith = "_BYDAY";

                    List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");

                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;

                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                        var disciplineResonCode = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");

                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            var objCatNameEntity = TotalDataAll.ListCat_NameEntity.Where(p => p.Code == disciplineResonCode && p.NameEntityType == EnumDropDown.EntityType.E_DISCIPLINE_REASON.ToString()).FirstOrDefault();

                            int IsExistsHreDiscipline = 0;
                            if (objCatNameEntity != null)
                            {
                                var listDiscipline = TotalData.dicDiscipline.GetValueOrNew(profileItem.ID);
                                var objHreDiscipline = listDiscipline.FirstOrDefault(p => p.DateOfEffective <= objAttendanceTableItem.WorkDate
                                && p.DateEndOfViolation >= objAttendanceTableItem.WorkDate
                                && p.DisciplineResonID == objCatNameEntity.ID
                                && p.ApproveStatus == EnumDropDown.Status.E_APPROVED.ToString());

                                if (objHreDiscipline != null)
                                {
                                    IsExistsHreDiscipline = 1;
                                }
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, IsExistsHreDiscipline.ToString());
                            }
                            indexRow += 1;
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
            }
            #endregion

            #region Hien.Le [23/04/2020][114539][Modify Func] [Skypec] Thêm phần tử lương lấy dữ liệu công (Phần tử lương)
            //Enum động Tổng ActualHours từng ngày (Att_ProfileTimeSheet.ActualHours theo Cat_Shift.Code) 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN47_SUM_ACTUALHOURS_ATT_PROFILETIMESHEET_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN47_SUM_ACTUALHOURS_ATT_PROFILETIMESHEET_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeCatShift = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objCatShift = TotalDataAll.listCat_Shift.Where(s => s.Code == codeCatShift).FirstOrDefault();
                    if (objCatShift != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumActualHours = 0;

                            var listTimeSheetByDate = TotalDataAll.ListAtt_ProfileTimeSheet.Where(
                            x => x.ActualHours != null
                            && x.ShiftID != null
                            && x.WorkDate != null
                            && x.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                            && x.ProfileID == profileItem.ID
                            && x.ShiftID == objCatShift.ID).ToList();

                            if (listTimeSheetByDate.Count > 0)
                            {
                                sumActualHours = listTimeSheetByDate.Sum(x => x.ActualHours.Value);
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumActualHours.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            //Enum động Taget từng ngày (RevenueForProfile.Taget theo RevenueForProfile.type) 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN65_SAL_REVENUEFORPROFILE_TARGET_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN65_SAL_REVENUEFORPROFILE_TARGET_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                    var type = formulaitem.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objRevenueForProfile = TotalDataAll.listRevenueForProfile.Where(s => s.ProfileID == profileItem.ID && s.Type == type).ToList();

                    if (objRevenueForProfile != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double? valueTaget = 0;
                            foreach (var reVenueTaget in objRevenueForProfile)
                            {

                                if (reVenueTaget.DateFrom != null && reVenueTaget.DateFrom.Value <= objAttendanceTableItem.WorkDate
                                        && reVenueTaget.DateTo != null && reVenueTaget.DateTo.Value >= objAttendanceTableItem.WorkDate)
                                {
                                    valueTaget = reVenueTaget.Target;
                                }

                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, valueTaget.ToString());
                            }
                            indexRow += 1;
                        }

                    }

                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            //Enum động ACTUAL từng ngày (RevenueForProfile.ACTUAL theo RevenueForProfile.type) 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN66_SAL_REVENUEFORPROFILE_ACTUALLY_ACHIEVED_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN66_SAL_REVENUEFORPROFILE_ACTUALLY_ACHIEVED_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var type = formulaitem.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");

                    var objRevenueForProfile = TotalDataAll.listRevenueForProfile.Where(s => s.ProfileID == profileItem.ID && s.Type == type).ToList();

                    if (objRevenueForProfile != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double? valueActual = 0;

                            foreach (var revenueActual in objRevenueForProfile)
                            {

                                if (revenueActual.DateFrom != null
                                    && revenueActual.DateFrom.Value <= objAttendanceTableItem.WorkDate
                                        && revenueActual.DateTo != null
                                        && revenueActual.DateTo.Value >= objAttendanceTableItem.WorkDate)
                                {
                                    valueActual = revenueActual.Actual;
                                }

                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, valueActual.ToString());
                            }
                            indexRow += 1;

                        }

                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN48_SUM_WORKHOURS_ATT_PROFILETIMESHEET_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN48_SUM_WORKHOURS_ATT_PROFILETIMESHEET_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeCatShift = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objCatShift = TotalDataAll.listCat_Shift.Where(s => s.Code == codeCatShift).FirstOrDefault();
                    if (objCatShift != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumWorkHours = 0;

                            var listTimeSheetByDate = TotalDataAll.ListAtt_ProfileTimeSheet.Where(
                            x => x.ShiftID != null
                            && x.WorkDate != null
                            && x.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                            && x.ProfileID == profileItem.ID
                            && x.ShiftID == objCatShift.ID).ToList();

                            if (listTimeSheetByDate.Count > 0)
                            {
                                var listShiftID = listTimeSheetByDate.Select(p => p.ShiftID).ToList();
                                sumWorkHours = TotalDataAll.listCat_Shift.Where(p => p.WorkHours != null && listShiftID.Contains(p.ID)).ToList().Sum(p => p.WorkHours.Value);
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumWorkHours.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region Hien.Le [12/08/2020] [117800] : Thêm enum phần tử lương Kiểm tra dòng OT có check 'Đăng ký ăn' - Phần tử ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN49_COUNT_ATT_OVERTIME_ISMEALREGISTRATION_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN49_COUNT_ATT_OVERTIME_ISMEALREGISTRATION_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                #region Trạng thái theo cấu hình "Giờ tăng ca được tính ở trạng thái" 
                var statusOT = EnumDropDown.OverTimeStatus.E_APPROVED.ToString();
                var objSysAllSetting = TotalDataAll.listAllSettingEntity.FirstOrDefault(p => p.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString());
                if (objSysAllSetting != null)
                {
                    statusOT = objSysAllSetting.Value1;
                }
                #endregion

                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeOvertimeType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objCatOvertimeType = TotalDataAll.listOvertimeTypeAll.Where(s => s.Code == codeOvertimeType).FirstOrDefault();
                    if (objCatOvertimeType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double countAttOvertime = 0;

                            var listOvertime = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID)
                                .Where(x => x.Status == statusOT
                                 && x.OvertimeTypeID == objCatOvertimeType.ID
                                 && x.IsMealRegistration == true
                                 && x.WorkDateRoot != null && x.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date).ToList();

                            if (listOvertime.Count > 0)
                            {
                                countAttOvertime = listOvertime.Count();
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, countAttOvertime.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region Hien.Le [15/08/2020] [0118691]: [IRV] Modify thêm phần tử tính lương sản phẩm theo ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN50_SAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_.ToString(), "_BYDAY"))
            {
                string status = string.Empty;
                dataComputeSer.GetdicSalProductSalaryOverOffset(TotalData, CutOffDuration, ref status);
                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.DYN50_SAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_.ToString() + ") ";
                }
                else
                {
                    var strStartsWith = PayrollElementByDay.DYN50_SAL_PRODUCTSALARYOVEROFFSET_TOTALAMOUNT_.ToString();
                    var strEndWith = "_BYDAY";
                    List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");

                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;

                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                        var typeQuantity = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double totalAmount = 0;

                            var listSalProductSalaryOverOffset = TotalData.dicSalProductSalaryOverOffset.GetValueOrNew(profileItem.ID)
                                .Where(x => x.WorkDate != null && x.WorkDate == objAttendanceTableItem.WorkDate
                                 && x.TypeQuantity == typeQuantity).ToList();

                            if (listSalProductSalaryOverOffset.Count > 0)
                            {
                                totalAmount = listSalProductSalaryOverOffset.Where(x => x.TotalAmount != null).Sum(x => x.TotalAmount.Value);
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, totalAmount.ToString());
                            }
                            indexRow += 1;
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
            }
            #endregion

            #region Hien.Le [31/08/2020] [118568] [Skypec] Thêm 2 phần tử lương lấy dữ liệu màn hình Công việc hàng ngày
            //(Att_ProfileTimeSheet.NightActualWorkHours theo Cat_Shift.Code) 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN51_ATT_PROFILETIMESHEET_SUM_NIGHTACTUALHOURS_BY_SHIFTCODE_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN51_ATT_PROFILETIMESHEET_SUM_NIGHTACTUALHOURS_BY_SHIFTCODE_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var shiftCode = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objCatShift = TotalDataAll.listCat_Shift.Where(s => s.Code == shiftCode).FirstOrDefault();
                    if (objCatShift != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumNightActualHours = 0;

                            var listAttProfileTimeSheetProfile = TotalDataAll.ListAtt_ProfileTimeSheet.
                                Where(p => p.ProfileID == profileItem.ID
                                && p.NightActualWorkHours != null
                                && p.ShiftID != null
                                && p.WorkDate != null
                                && p.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                                && p.ShiftID == objCatShift.ID).ToList();

                            if (listAttProfileTimeSheetProfile.Count > 0)
                            {
                                sumNightActualHours = listAttProfileTimeSheetProfile.Sum(p => p.NightActualWorkHours.Value);
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumNightActualHours.ToString());
                            }
                            indexRow += 1;
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
            }

            //(Att_ProfileTimeSheet.NightActualWorkHours theo Cat_JobType.Code) 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN52_ATT_PROFILETIMESHEET_SUM_NIGHTACTUALHOURS_BY_JOBTYPECODE_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN52_ATT_PROFILETIMESHEET_SUM_NIGHTACTUALHOURS_BY_JOBTYPECODE_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeJobType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objCatJobType = TotalDataAll.listCat_JobType.Where(s => s.Code == codeJobType).FirstOrDefault();
                    if (objCatJobType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumNightActualHours = 0;

                            var listAttProfileTimeSheetProfile = TotalDataAll.ListAtt_ProfileTimeSheet.
                                Where(p => p.ProfileID == profileItem.ID
                                && p.NightActualWorkHours != null
                                && p.JobTypeID != null
                                && p.WorkDate != null
                                && p.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                                && p.JobTypeID == objCatJobType.ID).ToList();

                            if (listAttProfileTimeSheetProfile.Count > 0)
                            {
                                sumNightActualHours = listAttProfileTimeSheetProfile.Sum(p => p.NightActualWorkHours.Value);
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumNightActualHours.ToString());
                            }
                            indexRow += 1;
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
            }
            #endregion

            #region Nghia.Dang [06/10/2020][119559] [IRV]  Modify thêm enum tính lương theo ngày 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN53_SUM_ATT_OVERTIME_ISNOTCHECKINOUT_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN53_SUM_ATT_OVERTIME_ISNOTCHECKINOUT_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                var listOverTime = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);

                #region Trạng thái theo cấu hình "Giờ tăng ca được tính ở trạng thái" 
                var statusOT = EnumDropDown.OverTimeStatus.E_APPROVED.ToString();
                var objSysAllSetting = TotalDataAll.listAllSettingEntity.FirstOrDefault(p => p.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString());
                if (objSysAllSetting != null)
                {
                    statusOT = objSysAllSetting.Value1;
                }
                #endregion

                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();


                    var codeCatOverTimeType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objCatOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(s => s.Code == codeCatOverTimeType).FirstOrDefault();
                    if (objCatOverTimeType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double? sumOTHours = 0;

                            var listOverTimeByDate = listOverTime.Where(
                            x => x.WorkDateRoot == objAttendanceTableItem.WorkDate
                            && x.Status == statusOT
                            && x.IsNotCheckInOut == true
                            && x.OvertimeTypeID == objCatOverTimeType.ID).ToList();

                            if (statusOT == "E_APPROVE")
                            {
                                sumOTHours = listOverTimeByDate.Sum(x => x.ApproveHours);
                            }
                            else if (statusOT == "E_CONFIRM")
                            {
                                sumOTHours = listOverTimeByDate.Sum(x => x.ConfirmHours);
                            }
                            else
                            {
                                sumOTHours = listOverTimeByDate.Sum(x => x.RegisterHours);
                            }

                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumOTHours.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }

            #endregion

            #region Khoa.Nguyen [09/11/2020] [0121048]: [IRV] [HOTFIX BUILD 43] [MODIFY] Thêm enum tính lương theo ngày	
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN54_SAL_PRODUCTSALARYOVEROFFSET_SUMQUANTITY_.ToString(), "_BYDAY"))
            {
                string status = string.Empty;
                dataComputeSer.GetdicSalProductSalaryOverOffset(TotalData, CutOffDuration, ref status);
                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.DYN54_SAL_PRODUCTSALARYOVEROFFSET_SUMQUANTITY_.ToString() + ") ";
                }
                else
                {
                    var strStartsWith = PayrollElementByDay.DYN54_SAL_PRODUCTSALARYOVEROFFSET_SUMQUANTITY_.ToString();
                    var strEndWith = "_BYDAY";
                    List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();


                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");

                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;

                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                        var lstProductItem = new List<Cat_ProductItemEntity>();
                        var typeQuantityAndProductItem = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace("_AND_", "|").Replace(" ", "");
                        var splitTypeAndItem = typeQuantityAndProductItem.Split("|");
                        string typeQuantiy = string.Empty;
                        if (splitTypeAndItem.Count == 2)
                        {
                            lstProductItem = TotalDataAll.ListProductItem.Where(x => x.ProductCode == splitTypeAndItem[0]).ToList();
                            typeQuantiy = splitTypeAndItem[1];
                        }
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double totalAmount = 0;
                            var listSalProductSalaryOverOffset = new List<Sal_ProductSalaryOverOffsetEntity>();

                            if (lstProductItem.Count > 0 && !string.IsNullOrEmpty(typeQuantiy))
                            {
                                listSalProductSalaryOverOffset = TotalData.dicSalProductSalaryOverOffset.GetValueOrNew(profileItem.ID)
                               .Where(x => x.WorkDate != null && x.WorkDate == objAttendanceTableItem.WorkDate
                                && x.TypeQuantity == typeQuantiy
                                && x.ProductItemID != null
                                && lstProductItem.Select(m => m.ID).ToList().Contains(x.ProductItemID.Value)
                                ).ToList();
                            }

                            if (listSalProductSalaryOverOffset.Count > 0)
                            {
                                totalAmount = listSalProductSalaryOverOffset.Where(x => x.Quantity != null).Sum(x => x.Quantity.Value);
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, totalAmount.ToString());
                            }
                            indexRow += 1;
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
            }
            #endregion

            #region Nghia.Dang [11/12/2020][121998] [OCCEAN] Modify lấy thêm phần tử lương 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN55_ATT_TIMESHEET_COUNT_BYJOBTYPE_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN55_ATT_TIMESHEET_COUNT_BYJOBTYPE_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();


                    var codeCatJobType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objCatJobType = TotalDataAll.listCat_JobType.Where(s => s.Code == codeCatJobType).FirstOrDefault();
                    if (objCatJobType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double? countProfileTimeSheet = 0;

                            var listProfileTimeSheetByDate = TotalDataAll.ListAtt_ProfileTimeSheet.Where(
                              x => x.WorkDate != null
                              && x.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                              && x.ProfileID == profileItem.ID
                              && x.JobTypeID == objCatJobType.ID).ToList();


                            countProfileTimeSheet = listProfileTimeSheetByDate.Count();
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, countProfileTimeSheet.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN56_ATT_TIMESHEET_SUM_BYJOBTYPE_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN56_ATT_TIMESHEET_SUM_BYJOBTYPE_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();


                    var codeCatJobType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objCatJobType = TotalDataAll.listCat_JobType.Where(s => s.Code == codeCatJobType).FirstOrDefault();
                    if (objCatJobType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double? sumActualHours = 0;

                            var listProfileTimeSheetByDate = TotalDataAll.ListAtt_ProfileTimeSheet.Where(
                            x => x.WorkDate != null
                            && x.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                            && x.ProfileID == profileItem.ID
                            && x.JobTypeID == objCatJobType.ID).ToList();

                            sumActualHours = listProfileTimeSheetByDate.Sum(x => x.ActualHours);
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumActualHours.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN57_ATT_TIMESHEET_SUM_BYSHOPTRANS_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN57_ATT_TIMESHEET_SUM_BYSHOPTRANS_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                var listProfileTimeSheet = TotalDataAll.dicAtt_ProfileTimeSheet.GetValueOrNew(profileItem.ID);

                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();


                    var codeCatShop = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objCatShop = TotalDataAll.listShop.Where(s => s.Code == codeCatShop).FirstOrDefault();
                    if (objCatShop != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double? sumActualHours = 0;

                            var listProfileTimeSheetByDate = TotalDataAll.ListAtt_ProfileTimeSheet.Where(
                               x => x.WorkDate != null
                               && x.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                               && x.ProfileID == profileItem.ID
                               && x.ShopTransID == objCatShop.ID).ToList();
                            sumActualHours = listProfileTimeSheetByDate.Sum(x => x.ActualHours);
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumActualHours.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }


            #endregion

            #region Hien.Le [30/12/2020] 0122982: [HOTFIX SVP_v8.7.13.02.36.05] - Bổ sung enum lấy ra số giờ OT
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN58_ATT_OVERTIME_SUM_HOURS_.ToString(), "_BYDAY"))
            {
                string statusOT = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    statusOT = objAllSetting.Value1;
                }
                var strStartsWith = PayrollElementByDay.DYN58_ATT_OVERTIME_SUM_HOURS_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                var listOverTime = TotalDataAll.dicOverTime.GetValueOrNew(profileItem.ID);
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeCatShift = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objCatShift = TotalDataAll.listCat_Shift.Where(s => s.Code == codeCatShift).FirstOrDefault();
                    if (objCatShift != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double? sumHours = 0;
                            var listOverTimeByProfile = listOverTime.Where(
                               x => x.WorkDateRoot != null
                               && x.Status == statusOT
                               && x.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date
                               && x.ProfileID == profileItem.ID
                               && x.ShiftID == objCatShift.ID).ToList();

                            if (statusOT == EnumDropDown.OverTimeStatus.E_CONFIRM.ToString())
                            {
                                sumHours = listOverTimeByProfile.Sum(x => x.ConfirmHours);
                            }
                            else if (statusOT == EnumDropDown.OverTimeStatus.E_SUBMIT.ToString()
                                || statusOT == EnumDropDown.OverTimeStatus.E_FIRST_APPROVED.ToString()
                                || statusOT == EnumDropDown.OverTimeStatus.E_APPROVED1.ToString()
                                || statusOT == EnumDropDown.OverTimeStatus.E_APPROVED2.ToString())
                            {
                                sumHours = listOverTimeByProfile.Sum(x => x.RegisterHours);
                            }
                            else if (statusOT == EnumDropDown.OverTimeStatus.E_APPROVED.ToString())
                            {
                                sumHours = listOverTimeByProfile.Where(x => x.ApproveHours != null).Sum(x => x.ApproveHours);
                            }

                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumHours.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region  Khoa.nguyen [11/03/2021] 0124481: [HOT FIX IVC_V8.8.36.01.11] Bổ sung thêm Enums Số ngày công tác trong nước và số ngày công tác ngoài nước	
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN59_ATT_LEAVEDAY_TYPE_.ToString(), "_BYDAY"))
            {
                var strLeaveDayStatus = AttendanceDataStatus.E_APPROVED.ToString();
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYBUSSINESSSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null && objAllSetting.Value1 != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }

                var strStartsWith = PayrollElementByDay.DYN59_ATT_LEAVEDAY_TYPE_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");

                    if (!string.IsNullOrEmpty(codeType))
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            int valueTypeInt = 0;

                            var leaveDay = TotalDataAll.dicLeaveDayNotStatus.GetValueOrNew(profileItem.ID).Where( s=>
                                s.Status == strLeaveDayStatus
                                && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                                && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                                && s.IsBusinessTravel == true
                                ).FirstOrDefault();


                            if(leaveDay != null)
                            {
                                valueTypeInt = leaveDay.Type == codeType ? 1 : 0;
                            }    

                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, valueTypeInt.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region  Khoa.nguyen [11/03/2021] 0124481: [HOT FIX IVC_V8.8.36.01.11] Bổ sung thêm Enums Số ngày công tác trong nước và số ngày công tác ngoài nước
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN60_ATT_LEAVEDAY_MISSIONCOSTTYPE_.ToString(), "_BYDAY"))
            {
                var strLeaveDayStatus = AttendanceDataStatus.E_APPROVED.ToString();
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYBUSSINESSSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null && objAllSetting.Value1 != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }

                var strStartsWith = PayrollElementByDay.DYN60_ATT_LEAVEDAY_MISSIONCOSTTYPE_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                string status = string.Empty;
                string nameTableGetData = "listAtt_LeaveDayItem";
                if (!TotalData.dicTableGetDataByProfileIDs.ContainsKey(nameTableGetData))
                {
                    TotalData.listAtt_LeaveDayItem = dataComputeSer.GetLeaveDayItem(TotalData, CutOffDuration.DateStart, CutOffDuration.DateEnd, ref status);
                    TotalData.dicTableGetDataByProfileIDs.Add(nameTableGetData, "");
                }
                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông lưu store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.DYN60_ATT_LEAVEDAY_MISSIONCOSTTYPE_.ToString() + ") ";
                }
                else
                {
                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");

                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;

                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                        var codeType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");

                        if (!string.IsNullOrEmpty(codeType))
                        {
                            var objCatMissionCostType = TotalDataAll.listCat_MissionCostType.FirstOrDefault(x => x.Code == codeType);
                            if (objCatMissionCostType != null)
                            {
                                int indexRow = 0;
                                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                                {
                                    double? valueCostLeaveDays = 0;

                                    var leaveDay = TotalDataAll.dicLeaveDayNotStatus.GetValueOrNew(profileItem.ID).Where(s =>
                                       s.Status == strLeaveDayStatus
                                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                                       && s.IsBusinessTravel == true
                                        ).FirstOrDefault();

                                    if (leaveDay != null)
                                    {
                                        var objtAttLeaveDayItem = TotalData.listAtt_LeaveDayItem.FirstOrDefault(x => x.LeaveDayID == leaveDay.ID && x.MissionCostTypeID == objCatMissionCostType.ID);
                                        if (objtAttLeaveDayItem != null)
                                        {
                                            valueCostLeaveDays = (objtAttLeaveDayItem.Cost / leaveDay.LeaveDays);
                                        }
                                    }

                                    if (!listValueByDay.ContainsKey(indexRow))
                                    {
                                        listValueByDay.Add(indexRow, valueCostLeaveDays.ToString());
                                    }
                                    indexRow += 1;
                                }
                            }
                        }
                        else
                        {
                            for (int i = 0; i < totalRowInDataSoure; i++)
                            {
                                if (!listValueByDay.ContainsKey(i))
                                {
                                    listValueByDay.Add(i, "0");
                                }
                            }
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }    
            }
            #endregion

            #region Khoa.nguyen 0125749 [22/05/2021] Phần tử lương theo ngày động trả ra số ngày

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN61_ATT_ATTENDANCETABLEITEM_BUSINESSTRAVELDAY_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN61_ATT_ATTENDANCETABLEITEM_BUSINESSTRAVELDAY_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");

                    if (!string.IsNullOrEmpty(codeType))
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {

                            double? valueSum = 0;
                            var objBusinessTravel = TotalDataAll.listBusinessTravel.FirstOrDefault(x => x.BusinessTravelCode == codeType);

                            if (objBusinessTravel != null && (objAttendanceTableItem.BusinessTravelTypeID1 != null && objAttendanceTableItem.BusinessTravelTypeID1 == objBusinessTravel.ID))
                            {
                                valueSum += objAttendanceTableItem.BusinessTravelDay1;
                            }

                            if (objBusinessTravel != null && (objAttendanceTableItem.BusinessTravelTypeID2 != null && objAttendanceTableItem.BusinessTravelTypeID2 == objBusinessTravel.ID))
                            {
                                valueSum += objAttendanceTableItem.BusinessTravelDay2;
                            }


                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, valueSum.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region Khoa.nguyen 0125749 [22/05/2021] Phần tử lương theo ngày động trả ra số giờ

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN62_ATT_ATTENDANCETABLEITEM_BUSINESSTRAVELHOURS_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN62_ATT_ATTENDANCETABLEITEM_BUSINESSTRAVELHOURS_.ToString();
                var strEndWith = "_BYDAY";
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");

                    if (!string.IsNullOrEmpty(codeType))
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {

                            double? valueSum = 0;
                            var objBusinessTravel = TotalDataAll.listBusinessTravel.FirstOrDefault(x => x.BusinessTravelCode == codeType);

                            if (objBusinessTravel != null && (objAttendanceTableItem.BusinessTravelTypeID1 != null && objAttendanceTableItem.BusinessTravelTypeID1 == objBusinessTravel.ID))
                            {
                                valueSum += objAttendanceTableItem.BusinessTravelHours1;
                            }

                            if (objBusinessTravel != null && (objAttendanceTableItem.BusinessTravelTypeID2 != null && objAttendanceTableItem.BusinessTravelTypeID2 == objBusinessTravel.ID))
                            {
                                valueSum += objAttendanceTableItem.BusinessTravelHours2;
                            }


                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, valueSum.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region kietnguyen 05/10/2021 133623: [Hotfix_Ver: Vinasoy_v8.8.43.01.07.56]Phần tử lương: Thêm PTL lấy ra số giờ tăng ca với phương thức nghỉ bù
            //[09/07/2018][bang.nguyen][96518][Modify Func]
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN115_SUM_ATT_OVERTIME_GROUPBYOVERTIMEOFFTYPEID_.ToString(), "_BYDAY"))
            {
                var strStartsWith = PayrollElementByDay.DYN115_SUM_ATT_OVERTIME_GROUPBYOVERTIMEOFFTYPEID_.ToString();
                var strEndWith = "_BYDAY";
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                    var codeOverTimeType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objOverTimeType = TotalDataAll.listOvertimeType.FirstOrDefault(s => s.Code == codeOverTimeType);

                    if (objOverTimeType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double? sumOverTimeHour = 0;
                            if (objAttendanceTableItem.OvertimeOFFTypeID1 == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.OvertimeOFFHours1;
                            }
                            if (objAttendanceTableItem.OvertimeOFFTypeID2 == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.OvertimeOFFHours2;
                            }
                            if (objAttendanceTableItem.OvertimeOFFTypeID3 == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.OvertimeOFFHours3;
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumOverTimeHour.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }

                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #endregion
            #region Tạo cấu trúc bảng
            //bang sẽ chứa all các cột làm enum cho công thức mảng
            //mỗi 1 cột sẽ là 1 logic để lấy giá trị trả về cho từng ngày
            DataTable dataSource = new DataTable();

            //add all cột
            foreach (var columnByDay in listColumnByDay)
            {
                string columnName = columnByDay.ColumnName;
                if (!dataSource.Columns.Contains(columnName))
                {
                    if (columnByDay.ValueType == strDouble)
                    {
                        dataSource.Columns.Add(columnName, typeof(Double));
                    }
                    else if (columnByDay.ValueType == strDateTime)
                    {
                        dataSource.Columns.Add(columnName, typeof(DateTime));
                    }
                    else
                    {
                        dataSource.Columns.Add(columnName);
                    }
                }
            }

            //gán dữ liệu cho các cột
            for (int i = 0; i < totalRowInDataSoure; i++)
            {
                DataRow row = dataSource.NewRow();
                foreach (var columnByDay in listColumnByDay)
                {
                    string columnName = columnByDay.ColumnName;
                    string valueString = string.Empty;
                    if (columnByDay.ListValueByDay.Keys.Contains(i))
                    {
                        valueString = columnByDay.ListValueByDay[i];
                    }
                    if (columnByDay.ValueType == strDouble)
                    {
                        if (!string.IsNullOrEmpty(valueString))
                        {
                            double valueDouble = 0;
                            row[columnName] = valueDouble;
                            if (Double.TryParse(valueString, out valueDouble))
                            {
                                row[columnName] = valueDouble;
                            }
                        }
                    }
                    else if (columnByDay.ValueType == strDateTime)
                    {
                        if (!string.IsNullOrEmpty(valueString))
                        {
                            DateTime valueDateTime = DateTime.MinValue;
                            row[columnName] = valueDateTime;
                            if (DateTime.TryParse(valueString, out valueDateTime))
                            {
                                row[columnName] = valueDateTime;
                            }
                        }
                    }
                    else
                    {
                        row[columnName] = valueString;
                    }
                }
                dataSource.Rows.Add(row);
            }
            #endregion

            //bang chua all các cột làm enum tính
            var elementFormulaDataSource = new ElementFormula
            {
                VariableName = "Source",
                OrderNumber = 0,
                Value = dataSource
            };
            //ds all enum trong source
            TotalData.listAllColumnInSource = dataSource.Columns.Cast<DataColumn>().Select(x => x.ColumnName).ToList();
            listElementFormulaByDay.Add(elementFormulaDataSource);
            return listElementFormulaByDay;
        }
        #endregion

        #region Tung.Tran [19/09/2018][0098471][Modify] Tính giá trị cho các phần tử sử dụng enum ngày - N tháng
        public List<ElementFormula> ParseElementFormulaByDayPreMonth(
            ComputePayrollDataModelKZAll TotalDataAll,
            List<ElementFormula> listElementFormulaByDay,
            List<Cat_ElementEntity> listGradeElementByDay,
            ComputePayrollDataModelKZ TotalData,
            Hre_ProfileEntity profileItem,
            Att_CutOffDurationEntity CutOffDuration,
            Sal_GradeEntity GradeElement,
            Dictionary<Guid, ValueCount> listTmpDeduction,
            bool ComputeOrderNumber, string strMonthPre)
        {
            //lấy bảng công của nv trong tháng tính lương
            Att_AttendanceTableEntity objAttendanceTableProCut = TotalData.listAttendanceTableAll.Where(m => m.ProfileID == profileItem.ID && m.DateStart <= CutOffDuration.DateEnd && m.DateEnd >= CutOffDuration.DateStart).FirstOrDefault();
            if (objAttendanceTableProCut == null)
            {
                objAttendanceTableProCut = new Att_AttendanceTableEntity();
            }

            #region Cho các phần tử ngày gọi lại với nhau
            //lấy all enum trong công thức ngày => rồi đi lấy giá trị 1 lần => sau đó tính cho từng công thức 
            List<string> ListFormula = new List<string>();
            foreach (var elementItem in listGradeElementByDay)
            {
                try
                {
                    string strFormula = elementItem.Formula.Replace("[Source]", "").Replace("[Value]", "");
                    //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                    ListFormula.AddRange(Common.ParseFormulaToList(strFormula).Where(m => m.IndexOf('[') != -1 && m.IndexOf(']') != -1).ToList());
                }
                catch
                {
                    throw new Exception(elementItem.ElementCode);
                }
            }
            //Các phần tử tính lương chưa có kết quả
            ListFormula = ListFormula.Select(s => s = s.Replace("[", "").Replace("]", "")).Distinct().ToList();

            //tính cho các enum hệ thống trước (enum theo tháng)
            listElementFormulaByDay = computePayrollSer.GetStaticValues(
                TotalDataAll,
                TotalData,
                listElementFormulaByDay,
                profileItem,
                CutOffDuration,
                null,
                ListFormula,
                GradeElement.GradePayrollID,
                objAttendanceTableProCut,
                listTmpDeduction,
                null
                );
            //Hien.Le [05/01/2021] [Bug] Đặt enum ngày lùi có chứa enum tháng
            //var listFormulaNotPreMonth = listElementFormulaByDay.Where(p => !p.VariableName.Contains("BYDAY_N_")).ToList();

            //tinh gia tri cho cong thuc theo ngay
            listElementFormulaByDay = GetStaticValuesByDayPreMonth(TotalDataAll, TotalData, listElementFormulaByDay, profileItem, CutOffDuration, ListFormula, GradeElement.GradePayrollID, objAttendanceTableProCut, listTmpDeduction, strMonthPre);

            if (ComputeOrderNumber)
            {
                listGradeElementByDay = listGradeElementByDay.OrderBy(m => m.OrderNumber).ToList();
                foreach (var elementItem in listGradeElementByDay)
                {
                    try
                    {
                        //tính cho công thức dạng mảng
                        var result = FormulaHelper.ParseFormula(elementItem.Formula, listElementFormulaByDay);
                        //them kết quả để dùng lại tính cho các phần tử thường
                        listElementFormulaByDay.Add(new ElementFormula(elementItem.ElementCode, result.Value, 0, result.ErrorMessage));
                    }
                    catch
                    {
                        throw new Exception(elementItem.ElementCode);
                    }
                }
            }
            else
            {
                foreach (var elementItem in listGradeElementByDay)
                {
                    try
                    {
                        listElementFormulaByDay = ParseFormulaByDay(elementItem, listElementFormulaByDay, TotalData, profileItem, CutOffDuration, GradeElement.GradePayrollID, objAttendanceTableProCut, listTmpDeduction);
                    }
                    catch
                    {
                        throw new Exception(elementItem.ElementCode);
                    }
                }
            }
            #endregion
            //Hien.Le [05/01/2021] [Bug] Đặt enum ngày lùi có chứa enum tháng
            //listElementFormulaByDay = listElementFormulaByDay.Where(s => s.VariableName != "Source" && !listFormulaNotPreMonth.Any(p => p.VariableName == s.VariableName)).Distinct().ToList();
            return listElementFormulaByDay.Where(s => s.VariableName != "Source").Distinct().ToList(); ;
        }

        public List<ElementFormula> GetStaticValuesByDayPreMonth(
            ComputePayrollDataModelKZAll TotalDataAll,
            ComputePayrollDataModelKZ TotalData,
            List<ElementFormula> listElementFormulaByDay,
            Hre_ProfileEntity profileItem,
            Att_CutOffDurationEntity CutOffDuration,
            List<string> formula,
            Guid? GradePayrollID,
            Att_AttendanceTableEntity objAttendanceTableProCut,
            Dictionary<Guid, ValueCount> listTmpDeduction,
            string strMonthPre)
        {
            //ds tất cả các enum và giá trị từng ngày cho từng enum
            List<ColumnByDay> listColumnByDay = new List<ColumnByDay>();
            string strDouble = "Double";
            string strDateTime = "DateTime";
            string strString = "String";

            var listAttendanceTableItem = TotalData.listAttendanceTableItemAll.Where(s => s.AttendanceTableID == objAttendanceTableProCut.ID).OrderBy(s => s.WorkDate).ToList();
            //tổng số dòng trong table
            int totalRowInDataSoure = listAttendanceTableItem.Count;

            #region Enum

            #region so phu tre som 96183
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EARLYOUTMINUTES_BYDAY.ToString() + strMonthPre, PayrollElementByDay.LATEINMINUTES_BYDAY.ToString() + strMonthPre }))
            {
                string columnEARLYOUTMINUTES_BYDAY = PayrollElementByDay.EARLYOUTMINUTES_BYDAY.ToString() + strMonthPre;
                string columLATEINMINUTES_BYDAY = PayrollElementByDay.LATEINMINUTES_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columnEARLYOUTMINUTES_BYDAY;
                objColumnByDay.ValueType = "Double";
                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                ColumnByDay objColumnByDayEarly = new ColumnByDay();
                objColumnByDayEarly.ColumnName = columLATEINMINUTES_BYDAY;
                objColumnByDayEarly.ValueType = strDouble;
                Dictionary<int, string> listValueByDayEarly = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, objAttendanceTableItem.EarlyOutMinutes.ToString());
                    }
                    if (!listValueByDayEarly.ContainsKey(indexRow))
                    {
                        listValueByDayEarly.Add(indexRow, objAttendanceTableItem.LateInMinutes.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueByDay;
                objColumnByDayEarly.ListValueByDay = listValueByDayEarly;
                listColumnByDay.Add(objColumnByDay);
                listColumnByDay.Add(objColumnByDayEarly);
            }
            #endregion

            #region Thu trong tuần 
            //[09/07/2018][bang.nguyen][96518][modify]
            //Thứ trong tuần theo quy định (CN, T2, T3, T4, T5, T6, T7) tương ứng (0, 1, 2, 3, 4, 5, 6, 7)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.INDEXDAYOFWEEK_BYDAY.ToString() + strMonthPre))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.INDEXDAYOFWEEK_BYDAY.ToString() + strMonthPre;
                objColumnByDay.ValueType = "Double";
                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                int indexRow = 0;
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string strIndexDayOfWeek = string.Empty;
                    if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Sunday)
                    {
                        strIndexDayOfWeek = "1";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Monday)
                    {
                        strIndexDayOfWeek = "2";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Tuesday)
                    {
                        strIndexDayOfWeek = "3";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Wednesday)
                    {
                        strIndexDayOfWeek = "4";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Thursday)
                    {
                        strIndexDayOfWeek = "5";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Friday)
                    {
                        strIndexDayOfWeek = "6";
                    }
                    else if (objAttendanceTableItem.WorkDate.DayOfWeek == DayOfWeek.Saturday)
                    {
                        strIndexDayOfWeek = "7";
                    }
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, strIndexDayOfWeek);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region nhom nhan vien 96518
            //[09/07/2018][bang.nguyen][96518][modify]
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EMPLOYEETYPE_BYDAY.ToString() + strMonthPre))
            {
                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = PayrollElementByDay.EMPLOYEETYPE_BYDAY.ToString() + strMonthPre;
                objColumnByDay.ValueType = strString;
                //ds dữ liệu cho từng ngày
                Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                int indexRow = 0;
                var listWorkHistory = TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID).Where(s => s.ProfileID == profileItem.ID).ToList();
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string employeeTypeCode = string.Empty;
                    var objWorkHistory = listWorkHistory.Where(s => s.DateEffective <= objAttendanceTableItem.WorkDate).OrderByDescending(s => s.DateEffective).FirstOrDefault();
                    if (!string.IsNullOrEmpty(objWorkHistory.EmployeeTypeCode))
                    {
                        employeeTypeCode = objWorkHistory.EmployeeTypeCode;
                    }
                    if (!listValueByDay.ContainsKey(indexRow))
                    {
                        listValueByDay.Add(indexRow, employeeTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [15082018][0097380] Thêm phần tử ngày:  Lấy field (WorkDate)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.WORKDAY_BYDAY.ToString() + strMonthPre }))
            {
                string columWORKDAY_BYDAY = PayrollElementByDay.WORKDAY_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columWORKDAY_BYDAY;
                objColumnByDay.ValueType = strDateTime;
                Dictionary<int, string> listValueWorkDayByDay = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var workDate = DateTime.MinValue;
                    if (objAttendanceTableItem.WorkDate != null)
                    {
                        workDate = objAttendanceTableItem.WorkDate;
                    }
                    if (!listValueWorkDayByDay.ContainsKey(indexRow))
                    {
                        listValueWorkDayByDay.Add(indexRow, workDate.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueWorkDayByDay;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:  Lấy field (ActualWorkHour)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.ACTUALWORKHOUR_BYDAY.ToString() + strMonthPre }))
            {
                string columACTUALWORKHOUR_BYDAY = PayrollElementByDay.ACTUALWORKHOUR_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columACTUALWORKHOUR_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueAcTualWorkHourByDay = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var actualWorkHour = 0.0;
                    if (objAttendanceTableItem.ActualWorkHour != null)
                    {
                        actualWorkHour = objAttendanceTableItem.ActualWorkHour.Value;
                    }
                    if (!listValueAcTualWorkHourByDay.ContainsKey(indexRow))
                    {
                        listValueAcTualWorkHourByDay.Add(indexRow, actualWorkHour.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueAcTualWorkHourByDay;
                listColumnByDay.Add(objColumnByDay);
            }


            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:  Att_LeaveDay.HaveMeal
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.LEAVETYPEHAVEMEAL_BYDAY.ToString() + strMonthPre,
                PayrollElementByDay.EXTRALEAVETYPEHAVEMEAL_BYDAY.ToString() + strMonthPre,
                PayrollElementByDay.EXTRALEAVETYPE3HAVEMEAL_BYDAY.ToString() + strMonthPre,
                PayrollElementByDay.EXTRALEAVETYPE4HAVEMEAL_BYDAY.ToString() + strMonthPre,
                PayrollElementByDay.EXTRALEAVETYPE5HAVEMEAL_BYDAY.ToString() + strMonthPre,
                PayrollElementByDay.EXTRALEAVETYPE6HAVEMEAL_BYDAY.ToString() + strMonthPre,
                PayrollElementByDay.LEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ToString() + strMonthPre,

            }))
            {
                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }

                #region Khai báo các cột
                string columLEAVETYPEHAVEMEAL_BYDAY = PayrollElementByDay.LEAVETYPEHAVEMEAL_BYDAY.ToString() + strMonthPre;
                string columEXTRALEAVETYPEHAVEMEAL_BYDAY = PayrollElementByDay.EXTRALEAVETYPEHAVEMEAL_BYDAY.ToString() + strMonthPre;
                string columEXTRALEAVETYPE3HAVEMEAL_BYDAY = PayrollElementByDay.EXTRALEAVETYPE3HAVEMEAL_BYDAY.ToString() + strMonthPre;
                string columEXTRALEAVETYPE4HAVEMEAL_BYDAY = PayrollElementByDay.EXTRALEAVETYPE4HAVEMEAL_BYDAY.ToString() + strMonthPre;
                string columEXTRALEAVETYPE5HAVEMEAL_BYDAY = PayrollElementByDay.EXTRALEAVETYPE5HAVEMEAL_BYDAY.ToString() + strMonthPre;
                string columEXTRALEAVETYPE6HAVEMEAL_BYDAY = PayrollElementByDay.EXTRALEAVETYPE6HAVEMEAL_BYDAY.ToString() + strMonthPre;
                string columLEAVEWORKDAYTYPEHAVEMEAL_BYDAY = PayrollElementByDay.LEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ToString() + strMonthPre;


                ColumnByDay objColumnLEAVETYPEHAVEMEAL_BYDAY = new ColumnByDay();
                objColumnLEAVETYPEHAVEMEAL_BYDAY.ColumnName = columLEAVETYPEHAVEMEAL_BYDAY;
                objColumnLEAVETYPEHAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPEHAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnEXTRALEAVETYPEHAVEMEAL_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPEHAVEMEAL_BYDAY.ColumnName = columEXTRALEAVETYPEHAVEMEAL_BYDAY;
                objColumnEXTRALEAVETYPEHAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPEHAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnEXTRALEAVETYPE3HAVEMEAL_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE3HAVEMEAL_BYDAY.ColumnName = columEXTRALEAVETYPE3HAVEMEAL_BYDAY;
                objColumnEXTRALEAVETYPE3HAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE3HAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnEXTRALEAVETYPE4HAVEMEAL_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE4HAVEMEAL_BYDAY.ColumnName = columEXTRALEAVETYPE4HAVEMEAL_BYDAY;
                objColumnEXTRALEAVETYPE4HAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE4HAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnEXTRALEAVETYPE5HAVEMEAL_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE5HAVEMEAL_BYDAY.ColumnName = columEXTRALEAVETYPE5HAVEMEAL_BYDAY;
                objColumnEXTRALEAVETYPE5HAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE5HAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnEXTRALEAVETYPE6HAVEMEAL_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE6HAVEMEAL_BYDAY.ColumnName = columEXTRALEAVETYPE6HAVEMEAL_BYDAY;
                objColumnEXTRALEAVETYPE6HAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE6HAVEMEAL_BYDAY = new Dictionary<int, string>();

                ColumnByDay objColumnLEAVEWORKDAYTYPEHAVEMEAL_BYDAY = new ColumnByDay();
                objColumnLEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ColumnName = columLEAVEWORKDAYTYPEHAVEMEAL_BYDAY;
                objColumnLEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueLEAVEWORKDAYTYPEHAVEMEAL_BYDAY = new Dictionary<int, string>();
                #endregion


                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {

                    #region HaveMeal 1
                    var leaveDay1 = TotalData.listLeaveDayAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.LeaveTypeID).FirstOrDefault();
                    var haveMeal1 = string.Empty;
                    if (leaveDay1 != null && !string.IsNullOrEmpty(leaveDay1.HaveMeal))
                    {
                        haveMeal1 = leaveDay1.HaveMeal;
                    }
                    if (!listValueLEAVETYPEHAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPEHAVEMEAL_BYDAY.Add(indexRow, haveMeal1);
                    }
                    #endregion

                    #region HaveMeal 2
                    var leaveDay2 = TotalData.listLeaveDayAll.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveTypeID).FirstOrDefault();
                    var haveMeal2 = string.Empty;
                    if (leaveDay2 != null && !string.IsNullOrEmpty(leaveDay2.HaveMeal))
                    {
                        haveMeal2 = leaveDay2.HaveMeal;
                    }
                    if (!listValueEXTRALEAVETYPEHAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPEHAVEMEAL_BYDAY.Add(indexRow, haveMeal2);
                    }
                    #endregion

                    #region HaveMeal 3
                    var leaveDay3 = TotalData.listLeaveDayAll.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType3ID).FirstOrDefault();
                    var haveMeal3 = string.Empty;
                    if (leaveDay3 != null && !string.IsNullOrEmpty(leaveDay3.HaveMeal))
                    {
                        haveMeal3 = leaveDay3.HaveMeal;
                    }
                    if (!listValueEXTRALEAVETYPE3HAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE3HAVEMEAL_BYDAY.Add(indexRow, haveMeal3);
                    }
                    #endregion

                    #region HaveMeal 4
                    var leaveDay4 = TotalData.listLeaveDayAll.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType4ID).FirstOrDefault();
                    var haveMeal4 = string.Empty;
                    if (leaveDay4 != null && !string.IsNullOrEmpty(leaveDay4.HaveMeal))
                    {
                        haveMeal4 = leaveDay4.HaveMeal;
                    }
                    if (!listValueEXTRALEAVETYPE4HAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE4HAVEMEAL_BYDAY.Add(indexRow, haveMeal4);
                    }
                    #endregion

                    #region HaveMeal 5
                    var leaveDay5 = TotalData.listLeaveDayAll.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType5ID).FirstOrDefault();
                    var haveMeal5 = string.Empty;
                    if (leaveDay5 != null && !string.IsNullOrEmpty(leaveDay5.HaveMeal))
                    {
                        haveMeal5 = leaveDay5.HaveMeal;
                    }
                    if (!listValueEXTRALEAVETYPE5HAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE5HAVEMEAL_BYDAY.Add(indexRow, haveMeal5);
                    }
                    #endregion

                    #region HaveMeal 6
                    var leaveDay6 = TotalData.listLeaveDayAll.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType6ID).FirstOrDefault();
                    var haveMeal6 = string.Empty;
                    if (leaveDay6 != null && !string.IsNullOrEmpty(leaveDay6.HaveMeal))
                    {
                        haveMeal6 = leaveDay6.HaveMeal;
                    }
                    if (!listValueEXTRALEAVETYPE6HAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE6HAVEMEAL_BYDAY.Add(indexRow, haveMeal6);
                    }
                    #endregion

                    #region HaveMeal 7 ( Cột LeaveWorkDayType)
                    var leaveDay7 = TotalData.listLeaveDayAll.Where(
                       s => s.ProfileID == profileItem.ID
                       && s.Status == strLeaveDayStatus
                       && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                       && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                       && s.LeaveDayTypeID == objAttendanceTableItem.LeaveWorkDayType).FirstOrDefault();
                    var haveMeal7 = string.Empty;
                    if (leaveDay7 != null && !string.IsNullOrEmpty(leaveDay7.HaveMeal))
                    {
                        haveMeal7 = leaveDay7.HaveMeal;
                    }
                    if (!listValueLEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVEWORKDAYTYPEHAVEMEAL_BYDAY.Add(indexRow, haveMeal7);
                    }
                    #endregion

                    indexRow += 1;
                }
                objColumnLEAVETYPEHAVEMEAL_BYDAY.ListValueByDay = listValueLEAVETYPEHAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnLEAVETYPEHAVEMEAL_BYDAY);

                objColumnEXTRALEAVETYPEHAVEMEAL_BYDAY.ListValueByDay = listValueEXTRALEAVETYPEHAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPEHAVEMEAL_BYDAY);

                objColumnEXTRALEAVETYPE3HAVEMEAL_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE3HAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE3HAVEMEAL_BYDAY);

                objColumnEXTRALEAVETYPE4HAVEMEAL_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE4HAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE4HAVEMEAL_BYDAY);

                objColumnEXTRALEAVETYPE5HAVEMEAL_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE5HAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE5HAVEMEAL_BYDAY);

                objColumnEXTRALEAVETYPE6HAVEMEAL_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE6HAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE6HAVEMEAL_BYDAY);

                objColumnLEAVEWORKDAYTYPEHAVEMEAL_BYDAY.ListValueByDay = listValueLEAVEWORKDAYTYPEHAVEMEAL_BYDAY;
                listColumnByDay.Add(objColumnLEAVEWORKDAYTYPEHAVEMEAL_BYDAY);
            }
            #endregion

            #region Tung.Tran [21082018][97292] AVAILABLEHOURS_BYDAY (Att_AttendanceTableItem.AVAILABLEHOURS

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.AVAILABLEHOURS_BYDAY.ToString() + strMonthPre }))
            {
                string columAVAILABLEHOURS_BYDAY = PayrollElementByDay.AVAILABLEHOURS_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columAVAILABLEHOURS_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueAVAILABLEHOURS_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {

                    if (!listValueAVAILABLEHOURS_BYDAY.ContainsKey(indexRow))
                    {
                        listValueAVAILABLEHOURS_BYDAY.Add(indexRow, objAttendanceTableItem.AvailableHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueAVAILABLEHOURS_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] SHIFTCODE1_BYDAY (Att_AttendanceTableItem.ShiftID.Code)

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.SHIFTCODE1_BYDAY.ToString() + strMonthPre }))
            {
                string columSHIFTCODE1_BYDAY = PayrollElementByDay.SHIFTCODE1_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columSHIFTCODE1_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueSHIFTCODE1_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var shiftCode = string.Empty;
                    if (objAttendanceTableItem.ShiftID != null)
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null && objShift.Code != null)
                        {
                            shiftCode = objShift.Code;
                        }
                    }
                    if (!listValueSHIFTCODE1_BYDAY.ContainsKey(indexRow))
                    {
                        listValueSHIFTCODE1_BYDAY.Add(indexRow, shiftCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueSHIFTCODE1_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] SHIFTCODE2_BYDAY (Att_AttendanceTableItem.ShiftID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.SHIFTCODE2_BYDAY.ToString() + strMonthPre }))
            {
                string columSHIFTCODE2_BYDAY = PayrollElementByDay.SHIFTCODE2_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columSHIFTCODE2_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueSHIFTCODE2_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var shiftCode = string.Empty;
                    if (objAttendanceTableItem.Shift2ID != null)
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == objAttendanceTableItem.Shift2ID);
                        if (objShift != null && objShift.Code != null)
                        {
                            shiftCode = objShift.Code;
                        }
                    }
                    if (!listValueSHIFTCODE2_BYDAY.ContainsKey(indexRow))
                    {
                        listValueSHIFTCODE2_BYDAY.Add(indexRow, shiftCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueSHIFTCODE2_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE1_BYDAY (Att_AttendanceTableItem.LeaveTypeID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE1_BYDAY.ToString() + strMonthPre }))
            {
                string columLEAVETYPECODE1_BYDAY = PayrollElementByDay.LEAVETYPECODE1_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE1_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE1_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.LeaveTypeID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.LeaveTypeID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE1_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE1_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE1_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS1_BYDAY (Att_AttendanceTableItem.LeaveHours)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS1_BYDAY.ToString() + strMonthPre }))
            {
                string columEXTRALEAVEHOURS1_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS1_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS1_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS1_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValueEXTRALEAVEHOURS1_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS1_BYDAY.Add(indexRow, objAttendanceTableItem.LeaveHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS1_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE2_BYDAY (Att_AttendanceTableItem.ExtraLeaveTypeID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE2_BYDAY.ToString() + strMonthPre }))
            {
                string columLEAVETYPECODE2_BYDAY = PayrollElementByDay.LEAVETYPECODE2_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE2_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE2_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.ExtraLeaveTypeID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.ExtraLeaveTypeID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE2_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE2_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE2_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS2_BYDAY (Att_AttendanceTableItem.ExtraLeaveHours)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS2_BYDAY.ToString() + strMonthPre }))
            {
                string columEXTRALEAVEHOURS2_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS2_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS2_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS2_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValueEXTRALEAVEHOURS2_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS2_BYDAY.Add(indexRow, objAttendanceTableItem.ExtraLeaveHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS2_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE3_BYDAY (Att_AttendanceTableItem.ExtraLeaveType3ID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE3_BYDAY.ToString() + strMonthPre }))
            {
                string columLEAVETYPECODE3_BYDAY = PayrollElementByDay.LEAVETYPECODE3_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE3_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE3_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.ExtraLeaveType3ID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.ExtraLeaveType3ID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE3_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE3_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE3_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS3_BYDAY (Att_AttendanceTableItem.ExtraLeaveHours3)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS3_BYDAY.ToString() + strMonthPre }))
            {
                string columEXTRALEAVEHOURS3_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS3_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS3_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS3_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var extraLeaveHours3 = 0.0;
                    if (objAttendanceTableItem.ExtraLeaveHours3 != null)
                    {
                        extraLeaveHours3 = objAttendanceTableItem.ExtraLeaveHours3.Value;
                    }

                    if (!listValueEXTRALEAVEHOURS3_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS3_BYDAY.Add(indexRow, extraLeaveHours3.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS3_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE4_BYDAY (Att_AttendanceTableItem.ExtraLeaveType4ID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE4_BYDAY.ToString() + strMonthPre }))
            {
                string columLEAVETYPECODE4_BYDAY = PayrollElementByDay.LEAVETYPECODE4_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE4_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE4_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.ExtraLeaveType4ID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.ExtraLeaveType4ID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE4_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE4_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE4_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS4_BYDAY (Att_AttendanceTableItem.ExtraLeaveHours4)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS4_BYDAY.ToString() + strMonthPre }))
            {
                string columEXTRALEAVEHOURS4_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS4_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS4_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS4_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var extraLeaveHours4 = 0.0;
                    if (objAttendanceTableItem.ExtraLeaveHours4 != null)
                    {
                        extraLeaveHours4 = objAttendanceTableItem.ExtraLeaveHours4.Value;
                    }

                    if (!listValueEXTRALEAVEHOURS4_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS4_BYDAY.Add(indexRow, extraLeaveHours4.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS4_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE5_BYDAY (Att_AttendanceTableItem.ExtraLeaveType5ID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE5_BYDAY.ToString() + strMonthPre }))
            {
                string columLEAVETYPECODE5_BYDAY = PayrollElementByDay.LEAVETYPECODE5_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE5_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE5_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.ExtraLeaveType5ID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.ExtraLeaveType5ID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE5_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE5_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE5_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS5_BYDAY (Att_AttendanceTableItem.ExtraLeaveHours5)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS5_BYDAY.ToString() + strMonthPre }))
            {
                string columEXTRALEAVEHOURS5_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS5_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS5_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS5_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var extraLeaveHours5 = 0.0;
                    if (objAttendanceTableItem.ExtraLeaveHours5 != null)
                    {
                        extraLeaveHours5 = objAttendanceTableItem.ExtraLeaveHours5.Value;
                    }
                    if (!listValueEXTRALEAVEHOURS5_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS5_BYDAY.Add(indexRow, extraLeaveHours5.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS5_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] LEAVETYPECODE6_BYDAY (Att_AttendanceTableItem.ExtraLeaveType6ID.Code)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.LEAVETYPECODE6_BYDAY.ToString() + strMonthPre }))
            {
                string columLEAVETYPECODE6_BYDAY = PayrollElementByDay.LEAVETYPECODE6_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columLEAVETYPECODE6_BYDAY;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPECODE6_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveTypeCode = string.Empty;
                    if (objAttendanceTableItem.ExtraLeaveType6ID != null)
                    {
                        var objLeaveDay = TotalDataAll.listLeavedayType.FirstOrDefault(a => a.ID == objAttendanceTableItem.ExtraLeaveType6ID);
                        if (objLeaveDay != null && objLeaveDay.Code != null)
                        {
                            leaveTypeCode = objLeaveDay.Code;
                        }
                    }
                    if (!listValueLEAVETYPECODE6_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPECODE6_BYDAY.Add(indexRow, leaveTypeCode);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueLEAVETYPECODE6_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [21082018][97292] EXTRALEAVEHOURS6_BYDAY (Att_AttendanceTableItem.ExtraLeaveHours6)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.EXTRALEAVEHOURS6_BYDAY.ToString() + strMonthPre }))
            {
                string columEXTRALEAVEHOURS6_BYDAY = PayrollElementByDay.EXTRALEAVEHOURS6_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = columEXTRALEAVEHOURS6_BYDAY;
                objColumnByDay.ValueType = strDouble;
                Dictionary<int, string> listValueEXTRALEAVEHOURS6_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var extraLeaveHours6 = 0.0;
                    if (objAttendanceTableItem.ExtraLeaveHours6 != null)
                    {
                        extraLeaveHours6 = objAttendanceTableItem.ExtraLeaveHours6.Value;
                    }
                    if (!listValueEXTRALEAVEHOURS6_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVEHOURS6_BYDAY.Add(indexRow, extraLeaveHours6.ToString());
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValueEXTRALEAVEHOURS6_BYDAY;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.LeaveTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.LEAVETYPEDURATIONTYPE_BYDAY.ToString() + strMonthPre,
            }))
            {
                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columLEAVETYPEDURATIONTYPE_BYDAY = PayrollElementByDay.LEAVETYPEDURATIONTYPE_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnLEAVETYPEDURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnLEAVETYPEDURATIONTYPE_BYDAY.ColumnName = columLEAVETYPEDURATIONTYPE_BYDAY;
                objColumnLEAVETYPEDURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueLEAVETYPEDURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {

                    var leaveDay = TotalData.listLeaveDayAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.LeaveDayTypeID == objAttendanceTableItem.LeaveTypeID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueLEAVETYPEDURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueLEAVETYPEDURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnLEAVETYPEDURATIONTYPE_BYDAY.ListValueByDay = listValueLEAVETYPEDURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnLEAVETYPEDURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.ExtraLeaveTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.EXTRALEAVETYPEDURATIONTYPE_BYDAY.ToString() + strMonthPre,
            }))
            {
                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columEXTRALEAVETYPEDURATIONTYPE_BYDAY = PayrollElementByDay.EXTRALEAVETYPEDURATIONTYPE_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnEXTRALEAVETYPEDURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPEDURATIONTYPE_BYDAY.ColumnName = columEXTRALEAVETYPEDURATIONTYPE_BYDAY;
                objColumnEXTRALEAVETYPEDURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPEDURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveDay = TotalData.listLeaveDayAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveTypeID).FirstOrDefault();
                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueEXTRALEAVETYPEDURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPEDURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnEXTRALEAVETYPEDURATIONTYPE_BYDAY.ListValueByDay = listValueEXTRALEAVETYPEDURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPEDURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.ExtraLeaveType3ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.EXTRALEAVETYPE3DURATIONTYPE_BYDAY.ToString() + strMonthPre,
            }))
            {
                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columEXTRALEAVETYPE3DURATIONTYPE_BYDAY = PayrollElementByDay.EXTRALEAVETYPE3DURATIONTYPE_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnEXTRALEAVETYPE3DURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE3DURATIONTYPE_BYDAY.ColumnName = columEXTRALEAVETYPE3DURATIONTYPE_BYDAY;
                objColumnEXTRALEAVETYPE3DURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE3DURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveDay = TotalData.listLeaveDayAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType3ID).FirstOrDefault();
                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueEXTRALEAVETYPE3DURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE3DURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnEXTRALEAVETYPE3DURATIONTYPE_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE3DURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE3DURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.ExtraLeaveType4ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.EXTRALEAVETYPE4DURATIONTYPE_BYDAY.ToString() + strMonthPre,
            }))
            {
                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columEXTRALEAVETYPE4DURATIONTYPE_BYDAY = PayrollElementByDay.EXTRALEAVETYPE4DURATIONTYPE_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnEXTRALEAVETYPE4DURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE4DURATIONTYPE_BYDAY.ColumnName = columEXTRALEAVETYPE4DURATIONTYPE_BYDAY;
                objColumnEXTRALEAVETYPE4DURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE4DURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveDay = TotalData.listLeaveDayAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType4ID).FirstOrDefault();
                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueEXTRALEAVETYPE4DURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE4DURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnEXTRALEAVETYPE4DURATIONTYPE_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE4DURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE4DURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.ExtraLeaveType5ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.EXTRALEAVETYPE5DURATIONTYPE_BYDAY.ToString() + strMonthPre,
            }))
            {
                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columEXTRALEAVETYPE5DURATIONTYPE_BYDAY = PayrollElementByDay.EXTRALEAVETYPE5DURATIONTYPE_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnEXTRALEAVETYPE5DURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE5DURATIONTYPE_BYDAY.ColumnName = columEXTRALEAVETYPE5DURATIONTYPE_BYDAY;
                objColumnEXTRALEAVETYPE5DURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE5DURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveDay = TotalData.listLeaveDayAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType5ID).FirstOrDefault();
                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueEXTRALEAVETYPE5DURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE5DURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnEXTRALEAVETYPE5DURATIONTYPE_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE5DURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE5DURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [20082018][97552] Thêm phần tử ngày:   Att_LeaveDay.DurationType của cột loại nghỉ Att_AttendanceTableItem.ExtraLeaveType6ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] {
                PayrollElementByDay.EXTRALEAVETYPE6DURATIONTYPE_BYDAY.ToString() + strMonthPre,
            }))
            {
                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }
                string columEXTRALEAVETYPE6DURATIONTYPE_BYDAY = PayrollElementByDay.EXTRALEAVETYPE6DURATIONTYPE_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnEXTRALEAVETYPE6DURATIONTYPE_BYDAY = new ColumnByDay();
                objColumnEXTRALEAVETYPE6DURATIONTYPE_BYDAY.ColumnName = columEXTRALEAVETYPE6DURATIONTYPE_BYDAY;
                objColumnEXTRALEAVETYPE6DURATIONTYPE_BYDAY.ValueType = strString;
                Dictionary<int, string> listValueEXTRALEAVETYPE6DURATIONTYPE_BYDAY = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var leaveDay = TotalData.listLeaveDayAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && s.Status == strLeaveDayStatus
                        && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                        && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                        && s.LeaveDayTypeID == objAttendanceTableItem.ExtraLeaveType6ID).FirstOrDefault();
                    var durationType = string.Empty;
                    if (leaveDay != null && !string.IsNullOrEmpty(leaveDay.DurationType))
                    {
                        durationType = leaveDay.DurationType;
                    }
                    if (!listValueEXTRALEAVETYPE6DURATIONTYPE_BYDAY.ContainsKey(indexRow))
                    {
                        listValueEXTRALEAVETYPE6DURATIONTYPE_BYDAY.Add(indexRow, durationType);
                    }
                    indexRow += 1;
                }
                objColumnEXTRALEAVETYPE6DURATIONTYPE_BYDAY.ListValueByDay = listValueEXTRALEAVETYPE6DURATIONTYPE_BYDAY;
                listColumnByDay.Add(objColumnEXTRALEAVETYPE6DURATIONTYPE_BYDAY);
            }
            #endregion

            #region Tung.Tran [03092018][0098109] WorkDate có tồn tại trong ngày nghỉ Cat_DayOff  ? (Trả về 1 or 0) (Chưa hỗ trợ true / false)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.ISHOLIDAYWORKDATE_BYDAY.ToString() + strMonthPre))
            {
                string columIsHoliday = PayrollElementByDay.ISHOLIDAYWORKDATE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = columIsHoliday;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var isDayOff = 0;

                    var dayOff = TotalDataAll.listDayOff.Where(a => a.DateOff != null && (a.DateOff.Date == objAttendanceTableItem.WorkDate.Date)).FirstOrDefault();
                    if (dayOff != null)
                    {
                        isDayOff = 1;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, isDayOff.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Công chuẩn theo ngày < Att_AttendanceTableItem.StdWorkDayCount >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.STDWORKDAYCOUNT_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.STDWORKDAYCOUNT_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double stdWorkDayCount = 0;
                    if (objAttendanceTableItem.StdWorkDayCount != null)
                    {
                        stdWorkDayCount = objAttendanceTableItem.StdWorkDayCount.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, stdWorkDayCount.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Số giờ đi làm tính lương < Att_AttendanceTableItem.WorkPaidHours >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.WORKPAIDHOURS_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.WORKPAIDHOURS_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.WorkPaidHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Số giờ nghỉ tính lương < Att_AttendanceTableItem.PaidLeaveHours >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.PAIDLEAVEHOURS_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.PAIDLEAVEHOURS_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.PaidLeaveHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Số giờ nghỉ không tính lương < Att_AttendanceTableItem.UnpaidLeaveHours >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.UNPAIDLEAVEHOURS_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.UNPAIDLEAVEHOURS_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.UnpaidLeaveHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Số phút muộn sớm < Att_AttendanceTableItem.LateEarlyMinutes >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.LATEEARLYMINUTES_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.LATEEARLYMINUTES_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.LateEarlyMinutes.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098136][Modify Func] Enum Số giờ ca đêm < Att_AttendanceTableItem.NightShiftHours >
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.NIGHTSHIFTHOURS_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.NIGHTSHIFTHOURS_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.NightShiftHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 1 : Att_AttendanceTableItem.OvertimeTypeID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMETYPECODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMETYPECODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overTimeCode = string.Empty;

                    if (objAttendanceTableItem.OvertimeTypeID != null && objAttendanceTableItem.OvertimeTypeID != Guid.Empty)
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.OvertimeTypeID).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 2 : Att_AttendanceTableItem.ExtraOvertimeTypeID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPECODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMETYPECODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overTimeCode = string.Empty;

                    if (objAttendanceTableItem.ExtraOvertimeTypeID != null && objAttendanceTableItem.ExtraOvertimeTypeID != Guid.Empty)
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.ExtraOvertimeTypeID).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 3 : Att_AttendanceTableItem.ExtraOvertimeType2ID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE2CODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE2CODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overTimeCode = string.Empty;

                    if (objAttendanceTableItem.ExtraOvertimeType2ID != null && objAttendanceTableItem.ExtraOvertimeType2ID != Guid.Empty)
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.ExtraOvertimeType2ID).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 4 : Att_AttendanceTableItem.ExtraOvertimeType3ID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE3CODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE3CODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overTimeCode = string.Empty;

                    if (objAttendanceTableItem.ExtraOvertimeType3ID != null && objAttendanceTableItem.ExtraOvertimeType3ID != Guid.Empty)
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.ExtraOvertimeType3ID).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Mã loại OT 5 : Att_AttendanceTableItem.ExtraOvertimeType4ID.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE4CODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE4CODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overTimeCode = string.Empty;

                    if (objAttendanceTableItem.ExtraOvertimeType4ID != null && objAttendanceTableItem.ExtraOvertimeType4ID != Guid.Empty)
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.ExtraOvertimeType4ID).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Số giờ OT 1: Att_AttendanceTableItem.OvertimeHours
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEHOURS_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMEHOURS_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.OvertimeHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Số giờ OT 2: Att_AttendanceTableItem.ExtraOvertimeHours
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMEHOURS_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMEHOURS_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.ExtraOvertimeHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Số giờ OT 3: Att_AttendanceTableItem.ExtraOvertimeHours2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMEHOURS2_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMEHOURS2_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.ExtraOvertimeHours2.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Số giờ OT 4: Att_AttendanceTableItem.ExtraOvertimeHours3
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMEHOURS3_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMEHOURS3_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, objAttendanceTableItem.ExtraOvertimeHours3.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Số giờ OT 5: Att_AttendanceTableItem.ExtraOvertimeHours4
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMEHOURS4_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.EXTRAOVERTIMEHOURS4_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double extraOvertimeHours4 = 0;

                    if (objAttendanceTableItem.ExtraOvertimeHours4 != null)
                    {
                        extraOvertimeHours4 = objAttendanceTableItem.ExtraOvertimeHours4.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, extraOvertimeHours4.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.InTime của loại OT Att_AttendanceTableItem.OvertimeTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMETYPEINTIME_BYDAY.ToString() + strMonthPre))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.OVERTIMETYPEINTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime = null;

                    var overTime = TotalData.listOverTimeAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.OvertimeTypeID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.OvertimeTypeID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.InTime != null)
                    {
                        inTime = overTime.InTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, inTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.InTime của loại OT Att_AttendanceTableItem.ExtraOvertimeTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPEINTIME_BYDAY.ToString() + strMonthPre))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPEINTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime = null;

                    var overTime = TotalData.listOverTimeAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeTypeID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeTypeID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.InTime != null)
                    {
                        inTime = overTime.InTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, inTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.InTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType2ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE2INTIME_BYDAY.ToString() + strMonthPre))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE2INTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime = null;

                    var overTime = TotalData.listOverTimeAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType2ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType2ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.InTime != null)
                    {
                        inTime = overTime.InTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, inTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.InTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType3ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE3INTIME_BYDAY.ToString() + strMonthPre))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE3INTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime = null;

                    var overTime = TotalData.listOverTimeAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType3ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType3ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.InTime != null)
                    {
                        inTime = overTime.InTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, inTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.InTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType4ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE4INTIME_BYDAY.ToString() + strMonthPre))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE4INTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime = null;

                    var overTime = TotalData.listOverTimeAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType4ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType4ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.InTime != null)
                    {
                        inTime = overTime.InTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, inTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.OutTime của loại OT Att_AttendanceTableItem.OvertimeTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMETYPEOUTTIME_BYDAY.ToString() + strMonthPre))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.OVERTIMETYPEOUTTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? outTime = null;

                    var overTime = TotalData.listOverTimeAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.OvertimeTypeID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.OvertimeTypeID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.OutTime != null)
                    {
                        outTime = overTime.OutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, outTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.OutTime của loại OT Att_AttendanceTableItem.ExtraOvertimeTypeID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPEOUTTIME_BYDAY.ToString() + strMonthPre))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPEOUTTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? outTime = null;

                    var overTime = TotalData.listOverTimeAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeTypeID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeTypeID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.OutTime != null)
                    {
                        outTime = overTime.OutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, outTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.OutTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType2ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE2OUTTIME_BYDAY.ToString() + strMonthPre))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE2OUTTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? outTime = null;

                    var overTime = TotalData.listOverTimeAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType2ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType2ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.OutTime != null)
                    {
                        outTime = overTime.OutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, outTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.OutTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType3ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE3OUTTIME_BYDAY.ToString() + strMonthPre))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE3OUTTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? outTime = null;

                    var overTime = TotalData.listOverTimeAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType3ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType3ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.OutTime != null)
                    {
                        outTime = overTime.OutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, outTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [05/09/2018][0098023][Modify Func] Lấy Att_Overtime.OutTime của loại OT Att_AttendanceTableItem.ExtraOvertimeType4ID
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EXTRAOVERTIMETYPE4OUTTIME_BYDAY.ToString() + strMonthPre))
            {

                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }


                string colum = PayrollElementByDay.EXTRAOVERTIMETYPE4OUTTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? outTime = null;

                    var overTime = TotalData.listOverTimeAll.Where(
                        s => s.ProfileID == profileItem.ID
                        && objAttendanceTableItem.ExtraOvertimeType4ID != null
                        && s.OvertimeTypeID == objAttendanceTableItem.ExtraOvertimeType4ID
                        && s.Status == strOTStatus
                        && ((s.WorkDateRoot != null && objAttendanceTableItem.WorkDate != null) && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date)
                        ).FirstOrDefault();

                    if (overTime != null && overTime.OutTime != null)
                    {
                        outTime = overTime.OutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, outTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran  [24/09/2018][0098656][Modify Func] ATT_WORKDAY.SRCTYPE  (ATTWORKDAYSRCTYPE_BYDAY)
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.ATTWORKDAYSRCTYPE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.ATTWORKDAYSRCTYPE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string srcType = string.Empty;
                    var objWorkDate = TotalData.listAttWorkdayAll.Where(
                    s => s.ProfileID == profileItem.ID
                    && s.WorkDate.Date == objAttendanceTableItem.WorkDate.Date
                    ).FirstOrDefault();
                    if (objWorkDate != null && !string.IsNullOrEmpty(objWorkDate.SrcType))
                    {
                        srcType = objWorkDate.SrcType;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, srcType.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/09/2018][98838][Modify Func] Enum mã chế độ công : Att_AttendanceTableItem.GradeAttendanceID.Code tương ứng từng ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.GRADEATTENDANCECODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.GRADEATTENDANCECODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string gradeAttendanceCode = string.Empty;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.GradeAttendanceID))
                    {
                        var objGradeAttendance = TotalDataAll.ListCat_GradeAttendance.Where(a => a.ID == objAttendanceTableItem.GradeAttendanceID).FirstOrDefault();
                        if (objGradeAttendance != null && !string.IsNullOrEmpty(objGradeAttendance.Code))
                        {
                            gradeAttendanceCode = objGradeAttendance.Code;
                        }
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, gradeAttendanceCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [29/09/2018][98920][Modify Func] Số phút muộn chuyên cần sau làm tròn: LateInMinutes2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.LATEINMINUTES2_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.LATEINMINUTES2_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double lateInMinutes2 = 0;
                    if (objAttendanceTableItem.LateInMinutes2 != null)
                    {
                        lateInMinutes2 = objAttendanceTableItem.LateInMinutes2.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, lateInMinutes2.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [29/09/2018][98920][Modify Func] Số phút muộn chuyên cần sau làm tròn: LateInMinutes2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.EARLYOUTMINUTES2_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.EARLYOUTMINUTES2_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double earlyOutMinutes2 = 0;
                    if (objAttendanceTableItem.EarlyOutMinutes2 != null)
                    {
                        earlyOutMinutes2 = objAttendanceTableItem.EarlyOutMinutes2.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, earlyOutMinutes2.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [29/09/2018][98920][Modify Func] Số phút muộn chuyên cần sau làm tròn: LateEarlyMinutes2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.LATEEARLYMINUTES2_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.LATEEARLYMINUTES2_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double lateEarlyMinutes2 = 0;
                    if (objAttendanceTableItem.LateEarlyMinutes2 != null)
                    {
                        lateEarlyMinutes2 = objAttendanceTableItem.LateEarlyMinutes2.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, lateEarlyMinutes2.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [15/10/2018][99513][Modify Func] Enum Giờ vào: FistInTime
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.FIRSTINTIME_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.FIRSTINTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? firstInTime = null;
                    if (objAttendanceTableItem.FirstInTime != null)
                    {
                        firstInTime = objAttendanceTableItem.FirstInTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, firstInTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [15/10/2018][99513][Modify Func] Enum Giờ vào: LastOutTime
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.LASTOUTTIME_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.LASTOUTTIME_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? lastOutTime = null;
                    if (objAttendanceTableItem.LastOutTime != null)
                    {
                        lastOutTime = objAttendanceTableItem.LastOutTime.Value;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, lastOutTime.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [16/10/2018][100008][Modify Func] Ngày thay đổi lương trong tháng : BASICSALARYDATEOFEFFECT_BYDAY
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.BASICSALARYDATEOFEFFECT_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.BASICSALARYDATEOFEFFECT_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                List<Sal_BasicSalaryEntity> SalaryProfile = new List<Sal_BasicSalaryEntity>();
                DateTime? dateChangeSalary = null;
                // Lấy lương cơ bản tương ứng của nhân viên
                SalaryProfile = TotalData.listBasicSalaryAll.Where(m => m.ProfileID == profileItem.ID && m.DateOfEffect <= CutOffDuration.DateEnd).OrderByDescending(m => m.DateOfEffect).ToList();
                // Kiểm tra có thay đổi lương hay không
                if (SalaryProfile != null && SalaryProfile.Any() && computePayrollSer.CheckIsChangeBasicSalary(TotalData.listBasicSalaryAll.Where(m => m.DateOfEffect <= CutOffDuration.DateEnd).ToList(), CutOffDuration.DateStart, CutOffDuration.DateEnd, profileItem.ID))
                {// Có thay đổi lương trong tháng
                    dateChangeSalary = SalaryProfile.FirstOrDefault().DateOfEffect; // Lấy ra ngày thay đổi lương
                }

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dateChangeSalary.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Mã loại OT OFF 1 Att_AttendanceTableItem.OvertimeOFFTypeID1.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFTYPE1CODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFTYPE1CODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var overTimeOffTypeCode = string.Empty;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.OvertimeOFFTypeID1))
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.OvertimeOFFTypeID1).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeOffTypeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeOffTypeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Mã loại OT OFF 2 Att_AttendanceTableItem.OvertimeOFFTypeID2.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFTYPE2CODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFTYPE2CODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var overTimeOffTypeCode = string.Empty;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.OvertimeOFFTypeID2))
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.OvertimeOFFTypeID2).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeOffTypeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeOffTypeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Mã loại OT OFF 3 Att_AttendanceTableItem.OvertimeOFFTypeID3.Code
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFTYPE3CODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFTYPE3CODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var overTimeOffTypeCode = string.Empty;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.OvertimeOFFTypeID3))
                    {
                        var objOverTimeType = TotalDataAll.listOvertimeTypeAll.Where(a => a.ID == objAttendanceTableItem.OvertimeOFFTypeID3).FirstOrDefault();
                        if (objOverTimeType != null)
                        {
                            overTimeOffTypeCode = objOverTimeType.Code;
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overTimeOffTypeCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func]  Số giờ OT OFF 1 : Att_AttendanceTableItem.OvertimeOFFHours1
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFHOURS1_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFHOURS1_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double overtimeOFFHours = 0;


                    if (objAttendanceTableItem.OvertimeOFFHours1 != null)
                    {
                        overtimeOFFHours = objAttendanceTableItem.OvertimeOFFHours1.Value;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func]  Số giờ OT OFF 2 : Att_AttendanceTableItem.OvertimeOFFHours2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFHOURS2_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFHOURS2_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double overtimeOFFHours = 0;


                    if (objAttendanceTableItem.OvertimeOFFHours2 != null)
                    {
                        overtimeOFFHours = objAttendanceTableItem.OvertimeOFFHours2.Value;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func]  Số giờ OT OFF 3 : Att_AttendanceTableItem.OvertimeOFFHours3
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFHOURS3_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFHOURS3_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double overtimeOFFHours = 0;


                    if (objAttendanceTableItem.OvertimeOFFHours3 != null)
                    {
                        overtimeOFFHours = objAttendanceTableItem.OvertimeOFFHours3.Value;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFHours.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Loại đăng ký OT 1: Att_AttendanceTableItem.OvertimeOFFDurationType1
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFDURATIONTYPE1_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFDURATIONTYPE1_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overtimeOFFDurationType = string.Empty;

                    if (!string.IsNullOrEmpty(objAttendanceTableItem.OvertimeOFFDurationType1))
                    {
                        overtimeOFFDurationType = objAttendanceTableItem.OvertimeOFFDurationType1;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFDurationType.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Loại đăng ký OT 1: Att_AttendanceTableItem.OvertimeOFFDurationType2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFDURATIONTYPE2_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFDURATIONTYPE2_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overtimeOFFDurationType = string.Empty;

                    if (!string.IsNullOrEmpty(objAttendanceTableItem.OvertimeOFFDurationType2))
                    {
                        overtimeOFFDurationType = objAttendanceTableItem.OvertimeOFFDurationType2;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFDurationType.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [26/10/2018][100089][Modify Func] Loại đăng ký OT 1: Att_AttendanceTableItem.OvertimeOFFDurationType3
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.OVERTIMEOFFDURATIONTYPE3_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.OVERTIMEOFFDURATIONTYPE3_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string overtimeOFFDurationType = string.Empty;

                    if (!string.IsNullOrEmpty(objAttendanceTableItem.OvertimeOFFDurationType3))
                    {
                        overtimeOFFDurationType = objAttendanceTableItem.OvertimeOFFDurationType3;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, overtimeOFFDurationType.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [03/11/2018][0100158][Modify Func] Enum DutyCode
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DUTYCODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.DUTYCODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string dutyCode = string.Empty;
                    if (!string.IsNullOrEmpty(objAttendanceTableItem.DutyCode))
                    {
                        dutyCode = objAttendanceTableItem.DutyCode;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dutyCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [14/11/2018][0100555][Modify Func] Enum đếm số ngày nghỉ từng ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.COUNTLEAVEDAY_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.COUNTLEAVEDAY_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                var strLeaveDayStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strLeaveDayStatus = objAllSetting.Value1;
                }

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double countLeaveDay = 0;
                    var lstLeaveDay = TotalData.listLeaveDayAll.Where(
                      s => s.ProfileID == profileItem.ID
                      && s.Status == strLeaveDayStatus
                      && ((s.DateStart != null && objAttendanceTableItem.WorkDate != null) && s.DateStart.Date <= objAttendanceTableItem.WorkDate.Date)
                      && ((s.DateEnd != null && objAttendanceTableItem.WorkDate != null) && s.DateEnd.Date >= objAttendanceTableItem.WorkDate.Date)
                      ).ToList();
                    if (lstLeaveDay != null)
                    {
                        countLeaveDay = lstLeaveDay.Count;
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, countLeaveDay.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [23/11/2018][101188][Modify Func] Enum lấy ca làm việc từ hàm GetdailyShift 
            // TH: Nhân viên nghỉ việc, nhân viên mới vào làm vẫn có ca làm việc nhưng tính công chưa lưu thông tin vào bảng công.
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.GETDAILYSHIFTCODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.GETDAILYSHIFTCODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();


                // Ds ca Roster theo profileID và kỳ công
                var listRosterByProfile = TotalData.listRosterAll.Where(m => m.ProfileID == profileItem.ID && m.DateStart <= CutOffDuration.DateEnd && m.DateEnd >= CutOffDuration.DateStart && m.Status == RosterStatus.E_APPROVED.ToString()).ToList();

                //DS RosterGroup của kỳ công
                var listRosterGroup = TotalData.ListRosterGroupAll.Where(s => s.Status == RosterStatus.E_APPROVED.ToString() && s.DateStart <= CutOffDuration.DateEnd && s.DateEnd >= CutOffDuration.DateStart).ToList();

                //Lịch làm việc của tháng N
                var lstDailyShift = Att_AttendanceLib.GetDailyShifts(
                    CutOffDuration.DateStart, 
                    CutOffDuration.DateEnd, 
                    profileItem.ID, 
                    listRosterByProfile,
                    listRosterGroup,
                    TotalDataAll.listRosterGroupByOrganization,
                    TotalDataAll.listRosterGroupType,
                    TotalDataAll.listOrgStructure,
                    TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID)
                            .Where(s => s.ProfileID == profileItem.ID
                            && s.DateEffective <= CutOffDuration.DateEnd
                            && s.Status == WorkHistoryStatus.E_APPROVED.ToString())
                            .FirstOrDefault());

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var shiftCode = string.Empty;
                    if (lstDailyShift.ContainsKey(objAttendanceTableItem.WorkDate) && lstDailyShift[objAttendanceTableItem.WorkDate] != null && lstDailyShift[objAttendanceTableItem.WorkDate].Count > 0)
                    {
                        try
                        {
                            // Lấy ca đầu tiên
                            var shiftID = lstDailyShift[objAttendanceTableItem.WorkDate][0];
                            var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(a => a.ID == shiftID);
                            if (objShift != null && objShift.Code != null)
                            {
                                shiftCode = objShift.Code;
                            }
                        }
                        catch (Exception ex)
                        {

                        }
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, shiftCode.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [06/12/2018][0101574] Phần tử ngày kiểm tra có tồn tại dòng chi phí hồ sơ (Chưa hỗ trợ true/false, dùng 1,0 để xác định)

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.UNUSUALALLOWANCE_COSTCV_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.UNUSUALALLOWANCE_COSTCV_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                string status = string.Empty;
                dataComputeSer.GetListSalUnusualAllowance(TotalData, CutOffDuration, ref status);
                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.UNUSUALALLOWANCE_COSTCV_BYDAY.ToString() + ") ";
                    int indexRow = 0;
                    for (int i = 0; i < totalRowInDataSoure; i++)
                    {
                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, 0.ToString());
                        }
                        indexRow += 1;
                    }
                }
                else
                {

                    var listUnusualAllowanceProfile = TotalData.dicSalUnusualAllowance.GetValueOrNew(profileItem.ID);

                    // Lấy danh sách loại phụ cấp chi phí hồ sơ
                    var listUnusualCfgCostCvIDs = TotalDataAll.listUnusualAllowanceCfg.Where(x => x.UnusualAllowanceGroup == UnusualAllowanceGroup.E_COSTCV.ToString()).Select(x => x.ID).ToArray(); ;

                    int indexRow = 0;
                    //gán dữ liệu cho từng ngày cho các enum
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        var isIncludeCostCV = 0;

                        var objUnusualCostCv = listUnusualAllowanceProfile.FirstOrDefault(x =>
                        x.ProfileID == profileItem.ID
                        && x.MonthStart != null && x.MonthEnd != null && !Common.IsNullOrGuidEmpty(x.UnusualEDTypeID)
                        && x.MonthStart.Value.Date <= objAttendanceTableItem.WorkDate.Date
                        && x.MonthEnd.Value.Date >= objAttendanceTableItem.WorkDate.Date
                        && listUnusualCfgCostCvIDs.Contains(x.UnusualEDTypeID.Value));

                        if (objUnusualCostCv != null)
                        {
                            isIncludeCostCV = 1;
                        }

                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, isIncludeCostCV.ToString());
                        }
                        indexRow += 1;
                    }
                }

                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [06/12/2018][0101574] Phần tử ngày lấy ra số giờ nghỉ giải lao của nhân viên trong ngày

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.SUMSHIFTBREAKHOUR_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.SUMSHIFTBREAKHOUR_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                // Lấy data nếu chưa được lấy trước đó
                string status = string.Empty;
                string nameTableGetData = "listCat_ShiftItem";
                if (!TotalData.dicTableGetDataCategory.ContainsKey(nameTableGetData))
                {
                    TotalData.listCat_ShiftItem = dataComputeSer.GetShiftItem(ShiftItemType.E_SHIFTBREAK.ToString(), ref status);
                    TotalData.dicTableGetDataCategory.Add(nameTableGetData, "");
                }

                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.SUMSHIFTBREAKHOUR_BYDAY.ToString() + ") ";
                    int indexRow = 0;
                    foreach (var objAttendanceTableItem in listAttendanceTableItem)
                    {
                        if (!listValue.ContainsKey(indexRow))
                        {
                            listValue.Add(indexRow, 0.ToString());
                        }
                        indexRow += 1;
                    }
                }
                else
                {
                    if (TotalData.listCat_ShiftItem.Count > 0)
                    {
                        #region Xử lý lấy dữ liệu
                        var listShiftID = TotalData.listCat_ShiftItem.Select(s => s.ShiftID).Distinct().ToList();

                        listShiftID = listAttendanceTableItem.Where(s => s.ShiftID != null).Select(s => s.ShiftID.Value).Distinct().ToList();
                        var listShiftItem = TotalData.listCat_ShiftItem.Where(s => listShiftID.Contains(s.ShiftID)).ToList();

                        var listLeaveDayInDate = TotalData.listLeaveDayAll
                            .Where(s => s.ProfileID == profileItem.ID
                                && s.DateStart <= CutOffDuration.DateEnd
                                && s.DateEnd >= CutOffDuration.DateStart)
                            .ToList();

                        var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_ANNUALDETAIL_LEAVEDAYSTATUS.ToString()).FirstOrDefault();
                        string statusLeaveday = string.Empty;
                        if (objAllSetting != null && !string.IsNullOrEmpty(objAllSetting.Value1))
                        {
                            statusLeaveday = objAllSetting.Value1;
                            listLeaveDayInDate = listLeaveDayInDate.Where(s => s.Status == statusLeaveday).ToList();
                        }
                        //lay ds ngày nghỉ sau khi tách ra từng ngày
                        Att_LeavedayServices leavedayServices = new Att_LeavedayServices();
                        var listLeaveDayForDate = new List<Att_LeaveDayEntity>();
                        if (listLeaveDayInDate.Count > 0)
                        {
                            var listRosterByPro = TotalData.listRosterAll.Where(s => s.ProfileID == profileItem.ID).ToList();
                            listLeaveDayForDate = leavedayServices.SplitLeaveByDayNotGetData(listLeaveDayInDate, ModifyType.E_EDIT.ToString(), listRosterByPro, TotalDataAll.ListRosterGroup.ToList(), TotalDataAll.listCat_Shift.ToList(), new List<Att_RosterGroupByOrganizationEntity>(), new List<Cat_RosterGroupTypeEntity>(), new List<Cat_OrgStructureEntity>(), new Dictionary<Guid, List<Hre_WorkHistoryEntity>>());
                        }

                        #endregion

                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {

                            double _SHIFTBREAK_HOUR = 0;

                            #region Xử lý tính thời gian nghỉ giải lao
                            if (objAttendanceTableItem.FirstInTime != null && objAttendanceTableItem.LastOutTime != null)
                            {
                                //neu có đăng ký nghỉ full ca => không tính giờ nghỉ ngày này
                                var countFULLSHIFT = listLeaveDayForDate
                                    .Where(s => s.DateStart.Date == objAttendanceTableItem.WorkDate.Date && s.DurationType == LeaveDayType.E_FULLSHIFT.ToString()).Count();
                                if (countFULLSHIFT == 0)
                                {
                                    DateTime firstInTime = objAttendanceTableItem.FirstInTime.Value;
                                    DateTime lastOutTime = objAttendanceTableItem.LastOutTime.Value;

                                    var objShift = TotalDataAll.listCat_Shift.Where(s => s.ID == objAttendanceTableItem.ShiftID).FirstOrDefault();
                                    if (objShift != null)
                                    {
                                        DateTime inTimeByShift = new DateTime(
                                                    objAttendanceTableItem.WorkDate.Year,
                                                    objAttendanceTableItem.WorkDate.Month,
                                                    objAttendanceTableItem.WorkDate.Day,
                                                    objShift.InTime.Hour,
                                                    objShift.InTime.Minute,
                                                    objShift.InTime.Second
                                                );

                                        DateTime outTimeByShift = inTimeByShift.AddHours(objShift.CoOut);

                                        var listShiftItemByWorkDate = listShiftItem.Where(s => s.ShiftID == objAttendanceTableItem.ShiftID).ToList();
                                        //có loại nghỉ trong ngày thi trừ giờ nghỉ nếu trùng
                                        if (listShiftItemByWorkDate.Count > 0)
                                        {
                                            //khong tru gio nghi giai lao khi nghi ngoai ca
                                            var listLeaveDayByWorkDate = listLeaveDayForDate
                                                .Where(s => s.DateStart.Date == objAttendanceTableItem.WorkDate
                                                    && s.DurationType != LeaveDayDurationType.E_FULLSHIFT.ToString()
                                                    && s.DurationType != LeaveDayDurationType.E_OUT_OF_SHIFT.ToString())
                                                .OrderBy(s => s.DateStart)
                                                .ToList();
                                            foreach (var objShiftItemByWorkDate in listShiftItemByWorkDate)
                                            {
                                                bool isCheck = true;
                                                DateTime dateFromShiftBreak = inTimeByShift.AddHours(objShiftItemByWorkDate.CoFrom);
                                                DateTime dateToShiftBreak = inTimeByShift.AddHours(objShiftItemByWorkDate.CoTo);

                                                //[19/12/2018][bang.nguyen][102046][bug]
                                                //logic ban dau tin.nguyen dua xu lý thiếu trường hợp ca đêm
                                                // đối với ca đêm xác định giờ nghỉ giữa ca => cộng thêm 1 ngày
                                                if (objShift.IsNightShift)
                                                {
                                                    if (objShiftItemByWorkDate.CoFrom < 0)
                                                    {
                                                        dateFromShiftBreak = dateFromShiftBreak.AddDays(1);
                                                    }
                                                    if (objShiftItemByWorkDate.CoTo < 0)
                                                    {
                                                        dateToShiftBreak = dateToShiftBreak.AddDays(1);
                                                    }
                                                }

                                                //không tính giờ nghỉ giải lao: neu giờ bắt đầu nghỉ <= giờ bắt đầu giữa ca và giờ kết thúc nghỉ >= giờ kết thúc giữa ca
                                                foreach (var objLeaveDayByWorkDate in listLeaveDayByWorkDate)
                                                {
                                                    DateTime dateStartLeave = objLeaveDayByWorkDate.DateStart;
                                                    DateTime dateEndLeave = objLeaveDayByWorkDate.DateEnd;
                                                    //neu datastart  ngay nghi nam ngoai in out của ca => + thêm 1 ngày 
                                                    if (objShift.IsNightShift)
                                                    {
                                                        if (dateStartLeave < inTimeByShift || dateStartLeave > outTimeByShift)
                                                        {
                                                            dateStartLeave = dateStartLeave.AddDays(1);
                                                        }
                                                        //neu dateend  ngay nghi nam ngoai in out của ca => + thêm 1 ngày 
                                                        if (dateEndLeave < inTimeByShift || dateEndLeave > outTimeByShift)
                                                        {
                                                            dateEndLeave = dateEndLeave.AddDays(1);
                                                        }
                                                    }

                                                    // neu giờ bắt đầu nghỉ <= giờ bắt đầu giữa ca và giờ kết thúc nghỉ >= giờ kết thúc giữa ca
                                                    //=> không được tính giờ nghỉ giải lao
                                                    if (dateStartLeave <= dateFromShiftBreak && dateEndLeave >= dateToShiftBreak)
                                                    {
                                                        isCheck = false;
                                                        break;
                                                    }
                                                }
                                                if (isCheck)
                                                {
                                                    //giờ quẹt thẻ vao ra có giao giờ giải lao => mới được tính giờ nghỉ giải lao ngày đó
                                                    if (firstInTime <= dateToShiftBreak && lastOutTime >= dateFromShiftBreak)
                                                    {
                                                        DateTime tempDateFrom = dateFromShiftBreak;
                                                        DateTime tempDateTo = dateToShiftBreak;
                                                        //giờ quẹt thẻ vao > giờ bắt đầu nghỉ giải lao
                                                        if (firstInTime > tempDateFrom)
                                                        {
                                                            tempDateFrom = firstInTime;
                                                        }
                                                        //giờ quẹt thẻ ra < giờ kết thúc nghỉ giải lao
                                                        if (lastOutTime < tempDateTo)
                                                        {
                                                            tempDateTo = lastOutTime;
                                                        }
                                                        _SHIFTBREAK_HOUR += (tempDateTo - tempDateFrom).TotalHours;
                                                        //nếu có giao => loại trừ khoảng giờ nghỉ có giao
                                                        double totalHourLeaveDay = 0;
                                                        foreach (var objLeaveDayByWorkDate in listLeaveDayByWorkDate)
                                                        {
                                                            DateTime dateStartLeave = objLeaveDayByWorkDate.DateStart;
                                                            DateTime dateEndLeave = objLeaveDayByWorkDate.DateEnd;
                                                            //neu datastart  ngay nghi nam ngoai in out của ca => + thêm 1 ngày 
                                                            if (objShift.IsNightShift)
                                                            {
                                                                if (dateStartLeave < inTimeByShift || dateStartLeave > outTimeByShift)
                                                                {
                                                                    dateStartLeave = dateStartLeave.AddDays(1);
                                                                }
                                                                //neu dateend  ngay nghi nam ngoai in out của ca => + thêm 1 ngày 
                                                                if (dateEndLeave < inTimeByShift || dateEndLeave > outTimeByShift)
                                                                {
                                                                    dateEndLeave = dateEndLeave.AddDays(1);
                                                                }
                                                            }
                                                            // có giao giữa giờ nghỉ giải lao và giờ nghỉ thì mới trừ
                                                            if (tempDateFrom <= dateEndLeave && tempDateTo >= dateStartLeave)
                                                            {
                                                                if (dateStartLeave < tempDateFrom)
                                                                {
                                                                    dateStartLeave = tempDateFrom;
                                                                }
                                                                if (dateEndLeave > tempDateTo)
                                                                {
                                                                    dateEndLeave = tempDateTo;
                                                                }
                                                                totalHourLeaveDay += (dateEndLeave - dateStartLeave).TotalHours;
                                                            }
                                                        }
                                                        if (totalHourLeaveDay >= 0)
                                                        {
                                                            _SHIFTBREAK_HOUR -= totalHourLeaveDay;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            #endregion

                            if (!listValue.ContainsKey(indexRow))
                            {
                                listValue.Add(indexRow, _SHIFTBREAK_HOUR.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                }

                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [22/12/2018][102060] Enum Loại chế độ từng ngày
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[] { PayrollElementByDay.PREGNANCYTYPE_BYDAY.ToString() + strMonthPre }))
            {
                string colum = PayrollElementByDay.PREGNANCYTYPE_BYDAY.ToString() + strMonthPre;

                ColumnByDay objColumnByDay = new ColumnByDay();
                objColumnByDay.ColumnName = colum;
                objColumnByDay.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    var pregnancyType = string.Empty;

                    if (!string.IsNullOrEmpty(objAttendanceTableItem.PregnancyType))
                    {
                        pregnancyType = objAttendanceTableItem.PregnancyType;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, pregnancyType);
                    }
                    indexRow += 1;
                }
                objColumnByDay.ListValueByDay = listValue;
                listColumnByDay.Add(objColumnByDay);
            }
            #endregion

            #region [24/12/2018][102024]: Enum giờ bắt đầu nghỉ ca 1
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.CATSHIFT_COBREAKIN_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.CATSHIFT_COBREAKIN_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? dateTimeCoBreakIn = null;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.ShiftID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null)
                        {
                            dateTimeCoBreakIn = objShift.InTime.AddHours(objShift.CoBreakIn);
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dateTimeCoBreakIn.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region [24/12/2018][102024]: Enum giờ bắt đầu nghỉ ca 2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.CATSHIFT2_COBREAKIN_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.CATSHIFT2_COBREAKIN_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? dateTimeCoBreakIn = null;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.Shift2ID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.Shift2ID);
                        if (objShift != null)
                        {
                            dateTimeCoBreakIn = objShift.InTime.AddHours(objShift.CoBreakIn);
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dateTimeCoBreakIn.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region [24/12/2018][102024]: Enum giờ kết thúc nghỉ ca 1
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.CATSHIFT_COBREAKOUT_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.CATSHIFT_COBREAKOUT_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? dateTimeCoBreakOut = null;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.ShiftID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null)
                        {
                            dateTimeCoBreakOut = objShift.InTime.AddHours(objShift.CoBreakOut);
                        }
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dateTimeCoBreakOut.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region [24/12/2018][102024]: Enum giờ kết thúc nghỉ ca 2
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.CATSHIFT2_COBREAKOUT_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.CATSHIFT2_COBREAKOUT_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDateTime;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? dateTimeCoBreakOut = null;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.Shift2ID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.Shift2ID);
                        if (objShift != null)
                        {
                            dateTimeCoBreakOut = objShift.InTime.AddHours(objShift.CoBreakOut);
                        }
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, dateTimeCoBreakOut.ToString());
                    }
                    indexRow += 1;
                }
                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [19/02/2019][102996]
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new[]
           {
                PayrollElementByDay.ATT_OVERTIMETYPE1_TAXTOTAL_BYDAY.ToString() + strMonthPre,
                PayrollElementByDay.ATT_OVERTIMETYPE2_TAXTOTAL_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMETYPE3_TAXTOTAL_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMETYPE4_TAXTOTAL_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMETYPE5_TAXTOTAL_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMEHOUR1_TAXTOTAL_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMEHOUR2_TAXTOTAL_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMEHOUR3_TAXTOTAL_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMEHOUR4_TAXTOTAL_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMEHOUR5_TAXTOTAL_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMETYPE1_TAXPROPORTION_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMETYPE2_TAXPROPORTION_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMETYPE3_TAXPROPORTION_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMETYPE4_TAXPROPORTION_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMETYPE5_TAXPROPORTION_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMEHOUR1_TAXPROPORTION_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMEHOUR2_TAXPROPORTION_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMEHOUR3_TAXPROPORTION_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMEHOUR4_TAXPROPORTION_BYDAY.ToString()+ strMonthPre,
                PayrollElementByDay.ATT_OVERTIMEHOUR5_TAXPROPORTION_BYDAY.ToString()+ strMonthPre,
            }
           ))
            {
                #region Get data
                var strOTStatus = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUS.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strOTStatus = objAllSetting.Value1;
                }

                //lay data nếu chưa được lấy trước đó
                string status = string.Empty;
                string nameTableGetData = "listOverTimeByDateApprove";
                if (!TotalData.dicTableGetDataByProfileIDs.ContainsKey(nameTableGetData))
                {
                    TotalData.listOverTimeByDateApprove = dataComputeSer.GetListOverTimeTimeLineByDateApprove(TotalData.strOrderByProfile, CutOffDuration, ref status);
                    TotalData.dicTableGetDataByProfileIDs.Add(nameTableGetData, "");
                }

                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông lưu store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.ATT_OVERTIMETYPE1_TAXTOTAL_BYDAY.ToString() + ") ";
                }
                #endregion
                else
                {
                    #region Khai báo


                    #region ATT_OVERTIMETYPE1_TAXTOTAL_BYDAY
                    ColumnByDay objColumnTypeTotal1 = new ColumnByDay();
                    objColumnTypeTotal1.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE1_TAXTOTAL_BYDAY.ToString() + strMonthPre;
                    objColumnTypeTotal1.ValueType = strString;
                    Dictionary<int, string> listValueTypeTotal1 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE2_TAXTOTAL_BYDAY
                    ColumnByDay objColumnTypeTotal2 = new ColumnByDay();
                    objColumnTypeTotal2.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE2_TAXTOTAL_BYDAY.ToString() + strMonthPre;
                    objColumnTypeTotal2.ValueType = strString;
                    Dictionary<int, string> listValueTypeTotal2 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE3_TAXTOTAL_BYDAY
                    ColumnByDay objColumnTypeTotal3 = new ColumnByDay();
                    objColumnTypeTotal3.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE3_TAXTOTAL_BYDAY.ToString() + strMonthPre;
                    objColumnTypeTotal3.ValueType = strString;
                    Dictionary<int, string> listValueTypeTotal3 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE4_TAXTOTAL_BYDAY
                    ColumnByDay objColumnTypeTotal4 = new ColumnByDay();
                    objColumnTypeTotal4.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE4_TAXTOTAL_BYDAY.ToString() + strMonthPre;
                    objColumnTypeTotal4.ValueType = strString;
                    Dictionary<int, string> listValueTypeTotal4 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE5_TAXTOTAL_BYDAY
                    ColumnByDay objColumnTypeTotal5 = new ColumnByDay();
                    objColumnTypeTotal5.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE5_TAXTOTAL_BYDAY.ToString() + strMonthPre;
                    objColumnTypeTotal5.ValueType = strString;
                    Dictionary<int, string> listValueTypeTotal5 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR1_TAXTOTAL_BYDAY
                    ColumnByDay objColumnHourTotal1 = new ColumnByDay();
                    objColumnHourTotal1.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR1_TAXTOTAL_BYDAY.ToString() + strMonthPre;
                    objColumnHourTotal1.ValueType = strDouble;
                    Dictionary<int, string> listValueHourTotal1 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR2_TAXTOTAL_BYDAY
                    ColumnByDay objColumnHourTotal2 = new ColumnByDay();
                    objColumnHourTotal2.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR2_TAXTOTAL_BYDAY.ToString() + strMonthPre;
                    objColumnHourTotal2.ValueType = strDouble;
                    Dictionary<int, string> listValueHourTotal2 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR3_TAXTOTAL_BYDAY
                    ColumnByDay objColumnHourTotal3 = new ColumnByDay();
                    objColumnHourTotal3.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR3_TAXTOTAL_BYDAY.ToString() + strMonthPre;
                    objColumnHourTotal3.ValueType = strDouble;
                    Dictionary<int, string> listValueHourTotal3 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR4_TAXTOTAL_BYDAY
                    ColumnByDay objColumnHourTotal4 = new ColumnByDay();
                    objColumnHourTotal4.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR4_TAXTOTAL_BYDAY.ToString() + strMonthPre;
                    objColumnHourTotal4.ValueType = strDouble;
                    Dictionary<int, string> listValueHourTotal4 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR5_TAXTOTAL_BYDAY
                    ColumnByDay objColumnHourTotal5 = new ColumnByDay();
                    objColumnHourTotal5.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR5_TAXTOTAL_BYDAY.ToString() + strMonthPre;
                    objColumnHourTotal5.ValueType = strDouble;
                    Dictionary<int, string> listValueHourTotal5 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE1_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnTypeProportion1 = new ColumnByDay();
                    objColumnTypeProportion1.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE1_TAXPROPORTION_BYDAY.ToString() + strMonthPre;
                    objColumnTypeProportion1.ValueType = strString;
                    Dictionary<int, string> listValueTypeProportion1 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE2_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnTypeProportion2 = new ColumnByDay();
                    objColumnTypeProportion2.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE2_TAXPROPORTION_BYDAY.ToString() + strMonthPre;
                    objColumnTypeProportion2.ValueType = strString;
                    Dictionary<int, string> listValueTypeProportion2 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE3_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnTypeProportion3 = new ColumnByDay();
                    objColumnTypeProportion3.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE3_TAXPROPORTION_BYDAY.ToString() + strMonthPre;
                    objColumnTypeProportion3.ValueType = strString;
                    Dictionary<int, string> listValueTypeProportion3 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE4_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnTypeProportion4 = new ColumnByDay();
                    objColumnTypeProportion4.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE4_TAXPROPORTION_BYDAY.ToString() + strMonthPre;
                    objColumnTypeProportion4.ValueType = strString;
                    Dictionary<int, string> listValueTypeProportion4 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMETYPE5_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnTypeProportion5 = new ColumnByDay();
                    objColumnTypeProportion5.ColumnName = PayrollElementByDay.ATT_OVERTIMETYPE5_TAXPROPORTION_BYDAY.ToString() + strMonthPre;
                    objColumnTypeProportion5.ValueType = strString;
                    Dictionary<int, string> listValueTypeProportion5 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR1_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnHourProportion1 = new ColumnByDay();
                    objColumnHourProportion1.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR1_TAXPROPORTION_BYDAY.ToString() + strMonthPre;
                    objColumnHourProportion1.ValueType = strDouble;
                    Dictionary<int, string> listValueHourProportion1 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR2_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnHourProportion2 = new ColumnByDay();
                    objColumnHourProportion2.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR2_TAXPROPORTION_BYDAY.ToString() + strMonthPre;
                    objColumnHourProportion2.ValueType = strDouble;
                    Dictionary<int, string> listValueHourProportion2 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR3_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnHourProportion3 = new ColumnByDay();
                    objColumnHourProportion3.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR3_TAXPROPORTION_BYDAY.ToString() + strMonthPre;
                    objColumnHourProportion3.ValueType = strDouble;
                    Dictionary<int, string> listValueHourProportion3 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR4_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnHourProportion4 = new ColumnByDay();
                    objColumnHourProportion4.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR4_TAXPROPORTION_BYDAY.ToString() + strMonthPre;
                    objColumnHourProportion4.ValueType = strDouble;
                    Dictionary<int, string> listValueHourProportion4 = new Dictionary<int, string>();
                    #endregion

                    #region ATT_OVERTIMEHOUR5_TAXPROPORTION_BYDAY
                    ColumnByDay objColumnHourProportion5 = new ColumnByDay();
                    objColumnHourProportion5.ColumnName = PayrollElementByDay.ATT_OVERTIMEHOUR5_TAXPROPORTION_BYDAY.ToString() + strMonthPre;
                    objColumnHourProportion5.ValueType = strDouble;
                    Dictionary<int, string> listValueHourProportion5 = new Dictionary<int, string>();
                    #endregion


                    var listOTGroup = TotalData.listOverTimeAllByDateApprove.Where(x => x.ProfileID == profileItem.ID
                                                && x.DateApprove != null
                                                && x.DateApprove.Value.Date >= CutOffDuration.DateStart.Date
                                                && x.DateApprove.Value.Date <= CutOffDuration.DateEnd.Date
                                                ).GroupBy(x => x.OvertimeTypeID).Select(x => x.Key).ToList();


                    #endregion

                    // Chỉ hỗ trợ 5 nhóm OT
                    int indexGroup = 1;
                    foreach (var itemGroup in listOTGroup.Take(5))
                    {

                        #region get Code
                        var overTimeCode = string.Empty;
                        var objOverTime = TotalDataAll.listOvertimeType.FirstOrDefault(x => x.ID == itemGroup);
                        if (objOverTime != null)
                        {
                            overTimeCode = objOverTime.Code;
                        }
                        #endregion

                        int indexRow = 0;
                        double sumOverTimeHourTotal = 0;
                        double sumOverTimeHourProportion = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {

                            #region E_TOTAL
                            var listOTProfileTaxByToTal = TotalData.listOverTimeAllByDateApprove.Where(
                                   x => x.ProfileID == profileItem.ID
                                   && x.OvertimeTypeID != null
                                   && x.DateApprove != null
                                   && x.DateApprove.Value.Date == objAttendanceTableItem.WorkDate.Date
                                   && x.Status == strOTStatus
                                   && x.TaxType == "E_TOTAL"
                                   ).ToList();

                            #region get sum Hour

                            if (strOTStatus == EnumDropDown.OverTimeStatus.E_APPROVED.ToString())
                            {
                                sumOverTimeHourTotal = listOTProfileTaxByToTal.Where(x => x.ApproveHours != null && x.OvertimeTypeID == itemGroup).Sum(x => x.ApproveHours.Value);
                            }
                            else if (strOTStatus == EnumDropDown.OverTimeStatus.E_CONFIRM.ToString())
                            {
                                sumOverTimeHourTotal = listOTProfileTaxByToTal.Where(x => x.OvertimeTypeID == itemGroup).Sum(x => x.ConfirmHours);
                            }
                            else if (strOTStatus == EnumDropDown.OverTimeStatus.E_SUBMIT.ToString())
                            {
                                sumOverTimeHourTotal = listOTProfileTaxByToTal.Where(x => x.OvertimeTypeID == itemGroup).Sum(x => x.RegisterHours);
                            }
                            #endregion

                            #region Set value
                            if (!listValueTypeTotal1.ContainsKey(indexRow) && indexGroup == 1)
                            {
                                listValueTypeTotal1.Add(indexRow, overTimeCode);
                                listValueHourTotal1.Add(indexRow, sumOverTimeHourTotal.ToString());
                            }
                            else if (!listValueTypeTotal2.ContainsKey(indexRow) && indexGroup == 2)
                            {
                                listValueTypeTotal2.Add(indexRow, overTimeCode);
                                listValueHourTotal2.Add(indexRow, sumOverTimeHourTotal.ToString());
                            }

                            else if (!listValueTypeTotal3.ContainsKey(indexRow) && indexGroup == 3)
                            {
                                listValueTypeTotal3.Add(indexRow, overTimeCode);
                                listValueHourTotal3.Add(indexRow, sumOverTimeHourTotal.ToString());
                            }
                            else if (!listValueTypeTotal4.ContainsKey(indexRow) && indexGroup == 4)
                            {
                                listValueTypeTotal4.Add(indexRow, overTimeCode);
                                listValueHourTotal4.Add(indexRow, sumOverTimeHourTotal.ToString());
                            }
                            else if (!listValueTypeTotal5.ContainsKey(indexRow) && indexGroup == 5)
                            {
                                listValueTypeTotal5.Add(indexRow, overTimeCode);
                                listValueHourTotal5.Add(indexRow, sumOverTimeHourTotal.ToString());
                            }
                            #endregion

                            #endregion

                            #region E_PROPORTION

                            var listOTProfileTaxByProportion = TotalData.listOverTimeAllByDateApprove.Where(
                                 x => x.ProfileID == profileItem.ID
                                 && x.OvertimeTypeID != null
                                 && x.DateApprove != null
                                 && x.DateApprove.Value.Date == objAttendanceTableItem.WorkDate.Date
                                 && x.Status == strOTStatus
                                 && x.TaxType == "E_PROPORTION"
                                 ).ToList();

                            #region get sum Hour

                            if (strOTStatus == EnumDropDown.OverTimeStatus.E_APPROVED.ToString())
                            {
                                sumOverTimeHourProportion = listOTProfileTaxByProportion.Where(x => x.ApproveHours != null && x.OvertimeTypeID == itemGroup).Sum(x => x.ApproveHours.Value);
                            }
                            else if (strOTStatus == EnumDropDown.OverTimeStatus.E_CONFIRM.ToString())
                            {
                                sumOverTimeHourProportion = listOTProfileTaxByProportion.Where(x => x.OvertimeTypeID == itemGroup).Sum(x => x.ConfirmHours);
                            }
                            else if (strOTStatus == EnumDropDown.OverTimeStatus.E_SUBMIT.ToString())
                            {
                                sumOverTimeHourProportion = listOTProfileTaxByProportion.Where(x => x.OvertimeTypeID == itemGroup).Sum(x => x.RegisterHours);
                            }
                            #endregion

                            #region Set value
                            if (!listValueTypeProportion1.ContainsKey(indexRow) && indexGroup == 1)
                            {
                                listValueTypeProportion1.Add(indexRow, overTimeCode);
                                listValueHourProportion1.Add(indexRow, sumOverTimeHourProportion.ToString());
                            }
                            else if (!listValueTypeProportion2.ContainsKey(indexRow) && indexGroup == 2)
                            {
                                listValueTypeProportion2.Add(indexRow, overTimeCode);
                                listValueHourProportion2.Add(indexRow, sumOverTimeHourProportion.ToString());
                            }
                            else if (!listValueTypeProportion3.ContainsKey(indexRow) && indexGroup == 3)
                            {
                                listValueTypeProportion3.Add(indexRow, overTimeCode);
                                listValueHourProportion3.Add(indexRow, sumOverTimeHourProportion.ToString());
                            }
                            else if (!listValueTypeProportion4.ContainsKey(indexRow) && indexGroup == 4)
                            {
                                listValueTypeProportion4.Add(indexRow, overTimeCode);
                                listValueHourProportion4.Add(indexRow, sumOverTimeHourProportion.ToString());
                            }
                            else if (!listValueTypeProportion5.ContainsKey(indexRow) && indexGroup == 5)
                            {
                                listValueTypeProportion5.Add(indexRow, overTimeCode);
                                listValueHourProportion5.Add(indexRow, sumOverTimeHourProportion.ToString());
                            }
                            #endregion

                            #endregion

                            indexRow += 1;
                        }
                        indexGroup++;
                    }

                    #region Set Value
                    objColumnTypeTotal1.ListValueByDay = listValueTypeTotal1;
                    listColumnByDay.Add(objColumnTypeTotal1);

                    objColumnTypeTotal2.ListValueByDay = listValueTypeTotal2;
                    listColumnByDay.Add(objColumnTypeTotal2);

                    objColumnTypeTotal3.ListValueByDay = listValueTypeTotal3;
                    listColumnByDay.Add(objColumnTypeTotal3);

                    objColumnTypeTotal4.ListValueByDay = listValueTypeTotal4;
                    listColumnByDay.Add(objColumnTypeTotal4);

                    objColumnTypeTotal5.ListValueByDay = listValueTypeTotal5;
                    listColumnByDay.Add(objColumnTypeTotal5);

                    objColumnHourTotal1.ListValueByDay = listValueHourTotal1;
                    listColumnByDay.Add(objColumnHourTotal1);

                    objColumnHourTotal2.ListValueByDay = listValueHourTotal2;
                    listColumnByDay.Add(objColumnHourTotal2);

                    objColumnHourTotal3.ListValueByDay = listValueHourTotal3;
                    listColumnByDay.Add(objColumnHourTotal3);

                    objColumnHourTotal4.ListValueByDay = listValueHourTotal4;
                    listColumnByDay.Add(objColumnHourTotal4);

                    objColumnHourTotal5.ListValueByDay = listValueHourTotal5;
                    listColumnByDay.Add(objColumnHourTotal5);


                    objColumnTypeProportion1.ListValueByDay = listValueTypeProportion1;
                    listColumnByDay.Add(objColumnTypeProportion1);

                    objColumnTypeProportion2.ListValueByDay = listValueTypeProportion2;
                    listColumnByDay.Add(objColumnTypeProportion2);

                    objColumnTypeProportion3.ListValueByDay = listValueTypeProportion3;
                    listColumnByDay.Add(objColumnTypeProportion3);

                    objColumnTypeProportion4.ListValueByDay = listValueTypeProportion4;
                    listColumnByDay.Add(objColumnTypeProportion4);

                    objColumnTypeProportion5.ListValueByDay = listValueTypeProportion5;
                    listColumnByDay.Add(objColumnTypeProportion5);

                    objColumnHourProportion1.ListValueByDay = listValueHourProportion1;
                    listColumnByDay.Add(objColumnHourProportion1);

                    objColumnHourProportion2.ListValueByDay = listValueHourProportion2;
                    listColumnByDay.Add(objColumnHourProportion2);

                    objColumnHourProportion3.ListValueByDay = listValueHourProportion3;
                    listColumnByDay.Add(objColumnHourProportion3);

                    objColumnHourProportion4.ListValueByDay = listValueHourProportion4;
                    listColumnByDay.Add(objColumnHourProportion4);

                    objColumnHourProportion5.ListValueByDay = listValueHourProportion5;
                    listColumnByDay.Add(objColumnHourProportion5);
                    #endregion
                }
            }

            #endregion

            #region Tung.Tran [26/03/2019][103784] Enum tính tổng số giờ tích lũy tăng ca theo từng ngày (Theo trạng thái tính lũy tiến)

            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.ATT_OVERTIME_PROGRESSIVE_BYDAY.ToString() + strMonthPre))
            {
                // Lấy cấu hình tính lũy tiến
                var strProgressive = string.Empty;
                var objAllSetting = TotalDataAll.listAllSettingEntity.Where(s => s.Name == AppConfig.HRM_ATT_OT_OVERTIMESTATUSPROGRESSIVE.ToString()).FirstOrDefault();
                if (objAllSetting != null)
                {
                    strProgressive = objAllSetting.Value1;
                }

                string colum = PayrollElementByDay.ATT_OVERTIME_PROGRESSIVE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strDouble;
                Dictionary<int, string> listValue = new Dictionary<int, string>();
                var arrayStatusCancel = new List<string>() { EnumDropDown.OverTimeStatus.E_CANCEL.ToString(), EnumDropDown.OverTimeStatus.E_REJECTED.ToString() };


                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double sumHoursOT = 0;

                    var listOverTime = TotalData.listOverTimeAll.Where(
                                       s => s.WorkDateRoot != null
                                       && s.ProfileID == profileItem.ID
                                       //[Hien.Le][02/04/2019] 0104336 Kiểm tra cấu hình trạng thái tính luỹ tiến là null
                                       && ((string.IsNullOrEmpty(strProgressive) && !arrayStatusCancel.Contains(s.Status))
                                          || (!string.IsNullOrEmpty(strProgressive) && strProgressive.Contains(s.Status)))
                                       && s.WorkDateRoot.Value.Date == objAttendanceTableItem.WorkDate.Date).ToList();

                    if (listOverTime != null && listOverTime.Count > 0)
                    {
                        listOverTime.ForEach(itemOverTime =>
                        {
                            if (itemOverTime.Status == "E_CONFIRM")
                            {
                                // Trạng thái xác nhận lấy cột ConfirmHours
                                sumHoursOT += itemOverTime.ConfirmHours;
                            }
                            else if (itemOverTime.Status == "E_APPROVED")
                            {
                                // Trạng thái duyệt lấy cột ApproveHours
                                sumHoursOT += itemOverTime.ApproveHours != null ? itemOverTime.ApproveHours.Value : 0;
                            }
                            else
                            {
                                // Ngược lại lấy cột RegisterHours
                                sumHoursOT += itemOverTime.RegisterHours;
                            }
                        });
                    }

                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, sumHoursOT.ToString());
                    }
                    indexRow += 1;
                }


                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }

            #endregion

            #region Tung.Tran [26/03/2019][103855]: Thêm phần tử lương ngày: nhóm nhân viên	
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.HR_WORKHISTORY_EMPLOYEEGROUPCODE_BYDAY.ToString() + strMonthPre))
            {
                string colum = PayrollElementByDay.HR_WORKHISTORY_EMPLOYEEGROUPCODE_BYDAY.ToString() + strMonthPre;
                ColumnByDay objColumn = new ColumnByDay();
                objColumn.ColumnName = colum;
                objColumn.ValueType = strString;
                Dictionary<int, string> listValue = new Dictionary<int, string>();

                int indexRow = 0;

                var listWorkHistory = TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID)
                            .Where(s => s.ProfileID == profileItem.ID && s.DateEffective <= CutOffDuration.DateEnd && s.Status == WorkHistoryStatus.E_APPROVED.ToString()).ToList();

                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    string codeEmployeeGroupCode = string.Empty;

                    var objWorkHistory = listWorkHistory.Where(s =>
                                         s.DateEffective <= objAttendanceTableItem.WorkDate.Date
                                         && s.Status == WorkHistoryStatus.E_APPROVED.ToString()).OrderByDescending(s => s.DateEffective).FirstOrDefault();

                    if (objWorkHistory != null && !string.IsNullOrEmpty(objWorkHistory.EmployeeGroupCode))
                    {
                        codeEmployeeGroupCode = objWorkHistory.EmployeeGroupCode;
                    }
                    if (!listValue.ContainsKey(indexRow))
                    {
                        listValue.Add(indexRow, codeEmployeeGroupCode);
                    }
                    indexRow += 1;
                }

                objColumn.ListValueByDay = listValue;
                listColumnByDay.Add(objColumn);
            }
            #endregion

            #region Tung.Tran [03/04/2019][0104014]
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[]
            {
                 PayrollElementByDay.LATECOUNT_BYDAY.ToString() + strMonthPre,
                 PayrollElementByDay.EARLYCOUNT_BYDAY.ToString()+ strMonthPre,
                 PayrollElementByDay.LATEEARLYCOUNT_BYDAY.ToString()+ strMonthPre,

            }))
            {
                ColumnByDay objColumnLateCount = new ColumnByDay();
                objColumnLateCount.ColumnName = PayrollElementByDay.LATECOUNT_BYDAY.ToString() + strMonthPre;
                objColumnLateCount.ValueType = strDouble;

                ColumnByDay objColumnEarlyCount = new ColumnByDay();
                objColumnEarlyCount.ColumnName = PayrollElementByDay.EARLYCOUNT_BYDAY.ToString() + strMonthPre;
                objColumnEarlyCount.ValueType = strDouble;

                ColumnByDay objColumnLateEarlyCount = new ColumnByDay();
                objColumnLateEarlyCount.ColumnName = PayrollElementByDay.LATEEARLYCOUNT_BYDAY.ToString() + strMonthPre;
                objColumnLateEarlyCount.ValueType = strDouble;

                Dictionary<int, string> listValueLateCount = new Dictionary<int, string>();
                Dictionary<int, string> listValueEarylyCount = new Dictionary<int, string>();
                Dictionary<int, string> listValueLateEarlyCount = new Dictionary<int, string>();

                int indexRow = 0;

                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    int lateCount = 0;
                    int earlyCount = 0;
                    int lateEarlyCount = 0;

                    if (objAttendanceTableItem.LateCount != null)
                    {
                        lateCount = objAttendanceTableItem.LateCount.Value;
                    }

                    if (objAttendanceTableItem.EarlyCount != null)
                    {
                        earlyCount = objAttendanceTableItem.EarlyCount.Value;
                    }

                    if (objAttendanceTableItem.LateEarlyCount != null)
                    {
                        lateEarlyCount = objAttendanceTableItem.LateEarlyCount.Value;
                    }


                    if (!listValueLateCount.ContainsKey(indexRow))
                    {
                        listValueLateCount.Add(indexRow, lateCount.ToString());
                        listValueEarylyCount.Add(indexRow, earlyCount.ToString());
                        listValueLateEarlyCount.Add(indexRow, lateEarlyCount.ToString());
                    }
                    indexRow += 1;
                }
                objColumnLateCount.ListValueByDay = listValueLateCount;
                listColumnByDay.Add(objColumnLateCount);

                objColumnEarlyCount.ListValueByDay = listValueEarylyCount;
                listColumnByDay.Add(objColumnEarlyCount);

                objColumnLateEarlyCount.ListValueByDay = listValueLateEarlyCount;
                listColumnByDay.Add(objColumnLateEarlyCount);
            }
            #endregion

            #region Hien.Le [04/04/2019][104191] Enum tính lương trường hợp đi làm đêm ngày thứ 7 sang chủ nhật
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, new string[]
         {
                    PayrollElementByDay.TYPEOFDATE_TRANSFER_BYDAY.ToString() + strMonthPre,
                    PayrollElementByDay.WORKINGNIGHTHOURSBEFORE_BYDAY.ToString()+ strMonthPre,
                    PayrollElementByDay.WORKINGNIGHTHOURSAFTER_BYDAY.ToString()+ strMonthPre,
         }))
            {
                ColumnByDay objColumnTypeOfTransfer = new ColumnByDay();
                objColumnTypeOfTransfer.ColumnName = PayrollElementByDay.TYPEOFDATE_TRANSFER_BYDAY.ToString() + strMonthPre;
                objColumnTypeOfTransfer.ValueType = strDouble;

                ColumnByDay objColumnWorkingNightHoursBefore = new ColumnByDay();
                objColumnWorkingNightHoursBefore.ColumnName = PayrollElementByDay.WORKINGNIGHTHOURSBEFORE_BYDAY.ToString() + strMonthPre;
                objColumnWorkingNightHoursBefore.ValueType = strDouble;

                ColumnByDay objColumnWorkingNightHoursAfter = new ColumnByDay();
                objColumnWorkingNightHoursAfter.ColumnName = PayrollElementByDay.WORKINGNIGHTHOURSAFTER_BYDAY.ToString() + strMonthPre;
                objColumnWorkingNightHoursAfter.ValueType = strDouble;

                Dictionary<int, string> listValueTypeOfTransfer = new Dictionary<int, string>();
                Dictionary<int, string> listValueWorkingNightHoursBefore = new Dictionary<int, string>();
                Dictionary<int, string> listValueWorkingNightHoursAfter = new Dictionary<int, string>();

                int indexRow = 0;

                //gán dữ liệu cho từng ngày cho các enum

                // Nếu có thay đổi => Phần tử đi tính
                var listRosterByProfile = TotalDataAll.dicRoster.GetValueOrNew(profileItem.ID).Where(m => m.DateStart <= CutOffDuration.DateEnd.AddDays(1) && m.DateEnd >= CutOffDuration.DateStart && m.Status == RosterStatus.E_APPROVED.ToString()).ToList();

                //rostergroup thang N
                var listRosterGroup = TotalDataAll.ListRosterGroup.Where(s => s.Status == RosterStatus.E_APPROVED.ToString() && s.DateStart <= CutOffDuration.DateEnd.AddDays(1) && s.DateEnd >= CutOffDuration.DateStart).ToList();

                // B2: Hàm này dùng để lấy ca làm việc của nhân viên từ ngày đến ngày truyền vào
                var lstDailyShift = Att_AttendanceLib.GetDailyShifts(
                    CutOffDuration.DateStart,
                    CutOffDuration.DateEnd.AddDays(1),
                    profileItem.ID,
                    listRosterByProfile,
                    listRosterGroup,
                    TotalDataAll.listRosterGroupByOrganization,
                    TotalDataAll.listRosterGroupType,
                    TotalDataAll.listOrgStructure,
                    TotalDataAll.dicWorkHistory.GetValueOrNew(profileItem.ID)
                            .Where(s => s.ProfileID == profileItem.ID
                            && s.DateEffective <= CutOffDuration.DateEnd
                            && s.Status == WorkHistoryStatus.E_APPROVED.ToString())
                            .FirstOrDefault());

                string[] listType = new string[]
                {
                     Infrastructure.Utilities.EnumDropDown.DayOffType.E_HOLIDAY.ToString(),
                     Infrastructure.Utilities.EnumDropDown.DayOffType.E_HOLIDAY_HLD.ToString(),
                };

                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double workingNightHoursBefore = 0;
                    double workingNightHoursAfter = 0;
                    int resultTypeOfDay = 0;

                    #region Set Today
                    var typeToDay = string.Empty;
                    var isHolidayToday = TotalDataAll.listDayOff.FirstOrDefault(
                                p => (p.DateOff.Date == objAttendanceTableItem.WorkDate.Date
                                          && listType.Contains(p.Type.ToString()))
                                         );
                    if (isHolidayToday != null)
                    {
                        // Ngày Lễ
                        typeToDay = "HOLIDAY";
                    }
                    else
                    {
                        // Ngày Thường
                        if (lstDailyShift.ContainsKey(objAttendanceTableItem.WorkDate)
                            && lstDailyShift[objAttendanceTableItem.WorkDate] != null
                            && lstDailyShift[objAttendanceTableItem.WorkDate].Count > 0)
                        {
                            typeToDay = "SHIFT_NORMALDAY";
                        }
                        else
                        {
                            typeToDay = "NOSHIFT_NORMALDAY";
                        }
                    }

                    #endregion

                    #region Set Tomorrow

                    var typeTomorrow = string.Empty;
                    var isHolidayTomorrow = TotalDataAll.listDayOff.FirstOrDefault(
                                        p => (p.DateOff.Date == objAttendanceTableItem.WorkDate.AddDays(1).Date
                                                && listType.Contains(p.Type.ToString()))
                                         );
                    if (isHolidayTomorrow != null)
                    {
                        // Ngày Lễ
                        typeTomorrow = "HOLIDAY";
                    }
                    else
                    {
                        // Ngày Thường
                        if (lstDailyShift.ContainsKey(objAttendanceTableItem.WorkDate.AddDays(1))
                            && lstDailyShift[objAttendanceTableItem.WorkDate.AddDays(1)] != null
                            && lstDailyShift[objAttendanceTableItem.WorkDate.AddDays(1)].Count > 0)
                        {
                            typeTomorrow = "SHIFT_NORMALDAY";
                        }
                        else
                        {
                            typeTomorrow = "NOSHIFT_NORMALDAY";
                        }
                    }
                    #endregion

                    // Từ ngày Thường (Có ca) -> Ngày Nghỉ (Ngày không ca) 
                    if (typeToDay == "SHIFT_NORMALDAY" && typeTomorrow == "NOSHIFT_NORMALDAY")
                    {
                        resultTypeOfDay = 1;
                    }
                    //•	Từ ngày Thường (Có ca) -> Ngày lễ
                    if (typeToDay == "SHIFT_NORMALDAY" && typeTomorrow == "HOLIDAY")
                    {
                        resultTypeOfDay = 2;
                    }
                    //•	Ngày Nghỉ (Ngày không ca) -> Từ ngày Thường (Có ca)
                    if (typeToDay == "NOSHIFT_NORMALDAY" && typeTomorrow == "SHIFT_NORMALDAY")
                    {
                        resultTypeOfDay = 3;
                    }
                    //•	Ngày Nghỉ (Ngày không ca)  -> Ngày lễ 
                    if (typeToDay == "NOSHIFT_NORMALDAY" && typeTomorrow == "HOLIDAY")
                    {
                        resultTypeOfDay = 4;
                    }
                    //•	Ngày lễ -> ngày Thường (Có ca)
                    if (typeToDay == "HOLIDAY" && typeTomorrow == "SHIFT_NORMALDAY")
                    {
                        resultTypeOfDay = 5;
                    }
                    //•	Ngày lễ -> Ngày Nghỉ (Ngày không ca) 
                    if (typeToDay == "HOLIDAY" && typeTomorrow == "NOSHIFT_NORMALDAY")
                    {
                        resultTypeOfDay = 6;
                    }
                    //================================================================
                    if (objAttendanceTableItem.WorkingNightHoursBefore != null)
                    {
                        workingNightHoursBefore = objAttendanceTableItem.WorkingNightHoursBefore.Value;
                    }
                    if (objAttendanceTableItem.WorkingNightHoursAfter != null)
                    {
                        workingNightHoursAfter = objAttendanceTableItem.WorkingNightHoursAfter.Value;
                    }

                    if (!listValueTypeOfTransfer.ContainsKey(indexRow))
                    {
                        listValueTypeOfTransfer.Add(indexRow, resultTypeOfDay.ToString());
                        listValueWorkingNightHoursBefore.Add(indexRow, workingNightHoursBefore.ToString());
                        listValueWorkingNightHoursAfter.Add(indexRow, workingNightHoursAfter.ToString());
                    }
                    indexRow += 1;
                }
                objColumnTypeOfTransfer.ListValueByDay = listValueTypeOfTransfer;
                listColumnByDay.Add(objColumnTypeOfTransfer);

                objColumnWorkingNightHoursBefore.ListValueByDay = listValueWorkingNightHoursBefore;
                listColumnByDay.Add(objColumnWorkingNightHoursBefore);

                objColumnWorkingNightHoursAfter.ListValueByDay = listValueWorkingNightHoursAfter;
                listColumnByDay.Add(objColumnWorkingNightHoursAfter);
            }

            #endregion

            #region Hien.Le [08/04/2019][0104519]:  Giờ bắt đầu 1, giờ kết thúc 1 , Giờ bắt đầu 2, giờ kết thúc 2

            // TH: Nhân viên nghỉ việc, nhân viên mới vào làm vẫn có ca làm việc nhưng tính công chưa lưu thông tin vào bảng công.
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula,
                new string[] {
                    PayrollElementByDay.SHIFT_INTIME1_BYDAY.ToString() + strMonthPre,
                    PayrollElementByDay.SHIFT_INTIME2_BYDAY.ToString() + strMonthPre,
                    PayrollElementByDay.SHIFT_OUTTIME1_BYDAY.ToString() + strMonthPre,
                    PayrollElementByDay.SHIFT_OUTTIME2_BYDAY.ToString() + strMonthPre,

                }))
            {
                ColumnByDay objColumnInTime1 = new ColumnByDay();
                objColumnInTime1.ColumnName = PayrollElementByDay.SHIFT_INTIME1_BYDAY.ToString() + strMonthPre;
                objColumnInTime1.ValueType = strDateTime;
                Dictionary<int, string> listValueInTime1 = new Dictionary<int, string>();

                ColumnByDay objColumnInTime2 = new ColumnByDay();
                objColumnInTime2.ColumnName = PayrollElementByDay.SHIFT_INTIME2_BYDAY.ToString() + strMonthPre;
                objColumnInTime2.ValueType = strDateTime;
                Dictionary<int, string> listValueInTime2 = new Dictionary<int, string>();

                ColumnByDay objColumnOutTime1 = new ColumnByDay();
                objColumnOutTime1.ColumnName = PayrollElementByDay.SHIFT_OUTTIME1_BYDAY.ToString() + strMonthPre;
                objColumnOutTime1.ValueType = strDateTime;
                Dictionary<int, string> listValueOutTime1 = new Dictionary<int, string>();

                ColumnByDay objColumnOutTime2 = new ColumnByDay();
                objColumnOutTime2.ColumnName = PayrollElementByDay.SHIFT_OUTTIME2_BYDAY.ToString() + strMonthPre;
                objColumnOutTime2.ValueType = strDateTime;
                Dictionary<int, string> listValueOutTime2 = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    DateTime? inTime1 = null;
                    DateTime? inTime2 = null;
                    DateTime? outTime1 = null;
                    DateTime? outTime2 = null;

                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.ShiftID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.ShiftID);
                        if (objShift != null)
                        {
                            inTime1 = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                    objAttendanceTableItem.WorkDate.Month,
                                    objAttendanceTableItem.WorkDate.Day,
                                    objShift.InTime.Hour,
                                    objShift.InTime.Minute,
                                    objShift.InTime.Second
                                    );

                            outTime1 = inTime1.Value.AddHours(objShift.CoOut);
                        }
                    }
                    if (!Common.IsNullOrGuidEmpty(objAttendanceTableItem.Shift2ID))
                    {
                        var objShift = TotalDataAll.listCat_Shift.FirstOrDefault(x => x.ID == objAttendanceTableItem.Shift2ID);
                        if (objShift != null)
                        {

                            inTime2 = new DateTime(objAttendanceTableItem.WorkDate.Year,
                                      objAttendanceTableItem.WorkDate.Month,
                                      objAttendanceTableItem.WorkDate.Day,
                                      objShift.InTime.Hour,
                                      objShift.InTime.Minute,
                                      objShift.InTime.Second
                                      );
                            outTime2 = inTime2.Value.AddHours(objShift.CoOut);
                        }
                    }
                    if (!listValueInTime1.ContainsKey(indexRow))
                    {
                        listValueInTime1.Add(indexRow, inTime1.ToString());
                        listValueOutTime1.Add(indexRow, outTime1.ToString());
                        listValueInTime2.Add(indexRow, inTime2.ToString());
                        listValueOutTime2.Add(indexRow, outTime2.ToString());
                    }
                    indexRow += 1;
                }
                objColumnInTime1.ListValueByDay = listValueInTime1;
                listColumnByDay.Add(objColumnInTime1);

                objColumnInTime2.ListValueByDay = listValueInTime2;
                listColumnByDay.Add(objColumnInTime2);

                objColumnOutTime1.ListValueByDay = listValueOutTime1;
                listColumnByDay.Add(objColumnOutTime1);

                objColumnOutTime2.ListValueByDay = listValueOutTime2;
                listColumnByDay.Add(objColumnOutTime2);
            }

            #endregion

            #region Hien.Le [22/04/2019] [0104658] Lấy enum lương đếm số phụ cấp ca 2 và ca 3 từ enum đã lấy lên trên bảng công
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula,
             new string[] {
                    PayrollElementByDay.ACTUALHOURSALLOWANCE_BYDAY.ToString() + strMonthPre,
             }))
            {
                ColumnByDay objColumnActualHoursAllowance = new ColumnByDay();
                objColumnActualHoursAllowance.ColumnName = PayrollElementByDay.ACTUALHOURSALLOWANCE_BYDAY.ToString() + strMonthPre;
                objColumnActualHoursAllowance.ValueType = strDouble;

                Dictionary<int, string> listValueActualHoursAllowance = new Dictionary<int, string>();

                int indexRow = 0;
                //gán dữ liệu cho từng ngày cho các enum
                foreach (var objAttendanceTableItem in listAttendanceTableItem)
                {
                    double actualHoursAllowance = 0;

                    if (objAttendanceTableItem.ActualHoursAllowance != null)
                    {
                        actualHoursAllowance = objAttendanceTableItem.ActualHoursAllowance.Value;
                    }

                    if (!listValueActualHoursAllowance.ContainsKey(indexRow))
                    {
                        listValueActualHoursAllowance.Add(indexRow, actualHoursAllowance.ToString());
                    }
                    indexRow += 1;
                }
                objColumnActualHoursAllowance.ListValueByDay = listValueActualHoursAllowance;
                listColumnByDay.Add(objColumnActualHoursAllowance);
            }
            #endregion

  

            #endregion

            #region Enum động
            #region tong gio nghi theo loai nghi 96183
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN9_SUM_LEAVEDAY_.ToString(), "_BYDAY" + strMonthPre))
            {
                var strStartsWith = PayrollElementByDay.DYN9_SUM_LEAVEDAY_.ToString();
                var strEndWith = "_BYDAY" + strMonthPre;
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeLeaveDayType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objLeaveDayType = TotalDataAll.listLeavedayType.FirstOrDefault(s => s.Code == codeLeaveDayType);
                    if (objLeaveDayType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumValue = 0;
                            if (objAttendanceTableItem.LeaveTypeID == objLeaveDayType.ID && objAttendanceTableItem.LeaveDays != null)
                            {
                                sumValue += objAttendanceTableItem.LeaveDays.Value;
                            }
                            if (objAttendanceTableItem.ExtraLeaveTypeID == objLeaveDayType.ID && objAttendanceTableItem.ExtraLeaveDays != null)
                            {
                                sumValue += objAttendanceTableItem.ExtraLeaveDays.Value;
                            }
                            if (objAttendanceTableItem.LeaveWorkDayType == objLeaveDayType.ID && objAttendanceTableItem.LeaveWorkDayDays != null)
                            {
                                sumValue += objAttendanceTableItem.LeaveWorkDayDays.Value;
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumValue.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region tong gio tang ca theo loai ot 96518
            //[09/07/2018][bang.nguyen][96518][Modify Func]
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN10_SUM_OVERTIMEHOURS_.ToString(), "_BYDAY" + strMonthPre))
            {
                var strStartsWith = PayrollElementByDay.DYN10_SUM_OVERTIMEHOURS_.ToString();
                var strEndWith = "_BYDAY" + strMonthPre;
                //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeOverTimeType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objOverTimeType = TotalDataAll.listOvertimeType.FirstOrDefault(s => s.Code == codeOverTimeType);
                    if (objOverTimeType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumOverTimeHour = 0;
                            if (objAttendanceTableItem.OvertimeTypeID == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.OvertimeHours;
                            }
                            if (objAttendanceTableItem.ExtraOvertimeTypeID == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.ExtraOvertimeHours;
                            }
                            if (objAttendanceTableItem.ExtraOvertimeType2ID == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.ExtraOvertimeHours2;
                            }
                            if (objAttendanceTableItem.ExtraOvertimeType3ID == objOverTimeType.ID)
                            {
                                sumOverTimeHour += objAttendanceTableItem.ExtraOvertimeHours3;
                            }
                            if (objAttendanceTableItem.ExtraOvertimeType4ID == objOverTimeType.ID && objAttendanceTableItem.ExtraOvertimeHours4 != null)
                            {
                                sumOverTimeHour += objAttendanceTableItem.ExtraOvertimeHours4.Value;
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumOverTimeHour.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region Tung.Tran [16/10/2018][100008][Modify Func] Enum động Tổng ActualHours từng ngày (Att_ProfileTimeSheet.ActualHours theo Cat_JobType.Code) 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN12_SUM_ACTUALHOURS_.ToString(), "_BYDAY" + strMonthPre))
            {
                var strStartsWith = PayrollElementByDay.DYN12_SUM_ACTUALHOURS_.ToString();
                var strEndWith = "_BYDAY" + strMonthPre;
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                foreach (var formulaitem in ListFormula)
                {
                    string formulaItemTemp = formulaitem.Replace(" ", "");

                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaItemTemp;
                    objColumnByDay.ValueType = strDouble;

                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                    var codeJobType = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                    var objJobType = TotalDataAll.listCat_JobType.Where(s => s.Code == codeJobType).FirstOrDefault();
                    if (objJobType != null)
                    {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double sumActualHours = 0;

                            var listTimeSheetByDate = TotalData.ListAtt_ProfileTimeSheetAll.Where(
                            x => x.ActualHours != null
                            && x.JobTypeID != null
                            && x.WorkDate != null
                            && x.WorkDate.Value.Date == objAttendanceTableItem.WorkDate.Date
                            && x.ProfileID == profileItem.ID
                            && x.JobTypeID == objJobType.ID).ToList();

                            if (listTimeSheetByDate != null)
                            {
                                sumActualHours = listTimeSheetByDate.Sum(x => x.ActualHours.Value);
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, sumActualHours.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion

            #region Tung.Tran [20/10/2018][99473][Modify Func] Tổng số tiền phụ cấp từng ngày theo loại phụ cấp: DYN13_UNUSUALALLOWANCE_SUM_AMOUNT_ + "Cat_UnusualAllowanceCfg.Code" + _BYDAY
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN13_UNUSUALALLOWANCE_SUM_AMOUNT_.ToString(), "_BYDAY" + strMonthPre))
            {

                var strStartsWith = PayrollElementByDay.DYN13_UNUSUALALLOWANCE_SUM_AMOUNT_.ToString();
                var strEndWith = "_BYDAY" + strMonthPre;
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();

                string status = string.Empty;
                dataComputeSer.GetListSalUnusualAllowance(TotalData, CutOffDuration, ref status);
                //truong hợp store lỗi => các phần tử lấy từ nguồn này sẽ = 0 và thông báo store lỗi
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.UNUSUALALLOWANCE_COSTCV_BYDAY.ToString() + ") ";

                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");

                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;
                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
                else
                {
                    var listUnusualAllowanceProfile = TotalData.dicSalUnusualAllowance.GetValueOrNew(profileItem.ID);

                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");

                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;

                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                        var unusualAllowanceCfgCode = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                        var objUnusualAllowanceCfg = TotalDataAll.listUnusualAllowanceCfg.Where(s => s.Code == unusualAllowanceCfgCode).FirstOrDefault();

                        if (objUnusualAllowanceCfg != null)
                        {
                            int indexRow = 0;
                            foreach (var objAttendanceTableItem in listAttendanceTableItem)
                            {
                                double sumAmount = 0;
                                var listSalUnusualAllowanceByProfile = listUnusualAllowanceProfile.Where(
                                            x => x.ProfileID == profileItem.ID
                                            && x.IsFollowDay == true
                                            && (x.MonthStart != null && x.MonthStart.Value.Date <= objAttendanceTableItem.WorkDate.Date)
                                            && (x.MonthEnd != null && x.MonthEnd.Value.Date >= objAttendanceTableItem.WorkDate.Date)
                                            && x.UnusualEDTypeID == objUnusualAllowanceCfg.ID
                                            ).ToList();

                                if (listSalUnusualAllowanceByProfile != null && listSalUnusualAllowanceByProfile.Any())
                                {
                                    sumAmount = listSalUnusualAllowanceByProfile.Where(x => x.Amount != null).Sum(x => x.Amount.Value);
                                }

                                if (!listValueByDay.ContainsKey(indexRow))
                                {
                                    listValueByDay.Add(indexRow, sumAmount.ToString());
                                }
                                indexRow += 1;
                            }
                        }
                        else
                        {
                            for (int i = 0; i < totalRowInDataSoure; i++)
                            {
                                if (!listValueByDay.ContainsKey(i))
                                {
                                    listValueByDay.Add(i, "0");
                                }
                            }
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
            }
            #endregion

            #region Tung.Tran [05/12/2018][101500] Enum động Số tiền phụ cấp động theo chức vụ 
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN16_POSITION_USUALALLOWANCEGROUP_.ToString(), "_BYDAY" + strMonthPre))
            {

                //Lấy All dữ liệu danh mục chi tiết thiết bị
                string status = string.Empty;
                var nameTableGetData = "listUsualAllowanceGroup";
                if (!TotalData.dicTableGetDataCategory.ContainsKey(nameTableGetData))
                {
                    TotalData.listUsualAllowanceGroup = dataComputeSer.GetUsualAllowanceGroup(ref status);
                    TotalData.dicTableGetDataCategory.Add(nameTableGetData, "");
                }
                if (!string.IsNullOrEmpty(status))
                {
                    TotalData.statusBugStore += status + " (" + PayrollElementByDay.DYN16_POSITION_USUALALLOWANCEGROUP_.ToString() + ") ";
                }
                else
                {
                    var strStartsWith = PayrollElementByDay.DYN16_POSITION_USUALALLOWANCEGROUP_.ToString();
                    var strEndWith = "_BYDAY" + strMonthPre;
                    List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndWith)).Distinct().ToList();
                    foreach (var formulaitem in ListFormula)
                    {
                        string formulaItemTemp = formulaitem.Replace(" ", "");

                        ColumnByDay objColumnByDay = new ColumnByDay();
                        objColumnByDay.ColumnName = formulaItemTemp;
                        objColumnByDay.ValueType = strDouble;
                        Dictionary<int, string> listValueByDay = new Dictionary<int, string>();

                        // Lấy ra mã loại phụ cấp cấu hình
                        var unusualAllowanceCode = formulaItemTemp.Replace(strStartsWith, "").Replace(strEndWith, "").Replace(" ", "");
                        // Lấy thông tin Loại phụ cấp theo mã
                        var objUnusualAllowance = TotalDataAll.listUsualAllowance.FirstOrDefault(s => s.Code == unusualAllowanceCode);

                        if (objUnusualAllowance != null)
                        {
                            int indexRow = 0;
                            foreach (var objAttendanceTableItem in listAttendanceTableItem)
                            {
                                double sumAmount = 0;

                                // For từng ngày công kiểm tra có chức vụ thì xử lý 
                                if (objAttendanceTableItem != null && !Common.IsNullOrGuidEmpty(objAttendanceTableItem.PositionID))
                                {
                                    var objPosition = TotalDataAll.listPosition.FirstOrDefault(x => x.ID == objAttendanceTableItem.PositionID);
                                    if (objPosition != null && !string.IsNullOrEmpty(objPosition.UsualAllowanceGroupID))
                                    {
                                        //Hien.Le [19/02/2020] 0112318: điều chỉnh một số màn hình bên lương có control nhóm phụ cấp load theo chức vụ
                                        var listUsualAllowanceGroupID = new List<string>();
                                        listUsualAllowanceGroupID = objPosition.UsualAllowanceGroupID.Split(",").ToList();
                                        foreach (var itemUsualAllowanceGroupID in listUsualAllowanceGroupID)
                                        {
                                            var sGuidUsualAllowanceGroupID = Guid.Parse(itemUsualAllowanceGroupID);
                                            var objUsualAllowanceGroup = TotalData.listUsualAllowanceGroup.Where(
                                            x => x.ID == sGuidUsualAllowanceGroupID
                                            && (
                                            x.AllowanceTypeID1 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID2 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID3 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID4 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID5 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID6 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID7 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID8 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID9 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID10 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID11 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID12 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID13 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID14 == objUnusualAllowance.ID ||
                                            x.AllowanceTypeID15 == objUnusualAllowance.ID
                                            )).FirstOrDefault();
                                            if (objUsualAllowanceGroup != null)
                                            {
                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID1)
                                                    && objUsualAllowanceGroup.AllowanceTypeID1 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount1 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount1.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID2)
                                                   && objUsualAllowanceGroup.AllowanceTypeID2 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount2 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount2.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID3)
                                                   && objUsualAllowanceGroup.AllowanceTypeID3 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount3 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount3.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID4)
                                                   && objUsualAllowanceGroup.AllowanceTypeID4 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount4 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount4.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID5)
                                                   && objUsualAllowanceGroup.AllowanceTypeID5 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount5 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount5.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID6)
                                                   && objUsualAllowanceGroup.AllowanceTypeID6 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount6 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount6.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID7)
                                                   && objUsualAllowanceGroup.AllowanceTypeID7 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount7 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount7.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID8)
                                                   && objUsualAllowanceGroup.AllowanceTypeID8 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount8 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount8.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID9)
                                                   && objUsualAllowanceGroup.AllowanceTypeID9 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount9 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount9.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID10)
                                                   && objUsualAllowanceGroup.AllowanceTypeID10 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount10 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount10.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID11)
                                                   && objUsualAllowanceGroup.AllowanceTypeID11 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount11 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount11.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID12)
                                                   && objUsualAllowanceGroup.AllowanceTypeID12 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount12 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount12.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID13)
                                                   && objUsualAllowanceGroup.AllowanceTypeID13 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount13 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount13.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID14)
                                                   && objUsualAllowanceGroup.AllowanceTypeID14 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount14 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount14.Value;
                                                }

                                                if (!Common.IsNullOrGuidEmpty(objUsualAllowanceGroup.AllowanceTypeID15)
                                                   && objUsualAllowanceGroup.AllowanceTypeID15 == objUnusualAllowance.ID && objUsualAllowanceGroup.AllowanceAmount15 != null)
                                                {
                                                    sumAmount += objUsualAllowanceGroup.AllowanceAmount15.Value;
                                                }
                                            }
                                        }
                                    }
                                }

                                if (!listValueByDay.ContainsKey(indexRow))
                                {
                                    listValueByDay.Add(indexRow, sumAmount.ToString());
                                }
                                indexRow += 1;
                            }
                        }
                        else
                        {
                            for (int i = 0; i < totalRowInDataSoure; i++)
                            {
                                if (!listValueByDay.ContainsKey(i))
                                {
                                    listValueByDay.Add(i, "0");
                                }
                            }
                        }
                        objColumnByDay.ListValueByDay = listValueByDay;
                        listColumnByDay.Add(objColumnByDay);
                        //xoa cac enum da xu ly trong list enum tong
                        formula.Remove(formulaitem);
                    }
                }
            }
            #endregion

            #region nghia.dang 127483 [22/05/2021] Phần tử lương theo ngày động trả ra số giờ
            if (computePayrollSer.CheckIsExistFormula(listElementFormulaByDay, ref formula, PayrollElementByDay.DYN63_ATT_ATTENDANCETABLEITEM_BY_LEAVEDAYTYPE_.ToString(), "_BYDAY" + strMonthPre))
            {
                var strStartsWith = PayrollElementByDay.DYN63_ATT_ATTENDANCETABLEITEM_BY_LEAVEDAYTYPE_.ToString();
                var strEndsWith = "_BYDAY" + strMonthPre;
                //lấy các phần tử cần lấy dữ liệu
                List<string> ListFormula = formula.Where(m => m.StartsWith(strStartsWith) && m.EndsWith(strEndsWith)).Distinct().ToList();

                foreach (var formulaitem in ListFormula)
                {
                    ColumnByDay objColumnByDay = new ColumnByDay();
                    objColumnByDay.ColumnName = formulaitem;
                    objColumnByDay.ValueType = strDouble;
                    Dictionary<int, string> listValueByDay = new Dictionary<int, string>();
                    var code = formulaitem.Replace(strStartsWith, "").Replace(strEndsWith, "").Replace(" ", "");
                    // Lấy thông tin Loại phụ cấp theo mã
                    var objLeavedayType = TotalDataAll.listLeavedayType.Where(s => s.Code == code).FirstOrDefault();
                    if (objColumnByDay != null) {
                        int indexRow = 0;
                        foreach (var objAttendanceTableItem in listAttendanceTableItem)
                        {
                            double? valueSum = 0;
                            if (objAttendanceTableItem.LeaveTypeID != null && objAttendanceTableItem.LeaveTypeID == objLeavedayType.ID)
                            {
                                valueSum += objAttendanceTableItem.LeaveHours;
                            }
                            if (objAttendanceTableItem.ExtraLeaveTypeID != null && objAttendanceTableItem.ExtraLeaveTypeID == objLeavedayType.ID)
                            {
                                valueSum += objAttendanceTableItem.ExtraLeaveHours;
                            }
                            if (objAttendanceTableItem.ExtraLeaveType3ID != null && objAttendanceTableItem.ExtraLeaveType3ID == objLeavedayType.ID)
                            {
                                valueSum += objAttendanceTableItem.ExtraLeaveHours3;
                            }
                            if (objAttendanceTableItem.ExtraLeaveType4ID != null && objAttendanceTableItem.ExtraLeaveType4ID == objLeavedayType.ID)
                            {
                                valueSum += objAttendanceTableItem.ExtraLeaveHours4;
                            }
                            if (objAttendanceTableItem.ExtraLeaveType5ID != null && objAttendanceTableItem.ExtraLeaveType5ID == objLeavedayType.ID)
                            {
                                valueSum += objAttendanceTableItem.ExtraLeaveHours5;
                            }
                            if (objAttendanceTableItem.ExtraLeaveType6ID != null && objAttendanceTableItem.ExtraLeaveType6ID == objLeavedayType.ID)
                            {
                                valueSum += objAttendanceTableItem.ExtraLeaveHours6;
                            }
                            if (!listValueByDay.ContainsKey(indexRow))
                            {
                                listValueByDay.Add(indexRow, valueSum.ToString());
                            }
                            indexRow += 1;
                        }
                    }
                    else
                    {
                        for (int i = 0; i < totalRowInDataSoure; i++)
                        {
                            if (!listValueByDay.ContainsKey(i))
                            {
                                listValueByDay.Add(i, "0");
                            }
                        }
                    }
                    objColumnByDay.ListValueByDay = listValueByDay;
                    listColumnByDay.Add(objColumnByDay);
                    //xoa cac enum da xu ly trong list enum tong
                    formula.Remove(formulaitem);
                }
            }
            #endregion
            #endregion

            #region Tạo cấu trúc bảng
            //bang sẽ chứa all các cột làm enum cho công thức mảng
            //mỗi 1 cột sẽ là 1 logic để lấy giá trị trả về cho từng ngày
            DataTable dataSource = new DataTable();

            //add all cột
            foreach (var columnByDay in listColumnByDay)
            {
                string columnName = columnByDay.ColumnName;
                if (!dataSource.Columns.Contains(columnName))
                {
                    if (columnByDay.ValueType == strDouble)
                    {
                        dataSource.Columns.Add(columnName, typeof(Double));
                    }
                    else if (columnByDay.ValueType == strDateTime)
                    {
                        dataSource.Columns.Add(columnName, typeof(DateTime));
                    }
                    else
                    {
                        dataSource.Columns.Add(columnName);
                    }
                }
            }

            //gán dữ liệu cho các cột
            for (int i = 0; i < totalRowInDataSoure; i++)
            {
                DataRow row = dataSource.NewRow();
                foreach (var columnByDay in listColumnByDay)
                {
                    string columnName = columnByDay.ColumnName;
                    string valueString = string.Empty;
                    if (columnByDay.ListValueByDay.Keys.Contains(i))
                    {
                        valueString = columnByDay.ListValueByDay[i];
                    }
                    if (columnByDay.ValueType == strDouble)
                    {
                        if (!string.IsNullOrEmpty(valueString))
                        {
                            double valueDouble = 0;
                            row[columnName] = valueDouble;
                            if (Double.TryParse(valueString, out valueDouble))
                            {
                                row[columnName] = valueDouble;
                            }
                        }
                    }
                    else if (columnByDay.ValueType == strDateTime)
                    {
                        if (!string.IsNullOrEmpty(valueString))
                        {
                            DateTime valueDateTime = DateTime.MinValue;
                            row[columnName] = valueDateTime;
                            if (DateTime.TryParse(valueString, out valueDateTime))
                            {
                                row[columnName] = valueDateTime;
                            }
                        }
                    }
                    else
                    {
                        row[columnName] = valueString;
                    }
                }
                dataSource.Rows.Add(row);
            }
            #endregion

            //bang chua all các cột làm enum tính
            var elementFormulaDataSource = new ElementFormula
            {
                VariableName = "Source",
                OrderNumber = 0,
                Value = dataSource
            };
            //ds all enum trong source
            TotalData.listAllColumnInSource = dataSource.Columns.Cast<DataColumn>().Select(x => x.ColumnName).ToList();
            listElementFormulaByDay.Add(elementFormulaDataSource);
            return listElementFormulaByDay;
        }


        #endregion
    }
}
