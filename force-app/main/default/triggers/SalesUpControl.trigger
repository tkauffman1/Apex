trigger SalesUpControl on Sales_Up__c (before insert, before update) {

    SalesUpControlHandler handler = new SalesUpControlHandler();

    switch on Trigger.OperationType {
        when BEFORE_UPDATE {
            handler.alignBuyer(Trigger.new);
        }
    }    
}   