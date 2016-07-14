using System;
using System.ComponentModel.DataAnnotations;
using com.Sconit.Entity.SYS;

namespace com.Sconit.Entity.SI.SAP
{
    [Serializable]
    public partial class SAPCSSetNo : EntityBase
    {
        #region O/R Mapping Properties
		
		public Int32 Id { get; set; }

        public Int32 ActBill { get; set; }
        public Int32 SetTransId { get; set; }

        public string SetNo { get; set; }
        public string SetRec { get; set; }
        public string Item { get; set; }
        public string Qty { get; set; }
        public string Uom { get; set; }
        public string Supplier { get; set; }
        public string OrgOrderNo { get; set; }
        public string OrgRecNo { get; set; }
        public string BatchNo { get; set; }
        public DateTime CreateDate { get; set; }

        #endregion

		public override int GetHashCode()
        {
			if (Id != 0)
            {
                return Id.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            SAPCSSetNo another = obj as SAPCSSetNo;

            if (another == null)
            {
                return false;
            }
            else
            {
            	return (this.Id == another.Id);
            }
        }

        
    }
	
}
