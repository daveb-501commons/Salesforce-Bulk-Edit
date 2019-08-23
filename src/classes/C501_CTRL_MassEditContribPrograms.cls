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

global virtual with sharing class C501_CTRL_MassEditContribPrograms {

    global integer cEmptyPaymentRecords {
        get {
            return 1;
        }
    }
    
    private C501_MassEdit_SharedCode c501MassEdit_SharedCode;
    private List<String> listStrFields;
    
    global boolean redirect { get; private set; }
    global ID idRedirect { get; private set; }
    
    // constructor
    global C501_CTRL_MassEditContribPrograms() {
        redirect = false;
        c501MassEdit_SharedCode = new C501_MassEdit_SharedCode();
        
        // handle optional parameters (must use string, not ID, to handle null)
        string id = ApexPages.currentPage().getParameters().get('programname');
        if (id != null && id != '') programname = id;
        
        id = ApexPages.currentPage().getParameters().get('ownerid');
        if (id != null && id != '') ownerid = id;

        // Get list of fields from fieldset
        listStrFields = new List<String>();
        for (Schema.FieldSetMember f : SObjectType.FGM_Base__Contributing_Programs__c.FieldSets.MassEditContribPrograms.getFields()) {
            listStrFields.add(f.getFieldPath());
        }

        if (!listStrFields.contains('Id')) {
            listStrFields.add('Id');
        }
        if (!listStrFields.contains('FGM_Base__Request__r.OwnerId')) {
            listStrFields.add('FGM_Base__Request__r.OwnerId');
        }
        if (!listStrFields.contains('FGM_Base__Request__r.FGM_Base__Lead_Program__c')) {
            listStrFields.add('FGM_Base__Request__r.FGM_Base__Lead_Program__c');
        }
    }   
    
    // holds the currently selected Program in the Program dropdown
    global String programname { get; set; }

    // the list of Programs to put in the Program dropdown
    global List<SelectOption> listSOPrograms {
        get {
            if (listSOPrograms == null )
                listSOPrograms = c501MassEdit_SharedCode.listSOProgramsWithRequests(paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c, paymentDateFilter.FGM_Base__Payment_Date__c);

            return listSOPrograms;
        }

        set;
        }
    
    // the user has changed the Program dropdown
    global virtual PageReference ChangeProgram() {

        // clear out all state that is specific to the Program
        listSOOwners = null;
        ownerid = null;
        ChangeOwner();
        return null;
    }

    // holds the currently select Owner in the Owner dropdown
    global ID ownerid { get; set; }
    
    // the list of Owners to put in the dropdown
    global List<SelectOption> listSOOwners {
        get {
            if (listSOOwners == null && programName != null) {
                listSOOwners = c501MassEdit_SharedCode.listSOOwnersOfRequests(programName, paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c, paymentDateFilter.FGM_Base__Payment_Date__c);
            }
            return listSOOwners;
        }
        
        set;
    }
    
    // dates to filter the list of requests
    global date startDate { get; set; }
    global date endDate { get; set; }
    
    global FGM_Base__Payment__c paymentDateFilter {
        get {
            if (paymentDateFilter == null) {
                paymentDateFilter = new FGM_Base__Payment__c();
                
                paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c = Date.newInstance(system.today().year(), 1, 1);
                paymentDateFilter.FGM_Base__Payment_Date__c = Date.newInstance(system.today().year(), 12, 31);
            }
            return paymentDateFilter;
        }
        set;
    }

    // the user has changed the Owner dropdown
    global virtual PageReference ChangeOwner() {
        // clear out all state that is specific to the Owner
        listContributingPrograms = null;
        strSaveResults = null;
        return null;
    }

    // the user has changed the date query
    global virtual PageReference ChangeDate() {
        // clear out all state that is specific to the Date
        listSOPrograms = null;
        listSOOwners = null;
        listContributingPrograms = null;
        strSaveResults = null;
        return null;
    }

    // status string for reporting the results of saving.
    global String strSaveResults { get; set; }
      
    // The list of ContributingPrograms.
    global List<FGM_Base__Contributing_Programs__c> listContributingPrograms {
        get {
            if (listContributingPrograms == null) {
                FillListContributingPrograms();
            }
            return listContributingPrograms;
        }
        
        set;
    }
    
    // helper function that the client can override, to query for the appropriate fields in ContributingPrograms.
    global virtual void FillListContributingPrograms() {

        List<Opportunity> listOpportunities = c501MassEdit_SharedCode.listOpportunitiesByCriteria(null, programname, ownerid, paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c, paymentDateFilter.FGM_Base__Payment_Date__c);
        List<Id> requestIds = new List<Id>();
        for (Opportunity request :listOpportunities) {
            requestIds.add(request.Id);
        }

        // if they haven't yet picked a program
        if (programName == null) return;           
        
        // find the existing owners
        // we need to use dynamic soql to pick up all custom fields we don't know about
        string strSoql = 
            'select ' + String.join(listStrFields, ',');

        strSoql += ' from FGM_Base__Contributing_Programs__c where FGM_Base__Request__c <> null and FGM_Base__Request__c in :requestIds';
        
        if (paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c != null) {
            Date dtStart = paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c;
            strSoql += ' and FGM_Base__Scheduled_Payment_Date__c >= :dtStart ';
        }
        if (paymentDateFilter.FGM_Base__Payment_Date__c != null) {
            Date dtEnd = paymentDateFilter.FGM_Base__Payment_Date__c;
            strSoql += ' and FGM_Base__Scheduled_Payment_Date__c <= :dtEnd ';
        }

        strSoql += ' order by FGM_Base__Request__r.FGM_Base__Lead_Program__r.Name, FGM_Base__Scheduled_Payment_Date__c, FGM_Base__Request__r.Owner.Name ASC NULLS FIRST';
        
        listContributingPrograms = Database.Query(strSoql); 
    }
    
    global Boolean fHasListContributingPrograms {
        get {
            return listContributingPrograms != null && listContributingPrograms.size() > 0;
        }
    }     
 
    global virtual void AddMoreEmptyRowsToContributingPrograms() {
        try {
            if (listContributingPrograms == null) return;

            for (integer i = 0; i < cEmptyPaymentRecords; i++) { 
                FGM_Base__Contributing_Programs__c payment = new FGM_Base__Contributing_Programs__c();
                listContributingPrograms.add(payment);
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);            
        }       
    }
    
    // used to track the Id's of all FGM_Base__Contributing_Programs__c records that get modified.
    global Set<ID> setContributingProgramsIdDirty {
        get {
            if (setContributingProgramsIdDirty == null) {
                setContributingProgramsIdDirty = new Set<ID>();
            }
            return setContributingProgramsIdDirty;
        }
        set;
    }
    
    // to allow vf page to see how many FGM_Base__Contributing_Programs__c records are dirty
    global Integer numberOfRecordsDirty {
        get { 
            if (setContributingProgramsIdDirty == null)
                return 0;
            else
                return setContributingProgramsIdDirty.size();
        }
    }
    
    // this gets called whenever a field in the ContributingPrograms datatable is modified.
    // use this to remember which existing ContributingPrograms records have been modified.
    global virtual PageReference ContributingProgramsRecordModified() {
        String strId = ApexPages.currentPage().getParameters().get('usersIdDirtied');
        if (strId != null && strId != '') setContributingProgramsIdDirty.add(strId);
        return null;
    }
    
    //save the ContributingPrograms created or modified
    global virtual PageReference SaveContributingPrograms() {
        
        if (listContributingPrograms == null) return null;
        
        strSaveResults = null;
        
        try {
            // create two lists: one to update and one to insert.

            List<FGM_Base__Contributing_Programs__c> listContributingProgramsUpdate = new List<FGM_Base__Contributing_Programs__c>();
            
            // Disabled creating new ContributingPrograms on the Mass Edit page - too many required fields so just change new row to New Payment which takes user to a new screen to create payment
            List<FGM_Base__Contributing_Programs__c> listContributingProgramsCreate = new List<FGM_Base__Contributing_Programs__c>();

            for (FGM_Base__Contributing_Programs__c payment : listContributingPrograms) {
                if (payment.Id != null) {
                    // we couldn't reliably mark dirty records in all scenarios,
                    // so we've decided it is better to always update all records.
                    //if (setContributingProgramsIdDirty.contains(payment.Id)) 
                        listContributingProgramsUpdate.add(payment);
                } else if (payment.FGM_Base__Request__r.OwnerId != null) {
                    listContributingProgramsCreate.add(payment);
                }
            }
            
            if (!listContributingProgramsUpdate.isEmpty()) {
                update listContributingProgramsUpdate;
            }
           
            /*if (!listContributingProgramsCreate.isEmpty()) {
                insert listContributingProgramsCreate;
            }*/
            
            strSaveResults = String.valueOf(listContributingProgramsCreate.size() + listContributingProgramsUpdate.size()) + ' ' + Label.labelMassEditContribProgramsSaveSuccess;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, strSaveResults));
            // successful save, so clear out dirty list
            setContributingProgramsIdDirty = null;
            return null;            
        } catch (Exception e) {
            strSaveResults = Label.labelMassEditContribProgramsErrorOnSave;
            ApexPages.addMessages(e); 
            return null;
        }
    }

    // user wants to add more empty rows to the ContributingPrograms table
    global PageReference AddMoreEmptyRows() {
        AddMoreEmptyRowsToContributingPrograms();
        return null;
    }
    
    // this was a testmethod which can't be compiled in this class under api 31.  
    // but because it was marked global, it could not be completely removed.
    global static void CodeCoverageTests() {}
}