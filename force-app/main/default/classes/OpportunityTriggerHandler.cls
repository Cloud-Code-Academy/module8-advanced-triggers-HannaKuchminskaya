public with sharing class OpportunityTriggerHandler extends TriggerHandler {

    // Constructor
    public OpportunityTriggerHandler() {
    
    }

    protected override void beforeInsert() {
        setDefaultType((List<Opportunity>) Trigger.new);
    }

    
    protected override void beforeUpdate() {
        validateAmount((List<Opportunity>) Trigger.new);
        setPrimaryContactOnUpdate((List<Opportunity>) Trigger.new);
        appendStageChangeToDescription((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

   
    protected override void beforeDelete() {
        
        preventDeleteClosedOpportunity((List<Opportunity>) Trigger.old);
    }

    
    protected override void afterInsert() {
        createTasksForNewOpportunities((List<Opportunity>) Trigger.new);
    }

    
     
    protected override void afterUpdate() {
        // No afterUpdate logic
    }

    
    protected override void afterDelete() {
        notifyOwnersOpportunityDeleted((List<Opportunity>) Trigger.old);
    }

    protected override void afterUndelete() {
        assignPrimaryContactOnUndelete((Map<Id, Opportunity>) Trigger.newMap);
    }

    // HELPER METHODS

//     if (Trigger.isBefore && Trigger.isInsert){
//             // Set default Type for new Opportunities
//             for (Opportunity opp : Trigger.new) {
//             if (opp.Type == null){
//                 opp.Type = 'New Customer';
//             }  
//           } 
//     }

    
    private void setDefaultType(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if (opp.Type == null) {
                opp.Type = 'New Customer';
            }
        }
    }
//     // if (Trigger.isUpdate && Trigger.isBefore){
//     //     for(Opportunity opp : Trigger.new){
//     //         if(opp.Amount < 5000){
//     //             opp.addError('Opportunity amount must be greater than 5000');
//     //         }
//     //     }
//     // }
    
    private void validateAmount(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if (opp.Amount < 5000) {
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    // BEFORE UPDATE: Set primary contact to CEO
//  if (Trigger.isUpdate && Trigger.isBefore){
//         //Get contacts related to the opportunity account
//         Set<Id> accountIds = new Set<Id>();
//         for(Opportunity opp : Trigger.new){
//             accountIds.add(opp.AccountId);
//         }
        
//         Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
//         Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

//         for (Contact cont : contacts.values()) {
//             if (!accountIdToContact.containsKey(cont.AccountId)) {
//                 accountIdToContact.put(cont.AccountId, cont);
//             }
//         }

//         for(Opportunity opp : Trigger.new){
//             if(opp.Primary_Contact__c == null){
//                 if (accountIdToContact.containsKey(opp.AccountId)){
//                     opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
//                 }
//             }
//         }

    private void setPrimaryContactOnUpdate(List<Opportunity> opps) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opps) accountIds.add(opp.AccountId);


        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
        for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]) {
            if (!accountIdToContact.containsKey(c.AccountId)) {
                accountIdToContact.put(c.AccountId, c);
            }
        }

        for (Opportunity opp : opps) {
            if (opp.Primary_Contact__c == null && accountIdToContact.containsKey(opp.AccountId)) {
                opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
            }
        }
    }

    // BEFORE UPDATE: Append Stage change to Description
    private void appendStageChangeToDescription(List<Opportunity> opps, Map<Id, Opportunity> oldMap) {
        for (Opportunity opp : opps) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.StageName != oldOpp.StageName) {
                String existingDesc = opp.Description == null ? '' : opp.Description;
                opp.Description = existingDesc + '\nStage Change:' + opp.StageName + ':' + DateTime.now().format();
            }
        }
    }

    
//     if (Trigger.isBefore && Trigger.isDelete){
//             // Prevent deletion of closed Opportunities
//             for (Opportunity oldOpp : Trigger.old){
//                 if (oldOpp.IsClosed){
//                     oldOpp.addError('Cannot delete closed opportunity');
//                 }
//             }
//         }
    // BEFORE DELETE: Prevent deletion of any closed opportunity
    private void preventDeleteClosedOpportunity(List<Opportunity> oldOpps) {
        for (Opportunity opp : oldOpps) {
            if (opp.IsClosed) opp.addError('Cannot delete closed opportunity');
        }
    }


    //     if (Trigger.isAfter && Trigger.isInsert){
       
//             // Create a new Task for newly inserted Opportunities
//             List<Task> tasksToInsert = new List<Task>();
//             for (Opportunity opp : Trigger.new){
//                 Task tsk = new Task();
//                 tsk.Subject = 'Call Primary Contact';
//                 tsk.WhatId = opp.Id;
//                 tsk.WhoId = opp.Primary_Contact__c;
//                 tsk.OwnerId = opp.OwnerId;
//                 tsk.ActivityDate = Date.today().addDays(3);
//                 tasksToInsert.add(tsk);
//             }
       
//             insert tasksToInsert;
//     }

    // AFTER INSERT: Create tasks for new opportunities
    private void createTasksForNewOpportunities(List<Opportunity> newOpps) {
        List<Task> tasksToInsert = new List<Task>();
        for (Opportunity opp : newOpps) {
            
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                if (opp.Primary_Contact__c != null) {
                tsk.WhoId = opp.Primary_Contact__c;}
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                tasksToInsert.add(tsk);
            
        }
        if (!tasksToInsert.isEmpty()) insert tasksToInsert;
    }

    // AFTER DELETE: Notify owners via email
    private static void notifyOwnersOpportunityDeleted(List<Opportunity> oldOpps) {
        if (oldOpps == null || oldOpps.isEmpty()) return;

        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : oldOpps) ownerIds.add(opp.OwnerId);

        Map<Id, User> ownersMap = new Map<Id, User>(
            [SELECT Id, Email FROM User WHERE Id IN :ownerIds AND Email != null]
        );

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : oldOpps) {
            User owner = ownersMap.get(opp.OwnerId);
            if (owner != null && owner.Email != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{owner.Email});
                mail.setSubject('Opportunity Deleted: ' + opp.Name);
                mail.setPlainTextBody('Your Opportunity "' + opp.Name + '" has been deleted.');
                mails.add(mail);
            }
        }

        if (!mails.isEmpty()) {
            try { Messaging.sendEmail(mails); }
            catch (Exception e) { System.debug('Error sending emails: ' + e.getMessage()); }
        }
    }

    // AFTER UNDELETE: Assign primary contact (VP Sales)
    private static void assignPrimaryContactOnUndelete(Map<Id, Opportunity> newMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newMap.values()) accountIds.add(opp.AccountId);

        Map<Id, Account> accMap = new Map<Id, Account>(
            [SELECT Id, (SELECT Id FROM Contacts WHERE Title = 'VP Sales' LIMIT 1) 
             FROM Account WHERE Id IN :accountIds]
        );

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : newMap.values()) {
            if (opp.Primary_Contact__c == null &&
                accMap.get(opp.AccountId)?.Contacts != null &&
                !accMap.get(opp.AccountId).Contacts.isEmpty()) {

                oppsToUpdate.add(new Opportunity(
                    Id = opp.Id,
                    Primary_Contact__c = accMap.get(opp.AccountId).Contacts[0].Id
                ));
            }
        }

        if (!oppsToUpdate.isEmpty()) update oppsToUpdate;
    }
}
