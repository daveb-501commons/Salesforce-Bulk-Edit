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
private with sharing class C501_CTRL_MassEditContribPrograms_TEST {
    
    //==================== TEST METHOD(s) ======================================
    private static testmethod void CodeCoverageTests() {
        // set up intial test data
        Account acc = new Account(name='Individual Test User');
        insert acc;

        String orgId = UserInfo.getOrganizationId();
        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000));
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        String uniqueName=orgId+dateString+RandomId;
        User user = new User(firstname = 'ABC',
            lastName = 'XYZ',
            email = uniqueName + '@test' + orgId + '.org',
            Username = uniqueName + '@test' + orgId + '.org',
            EmailEncodingKey = 'ISO-8859-1',
            Alias = uniqueName.substring(18, 23),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        ); 
        insert user;

        // Create Programs
        integer cRequests = 5;     
        List<FGM_Base__Program__c> listPrograms = new List<FGM_Base__Program__c>();   
        for (integer i = 0; i < cRequests; i++) {
            listPrograms.add(
                new FGM_Base__Program__c(
                    Name = 'Program ' + i
            ));
        }
        insert listPrograms;         

        // Create Requests
        List<Opportunity> listRequests = new List<Opportunity>();   
        for (integer i = 0; i < cRequests; i++) {
            listRequests.add(
                new Opportunity(
                    // Request Information
                    AccountId = acc.id, 
                    Name = 'Opportunity ' + 1,
                    CloseDate = System.today(),                   // Pipeline Date
                    StageName = 'Active',                         // Pipeline

                    // Program
                    FGM_Base__Lead_Program__c = listPrograms[i].Id,

                    // Financials
                    Amount = i * 1.5,

                    // Timeframe
                    FGM_Base__Start_Date__c = System.today(),

                    // Optionals
                    OwnerId = user.Id,
                    Status__c = 'Confirmed'
            ));
        }              
        insert listRequests;

        // Create ContributingPrograms
        List<FGM_Base__Payment__c> listPayments = new List<FGM_Base__Payment__c>();   
        for (integer i = 0; i < cRequests; i++) {
            listPayments.add(
                new FGM_Base__Payment__c (
                    // Update required fields
                    FGM_Base__Request__c = listRequests[i].Id,
                    FGM_Base__Amount__c = i * 10.0,
                    Pledged_or_New__c = 'New',
                    FGM_Base__Status__c = 'Scheduled',
                    FGM_Base__Scheduled_Payment_Date__c = System.today()
            ));
        }
        insert listPayments;


        // Create Budgets
        List<FGM_Base__Budget__c> listBudgets = new List<FGM_Base__Budget__c>();   
        for (integer i = 0; i < cRequests; i++) {
            listBudgets.add(
                new FGM_Base__Budget__c(
                    Name = 'Budget ' + i,
                    Budget_Status__c = 'Estimated',
                    FGM_Base__Fiscal_Year__c = '2010',
                    FGM_Base__Program__c = listPrograms[i].Id
            ));
        }
        insert listBudgets;         

        // Create Contibuting Programs
        List<FGM_Base__Contributing_Programs__c> listContributingPrograms = new List<FGM_Base__Contributing_Programs__c>();   
        for (integer i = 0; i < cRequests; i++) {
            listContributingPrograms.add(
                new FGM_Base__Contributing_Programs__c(
                    FGM_Base__Request__c = listRequests[i].Id,
                    FGM_Base__Amount__c = i * 10.0,
                    FGM_Base__Program__c = listPrograms[i].Id,
                    Budget__c = listBudgets[i].Id,
                    FGM_Base__Payment__c = listPayments[i].Id
            ));
        }
        insert listContributingPrograms;         

        //point to our VF page
        PageReference p = new PageReference('Page.MassEditContribPrograms');
        p.getParameters().put('programname', 'Program');
        p.getParameters().put('ownerid', user.id);
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this opp
        C501_CTRL_MassEditContribPrograms ctrl = new C501_CTRL_MassEditContribPrograms();
        System.AssertEquals('Program', ctrl.programname);
        System.AssertEquals(user.Id, ctrl.ownerid);
        System.Assert(ctrl.listSOPrograms.size() > 1);
        System.AssertEquals(2, ctrl.listSOOwners.size());
        System.AssertEquals(cRequests, ctrl.listContributingPrograms.size());
        
        ctrl.AddMoreEmptyRows();
        System.AssertEquals(cRequests + ctrl.cEmptyPaymentRecords, ctrl.listContributingPrograms.size());
        System.AssertEquals(true, ctrl.fHaslistContributingPrograms);
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);
        System.AssertEquals(null, ctrl.strSaveResults); 

        ctrl.programname = null;
        ctrl.ChangeProgram();
        System.AssertEquals(null, ctrl.ownerid);
        System.AssertEquals(null, ctrl.listContributingPrograms);
        
        ctrl.programname = listPrograms[0].Name;
        ctrl.ChangeProgram();
        ctrl.ownerid = user.Id;
        ctrl.ChangeOwner();
        ctrl.AddMoreEmptyRows();
        System.AssertEquals(1 + ctrl.cEmptyPaymentRecords, ctrl.listContributingPrograms.size());
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);
        
        ctrl.listContributingPrograms.get(0).FGM_Base__Amount__c = 2;
        p.getParameters().put('usersIdDirtied', ctrl.listContributingPrograms.get(0).id);
        ctrl.ContributingProgramsRecordModified();
        System.AssertEquals(1, ctrl.setContributingProgramsIdDirty.size());
        
        p.getParameters().put('usersIdDirtied', null);
        ctrl.ContributingProgramsRecordModified();
        System.AssertEquals(1, ctrl.setContributingProgramsIdDirty.size());
        System.AssertEquals(1, ctrl.numberOfRecordsDirty);

        // test the save!
        ctrl.SaveContributingPrograms();
        system.debug(ctrl.strSaveResults);
        //System.Assert(ctrl.strSaveResults.startsWith('Error'));
        ctrl.ChangeOwner();
        ctrl.SaveContributingPrograms();      
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);        
    }
}