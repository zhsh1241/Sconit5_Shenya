using System;
using System.Collections;
using System.Collections.Generic;
using com.Sconit.Entity.SYS;

//TODO: Add other using statements here

namespace com.Sconit.Entity.MD
{
    [Serializable]
    public class TraceLog : EntityBase
    {
        #region O/R Mapping Properties


        public Int32 Id { get; set; }

        public string Entity { get; set; }

        public string EntityTable { get; set; }

        public string Operator { get; set; }

        public string Key1 { get; set; }

        public string Key2 { get; set; }

        public string Key3 { get; set; }

        public DateTime? OperateDate { get; set; }

        public string UserCode { get; set; }

        public string UserName { get; set; }

        public Boolean IsUpdated { get; set; }


        [CodeDetailDescriptionAttribute(CodeMaster = com.Sconit.CodeMaster.CodeMaster.TraceTable, ValueField = "EntityTable")]
        public string EntityTableDescription { get; set; }
        
        #endregion

		public override int GetHashCode()
        {
			if (Id != null)
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
            TraceLog another = obj as TraceLog;

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
