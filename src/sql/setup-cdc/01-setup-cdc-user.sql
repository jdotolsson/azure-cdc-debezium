-- Create user used in the sample
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '#{USER}#')
BEGIN
   CREATE USER [#{USER}#] WITH PASSWORD = '#{PASSWORD}#'
   PRINT 'User #{USER}# created.'
END
ELSE
BEGIN
   PRINT 'User #{USER}# already exists.'
END
GO

-- Make sure user has db_owner permissions
IF NOT EXISTS (SELECT 1 
            FROM sys.database_role_members drm
            JOIN sys.database_principals dp ON drm.member_principal_id = dp.principal_id
            WHERE dp.name = '#{USER}#' AND drm.role_principal_id = DATABASE_PRINCIPAL_ID('db_owner'))
BEGIN
   ALTER ROLE [db_owner] ADD MEMBER [#{USER}#]
   PRINT 'User #{USER}# added to db_owner role.'
END
ELSE
BEGIN
   PRINT 'User #{USER}# is already a member of db_owner role.'
END
GO
