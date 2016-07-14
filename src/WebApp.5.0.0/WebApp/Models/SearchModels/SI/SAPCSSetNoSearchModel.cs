using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace com.Sconit.Web.Models.SearchModels.SI
{
    public class SAPCSSetNoSearchModel : SearchModelBase
    {
        public string SetTransId { get; set; }

        public string SetNo { get; set; }

        public string Party { get; set; }

        public DateTime? DateFrom { get; set; }

        public DateTime? DateTo { get; set; }
    }
}