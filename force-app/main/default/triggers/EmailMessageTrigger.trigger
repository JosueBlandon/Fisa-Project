trigger EmailMessageTrigger on EmailMessage (after insert) {
    if(trigger.isInsert) {
        if(trigger.isAfter) {
            EmailMessageTriggerHandler.afterInsert(trigger.new, trigger.oldMap);
        }
    }
}