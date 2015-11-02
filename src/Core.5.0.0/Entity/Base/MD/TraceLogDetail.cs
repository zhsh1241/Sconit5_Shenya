using System;
using System.Collections;
using System.Collections.Generic;

//TODO: Add other using statements here

namespace com.Sconit.Entity.MD
{
    [Serializable]
    public class TraceLogDetail : EntityBase
    {
        #region O/R Mapping Properties


        public Int32 Id { get; set; }

        public Int32 TraceLogId { get; set; }

        public string Field { get; set; }

        public string OldValue { get; set; }

        public string NewValue { get; set; }
        
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
            TraceLogDetail another = obj as TraceLogDetail;

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
