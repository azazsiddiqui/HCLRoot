/**
 *@author :RAJ BEHURA
 * @description :Test Class for Account_TerritoryMapHelper class
 */
@isTest
private class Account_TerritoryMapHelper_Test {
    static testMethod void testAccount_TerritoryMapHelper_Test()
    {
      test.startTest();
      Territory__c  newTerriParent=new Territory__c(Name='Terri1',External_ID__c='Terri1');
      insert newTerriParent;
      Territory__c  newTerriParent1=new Territory__c(Name='Terri2',External_ID__c='Terri2');
      insert newTerriParent1;
      Territory_Mapping__c newTeriOne = new Territory_Mapping__c(Geo_level_0__c = '12345',Geo_Level_1__c ='testdist',Territory_Name__c=newTerriParent.id);
      insert newTeriOne;
      Territory_Mapping__c newTeriTwo = new Territory_Mapping__c(Geo_level_0__c = '12377',Geo_Level_1__c ='testdist2',Territory_Name__c=newTerriParent1.id);
      insert newTeriTwo;
      
      Account testAccountMap=TYCOSALESUTILITYFORTESTDATA.createTestAccount('testaccmap',null,'Tier 1',null,null);
      insert testAccountMap;
      system.assertEquals(testAccountMap.BillingPostalCode,'12345');
      testAccountMap.BillingPostalCode='12377-66';
      update testAccountMap;
      system.assertEquals(testAccountMap.BillingPostalCode,'12377-66');
      testAccountMap.BillingPostalCode='12377 66';
      update testAccountMap;
      testAccountMap.BillingPostalCode='1237766';
      update testAccountMap;  
      
      test.stopTest();
    }
}