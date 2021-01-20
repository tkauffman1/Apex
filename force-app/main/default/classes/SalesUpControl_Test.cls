@isTest
public class SalesUpControl_Test {
    
    private static Sales_Up__c createDefaultSup(){
        Sales_Up__c sup = new Sales_Up__c(Name='Test Sup');
        insert sup;
        return sup;
    }
    
    /**
     * Tests the following AC:
     * If Contact is populated, populate Buyer_Account__c with the 
     * Contact’s AccountId if populated
     */
    @IsTest
    static void testBuyerContact(){
       
        //Get default sales up
        Sales_Up__c sup = createDefaultSup();
        
        //Step 1: test default case of a Contact with no Parent Account
        Contact cont = new Contact(LastName='TestContact');
        insert cont;

        sup.Buyer_Contact__c = cont.Id;
        update sup; //Ensure no errors occured here.

        //Get Values actually stored to the database after Domain Layer logic has fired.
        sup = [SELECT Id, Buyer_Contact__c, Buyer_Account__c FROM Sales_Up__c WHERE Id =: sup.Id]; 

        //Ensure the default case works.
        System.assertEquals(cont.Id, sup.Buyer_Contact__c);
        System.assertEquals(null, sup.Buyer_Account__c);

        //Step 2: test the acceptance Criteria
        Account acct = new Account(Name='TestAcct');
        insert acct;

        cont.AccountId = acct.Id;
        update cont;

        //reset sup
        sup.Buyer_contact__c = null;
        update sup;

        sup.Buyer_Contact__c = cont.Id;
        update sup;

        sup = [SELECT Id, Buyer_Contact__c, Buyer_Account__c FROM Sales_Up__c WHERE Id =: sup.Id]; 

        //Ensure Buyer Account was populated from the contact record.
        System.assertEquals(cont.Id, sup.Buyer_Contact__c);
        System.assertEquals(acct.Id, sup.Buyer_Account__c);
    }

    /**
     *  Tests the following AC:
     *  If Account is populated and Contact is null we need to populate
     *  the Buyer_Contact__c field ONLY if there is one related Contact 
     *  on an account.
     */
    @IsTest
    static void testBuyerAccount(){
               
        //Get default sales up
        Sales_Up__c sup = createDefaultSup();
        
        //Step 1: test default case of an Account with 0 related Contacts
        Account acct = new Account(Name='TestAcct');
        insert acct;

        sup.Buyer_Account__c = acct.Id;
        update sup;

        //Get Values actually stored to the database after Domain Layer logic has fired.
        sup = [SELECT Id, Buyer_Contact__c, Buyer_Account__c FROM Sales_Up__c WHERE Id =: sup.Id]; 
        
        //test default case
        System.assertEquals(null, sup.Buyer_Contact__c);
        System.assertEquals(acct.Id, sup.Buyer_Account__c);
        
        //Step 2: test single related contact

        Contact cont = new Contact(LastName='contact', AccountId=acct.Id);
        insert cont;

        //reset sup
        sup.Buyer_Account__c = null;
        update sup;

        sup.Buyer_Account__c = acct.Id;
        update sup;

        sup = [SELECT Id, Buyer_Contact__c, Buyer_Account__c FROM Sales_Up__c WHERE Id =: sup.Id]; 

        //Ensure Buyer Contact was populated from the Account record.
        System.assertEquals(cont.Id, sup.Buyer_Contact__c);
        System.assertEquals(acct.Id, sup.Buyer_Account__c);

        //Step 3: Ensure contact populates ONLY when there is one related contact to the buyer account
        
        sup.Buyer_Account__c = null;
        sup.Buyer_Contact__c = null;
        update sup;

        Contact cont2 = new Contact(LastName='contact2',AccountId=acct.Id);
        insert cont2;

        sup.Buyer_Account__c = acct.Id;
        update sup;

        sup = [SELECT Id, Buyer_Contact__c, Buyer_Account__c FROM Sales_Up__c WHERE Id =: sup.Id]; 
        
        //Ensure contact field was not set
        System.assertEquals(null, sup.Buyer_Contact__c);
        System.assertEquals(acct.Id, sup.Buyer_Account__c);

    }

    /**
     * tests the following AC: 
     * If both the Buyer Account and Buyer Contact fields are populated, 
     * the Buyer Contact sets the precedence and the Buyer Account needs 
     * to be updated from the Contact.
     */
    @IsTest
    static void testBuyerContactFromAccount(){

        //Get default sales up
        Sales_Up__c sup = createDefaultSup();

        Account acct = new Account(name='account');
        insert acct;

        Account acct2 = new Account(name='account');
        insert acct2;

        Contact cont = new Contact(LastName='contact');
        insert cont;

        //Step 1: Test populating unrelated account / contact
        sup.Buyer_Account__c = acct.Id;
        sup.Buyer_Contact__c = cont.Id;
        update sup;

        sup = [SELECT Id, Buyer_Contact__c, Buyer_Account__c FROM Sales_Up__c WHERE Id =: sup.Id]; 

        //Ensure that because the contact is not related to the Account, the account field gets nulled out
        System.assertEquals(cont.Id, sup.Buyer_Contact__c);
        System.assertEquals(null, sup.Buyer_Account__c);

        //Step 2: Test proper alignment & that contact has the precidence 
        cont.AccountId = acct.Id;
        update cont;

        sup.Buyer_Account__c = acct2.Id;
        sup.Buyer_Contact__c = cont.id;
        update sup;

        sup = [SELECT Id, Buyer_Contact__c, Buyer_Account__c FROM Sales_Up__c WHERE Id =: sup.Id]; 

        //Ensure that the proper Account was populated. Acct2.Id should have been overwritten with Acct.Id
        System.assertEquals(cont.Id, sup.Buyer_Contact__c);
        System.assertEquals(acct.Id, sup.Buyer_Account__c);
    }


}
