# Data Warehouse Tools - various tools for creating, updating and managing data warehouses

##separating raw data into dimensions and facts

###dimify @tblname, @dimcols, @excludecols

will create a dimensioned view of the raw data table specified as tblname for each column indicated in  dimcols. dimify will not present the excludecols in the resulting view.  The resulting view is the table name prefixed with 'v'. So if the table name were RawRigData, the resulting view is vRawRigData.

###crDim @tblname, @colname

creates a dimension table for the specified column in tblname and loads it with the unique dimension elements from the raw data table (i.e. tblname).

+ the dimension table is named Dim`<colname`>

+ the id column is called `<colname`>_ID

+ the name column is just `<colname`>

###getColType @tblname, @colname

returns the type specification for the column of the table

## Usage example

See DimifyRigData.sql in this repo