USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_SAP_MM_ExportPurOrder]    Script Date: 12/08/2014 10:31:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec USP_SAP_MM_ExportPurOrder '1231','2014-04-01','2014-04-30'
select * from SAP_Interface_MMMES001
*/

ALTER PROCEDURE [dbo].[USP_SAP_MM_ExportPurOrder]
(
	@BatchNo varchar(50),
	@StartTime datetime,
	@EndTime datetime
)
AS
BEGIN
	----2014/06/21	Add UnitQty 0001
	----2014/08/04	采购转手贸易 0002
	----2014/08/25	冲销数据收集 0003
	----2014/09/16	C346 30709-9306不传给SAP 0004
	----2014/09/25	销售转手贸易价格单取维护的价格单 0005
	SET NOCOUNT ON
		DECLARE @CurrDate datetime=GETDATE()
		DECLARE @EKORG varchar(50),@WERKS varchar(50),@BUKRS varchar(50)
		--从重庆直接销售需要走转手贸易（重庆---》申雅----》客户）
		DECLARE @ResaleTradeFlow varchar(4000)=''
		SELECT @ResaleTradeFlow=Value FROM SYS_EntityPreference where Id=90101
		SELECT F1 As Flow INTO #SalesFlowASResaleTradeFlow FROM dbo.Func_SplitStr(@ResaleTradeFlow,'‖')
		--0002Begin
		DECLARE @PurTradeFlow varchar(4000)=''
		SELECT @PurTradeFlow=Value FROM SYS_EntityPreference where Id=90110
		SELECT F1 As Flow INTO #PurFlowASResaleTradeFlow FROM dbo.Func_SplitStr(@PurTradeFlow,'‖')
		--0002End
		--0004Begin
 		DECLARE @ExcludePurTradeFlow varchar(4000)=''
		SELECT @ExcludePurTradeFlow=Value FROM SYS_EntityPreference where Id=90111
		SELECT F1 As Flow INTO #ExcludePurFlowASResaleTradeFlow FROM dbo.Func_SplitStr(@ExcludePurTradeFlow,'‖')
		--00004End
		---select * from SYS_EntityPreference
		SELECT @EKORG=Value FROM SYS_EntityPreference WHERE Id=90105
		SELECT @BUKRS=Value FROM SYS_EntityPreference WHERE Id=90106
		SELECT @WERKS=Value FROM SYS_EntityPreference WHERE Id=90107
		---插入非寄售采购数据
		INSERT INTO SAP_Interface_MMMES0001(ZMESPO, LIFNR, BSART, EKORG, EKGRP, BUKRS, BWART_H, LFSNR, BUDAT, BLDAT, EBELP_I, EPSTP, 
			MATNR, TARGET_QTY_I, NETPR, PEINH, WAERS, BPRME_I, EINDT, WERKS, LGORT, RETPO, BWART_C, MATNR_C, TARGET_QTY_C, 
			BPRME_C, ZMESGUID, ZCSRQSJ, Status, BatchNo)
		SELECT DISTINCT rm.RecNo,CASE WHEN rm.OrderSubType=1 THEN rm.PartyTo ELSE rm.PartyFrom END AS Supplier,'NB' AS BSART,@EKORG AS EKORG,
			CASE WHEN rm.OrderSubType=1 THEN st.PurchaseGroup ELSE sf.PurchaseGroup END AS EKGRP,@BUKRS AS BUKRS,CASE WHEN rm.OrderSubType=1 THEN '122' ELSE '101' END AS BWART_H,
			rd.OrderNo,rm.EffDate,rm.EffDate,rd.Seq,'' AS EPSTP,rd.Item,CAST(rd.RecQty*rd.UnitQty AS decimal(10,3)) AS Qty,CAST(rd.UnitPrice AS decimal(10,3)) AS NETPR,1 AS PEINH,
			rd.Currency,i.Uom,rm.CreateDate,@WERKS AS WERKS,
			--0002Begin
			CASE WHEN rm.OrderSubType=1 AND ISNULL(prtf.Flow,'')='' THEN lf.SAPLocation 
			WHEN rm.OrderSubType=1 AND ISNULL(prtf.Flow,'')<>'' THEN '7001'
			WHEN rm.OrderSubType=0 AND ISNULL(prtf.Flow,'')='' THEN lt.SAPLocation
			WHEN rm.OrderSubType=0 AND ISNULL(prtf.Flow,'')<>'' THEN '7001' END AS LGORT,
			--0002End
			CASE WHEN rm.OrderSubType=1 THEN 'X' ELSE '' END AS RETPO,'','','','',
			rm.RecNo+'0',@CurrDate,0,@BatchNo
		FROM ORD_RecMstr_1 rm INNER JOIN ORD_RecDet_1 rd ON rm.RecNo=rd.RecNo
		INNER JOIN SCM_FlowMstr fm ON rm.Flow=fm.Code 	
		INNER JOIN MD_Item i ON rd.Item=i.Code
		--INNER JOIN BIL_PriceListMstr pm ON rd.PriceList=pm.Code 
		--INNER JOIN BIL_PriceListDet pd ON rd.Item=pd.Item AND pm.Code=pd.PriceList AND rd.UnitPrice=pd.UnitPrice
		LEFT JOIN MD_Supplier sf ON sf.Code=rm.PartyFrom
		LEFT JOIN MD_Supplier st ON st.Code=rm.PartyTo
		LEFT JOIN MD_Location lf ON lf.Code=rd.LocFrom
		LEFT JOIN MD_Location lt ON lt.Code=rd.LocTo
		LEFT JOIN #PurFlowASResaleTradeFlow prtf ON prtf.Flow=rm.Flow
		WHERE rm.CreateDate>@StartTime AND rm.CreateDate<=@EndTime AND rm.Type=0 AND rd.BillTerm=1 AND rm.CreateUser<>3910
		--0004
		AND rm.Flow not in(select Flow from #ExcludePurFlowASResaleTradeFlow)
		
		---插入重庆销售数据
		--0005
			Select   top 0 *,SPACE(50) As Flow,SPACE(50) As PriceList into #SAP_Interface_MMMES0001_Temp from  SAP_Interface_MMMES0001
		--0005
		--SP_HELP'ORD_RecDet_3'
		INSERT INTO #SAP_Interface_MMMES0001_Temp(ZMESPO, LIFNR, BSART, EKORG, EKGRP, BUKRS, BWART_H, LFSNR, BUDAT, BLDAT, EBELP_I, EPSTP, 
			MATNR, TARGET_QTY_I, NETPR, PEINH, WAERS, BPRME_I, EINDT, WERKS, LGORT, RETPO, BWART_C, MATNR_C, TARGET_QTY_C, 
			BPRME_C, ZMESGUID, ZCSRQSJ, Status, BatchNo,Flow,PriceList)
		SELECT rm.RecNo,std.Supplier AS Supplier,'NB' AS BSART,@EKORG AS EKORG,
			std.PurchaseGroup AS EKGRP,@BUKRS AS BUKRS,CASE WHEN rm.OrderSubType=1 THEN '122' ELSE '101' END AS BWART_H,
			rd.OrderNo,rm.EffDate,rm.EffDate,rd.Seq,'' AS EPSTP,rd.Item,CAST(rd.RecQty*rd.UnitQty AS decimal(10,3)) AS Qty, cast(rd.UnitPrice AS decimal(10,3)) AS NETPR,1 AS PEINH,
			rd.Currency,i.Uom,rm.CreateDate,@WERKS AS WERKS,'7001' AS LGORT,
			CASE WHEN rm.OrderSubType=1 THEN 'X' ELSE '' END AS RETPO,'','','','',
			rm.RecNo+'0',@CurrDate,0,@BatchNo,rm.Flow As Flow,std.priceList As PriceList
		FROM ORD_RecMstr_3 rm INNER JOIN ORD_RecDet_3 rd ON rm.RecNo=rd.RecNo
		INNER JOIN SCM_FlowMstr fm ON rm.Flow=fm.Code 
		INNER JOIN MD_SwitchTrading std ON fm.Code=std.Flow	
		INNER JOIN MD_Item i ON rd.Item=i.Code
		--INNER JOIN BIL_PriceListMstr pm ON rd.PriceList=pm.Code
		--INNER JOIN BIL_PriceListDet pd ON rd.Item=pd.Item AND pm.Code=pd.PriceList AND rd.UnitPrice=pd.UnitPrice
		INNER JOIN #SalesFlowASResaleTradeFlow sfrt ON sfrt.Flow=rm.Flow 
		LEFT JOIN MD_Supplier sf ON sf.Code=rm.PartyFrom
		LEFT JOIN MD_Supplier st ON st.Code=rm.PartyTo
		LEFT JOIN MD_Location lf ON lf.Code=rd.LocFrom
		LEFT JOIN MD_Location lt ON lt.Code=rd.LocTo
		WHERE rm.CreateDate>@StartTime AND rm.CreateDate<=@EndTime AND rm.Type=0 AND rm.CreateUser<>3910
		
		--0005
		SELECT a.* into #BIL_PriceListDet_SwichTrade FROM BIL_PriceListDet a where PriceList in
		(Select PriceList from #SAP_Interface_MMMES0001_Temp)  and not exists
		(select 1 from BIL_PriceListDet b where a.Item=b.Item and a.Uom=b.Uom and a.PriceList=b.PriceList and b.StartDate>a.StartDate)
		Update a
			Set a.NETPR=cast(b.UnitPrice As decimal(10,3)) from #SAP_Interface_MMMES0001_Temp a,#BIL_PriceListDet_SwichTrade b
			Where a.MATNR=b.Item and a.PriceList =b.PriceList
		Insert into SAP_Interface_MMMES0001(ZMESPO, LIFNR, BSART, EKORG, EKGRP, BUKRS, BWART_H, LFSNR, BUDAT, BLDAT, EBELP_I, EPSTP, 
			MATNR, TARGET_QTY_I, NETPR, PEINH, WAERS, BPRME_I, EINDT, WERKS, LGORT, RETPO, BWART_C, MATNR_C, TARGET_QTY_C, 
			BPRME_C, ZMESGUID, ZCSRQSJ, Status, BatchNo)
			Select Distinct ZMESPO, LIFNR, BSART, EKORG, EKGRP, BUKRS, BWART_H, LFSNR, BUDAT, BLDAT, EBELP_I, EPSTP, 
			MATNR, TARGET_QTY_I, NETPR, PEINH, WAERS, BPRME_I, EINDT, WERKS, LGORT, RETPO, BWART_C, MATNR_C, TARGET_QTY_C, 
			BPRME_C, ZMESGUID, ZCSRQSJ, Status, BatchNo from #SAP_Interface_MMMES0001_Temp
		--0005
		---插入委外数据
		INSERT INTO SAP_Interface_MMMES0001(ZMESPO, LIFNR, BSART, EKORG, EKGRP, BUKRS, BWART_H, LFSNR, BUDAT, BLDAT, EBELP_I, EPSTP, 
			MATNR, TARGET_QTY_I, NETPR, PEINH, WAERS, BPRME_I, EINDT, WERKS, LGORT, RETPO, BWART_C, MATNR_C, TARGET_QTY_C, 
			BPRME_C, ZMESGUID, ZCSRQSJ, Status, BatchNo)
		SELECT ZMESPO, LIFNR, BSART, EKORG, EKGRP, BUKRS, BWART_H, LFSNR, BUDAT, BLDAT, EBELP_I, EPSTP, 
			MATNR, TARGET_QTY_I, NETPR, PEINH, WAERS, BPRME_I, EINDT, WERKS, LGORT, RETPO, BWART_C, MATNR_C, SUM(TARGET_QTY_C),
			BPRME_C, ZMESGUID, ZCSRQSJ, Status, BatchNo
		FROM (SELECT rm.RecNo AS ZMESPO,CASE WHEN rm.OrderSubType=1 THEN rm.PartyTo ELSE rm.PartyFrom END AS LIFNR,'NB' AS BSART,@EKORG AS EKORG,
			CASE WHEN rm.OrderSubType=1 THEN st.PurchaseGroup ELSE sf.PurchaseGroup END AS EKGRP,@BUKRS AS BUKRS,CASE WHEN rm.OrderSubType=1 THEN '122' ELSE '101' END AS BWART_H,
			rd.OrderNo AS LFSNR,rm.EffDate AS BUDAT,rm.EffDate AS BLDAT,rd.Seq AS EBELP_I,'L' AS EPSTP,rd.Item AS MATNR,CAST(rd.RecQty*rd.UnitQty AS decimal(10,3)) AS TARGET_QTY_I,
			CAST(rd.UnitPrice AS decimal(10,3)) AS NETPR,1 AS PEINH,
			rd.Currency AS WAERS,i.Uom AS BPRME_I,rm.CreateDate AS EINDT,@WERKS AS WERKS,CASE WHEN rm.OrderSubType=1 THEN lf.SAPLocation ELSE lt.SAPLocation END AS LGORT,
			CASE WHEN rm.OrderSubType=1 THEN 'X' ELSE '' END AS RETPO,'543' AS BWART_C,obd.Item AS MATNR_C,CAST((ABS(obd.BFQty)+ABS(obd.BFRejQty))*obd.UnitQty As decimal(13,3)) AS TARGET_QTY_C,obd.BaseUom AS BPRME_C,
			rm.RecNo+'0' AS ZMESGUID,@CurrDate AS ZCSRQSJ,0 AS Status,@BatchNo AS BatchNo
		FROM ORD_RecMstr_5 rm INNER JOIN ORD_RecDet_5 rd ON rm.RecNo=rd.RecNo
		INNER JOIN ORD_OrderBackflushDet obd ON obd.RecDetId=rd.Id
		INNER JOIN SCM_FlowMstr fm ON rm.Flow=fm.Code 	
		INNER JOIN MD_Item i ON rd.Item=i.Code
		--INNER JOIN BIL_PriceListMstr pm ON rd.PriceList=pm.Code
		--INNER JOIN BIL_PriceListDet pd ON rd.Item=pd.Item AND pm.Code=pd.PriceList AND rd.UnitPrice=pd.UnitPrice
		LEFT JOIN MD_Supplier sf ON sf.Code=rm.PartyFrom
		LEFT JOIN MD_Supplier st ON st.Code=rm.PartyTo
		LEFT JOIN MD_Location lf ON lf.Code=rd.LocFrom
		LEFT JOIN MD_Location lt ON lt.Code=rd.LocTo
		WHERE rm.CreateDate>@StartTime AND rm.CreateDate<=@EndTime AND rm.Type=0 AND rd.BillTerm=1 AND rm.CreateUser<>3910) AS T
		GROUP BY ZMESPO, LIFNR, BSART, EKORG, EKGRP, BUKRS, BWART_H, LFSNR, BUDAT, BLDAT, EBELP_I, EPSTP, 
			MATNR, TARGET_QTY_I, NETPR, PEINH, WAERS, BPRME_I, EINDT, WERKS, LGORT, RETPO, BWART_C, MATNR_C,
			BPRME_C, ZMESGUID, ZCSRQSJ, Status, BatchNo
		
		
		---插入寄售采购结算数据
		INSERT INTO SAP_Interface_MMMES0001(ZMESPO, LIFNR, BSART, EKORG, EKGRP, BUKRS, BWART_H, LFSNR, BUDAT, BLDAT, EBELP_I, EPSTP, 
			MATNR, TARGET_QTY_I, NETPR, PEINH, WAERS, BPRME_I, EINDT, WERKS, LGORT, RETPO, BWART_C, MATNR_C, TARGET_QTY_C, 
			BPRME_C, ZMESGUID, ZCSRQSJ, Status, BatchNo)
		SELECT ab.Id,ab.Party AS Supplier,'NB' AS BSART,@EKORG AS EKORG,
			sf.PurchaseGroup AS EKGRP,@BUKRS AS BUKRS,CASE WHEN ab.TransType=12 OR ab.BillQty<0 THEN '122' ELSE '101' END AS BWART_H,
			rd.OrderNo,ab.EffDate,ab.EffDate,1,'' AS EPSTP,rd.Item,CAST(ABS(ab.BillQty) AS decimal(10,3)) AS Qty,CAST(ab.UnitPrice AS decimal(10,3)) AS NETPR,1 AS PEINH,
			ab.Currency,i.Uom,ab.CreateDate,@WERKS AS WERKS, 
			--0002Begin
			lt.SAPLocation,
			--0002End
			CASE WHEN ab.TransType=12 OR ab.BillQty<0 THEN 'X' ELSE '' END AS RETPO,'','','','',
			rd.RecNo+'0',@CurrDate,0,@BatchNo
		FROM BIL_SettleBillTrans ab
		INNER JOIN ORD_RecDet_1 rd ON ab.RecNo=rd.RecNo AND ab.Item=rd.Item
		INNER JOIN MD_Item i ON rd.Item=i.Code
		--INNER JOIN BIL_PriceListMstr pm ON ab.PriceList=pm.Code 
		--INNER JOIN BIL_PriceListDet pd ON ab.Item=pd.Item AND pm.Code=pd.PriceList AND ab.UnitPrice=pd.UnitPrice
		INNER JOIN MD_Supplier sf ON sf.Code=ab.Party
		INNER JOIN MD_Location lt ON lt.Code=ab.LocFrom
		WHERE ab.BillTerm<>1 AND ab.CreateDate>@StartTime AND ab.CreateDate<=@EndTime AND ab.TransType IN (11,12) AND ab.CreateUser<>3910
		

		INSERT INTO SAP_Interface_MMMES0001(ZMESPO, LIFNR, BSART, EKORG, EKGRP, BUKRS, BWART_H, LFSNR, BUDAT, BLDAT, EBELP_I, EPSTP, 
			MATNR, TARGET_QTY_I, NETPR, PEINH, WAERS, BPRME_I, EINDT, WERKS, LGORT, RETPO, BWART_C, MATNR_C, TARGET_QTY_C, 
			BPRME_C, ZMESGUID, ZCSRQSJ, Status, BatchNo)
		SELECT ab.Id,ab.Party AS Supplier,'NB' AS BSART,@EKORG AS EKORG,
			sf.PurchaseGroup AS EKGRP,@BUKRS AS BUKRS,CASE WHEN ab.TransType=12 OR ab.BillQty<0 THEN '122' ELSE '101' END AS BWART_H,
			md.MiscOrderNo,ab.EffDate,ab.EffDate,1,'' AS EPSTP,md.Item,CAST(ABS(ab.BillQty) AS decimal(10,3)) AS Qty,CAST(ab.UnitPrice AS decimal(10,3)) AS NETPR,1 AS PEINH,
			ab.Currency,i.Uom,ab.CreateDate,@WERKS AS WERKS, 
			--0002Begin
			lt.SAPLocation,
			--0002End
			CASE WHEN ab.TransType=12 OR ab.BillQty<0 THEN 'X' ELSE '' END AS RETPO,'','','','',
			md.MiscOrderNo+'0',@CurrDate,0,@BatchNo
		FROM BIL_SettleBillTrans ab
		INNER JOIN ORD_MiscOrderDet md ON ab.RecNo=md.MiscOrderNo AND ab.Item=md.Item
		INNER JOIN MD_Item i ON md.Item=i.Code
		--INNER JOIN BIL_PriceListMstr pm ON ab.PriceList=pm.Code 
		--INNER JOIN BIL_PriceListDet pd ON ab.Item=pd.Item AND pm.Code=pd.PriceList AND ab.UnitPrice=pd.UnitPrice
		INNER JOIN MD_Supplier sf ON sf.Code=ab.Party
		INNER JOIN MD_Location lt ON lt.Code=ab.LocFrom
		WHERE ab.BillTerm<>1 AND ab.CreateDate>@StartTime AND ab.CreateDate<=@EndTime AND ab.TransType IN (11,12) AND ab.CreateUser<>3910

		--INSERT INTO SAP_Interface_MMMES0002(ZMESGUID,ZMESPO,ZCSRQSJ,Status,BatchNo,UniqueCode)
		--SELECT ab.PlanBill,ab.Id,@CurrDate,0,@BatchNo,@BatchNo FROM BIL_SettleBillTrans ab
		--INNER JOIN ORD_RecDet_1 rd ON ab.RecNo=rd.RecNo
		--WHERE ab.BillTerm<>1 AND ab.CreateDate>@StartTime AND ab.CreateDate<=@EndTime and ab.TransType=12
		
		INSERT INTO SAP_Interface_MMMES0002(ZMESGUID,ZMESPO,ZCSRQSJ,Status,BatchNo,UniqueCode,CancelDate)
		----0003
		--SELECT rm.RecNo+'1',rm.RecNo,@CurrDate,0,@BatchNo,@BatchNo FROM ORD_RecMstr_1 rm WHERE rm.LastModifyDate>@StartTime AND rm.LastModifyDate<=@EndTime
		--	AND rm.Status=1 AND rm.Type=0
		SELECT distinct rm.RecNo+'1',rm.RecNo,@CurrDate,0,@BatchNo,@BatchNo,rm.LastModifyDate FROM ORD_RecMstr_1 rm ,ORD_RecDet_1 rd
			WHERE rm.RecNo =rd.RecNo and rm.LastModifyDate>@StartTime AND rm.LastModifyDate<=@EndTime
			AND rm.Status=1 AND rm.Type=0
			AND rd.BillTerm=1 AND rm.LastModifyUser<>3910
			--0004
			AND rm.Flow not in(select Flow from #ExcludePurFlowASResaleTradeFlow)
		----0003
		--取重庆的销售数据的冲销	
		INSERT INTO SAP_Interface_MMMES0002(ZMESGUID,ZMESPO,ZCSRQSJ,Status,BatchNo,UniqueCode,CancelDate)
		SELECT distinct rm.RecNo+'1',rm.RecNo,@CurrDate,0,@BatchNo,@BatchNo,rm.LastModifyDate FROM ORD_RecMstr_3 rm 
		INNER JOIN #SalesFlowASResaleTradeFlow sfrt ON sfrt.Flow=rm.Flow 
		WHERE rm.LastModifyDate>@StartTime AND rm.LastModifyDate<=@EndTime
			AND rm.Status=1 AND rm.Type=0 AND rm.LastModifyUser<>3910
			
		INSERT INTO SAP_Interface_MMMES0002(ZMESGUID,ZMESPO,ZCSRQSJ,Status,BatchNo,UniqueCode,CancelDate)
		SELECT distinct rm.RecNo+'1',rm.RecNo,@CurrDate,0,@BatchNo,@BatchNo ,rm.LastModifyDate FROM ORD_RecMstr_5 rm WHERE rm.LastModifyDate>@StartTime AND rm.LastModifyDate<=@EndTime
			AND rm.Status=1 AND rm.Type=0 AND rm.LastModifyUser<>3910
			
		SELECT s1.ZMESPO INTO #TEMP1 FROM SAP_Interface_MMMES0001 s1 INNER JOIN SAP_Interface_MMMES0002 s2 ON s1.ZMESPO=s2.ZMESPO
		WHERE s1.BatchNo=@BatchNo AND s2.BatchNo=@BatchNo
		
		IF @@ROWCOUNT>0
		BEGIN
			--如果同一个时间段内存在冲销都不传
			DELETE a FROM SAP_Interface_MMMES0001 a INNER JOIN #TEMP1 b ON a.ZMESPO=b.ZMESPO
			DELETE a FROM SAP_Interface_MMMES0002 a INNER JOIN #TEMP1 b ON a.ZMESPO=b.ZMESPO
		END
			
		DECLARE @UniqueCode varchar(50)
		WHILE EXISTS(SELECT * FROM SAP_Interface_MMMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL)
		BEGIN
			DECLARE @LastOrderNo varchar(50)
			SET @UniqueCode=REPLACE(NEWID(),'-','')
			UPDATE TOP(5000) SAP_Interface_MMMES0001 SET UniqueCode=@UniqueCode WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			SELECT TOP 1 @LastOrderNo=ZMESPO FROM SAP_Interface_MMMES0001 WHERE BatchNo=@BatchNo AND UniqueCode IS NULL
			PRINT @LastOrderNo
			IF EXISTS(SELECT 1 FROM SAP_Interface_MMMES0001 WHERE BatchNo=@BatchNo AND UniqueCode=@UniqueCode AND ZMESPO=@LastOrderNo )
			BEGIN
				UPDATE SAP_Interface_MMMES0001 SET UniqueCode=@UniqueCode WHERE BatchNo=@BatchNo AND ZMESPO=@LastOrderNo
			END
		END
		SELECT Status=1,BatchNo=@BatchNo,'生成采购接口数据成功。'
END

