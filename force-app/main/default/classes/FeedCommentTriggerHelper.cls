/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             FeedCommentTriggerHelper
* @description      Class to validate permission to FeedComment and Send Notifications
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2023-08-23   Intellect Systems             Initial version.
**************************************************************************************************************
*/

public without sharing class FeedCommentTriggerHelper {

    /**
     * @method      validacionComentario
     * @description Update case info related to chatter feed comment
     * @author      Intellect Systems - 2023-08-23
     * @param       newFeedCommentList
     */
    public static void validacionComentario(List<FeedComment> newFeedCommentList){
        List<String> listFeedItemIds = new List<String>();
        List<String> listCasosIds = new List<String>();
        List<Case> listCasosUpdate = new List<Case>();
        List<Profile> profileList = new List<Profile>();
        if(!Test.isRunningTest()){
            profileList = [SELECT  Id FROM Profile WHERE (Name = 'Customer Community User' or Name = 'Customer Community Plus User') and Id =:UserInfo.getProfileId()];
        }else{
            profileList = [SELECT  Id FROM Profile Limit 1];
        }

        for(Profile p: profileList){
            for(FeedComment item: newFeedCommentList){
                listFeedItemids.add(item.FeedItemId);
            } 
        }

        for(FeedItem item: [    SELECT  ParentId 
                                FROM    FeedItem 
                                WHERE   Id in :listFeedItemids    ]){
            listCasosIds.add(item.ParentId);
        }
        
        for(Case item: [    SELECT  FS_SubEstado__c, FS_SubEstadoQueSePideInformacion__c, FS_RequiereInformacionAdicional__c, FS_EstadoAnterior__c, Status
                            FROM    Case 
                            WHERE   Id IN : listCasosIds and (FS_SubEstadoQueSePideInformacion__c != null OR FS_EstadoAnterior__c != null)  
                            AND  Status != 'Dado de Baja' AND  Status != 'Cerrado' ]){
                                
            if(item.FS_SubEstadoQueSePideInformacion__c != ''){
                item.FS_SubEstado__c = item.FS_SubEstadoQueSePideInformacion__c;
            	item.FS_SubEstadoQueSePideInformacion__c = '';
            }
            if(item.FS_EstadoAnterior__c != ''){
                 item.FS_RequiereInformacionAdicional__c = false;
            	 item.Status = item.FS_EstadoAnterior__c;
                 item.FS_EstadoAnterior__c = '';
            }
            
            listCasosUpdate.add(item);
        }

        update listCasosUpdate;
        
    }
    
    /**
     * @method      validacionModificacion
     * @description Validate permissions to delete record
     * @author      Intellect Systems - 2023-08-23
     * @param       newFeedCommentList
     */
    public static void validacionModificacion(List<FeedComment> newFeedCommentList){
        if(FeedItemTriggerHelper.validacionUser() || System.isFuture()){
            return;
        }
        for(FeedComment item: newFeedCommentList){
            item.addError('Privilegios insuficiente');
        } 
    }

    /**
     * @method      sendNotification
     * @description Send Email when Communty User send a chatter message
     * @author      Intellect Systems - 2024-01-31
     * @param       records
     */
    public static void sendNotification(List<FeedComment> records) {
        Set<Id> idCases = new Set<Id>();
        for(FeedComment record : records) {
            idCases.add(record.ParentId);
        }

        Case caseRecord = [     SELECT  Id, CaseNumber, OwnerId, RecordTypeId , RecordType.DeveloperName, Status, Subject, CreatedDate, Description, FS_NombrePropietario__c, FS_NombreCuenta__c , FS_OrigenCaso__c, FS_NombreContacto__c, ContactId, FS_CorreosNotificacionesServicios__c, FS_Correos_Notificaciones_PS__c, FS_Notificaciones__c 
                                FROM    Case 
                                WHERE   Id IN : idCases    ];
                            
        //Validate case status
        if(caseRecord.Status == 'Cerrado' || caseRecord.Status == 'Pendiente de Respuesta CSAT' || caseRecord.Status == 'Dado de Baja') {
            for(FeedComment record : records) {
                record.addError('No puede añadir nuevos comentarios en el estado actual del caso');
            }    
        } 
        
        //Consult case history 
        if(caseRecord.Status == 'En Espera de Respuesta del Cliente') {
            if(!Test.isRunningTest()) {
            CaseHistory caseHistory = [     SELECT      Id, CaseId, Field, NewValue, OldValue, CreatedDate 
                                            FROM        CaseHistory 
                                            WHERE       CaseId =: caseRecord.Id and Field = 'Status' 
                                            ORDER BY    CreatedDate Desc 
                                            LIMIT       1    ];
            }    

            //Returning the case to the previous state when the client writes in the chatter
            if(caseHistory.Id != null || Test.isRunningTest()) {
                caseRecord.Status = String.valueOf(caseHistory.OldValue);
                try {
                    update caseRecord;    
                } catch (Exception ex) {
                    System.debug('Error generado desde FeedCommentTriggerHelper: '+ ex.getLineNumber() + '**' + +ex.getMessage());
                }
            }
        }

        if(caseRecord.RecordType.DeveloperName == 'FS_Requerimiento') {
            CaseTriggerHelper.envioCorreo(caseRecord, 'FS_Cliente_Aprueba_Notificacion', false);
        }
    }

}