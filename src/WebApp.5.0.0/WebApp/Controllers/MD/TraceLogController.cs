using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Telerik.Web.Mvc;
using com.Sconit.Utility;
using com.Sconit.Web.Models.SearchModels.MD;
using com.Sconit.Web.Models;
using com.Sconit.Entity.MD;

namespace com.Sconit.Web.Controllers.MD
{
    public class TraceLogController : WebAppBaseController
    {

        /// <summary>
        /// hql to get count of the address
        /// </summary>
        private static string selectCountStatement = "select count(*) from TraceLog as t";

        /// <summary>
        /// hql to get all of the address
        /// </summary>
        private static string selectStatement = "select t from TraceLog as t";

        //
        // GET: /TraceLog/
        public ActionResult Index()
        {
            return View();
        }


                /// <summary>
        /// List action
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel">Address Search model</param>
        /// <returns>return the result view</returns>
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_TraceLog_View")]
        public ActionResult List(GridCommand command, TraceLogSearchModel searchModel)
        {
            SearchCacheModel searchCacheModel = this.ProcessSearchModel(command, searchModel);
            if (searchCacheModel.isBack == true)
            {
                ViewBag.Page = searchCacheModel.Command.Page==0 ? 1 : searchCacheModel.Command.Page;
            }
            ViewBag.PageSize = base.ProcessPageSize(command.PageSize);
            return View();
        }

        /// <summary>
        ///  AjaxList action
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel">Address Search Model</param>
        /// <returns>return the result action</returns>
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_TraceLog_View")]
        public ActionResult _AjaxList(GridCommand command, TraceLogSearchModel searchModel)
        {
            this.GetCommand(ref command, searchModel);
            SearchStatementModel searchStatementModel = this.PrepareSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<TraceLog>(searchStatementModel, command));
        }

        /// <summary>
        /// New action
        /// </summary>
        /// <returns>New view</returns>
        [SconitAuthorize(Permissions = "Url_TraceLog_View")]
        public ActionResult Execute()
        {
            try
            {
                this.genericMgr.FindAllWithNativeSql<string>("USP_Help_FormatLog").FirstOrDefault();
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return Json(null);
        }


        /// <summary>
        /// Edit view
        /// </summary>
        /// <param name="id">address id for edit</param>
        /// <returns>return the result view</returns>
        [HttpGet]
        [SconitAuthorize(Permissions = "Url_TraceLog_View")]
        public ActionResult Edit(string id)
        {
            if (string.IsNullOrEmpty(id))
            {
                return HttpNotFound();
            }
            else
            {
                TraceLog traceLog = this.genericMgr.FindById<TraceLog>(int.Parse(id));
                return View(traceLog);
            }
        }

        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_TraceLog_View")]
        public ActionResult _DetailList(string id)
        {
            IList<TraceLogDetail> details = new List<TraceLogDetail>();
            if (!string.IsNullOrEmpty(id))
            {
                details = this.genericMgr.FindAll<TraceLogDetail>("from TraceLogDetail as tl where tl.TraceLogId=?", int.Parse(id));
            }
            return PartialView(details);
        }


        /// <summary>
        /// Search Statement
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel">Address Search Model</param>
        /// <returns>return address search model</returns>
        private SearchStatementModel PrepareSearchStatement(GridCommand command, TraceLogSearchModel searchModel)
        {            
            string whereStatement = string.Empty;

            IList<object> param = new List<object>();

            HqlStatementHelper.AddEqStatement("EntityTable", searchModel.Table, "t", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Operator", searchModel.OperatorType, "t", ref whereStatement, param);
            //HqlStatementHelper.AddLikeStatement("PostCode", searchModel.PostCode, HqlStatementHelper.LikeMatchMode.Start, "u", ref whereStatement, param);
            //HqlStatementHelper.AddLikeStatement("TelPhone", searchModel.TelPhone, HqlStatementHelper.LikeMatchMode.Start, "u", ref whereStatement, param);
            //HqlStatementHelper.AddLikeStatement("MobilePhone", searchModel.MobilePhone, HqlStatementHelper.LikeMatchMode.Start, "u", ref whereStatement, param);
            //HqlStatementHelper.AddLikeStatement("Fax", searchModel.Fax, HqlStatementHelper.LikeMatchMode.Start, "u", ref whereStatement, param);
            //HqlStatementHelper.AddLikeStatement("Email", searchModel.Email, HqlStatementHelper.LikeMatchMode.Start, "u", ref whereStatement, param);
            //HqlStatementHelper.AddLikeStatement("ContactPersonName", searchModel.ContactPersonName, HqlStatementHelper.LikeMatchMode.Start, "u", ref whereStatement, param);
            //HqlStatementHelper.AddEqStatement("Type", searchModel.Type, "u", ref whereStatement, param);

            if (searchModel.DateFrom != null & searchModel.DateTo != null)
            {
                HqlStatementHelper.AddBetweenStatement("OperateDate", searchModel.DateFrom, searchModel.DateTo, "t", ref whereStatement, param);
            }
            else if (searchModel.DateFrom != null & searchModel.DateTo == null)
            {
                HqlStatementHelper.AddGeStatement("OperateDate", searchModel.DateFrom, "t", ref whereStatement, param);
            }
            else if (searchModel.DateFrom == null & searchModel.DateTo != null)
            {
                HqlStatementHelper.AddLeStatement("OperateDate", searchModel.DateTo, "t", ref whereStatement, param);
            }

            //if (command.SortDescriptors.Count > 0)
            //{
            //    if (command.SortDescriptors[0].Member == "AddressTypeDescription")
            //    {
            //        command.SortDescriptors[0].Member = "Type";
            //    }
            //}
            string sortingStatement = HqlStatementHelper.GetSortingStatement(command.SortDescriptors);

            SearchStatementModel searchStatementModel = new SearchStatementModel();
            searchStatementModel.SelectCountStatement = selectCountStatement;
            searchStatementModel.SelectStatement = selectStatement;
            searchStatementModel.WhereStatement = whereStatement;
            searchStatementModel.SortingStatement = sortingStatement;
            searchStatementModel.Parameters = param.ToArray<object>();

            return searchStatementModel;
        }

    }
}
