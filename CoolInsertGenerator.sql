
SET QUOTED_IDENTIFIER OFF
GO
--------------------------------Main Procedure----------------------------------
CREATE PROC USP_CoolInsertGenerator

/*************************************************************************
PURPOSE: Writing an insert stored procedure in SQL for a giant table is a hard job. You have to hardcode all the tedious code , you should declare input parameters for your SP and then select all those columns in INSERT VALUES command and pass in all those parameters again. This stored procedure can be used for creating those kind of stored procedures. It can do all the hard work for you.
NOTES:  if the @StoreProcName parameter is not passed the insert procedure will be created in dbo schema with an specific name (USP_TableName_Insert)
		if you pass the store proc name with schema name make sure that this schema is already created.
		computed , PK and uniqueidentifier columns are ignored by default if you want to include them pass 0 (false) for escaping the corresponding parameter. 
Change History: 
Date		    | Author				    | Description     
2013-09-24	| Ashkan Hosseini		| This generator is written to make your life easier :)
***************************************************************************/ 

	@TableSchema VARCHAR(50),
	@TableName VARCHAR(50),
	@StoreProcName VARCHAR(50) = NULL ,
	@EscapePKColumns BIT = 1,
	@EscapeComputedColumns BIT = 1,
	@EscapeUniqueidentifierColumns BIT = 1,
	@ShowOutput BIT = 1
AS
BEGIN
	DECLARE @Script VARCHAR(MAX)
	DECLARE @v_SQL NVARCHAR(MAX)
	DECLARE @ColumnDetector NVARCHAR(MAx)
	DECLARE @ParamDefinition NVARCHAR(MAX)
	DECLARE @TestExecution VARCHAR (MAX)
	DECLARE @Count INT

	---------------------------------------set which columns should be escaped from insert ----------------------------------------------
	SET @ColumnDetector = 
	'DECLARE @result BIT; SET @result = 0; '+
	-------check for Id column -----------------------
	'IF EXISTS (SELECT * FROM sys.columns 
			   WHERE [object_id]=object_id(@TableName)
			   AND name= @ColumnName AND is_identity=1)
			   SET @result = 1 ; '
	---------------------check for primary key column ---------------------------
	IF (@EscapePKColumns = 1)
	BEGIN
		SET @ColumnDetector = @ColumnDetector + 
			   'IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
			    WHERE COLUMN_NAME = @ColumnName AND TABLE_NAME=@TableName
			    AND TABLE_SCHEMA = @TableSchema AND CONSTRAINT_NAME LIKE' + "'PK%" +  "') "+
			    'SET @result = 1 ; '
	END
	---------------------check for computed column --------------------------------
	IF (@EscapeComputedColumns = 1)
	BEGIN
		SET @ColumnDetector = @ColumnDetector 	+
				'IF EXISTS (SELECT * FROM sys.computed_columns 
			    WHERE name= @ColumnName )
			   SET @result = 1 ; '
	END
	---------------------check for unique identifier column -----------------------
	IF ( @EscapeUniqueidentifierColumns = 1)
	BEGIN
		SET @ColumnDetector = @ColumnDetector 	+
		'IF @DataType= ' + "'" + 'uniqueidentifier' + "' SET @result = 1 ; "
	END

	SET @ColumnDetector = @ColumnDetector + 'SET @Continue = @result; '
		
	SET @ParamDefinition = N'@Continue BIT OUTPUT, @TableName NVARCHAR(MAX), @ColumnName NVARCHAR(MAX),@TableSchema NVARCHAR(MAX) , @DataType NVARCHAR(MAX) '


	-------------------------------------------------------------------------------------------------------------------------------------


	------------This part determines the number fields inside the pointed table---------------------
	DECLARE @COUNT1 INT
	SET @V_SQL='SELECT @COUNT1=COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS '+
	'WHERE TABLE_SCHEMA='+"'"+@TableSchema+"' AND TABLE_NAME="+"'"+
	@TableName+"'"
	EXEC SP_EXECUTESQL @V_SQL,N'@COUNT1 INT OUTPUT',@COUNT1 OUTPUT
	SET @Count=@COUNT1
	----------------------------------------------------------------------------------------------
	IF (@StoreProcName IS NULL)
	BEGIN
		SET @Script='CREATE PROC USP_' +@TableName + '_Insert' +' ' + CHAR(13)+CHAR(10)
		SET @TestExecution = 'EXEC USP_' +@TableName + '_Insert' +' ' + CHAR(13)+CHAR(10)
	END
	ELSE BEGIN
		SET @Script='CREATE PROC '+@StoreProcName+' ' + CHAR(13)+CHAR(10)
		SET @TestExecution = 'EXEC ' +@StoreProcName+' ' + CHAR(13)+CHAR(10)
	END

	-------------------------Input proc info comments section-------------------------------------
	SET @Script = @Script +
	 '/*****************************************************************************************************************'
	  + CHAR(13) + CHAR(10) 
	  + 'PURPOSE: Template ' + CHAR(13) + CHAR(10)
	  +  'NOTES:  ' + CHAR(13) + CHAR(10)
	  + 'Change History: ' + CHAR(13)+CHAR(10)
	  + 'Date'+ CHAR(9)+ CHAR(9) + '| Author' + CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) +'| Description     ' + CHAR(13)+CHAR(10)
	  + CAST (CONVERT (DATE , GETDATE()) AS nvarchar(10)) + CHAR(9) + '| Cool Insert Generator' + CHAR(9) + '| Created by Cool Insert Generator' + CHAR(13) + CHAR(10)
	  + '*****************************************************************************************************************/ ' + CHAR(13) + CHAR(10)

	----------------------------------------------------------------------------------------------


	DECLARE @ColumnName VARCHAR(50)
	DECLARE @DataType VARCHAR(50)
	DECLARE @Length VARCHAR(50)
	DECLARE @Index INT
	DECLARE @Continue BIT
	
	DECLARE @NextColumn VARCHAR(50);
	SET @Index=1
	WHILE @Index<=@Count
	BEGIN
		WITH Q
		AS
		(
			SELECT ROW_NUMBER()
			OVER(ORDER BY ORDINAL_POSITION)'Row',COLUMN_NAME,DATA_TYPE,
			CHARACTER_MAXIMUM_LENGTH
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME=@TableName AND TABLE_SCHEMA=@TableSchema
		)
		
		SELECT @ColumnName=COLUMN_NAME,@DataType=DATA_TYPE,@Length=CHARACTER_MAXIMUM_LENGTH
		FROM Q 
		WHERE Row=@Index;
		
		
		------------------------------------
	
		EXEC sp_EXECUTESQL @ColumnDetector ,@ParamDefinition,@Continue OUTPUT , @TableName, @ColumnName, @TableSchema, @DataType

		IF @Continue=1 
		BEGIN
		SET @Index=@Index+1
		CONTINUE
		END
		
		
		IF @Length IS NULL OR @DataType='image' 
			SET @Script= @Script+   '@'+@ColumnName+' '+@DataType + CHAR(13)+CHAR(10)
		ELSE
			BEGIN
				IF ( (@DataType = 'varchar' OR @DataType = 'nvarchar') AND @Length = -1 )
				BEGIN
					SET @Script= @Script+  '@'+@ColumnName+' '+@DataType+'(max)' + CHAR(13)+CHAR(10)
				END
				ELSE BEGIN
					SET @Script= @Script+  '@'+@ColumnName+' '+@DataType+'('+@Length+')' + CHAR(13)+CHAR(10)	
				END
			END

		---------------------------SET parameters of test execution------------------------------

		SET @TestExecution = @TestExecution + '@'+@ColumnName +' = ' ;
		
		IF (@DataType = 'int' OR @DataType = 'real' OR @DataType = 'decimal' OR @DataType = 'numeric' OR @DataType = 'float' OR @DataType = 'bit' OR @DataType = 'smallint' OR @DataType = 'money' OR @DataType = 'smallmoney'  )
		BEGIN
			SET @TestExecution = @TestExecution + '1'
		END
		ELSE IF (@DataType = 'varchar' OR @DataType = 'nvarchar' OR @DataType = 'char' OR @DataType = 'nchar' OR @DataType = 'text')
		BEGIN
			SET @TestExecution = @TestExecution + "'" + 'T' + "'"
		END
		ELSE IF (@DataType = 'date')
		BEGIN
			SET @TestExecution = @TestExecution + "'"  + CAST (CONVERT (DATE , GETDATE()) AS nvarchar(10)) + "'" 
		END
		ELSE IF (@DataType = 'datetime' OR @DataType = 'smalldatetime') 
		BEGIN
			SET @TestExecution = @TestExecution + "'"  + CAST (GETDATE() AS nvarchar(MAX)) + "'" 
		END
		ELSE BEGIN
			SET @TestExecution = @TestExecution + "'"  + '-----> This input parameter is unknown for generator , please provide data <------' + "'" 
		END

		SET @TestExecution = @TestExecution + CHAR(13)+CHAR(10)
		-----------------------------------------------------------------------------------------
			
		
		---------------------------------------------------------------
		
		
		IF @Index!=@Count
		BEGIN
			SET @Script=@Script+ CHAR(9) +','
			SET @TestExecution = @TestExecution + CHAR(9) +','
		END
		ELSE 
		BEGIN
			--SET @Script= SUBSTRING (@Script,0,LEN(@Script)-1)
			SET @Script=@Script+' '
		END	
		SET @Index=@Index+1
	END
	SET @Script=@Script+'AS BEGIN ' + CHAR(13)+CHAR(10)
	SET @Script=@Script+'INSERT '+@TableSchema+'.'+@TableName+'(' + CHAR(13)+CHAR(10)
	SET @Index=1
	WHILE @Index<=@Count
	BEGIN
		WITH Q
		AS
		(
			SELECT ROW_NUMBER()
			OVER(ORDER BY ORDINAL_POSITION)'Row',COLUMN_NAME,DATA_TYPE,
			CHARACTER_MAXIMUM_LENGTH
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME=@TableName AND TABLE_SCHEMA=@TableSchema
		)
		SELECT @ColumnName=COLUMN_NAME,@DataType=DATA_TYPE
		FROM Q
		WHERE Row=@Index;
		
				
		------------------------------------
		
		
		----------------------------------------Check column type------------------
		EXEC sp_EXECUTESQL @ColumnDetector ,@ParamDefinition,@Continue OUTPUT , @TableName, @ColumnName, @TableSchema, @DataType


		IF @Continue=1 
		BEGIN
		SET @Index=@Index+1
		CONTINUE
		END
				
		SET @Script=@Script + '[' + @ColumnName + ']' + CHAR(13)+CHAR(10)
		
		
		------------------------------------------------------
		
		IF @Index!=@Count
			SET @Script=@Script+ CHAR(9) +','
		SET @Index=@Index+1
	END	
	SET @Script=@Script+')VALUES('	+ CHAR(13)+CHAR(10)
	SET @Index=1
	WHILE @Index<=@Count
	BEGIN
		WITH Q
		AS
		(
			SELECT ROW_NUMBER()
			OVER(ORDER BY ORDINAL_POSITION)'Row',COLUMN_NAME,DATA_TYPE,
			CHARACTER_MAXIMUM_LENGTH
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME=@TableName AND TABLE_SCHEMA=@TableSchema
		)
		SELECT @ColumnName=COLUMN_NAME,@DataType=DATA_TYPE
		FROM Q
		WHERE Row=@Index;
		
		
		------------------------------------
		
		
		----------------------------------------Check column type------------------
		EXEC sp_EXECUTESQL @ColumnDetector ,@ParamDefinition,@Continue OUTPUT , @TableName, @ColumnName, @TableSchema, @DataType

		IF @Continue=1 
		BEGIN
		SET @Index=@Index+1
		CONTINUE
		END
		
		
		SET @Script= @Script + '@'+@ColumnName + CHAR(13)+CHAR(10)
		
		
		------------------------------------------------------
		IF @Index!=@Count
			SET @Script=@Script + CHAR(9)+','
		SET @Index=@Index+1
	END		
	SET @Script=@Script+') END'

	---------------------------------------------------------add test execution for procedure ----------------------------------
	SET @Script = @Script + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10)
	 + '/**************************************' + CHAR(13)+CHAR(10)
	 + '--  Average execution time: 3 ms  ' + CHAR(13)+CHAR(10)
	 + 'DECLARE @StartTime DATETIME ' + CHAR(13)+CHAR(10)
	 + 'SET @StartTime = GETDATE()  ' + CHAR(13)+CHAR(10)
	 + @TestExecution + CHAR(13)+CHAR(10)
	 + 'PRINT CAST(DATEDIFF ( ms, @StartTime, GETDATE() ) AS VARCHAR(MAX)) + ' + "'" + ' (In ms)' + "'" + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10)
	 + '***************************************/'
	----------------------------------------------------------------------------------------------------------------------------
	IF ( @ShowOutput = 1) 
	BEGIN
		PRINT (@Script)
	END
	ELSE BEGIN
		EXECUTE (@Script)
	END
	
	
END
GO
-------------------------------------------END OF MAIN PROC------------------------------------------
