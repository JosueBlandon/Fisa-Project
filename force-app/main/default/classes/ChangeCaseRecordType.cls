/**
**************************************************************************************************************
* @author           Intellect Systems href=<info@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             ChangeCaseRecordType
* @description      Class to validate the record type change.
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-11-25   Intellect Systems             Initial version.
**************************************************************************************************************
*/

public with sharing class ChangeCaseRecordType {

    public static final String REQUERIMIENTO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();

    /**
     * @method      validateChangeRecordType
     * @description Method to assign new case owner if recordtype in changed
     * @author      Intellect Systems - 2024-11-25
     * @param       records
     * @param       oldRecords
     */
    public static void validateChangeRecordType(List<Case> records, Map<Id, Case> oldRecords) {
        // Get a list of records
        List<FS_Project_Jira__mdt> metadataRecords = [  SELECT  Id, FS_Tipo_de_Registro__c, FS_Sub_Tipo__c, FS_Project_Id__c, FS_Issue_Type__c
                                                        FROM    FS_Project_Jira__mdt 
                                                        WITH    SECURITY_ENFORCED  ];

        //Close Jira
        if(!records.isEmpty()) {
            CreateJiraRecord.checkCloseJira(records, oldRecords);
        }

        User usuario = [    SELECT  Contact.Account.FS_Carterizacion__c, Contact.Account.FS_ServicioRemoto__c, Contact.Account.FS_ColaAtencion__c, Contact.Account.FS_CorreosNotificacionesServicios__c, Contact.Account.FS_Correos_Notificaciones_PS__c  
                            FROM    user  
                            WHERE   Id =: userInfo.getUserId()    ];

        for(Case caso : records) { 
            Boolean esCore = CaseTriggerHelper.ProductoCore(caso);
            if(REQUERIMIENTO_TIPO_REGISTRO != caso.RecordTypeId) {
                caso.FS_Area__c = esCore ? 'N1. CORE' : 'N1. OMNIA';
            } else {
                caso.FS_Area__c = 'PS';
            }

            caso.Status = 'Nuevo';
            caso.FS_TipoIncidente__c = '';
            caso.FS_SubEstado__c = '';
            caso.FS_FechaCompromisoEntrega__c = null;
            caso.FS_RequiereInformacionAdicional__c = false;
            caso.FS_NumeroRequerimientosNuevo__c = null;

            if(REQUERIMIENTO_TIPO_REGISTRO != caso.RecordTypeId) {
                if(usuario.Contact.Account.FS_ServicioRemoto__c){
                    caso.OwnerId = [Select Id from Group Where DeveloperName = :usuario.Contact.Account.FS_ColaAtencion__c and Type = 'Queue'].Id;
                }else{
                    caso.OwnerId = [Select Id from Group Where DeveloperName = :(esCore ? CaseTriggerHelper.COLA_ATENCION_N1_CORE : CaseTriggerHelper.COLA_ATENCION_N1_OMNIA) and Type = 'Queue'].Id;
                }
            } else {                
                map<String, FS_Gestor_Cuenta__c> mapRecords = new map<String, FS_Gestor_Cuenta__c>([	SELECT 	Id, FS_Project_Manager__c  
                                                                                                        FROM 	FS_Gestor_Cuenta__c
                                                                                                        WHERE 	FS_Cuenta__c =: caso.AccountId and FS_Principal__c =: true	 ]);
                if(REQUERIMIENTO_TIPO_REGISTRO == caso.RecordTypeId && mapRecords.size() > 0) {	
                    for(Id key : mapRecords.keySet()) {
                        caso.OwnerId = mapRecords.get(key).FS_Project_Manager__c;    
                    }
                }
            }
        }
    }
}