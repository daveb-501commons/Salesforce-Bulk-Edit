/*
    Copyright (c) 2016, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/

global with sharing class C501_MassEdit_SharedCode { 

    // the list of Programs
    global list<SelectOption> listSOProgramsWithRequests(Date startDate, Date endDate) {
        list<SelectOption> listSO = new list<SelectOption>();
        listSO.add(new SelectOption('', ''));

        for (FGM_Base__Program__c program : [
            select Name, Id from FGM_Base__Program__c order by Name asc
            limit 999]) {

                for (Opportunity opp : [
                    select FGM_Base__Lead_Program__c from Opportunity
                    where FGM_Base__Lead_Program__c = :program.Id and (CloseDate = null or (CloseDate >= :startDate and CloseDate <= :endDate)) 
                    limit 1]) {
                        listSO.add(new SelectOption(program.Id, program.Name));
                    }
            }

        return listSO;
    }

    // the list of Owners for the specified FGM_Base__Program__c
    global list<SelectOption> listSOOwnersOfRequests(ID programid, Date startDate, Date endDate) {
        list<SelectOption> listSO = new list<SelectOption>();
        listSO.add(new SelectOption('', ''));

        for (User user : [
            select Id, Name from User order by Name asc
            limit 999]) {

            for (Opportunity opp : [
                    select OwnerId from Opportunity 
                    where OwnerId = :user.Id and FGM_Base__Lead_Program__c = :programid and (CloseDate = null or (CloseDate >= :startDate and CloseDate <= :endDate)) 
                    limit 1]) {
                        listSO.add(new SelectOption(user.Id, user.Name));
                }
        }       
        return listSO;
    }
   
       // global code to verify the passed in UserId is valid, as well as the email
    // exists on the User record.
    global static boolean isValidUserIdAndEmail(ID userId, string strEmail) {
        string strSoql = 'select Id from User where Id = :userId ';
        list<User> listCon = Database.Query(strSoql); 
        return listCon.size() > 0;
    }

    // global code to lookup an existing user
    // listStrFields are optional fields to include in the soql call
    global static list<User> LookupOwner(User user, list<string> listStrFields) {    
        // let's see if we can find any matching Users.
        // we need to use dynamic soql, since we allow the user to modify the FieldSet of fields to edit.
        string strSoql = 'select ';
        string strComma = '';
        if (listStrFields == null) {
            strSoql += 'Id';
        } else {
            for (string strF : listStrFields) {
                strSoql += strComma + strF;
                strComma = ', ';
            }
        }        
        strSoql += ' from User ';
        strSoql += ' limit 999 ';      
        list<User> listCon = Database.Query(strSoql); 
        return listCon;
    }

    // global utility to escape a string.
    global static string StrEscape(string str) {
        if (str == null) return null;
        return string.escapeSingleQuotes(str);
    }
    
    // global utility used to detect whether the Non Profit Starter Pack is installed in this instance.
    private static boolean fCheckedForNPSP = false;
    global static boolean IsNPSPInstalled {
        get {
            if (!fCheckedForNPSP) {
                Schema.SObjectType token = Schema.getGlobalDescribe().get('npe01__OppPayment__c');
                IsNPSPInstalled = (token != null);
                fCheckedForNPSP = true;
            }
            return IsNPSPInstalled;
        }
        set;
    }   
    
    /******************************************************************************************************
    * @description String helper property for getNamespace() method.
    *******************************************************************************************************/
    private static string plainNamespace;

    /*******************************************************************************************************
    * @description Finds the namespace for the current context.
    * @return string The current namespace as a string, or a blank string if we're not in a namespaced context.
    ********************************************************************************************************/
    public static string getNamespace() {
        if (plainNamespace == null) {
            string withDotNotation = C501_MassEdit_SharedCode.class.getName();

            if (withDotNotation.contains('.')) {
                plainNamespace = withDotNotation.substringBefore('.');
            } else {
                plainNamespace = '';
            }
        }
        return plainNamespace;
    }

    /*******************************************************************************************************
    * @description Static method that takes a string
    * If we are in a managed package, tokens in dynamic SOQL must include the package namespace prefix.
    * If you ever deploy this package as unmanaged, this routine will do nothing!
    * @param str token name 
    * @return token name, with namespace prefix, if required.
    ********************************************************************************************************/
    global static string StrTokenNSPrefix(string str) {
        if (getNamespace() == '') return str;
        str = getNamespace() + '__' + str;
        return str;
    }
  
    // utility to verify all the specified fields are accessible to the current user.
    // fields that are not accessible will have a pageMessage added to the current page
    // so the warning is displayed to the user.
    global static void testObjectFieldVisibility(string strObj, list<string>listStrField) {
        
        Map<String, Schema.SObjectType> gd;
        Schema.DescribeSObjectResult sobjDescr;
        Map<String, Schema.SObjectField> mapFieldDesc;
        
        // Obtaining the field name/token map for the object
        gd = Schema.getGlobalDescribe();
        if (gd != null)
            sobjDescr = gd.get(strObj).getDescribe();
        if (sobjDescr != null)
            mapFieldDesc = sobjDescr.fields.getMap();
        if (mapFieldDesc !=  null)
            for (String strField : listStrField) {
                // Check if the user has access on the each field
                // note that fields in our own package must not have their prefix for the Describe Field Map  
                Schema.SObjectField fld = mapFieldDesc.get(strField.replace(StrTokenNSPrefix(''), ''));     
                if (fld != null && !fld.getDescribe().isAccessible()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Field ' + strObj + '.' + strField +
                        ' needs to have field level security enabled on the Site\'s Guest User profile. Please see the V4S Installation & Configuration Guide.'));
                } 
            }
    }

    /*******************************************************************************************************
    * @description Static method checks if running user has field update access for a set of fields
    * @param objectName the name of the object the field belongs to
    * @param fieldNames the set of field names to check update access
    * @return void
    ********************************************************************************************************/
    public static void checkUpdateAccessSites(String objectName, Set<String> fieldNames) {
        // for backward compatibility with 1000's of nonprofit customers, we can
        // only enforce create permissions on the Sites user for Users.
        if (objectName == 'User') {
            C501_UTIL_Describe.checkCreateAccess(objectName, fieldNames);
        } else {
            C501_UTIL_Describe.checkUpdateAccess(objectName, fieldNames);
        }
    }

    /** Description: DML options to allow overriding duplicate rules to create users, while throwing
    * exceptions for validation rules, required fields, etc.
    */
    private static Database.DMLOptions dmlDuplicateOptions {
        get {
            if (dmlDuplicateOptions == null) {
                dmlDuplicateOptions = new Database.DMLOptions();
                dmlDuplicateOptions.optAllOrNone = true;
                dmlDuplicateOptions.DuplicateRuleHeader.allowSave = true;
            }
            return dmlDuplicateOptions;
        }
    }
}