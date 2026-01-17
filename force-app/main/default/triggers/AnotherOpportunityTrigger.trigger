
trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {}
//     if (Trigger.isBefore && Trigger.isInsert){
//             // Set default Type for new Opportunities
//             for (Opportunity opp : Trigger.new) {
//             if (opp.Type == null){
//                 opp.Type = 'New Customer';
//             }  
//           } 
//     } 
               
//     if (Trigger.isBefore && Trigger.isDelete){
//             // Prevent deletion of closed Opportunities
//             for (Opportunity oldOpp : Trigger.old){
//                 if (oldOpp.IsClosed){
//                     oldOpp.addError('Cannot delete closed opportunity');
//                 }
//             }
//         }
    

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
//     if (Trigger.isBefore && Trigger.isUpdate) {
//     for (Opportunity opp : Trigger.new) {
//         Opportunity oldOpp = Trigger.oldMap.get(opp.Id);

//         // Check if StageName actually changed
//         if (opp.StageName != oldOpp.StageName) {
//             String existingDesc = opp.Description == null ? '' : opp.Description;
//             opp.Description = existingDesc +
//                 '\nStage Change:' + opp.StageName + ':' +
//                 DateTime.now().format();
//         }
//     }
// }


//         // Send email notifications when an Opportunity is deleted 
// if (Trigger.isAfter && Trigger.isDelete){
//             notifyOwnersOpportunityDeleted(Trigger.old);
//         } 
//         // Assign the primary contact to undeleted Opportunities
// if (Trigger.isAfter && Trigger.isUndelete){
//             assignPrimaryContact(Trigger.newMap);
//         }
    

//     /*
//     notifyOwnersOpportunityDeleted:
//     - Sends an email notification to the owner of the Opportunity when it gets deleted.
//     - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
//     */


// private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
//     if (opps == null || opps.isEmpty()) return;

//     // Collect unique owner IDs
//     Set<Id> ownerIds = new Set<Id>();
//     for (Opportunity opp : opps) {
//         ownerIds.add(opp.OwnerId);
//     }

//     // Query all owners at once
//     Map<Id, User> ownersMap = new Map<Id, User>(
//         [SELECT Id, Email FROM User WHERE Id IN :ownerIds AND Email != null]
//     );

//     List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

//     for (Opportunity opp : opps) {
//         User owner = ownersMap.get(opp.OwnerId);
//         if (owner != null && owner.Email != null) {
//             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//             mail.setToAddresses(new String[] { owner.Email });
//             mail.setSubject('Opportunity Deleted: ' + opp.Name);
//             mail.setPlainTextBody('Your Opportunity "' + opp.Name + '" has been deleted.');
//             mails.add(mail);
//         }
//     }

//     // Send all emails in bulk
//     if (!mails.isEmpty()) {
//         try {
//             Messaging.sendEmail(mails);
//         } catch (Exception e) {
//             System.debug('Error sending emails: ' + e.getMessage());
//         }
//     }
// }



//     /*
//     assignPrimaryContact:
//     - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
//     - Only updates the Opportunities that don't already have a primary contact.
//     */
   
// public static void assignPrimaryContact(Map<Id, Opportunity> oppNewMap){
//         Set<Id> oppAccountIds = new Set<Id> ();
//         for (Opportunity opp : oppNewMap.values()){
//             oppAccountIds.add(opp.AccountId);
//         }
//         Map<Id, Account> accMap = new Map<Id, Account> ([SELECT Id, Name,
//                                     (SELECT Id FROM Contacts WHERE Title = 'VP Sales') 
//                                     FROM Account WHERE Id IN :oppAccountIds]);
//         Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
//         for (Opportunity opp :oppNewMap.values()) {
//             if (opp.Primary_Contact__c == null && !accMap.get(opp.AccountId).Contacts.isEmpty()){
//                 Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
//                 oppToUpdate.Primary_Contact__c = accMap.get(opp.AccountId).Contacts[0].Id;
//                 oppMap.put(opp.Id, oppToUpdate);
//             }
//         }
//         update oppMap.values();
//     }
// }
//