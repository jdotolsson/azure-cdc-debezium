
-- Check if CDC is already enabled for the table
IF NOT EXISTS (
   SELECT 
      name AS table_name,
      OBJECT_SCHEMA_NAME(object_id) AS table_schema,
      is_tracked_by_cdc
   FROM sys.tables
   WHERE is_tracked_by_cdc = 1 
     AND OBJECT_SCHEMA_NAME(object_id) = '#{SCHEMA}#' 
     AND name = '#{TABLE}#'
)
BEGIN
   -- Enable CDC on selected table
   EXEC sys.sp_cdc_enable_table 
      @source_schema = N'#{SCHEMA}#', 
      @source_name = N'#{TABLE}#', 
      @role_name = null, 
      @supports_net_changes = 0
END
GO
