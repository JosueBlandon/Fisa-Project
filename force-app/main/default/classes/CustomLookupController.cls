/**
**************************************************************************************************************
* @author           Intellect Systems
* @project          Fisa Ecuador - Implementación CRM
* @name             CustomLookupController
* @description      Class to assign Proyects to Cases
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-11-28   Intellect Systems             Initial version.
**************************************************************************************************************
*/

public without sharing class CustomLookupController {

    /**
     * @method      findCase
     * @description Method to find case record
     * @author      Intellect Systems - 2024-11-28
     * @param       recordId
     * @return      List<Case>
     */
    @AuraEnabled
    public static List<Case> findCase(String recordId) {
        return [
            SELECT	Id, AccountId, RecordType.Name
            FROM	Case
            WHERE	Id =: recordId
        ];
    }
    
    /**
     * @method      saveProyect
     * @description Method to assign proyects to case record
     * @author      Intellect Systems - 2024-11-28
     * @param       caseId
     * @param       projectId
     * @return      Case
     */
    @AuraEnabled
    public static Case saveProyect(String caseId, String projectId) {
        Case record = [	SELECT	Id, Status, FS_Buscar_Proyecto__c, FS_Buscar_Proyecto2__c, FS_Buscar_Proyecto3__c, FS_Buscar_Proyecto4__c
                        FROM	Case
                        WHERE	Id =: caseId 
                        LIMIT	1 ];

        if(record.Status == 'Nuevo' || record.Status == 'Análisis Previo') {
            record.FS_Buscar_Proyecto__c = projectId;
            record.FS_Buscar_Proyecto2__c = projectId;
            record.FS_Buscar_Proyecto3__c = projectId;
            record.FS_Buscar_Proyecto4__c = projectId;
        } else if(record.Status == 'Estimación Macro') {
            record.FS_Buscar_Proyecto2__c = projectId;
        } else if(record.Status == 'Documento de Especificación Funcional') {
            record.FS_Buscar_Proyecto3__c = projectId;
        } else if(record.Status == 'En Propuesta Económica') {
            record.FS_Buscar_Proyecto4__c = projectId;
        } else if(record.Status == 'Propuesta de Servicio') {
            record.FS_Buscar_Proyecto__c = projectId;
        }    

        update record;                                                             

        return record;
    }
}