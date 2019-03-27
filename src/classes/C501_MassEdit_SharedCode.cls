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

    // the list of Programs for Requests
    global List<SelectOption> listSOProgramsWithRequests(Date startDate, Date endDate) {

        List<SelectOption> listSO = new List<SelectOption>();
        listSO.add(new SelectOption('', ''));

        List<Opportunity> listOpportunities = listOpportunitiesByCriteria(null, null, null, startDate, endDate);
        List<Id> requestIds = new List<Id>();
        for (Opportunity request :listOpportunities) {
            requestIds.add(request.Id);
        }

        AggregateResult[] allAggregatedByName = [
            SELECT FGM_Base__Program__r.Name
            FROM FGM_Base__Contributing_Programs__c
            WHERE FGM_Base__Request__c in :requestIds
            GROUP BY FGM_Base__Program__r.Name
            ORDER BY FGM_Base__Program__r.Name ASC];

        Set<String> programGroups = new Set<String>();
        String name;
        for (AggregateResult result : allAggregatedByName)  {

            name = result.get('Name').toString();

            // Custom Client Filtering - find some way to get this from custom setting
            if (name.startsWith('NF ')) {
                continue;
            }

            // Check to add program group
            List<String> programNameTokens = name.split(' ');
            if (!programGroups.contains(programNameTokens[0])) {
                listSO.add(new SelectOption(programNameTokens[0], programNameTokens[0]));
                programGroups.add(programNameTokens[0]);
            }

            listSO.add(new SelectOption(name, name));
        }

        return listSO;
    }

    // the list of Owners for the specified FGM_Base__Program__c
    global List<SelectOption> listSOOwnersOfRequests(String programName, Date startDate, Date endDate) {

        List<SelectOption> listSO = new List<SelectOption>();
        listSO.add(new SelectOption('', ''));

        List<Opportunity> listOpportunities = listOpportunitiesByCriteria(null, programname, null, startDate, endDate);
        List<Id> requestIds = new List<Id>();
        for (Opportunity request :listOpportunities) {
            requestIds.add(request.Id);
        }

        AggregateResult[] allAggregatedByName = [
            SELECT OwnerId
            FROM Opportunity
            WHERE Id in :requestIds
            GROUP BY OwnerId];

        List<String> ownerIds = new List<String>();
        for (AggregateResult result : allAggregatedByName)  {
            ownerIds.add(result.get('OwnerId').toString());
        }

        String name, id;
        for (User user : [
            SELECT Id, Name
            FROM User
            WHERE Id in :ownerIds
            ORDER By Name ASC]) {
                listSO.add(new SelectOption(user.Id, user.Name));
        }

        return listSO;
    }
   
    global List<Opportunity> listOpportunitiesByCriteria(List<String> listStrFields, String programName, Id ownerId, Date startDate, Date endDate) {

        // Get Contributing Programs
        //
        string strSoql = 
            'select FGM_Base__Request__c from FGM_Base__Contributing_Programs__c where ';

        if (programName <> null && !String.isBlank(programName)) {
            strSoql += ' FGM_Base__Program__r.Name like \'' + programName + '%\' and ';
        }
        strSoql += ' FGM_Base__Scheduled_Payment_Date__c >= :startDate ';
        strSoql += ' and FGM_Base__Scheduled_Payment_Date__c <= :endDate ';
        strSoql += ' order by FGM_Base__Program__r.Name, FGM_Base__Scheduled_Payment_Date__c ASC NULLS FIRST';
        
        List<FGM_Base__Contributing_Programs__c> contributingPrograms = Database.Query(strSoql);
        List<Id> requestIds = new List<Id>();
        for (FGM_Base__Contributing_Programs__c contributingProgram :contributingPrograms) {
            requestIds.add(contributingProgram.FGM_Base__Request__c);
        }

        // Get Opportunities
        //
        strSoql = 'select ';
        if (listStrFields == null) {
            strSoql += ' Id ';
        }
        else {
            strSoql += String.join(listStrFields, ',');
        }

        strSoql += ' from Opportunity where Id in :requestIds';
        
        if (ownerId != null)
            strSoql += ' and (OwnerId = :ownerId or OwnerId = null) ';

        strSoql += ' and StageName <> \'Closed\' and StageName <> \'Withdrawn\'';

        // Custom Client Filtering - find some way to get this from custom setting
        strSoql += ' and (NOT Name like \'NF %\')';

        List<Opportunity> opportunitiesUnordered = Database.Query(strSoql);

        // Order Opportunities based on Scheduled Payment Date
        List<Opportunity> opportunitiesOrdered = new List<Opportunity>();
        for (Id requestId :requestIds) {
            for (Opportunity opportunity :opportunitiesUnordered) {
                if (opportunity.Id == requestId) {
                    opportunitiesOrdered.add(opportunity);
                }
            }
        }

        return opportunitiesOrdered;
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