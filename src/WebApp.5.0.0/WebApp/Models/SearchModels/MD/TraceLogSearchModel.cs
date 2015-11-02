using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace com.Sconit.Web.Models.SearchModels.MD
{
    public class TraceLogSearchModel : SearchModelBase
    {
        public string Table { get; set; }
        public string OperatorType { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
    }
}