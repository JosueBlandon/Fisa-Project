public class EmailMessageTriggerHandler {
     public static void afterInsert(List<EmailMessage> newEmailList, Map<Id, EmailMessage> oldEmailMap){
        //CaseTriggerHelper.historialDescripcion(newCaseList);
        EmailMessageTriggerHelper.deleteInternalEmail(newEmailList);
    }
}