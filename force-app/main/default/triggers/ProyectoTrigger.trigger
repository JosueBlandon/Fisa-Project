/**
**************************************************************************************************************
* @author           Intellect Systems
* @project          Fisa Ecuador - Implementación CRM
* @name             ProyectoTrigger
* @description      Trigger to FS_Proyecto__c Object.
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-11-27   Intellect Systems             Initial version.
**************************************************************************************************************
*/

trigger ProyectoTrigger on FS_Proyecto__c (before insert, before update) {
    if (Trigger.isInsert || Trigger.isUpdate) {
        DuplicateChecker.preventDuplicates(Trigger.new);
    }
}