----------------------------------------------------------------------------------------------------                                                       
-- UDF: Convert a SELECT-Statement into a JSON Data                                                                                
-- Parameters: ParSelect        --> SQL Select-Statement to be converted                                                
--                                                                                                                      
-- Enhanced:   2018-03-02 B.Hauser                                                                                      
--             ParDataName      --> Optional:  Name of the data array --> Default = "Data"                              
--             ParInclSuccess   --> Optional:  Any Value > ' ' --> Success/Error Message are included                   
--             ParNamesLower    --> Optional:  Any value > ' ' --> Array and object names in lowercase                  
--*************************************************************************************************                     
Create or Replace Function SELECT2JSON(                                                                                 
                           ParSelect        VARCHAR(32700),                                                             
                           ParDAtaName      VarChar(128)    Default 'Data',                                             
                           PARINCLSUCCESS   VarChar(1)      Default '',                                                 
                           ParNamesLower    VarChar(1)      Default '')                                                 
       Returns CLOB(16 M) CCSID 1208                                                                                    
       Language SQL                                                                                                     
       Modifies SQL Data                                                                                                
       Specific SELECT2JSON                                                                                             
       Not Fenced                                                                                                       
       Not Deterministic                                                                                                
       Called On Null Input                                                                                             
       No External Action                                                                                               
       Not Secured                                                                                                      
                                                                                                                        
       Set Option Datfmt  = *Iso,                                                                                       
                  commit  = *NONE,                                                                                      
                  Dbgview = *Source,                                                                                    
                  Decmpt  = *COMMA,                                                                                     
                  DLYPRP  = *Yes,                                                                                       
                  Optlob  = *Yes,                                                                                       
                  SrtSeq  = *LangIdShr                                                                                  
   --==============================================================================================                     
   Begin                                                                                                                
     Declare GblView            VarChar(257)   Default '';                                                              
     Declare GblViewName        VarChar(128)   Default '';                                                              
     Declare GblViewSchema      VarChar(128)   Default '';                                                              
                                                                                                                        
     Declare GblSelectNoOrderBy VarChar(32700) Default '';                                                              
     Declare GblOrderBy         VarChar(1024)  Default '';                                                              
                                                                                                                        
     Declare GblViewExists      SmallInt       Default 0;                                                               
     Declare GblPos             Integer        Default 0;                                                               
     Declare GblLastOrder       Integer        Default 0;                                                               
     Declare GblOccurence       Integer        Default 0;                                                               
                                                                                                                        
     Declare RtnJSON            CLOB(16 M) CCSID 1208;                                                                  
                                                                                                                        
     Declare Continue Handler for SQLSTATE '42704' Begin End;                                                           
                                                                                                                        
     Declare Continue Handler for SQLException                                                                          
             Begin                                                                                                      
                Declare LocErrText VarChar(128) Default '';                                                             
                Get Diagnostics Condition 1 LocErrText = MESSAGE_TEXT;                                                  
                Execute Immediate 'Drop View ' concat GblView;                                                          
                Return JSON_Object('Error': LocErrText);                                                                
             End;                                                                                                       
     ----------------------------------------------------------------------------------------------                     
     Set GblViewName   = Trim('SELECT2JSON' concat                                                                      
                              Trim(Replace(qsys2.Job_Name, '/', '')));                                                  
                                                                                                                        
     Set GblViewSchema = Trim('QGPL');                                                                                  
     Set GblView       = GblViewSchema concat '.' concat GblViewName;                                                   
                                                                                                                        
     If Trim(ParSelect) = ''                                                                                            
        Then Return JSON_Object('Error':                                                                                
                                'Select Statement not passed');                                                         
     End If;                                                                                                            
                                                                                                                        
     --1. Find the last Order by in the SQL Statement (if any)                                                          
     --   --> Split SQL Statement into SELECT and ORDER BY                                                              
     StartLoop:                                                                                                         
          Repeat set GblOccurence = GblOccurence + 1;                                                                   
                 set GblPos = Locate_in_String(ParSelect,                                                               
                                               'ORDER BY', 1, GblOccurence);                                            
                 If GblPos > 0                                                                                          
                    Then Set GblLastOrder = GblPos;                                                                     
                 End If;                                                                                                
          Until GblPos = 0 End Repeat;                                                                                  
                                                                                                                        
      If GblLastOrder > 0                                                                                               
         Then Set GblSelectNoOrderBy = Substr(ParSelect, 1, GblLastOrder - 1);                                          
              Set GblOrderBy = Replace(Substr(ParSelect, GblLastOrder),                                                 
                                       'ORDER BY', '');                                                                 
      Else Set GblSelectNoOrderBy = Trim(ParSelect);                                                                    
           Set GblOrderBY         = '' ;                                                                                
      End If;                                                                                                           
                                                                                                                        
      --2. Drop View if it already exists                                                                               
      Select 1 into GblViewExists                                                                                       
        From SysTables                                                                                                  
        Where     Table_Name   = GblViewName                                                                            
              and Table_Schema = GblViewSchema                                                                          
      Fetch First Row Only;                                                                                             
                                                                                                                        
      If GblViewExists = 1                                                                                              
         Then Execute Immediate 'Drop View ' concat GblView;                                                            
      End If;                                                                                                           
                                                                                                                        
      --3. Create View                                                                                                  
      Execute Immediate 'Create View '  concat GblView            concat                                                
                                ' as (' concat GblSelectNoOrderBy concat ' )';                                          
                                                                                                                        
      --4. Generate JSON Document (by calling TABLE2JSON)                                                               
      Set RtnJSON = Table2JSON(GblViewName, GblViewSchema, '', GblOrderBy,                                              
                               '',          ParDataName,   ParInclSuccess,                                              
                               ParNamesLower);                                                                          
                                                                                                                        
      --5. Drop View                                                                                                    
      Execute Immediate 'Drop View ' concat GblView;                                                                    
                                                                                                                        
      Return RtnJSON;                                                                                                   
   End;                                                                                                                 
                                                                                                                        
Begin                                                                                                                   
  Declare Continue Handler For SQLEXCEPTION Begin End;                                                                  
   Label On Specific Function SELECT2JSON                                                                               
      Is 'Convert a Select Statement into JSON';                                                                        
                                                                                                                        
   Comment On Parameter Specific Routine SELECT2JSON                                                                    
     (PARSELECT        Is 'Select Statement',                                                                           
      PARDATANAME      Is 'Data name --> Default = "Data"',                                                             
      PARINCLSUCCESS   Is 'Any Value --> success and errormsg are included',                                            
      PARNAMESLOWER    Is 'Any Value -->                                                                                
                           convert all column names into lower Case');                                                  
End;                                                                                           
