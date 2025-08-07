public class EmailMessageTriggerHelper {
    
    public static void deleteInternalEmail(List<EmailMessage> newEmailList){
        Set<Id> caseId = new Set<Id>();
        Map<Id, String> caseMap = new Map<Id, String>();
        list<EmailMessage> deleteEmailList = new list<EmailMessage>();
        for(EmailMessage item: newEmailList) {
            caseId.add(item.RelatedToId);
        }
        
        
        list<Case> caseList = [SELECT Id, ContactEmail FROM Case WHERE Id IN: caseId];
        for(Case c : caseList){
            caseMap.put(c.Id, c.ContactEmail);
        }
        
        for(EmailMessage item: newEmailList) {
            
            if(caseMap.get(item.RelatedToId) != item.ToAddress){
                EmailMessage record = new EmailMessage(Id = item.Id);
                deleteEmailList.add(record);
            }
        }
        
        if(!deleteEmailList.isEmpty()) {
            delete deleteEmailList;
        }
        
    }

}