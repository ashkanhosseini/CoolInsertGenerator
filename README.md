CoolInsertGenerator
===================

Writing an insert stored procedure in SQL for a giant table is a hard job. You have to hardcode all the tedious code , you should declare input parameters for your SP and then select all those columns in INSERT VALUES command and pass in all those parameters again. This stored procedure can be used for creating those kind of stored procedures. It can do all the hard work for you.

INSTRUCTION : 

1.Execute the code for creating the USP_CoolInsertGenerator stored procedure.
2.Then Execute the USP_CoolInsertGenerator with passing the schema name and the table name to which you want to create an insert stored procedure for.

PARAMETERS : 
1.@TableSchema : Name of the schema in which the table exists
2.@TableName : Name of the table for which the stored procedure should be craeted for
3.@StoreProcName : A name for the stored procedure to be created. 
      -If you don't pass this parameter the following naming convention will be user for creating the stored procedure : 
          USP_TableName_Insert'
      -If you pass the StoreProcName with schema name make sure that the schema is created.

4.@EscapePKColumns : If the generator should or shouldn't include PK columns in insert (true if it shouldn't). True by default
5.@EscapeComputedColumns : If the generator should or shouldn't include computed columns in insert (true if it shouldn't). True by default
6.@EscapeUniqueidentifierColumns : If the generator should or shouldn't include Uniqueidentifier columns in insert (true if it shouldn't). True by default
7.@ShowOutput : true will only print the generated code . false will literally create the storedprocedure. True by default

=====================================EXAMPLE OF GENERATED CODE===================================================
For instance executing the following code in AdventureWorks database :

  EXEC USP_CoolInsertGenerator 'Production' , 'Product' , @ShowOutput = 0
  
Will create the following stored procedure, notice that the last part which is commented out is for testing the execution of your stored procedure :


USE [AdventureWorks2012]
GO
/****** Object:  StoredProcedure [dbo].[USP_Product_Insert]    Script Date: 9/25/2013 3:14:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROC [dbo].[USP_Product_Insert] 
/*****************************************************************************************************************
PURPOSE: Template 
NOTES:  
Change History: 
Date		    | Author			        	| Description     
2013-09-25	| Cool Insert Generator	| Created by Cool Insert Generator
*****************************************************************************************************************/ 
@Name nvarchar(50)
	,@ProductNumber nvarchar(25)
	,@MakeFlag bit
	,@FinishedGoodsFlag bit
	,@Color nvarchar(15)
	,@SafetyStockLevel smallint
	,@ReorderPoint smallint
	,@StandardCost money
	,@ListPrice money
	,@Size nvarchar(5)
	,@SizeUnitMeasureCode nchar(3)
	,@WeightUnitMeasureCode nchar(3)
	,@Weight decimal
	,@DaysToManufacture int
	,@ProductLine nchar(2)
	,@Class nchar(2)
	,@Style nchar(2)
	,@ProductSubcategoryID int
	,@ProductModelID int
	,@SellStartDate datetime
	,@SellEndDate datetime
	,@DiscontinuedDate datetime
	,@ModifiedDate datetime
 AS BEGIN 
INSERT Production.Product(
[Name]
	,[ProductNumber]
	,[MakeFlag]
	,[FinishedGoodsFlag]
	,[Color]
	,[SafetyStockLevel]
	,[ReorderPoint]
	,[StandardCost]
	,[ListPrice]
	,[Size]
	,[SizeUnitMeasureCode]
	,[WeightUnitMeasureCode]
	,[Weight]
	,[DaysToManufacture]
	,[ProductLine]
	,[Class]
	,[Style]
	,[ProductSubcategoryID]
	,[ProductModelID]
	,[SellStartDate]
	,[SellEndDate]
	,[DiscontinuedDate]
	,[ModifiedDate]
)VALUES(
@Name
	,@ProductNumber
	,@MakeFlag
	,@FinishedGoodsFlag
	,@Color
	,@SafetyStockLevel
	,@ReorderPoint
	,@StandardCost
	,@ListPrice
	,@Size
	,@SizeUnitMeasureCode
	,@WeightUnitMeasureCode
	,@Weight
	,@DaysToManufacture
	,@ProductLine
	,@Class
	,@Style
	,@ProductSubcategoryID
	,@ProductModelID
	,@SellStartDate
	,@SellEndDate
	,@DiscontinuedDate
	,@ModifiedDate
) END


/**************************************
--  Average execution time: 3 ms  
DECLARE @StartTime DATETIME 
SET @StartTime = GETDATE()  
EXEC USP_Product_Insert 
@Name = 'T'
	,@ProductNumber = 'T'
	,@MakeFlag = 1
	,@FinishedGoodsFlag = 1
	,@Color = 'T'
	,@SafetyStockLevel = 1
	,@ReorderPoint = 1
	,@StandardCost = 1
	,@ListPrice = 1
	,@Size = 'T'
	,@SizeUnitMeasureCode = 'T'
	,@WeightUnitMeasureCode = 'T'
	,@Weight = 1
	,@DaysToManufacture = 1
	,@ProductLine = 'T'
	,@Class = 'T'
	,@Style = 'T'
	,@ProductSubcategoryID = 1
	,@ProductModelID = 1
	,@SellStartDate = 'Sep 25 2013  3:14AM'
	,@SellEndDate = 'Sep 25 2013  3:14AM'
	,@DiscontinuedDate = 'Sep 25 2013  3:14AM'
	,@ModifiedDate = 'Sep 25 2013  3:14AM'

PRINT CAST(DATEDIFF ( ms, @StartTime, GETDATE() ) AS VARCHAR(MAX)) + ' (In ms)'

***************************************/
