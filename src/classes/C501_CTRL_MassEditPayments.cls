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

    global integer cEmptyPaymentRecords {
        get {
            return 1;
        }
    }
    
    private C501_MassEdit_SharedCode c501MassEdit_SharedCode;
    private List<String> listStrFields;
    private List<String> listStrFieldsViewOnly;
    
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
        if (!listStrFields.contains('FGM_Base__Request__r.Name')) {
            listStrFields.add('FGM_Base__Request__r.Name');
        }
        if (!listStrFields.contains('FGM_Base__Request__r.OwnerId')) {
            listStrFields.add('FGM_Base__Request__r.OwnerId');
        }
        if (!listStrFields.contains('FGM_Base__Request__r.FGM_Base__Lead_Program__c')) {
            listStrFields.add('FGM_Base__Request__r.FGM_Base__Lead_Program__c');
        }

        // Get list of fields from fieldset
        listStrFieldsViewOnly = new List<String>();
        for (Schema.FieldSetMember f : SObjectType.FGM_Base__Payment__c.FieldSets.Mass_Edit_Payments_ViewOnly.getFields()) {
            listStrFieldsViewOnly.add(f.getFieldPath());
        }

        if (!listStrFieldsViewOnly.contains('Id')) {
            listStrFieldsViewOnly.add('Id');
        }
        if (!listStrFieldsViewOnly.contains('FGM_Base__Request__r.Name')) {
            listStrFieldsViewOnly.add('FGM_Base__Request__r.Name');
        }
        if (!listStrFieldsViewOnly.contains('FGM_Base__Request__r.Owner.Name__c')) {
            listStrFieldsViewOnly.add('FGM_Base__Request__r.Owner.Name__c');
        }
        if (!listStrFieldsViewOnly.contains('FGM_Base__Request__r.FGM_Base__Lead_Program__c')) {
            listStrFieldsViewOnly.add('FGM_Base__Request__r.Lead_Program__c');
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
        listPayments = null;
        listPaymentsViewOnly = null;
        strSaveResults = null;
        return null;
    }

    // the user has changed the date query
    global virtual PageReference ChangeDate() {
        // clear out all state that is specific to the Date
        listSOPrograms = null;
        listSOOwners = null;
        listPayments = null;
        listPaymentsViewOnly = null;
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

    // The list of Payments.
    global List<FGM_Base__Payment__c> listPaymentsViewOnly {
        get {
            if (listPaymentsViewOnly == null) {
                FillListPaymentsViewOnly();
            }

            return listPaymentsViewOnly;
        }
        
        set;
    }

    // helper function that the client can override, to query for the appropriate fields in Payments.
    global virtual void FillListPaymentsViewOnly() {

        if (programname == null || String.isBlank(programname)) {
            return;
        }

        listPaymentsViewOnly = c501MassEdit_SharedCode.listPaymentsByCriteria(listStrFieldsViewOnly, programname, ownerid, paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c, paymentDateFilter.FGM_Base__Payment_Date__c);
    }
    
    // helper function that the client can override, to query for the appropriate fields in Payments.
    global virtual void FillListPayments() {

        if (programname == null || String.isBlank(programname)) {
            return;
        }

        listPayments = c501MassEdit_SharedCode.listPaymentsByCriteria(listStrFields, programname, ownerid, paymentDateFilter.FGM_Base__Scheduled_Payment_Date__c, paymentDateFilter.FGM_Base__Payment_Date__c);
    }
    
    global Boolean fHasListPayments {
        get {
            return listPayments != null && listPayments.size() > 0;
        }
    }     

    global Boolean fHasListPaymentsViewOnly {
        get {
            return listPaymentsViewOnly != null && listPaymentsViewOnly.size() > 0;
        }
    }     
    
    global virtual void AddMoreEmptyRowsToPayments() {
        try {
            if (listPayments == null) return;

            for (integer i = 0; i < cEmptyPaymentRecords; i++) { 
                FGM_Base__Payment__c payment = new FGM_Base__Payment__c();
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
    
    // New Payment
    global virtual PageReference NewPayment() {
        return new Pagereference('/a0C/e?retURL=%2Fa0C%2Fo');
    }

    //save the Payments created or modified
    global virtual PageReference SavePayments() {
        
        if (listPayments == null) return null;
        
        strSaveResults = null;
        
        try {
            // create two lists: one to update and one to insert.

            List<FGM_Base__Payment__c> listPaymentsUpdate = new List<FGM_Base__Payment__c>();
            
            // Disabled creating new payments on the Mass Edit page - too many required fields so just change new row to New Payment which takes user to a new screen to create payment
            List<FGM_Base__Payment__c> listPaymentsCreate = new List<FGM_Base__Payment__c>();

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
            
            if (!listPaymentsUpdate.isEmpty()) {
                update listPaymentsUpdate;
            }
           
            /*if (!listPaymentsCreate.isEmpty()) {
                insert listPaymentsCreate;
            }*/
            
            strSaveResults = String.valueOf(listPaymentsCreate.size() + listPaymentsUpdate.size()) + ' ' + Label.labelMassEditPaymentsSaveSuccess;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, strSaveResults));

            // successful save, so clear out dirty list
            setPaymentsIdDirty = null;
            listPaymentsViewOnly = null;

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