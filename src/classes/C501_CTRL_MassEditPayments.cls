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

global virtual with sharing class C501_CTRL_MassEditPayments {

    global integer cEmptyFGMBasePaymentRecords {
        get {
            return 1;
        }
    }
    
    private C501_MassEdit_SharedCode c501MassEdit_SharedCode;
    private List<String> listStrFields;
    
    global boolean redirect { get; private set; }
    global ID idRedirect { get; private set; }
    
    // constructor
    global C501_CTRL_MassEditPayments() {
        redirect = false;
        c501MassEdit_SharedCode = new C501_MassEdit_SharedCode();
        
        // handle optional parameters (must use string, not ID, to handle null)
        string id = ApexPages.currentPage().getParameters().get('programname');
        if (id != null && id != '') programname = id;
        
        id = ApexPages.currentPage().getParameters().get('ownerid');
        if (id != null && id != '') ownerid = id;

        // Get list of fields from fieldset
        listStrFields = new List<String>();
        for (Schema.FieldSetMember f : SObjectType.FGM_Base__Payment__c.FieldSets.MassEditPayments.getFields()) {
            listStrFields.add(f.getFieldPath());
        }

        if (!listStrFields.contains('Id')) {
            listStrFields.add('Id');
        }
        if (!listStrFields.contains('FGM_Base__Request__r.OwnerId')) {
            listStrFields.add('FGM_Base__Request__r.OwnerId');
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
                
                paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c = Date.newInstance(system.today().addYears(-1).year(), 1, 1);
                paymentDateFilter.FGM_Base__Payment_Date__c = system.today();
            }
            return paymentDateFilter;
        }
        set;
    }

    // the user has changed the Owner dropdown
    global virtual PageReference ChangeOwner() {
        // clear out all state that is specific to the Owner
        listPayments = null;
        strSaveResults = null;
        return null;
    }

    // the user has changed the date query
    global virtual PageReference ChangeDate() {
        // clear out all state that is specific to the Date
        listSOPrograms = null;
        listSOOwners = null;
        listPayments = null;
        strSaveResults = null;
        return null;
    }

    // status string for reporting the results of saving.
    global String strSaveResults { get; set; }
      
    // The list of Payments.
    global List<FGM_Base__Payment__c> listPayments {
        get {
            if (listPayments == null) {
                FillListPayments();
            }
            return listPayments;
        }
        
        set;
    }
    
    // helper function that the client can override, to query for the appropriate fields in Payments.
    global virtual void FillListPayments() {

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

        strSoql += ' from FGM_Base__Payment__c where FGM_Base__Request__c <> null and FGM_Base__Request__c in :requestIds';
        
        if (paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c != null) {
            Date dtStart = paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c;
            strSoql += ' and FGM_Base__Scheduled_Payment_Date__c >= :dtStart ';
        }
        if (paymentDateFilter.FGM_Base__Payment_Date__c != null) {
            Date dtEnd = paymentDateFilter.FGM_Base__Payment_Date__c;
            strSoql += ' and FGM_Base__Scheduled_Payment_Date__c <= :dtEnd ';
        }

        strSoql += ' order by FGM_Base__Scheduled_Payment_Date__c, FGM_Base__Request__r.Owner.Name ASC NULLS FIRST';
        
        listPayments = Database.Query(strSoql); 
    }
    
    global Boolean fHasListPayments {
        get {
            return listPayments != null && listPayments.size() > 0;
        }
    }     
 
    global virtual void AddMoreEmptyRowsToPayments() {
        try {
            if (listPayments == null) return;

            for (integer i = 0; i < cEmptyFGMBasePaymentRecords; i++) { 
                FGM_Base__Payment__c payment = new FGM_Base__Payment__c();
                payment.FGM_Base__Request__r.OwnerId = ownerid;
                listPayments.add(payment);
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);            
        }       
    }
    
    // used to track the Id's of all FGM_Base__Payment__c records that get modified.
    global Set<ID> setPaymentsIdDirty {
        get {
            if (setPaymentsIdDirty == null) {
                setPaymentsIdDirty = new Set<ID>();
            }
            return setPaymentsIdDirty;
        }
        set;
    }
    
    // to allow vf page to see how many FGM_Base__Payment__c records are dirty
    global Integer numberOfRecordsDirty {
        get { 
            if (setPaymentsIdDirty == null)
                return 0;
            else
                return setPaymentsIdDirty.size();
        }
    }
    
    // this gets called whenever a field in the Payments datatable is modified.
    // use this to remember which existing Payments records have been modified.
    global virtual PageReference PaymentsRecordModified() {
        String strId = ApexPages.currentPage().getParameters().get('usersIdDirtied');
        if (strId != null && strId != '') setPaymentsIdDirty.add(strId);
        return null;
    }
    
    //save the Payments created or modified
    global virtual PageReference SavePayments() {
        
        if (listPayments == null) return null;
        
        strSaveResults = null;
        
        try {
            // create two lists: one to update and one to insert.
            List<FGM_Base__Payment__c> listPaymentsCreate = new List<FGM_Base__Payment__c>();
            List<FGM_Base__Payment__c> listPaymentsUpdate = new List<FGM_Base__Payment__c>();

            for (FGM_Base__Payment__c payment : listPayments) {
                if (payment.Id != null) {
                    // we couldn't reliably mark dirty records in all scenarios,
                    // so we've decided it is better to always update all records.
                    //if (setPaymentsIdDirty.contains(payment.Id)) 
                        listPaymentsUpdate.add(payment);
                } else if (payment.FGM_Base__Request__r.OwnerId != null) {
                    listPaymentsCreate.add(payment);
                }
            }
            
            update listPaymentsUpdate;
           
            insert listPaymentsCreate;
            
            strSaveResults = String.valueOf(listPaymentsCreate.size() + listPaymentsUpdate.size()) + ' ' + Label.labelMassEditPaymentsSaveSuccess;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, strSaveResults));
            // successful save, so clear out dirty list
            setPaymentsIdDirty = null;
            return null;            
        } catch (Exception e) {
            strSaveResults = Label.labelMassEditPaymentsErrorOnSave;
            ApexPages.addMessages(e); 
            return null;
        }
    }

    // user wants to add more empty rows to the Payments table
    global PageReference AddMoreEmptyRows() {
        AddMoreEmptyRowsToPayments();
        return null;
    }
    
    // this was a testmethod which can't be compiled in this class under api 31.  
    // but because it was marked global, it could not be completely removed.
    global static void CodeCoverageTests() {}
}