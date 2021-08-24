
--------------------------------CONSTRAINT-----------------------------------------
ALTER table [dbo].[Family_OF_Managers_Center] WITH NOCHECK

ADD CONSTRAINT [CONS_AGE]

CHECK 
(

DATEDIFF(YY,BirthDate,getdate()) -
IIF
(
(MONTH(BirthDate)*100 + DAY(BirthDate)) > (MONTH(getdate())*100 + DAY(getdate())),1,0
)
<18

)




GO 


---------------------------CURSOR---------------------------------
DECLARE 

@PaymetDuDate DATE , 
@InvoicePayDate DATE

SET @PaymetDuDate  =(select DISTINCT Payment_DueDate FROM Payment_System )


DECLARE MYCURSOR_BLACK CURSOR

for 
(
select InvoicePayDate FROM Payment_System 
)

OPEN MYCURSOR_BLACK 
FETCH NEXT FROM  MYCURSOR_BLACK INTO @InvoicePayDate

WHILE @@FETCH_STATUS=0 
 
 BEGIN  

 
 set @PaymetDuDate= @PaymetDuDate 

 if (
       DATEDIFF(dd,getdate() ,@PaymetDuDate )=1  and @InvoicePayDate is null
     )

		BEGIN
		INSERT INTO black_list ([Customer_id],[Entery_date])
		(
		select Customr_ID,GETDATE() 
		from payment_system
		)
        fetch next from  Mycursor into @PaymetDuDate
        END

fetch next from  Mycursor into @PaymetDuDate

END 

CLOSE MYCURSOR_BLACK
DEALLOCATE MYCURSOR_BLACK


GO



--------------------------------------TABLE FUNC--------------------------------------
CREATE FUNCTION Cake_Voucher (@DATE int)

RETURNS table 
	
AS

RETURN 
(

		select 
		t.Manager_ID,
		CASE WHEN COUNT(T.Birth_Date)> 4 THEN 'VOUCHER' ELSE 'CAKE' END AS [Cake OR Voucher]		
	     
		 from (
		    select  Manager_ID,Birth_Date, ' 'as Manager_Spouse_OR_Child
			from Managers_Center
		    where ReportTo is null --and Birth_Date=convert(date,GETDATE())  
			
			union

			select fmc.Manager_ID,fmc.BirthDate,fmc.Spouse_OR_Child
			from [dbo].[Family_OF_Managers_Center] as fmc 
			              join Managers_Center as mc 
						  on fmc.Manager_ID=mc.Manager_ID
			 
			 where mc.ReportTo is null
           ) as t

		   where
		   DAY(t.Birth_Date)   <= DAY(getdate()) AND
		   MONTH(t.Birth_Date) <= MONTH(getdate())

		 GROUP BY t.Manager_ID


)

GO



---------------------------------Temporale Table Exchange_Rate--------------------------
USE [Ahitofel_YossiElla_23082021]
GO

/****** Object:  Table [dbo].[Exchange_Rate]    Script Date: 24/08/2021 19:56:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Exchange_Rate](
	[Currency_Id] [float] NOT NULL,
	[Curreny_name] [varchar](10) NULL,
	[Exchange_Rate] [float] NULL,
	[ValidFrom] [datetime2](2) GENERATED ALWAYS AS ROW START NOT NULL,
	[ValidTo] [datetime2](2) GENERATED ALWAYS AS ROW END NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Currency_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
	PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
) ON [PRIMARY]
WITH
(
SYSTEM_VERSIONING = ON ( HISTORY_TABLE = [dbo].[MSSQL_TemporalHistoryFor_1829581556] )
)
GO