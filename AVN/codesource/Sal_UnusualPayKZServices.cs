using HRM.Business.Attendance.Models;
using HRM.Business.Category.Models;
using HRM.Business.Hr.Models;
using HRM.Business.Main.Domain;
using HRM.Business.Payroll.Models;
using HRM.Data.BaseRepository;
using HRM.Data.Entity;
using HRM.Infrastructure.Utilities;
using HRM.Infrastructure.Utilities.Helper;
using System;
using System.Collections.Generic;
using System.Linq;
using VnResource.Helper.Data;
using System.Text;
using System.Threading.Tasks;
using HRM.Business.Hr.Domain;
using VnResource.Helper.Linq;
using VnResource.Helper.Ado;
using VnResource.AdoHelper;
using System.Threading;
using VnResource.Helper.Setting;
using HRM.Business.Insurance.Models;
using System.Data.Entity.Validation;
using HRM.Business.Category.Domain;
using HRM.Business.HrmSystem.Domain;
using System.Configuration;

namespace HRM.Business.Payroll.Domain
{ 
    public class Sal_UnusualPayKZServices : BaseService
    {
        /// <summary>
        ///  /// Tung.Tran [30/05/2019][106096] : Kaizen tốc độ xử lý màn hình Tính Tạm ứng
        /// </summary>
        /// <param name="isIncludeWorkingEmp"></param>
        /// <param name="IsStopWorking"></param>
        /// <param name="strOrg"></param>
        /// <param name="gradeid"></param>
        /// <param name="monthYear"></param>
        /// <param name="dateofpayment"></param>
        /// <param name="amount"></param>
        /// <param name="Notes"></param>
        /// <param name="money"></param>
        /// <param name="payrollGroup"></param>
        /// <param name="strProfileID"></param>
        /// <param name="UnusualPayCondition"></param>
        /// <param name="userLogin"></param>
        /// <returns></returns>
        public Sal_ComputePayrollEntity UnusualPayInProcess(
            bool isIncludeWorkingEmp,
            bool IsStopWorking,
            string strOrg,
            Guid gradeid,
            Guid CutOffDurationID,
            DateTime dateofpayment,
            double amount,
            string Notes,
            bool money,
            string payrollGroup,
            string strProfileID,
            double? UnusualPayCondition,
            string userLogin)
        {
            using (var context = new VnrHrmDataContext())
            {
                #region Khởi tạo
                var listKeyLog = new List<string>() { DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"), DateTime.Now.ToString("yyyyMMddHHmmss") };

                LogHelper _logger = new LogHelper("ProcessPayroll\\UnusualPayroll\\UnusualPayroll" + listKeyLog[1],
                                    "UnusualPayroll - " + listKeyLog[0],
                                    base.UserLogin);

                _logger.WriteInfo("UnusualPayroll", "======> BẮT ĐẦU TÍNH TẠM ỨNG", new
                {
                    data = string.Format("{0} / {1}  Tính Nghỉ Việc / {2} Tính Đang Làm Việc ",
                           UserLogin,
                           IsStopWorking == true ? "Có" : "Không",
                           isIncludeWorkingEmp == true ? "Có" : "Không")
                });

                var swatch = new System.Diagnostics.Stopwatch();
                swatch.Start();

                var unitOfWork = (IUnitOfWork)new UnitOfWork(context);
                var repoAsynTask = new CustomBaseRepository<Sys_AsynTask>(unitOfWork);
                Sys_AsynTask asynTask = new Sys_AsynTask()
                {
                    ID = Guid.NewGuid(),
                    Status = AsynTaskStatus.Doing.ToString(),
                    TimeStart = DateTime.Now,
                    PercentComplete = 0.01,
                    Type = AsynTask.Payroll_Computing_UnusualPaySalary.ToString(),
                };

                repoAsynTask.Add(asynTask);
                unitOfWork.SaveChanges();
                #endregion

                try
                {
                    #region Lọc các điều kiện

                    string type1 = AppConfig.HRM_SAL_UNUSUALPAY_DAYKEEPUNUSUALPAY.ToString();
                    string type2 = AppConfig.HRM_SAL_UNUSUALPAY_CONDITIONUNUSUALPAY.ToString();
                    string type3 = AppConfig.HRM_SAL_UNUSUALPAY_PAYROLLCONFIG.ToString();
                    string type4 = AppConfig.HRM_SAL_UNUSUALPAY_UNUSUALMETHOD.ToString();
                    string type5 = AppConfig.HRM_SAL_UNUSUALPAY_ISLOCKCOMPUTER.ToString();
                    string type6 = AppConfig.HRM_SAL_ELEMENT_UNUSUALPAY.ToString();
                    string configRealWorkDayPay = AppConfig.HRM_SAL_ELEMENT_UNUSUAL_REALWORKDAYPAY.ToString();
                    string configHireInMonth = AppConfig.HRM_SAL_COMPUTEADVANCEPAYMENT_DATEHIRE_INMONTH.ToString();
                    string configQuitInMonth = AppConfig.HRM_SAL_COMPUTEADVANCEPAYMENT_DATEQUIT_INMONTH.ToString();
                    string degreeOfParallelism = AppConfig.HRM_ATT_WORKDAY_SUMMARY_PROCESSPARTICIPATECOMPUTEWORKDAY.ToString();


                    var lstappConfig = unitOfWork.CreateQueryable<Sys_AllSetting>(sy => sy.IsDelete == null && (
                           sy.Name == configRealWorkDayPay
                        || sy.Name == type1
                        || sy.Name == type2
                        || sy.Name == type3
                        || sy.Name == type4
                        || sy.Name == type5
                        || sy.Name == type6
                        || sy.Name == configHireInMonth
                        || sy.Name == configQuitInMonth
                        || sy.Name == degreeOfParallelism
                        )).ToList();
                    var config5 = lstappConfig.Where(s => s.Name == type5).FirstOrDefault();
                  
                    if (!string.IsNullOrEmpty(config5.Value1) && bool.TrueString.ToUpper() == config5.Value1.ToUpper())
                    {
                        return new Sal_ComputePayrollEntity() { Status = ConstantDisplay.HRM_Payroll_Lock_UnusualPay.TranslateString() };
                    }
                 
                    Att_CutOffDurationEntity Cutoffduration = unitOfWork.CreateQueryable<Att_CutOffDuration>(Guid.Empty, m => m.ID== CutOffDurationID).FirstOrDefault().Copy<Att_CutOffDurationEntity>(); //Kỳ lương 
                  
                    // Tung.Tran [16/05/2019] [105571]: Đưa ra thông báo trường hợp không có dữ liệu kỳ công
                    if (Cutoffduration == null)
                    {
                        return new Sal_ComputePayrollEntity() { Status = ConstantDisplay.HRM_Payroll_UnusualPay_CutOffDurationIsNull.TranslateString() };
                    }

                    //Hien.Nguyen
                    //Lọc nhân viên theo quá trình công tác
                    Hre_ProfileServices HrServices = new Hre_ProfileServices();

                    
                    var lstProfile = HrServices.FilterProfileForComputeSalary(
                        null,
                        null,
                        null,
                        strOrg,
                        strProfileID,
                        string.Empty,
                        payrollGroup,
                        null,
                        isIncludeWorkingEmp,
                        IsStopWorking,
                        UserLogin,
                        Cutoffduration.DateStart,
                        Cutoffduration.DateEnd,
                        null,
                        null,
                        false,
                        ObjectStorePermission.Sal_UnusualPay);

                    //HienNguyen-13102015-58168
                    //Loại bỏ những NV mới vào làm trong tháng và nghỉ việc trong tháng
                    if (Cutoffduration != null)
                    {
                        //[29/06/2017][bang.nguyen][84681][Modify Func]
                        //khi co cau hinh:Cho phép tính tạm ứng cho NV vào làm trong tháng và nghỉ việc trong tháng
                        //[28/08/2018][tung.tran][97762][Modify Func]
                        // Tách cấu hình tính tạm ứng cho NV vào làm trong tháng và nghỉ việc trong tháng ra 2 cấu hình riêng biệt
                        var objConfigHireInMonth = lstappConfig.Where(s => s.Name == configHireInMonth).FirstOrDefault();
                        var objConfigQuitInMonth = lstappConfig.Where(s => s.Name == configQuitInMonth).FirstOrDefault();

                        #region Vào làm trong tháng
                        if (objConfigHireInMonth != null && objConfigHireInMonth.Value1 != null && bool.TrueString.ToUpper() == objConfigHireInMonth.Value1.ToUpper())
                        {
                            // [28/08/2018][tung.tran][97762][Modify Func] Ưu tiên DateHireNew
                            foreach (var profile in lstProfile)
                            {
                                if (profile.DateHire != null)
                                    profile.DateHireTemp = profile.DateHire;
                                if (profile.DatehireNew != null)
                                    profile.DateHireTemp = profile.DatehireNew;
                            }
                            // Lấy nhân viên vào làm trong tháng và trước đó
                            lstProfile = lstProfile.Where(m => m.DateHireTemp.HasValue && m.DateHireTemp <= Cutoffduration.DateEnd).ToList();
                        }
                        else
                        {
                            // [28/08/2018][tung.tran][97762][Modify Func] Ưu tiên DateHireNew
                            foreach (var profile in lstProfile)
                            {
                                if (profile.DateHire != null)
                                    profile.DateHireTemp = profile.DateHire;
                                if (profile.DatehireNew != null)
                                    profile.DateHireTemp = profile.DatehireNew;
                            }
                            // Loại bỏ nhân viên mới vào làm trong tháng
                            lstProfile = lstProfile.Where(m => m.DateHireTemp.HasValue && m.DateHireTemp < Cutoffduration.DateStart).ToList();
                        }
                        #endregion

                        #region Nghỉ việc trong tháng
                        if (objConfigQuitInMonth != null && objConfigQuitInMonth.Value1 != null && bool.TrueString.ToUpper() == objConfigQuitInMonth.Value1.ToUpper())
                        {
                            // Loại bỏ những nhân viên nghỉ việc trước đó
                            lstProfile = lstProfile.Where(m => m.DateQuit == null || !(m.DateQuit != null && m.DateQuit.Value < Cutoffduration.DateStart)).ToList();
                        }
                        else
                        {
                            // Loại bỏ những nv có ngày nghỉ việc trong tháng
                            lstProfile = lstProfile.Where(m => m.DateQuit == null || !(m.DateQuit.Value >= Cutoffduration.DateStart && m.DateQuit.Value <= Cutoffduration.DateEnd)).ToList();
                        }
                        #endregion
                    }
                    Sys_AttOvertimePermitConfigServices Sys_Services = new Sys_AttOvertimePermitConfigServices();
                    string ElementConfig = Sys_Services.GetConfigValue<string>(AppConfig.HRM_SAL_UNUSUALPAY_DAYKEEPUNUSUALPAY);
                    int numberKeep = 0;
                    if (!string.IsNullOrEmpty(ElementConfig))
                        numberKeep = int.Parse(ElementConfig);
                    DateTime date = this.convertdatemonthyear(numberKeep, Cutoffduration.MonthYear);
                    if (date < Cutoffduration.DateStart)
                    {
                        date = date.AddMonths(1);
                    }
                    lstProfile = lstProfile.Where(x => x.DateHire != null && x.DateHire.Value.Date <= date.Date).ToList();
                    //nghia.dang [131922] [21/8/2021] : Main, Tạm ứng lương, loại trừ không tính tạm ứng cho Nhân viên nghỉ việc <= ngày chốt ứng => Ngày nghỉ viêc DateQuit = null hoặc > date.Date
                    lstProfile = lstProfile.Where(x => x.DateQuit == null || x.DateQuit.Value.Date > date.Date).ToList();
                    var listProfileID = lstProfile.Select(s => s.ID).Distinct().ToList();


                    //Lấy các nhân viên theo chế độ lương
                    if (gradeid != Guid.Empty)
                    {
                        var listProfileIDByGrade = new List<Guid>();
                        var salgradeQuery = unitOfWork.CreateQueryable<Sal_Grade>(Guid.Empty, s => s.GradePayrollID == gradeid && s.MonthStart <= Cutoffduration.MonthYear);
                        foreach (var profileids in listProfileID.Chunk(2000))
                        {
                            listProfileIDByGrade.AddRange(salgradeQuery.Where(s => profileids.Contains(s.ProfileID)).Select(s => s.ProfileID).ToList());
                        }
                        lstProfile = lstProfile.Where(hr => listProfileIDByGrade.Contains(hr.ID)).ToList();
                        listProfileID = lstProfile.Select(s => s.ID).ToList();
                    }
                    
                    //Lương CB
                    ////[03/11/2017][0089191: Điều chỉnh logic tính tạm ứng]
                    var salbasicQuery = unitOfWork.CreateQueryable<Sal_BasicSalary>(Guid.Empty, sal => sal.DateOfEffect <= Cutoffduration.DateEnd);
                    var lstBasicSal = new List<Sal_BasicSalary>();
                    foreach (var profileids in listProfileID.Chunk(2000))
                    {
                        lstBasicSal.AddRange(salbasicQuery.Where(s => profileids.Contains(s.ProfileID)).ToList());
                    }
                    listProfileID = lstBasicSal.Select(s => s.ProfileID).Distinct().ToList();
                    lstProfile = lstProfile.Where(hr => listProfileID.Contains(hr.ID)).ToList();

                    listProfileID = lstProfile.Select(s => s.ID).ToList();

                    var keyForCacheUtility = KeyForCacheUtility.COMPUTE_SALARYUNUSUALPAY.ToString();
                    var monthYearName = Cutoffduration.MonthYear.Month.ToString() + Cutoffduration.MonthYear.Year.ToString();
                    var keyMOnthYear = monthYearName + "-" + DateTime.Now.Ticks;
                    var list = CacheUtilityService.Get<List<Sal_UnusualPayMonthYearEntity>>(keyForCacheUtility);
                    if (list == null)
                    {
                        list = new List<Sal_UnusualPayMonthYearEntity>();
                        CacheUtilityService.AddOrUpdate(keyForCacheUtility, list);
                    }
                    var checkExists = list.Where(p => p.KeyMonthYear.StartsWith(monthYearName + "-"))
                         .Any(p => p.ListProfileID.Intersect(listProfileID).Any());

                    //Check Exists
                    if (checkExists)
                    {
                        return new Sal_ComputePayrollEntity() { Status = ConstantDisplay.HRM_SAL_YesWhoComputeAdvancepayment_PleaseWait.TranslateString() };
                    }
                    #endregion

                    _logger.WriteInfo("UnusualPayroll", "======> LẤY THÔNG TIN NHÂN VIÊN", new
                    {
                        Time = swatch.Elapsed.ToString(),
                    });

                    #region Nghia.Dang [16/8/2021][131739] : Xử lý tính lương kiểm tra ràng buộc phải khóa công mới được tính lương
                    List<Type> typeAtt = new List<Type> { typeof(Att_AttendanceTable) };
                    lstProfile = CheckLockAttenanceComputePayroll(
                        typeAtt,
                        null,
                        null,
                        SysLockObjectType: SysLockObjectType.E_LOCKOBJECT.ToString(),
                        CutOffDuration: Cutoffduration,
                        listProfileID: lstProfile
                        );
                    listProfileID = lstProfile.Select(s => s.ID).ToList();
                    #endregion

                    if (lstProfile.Count <= 0)
                    {
                        return new Sal_ComputePayrollEntity() { Status = ConstantDisplay.HRM_Common_Employees_AreNotEligibleForSalary_Calculation.TranslateString() };
                    }
                    

                    #region Tung.Tran [12/07/2021][129902]: Apply khóa đối tượng chức năng tính tạm ứng
                    //Tung.Tran [11/07/2021][129901]: Dùng hàm chung khóa đối tượng (Apply khóa chi tiết nhân viên)
                    var listPayrollGroupCheckLock = lstProfile.Where(s => s.WH_PayrollGroupID != null).Select(s => s.WH_PayrollGroupID.Value).ToList();
                    var listWorkPlaceCheckLock = lstProfile.Where(s => s.WH_WorkPlaceID != null).Select(s => s.WH_WorkPlaceID.Value).ToList();
                    var listOrgCheckLock = lstProfile.Where(s => s.WH_OrganizationStructureID != null).Select(s => s.WH_OrganizationStructureID.Value).ToList();

                    List<Type> types = new List<Type> { typeof(Sal_UnusualPay) };
                    var baseService = new BaseService();
                    var isLockedObject = baseService.CheckLockObject(
                        types,
                        null,
                        null,
                        listOrgCheckLock,
                        listPayrollGroupCheckLock,
                        listWorkPlaceCheckLock,
                        SysLockObjectType: SysLockObjectType.E_LOCKOBJECT.ToString(),
                        CutOffDurationID: CutOffDurationID,
                        listProfileID: lstProfile.Select(m => m.ID).ToList()
                        );

                    if (isLockedObject.IsLockObject)
                    {
                        return new Sal_ComputePayrollEntity() { Status = ConstantDisplay.HRM_Payroll_Lock_UnusualPay.TranslateString() };
                    }
                    #endregion

                    swatch.Restart();

                    asynTask.Summary = ConstantDisplay.HRM_Sal_UnusualPay_ComputingUnusualPay.TranslateString() + "_" + listProfileID.Count().ToString();
                    repoAsynTask.Edit(asynTask);
                    repoAsynTask.SaveChanges();

                    Thread thread = new Thread(() => ProcessUnusualPay(
                                                     _logger,
                                                     listKeyLog,
                                                     lstBasicSal,
                                                     lstappConfig,
                                                     lstProfile,
                                                     listProfileID,
                                                     Cutoffduration,
                                                     dateofpayment,
                                                     amount, Notes,
                                                     money,
                                                     payrollGroup,
                                                     UnusualPayCondition,
                                                     userLogin,
                                                     asynTask));
                    thread.Start();
                    return new Sal_ComputePayrollEntity() { CaculateHistoryID = asynTask.ID, ThreadRun = thread };
                }
                catch (Exception ex)
                {
                    ResultsObject resultObject = new ResultsObject();
                    asynTask.PercentComplete = 1D;
                    asynTask.TimeEnd = DateTime.Now;
                    asynTask.Status = AsynTaskStatus.Done.ToString();
                    repoAsynTask.Edit(asynTask);
                    unitOfWork.SaveChanges();

                    _logger.WriteError("UnusualPayroll", "======> LỖI, KẾT THÚC TÍNH TẠM ỨNG", new
                    {
                        innerException = ex.InnerException,
                        exeption = ex.Message + "; " + ex.StackTrace,
                    });

                    return new Sal_ComputePayrollEntity()
                    {
                        CaculateHistoryID = asynTask.ID,
                        Status = ConstantDisplay.HRM_Payroll_ErrorInProcessing.TranslateString()
                    };
                }
            }
        }

        public List<Hre_ProfileEntity> CheckLockAttenanceComputePayroll(List<Type> entityTypes, DateTime? dateStart, DateTime? dateEnd,string SysLockObjectType = null, Att_CutOffDurationEntity CutOffDuration = null, List<Hre_ProfileEntity> listProfileID = null)
        {
            using (var dbContext = new VnrHrmDataContext())
            {
                bool result = false;
                var unitOfWork = new UnitOfWork(dbContext);
                string approvedStatus = LockObjectStatus.E_APPROVED.ToString();
                dateStart = dateStart.HasValue ? dateStart : dateEnd;
                dateEnd = dateEnd.HasValue ? dateEnd : dateStart;
                var lstEntityType = new List<string>();
                var listHreProfileReturn = new List<Hre_ProfileEntity>();
                foreach (var item in entityTypes)
                {
                    var entityType = item.GetRealEntityType();
                    if (entityType != null)
                    {
                        lstEntityType.Add(entityType.Name);
                    }
                }

                LockObjectRepository lockObjectRepository = new LockObjectRepository();
                var lockInfo = lockObjectRepository.GetSettings(lstEntityType[0]);
                var CutOffDurationID = CutOffDuration.ID;
                if (lockInfo != null)
                {
                    var listLockObjectItem = unitOfWork.CreateQueryable<Sys_LockObjectItem>(d =>
                        d.Sys_LockObject.Status == approvedStatus && lstEntityType.Contains(d.ObjectName)
                        && (dateEnd == null || d.Sys_LockObject.DateStart <= dateEnd)
                        && (dateStart == null || d.Sys_LockObject.DateEnd >= dateStart)
                        && d.Sys_LockObject.IsLockProfile == true
                        && (d.Sys_LockObject.IsDelete == null || !d.Sys_LockObject.IsDelete.Value)
                        && (SysLockObjectType == null || d.Sys_LockObject.Type == SysLockObjectType)
                        && (CutOffDurationID == null || d.Sys_LockObject.CutOffDurationID == CutOffDurationID))
                        .Select(d => new LockObjectItem
                        {
                            ObjectName = d.ObjectName,
                            DateStart = d.Sys_LockObject.DateStart,
                            DateEnd = d.Sys_LockObject.DateEnd,
                            IsLockProfile = d.Sys_LockObject.IsLockProfile,
                            LockObjectID = d.LockObjectID
                        }).ToList();

                    if (listLockObjectItem != null && listLockObjectItem.Count() > 0)
                    {
                        #region Tung.Tran [04/07/2021][129003]: Lấy thêm dữ liệu Sys_LockObjectByProfile nếu có
                        var listLockObjectID = listLockObjectItem.Select(x => x.LockObjectID).Distinct().ToList();
                        var listlockObjectByProfile = unitOfWork.CreateQueryable<Sys_LockObjectByProfile>(x => listLockObjectID.Contains(x.LockObjectID)).Select(x => new LockObjectByProfile()
                        {
                            ProfileID = x.ProfileID,
                            LockObjectID = x.LockObjectID,
                        }).ToList();
                        #endregion

                        #region Tung.Tran [04/07/2021][129003]: Khóa dữ liệu theo nhân viên
                        //Nếu đang cấu hình khóa theo nhân viên => Xử lý kiểm tra nhân viên
                        if (listProfileID != null)
                        {
                            //Lấy dữ liệu nhân viên đã khóa
                            var listProfileIDLock = listlockObjectByProfile.Where(x => listLockObjectItem.Select(a => a.LockObjectID).ToList().Contains(x.LockObjectID)).Select(x => x.ProfileID).ToList();
                            //Nếu tồn tại nhân viên đang thao tác => return true (Đã bị khóa)
                            listHreProfileReturn = listProfileID.Where(x => listProfileIDLock.Contains(x.ID) || (!listProfileIDLock.Contains(x.ID) && x.DateQuit != null && x.DateQuit <= CutOffDuration.DateStart)).ToList();
                        }
                      
                        #endregion
                    }
                    else
                    {
                        string projectName = Common.Configuration.GetAppSettings("ProjectName", Common.GetPath("web.config"));
                        if (!string.IsNullOrEmpty(projectName) && projectName == "AVN" && GetConfigShowIsLockObjectByProfile())
                        {
                            listHreProfileReturn = new List<Hre_ProfileEntity>();
                        }
                        else
                        {
                            listHreProfileReturn = listProfileID;
                        }
                    }
                }
                return listHreProfileReturn;
            }
        }
        public bool GetConfigShowIsLockObjectByProfile()
        {
            Sys_AttOvertimePermitConfigServices sysServices = new Sys_AttOvertimePermitConfigServices();
            bool? IsShow = sysServices.GetConfigValue<bool?>(AppConfig.HRM_SAL_CONFIG_ISLOCKOBJECTBYPROFILE);
            return IsShow ?? false;
        }
        public ResultsObject ProcessUnusualPay(
            LogHelper _logger,
            List<string >listKeyLog,
            List<Sal_BasicSalary> lstBasicSal,
            List<Sys_AllSetting> lstappConfig,
            List<Hre_ProfileEntity> lstProfile,
            List<Guid> listProfileID,
            Att_CutOffDurationEntity Cutoffduration,
            DateTime dateofpayment,
            double amount,
            string Notes,
            bool money,
            string payrollGroup,
            double? UnusualPayCondition,
            string userLogin,
            Sys_AsynTask objAsynTask)
        {
            using (var context = new VnrHrmDataContext())
            {
                var unitOfWork = new UnitOfWork(context);
                var repoAsynTask = new CustomBaseRepository<Sys_AsynTask>(unitOfWork);

                try
                {
                    #region Khai báo + Get config
                    var swatch = new System.Diagnostics.Stopwatch();
                    swatch.Restart();
                    var repoUsu = new CustomBaseRepository<Sal_UnusualPay>(unitOfWork);
                    var repoCutoff = new CustomBaseRepository<Att_CutOffDuration>(unitOfWork);
                    var repoCat_Element = new CustomBaseRepository<Cat_Element>(unitOfWork);
                    var repoWorkHistory = new CustomBaseRepository<Hre_WorkHistory>(unitOfWork);
                    var repoProfile = new CustomBaseRepository<Hre_Profile>(unitOfWork);
                    ResultsObject resultObject = new ResultsObject();
                    DataErrorCode dataErrorCode = new DataErrorCode();
                    var _basicSalaryService = new Sal_BasicSalaryServices();
                    ComputePayrollDataModelKZAll TotalDataAll = new ComputePayrollDataModelKZAll();
                    TotalDataAll.UserLogin = userLogin;
                    var degreeOfParallelism = 4;
                    var listUnusualPayAdd = new List<Sal_UnusualPay>();
                    List<Sal_UnusualPayItem> listUnusualPayItem = new List<Sal_UnusualPayItem>();


                    //Hien.Nguyen-09102015-57626-58168
                    Sal_ComputePayrollKZServices Services = new Sal_ComputePayrollKZServices();
                    Hre_ProfileServices HrServices = new Hre_ProfileServices();

                    //HienNguyen
                    //Get Data Config
                    string type1 = AppConfig.HRM_SAL_UNUSUALPAY_DAYKEEPUNUSUALPAY.ToString();
                    string type2 = AppConfig.HRM_SAL_UNUSUALPAY_CONDITIONUNUSUALPAY.ToString();
                    string type3 = AppConfig.HRM_SAL_UNUSUALPAY_PAYROLLCONFIG.ToString();
                    string type4 = AppConfig.HRM_SAL_UNUSUALPAY_UNUSUALMETHOD.ToString();
                    string type5 = AppConfig.HRM_SAL_UNUSUALPAY_ISLOCKCOMPUTER.ToString();
                    string type6 = AppConfig.HRM_SAL_ELEMENT_UNUSUALPAY.ToString();
                    string realWorkDayPay = AppConfig.HRM_SAL_ELEMENT_UNUSUAL_REALWORKDAYPAY.ToString();
                    string degreeOfParallelismKey = AppConfig.HRM_ATT_WORKDAY_SUMMARY_PROCESSPARTICIPATECOMPUTEWORKDAY.ToString();

                    var lstConfig = lstappConfig.Where(sy =>

                           sy.Name == realWorkDayPay
                        || sy.Name == type1
                        || sy.Name == type2
                        || sy.Name == type3
                        || sy.Name == type4
                        || sy.Name == type5
                        || sy.Name == type6).ToList();

                    var degreeOfParallelismConfig = lstConfig.Where(s => s.Name == degreeOfParallelismKey).FirstOrDefault();
                    degreeOfParallelism = degreeOfParallelismConfig != null ? int.Parse(degreeOfParallelismConfig.Value1) : 4;
                    var config1 = lstConfig.Where(s => s.Name == type1).FirstOrDefault();
                    var config2 = lstConfig.Where(s => s.Name == type2).FirstOrDefault();
                    var config3 = lstConfig.Where(s => s.Name == type3).FirstOrDefault();
                    var config4 = lstConfig.Where(s => s.Name == type4).FirstOrDefault();
                    var config5 = lstConfig.Where(s => s.Name == type5).FirstOrDefault();
                    var config6 = lstConfig.Where(s => s.Name == type6).FirstOrDefault();
                    var configRealWorkDayPay = lstConfig.Where(s => s.Name == realWorkDayPay).FirstOrDefault();
                    if (!string.IsNullOrEmpty(config6.Value2))
                    {
                        config6.Value1 += config6.Value2;
                    }
                    if (!string.IsNullOrEmpty(config6.Value3))
                    {
                        config6.Value1 += config6.Value3;
                    }
                    if (!string.IsNullOrEmpty(config6.Value4))
                    {
                        config6.Value1 += config6.Value4;
                    }
                    string Formula = config6 != null && config6.Value1 != null ? config6.Value1 : string.Empty;
                  
                    double amountsalary = 0;    //Lương chính
                    int numberKeep = 0;         //Số ngày chốt để tạm ứng, tính từ đầu kỳ
                    double numberMinToAccept = 0;  //Điều Kiện Được Ứng Lương


                    if (config1 != null && !string.IsNullOrEmpty(config1.Value1))
                        numberKeep = int.Parse(config1.Value1);
                    //[08/05/2017][bang.nguyen][81254][Modify Func]
                    //Lấy cột giá trị vào công thức tạm ứng
                    if (UnusualPayCondition != null)
                    {
                        numberMinToAccept = UnusualPayCondition.Value;
                    }
                    else
                    {
                        if (config2 != null && !string.IsNullOrEmpty(config2.Value1))
                            numberMinToAccept = double.Parse(config2.Value1);
                    }
                   


                    _logger.WriteInfo("UnusualPayroll", "======> KHAI BÁO + LẤY DỮ LIỆU CẤU HÌNH", new
                    {
                        Time = swatch.Elapsed.ToString(),
                    });

                    swatch.Restart();
                    #endregion

                    #region Get data danh mục

                    //load them 10%
                    TotalDataAll = Services.GetDataForComputePayroll(Cutoffduration, UserLogin);

                    #region Dữ liệu danh mục dành riêng cho chức năng tính tạm ứng
                    TotalDataAll.listDataNote = context.Cat_DataNote
                        .AsNoTracking()
                        .Where(x => x.IsDelete != true)
                        .Where(x => x.Type == "PaymentAdvanceCondition")
                        .ToList();
                    #endregion


                    if (TotalDataAll.Status != string.Empty)
                    {
                        objAsynTask.PercentComplete = 1;
                        objAsynTask.TimeEnd = DateTime.Now;
                        unitOfWork.SaveChanges();
                        _logger.WriteError("UnusualPayroll", "======> LẤY DỮ LIỆU DANH MỤC LỖI, KẾT THÚC TÍNH TẠM ỨNG", new
                        {
                            exception = TotalDataAll.Status,
                        });

                        resultObject.Messenger = DataErrorCode.Error.ToString();
                        return resultObject;
                    }

                    _logger.WriteInfo("UnusualPayroll", "======> LẤY DỮ LIỆU DANH MỤC", new
                    {
                        Time = swatch.Elapsed.ToString(),
                    });
                    swatch.Restart();

                    objAsynTask.PercentComplete += 0.1;
                    repoAsynTask.Edit(objAsynTask);
                    unitOfWork.SaveChanges();

                    #endregion

                    #region [24/06/2017][bang.nguyen] Chặng không cho nhiều user tính cùng lúc nv hay phòng ban
                    var keyForCacheUtility = KeyForCacheUtility.COMPUTE_SALARYUNUSUALPAY.ToString();
                    var monthYearName = Cutoffduration.MonthYear.Month.ToString() + Cutoffduration.MonthYear.Year.ToString();
                    var keyMOnthYear = monthYearName + "-" + DateTime.Now.Ticks;

                    var list = CacheUtilityService.Get<List<Sal_UnusualPayMonthYearEntity>>(keyForCacheUtility);
                    if (list == null)
                    {
                        list = new List<Sal_UnusualPayMonthYearEntity>();
                        CacheUtilityService.AddOrUpdate(keyForCacheUtility, list);
                    }

                    //Them
                    var currentCompute = new Sal_UnusualPayMonthYearEntity
                    {
                        KeyMonthYear = keyMOnthYear,
                        ListProfileID = listProfileID
                    };

                    list.Add(currentCompute);
                    #endregion

                    #region Dùng parallel lấy data cho nhân viên
                    var lockObjectGetDataByProfile = new Object();

                    //ds nhân viên đã tạm ứng trước đó trong tháng
                    var ListWorkHistory = new List<Hre_WorkHistory>().Select(s => new
                    {
                        s.ProfileID,
                        s.DateEffective,
                        s.PositionID,
                        s.OrganizationStructureID,
                        s.JobTitleID,
                        s.EmployeeTypeID,
                        s.PayrollCategoryID,
                        s.CostCentreID,
                        s.PayrollGroupID

                    }).ToList();
                    var listUnusualPay = new List<Sal_UnusualPay>();

                    Parallel.ForEach(lstProfile.Chunk(600)
                    , new ParallelOptions() { MaxDegreeOfParallelism = degreeOfParallelism }
                    , listProfileSplit =>
                    {
                        using (var dbContext = new VnrHrmDataContext())
                        {
                            #region Khai báo
                            dbContext.Configuration.LazyLoadingEnabled = false;
                            dbContext.Configuration.ProxyCreationEnabled = false;
                            var unitOfWorkParallel = new UnitOfWork(dbContext);
                            Sal_ComputePayrollKZServices ComputePayrollKZServices = new Sal_ComputePayrollKZServices();
                            var listOrderByProfiles = listProfileSplit.Select(m => m.Order).Distinct().ToList();
                            var TotaDataByProfileIDs = new ComputePayrollDataModelKZAll();
                            var arrProfileIDs = listProfileSplit.Select(x => x.ID).ToArray();
                            #endregion

                            #region LẤY QUÁ TRÌNH CÔNG TÁC

                            var queryHistory = unitOfWorkParallel.CreateQueryable<Hre_WorkHistory>(Guid.Empty, s => s.DateEffective <= Cutoffduration.DateEnd);
                            var listWorkHistoryByProfile = queryHistory.Where(s => arrProfileIDs.Contains(s.ProfileID)).Select(s => new
                            {
                                s.ProfileID,
                                s.DateEffective,
                                s.PositionID,
                                s.OrganizationStructureID,
                                s.JobTitleID,
                                s.EmployeeTypeID,
                                s.PayrollCategoryID,
                                s.CostCentreID,
                                s.PayrollGroupID
                            }).ToList();

                            lock (lockObjectGetDataByProfile)
                            {
                                ListWorkHistory.AddRange(listWorkHistoryByProfile);
                            }
                            #endregion

                            #region LẤY DỮ LIỆU TẠM ỨNG CŨ 
                            var queryUnusualPay = unitOfWork.CreateQueryable<Sal_UnusualPay>(Guid.Empty, u => u.MonthYear == Cutoffduration.MonthYear);
                            var listUnusualPayByProfile = queryUnusualPay.Where(s => arrProfileIDs.Contains(s.ProfileID)).ToList();
                            lock (lockObjectGetDataByProfile)
                            {
                                listUnusualPay.AddRange(listUnusualPayByProfile);
                            }
                            #endregion

                            #region GET CÁC THÔNG TIN KHÁC
                            if (config3.Value1 == "HRM_SAL_UNUSUALPAY_PAYROLLCONFIG_ELEMENT" && !string.IsNullOrEmpty(Formula) && Cutoffduration != null)
                            {
                                TotaDataByProfileIDs = ComputePayrollKZServices.GetDataForComputePayrollByProfileIds(
                                           TotalDataAll,
                                           Cutoffduration,
                                           string.Join(",", listOrderByProfiles),
                                           UserLogin);
                            }
                            else if (!string.IsNullOrEmpty(configRealWorkDayPay.Value1) && Cutoffduration != null)
                            {
                                TotaDataByProfileIDs = ComputePayrollKZServices.GetDataForComputePayrollByProfileIds(
                                           TotalDataAll,
                                           Cutoffduration,
                                           string.Join(",", listOrderByProfiles),
                                           UserLogin);
                            }
                            else
                            {
                                if (TotaDataByProfileIDs.listAttendanceTable == null && Cutoffduration != null)
                                {
                                    string status = string.Empty;
                                    List<object> listModel = new List<object>();
                                    listModel = Common.AddRange(8);
                                    listModel[3] = new DateTime(Cutoffduration.MonthYear.Year - 1, 1, 1);
                                    listModel[4] = new DateTime(Cutoffduration.MonthYear.Year, 12, 31);
                                    listModel[5] = string.Join(",", listOrderByProfiles);
                                    TotaDataByProfileIDs.listAttendanceTable = GetData<Att_AttendanceTableEntity>(listModel, ConstantSql.hrm_att_sp_get_attdancetable_Sal, UserLogin, ref status);
                                    TotaDataByProfileIDs.listAttendanceTable = TotaDataByProfileIDs.listAttendanceTable.OrderByDescending(m => m.MonthYear).ToList();
                                }

                                if (TotaDataByProfileIDs.listAttendanceTableItem == null && Cutoffduration != null)
                                {
                                    string status = string.Empty;
                                    List<object> listModel = new List<object>();
                                    listModel = Common.AddRange(6);
                                    listModel[0] = Common.DotNetToOracle(Cutoffduration.ID.ToString());
                                    listModel[3] = string.Join(",", listOrderByProfiles);
                                    TotaDataByProfileIDs.listAttendanceTableItem = GetData<Att_AttendanceTableItemEntity>(listModel, ConstantSql.hrm_att_sp_get_AttendanceTableItem_Sal, UserLogin, ref status);
                                }

                                if (TotaDataByProfileIDs.listSalaryInformation == null && Cutoffduration != null)
                                {
                                    string status = string.Empty;
                                    List<object> listModel = new List<object>();
                                    listModel = Common.AddRange(9);
                                    listModel[6] = string.Join(",", listOrderByProfiles);
                                    TotaDataByProfileIDs.listSalaryInformation = GetData<Sal_SalaryInformationEntity>(listModel, ConstantSql.hrm_sal_sp_get_Sal_SalaryInformation_Sal, UserLogin, ref status);
                                }
                            }
                            if (!string.IsNullOrEmpty(TotaDataByProfileIDs.Status))
                            {
                                // Có lỗi trong quá trình get dữ liệu => Ghi log dừng xử lý
                                lock (lockObjectGetDataByProfile)
                                {
                                    TotaDataByProfileIDs.Status += TotaDataByProfileIDs.Status;
                                }
                            }
                            else
                            {
                                lock (lockObjectGetDataByProfile)
                                {
                                    #region Set into TotalData

                                    if (TotaDataByProfileIDs.listRecalAttendanceTableItem != null)
                                    {
                                        if (TotalDataAll.listRecalAttendanceTableItem == null) TotalDataAll.listRecalAttendanceTableItem = new List<Att_RecalAttendanceTableItemEntity>();
                                        TotalDataAll.listRecalAttendanceTableItem.AddRange(TotaDataByProfileIDs.listRecalAttendanceTableItem);
                                    }
                                    if (TotaDataByProfileIDs.listRecalAttendanceTable != null)
                                    {
                                        if (TotalDataAll.listRecalAttendanceTable == null) TotalDataAll.listRecalAttendanceTable = new List<Att_RecalAttendanceTableEntity>();
                                        TotalDataAll.listRecalAttendanceTable.AddRange(TotaDataByProfileIDs.listRecalAttendanceTable);
                                    }
                                    if (TotaDataByProfileIDs.listAttendanceTableItem != null)
                                    {
                                        if (TotalDataAll.listAttendanceTableItem == null) TotalDataAll.listAttendanceTableItem = new List<Att_AttendanceTableItemEntity>();
                                        TotalDataAll.listAttendanceTableItem.AddRange(TotaDataByProfileIDs.listAttendanceTableItem);
                                    }
                                    if (TotaDataByProfileIDs.listAttendanceTableItem_N_1 != null)
                                    {
                                        if (TotalDataAll.listAttendanceTableItem_N_1 == null) TotalDataAll.listAttendanceTableItem_N_1 = new List<Att_AttendanceTableItemEntity>();
                                        TotalDataAll.listAttendanceTableItem_N_1.AddRange(TotaDataByProfileIDs.listAttendanceTableItem_N_1);
                                    }
                                    if (TotaDataByProfileIDs.listRecalAttendanceTableItem_N_1 != null)
                                    {
                                        if (TotalDataAll.listRecalAttendanceTableItem_N_1 == null) TotalDataAll.listRecalAttendanceTableItem_N_1 = new List<Att_RecalAttendanceTableItemEntity>();
                                        TotalDataAll.listRecalAttendanceTableItem_N_1.AddRange(TotaDataByProfileIDs.listRecalAttendanceTableItem_N_1);
                                    }
                                    if (TotaDataByProfileIDs.listGrade != null)
                                    {
                                        if (TotalDataAll.listGrade == null) TotalDataAll.listGrade = new List<Sal_GradeEntity>();
                                        TotalDataAll.listGrade.AddRange(TotaDataByProfileIDs.listGrade);
                                    }
                                    if (TotaDataByProfileIDs.listAttendanceTable != null)
                                    {
                                        if (TotalDataAll.listAttendanceTable == null) TotalDataAll.listAttendanceTable = new List<Att_AttendanceTableEntity>();
                                        TotalDataAll.listAttendanceTable.AddRange(TotaDataByProfileIDs.listAttendanceTable);
                                    }
                                    if (TotaDataByProfileIDs.Att_AttendanceTable_Prev != null)
                                    {
                                        if (TotalDataAll.Att_AttendanceTable_Prev == null) TotalDataAll.Att_AttendanceTable_Prev = new List<Att_AttendanceTableEntity>();
                                        TotalDataAll.Att_AttendanceTable_Prev.AddRange(TotaDataByProfileIDs.Att_AttendanceTable_Prev);
                                    }

                                    if (TotaDataByProfileIDs.Att_AttendanceTable_Prev != null)
                                    {
                                        if (TotalDataAll.Att_RecalAttendanceTable_Prev == null) TotalDataAll.Att_RecalAttendanceTable_Prev = new List<Att_RecalAttendanceTableEntity>();
                                        TotalDataAll.Att_RecalAttendanceTable_Prev.AddRange(TotaDataByProfileIDs.Att_RecalAttendanceTable_Prev);
                                    }

                                    if (TotaDataByProfileIDs.listHre_StopWorking != null)
                                    {
                                        if (TotalDataAll.listHre_StopWorking == null) TotalDataAll.listHre_StopWorking = new List<Hre_StopWorkingEntity>();
                                        TotalDataAll.listHre_StopWorking.AddRange(TotaDataByProfileIDs.listHre_StopWorking);
                                    }
                                    if (TotaDataByProfileIDs.listBasicSalary != null)
                                    {
                                        if (TotalDataAll.listBasicSalary == null) TotalDataAll.listBasicSalary = new List<Sal_BasicSalaryEntity>();
                                        TotalDataAll.listBasicSalary.AddRange(TotaDataByProfileIDs.listBasicSalary);
                                    }
                                    if (TotaDataByProfileIDs.listBasicSalaryT3 != null)
                                    {
                                        if (TotalDataAll.listBasicSalaryT3 == null) TotalDataAll.listBasicSalaryT3 = new List<Sal_BasicSalaryEntity>();
                                        TotalDataAll.listBasicSalaryT3.AddRange(TotaDataByProfileIDs.listBasicSalaryT3);
                                    }
                                    if (TotaDataByProfileIDs.listWorkHistory != null)
                                    {
                                        if (TotalDataAll.listWorkHistory == null) TotalDataAll.listWorkHistory = new List<Hre_WorkHistoryEntity>();
                                        TotalDataAll.listWorkHistory.AddRange(TotaDataByProfileIDs.listWorkHistory);
                                    }
                                    if (TotaDataByProfileIDs.listSalaryInformation != null)
                                    {
                                        if (TotalDataAll.listSalaryInformation == null) TotalDataAll.listSalaryInformation = new List<Sal_SalaryInformationEntity>();
                                        TotalDataAll.listSalaryInformation.AddRange(TotaDataByProfileIDs.listSalaryInformation);
                                    }
                                    if (TotaDataByProfileIDs.listOverTime != null)
                                    {
                                        if (TotalDataAll.listOverTime == null) TotalDataAll.listOverTime = new List<Att_OvertimeEntity>();
                                        TotalDataAll.listOverTime.AddRange(TotaDataByProfileIDs.listOverTime);
                                    }
                                    if (TotaDataByProfileIDs.listOverTimeByCutOffBackPay != null)
                                    {
                                        if (TotalDataAll.listOverTimeByCutOffBackPay == null) TotalDataAll.listOverTimeByCutOffBackPay = new List<Att_OvertimeEntity>();
                                        TotalDataAll.listOverTimeByCutOffBackPay.AddRange(TotaDataByProfileIDs.listOverTimeByCutOffBackPay);
                                    }
                                    if (TotaDataByProfileIDs.listLeaveDayNotStatus != null)
                                    {
                                        if (TotalDataAll.listLeaveDayNotStatus == null) TotalDataAll.listLeaveDayNotStatus = new List<Att_LeaveDayEntity>();
                                        TotalDataAll.listLeaveDayNotStatus.AddRange(TotaDataByProfileIDs.listLeaveDayNotStatus);
                                    }
                                    if (TotaDataByProfileIDs.listLeaveDay != null)
                                    {
                                        if (TotalDataAll.listLeaveDay == null) TotalDataAll.listLeaveDay = new List<Att_LeaveDayEntity>();
                                        TotalDataAll.listLeaveDay.AddRange(TotaDataByProfileIDs.listLeaveDay);
                                    }
                                    if (TotaDataByProfileIDs.ListProductive != null)
                                    {
                                        if (TotalDataAll.ListProductive == null) TotalDataAll.ListProductive = new List<Sal_ProductiveEntity>();
                                        TotalDataAll.ListProductive.AddRange(TotaDataByProfileIDs.ListProductive);
                                    }
                                    if (TotaDataByProfileIDs.ListAttGrade != null)
                                    {
                                        if (TotalDataAll.ListAttGrade == null) TotalDataAll.ListAttGrade = new List<Att_GradeEntity>();
                                        TotalDataAll.ListAttGrade.AddRange(TotaDataByProfileIDs.ListAttGrade);
                                    }
                                    if (TotaDataByProfileIDs.ListInsuranceForPayrollMonthly != null)
                                    {
                                        if (TotalDataAll.ListInsuranceForPayrollMonthly == null) TotalDataAll.ListInsuranceForPayrollMonthly = new List<Ins_InsuranceForPayrollMonthlyEntity>();
                                        TotalDataAll.ListInsuranceForPayrollMonthly.AddRange(TotaDataByProfileIDs.ListInsuranceForPayrollMonthly);
                                    }
                                    if (TotaDataByProfileIDs.ListAtt_ProfileTimeSheet != null)
                                    {
                                        if (TotalDataAll.ListAtt_ProfileTimeSheet == null) TotalDataAll.ListAtt_ProfileTimeSheet = new List<Att_ProfileTimeSheetEntity>();
                                        TotalDataAll.ListAtt_ProfileTimeSheet.AddRange(TotaDataByProfileIDs.ListAtt_ProfileTimeSheet);
                                    }
                                    if (TotaDataByProfileIDs.ListPerformanceAllowance != null)
                                    {
                                        if (TotalDataAll.ListPerformanceAllowance == null) TotalDataAll.ListPerformanceAllowance = new List<Sal_PerformanceAllowanceEntity>();
                                        TotalDataAll.ListPerformanceAllowance.AddRange(TotaDataByProfileIDs.ListPerformanceAllowance);
                                    }
                                    if (TotaDataByProfileIDs.listSal_HoldSalary != null)
                                    {
                                        if (TotalDataAll.listSal_HoldSalary == null) TotalDataAll.listSal_HoldSalary = new List<Sal_HoldSalaryEntity>();
                                        TotalDataAll.listSal_HoldSalary.AddRange(TotaDataByProfileIDs.listSal_HoldSalary);
                                    }
                                    if (TotaDataByProfileIDs.listRoster != null)
                                    {
                                        if (TotalDataAll.listRoster == null) TotalDataAll.listRoster = new List<Att_RosterEntity>();
                                        TotalDataAll.listRoster.AddRange(TotaDataByProfileIDs.listRoster);
                                    }
                                    #endregion
                                }
                            }
                            #endregion
                        }
                    });

                    ListWorkHistory = ListWorkHistory.OrderByDescending(s => s.DateEffective).ToList();

                    if (TotalDataAll.Status != string.Empty)
                    {
                        objAsynTask.PercentComplete = 1;
                        objAsynTask.TimeEnd = DateTime.Now;
                        unitOfWork.SaveChanges();
                        _logger.WriteError("UnusualPayroll", "======> LẤY DỮ LIỆU NHÂN VIÊN LỖI, KẾT THÚC TÍNH TẠM ỨNG", new
                        {
                            exception = TotalDataAll.Status,
                        });

                        resultObject.Messenger = DataErrorCode.Error.ToString();
                        return resultObject;
                    }

                    #region Chuyển sang dictionary
                    Services.ConvertDictionaryOfData(TotalDataAll);
                    #endregion

                    _logger.WriteInfo("UnusualPayroll", "======> LẤY DỮ LIỆU CỦA " + lstProfile.Count().ToString() + " NHÂN VIÊN", new
                    {
                        Time = swatch.Elapsed.ToString(),
                    });
                    swatch.Restart();

                    #endregion

                    #region Kiểm tra cấu hình => Xóa dữ liệu 
                    //Kiểm tra cấu hình, nếu là tạm ứng 1 lần duy nhất trong tháng, thì sẽ xóa dữ liệu cũ đi, cập nhật lại dữ liệu tạm ứng mới.
                    if (config4 == null || (config4 != null && config4.Value1 != true.ToString()))
                    {
                        foreach (var listUnusualPayEditSave in listUnusualPay.Chunk(2000))
                        {
                            //listUnusualPayEditSave.ToList().ForEach(us => us.IsDelete = true);
                            //dataErrorCode = unitOfWork.SaveChanges();
                            try
                            {
                                unitOfWork.UpdateArray(listUnusualPayEditSave.AsEnumerable().Select((p) =>
                                {
                                    p.IsDelete = true;
                                    return p;
                                })
                           , p => p.IsDelete);
                            }
                            catch (Exception ex)
                            {
                                resultObject.Messenger = dataErrorCode.ToString();
                            }
                        }
                    }

                    _logger.WriteInfo("UnusualPayroll", "======> KIỂM TRA CẤU HÌNH XÓA DỮ LIỆU", new
                    {
                        Time = swatch.Elapsed.ToString(),
                    });
                    swatch.Restart();

                    #endregion

                    #region Xử lý

                    #region Duyệt qua profile để xử lý tính toán => Áp dụng parallel

                    #region Hien.Le [27/06/2019] [106626] Bổ sung lấy phần tử trong cấu hình ứng lương.
                    List<string> listFormulaSplit = new List<string>();
                    if (!string.IsNullOrEmpty(config6.Value1))
                    {
                        string strFormulaSplit = config6.Value1;
                        if (strFormulaSplit.IndexOf("\n") != -1 || strFormulaSplit.IndexOf("\t") != -1)
                        {
                            strFormulaSplit = strFormulaSplit.Replace("\n", "").Replace("\t", "").Trim();
                        }
                        //Các phần tử tính lương tách ra từ 1 chuỗi công thức
                        listFormulaSplit = Common.ParseFormulaToList(strFormulaSplit).Where(m => m.IndexOf('[') != -1 && m.IndexOf(']') != -1).ToList();

                        //Các phần tử tính lương chưa có kết quả
                        listFormulaSplit = listFormulaSplit.Select(s => s = s.Replace("[", "").Replace("]", "")).ToList();
                    }
                    #endregion

                    int indexComputePatch = 0;
                    var listThreadSave = new List<Thread>();
                    var lockObjectSave = new Object();
                    var objLockFileLog = new Object();
                    var objLockDataInsert = new Object();
                    Parallel.ForEach(lstProfile.Chunk(600)
                    , new ParallelOptions() { MaxDegreeOfParallelism = degreeOfParallelism }
                    , listProfileSplit =>
                    {
                        var swatchCompute = new System.Diagnostics.Stopwatch();
                        swatchCompute.Restart();
                        var indexPatchCompute = ++indexComputePatch;
                        var loggerPatch = new LogHelper(
                            "ProcessPayroll\\UnusualPayroll\\UnusualPayroll" + listKeyLog[1],
                            "UnusualPayroll - " + listKeyLog[0],
                            base.UserLogin);

                        loggerPatch.WriteInfo("UnusualPayroll Process", "======> START - NHÁNH PHÂN TÍCH: " + indexPatchCompute.ToString("000"), listProfileSplit.Count());

                        #region Gắn dữ liệu
                        var listUnusualPayAddChunk = new List<Sal_UnusualPay>();
                        var TotalData600 = new ComputePayrollDataModelKZ();
                        TotalData600.statusBugStore = string.Empty;
                        TotalData600.strOrderByProfile = string.Join(",", listProfileSplit.Select(m => m.Order.ToString()).ToArray());
                        TotalData600.listProfileIds = listProfileSplit.Select(x => x.ID).ToList();
                        TotalData600.listProfileSplit = listProfileSplit.ToList();
                        TotalData600.totalProfile = listProfileSplit.Count();
                        TotalData600.UserLogin = TotalDataAll.UserLogin;


                        var sourceType = TotalData600.GetType();
                        var sourceProperties = sourceType.GetProperties();
                        foreach (var property in sourceProperties)
                        {
                            if (TotalData600.GetPropertyValue(property.Name) == null)
                            {
                                try
                                {
                                    TotalData600.SetPropertyValue(
                                        property.Name,
                                        Activator.CreateInstance(TotalData600.GetPropertyType(property.Name))
                                        );
                                }
                                catch (Exception ex)
                                {

                                }
                            }
                        }
                        #endregion

                        try
                        {
                            foreach (Hre_ProfileEntity itemProfile in listProfileSplit)
                            {
                                List<ElementFormula> listElementFormula = new List<ElementFormula>();

                                double valueamount = 0;
                                //Bảng lương cơ bản của nhân viên
                                var salbasic = new Sal_BasicSalary();
                                var lstBasicSalPro = Sal_BasicSalaryServices.List(lstBasicSal, itemProfile.Copy<Hre_Profile>(), Cutoffduration.DateStart, Cutoffduration.DateEnd);
                                if (lstBasicSalPro.Count <= 0)
                                    continue;
                                if (lstBasicSalPro.Count == 2)
                                    salbasic = lstBasicSalPro[1];
                                else if (lstBasicSalPro.Count == 1)
                                    salbasic = lstBasicSalPro[0];
                                if (salbasic != null)
                                {
                                    if (salbasic.E_GrossAmount == null)
                                        amountsalary = 0;
                                    else
                                        amountsalary = salbasic.E_GrossAmount.DecryptValue().Value;
                                }

                                //công chi tiết của nhân viên
                                double res = 0;

                                var _att = TotalDataAll.listAttendanceTable.Where(att => att.ProfileID == itemProfile.ID && att.CutOffDurationID == Cutoffduration.ID).FirstOrDefault();
                                if (_att == null)
                                    continue;
                                //Ngày công chuẩn
                                double datestandar = _att.StdWorkDayCount;

                                //Kiểm tra khoảng ngày công đến ngày số ngày đã cấu hình
                                DateTime dateconvert = this.convertdatemonthyear(numberKeep, _att.MonthYear.Value);
                                if (dateconvert < _att.DateStart)
                                {
                                    dateconvert = dateconvert.AddMonths(1);
                                }

                                var _attLstItem = TotalDataAll.listAttendanceTableItem.Where(item => item.AttendanceTableID == _att.ID).ToList();
                                foreach (var item in _attLstItem)
                                {
                                    //[18/03/2016][Hien.Nguyen][64864]
                                    //điều kiện được hưởng lương
                                    double? _amountValidation = item.WorkPaidHours + item.PaidLeaveHours + (item.LeaveWorkDayHour ?? 0);

                                    if (item != null && item.WorkDate <= dateconvert && _amountValidation > 0)
                                    {
                                        //Ca thường: 8h, có một số TH (PhongPhu) có ca 10h (vd: ca cho bảo vệ)
                                        if (item.AvailableHours < 16)
                                            res += 1;
                                        else if (item.AvailableHours == 16)//Là ca ghép (ĐôngQuang)
                                        {
                                            if (item.WorkHourFirstHaftShift > 0)
                                                res += 1;
                                            if (item.WorkHourLastHaftShift > 0)
                                                res += 1;
                                        }
                                    }
                                }
                                if (res < numberMinToAccept) //Nếu ngày công nhỏ hơn số ngày đã cấu hình --> ko được tạm ứng
                                    continue;
                                else
                                {
                                    //Lấy quá trình công tác mới nhất của NV
                                    var WorkHistoryByProfile = ListWorkHistory.FirstOrDefault(m => m.ProfileID == itemProfile.ID);
                                    Sal_UnusualPay unusal = new Sal_UnusualPay();
                                    //Sal_UnusualPayEntity unusalEntity = new Sal_UnusualPayEntity();
                                    unusal.ID = Guid.NewGuid();
                                    unusal.ProfileID = itemProfile.ID;
                                    unusal.MonthYear = Cutoffduration.MonthYear;
                                    unusal.CutOffDurationID = Cutoffduration.ID;
                                    unusal.Type = UnusualPayType.ADVANCEPAY.ToString();
                                    unusal.Status = UnusualPayStatus.E_WAITING.ToString();
                                    unusal.DateOfPayment = dateofpayment;
                                    DateTime _profileQuitStart = Cutoffduration.DateStart.Date;
                                    DateTime _profileQuitEnd = Cutoffduration.DateEnd.Date;
                                    //[28/07/2021][minh.nguyenvan][Modify][0131072] Cập nhật trạng thái cho nhân viên
                                    if (itemProfile.DateQuit.HasValue && itemProfile.DateQuit.Value.Date < _profileQuitStart)
                                    {
                                        unusal.EmpStatus = SalUnusualProfileStatus.E_PROFILE_QUITED.ToString();
                                    }
                                    else if ((itemProfile.DateHire.HasValue && itemProfile.DateHire.Value.Date >= _profileQuitStart && itemProfile.DateHire.Value.Date <= _profileQuitEnd) && (itemProfile.DateQuit == null || itemProfile.DateQuit.Value.Date > _profileQuitEnd))
                                    {
                                        unusal.EmpStatus = SalUnusualProfileStatus.E_PROFILE_NEW.ToString();
                                    }
                                    else if ((itemProfile.DateHire.HasValue && itemProfile.DateHire.Value.Date < _profileQuitStart) && (itemProfile.DateQuit == null || itemProfile.DateQuit.Value.Date > _profileQuitEnd))
                                    {
                                        unusal.EmpStatus = SalUnusualProfileStatus.E_PROFILE_ACTIVE.ToString();
                                    }
                                    else if (itemProfile.DateQuit.HasValue && itemProfile.DateQuit.Value.Date >= _profileQuitStart && itemProfile.DateQuit.Value.Date <= _profileQuitEnd)
                                    {
                                        unusal.EmpStatus = SalUnusualProfileStatus.E_PROFILE_QUIT.ToString();
                                    }

                                    #region Tổ chức lưu trữ thông tin thanh toán (tài khoản) xuống bảng tính lương ứng
                                    //[25032016][bang.nguyen][64885][modify func]

                                    var objSalaryInformationByPro = TotalDataAll.dicSalaryInformation.GetValueOrNew(itemProfile.ID).FirstOrDefault();
                                    if (objSalaryInformationByPro != null)
                                    {
                                        if (objSalaryInformationByPro.IsCash != null && objSalaryInformationByPro.IsCash == true)
                                        {
                                            //phuong thuc thanh toan tien mat
                                            unusal.PaymentMethod = UnusualPayPaidType.E_CASH.ToString();
                                        }
                                        else
                                        {
                                            //phuong thuc thanh toan chuyển khoảng
                                            unusal.PaymentMethod = UnusualPayPaidType.E_TRANSFER.ToString();
                                            if (objSalaryInformationByPro.BankID != null)
                                            {
                                                unusal.BankID = objSalaryInformationByPro.BankID;
                                            }
                                            if (objSalaryInformationByPro.AccountNo != null && objSalaryInformationByPro.AccountNo != string.Empty)
                                            {
                                                unusal.AccountNo = objSalaryInformationByPro.AccountNo;
                                            }
                                        }
                                    }
                                    else
                                    {
                                        //phuong thuc thanh toan tien mat
                                        unusal.PaymentMethod = UnusualPayPaidType.E_CASH.ToString();
                                    }
                                    #endregion

                                    unusal.Description = Notes;
                                    if (WorkHistoryByProfile != null)
                                    {
                                        unusal.PositionID = WorkHistoryByProfile.PositionID;
                                        unusal.OrgstructureID = WorkHistoryByProfile.OrganizationStructureID;
                                        unusal.JobTittleID = WorkHistoryByProfile.JobTitleID;
                                        unusal.EmployeetypeID = WorkHistoryByProfile.EmployeeTypeID;
                                        unusal.PayrollgroupID = WorkHistoryByProfile.PayrollGroupID;
                                        unusal.CostcentreID = WorkHistoryByProfile.CostCentreID;
                                    }

                                    if (config3.Value1 == "HRM_SAL_UNUSUALPAY_PAYROLLCONFIGSTANDARDDAY")
                                    {
                                        valueamount = amountsalary / datestandar * res * amount / 100;
                                    }
                                    else if (config3.Value1 == "HRM_SAL_UNUSUALPAY_PAYROLLCONFIGPERCENT")
                                    {
                                        valueamount = amountsalary * amount / 100;
                                    }
                                    else if (config3.Value1 == "HRM_SAL_UNUSUALPAY_PAYROLLCONFIG_ELEMENT")
                                    {
                                        if (!string.IsNullOrEmpty(config6.Value1))
                                        {
                                            #region Tính Công Thức
                                            try
                                            {
                                                listElementFormula = new List<ElementFormula>();
                                                //Tạo ra 1 đối tượng element giả để gọi đc hàm parse công thức
                                                Cat_ElementEntity ElementItem = new Cat_ElementEntity();
                                                ElementItem.ElementCode = "HRM_SAL_UNUSUALPAY_PAYROLLCONFIG_ELEMENT";
                                                ElementItem.Formula = config6.Value1;

                                                #region Add thêm các phần tử ngoài giao diện chọn
                                                listElementFormula.Add(new ElementFormula()
                                                {
                                                    VariableName = UnusualPayElement.Pay_ActualWorkingDay.ToString(),
                                                    OrderNumber = 0,
                                                    Value = GetWorkingDayForUnusualPay(TotalDataAll.listAttendanceTable, TotalDataAll.listAttendanceTableItem,
                                                  Cutoffduration,
                                                  itemProfile.ID,
                                                  numberKeep)
                                                });

                                                listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.Pay_Conditionunusualpay.ToString(), OrderNumber = 0, Value = numberMinToAccept });
                                                listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.Pay_Money.ToString(), OrderNumber = 0, Value = money == true ? amount : 0 });
                                                listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.Pay_Percent.ToString(), OrderNumber = 0, Value = money == false ? amount / 100 : 0 });
                                                listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.Pay_TypeCompute.ToString(), OrderNumber = 0, Value = money == true ? 1 : 2 });
                                                #endregion

                                                #region Tung.Tran [04/07/2019] 0106905: [Hotfix PAIHO_v8.7.16.03.12.01] Modify thêm enum lấy giờ công thực tế của nhân viên tới ngày chốt tạm ứng	
                                                if (config6.Value1.IndexOf(UnusualPayElement.PAY_WORKPAIDHOURS.ToString()) != -1)
                                                {
                                                    double sumWorkPaidHours = 0;

                                                    sumWorkPaidHours = TotalDataAll.dicAttendanceTableItem.GetValueOrNew(_att.ID)
                                                                        .OrderBy(m => m.WorkDate)
                                                                        .Take(numberKeep)
                                                                        .Sum(a => a.WorkPaidHours);

                                                    listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_WORKPAIDHOURS.ToString(), OrderNumber = 0, Value = sumWorkPaidHours });
                                                }

                                                if (config6.Value1.IndexOf(UnusualPayElement.PAY_PAIDLEAVEHOURS.ToString()) != -1)
                                                {

                                                    double sumPaidLeaveHours = 0;

                                                    sumPaidLeaveHours = TotalDataAll.dicAttendanceTableItem.GetValueOrNew(_att.ID)
                                                                        .OrderBy(m => m.WorkDate)
                                                                        .Take(numberKeep)
                                                                        .Sum(a => a.PaidLeaveHours);

                                                    listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_PAIDLEAVEHOURS.ToString(), OrderNumber = 0, Value = sumPaidLeaveHours });
                                                }
                                                #endregion

                                                #region Hien.Le [01/06/2020] [0115511]: Thêm enum tính tạm ứng
                                                if (config6.Value1.IndexOf(UnusualPayElement.PAY_WORKPAIDHOURS_DAYKEEP_UNUSUALPAY.ToString()) != -1)
                                                {
                                                    double sumWorkPaidHours = 0;

                                                    sumWorkPaidHours = TotalDataAll.dicAttendanceTableItem.GetValueOrNew(_att.ID)
                                                                        .Where(m => m.WorkDate <= dateconvert)
                                                                        .OrderBy(m => m.WorkDate)
                                                                        .Sum(a => a.WorkPaidHours);

                                                    listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_WORKPAIDHOURS_DAYKEEP_UNUSUALPAY.ToString(), OrderNumber = 0, Value = sumWorkPaidHours });
                                                }

                                                if (config6.Value1.IndexOf(UnusualPayElement.PAY_PAIDLEAVEHOURS_DAYKEEP_UNUSUALPAY.ToString()) != -1)
                                                {
                                                    double sumPaidLeaveHours = 0;

                                                    sumPaidLeaveHours = TotalDataAll.dicAttendanceTableItem.GetValueOrNew(_att.ID)
                                                                        .Where(m => m.WorkDate <= dateconvert)
                                                                        .OrderBy(m => m.WorkDate)
                                                                        .Sum(a => a.PaidLeaveHours);

                                                    listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_PAIDLEAVEHOURS_DAYKEEP_UNUSUALPAY.ToString(), OrderNumber = 0, Value = sumPaidLeaveHours });
                                                }
                                                #endregion

                                                #region Hien.Le [28/06/2019] [0106626] Lấy Enum lương cơ bản và 15 loại phụ cấp
                                                if (listFormulaSplit.Contains(UnusualPayElement.PAY_BASICSALARY_GROSSAMOUNT.ToString())
                                                    || listFormulaSplit.Any(x => x.IndexOf("PAY_BASICSALARY_ALLOWANCEAMOUNT") != -1)
                                                    || listFormulaSplit.Any(x => x.IndexOf("PAY_BASICSALARY_ALLOWANCECODE") != -1))
                                                {
                                                    var objBasicSalary = TotalDataAll.dicBasicSalary.GetValueOrNew(itemProfile.ID)
                                                                         .Where(p => p.Status == EnumDropDown.Sal_BasicSalaryStatus.E_APPROVED.ToString()
                                                                         && p.DateOfEffect <= Cutoffduration.DateStart.AddDays(numberKeep - 1))
                                                                         .OrderByDescending(p => p.DateOfEffect)
                                                                         .FirstOrDefault();

                                                    if (objBasicSalary != null)
                                                    {
                                                        #region Mức lương cơ bản

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_GROSSAMOUNT.ToString(), Value = objBasicSalary.GrossAmount != null ? objBasicSalary.GrossAmount : "0" });

                                                        #endregion

                                                        #region Số tiền 15 loại phụ cấp 

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT1.ToString(), Value = objBasicSalary.AllowanceAmount1 != null ? objBasicSalary.AllowanceAmount1 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT2.ToString(), Value = objBasicSalary.AllowanceAmount2 != null ? objBasicSalary.AllowanceAmount2 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT3.ToString(), Value = objBasicSalary.AllowanceAmount3 != null ? objBasicSalary.AllowanceAmount3 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT4.ToString(), Value = objBasicSalary.AllowanceAmount4 != null ? objBasicSalary.AllowanceAmount4 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT5.ToString(), Value = objBasicSalary.AllowanceAmount5 != null ? objBasicSalary.AllowanceAmount5 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT6.ToString(), Value = objBasicSalary.AllowanceAmount6 != null ? objBasicSalary.AllowanceAmount6 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT7.ToString(), Value = objBasicSalary.AllowanceAmount7 != null ? objBasicSalary.AllowanceAmount7 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT8.ToString(), Value = objBasicSalary.AllowanceAmount8 != null ? objBasicSalary.AllowanceAmount8 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT9.ToString(), Value = objBasicSalary.AllowanceAmount9 != null ? objBasicSalary.AllowanceAmount9 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT10.ToString(), Value = objBasicSalary.AllowanceAmount10 != null ? objBasicSalary.AllowanceAmount10 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT11.ToString(), Value = objBasicSalary.AllowanceAmount11 != null ? objBasicSalary.AllowanceAmount11 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT12.ToString(), Value = objBasicSalary.AllowanceAmount12 != null ? objBasicSalary.AllowanceAmount12 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT13.ToString(), Value = objBasicSalary.AllowanceAmount13 != null ? objBasicSalary.AllowanceAmount13 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT14.ToString(), Value = objBasicSalary.AllowanceAmount14 != null ? objBasicSalary.AllowanceAmount14 : 0 });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCEAMOUNT15.ToString(), Value = objBasicSalary.AllowanceAmount15 != null ? objBasicSalary.AllowanceAmount15 : 0 });
                                                        #endregion

                                                        #region 15 mã phụ cấp

                                                        var objAllowanceType1 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceType1ID);
                                                        var usualAllowanceType1Code = objAllowanceType1?.Code ?? "";

                                                        var objAllowanceType2 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceType2ID);
                                                        var usualAllowanceType2Code = objAllowanceType2?.Code ?? "";

                                                        var objAllowanceType3 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceType3ID);
                                                        var usualAllowanceType3Code = objAllowanceType3?.Code ?? "";

                                                        var objAllowanceType4 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceType4ID);
                                                        var usualAllowanceType4Code = objAllowanceType4?.Code ?? "";

                                                        var objAllowanceType5 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID5);
                                                        var usualAllowanceType5Code = objAllowanceType5?.Code ?? "";

                                                        var objAllowanceType6 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID6);
                                                        var usualAllowanceType6Code = objAllowanceType6?.Code ?? "";

                                                        var objAllowanceType7 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID7);
                                                        var usualAllowanceType7Code = objAllowanceType7?.Code ?? "";

                                                        var objAllowanceType8 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID8);
                                                        var usualAllowanceType8Code = objAllowanceType8?.Code ?? "";

                                                        var objAllowanceType9 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID9);
                                                        var usualAllowanceType9Code = objAllowanceType9?.Code ?? "";

                                                        var objAllowanceType10 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID10);
                                                        var usualAllowanceType10Code = objAllowanceType10?.Code ?? "";

                                                        var objAllowanceType11 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID11);
                                                        var usualAllowanceType11Code = objAllowanceType11?.Code ?? "";

                                                        var objAllowanceType12 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID12);
                                                        var usualAllowanceType12Code = objAllowanceType12?.Code ?? "";

                                                        var objAllowanceType13 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID13);
                                                        var usualAllowanceType13Code = objAllowanceType13?.Code ?? "";

                                                        var objAllowanceType14 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID14);
                                                        var usualAllowanceType14Code = objAllowanceType14?.Code ?? "";

                                                        var objAllowanceType15 = TotalDataAll.listUsualAllowance.FirstOrDefault(p => p.ID == objBasicSalary.AllowanceTypeID15);
                                                        var usualAllowanceType15Code = objAllowanceType15?.Code ?? "";

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE1.ToString(), Value = usualAllowanceType1Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE2.ToString(), Value = usualAllowanceType2Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE3.ToString(), Value = usualAllowanceType3Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE4.ToString(), Value = usualAllowanceType4Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE5.ToString(), Value = usualAllowanceType5Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE6.ToString(), Value = usualAllowanceType6Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE7.ToString(), Value = usualAllowanceType7Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE8.ToString(), Value = usualAllowanceType8Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE9.ToString(), Value = usualAllowanceType9Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE10.ToString(), Value = usualAllowanceType10Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE11.ToString(), Value = usualAllowanceType11Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE12.ToString(), Value = usualAllowanceType12Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE13.ToString(), Value = usualAllowanceType13Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE14.ToString(), Value = usualAllowanceType14Code });

                                                        listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_BASICSALARY_ALLOWANCECODE15.ToString(), Value = usualAllowanceType15Code });
                                                        #endregion
                                                    }
                                                }

                                                #endregion

                                                listElementFormula = Services.ParseFormulaForComputePayroll(
                                                                     TotalDataAll,
                                                                     ElementItem,
                                                                     listElementFormula,
                                                                     TotalData600,
                                                                     itemProfile,
                                                                     Cutoffduration,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     new Dictionary<Guid, ValueCount>());

                                                var FormulaValue = listElementFormula.Where(m => m.VariableName.ReplaceSpace() == ElementItem.ElementCode.ReplaceSpace()).FirstOrDefault();
                                                valueamount = double.Parse(FormulaValue != null ? FormulaValue.Value.ToString() : "0");

                                                #region Hien.Le [27/06/2019] [106626] : Bổ sung save bảng chi tiết tạm ứng
                                                foreach (var itemFormula in listFormulaSplit)
                                                {
                                                    Sal_UnusualPayItem payItem = new Sal_UnusualPayItem();
                                                    payItem.ID = Guid.NewGuid();
                                                    payItem.UnusualPayID = unusal.ID;
                                                    payItem.Code = itemFormula;
                                                    payItem.UnusualPayItemName = itemFormula;
                                                    var ElementResult = listElementFormula.FirstOrDefault(m => m.VariableName.Trim() == itemFormula.Trim());
                                                    if (ElementResult != null)
                                                    {
                                                        double number = 0;
                                                        var dtDatetime = DateTime.Now;

                                                        if (ElementResult.Value != null)
                                                        {
                                                            payItem.Amount = ElementResult.Value.ToString();
                                                        }

                                                        if (double.TryParse(payItem.Amount, out number))
                                                            payItem.DataType = EnumDropDown.ElementDataType.Double.ToString();
                                                        else if (DateTime.TryParse(payItem.Amount, out dtDatetime))
                                                            payItem.DataType = EnumDropDown.ElementDataType.Datetime.ToString();
                                                        else
                                                            payItem.DataType = EnumDropDown.ElementDataType.Nvarchar.ToString();
                                                    }
                                                    else
                                                    {
                                                        payItem.Amount = "0";
                                                        payItem.DataType = EnumDropDown.ElementDataType.Nvarchar.ToString();
                                                        payItem.Description = ConstantDisplay.HRM_Sal_ComputePayroll_NotFoundElement.TranslateString() + " " + itemFormula;
                                                    }
                                                    listUnusualPayItem.Add(payItem);
                                                }
                                                #endregion

                                            }
                                            catch
                                            {
                                                valueamount = 0;
                                            }
                                            #endregion
                                        }
                                    }
                                    unusal.Amount = valueamount;

                                    #region Xử lý lưu RealWorkDayPay
                                    if (configRealWorkDayPay != null)
                                    {
                                        if (!string.IsNullOrEmpty(configRealWorkDayPay.Value1))
                                        {
                                            var valueAmountConfigRealWorkDayPay = 0.0;
                                            #region Tính Công Thức
                                            try
                                            {
                                                if (listElementFormula.Count == 0)
                                                {
                                                    listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.Pay_ActualWorkingDay.ToString(), OrderNumber = 0, Value = GetWorkingDayForUnusualPay(TotalDataAll.listAttendanceTable, TotalDataAll.listAttendanceTableItem, Cutoffduration, itemProfile.ID, numberKeep) });
                                                    listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.Pay_Conditionunusualpay.ToString(), OrderNumber = 0, Value = numberMinToAccept });
                                                    listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.Pay_Money.ToString(), OrderNumber = 0, Value = money == true ? amount : 0 });
                                                    listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.Pay_Percent.ToString(), OrderNumber = 0, Value = money == false ? amount / 100 : 0 });
                                                    listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_WORKPAIDHOURS.ToString(), OrderNumber = 0, Value = GetTotalWorkPaidHours(TotalDataAll.listAttendanceTable, TotalDataAll.listAttendanceTableItem, Cutoffduration, itemProfile.ID, numberKeep) });
                                                    listElementFormula.Add(new ElementFormula() { VariableName = UnusualPayElement.PAY_PAIDLEAVEHOURS.ToString(), OrderNumber = 0, Value = GetTotalPaidLeaveHours(TotalDataAll.listAttendanceTable, TotalDataAll.listAttendanceTableItem, Cutoffduration, itemProfile.ID, numberKeep) });
                                                }

                                                //Tạo ra 1 đối tượng element giả để gọi đc hàm parse công thức
                                                Cat_ElementEntity ElementItem = new Cat_ElementEntity();
                                                ElementItem.ElementCode = AppConfig.HRM_SAL_ELEMENT_UNUSUAL_REALWORKDAYPAY.ToString();
                                                ElementItem.Formula = configRealWorkDayPay.Value1;

                                                listElementFormula = Services.ParseFormulaForComputePayroll(
                                                                     TotalDataAll,
                                                                     ElementItem,
                                                                     listElementFormula,
                                                                     TotalData600,
                                                                     itemProfile,
                                                                     Cutoffduration,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     new Dictionary<Guid, ValueCount>());

                                                var formulaValueByConfigRealWorkDayPay = listElementFormula.Where(m => m.VariableName.ReplaceSpace() == ElementItem.ElementCode.ReplaceSpace()).FirstOrDefault();
                                                valueAmountConfigRealWorkDayPay = double.Parse(formulaValueByConfigRealWorkDayPay != null ? formulaValueByConfigRealWorkDayPay.Value.ToString() : "0");
                                            }
                                            catch
                                            {
                                                valueAmountConfigRealWorkDayPay = 0;
                                            }
                                            #endregion
                                            unusal.RealWorkDayPay = valueAmountConfigRealWorkDayPay;
                                        }
                                    }
                                    #endregion

                                    #region Xử lý lưu ghi chú
                                    if (TotalDataAll.listDataNote != null && TotalDataAll.listDataNote.Count > 0)
                                    {
                                        var listReasonNotPayAdvance = new List<string>();
                                        foreach (var itemDataNote in TotalDataAll.listDataNote)
                                        {
                                            if (!string.IsNullOrEmpty(itemDataNote.Formula))
                                            {
                                                Cat_ElementEntity ElementItem = new Cat_ElementEntity();
                                                ElementItem.ElementCode = "CAT_DATANOTE_FORMULA_" + itemDataNote.EnumKey;
                                                ElementItem.Formula = itemDataNote.Formula;

                                                listElementFormula = Services.ParseFormulaForComputePayroll(
                                                                     TotalDataAll,
                                                                     ElementItem,
                                                                     listElementFormula,
                                                                     TotalData600,
                                                                     itemProfile,
                                                                     Cutoffduration,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     null,
                                                                     new Dictionary<Guid, ValueCount>());

                                                var objElementValue = listElementFormula
                                                .Where(m => m.VariableName.ReplaceSpace() == ElementItem.ElementCode.ReplaceSpace())
                                                .FirstOrDefault();
                                                if (objElementValue != null
                                                    && objElementValue.Value != null
                                                    && objElementValue.Value.ToString().ToLower() == "true")
                                                {
                                                    listReasonNotPayAdvance.Add(itemDataNote.EnumKey);
                                                }
                                            }
                                        }
                                        if (listReasonNotPayAdvance.Any())
                                        {
                                            unusal.ReasonNotPayAdvance = Common.Join(listReasonNotPayAdvance, ",");
                                        }
                                    }
                                    #endregion

                                    if (unusal != null)
                                    {
                                        unusal.UserCreate = userLogin;
                                        unusal.UserUpdate = userLogin;
                                        unusal.DateCreate = DateTime.Now;
                                        unusal.DateUpdate = DateTime.Now;
                                        listUnusualPayAddChunk.Add(unusal);
                                    }
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            lock (objLockFileLog)
                            {
                                loggerPatch.WriteError("UnusualPayroll Process", "======> NHÁNH PHÂN TÍCH: " + indexPatchCompute.ToString("000") + ": Process Exception", new
                                {
                                    innerException = ex.InnerException,
                                    exeption = ex.Message + "; " + ex.StackTrace,
                                });
                            }
                        }
                        finally
                        {
                            lock (objLockFileLog)
                            {

                                listUnusualPayAdd.AddRange(listUnusualPayAddChunk);

                                #region Ghi log lại các store và phần tử không tính được khi lỗi store
                                if (!string.IsNullOrEmpty(TotalData600.statusBugStore))
                                {
                                    loggerPatch.WriteError("UnusualPayroll Process", "======> NHÁNH PHÂN TÍCH: " + indexPatchCompute.ToString("000") + ": Lỗi store", new
                                    {
                                        exception = TotalData600.statusBugStore
                                    });

                                    TotalData600.statusBugStore = string.Empty;
                                }
                                #endregion

                                #region Ghi log lỗi khi tính
                                if (!string.IsNullOrEmpty(TotalData600.strErrMesage))
                                {
                                    loggerPatch.WriteError("UnusualPayroll Process", "======> NHÁNH PHÂN TÍCH: " + indexPatchCompute.ToString("000") + ": Tính toán phần tử cho " + listProfileSplit.Count().ToString() + " nhân viên lỗi", new
                                    {
                                        ErrMesage = TotalData600.strErrMesage,
                                        ErrMesageByDay = TotalData600.strErrMesageByDay,
                                        ErrMesageByGroup = TotalData600.strErrMesageByGroup,
                                    });

                                    TotalData600.strErrMesage = string.Empty;
                                    TotalData600.strErrMesageByDay = string.Empty;
                                    TotalData600.strErrMesageByGroup = string.Empty;
                                }
                                #endregion

                                #region Ghi log thời gian tính
                                loggerPatch.WriteInfo("UnusualPayroll Process", "======> NHÁNH PHÂN TÍCH: " + indexPatchCompute.ToString("000") + ": Thời gian tính " + listProfileSplit.Count() + " nhân viên", new
                                {
                                    Time = swatchCompute.Elapsed.ToString(),
                                });
                                #endregion
                            }
                        }
                    });
                    #endregion

                    _logger.WriteInfo("UnusualPayroll", "======> TỔNG THỜI GIAN XỬ LÝ TÍNH CỦA " + lstProfile.Count().ToString() + " NHÂN VIÊN", new
                    {
                        Time = swatch.Elapsed.ToString(),
                    });
                    swatch.Restart();
                    #endregion

                    #region Save

                    #region Save Master
                    Sal_CacheUnusualPayServices cacheUnusualPayServices = new Sal_CacheUnusualPayServices();
                    Sal_CacheUnusualPayItemServices cacheUnusualPayItemServices = new Sal_CacheUnusualPayItemServices();
                    foreach (var listUnusualPayAddSave in listUnusualPayAdd.Chunk(2000))
                    {
                        try
                        {
                            unitOfWork.InsertArray(listUnusualPayAddSave);

                            //Tung.Tran [27/08/2021][132166]: Clear cache khi tính lương xong, cache sẽ được thêm vào khi công bố
                            cacheUnusualPayServices.DeleteCache(listUnusualPayAddSave.ToList());
                            cacheUnusualPayItemServices.DeleteCache(listUnusualPayAddSave.ToList());
                        }
                        catch (Exception ex)
                        {
                            resultObject.Messenger = dataErrorCode.ToString();
                        }
                    }
                    #endregion

                    #region Hien.Le Bổ sung save bảng chi tiết tạm ứng
                    if (listUnusualPayItem.Count > 0)
                    {
                        TraceLogManager FileLog = new TraceLogManager();
                        try
                        {
                            // Xử lý Save
                            unitOfWork.InsertArray(listUnusualPayItem, 2000);
                        }
                        catch (Exception ex)
                        {
                            try
                            {
                                // Xử lý save nhưng số lượng save nhỏ hơn => Tránh TH timeout
                                unitOfWork.InsertArray(listUnusualPayItem, 1000);
                            }
                            catch (DbEntityValidationException dbex)
                            {
                                // Xảy ra lỗi trong quá trình lưu => Lấy thông tin lỗi => Ghi log
                                var errorMessages = dbex.EntityValidationErrors
                                        .SelectMany(x => x.ValidationErrors)
                                        .Select(x => x.ErrorMessage);

                                var fullErrorMessage = string.Join("; ", errorMessages);

                                var exceptionMessage = string.Concat(dbex.Message, " The validation errors are: ", fullErrorMessage);

                                FileLog.WriteLog(
                                userLog: UserLogin
                                , message: "Save UnusualPayItem DbEntity"
                                , source: Newtonsoft.Json.JsonConvert.SerializeObject(new
                                {
                                    innerException = dbex.InnerException,
                                    exeption = exceptionMessage,
                                    count = listUnusualPayItem.Count(),
                                    data = lstProfile.Select(s => s.CodeEmp).ToList()
                                }));
                            }
                            catch (Exception ex1)
                            {
                                FileLog.WriteLog(
                                userLog: UserLogin
                                , message: "Save Change UnusualPayItem"
                                , source: Newtonsoft.Json.JsonConvert.SerializeObject(new
                                {
                                    innerException = ex.InnerException,
                                    exeption = ex1.Message + "; " + ex1.StackTrace,
                                    count = listUnusualPayItem.Count(),
                                    data = lstProfile.Select(s => s.CodeEmp).ToList()
                                }));
                            }
                        }
                    }
                    #endregion

                    //Xoa cache thang tinh
                    list.Remove(currentCompute);

                    if (dataErrorCode.ToString() == DataErrorCode.Success.ToString())
                    {
                        resultObject.Success = true;
                        resultObject.Messenger = dataErrorCode.ToString();
                    }
                    else
                    {
                        resultObject.Messenger = dataErrorCode.ToString();
                    }

                    _logger.WriteInfo("UnusualPayroll", "======> LƯU DỮ LIỆU", new
                    {
                        Time = swatch.Elapsed.ToString(),
                    });
                    swatch.Restart();
                    #endregion
                  
                    objAsynTask.PercentComplete = 1D;
                    objAsynTask.TimeEnd = DateTime.Now;
                    objAsynTask.Status = AsynTaskStatus.Done.ToString();
                    repoAsynTask.Edit(objAsynTask);
                    unitOfWork.SaveChanges();

                    _logger.WriteInfo("UnusualPayroll", "======> KẾT THÚC TÍNH TẠM ỨNG", new
                    {
                        Time = (DateTime.Now - objAsynTask.TimeStart).TotalMinutes + " min",
                    });

                    return resultObject;
                }
                catch (Exception ex)
                {
                    #region Ghi log lỗi & Lưu 100% & Đưa thông báo
                    _logger.WriteError("UnusualPayroll", "======> LỖI, KẾT THÚC TÍNH TẠM ỨNG", new
                    {
                        innerException = ex.InnerException,
                        exeption = ex.Message + "; " + ex.StackTrace,
                    });

                    objAsynTask.PercentComplete = 1D;
                    objAsynTask.TimeEnd = DateTime.Now;
                    objAsynTask.Status = AsynTaskStatus.Done.ToString();
                    repoAsynTask.Edit(objAsynTask);
                    unitOfWork.SaveChanges();
                    ResultsObject resultObject = new ResultsObject();
                    resultObject.Messenger = DataErrorCode.Error.ToString();
                    return resultObject;
                    #endregion
                }
            }
        }

        //Chuyển số ngày chốt tạm ứng lương (cấu hình chung) thành datetime.
        protected DateTime convertdatemonthyear(int day, DateTime dateAttItem)
        {
            if (day == 0)
                day = 1;
            int month = dateAttItem.Month;
            int year = dateAttItem.Year;
            int tempDayInMonth = DateTime.DaysInMonth(year, month);
            if (day > tempDayInMonth)
            {
                day = tempDayInMonth;
            }
            DateTime dayconvert = new DateTime(year, month, day);
            return dayconvert;
        }

        private Double GetWorkingDayForUnusualPay(List<Att_AttendanceTableEntity> ListAttTable, List<Att_AttendanceTableItemEntity> ListAttTableItem, Att_CutOffDurationEntity Cutoffduration, Guid ProfileID, int DateClosePay)
        {
            using (var context = new VnrHrmDataContext())
            {
                var unitOfWork = (IUnitOfWork)(new UnitOfWork(context));
                //var repoAttTable = new CustomBaseRepository<Att_AttendanceTable>(unitOfWork);
                //var repoAttTableItem = new CustomBaseRepository<Att_AttendanceTableItem>(unitOfWork);
                if (Cutoffduration != null)
                {
                    var AttTable = ListAttTable.Where(m => m.IsDelete != true && m.ProfileID == ProfileID && m.CutOffDurationID == Cutoffduration.ID).FirstOrDefault();
                    if (AttTable != null)
                    {
                        ListAttTableItem = ListAttTableItem.Where(m => m.AttendanceTableID == AttTable.ID).ToList();

                        //[18/03/2016][Hien.Nguyen][64864]
                        //điều kiện được hưởng lương
                        return ListAttTableItem.Count(m => (m.WorkPaidHours + m.PaidLeaveHours + (m.LeaveWorkDayHour ?? 0)) > 0 && m.WorkDate.Day <= DateClosePay);
                    }
                    else
                    {
                        return 0;
                    }
                }
                else
                {
                    return 0;
                }
            }
        }


        /// <summary>
        /// Tung.Tran [17/09/2018][97990] Hàm lấy tổng giờ làm thực thế SUM(att_attendancetableitem.WorkPaidHours)
        /// </summary>
        /// <param name="ListAttTable"></param>
        /// <param name="ListAttTableItem"></param>
        /// <param name="Cutoffduration"></param>
        /// <param name="ProfileID"></param>
        /// <param name="DateClosePay"></param>
        /// <returns></returns>
        public Double GetTotalWorkPaidHours(List<Att_AttendanceTableEntity> ListAttTable, List<Att_AttendanceTableItemEntity> ListAttTableItem, Att_CutOffDurationEntity Cutoffduration, Guid ProfileID, int DateClosePay)
        {
            using (var context = new VnrHrmDataContext())
            {
                var unitOfWork = (IUnitOfWork)(new UnitOfWork(context));
                if (Cutoffduration != null)
                {
                    var AttTable = ListAttTable.Where(m => m.IsDelete != true && m.ProfileID == ProfileID && m.CutOffDurationID == Cutoffduration.ID).FirstOrDefault();
                    if (AttTable != null)
                    {

                        // Lấy ra N dòng bảng công chi tiết (tăng dần theo ngày công) với N = số ngày chốt tạm ứng
                        ListAttTableItem = ListAttTableItem.Where(m => m.AttendanceTableID == AttTable.ID).OrderBy(m => m.WorkDate).Take(DateClosePay).ToList();
                        return ListAttTableItem.Sum(a => a.WorkPaidHours);
                    }
                    else
                    {
                        return 0;
                    }
                }
                else
                {
                    return 0;
                }
            }
        }



        /// <summary>
        /// Tung.Tran [17/09/2018][97990] Hàm lấy tổng Tổng số giờ nghỉ có lương  SUM(att_attendancetableitem.PaidLeaveHours)
        /// </summary>
        /// <param name="ListAttTable"></param>
        /// <param name="ListAttTableItem"></param>
        /// <param name="Cutoffduration"></param>
        /// <param name="ProfileID"></param>
        /// <param name="DateClosePay"></param>
        /// <returns></returns>
        public Double GetTotalPaidLeaveHours(List<Att_AttendanceTableEntity> ListAttTable, List<Att_AttendanceTableItemEntity> ListAttTableItem, Att_CutOffDurationEntity Cutoffduration, Guid ProfileID, int DateClosePay)
        {
            using (var context = new VnrHrmDataContext())
            {
                var unitOfWork = (IUnitOfWork)(new UnitOfWork(context));
                if (Cutoffduration != null)
                {
                    var AttTable = ListAttTable.Where(m => m.IsDelete != true && m.ProfileID == ProfileID && m.CutOffDurationID == Cutoffduration.ID).FirstOrDefault();
                    if (AttTable != null)
                    {

                        // Lấy ra N dòng bảng công chi tiết (tăng dần theo ngày công) với N = số ngày chốt tạm ứng
                        ListAttTableItem = ListAttTableItem.Where(m => m.AttendanceTableID == AttTable.ID).OrderBy(m => m.WorkDate).Take(DateClosePay).ToList();
                        return ListAttTableItem.Sum(a => a.PaidLeaveHours);
                    }
                    else
                    {
                        return 0;
                    }
                }
                else
                {
                    return 0;
                }
            }
        }
    }
}
