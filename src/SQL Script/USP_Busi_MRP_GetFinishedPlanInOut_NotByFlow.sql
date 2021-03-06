USE [Sconit]
GO
/****** Object:  StoredProcedure [dbo].[USP_Busi_MRP_GetFinishedPlanInOut_NotByFlow]    Script Date: 12/22/2014 18:28:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		
-- Create date: 
-- Description:	已完成的收发
--========
ALTER PROCEDURE [dbo].[USP_Busi_MRP_GetFinishedPlanInOut_NotByFlow]
(
	@PlanVersion datetime,
	@Flow varchar(50)
)
AS

BEGIN
	--2014/4/16 开始时间@StartDate取@PlanVersion date&补足PlanVersion里面没有的日期 --0001
	Set @Flow = LEFT(@Flow,4)
    Declare @SnapTime datetime 
    select top 1 @SnapTime=SnapTime from MRP_MrpPlanMaster With(nolock) where PlanVersion = @PlanVersion
    print @SnapTime
	Declare @CurrentTime datetime=getdate()
	Select a.item into #Items from SCM_FlowDet a with(nolock), SCM_FlowMstr d with(nolock)
				where a.Flow=d.Code 
				and d.IsMRP = 1 and d.Type =4 and d.ResourceGroup = 30
				and d.IsActive =1 and a.MrpWeight>0
				and (a.StartDate is null or a.StartDate<@CurrentTime)and (a.EndDate is null or a.EndDate>@CurrentTime)
				and isnull(a.Machine,'')!='' 
    --这个变量很重要，算出当前的工作日，Example如果是18号，那么18号之前的算作已发已收的范畴
    Declare @CurrentPlandate date = dbo.FormatDate(@CurrentTime,'YYYY/MM/DD')
    Declare @VersionPlandate date = dbo.FormatDate(@PlanVersion,'YYYY/MM/DD')
    If  dbo.FormatDate(@CurrentTime,'HHNNSS') between '000000' and '090000' 
		Begin
			Set @CurrentPlandate=dbo.FormatDate(dateadd(day,-1,@CurrentTime),'YYYY/MM/DD')
		End
	--版本的开始和结束时间
	Declare @StartDate datetime
	Declare @EndDate datetime
	Declare @StartShipDate datetime
	Declare @EndShipDate datetime
	Declare @IsMrp bit
	Declare @ResourceGroup int
	--0001@VersionPlandate
	--select @StartDate =MIN(PlanDate) from MRP_MrpFiShiftPlan where PlanVersion=@Planversion
	Select @StartDate=dbo.FormatDate(@PlanVersion,'YYYY-MM-DD 00:00:00')
	--0001
	select @EndDate = dbo.Format_To_Date(dbo.FormatDate(GETDATE(),'YYYYMMDD ')+'000000')
	Select @StartShipDate=DATEADD(MINUTE,465,@StartDate),@EndShipDate = DATEADD(MINUTE,465,@EndDate)
	 
	--select @StartDate,@EndDate,@IsMrp,@StartShipDate,@EndShipDate 
	Select case when IOType=0 then '入' else '出' End 动作, Case when dbo.FormatDate(EffDate,'HHNNSS') between '000000' and '090000' 
		then dbo.FormatDate(DATEADD(day,-1,EffDate),'YYYY/MM/DD') 
		else  dbo.FormatDate(EffDate,'YYYY/MM/DD') End as PlanDate,Item,SUM(Qty*UnitQty) As Qty
		into #TEMP1
		from VIEW_LocTrans where  Item in(select Item from #Items)
		and EffDate between @StartShipDate and @EndShipDate
		Group by case when IOType=0 then '入' else '出' End , Case when dbo.FormatDate(EffDate,'HHNNSS') between '000000' and '090000' 
		then dbo.FormatDate(DATEADD(day,-1,EffDate),'YYYY/MM/DD') 
		else  dbo.FormatDate(EffDate,'YYYY/MM/DD') End ,Item
	Update #TEMP1 Set 动作 ='出' where 动作 ='入' and Qty <0
	Update #TEMP1 Set 动作 ='入' where 动作 ='出' and Qty >0
	
	Select PlanDate,Item ,SUM(ABS(qty)) qty into #SHIPPEDQQTY from #TEMP1 where 动作 ='出' group by PlanDate,Item
	Select PlanDate,Item ,SUM(ABS(qty)) qty into #RECCEDQQTY from #TEMP1 where 动作 ='入' group by PlanDate,Item
	
	--return
 
	select dbo.FormatDate(PlanDate,'YYYY/MM/DD') As PlanDate,Item,sum(Qty) As PlanRecQty into #PlanRecQty from MRP_MrpFiShiftPlan with(nolock) 
		where PlanVersion=@Planversion /*and Qty!=0 and ProductLine=@Flow*/ 
		Group by dbo.FormatDate(PlanDate,'YYYY/MM/DD'),Item
	--0001Begin
	--补足PlanVersion里面没有的日期
	Insert into #PlanRecQty
		Select distinct PlanDate ,Item ,0 As Qty  from #RECCEDQQTY a where not exists(
			Select 0 from #PlanRecQty b where a.PlanDate =b.PlanDate and a.Item =b.Item )
	Insert into #PlanRecQty
		Select distinct PlanDate ,Item ,0 As Qty  from #SHIPPEDQQTY a where not exists(
			Select 0 from #PlanRecQty b where a.PlanDate =b.PlanDate and a.Item =b.Item )
	--0001End
	
	Select a.PlanDate,a.Item,isnull(a.PlanRecQty,0),0 PlanShipQty,isnull(c.qty,0)ReceivedQty,isnull(d.qty,0) ShippedQty
		from #PlanRecQty a 
		Left join #RECCEDQQTY c on a.PlanDate =c.plandate and a.Item=c.Item 
		Left join #SHIPPEDQQTY d on a.PlanDate =d.plandate and a.Item=d.Item 
		where a.Item in (select * from #Items) and a.PlanDate < @CurrentPlandate 
	
END


