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
   
    // global utility used to detect whether the Foundation Grant Manager (Foundation Connect) is installed in this instance.
    private static boolean fCheckedForFGM = false;
    global static boolean IsFGMInstalled {
        get {
            if (!fCheckedForFGM) {
                Schema.SObjectType token = Schema.getGlobalDescribe().get('FGM_Base__Lead_Program__c');
                IsFGMInstalled = (token != null);
                fCheckedForFGM = true;
            }
            return IsFGMInstalled;
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
    global static string StrTokenFGMPrefix(string str) {
        if (getNamespace() == '') return str;
        str = getNamespace() + '__' + str;
        return str;
    }
}