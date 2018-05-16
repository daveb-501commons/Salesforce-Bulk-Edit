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

@isTest
private with sharing class C501_CTRL_MassEditOpportunities_TEST {
    
    //==================== TEST METHOD(s) ======================================
    private static testmethod void CodeCoverageTests() {
    
        // set up intial test data
        Account acc = new Account(name='Individual Test User');
        insert acc;
        User user = new User(Lastname='Testy');
        insert user;
        FGM_Base__Program__c cmp = new FGM_Base__Program__c(name='Test FGM_Base__Program__c', FGM_Base__Active__c=true);
        insert cmp;
        //User account = new User(name='account1', FGM_Base__Program__c=cmp.Id);
        list<Opportunity> listAmounts = new list<Opportunity>();   
        integer cAmounts = 5;     
        for (integer i = 0; i < cAmounts; i++) {
            Opportunity amount = new Opportunity(
                AccountId=acc.id, 
                OwnerId=user.Id,
                FGM_Base__Start_Date__c=System.today(), 
                Status__c='Confirmed'
                );
            listAmounts.add(amount);
        }                       
        insert listAmounts;
        
        //point to our VF page
        PageReference p = new PageReference('Page.MassEditOpportunities');
        p.getParameters().put('programid', cmp.id);
        p.getParameters().put('ownerid', user.id);
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this opp
        C501_CTRL_MassEditOpportunities ctrl = new C501_CTRL_MassEditOpportunities();
        System.AssertEquals(cmp.Id, ctrl.programid);
        System.AssertEquals(user.Id, ctrl.ownerid);
        System.Assert(ctrl.listSOPrograms.size() > 1);
        System.AssertEquals(2, ctrl.listSOOwners.size());
        System.AssertEquals(cAmounts + ctrl.cEmptyOpportunityRecords, ctrl.listOpportunities.size());
        
        ctrl.AddMoreEmptyRows();
        System.AssertEquals(cAmounts + (2 * ctrl.cEmptyOpportunityRecords), ctrl.listOpportunities.size());
        System.AssertEquals(true, ctrl.fHasListOpportunities);
        System.Assert(ctrl.Cancel() == null);
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);
        System.AssertEquals(null, ctrl.strSaveResults); 

        ctrl.programid = null;
        ctrl.ChangeProgram();
        System.AssertEquals(null, ctrl.ownerid);
        System.AssertEquals(null, ctrl.listOpportunities);
        
        ctrl.programid = cmp.Id;
        ctrl.ChangeProgram();
        ctrl.ownerid = user.Id;
        ctrl.ChangeOwner();
        System.AssertEquals(cAmounts + ctrl.cEmptyOpportunityRecords, ctrl.listOpportunities.size());
        System.AssertEquals(cAmounts + ctrl.cEmptyOpportunityRecords, ctrl.listOpportunities.size());
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);
        
        ctrl.listOpportunities.get(0).Amount = 2;
        p.getParameters().put('usersIdDirtied', ctrl.listOpportunities.get(0).id);
        ctrl.OpportunitiesRecordModified();
        System.AssertEquals(1, ctrl.setOpportunitiesIdDirty.size());
        
        Opportunity opp = ctrl.listOpportunities.get(5);
        opp.OwnerId = user.id;
        opp.AccountId = acc.id;
        opp.Status__c = 'Completed';
        opp.FGM_Base__Start_Date__c = system.today();
        opp.Amount = null; // to test failure
        p.getParameters().put('usersIdDirtied', null);
        ctrl.OpportunitiesRecordModified();
        System.AssertEquals(1, ctrl.setOpportunitiesIdDirty.size());
        System.AssertEquals(1, ctrl.numberOfRecordsDirty);

        // test the save!
        ctrl.SaveOpportunities();
        system.debug(ctrl.strSaveResults);
        System.Assert(ctrl.strSaveResults.startsWith('Error'));
        opp.Amount = 2.5;
        ctrl.SaveAndCloseOpportunities();      
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);
        
    }

}