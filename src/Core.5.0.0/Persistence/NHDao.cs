using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Castle.Facilities.NHibernateIntegration.Util;
using NHibernate;
using NHibernate.Collection;
using NHibernate.Exceptions;
using NHibernate.Proxy;
using NHibernate.Type;
using com.Sconit.Entity;
using com.Sconit.Entity.ACC;
using com.Sconit.Entity.MD;

namespace com.Sconit.Persistence
{
    public class NHDao : NHQueryDao, INHDao
    {
        public virtual object Create(object instance)
        {
            using (ISession session = GetSession())
            {
                try
                {
                    session.Save(instance);
                    ILogable logger = instance as ILogable;
                    if (logger != null)
                    {
                        this.AddLog(instance, "CREATE");
                        //this.AddLog(instance, "Update");
                    }
                    //session.Flush();
                    return instance;
                }
                catch (Exception ex)
                {
                    throw new DataException("Could not perform Create for " + instance.GetType().Name, ex);
                }
            }
        }

        public virtual bool BatchInsert<T>(IList<T> instanceList)
        {
            if (instanceList != null && instanceList.Count > 0)
            {
                using (IStatelessSession session = GetStatelessSession())
                {
                    try
                    {
                        foreach (var instance in instanceList)
                        {
                            session.Insert(instance);
                        }
                        return true;
                    }
                    catch (Exception ex)
                    {
                        throw new DataException("Could not perform Create for " + instanceList[0].GetType().Name, ex);
                    }
                }
            }
            else
            {
                return false;
            }
        }

        public virtual void Delete(object instance)
        {
            using (ISession session = GetSession())
            {
                try
                {
                    session.Delete(instance);
                    ILogable logger = instance as ILogable;
                    if (logger != null)
                    {
                        this.AddLog(instance, "DELETE");
                        //this.AddLog(instance, "Update");
                    }
                    //session.Flush();
                }
                catch (Exception ex)
                {
                    throw new DataException("Could not perform Delete for " + instance.GetType().Name, ex);
                }
            }
        }

        public virtual void Update(object instance)
        {
            using (ISession session = GetSession())
            {
                try
                {
                    session.Update(instance);
                    ILogable logger = instance as ILogable;
                    if (logger != null)
                    {
                        this.AddLog(instance, "UPDATE");
                        //this.AddLog(instance, "Update");
                    }
                    //SaveOrUpdateCopy可以解决在hibernate中同一个session里面有了两个相同标识的错误
                    //a different object with the same identifier value was already associated with the session
                    //不知道有没有什么未知影响
                    //session.SaveOrUpdateCopy(instance);
                    //session.Flush();
                }
                catch (Exception ex)
                {
                    throw new DataException("Could not perform Update for " + instance.GetType().Name, ex);
                }
            }
        }

        public virtual void MergeUpdate(object instance)
        {
            using (ISession session = GetSession())
            {
                try
                {
                    session.Merge(instance);
                }
                catch (Exception ex)
                {
                    throw new DataException("Could not perform Update for " + instance.GetType().Name, ex);
                }
            }
        }

        public virtual void DeleteAll(Type type)
        {
            using (ISession session = GetSession())
            {
                try
                {
                    session.Delete(String.Format("from {0}", type.Name));
                    //session.Flush();
                }
                catch (Exception ex)
                {
                    throw new DataException("Could not perform DeleteAll for " + type.Name, ex);
                }
            }
        }

        public virtual void Save(object instance)
        {
            using (ISession session = GetSession())
            {
                try
                {
                    session.SaveOrUpdate(instance);
                    //session.Flush();
                }
                catch (Exception ex)
                {
                    throw new DataException("Could not perform Save for " + instance.GetType().Name, ex);
                }
            }
        }

        public virtual void Delete(string hqlString)
        {
            Delete(hqlString, (object[])null, (IType[])null);
        }

        public virtual void Delete(string hqlString, object value, IType type)
        {
            Delete(hqlString, new object[] { value }, new IType[] { type });
        }


        //public virtual void Delete(string hqlString, object value)
        //{
        //    Delete(hqlString, new object[] { value }, (IType[])null);
        //}

        //public virtual void Delete(string hqlString, object[] values)
        //{
        //    Delete(hqlString, values, (IType[])null);
        //}

        public virtual void Delete(string hqlString, object[] values, IType[] types)
        {
            if (hqlString == null || hqlString.Length == 0) throw new ArgumentNullException("hqlString");
            if (values != null && types != null && types.Length != values.Length) throw new ArgumentException("Length of values array must match length of types array");

            using (ISession session = GetSession())
            {
                try
                {
                    if (values == null)
                    {
                        session.Delete(hqlString);
                    }
                    //else if (types == null)
                    //{
                    //    session.Delete(hqlString, values);
                    //}
                    else
                    {
                        session.Delete(hqlString, values, types);
                    }
                    //session.Flush();
                }
                catch (Exception ex)
                {
                    throw new DataException("Could not perform Delete for " + hqlString, ex);
                }
            }
        }

        public virtual int ExecuteUpdateWithCustomQuery(string queryString)
        {
            return ExecuteUpdateWithCustomQuery(queryString, (object[])null, (IType[])null);
        }

        public virtual int ExecuteUpdateWithCustomQuery(string queryString, object value)
        {
            return ExecuteUpdateWithCustomQuery(queryString, new object[] { value }, (IType[])null);
        }

        public virtual int ExecuteUpdateWithCustomQuery(string queryString, object value, IType type)
        {
            return ExecuteUpdateWithCustomQuery(queryString, new object[] { value }, new IType[] { type });
        }

        public virtual int ExecuteUpdateWithCustomQuery(string queryString, object[] values)
        {
            return ExecuteUpdateWithCustomQuery(queryString, values, (IType[])null);
        }

        public virtual int ExecuteUpdateWithCustomQuery(string queryString, object[] values, IType[] types)
        {
            if (queryString == null || queryString.Length == 0) throw new ArgumentNullException("queryString");
            if (values != null && types != null && types.Length != values.Length) throw new ArgumentException("Length of values array must match length of types array");

            using (ISession session = GetSession())
            {
                try
                {
                    IQuery query = session.CreateQuery(queryString);
                    if (values != null)
                    {
                        for (int i = 0; i < values.Length; i++)
                        {
                            if (types != null && types[i] != null)
                            {
                                query.SetParameter(i, values[i], types[i]);
                            }
                            else
                            {
                                query.SetParameter(i, values[i]);
                            }
                        }
                    }

                    int resultCount = query.ExecuteUpdate();
                    return resultCount;
                }
                catch (Exception ex)
                {
                    throw new DataException("Could not perform Find for custom query : " + queryString, ex);
                }
            }
        }

        public void InitializeLazyProperties(object instance)
        {
            if (instance == null) throw new ArgumentNullException("instance");

            using (ISession session = GetSession())
            {
                foreach (object val in ReflectionUtility.GetPropertiesDictionary(instance).Values)
                {
                    if (val is INHibernateProxy || val is IPersistentCollection)
                    {
                        if (!NHibernateUtil.IsInitialized(val))
                        {
                            session.Lock(instance, LockMode.None);
                            NHibernateUtil.Initialize(val);
                        }
                    }
                }
            }
        }

        public void InitializeLazyProperty(object instance, string propertyName)
        {
            if (instance == null) throw new ArgumentNullException("instance");
            if (propertyName == null || propertyName.Length == 0) throw new ArgumentNullException("collectionPropertyName");

            IDictionary<string, object> properties = ReflectionUtility.GetPropertiesDictionary(instance);
            if (!properties.ContainsKey(propertyName))
                throw new ArgumentOutOfRangeException("collectionPropertyName", "Property "
                    + propertyName + " doest not exist for type "
                    + instance.GetType().ToString() + ".");

            using (ISession session = GetSession())
            {
                object val = properties[propertyName];

                if (val is INHibernateProxy || val is IPersistentCollection)
                {
                    if (!NHibernateUtil.IsInitialized(val))
                    {
                        session.Lock(instance, LockMode.None);
                        NHibernateUtil.Initialize(val);
                    }
                }
            }
        }

        public void FlushSession()
        {
            using (ISession session = GetSession())
            {
                session.Flush();
            }
        }

        public void CleanSession()
        {
            using (ISession session = GetSession())
            {
                session.Clear();
            }
        }

        public void GetTableProperty(object entity, out string tableName, out Dictionary<string, string> propertyAndColumnNames)
        {
            using (ISession session = GetSession())
            {
                NHibernateHelper.GetTableProperty(session, entity, out tableName, out propertyAndColumnNames);
            }
        }


        #region Trace Log
        public void AddLog<T>(T t, string operationType)
        {
            User user = SecurityContextHolder.Get();
            var props = System.ComponentModel.TypeDescriptor.GetProperties(t.GetType())
                        .Cast<System.ComponentModel.PropertyDescriptor>();
            //    //.Where(propertyInfo => propertyInfo.PropertyType.Namespace.Equals("System"))
            //            .ToArray();
            string tableName = string.Empty, primaryKey = string.Empty;
            this.GetTableNameAndPK(t, out tableName, out primaryKey);
            TraceLog log = new TraceLog();

            log.OperateDate = DateTime.Now;
            log.Operator = operationType;
            log.Entity = props.First().ComponentType.FullName;
            log.EntityTable = tableName;
            log.UserCode = user.Code;
            log.UserName = user.FullName;
            log.IsUpdated = false;
            log.Key1 = props.Where(p => p.Name == primaryKey).FirstOrDefault().GetValue(t).ToString();
            
            this.Create(log);

            //Dictionary<Type, string> dic = new Dictionary<Type, string>();
            //dic.Add(typeof(Bom), "Code");
            //dic.Add(typeof(Uom), "Code");
            //dic.Add(typeof(Item), "Code");
            //dic.Add(typeof(Location), "Code");
            //dic.Add(typeof(ItemCategory), "Code");
            //dic.Add(typeof(Region), "Code");
            //dic.Add(typeof(ShipAddress), "Code");
            //dic.Add(typeof(BillAddress), "Code");
            //dic.Add(typeof(Customer), "Code");

            foreach (var propertyInfo in props)
            {
                TraceLogDetail logDetail = new TraceLogDetail();
                logDetail.Field = propertyInfo.Name;
                logDetail.TraceLogId = log.Id;
                var pValue = propertyInfo.GetValue(t);
                if (pValue != null)
                {
                    if (string.Equals("DELETE", operationType, StringComparison.OrdinalIgnoreCase))
                    {
                        if (pValue.GetType().BaseType == typeof(EntityBase))
                        {
                            logDetail.OldValue = pValue.GetType().GetProperty("Id").GetValue(pValue, null).ToString();
                        }
                        else
                        {
                            logDetail.OldValue = pValue == null ? string.Empty : pValue.ToString();
                        }
                    }
                    else
                    {
                        if (pValue.GetType().BaseType == typeof(EntityBase))
                        {
                            logDetail.NewValue = pValue.GetType().GetProperty("Id").GetValue(pValue, null).ToString();
                        }
                        else
                        {
                            logDetail.NewValue = pValue == null ? string.Empty : pValue.ToString();
                        }
                    }
                    this.Create(logDetail);
                }
            }

            this.FindAllWithNativeSql<object>("USP_Help_FormatLog ?",  log.Id);
            //this.FindAllWithNamedQuery("USP_Help_FormatLog ?", log.Id);
            //ISession session = this.GetSession();
            //using (var conn = session.Connection)
            //{
            //    conn.Open();
            //    System.Data.SqlClient.SqlCommand cmd = new System.Data.SqlClient.SqlCommand();
            //    cmd.CommandText = "USP_Help_FormatLog";
            //    cmd.Connection = (System.Data.SqlClient.SqlConnection)conn;
            //    cmd.Parameters.Add(new System.Data.SqlClient.SqlParameter("@p1", log.Id));
            //    cmd.ExecuteScalar();
            //}
        }

        public void GetTableNameAndPK(object entity, out string tableName, out string promaryKey)
        {
            using (ISession session = GetSession())
            {
                NHibernateHelper.GetTableNameAndPK(session, entity, out tableName, out promaryKey);
            }
        }
        #endregion
    }
}
