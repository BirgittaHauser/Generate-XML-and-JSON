# Generate-XML-and-JSON
Generate XML and JSON Data for a Db2 Table or View or for an SELECT-Statement

## Description
This tool includes: 
<Table>
<tr><td>SQL User Defined Function  </td><td><b>TABLE2XML  </b></td><td> for generating the XML data 
                                                                        for a complete Db2 table</td></tr>
<tr><td>SQL User Defined Function  </td><td><b>TABLE2JSON </b></td><td> for generating the JSON data 
                                                                        for a complete Db2 table</td></tr>
<tr><td>SQL User Defined Function  </td><td><b>SELECT2XML </b></td><td> for generating the XML data
                                                                        for an SQL Select Statement</td></tr>
<tr><td>SQL User Defined Function  </td><td><b>SELECT2JSON</b></td><td> for generating the JSON data
                                                                        for an SQL Select Statement</td></tr>
</Table>

## Author
<strong>Birgitta Hauser</strong> is Software and Database Engineer, focusing on RPG, SQL and Web development on IBM i at Toolmaker Advanced Efficiency GmbH in Germany. She also works in consulting with regard to modernizaing legacy IBM i applications IBM i as well as in education as a trainer for RPG and SQL developers. 

Since 2002 she has frequently spoken at the COMMON User Groups and other IBM i and Power Conferences in Germany, other European Countries, USA and Canada. 

In addition, she is co-author of two IBM Redbooks and also the author of several articles and papers focusing on RPG and SQL for a German publisher, IBM DeveloperWorks and IT Jungle.

## Prerequisites
Minimum IBM i Release: 7.2 TR7 (or 7.3 TR3)

## Compile

### SQL Stored Procedures and User Defined Functions
The SQL Scripts containing the source code for the stored procedures, can be run with the <b>RUNSQLSTM command</b>:
<pre>RUNSQLSTM SRCFILE(YOURSCHEMA/QSQLSRC)   
               SRCMBR(TABLE2JSON)          
               COMMIT(*NONE)               
               NAMING(*SYS)                
               MARGINS(132)                
               DFTRDBCOL(YOURSCHEMA)</pre>  
               
It is also possible to run the SQL scripts from the b>RUN SQL SCRIPTING facility</b> in Client Access or (even better) ACS (Access Client Solution). 

<Table>
<tr><td><b>Attention:</b></td><td>The database objects are <b>not qualified</b> in the SQL script, <br>
                                   so you need to <b>add YOURSCHEMA</b> to the script by yourself.</td><tr>
</Table>
   
## Program and Procedure Descriptions:

### TABLE2XML – Create an XML Document for a table with all columns
Parameter: 
<table>  
<tr><th>Parameter Name</th><th>Data Type/Length</th><th>Description</th></tr>  
<tr><td><b>ParTable        </b></td><td>VarChar(128)    </td><td>Table (SQL Name) to be converted into XML</td><tr>
<tr><td><b>ParSchema       </b></td><td>VarChar(128)    </td><td>Schema (SQL Name) of the table to be converted into XML
                                                        </td><tr>
<tr><td><b>ParWhere        </b></td><td>VarChar(4096)   </td><td>Additional Where Conditions (without leading WHERE)<br> 
                                                                 for reducing the data<br> 
                                                                 (Optional --> Default = ‘’)</td><tr>
<tr><td><b>ParOrderBy      </b></td><td>VarChar(1024)   </td><td>Order by clause (without leading ORDER BY)<br> 
                                                                 for sorting the result<br> 
                                                                 (Optional --> Default = ‘’)</td><tr>
<tr><td><b>ParRoot         </b></td><td>VarChar(128)    </td><td>Name of the Root Element<br> 
                                                                 (Optional --> Default = ‘”rowset”’)</td><tr> 
<tr><td><b>ParRow          </b></td><td>VarChar(128)    </td><td>Name of the Row Element 
                                                                 (Optional --> Default = ‘”row”’)</td><tr>
<tr><td><b>ParAsAttributes </b></td><td>VarChar(1)      </td><td>Y = single empty element per row,<br> 
                                                                     all column data are passed as attributes<br> 
                                                                 (Optional --> Default = ‘’)
</table>  

Description:
For the passed table a list of all columns separated by a comma is generated with the LIST_AGG Aggregate function 
from the SYSCOLUMS view.
With this information and the passed parameter information a XMLGROUP Statement is performed that returns the XML data.

The structure of the resulting XML looks as follows:
<pre>
&lt;rowset&gt;
       &lt;row&gt;&lt;COLUMN1>Value1&lt;/COLUMN1&gt;&lt;COLUMN2&gt;Value2&lt;/COLUMN2&gt;
                ... more columns...&lt;COLUMNN&gt;ValueN&lt;/COLUMNN&gt;&lt;row&gt;
       ... more rows
&lt/rowset&gt;   
</pre>

If the ParAsAttributes parameter is passed with 'Y' the following structure is returned:
<pre>
&lt;rowset&gt;
    &lt;row COLUMN1="Value1" COLUMN2="Value2" ... more columns ... COLUMNN="ValueN" /&gt;
        ... more rows
&lt;rowset&gt;
 </pre>     

Example:             
<pre>Values(Table2XML('ADDRESSX', 'HSCOMMON10'));</pre>    

<pre>
Values(Table2XML('ADDRESSX', 'HSCOMMON10',
                 ParWhere       => 'ZipCode between ''70000'' and ''80000''',
                 ParOrderBy     => 'ZipCode, CustNo'));</pre>  
 
<pre>
Call WrtXML2IFS_Create(Table2XML('SALES', 'HSCOMMON10', 
                                 ParWhere        => 'Year(SalesDate) = 2018', 
                                 ParOrderBy      => 'SalesDate, CustNo Desc',
                                 ParRoot         => '"Sales"',
                                 ParRow          => '"SalesRow"',
                                 ParAsAttributes => 'Y'),
                        '/home/Hauser/Umsatz20180224.xml'); </pre> 
                 
### TABLE2JSON – Create JSON Data for a table containing all columns
Parameter:
<table>  
<tr><th>Parameter Name</th><th>Data Type/Length</th><th>Description</th></tr>  
<tr><td><b>ParTable     </b></td><td>VarChar(128)    </td><td>Table (SQL Name) to be converted into JSON</td><tr>
<tr><td><b>ParSchema    </b></td><td>VarChar(128)    </td><td>Schema (SQL Name) of the table to be converted into JSON</td><tr>
<tr><td><b>ParWhere     </b></td><td>VarChar(4096)   </td><td>Additional Where Conditions (without leading WHERE)<br> 
                                                     for reducing the data<br> 
                                                     (Optional => Default = ‘’)</td><tr>
<tr><td><b>ParOrderBy   </b></td><td>VarChar(1024)   </td><td>Order by clause (without leading ORDER BY)<br> 
                                                     for sorting the result<br> 
                                                     (Optional => Default = ‘’)</td><tr>
  </table>
               
 Description:
 For the passed table a list containing with columns separated by a comma is generated with the ListAgg Aggregate function 
 from the SYSCOLUMS view.
 With this information and the passed parameter information and a composition of the JSON_ArrayAgg and JSON_Object functions
 the JSON Data is created.

 Example:             
 <pre>Values(Table2JSON('ADDRESSX', 'HSCOMMON10'));</pre>    

<pre>
Values(Table2JSON('ADDRESSX', 'HSCOMMON10',
                  ParWhere       => 'ZipCode between ''70000'' and ''80000''',
                  ParOrderBy     => 'ZipCode, CustNo'));</pre>   
 
<pre>
Call WrtJSON2IFS_Create(Table2JSON('SALES', 'HSCOMMON10', 
                                   ParWhere    => 'Year(SalesDate) = 2017', 
                                   ParOrderBy  => 'SalesDate, CustNo Desc',
                                   ParRoot     => '"Sales"'),         
                        '/home/Hauser/Umsatz20180224.json');</pre> 
                        
### SELECT2XML – Create an XML Document based on an Select-Statement
Parameter: 
<table>  
<tr><th>Parameter Name</th><th>Data Type/Length</th><th>Description</th></tr>  
<tr><td><b>ParSelect       </b></td><td>VarChar(32700)  </td><td>SQL Select-Statement to be converted into XML</td><tr>
<tr><td><b>ParRoot         </b></td><td>VarChar(128)    </td><td>Name of the Root Element<br> 
                                                                 (Optional --> Default = ‘”rowset”’)</td><tr> 
<tr><td><b>ParRow          </b></td><td>VarChar(128)    </td><td>Name of the Row Element 
                                                                 (Optional --> Default = ‘”row”’)</td><tr>
<tr><td><b>ParAsAttributes </b></td><td>VarChar(1)      </td><td>Y = single empty element per row,<br> 
                                                                     all column data are passed as attributes<br> 
                                                                 (Optional --> Default = ‘’)
</table>  

Description:
Almost any SELECT-Statement including Common Table Expressions or Nested Sub-Selects
For the passed table a list of all columns separated by a comma is generated with the LIST_AGG Aggregate function 
from the SYSCOLUMS view.
With this information and the passed parameter information a XMLGROUP Statement is performed that returns the XML data.

Example:             
