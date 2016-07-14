using System.Data;
using System.Web.Mvc;
using com.Sconit.Utility;
using Telerik.Web.Mvc;
using com.Sconit.Web.Models.SearchModels.SI;
using System.Data.SqlClient;
using System;
using com.Sconit.Entity.Exception;
using com.Sconit.Service.SI.SAP;
using com.Sconit.Web.Models;
using com.Sconit.Entity.SI.SAP;
using System.Collections.Generic;
using System.Linq;
using com.Sconit.Entity.SYS;
using System.Web.Routing;
using com.Sconit.Service;
using NHibernate.Type;
using NHibernate;
using com.Sconit.Entity;
using com.Sconit.Entity.INV;
using System.Text;


namespace com.Sconit.Web.Controllers.SI
{
    public class SAPCSSetNoController : WebAppBaseController
    {
        //
        #region Properties
        /// <summary>
        /// Gets or sets the this.GeneMgr which main consider the Currency security 
        /// </summary>
        //public IGenericMgr genericMgr { get; set; }

        //public ICurrencyMgr currencyMgr { get; set; }
        #endregion

        /// <summary>
        /// hql to get count of the currency 
        /// </summary>
        private static string selectCountStatement = "select count(*) from SAPCSSetNo as s";

        /// <summary>
        /// hql to get all of the currency
        /// </summary>
        private static string selectStatement = "select s from SAPCSSetNo as s";


        #region public actions
        /// <summary>
        /// Index action for Currency controller
        /// </summary>
        /// <returns>Index view</returns>
        [SconitAuthorize(Permissions = "Url_SI_SAPCSSetNo_View")]
        public ActionResult Index()
        {
            return View();
        }

        /// <summary>
        /// List action
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel">Currency Search model</param>
        /// <returns>return the result view</returns>
        [GridAction]
        [SconitAuthorize(Permissions = "Url_SI_SAPCSSetNo_View")]
        public ActionResult List(GridCommand command, SAPCSSetNoSearchModel searchModel)
        {
            SearchCacheModel searchCacheModel = this.ProcessSearchModel(command, searchModel);
            if (searchCacheModel.isBack == true)
            {
                ViewBag.Page = searchCacheModel.Command.Page == 0 ? 1 : searchCacheModel.Command.Page;
            }
            ViewBag.PageSize = base.ProcessPageSize(command.PageSize);
            return View();
        }

        /// <summary>
        /// AjaxList action
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel">Currency Search Model</param>
        /// <returns>return the result Model</returns>
        [GridAction(EnableCustomBinding = true)]
        [SconitAuthorize(Permissions = "Url_SI_SAPCSSetNo_View")]
        public ActionResult _AjaxList(GridCommand command, SAPCSSetNoSearchModel searchModel)
        {
            this.GetCommand(ref command, searchModel);
            SearchStatementModel searchStatementModel = this.PrepareSearchStatement(command, searchModel);
            return PartialView(GetAjaxPageData<SAPCSSetNo>(searchStatementModel, command));
        }

        /// <summary>
        /// New action
        /// </summary>
        /// <param name="currency">currency model</param>
        /// <returns>return to Edit action </returns>

        [SconitAuthorize(Permissions = "Url_SI_SAPCSSetNo_View")]
        public ActionResult _ProcessData()
        {
            this.genericMgr.FindAllWithNamedQuery("USP_Report_PorcessSetNo");
            return Json(null);
        }
        #endregion

        /// <summary>
        /// Search Statement
        /// </summary>
        /// <param name="command">Telerik GridCommand</param>
        /// <param name="searchModel">Currency Search Model</param>
        /// <returns>return Search Statement</returns>
        private SearchStatementModel PrepareSearchStatement(GridCommand command, SAPCSSetNoSearchModel searchModel)
        {
            string whereStatement = string.Empty;

            IList<object> param = new List<object>();

            HqlStatementHelper.AddEqStatement("SetTransId", searchModel.SetTransId, "s", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("SetNo", searchModel.SetNo, "s", ref whereStatement, param);
            HqlStatementHelper.AddEqStatement("Supplier", searchModel.Party, "s", ref whereStatement, param);


            if (searchModel.DateFrom != null & searchModel.DateTo != null)
            {
                HqlStatementHelper.AddBetweenStatement("CreateDate", searchModel.DateFrom, searchModel.DateTo, "s", ref whereStatement, param);
            }
            else if (searchModel.DateFrom != null & searchModel.DateTo == null)
            {
                HqlStatementHelper.AddGeStatement("CreateDate", searchModel.DateFrom, "s", ref whereStatement, param);
            }
            else if (searchModel.DateFrom == null & searchModel.DateTo != null)
            {
                HqlStatementHelper.AddLeStatement("CreateDate", searchModel.DateTo, "s", ref whereStatement, param);
            }

            string sortingStatement = string.Empty;
            if (command.SortDescriptors.Count == 0)
            {
                sortingStatement = " order by CreateDate desc";
            }
            else
            {
                sortingStatement = HqlStatementHelper.GetSortingStatement(command.SortDescriptors);
            }
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
