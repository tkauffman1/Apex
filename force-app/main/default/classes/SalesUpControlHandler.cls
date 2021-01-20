public class SalesUpControlHandler {
    /**
     * Constructor
     */ 
    public SalesUpControlHandler() {}

    /**
     * Aligns buyer and cobuyer info
     * Before Update
     * @param  triggerNew triggerNew Sales Ups in update call
     */
    public void alignBuyer(List<Sales_Up__c> triggerNew) {
        
        //Instantiate map with wrapper
        Map<Id, BuyerInfo> buyerMap = new Map<Id, BuyerInfo>();
        Set<Id> acctIds    = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        
        for(Sales_Up__c sup : triggerNew){
            
            buyerMap.put(sup.Id, new BuyerInfo(sup, new Account(), new List<Contact>()));
            
            if(sup.Buyer_Account__c != null){
                acctIds.add(sup.Buyer_Account__c);
            }
            if(sup.Buyer_Contact__c != null){
                contactIds.add(sup.Buyer_Contact__c);
            }
        }

        //Instantiate a map for each Account and contact on the record
        Map<Id, Contact> contactMap = new Map<Id,Contact>([SELECT Id, AccountId FROM Contact WHERE Id IN: contactIds]);
        for(Contact c : contactMap.values()){
            if(c.AccountId != null){
                acctIds.add(c.AccountId);
            }
        }
        Map<Id, Account> accountMap = new Map<Id,Account>([SELECT Id FROM Account WHERE Id IN: acctIds]);

        Set<Id> acctContactSet = new Set<Id>();
        
        //Loop triggerNew (Sales Ups) and populate the Buyer Info Wrapper (We will populate the related contacts later)
        for(Sales_Up__c sup : triggerNew){
            if(sup.Buyer_Account__c != null){
                buyerMap.get(sup.Id).buyerAccount = accountMap.get(sup.Buyer_Account__c);
            }
            if(sup.Buyer_Contact__c != null){
                buyerMap.get(sup.Id).buyerContacts.add(contactMap.get(sup.Buyer_Contact__c));
            }

            if(sup.Buyer_Account__c != null && sup.Buyer_Contact__c == null){
                acctContactSet.add(sup.Buyer_Account__c);
            }

        }

        //Map to hold related Contacts
        Map<Id, List<Contact>> relatedContactMap = new Map<Id, List<Contact>>();
        for(Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN: acctContactSet]){
            if(relatedContactMap.get(c.AccountId) == null){
                relatedContactMap.put(c.AccountId, new List<Contact>{c});
            }else{
                relatedContactMap.get(c.AccountId).add(c);
            }
        }

        //Populate Account and all related Contacts to Buyer Info Wrapper
        for(Id sId : buyerMap.keySet()){
            BuyerInfo b = buyerMap.get(sId);
            if(b.SalesUp.Buyer_Contact__c != null){//Buyer Contact has precedence
                if(contactMap.get(b.SalesUp.Buyer_Contact__c).AccountId != null){ //Set Account
                    b.buyerAccount = accountMap.get(contactMap.get(b.SalesUp.Buyer_Contact__c).AccountId);
                } else {
                    b.buyerAccount = new Account();
                }
            } else if(b.SalesUp.Buyer_Account__c != null) {
                if(relatedContactMap.get(b.SalesUp.Buyer_Account__c) != null){
                    b.buyerContacts = relatedContactMap.get(b.SalesUp.Buyer_Account__c);
                }
            }
        }

        //We need to loop the BuyerInfo List one more time to sanitize the data to specs
        for(BuyerInfo b : buyerMap.values()){
            if(b.salesUp.Buyer_Contact__c != null){
                b.SalesUp.Buyer_Account__c = b.buyerAccount.Id;
            } else if(b.salesUp.Buyer_Account__c != null){
                if(b.buyerContacts.size() == 1){
                    b.salesUp.Buyer_Contact__c = b.buyerContacts[0].Id;
                } else {
                    b.salesUp.Buyer_Contact__c = null;
                }
            }

        }

    }

    public class BuyerInfo {
        public Sales_Up__c salesUp;
        public Account buyerAccount;
        public List<Contact> buyerContacts;

        public BuyerInfo(Sales_Up__c salesUp, Account buyerAccount, List<Contact> buyerContacts){
            this.salesUp = salesUp;
            this.buyerAccount = buyerAccount;
            this.buyerContacts = buyerContacts != null ? buyerContacts : new List<Contact>();
        }
    }

}
