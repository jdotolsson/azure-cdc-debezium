-- Create Products table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
BEGIN
    CREATE TABLE Products (
        ProductID INT PRIMARY KEY IDENTITY(1,1),
        Name NVARCHAR(255),
        Description NVARCHAR(MAX)
    );
END;

-- Create Reviews table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Reviews]') AND type in (N'U'))
BEGIN
    CREATE TABLE Reviews (
        ReviewID INT PRIMARY KEY IDENTITY(1,1),
        ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
        Rating INT CHECK (Rating >= 1 AND Rating <= 5),
        Comment NVARCHAR(MAX)
    );
END;

-- Create Tags table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Tags]') AND type in (N'U'))
BEGIN
    CREATE TABLE Tags (
        TagID INT PRIMARY KEY IDENTITY(1,1),
        Name NVARCHAR(50)
    );
END;

-- Create ProductTags table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductTags]') AND type in (N'U'))
BEGIN
    CREATE TABLE ProductTags (
        ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
        TagID INT FOREIGN KEY REFERENCES Tags(TagID),
        PRIMARY KEY (ProductID, TagID)
    );
END;

-- Create ReviewTags table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReviewTags]') AND type in (N'U'))
BEGIN
    CREATE TABLE ReviewTags (
        ReviewID INT FOREIGN KEY REFERENCES Reviews(ReviewID),
        TagID INT FOREIGN KEY REFERENCES Tags(TagID),
        PRIMARY KEY (ReviewID, TagID)
    );
END;
