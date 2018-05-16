/*
    Copyright (c) 2016 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
/**
 * @author Salesforce.org
 * @date 2017
 * @group Volunteers for Salesforce (V4S)
 * @description Tests for C501_UTIL_Describe
 */
@isTest
    private with sharing class C501_UTIL_Describe_TEST {
    /*******************************************************************************************************
     * @description Tests namespace fixup conditionally depending on whether a namespace is present
     *******************************************************************************************************/
    @isTest
    public static void TestNamespacePrefixFixups() {
        if (C501_UTIL_Describe.getNamespace()!='') {
            system.assertEquals(C501_UTIL_Describe.getNamespace()+'__foo', C501_UTIL_Describe.StrTokenNSPrefix('foo'));
            system.assertEquals(C501_UTIL_Describe.getNamespace()+'__foo__c', C501_UTIL_Describe.StrTokenNSPrefix('foo__c'));     
        } else {
            system.assertEquals('foo', C501_UTIL_Describe.StrTokenNSPrefix('foo'));
            system.assertEquals('foo__c', C501_UTIL_Describe.StrTokenNSPrefix('foo__c'));          
        }
    }
    /*******************************************************************************************************
     * @description Test invalid object name and assert and exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestInvalidObjectDescribe() {
        try {
            C501_UTIL_Describe.checkObjectCreateAccess('InvalidObjectName');
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
    /*******************************************************************************************************
     * @description Test invalid field name and assert and exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestInvalidFieldDescribe() {
        try {
            C501_UTIL_Describe.checkFieldCreateAccess(C501_UTIL_Describe.StrTokenNSPrefix('Volunteer_Job__c'),
                'InvalidFieldName');
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
    /*******************************************************************************************************
     * @description Test permissions exception, since CRUD cannot be set in a test, setting a flag on
     * C501_UTIL_Describe to simulate and asserting the exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestNoCreateAccess() {
        C501_UTIL_Describe.throwException = true;
        try {
            C501_UTIL_Describe.checkObjectCreateAccess(C501_UTIL_Describe.StrTokenNSPrefix('Volunteer_Job__c'));
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
    /*******************************************************************************************************
     * @description Test permissions exception, since CRUD cannot be set in a test, setting a flag on
     * C501_UTIL_Describe to simulate and asserting the exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestNoReadAccess() {
        C501_UTIL_Describe.throwException = true;
        try {
            C501_UTIL_Describe.checkObjectReadAccess(C501_UTIL_Describe.StrTokenNSPrefix('Volunteer_Job__c'));
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
    /*******************************************************************************************************
     * @description Test permissions exception, since CRUD cannot be set in a test, setting a flag on
     * C501_UTIL_Describe to simulate and asserting the exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestNoFieldCreateAccess() {
        C501_UTIL_Describe.throwException = true;
        try {
            C501_UTIL_Describe.checkFieldCreateAccess(C501_UTIL_Describe.StrTokenNSPrefix('Volunteer_Job__c'), 'Name');
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
    /*******************************************************************************************************
     * @description Test permissions exception, since CRUD cannot be set in a test, setting a flag on
     * C501_UTIL_Describe to simulate and asserting the exception was caught
     *******************************************************************************************************/
    @isTest
    public static void TestNoDeleteAccess() {
        C501_UTIL_Describe.throwException = true;
        try {
            C501_UTIL_Describe.checkObjectDeleteAccess(C501_UTIL_Describe.StrTokenNSPrefix('Volunteer_Job__c'));
            System.assert(false, 'An exception should have occured.');
        } catch(Exception ex) {
            System.assert(true, 'An exception should occur.');
        }
    }
}