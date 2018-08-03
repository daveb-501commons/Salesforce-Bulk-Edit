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

global virtual with sharing class C501_CTRL_MassEditOpportunities {

    global integer cEmptyOpportunityRecords {
        get {
            return 1;
        }
    }
    
    private C501_MassEdit_SharedCode c501MassEdit_SharedCode;
    private List<String> listStrFields;
    
    global boolean redirect { get; private set; }
    global ID idRedirect { get; private set; }
    
    // constructor
    global C501_CTRL_MassEditOpportunities() {
        redirect = false;
        c501MassEdit_SharedCode = new C501_MassEdit_SharedCode();
        
        // handle optional parameters (must use string, not ID, to handle null)
        string id = ApexPages.currentPage().getParameters().get('programid');
        if (id != null && id != '') programid = id;
        
        id = ApexPages.currentPage().getParameters().get('ownerid');
        if (id != null && id != '') ownerid = id;

        // Get list of fields from fieldset
        listStrFields = new List<String>();
        for (Schema.FieldSetMember f : SObjectType.Opportunity.FieldSets.MassEditOpportunities.getFields()) {
            listStrFields.add(f.getFieldPath());
        }

        // Required fields
        listStrFields.add('FGM_Base__Lead_Program__c');
        listStrFields.add('OwnerId');
    }   
    
    // holds the currently selected Program in the Program dropdown
    global ID programid { get; set; }

    // the list of Programs to put in the Program dropdown
    global list<SelectOption> listSOPrograms {
        get {
            if (listSOPrograms == null )
                listSOPrograms = c501MassEdit_SharedCode.listSOProgramsWithRequests(oppDateFilter.FGM_Base__Start_Date__c, oppDateFilter.FGM_Base__End_Date__c);

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
    global list<SelectOption> listSOOwners {
        get {
            if (listSOOwners == null && programid != null) {
                listSOOwners = c501MassEdit_SharedCode.listSOOwnersOfRequests(programid, oppDateFilter.FGM_Base__Start_Date__c, oppDateFilter.FGM_Base__End_Date__c);
            }
            return listSOOwners;
        }
        
        set;
    }
    
    // dates to filter the list of requests
    global date startDate { get; set; }
    global date endDate { get; set; }
    
    global Opportunity oppDateFilter {
        get {
            if (oppDateFilter == null) {
                oppDateFilter = new Opportunity();
                
                oppDateFilter.FGM_Base__Start_Date__c = Date.newInstance(system.today().addYears(-1).year(), 1, 1);
                oppDateFilter.FGM_Base__End_Date__c = system.today();
            }
            return oppDateFilter;
        }
        set;
    }

    // the user has changed the Owner dropdown
    global virtual PageReference ChangeOwner() {
        // clear out all state that is specific to the Owner
        listOpportunities = null;
        strSaveResults = null;
        return null;
    }

    // the user has changed the date query
    global virtual PageReference ChangeDate() {
        // clear out all state that is specific to the Date
        listSOPrograms = null;
        listSOOwners = null;
        listOpportunities = null;
        strSaveResults = null;
        return null;
    }

    // status string for reporting the results of saving.
    global String strSaveResults { get; set; }
      
    // The list of Opportunities.
    global list<Opportunity> listOpportunities {
        get {
            if (listOpportunities == null) {
                FillListOpportunities();
            }
            return listOpportunities;
        }
        
        set;
    }
    
    // helper function that the client can override, to query for the appropriate fields in Opportunities.
    global virtual void FillListOpportunities() {

        // if they haven't yet picked a program
        if (programid == null) return;           
        
        // find the existing owners
        // we need to use dynamic soql to pick up all custom fields we don't know about
        string strSoql = 
            'select ' + String.join(listStrFields, ',');

        strSoql += ' from Opportunity where FGM_Base__Lead_Program__c = :programid ';
        
        if (ownerid != null)
            strSoql += ' and (OwnerId = :ownerid or OwnerId = null) ';

        if (oppDateFilter.FGM_Base__Start_Date__c != null) {
            Date dtStart = oppDateFilter.FGM_Base__Start_Date__c;
            strSoql += ' and CloseDate >= :dtStart ';
        }
        if (oppDateFilter.FGM_Base__End_Date__c != null) {
            Date dtEnd = oppDateFilter.FGM_Base__End_Date__c;
            strSoql += ' and CloseDate <= :dtEnd ';
        }

        strSoql += ' and StageName <> \'Closed\' and StageName <> \'Withdrawn\'';
        strSoql += ' order by Owner.Name, CloseDate ASC NULLS FIRST';
        
        listOpportunities = Database.Query(strSoql); 
    }
    
    global Boolean fHasListOpportunities {
        get {
            return listOpportunities != null && listOpportunities.size() > 0;
        }
    }     
 
    global virtual void AddMoreEmptyRowsToOpportunities() {
        try {
            if (listOpportunities == null) return;

            for (integer i = 0; i < cEmptyOpportunityRecords; i++) { 
                Opportunity opp = new Opportunity();
                opp.OwnerId = ownerid;
                opp.FGM_Base__Lead_Program__c = programid;
                listOpportunities.add(opp);
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);            
        }       
    }
    
    // used to track the Id's of all Opportunity records that get modified.
    global Set<ID> setOpportunitiesIdDirty {
        get {
            if (setOpportunitiesIdDirty == null) {
                setOpportunitiesIdDirty = new Set<ID>();
            }
            return setOpportunitiesIdDirty;
        }
        set;
    }
    
    // to allow vf page to see how many Opportunity records are dirty
    global Integer numberOfRecordsDirty {
        get { 
            if (setOpportunitiesIdDirty == null)
                return 0;
            else
                return setOpportunitiesIdDirty.size();
        }
    }
    
    // this gets called whenever a field in the Opportunities datatable is modified.
    // use this to remember which existing Opportunities records have been modified.
    global virtual PageReference OpportunitiesRecordModified() {
        String strId = ApexPages.currentPage().getParameters().get('usersIdDirtied');
        if (strId != null && strId != '') setOpportunitiesIdDirty.add(strId);
        return null;
    }
    
    //save the Opportunities created or modified
    global virtual PageReference SaveOpportunities() {
        
        if (listOpportunities == null) return null;
        
        strSaveResults = null;
        
        try {
            // create two lists: one to update and one to insert.
            list<Opportunity> listOpportunitiesCreate = new list<Opportunity>();
            list<Opportunity> listOpportunitiesUpdate = new list<Opportunity>();

            for (Opportunity opp : listOpportunities) {
                if (opp.Id != null) {
                    // we couldn't reliably mark dirty records in all scenarios,
                    // so we've decided it is better to always update all records.
                    //if (setOpportunitiesIdDirty.contains(opp.Id)) 
                        listOpportunitiesUpdate.add(opp);
                } else if (opp.OwnerId != null) {
                    listOpportunitiesCreate.add(opp);
                }
            }
            
            update listOpportunitiesUpdate;
           
            insert listOpportunitiesCreate;
            
            strSaveResults = String.valueOf(listOpportunitiesCreate.size() + listOpportunitiesUpdate.size()) + ' ' + Label.labelMassEditSaveSuccess;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, strSaveResults));
            // successful save, so clear out dirty list
            setOpportunitiesIdDirty = null;
            return null;            
        } catch (Exception e) {
            strSaveResults = Label.labelMassEditErrorOnSave;
            ApexPages.addMessages(e); 
            return null;
        }
    }

    //save the Opportunities created or modified, and then close the page.
    global virtual PageReference SaveAndCloseOpportunities() {
        SaveOpportunities();
        if (ApexPages.hasMessages(ApexPages.Severity.ERROR) ||
           ApexPages.hasMessages(ApexPages.Severity.FATAL) ||
            ApexPages.hasMessages(ApexPages.Severity.WARNING)) {
                return null; // don't close window.
        }
        return Cancel();    
    }
    
    // user wants to close this page
    global virtual PageReference Cancel() {
        // figure out which object to return to.
        if (ownerid != null)
            idRedirect = ownerid;
        else
            idRedirect = programid;
        
        // trigger our redirect component to redirect using javascript.
        redirect = true;
        return null;
    }
    
    // user wants to add more empty rows to the Opportunities table
    global PageReference AddMoreEmptyRows() {
        AddMoreEmptyRowsToOpportunities();
        return null;
    }
    
    // this was a testmethod which can't be compiled in this class under api 31.  
    // but because it was marked global, it could not be completely removed.
    global static void CodeCoverageTests() {}
}