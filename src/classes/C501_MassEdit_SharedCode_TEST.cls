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
public with sharing class C501_MassEdit_SharedCode_TEST {

    /*******************************************************************************************************
    * @description test methods to test all permutations of the User Matching Rule.
    * @return void
    */ 
    static testmethod void testUserMatchRule1() {
    	testUserMatchRule('Firstname;Lastname;Email');
    }
    static testmethod void testUserMatchRule2() {
    	testUserMatchRule('Firstname;Lastname');
    }
    static testmethod void testUserMatchRule3() {
    	testUserMatchRule('Firstname;Email');
    }
    static testmethod void testUserMatchRule4() {
    	testUserMatchRule('Lastname;Email');
    }
    static testmethod void testUserMatchRule5() {
    	testUserMatchRule('');
    }
    static testmethod void testUserMatchRule6() {
    	testUserMatchRule('Firstname;');
    }
    static testmethod void testUserMatchRule7() {
    	testUserMatchRule('Lastname');
    }
    static testmethod void testUserMatchRule8() {
    	testUserMatchRule('Email');
    }
    static void testUserMatchRule(string strRule) {

		// test data
		list<User> listCon = new list<User>();
		listCon.add(new User(Firstname='Fred', Lastname='Smith', Email='fred@smith.com'));
		listCon.add(new User(Firstname='Fred', Lastname='Smith', Email=null));
		listCon.add(new User(Firstname='Fred', Lastname='Smith', Email='NOTfred@smith.com'));
		listCon.add(new User(Firstname='NOTFred', Lastname='Smith', Email='fred@smith.com'));
		listCon.add(new User(Firstname='Fred', Lastname='NOTSmith', Email='fred@smith.com'));
		insert listCon;
		
        list<string> listStrFields = new list<string>{'Id', 'Firstname', 'Lastname', 'Email'};        
		list<User> listCon2 = C501_MassEdit_SharedCode.LookupOwner(listCon[0], listStrFields);
		
		if (strRule == 'Firstname;Lastname;Email') {
			system.assertEquals(1, listCon2.size());
		}
		if (strRule == 'Firstname;Email') {
			system.assertEquals(2, listCon2.size());
		}
		if (strRule == 'Lastname;Email') {
			system.assertEquals(2, listCon2.size());
		}
		if (strRule == 'Firstname;Lastname') {
			system.assertEquals(3, listCon2.size());
		}
		if (strRule == 'Email') {
			system.assertEquals(3, listCon2.size());
		}
		if (strRule == 'Firstname') {
			system.assertEquals(4, listCon2.size());
		}
		if (strRule == 'Lastname') {
			system.assertEquals(4, listCon2.size());
		}
		if (strRule == '') {  // we treat blank as 'Firstname;Lastname;Email'
			system.assertEquals(1, listCon2.size());
		}
    }
}