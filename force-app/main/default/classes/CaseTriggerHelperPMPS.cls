/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             CaseTriggerHelperPMPS
* @description      Class to manage new process in case called: Requerimiento.
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-22-01   Intellect Systems             Initial version.
* 2025-02-12   Intellect Systems             Add method called: updateJiraRecordPMPS.
**************************************************************************************************************
*/
public with sharing class CaseTriggerHelperPMPS {

    public static final String REQUERIMIENTO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();
    public static final String CONTROLDECAMBIO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_ControlCambios').getRecordTypeId();
    public static final String TIEMPOMATERIALES_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_TiempoMateriales').getRecordTypeId();
    public static Map<String, EmailTemplate> mapPlantillas;
    public static Map<String, EmailTemplate> mapPlantillasPMPS;
    static{
        mapPlantillas = new Map<String, EmailTemplate>();
        
        for(EmailTemplate plantilla :[Select Id, Subject, HTMLValue,DeveloperName from EmailTemplate Where DeveloperName Like '%FS_%' Limit 1]){
            mapPlantillas.put(plantilla.DeveloperName, plantilla);
        }
    }
    
    /**
     * @method      preventDeleteRecords
     * @description Method that prevent delete records, except the System Administrator
     * @author      Intellect Systems - 2024-22-01
     * @param 		records - list of cases		
     */
	public static void preventDeleteRecords(List<Case> records) {
        try {
            Id profileId=userinfo.getProfileId();
            String profileName=[Select Id,Name from Profile where Id=:profileId].Name;  
            if(profileName != 'Administrador del sistema' && profileName != 'System Administrator') {
                for(Case caseList : records) {
                    caseList.addError('Privilegios insuficiente para eliminar el caso');	    
                }	   
            }
        } catch(Exception ex) {
            System.debug('Error en CaseTriggerHelperPMPS: '+ex.getLineNumber()+'---'+ex.getMessage());
        }
    }

    /**
     * @method      preventChangeCaseValues
     * @description Method to prevent a user from changing the case information
     * @author      Intellect Systems - 2024-02-19
     * @param       records
     * @param       oldRecords
     */
    public static void preventChangeCaseValues(List<Case> records, Map<Id, Case> oldRecords) {
        List<Case> casesOld = new List<Case>();
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileName != 'Administrador del sistema' && profileName != 'System Administrator') {
            for (Case record : records) {
                Case caso = oldRecords.get(record.Id);
                if(record.ContactId != caso.ContactId) {
                    record.addError('Privilegios insuficientes, no puede editar campos del caso ingresados por el cliente.'); 
                }
                if((record.Status == 'Dado de Baja' || record.Status == 'Cerrado') && record.status == caso.Status && (record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO  || Record.RecordTypeId == CONTROLDECAMBIO_TIPO_REGISTRO) && (profileName != 'Customer Community User' ||  profileName != 'Encuestas Servicio al Cliente. Perfil') ) {
                    record.addError('Privilegios insuficientes para modificar el caso en el estado actual.');
                }
                if(record.FS_TipoRequerimiento__c != 'Master' && record.FS_TipoRequerimiento__c != caso.FS_TipoRequerimiento__c && (record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO || Record.RecordTypeId == CONTROLDECAMBIO_TIPO_REGISTRO)) {
                    record.addError('Privilegios insuficientes para modificar la calificación del caso.');    
                }
            }  
        } 
    }
    
    /**
     * @method      assignCases
     * @description Method that assign owner to record case if the recordtype is Requerimiento
     * @author      Intellect Systems - 2024-23-01
     * @param 		records - list of cases	
     */
    public static void assignCases(List<Case> records) {
        set<Id> accountId = new set<id>();
        for(Case lstCase: records) {
            accountId.add(lstCase.AccountId);   
        }

        map<String, FS_Gestor_Cuenta__c> mapRecords = new map<String, FS_Gestor_Cuenta__c>([	SELECT 	Id, FS_Project_Manager__c,FS_Project_Manager__r.Name
                                                                                                FROM 	FS_Gestor_Cuenta__c
                                                                                                WHERE 	FS_Cuenta__c IN : accountId and FS_Principal__c =: true	 ]);        

        for(Case lstCase: records) {
            if((REQUERIMIENTO_TIPO_REGISTRO == lstCase.RecordTypeId || CONTROLDECAMBIO_TIPO_REGISTRO == lstCase.RecordTypeId || TIEMPOMATERIALES_TIPO_REGISTRO == lstCase.RecordTypeId) && mapRecords.size() > 0) {	
                for(Id key : mapRecords.keySet()) {
                    lstCase.OwnerId = mapRecords.get(key).FS_Project_Manager__c; 
                }
            }    
        }
    }

    /**
     * @method      sendToJiraPMPS
     * @description Method to send case to jira
     * @author      Intellect Systems - 2024-01-30
     * @param       records     - New list of cases
     * @param       oldRecords  - Old map of cases
     */
    public static void sendToJiraPMPS(List<Case> records, Map<Id, Case> oldRecords) {
        List<Case> casesNew = new List<Case>();
        Map<Id, Case> casesOld = new Map<Id, Case>();
        for (Case record : records) {
            Case caso = oldRecords.get(record.Id);
            if(record.FS_TipoRequerimiento__c == 'Master' && record.FS_TipoRequerimiento__c != caso.FS_TipoRequerimiento__c ) {
                record.Status = 'Análisis Previo';
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.createJira(casesNew, casesOld);
            }
            
            if(record.Status == 'Análisis Previo' && record.Status != caso.Status && record.RecordTypeId == CONTROLDECAMBIO_TIPO_REGISTRO) {
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.createJira(casesNew, casesOld);
            }

            if(record.FS_TipoRequerimiento__c == 'Tiempo y Materiales' && record.FS_TipoRequerimiento__c != caso.FS_TipoRequerimiento__c && record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO) {
                record.Status = 'Propuesta de Servicio';  
                record.RecordTypeId = TIEMPOMATERIALES_TIPO_REGISTRO;
                
                /*casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.createJira(casesNew, casesOld);*/
            }
            
            if((record.FS_Aplica_Licencia_Recurrente__c == 'Si' && record.FS_Cuando_Aplica_LR__c != null && record.FS_Dias_que_Aplica_LR__c != null && record.FS_Aplica_Licencia_Recurrente__c != caso.FS_Aplica_Licencia_Recurrente__c) || (record.FS_Aplica_Licencia_Recurrente__c	== 'No' && record.FS_Aplica_Licencia_Recurrente__c != caso.FS_Aplica_Licencia_Recurrente__c)) {
                record.Status = 'En Planificación';
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.updateIssueJira(casesNew, casesOld);
            }
            if(record.FS_Acepta_Propuesta_Economica__c == 'Si' && record.FS_Acepta_Propuesta_Economica__c != caso.FS_Acepta_Propuesta_Economica__c) {
                CaseTriggerHelper.crearHistorialAprobaciones(record);
            }
            if(record.FS_Acepta_Propuesta_Economica__c == 'No' && record.FS_Acepta_Propuesta_Economica__c != caso.FS_Acepta_Propuesta_Economica__c) {
                record.Status = 'Pendiente de Respuesta CSAT';  
                record.FS_EncuestaEnviada__c = true;
                record.FS_FechaEnvioEncuesta__c = System.now();
                CaseTriggerHelper.crearHistorialAprobaciones(record);
                casesNew.add(record);
                casesOld.put(caso.Id, caso); 
                CaseTriggerHelper.crearEncuesta(record);
                CreateJiraRecord.updateIssueJira(casesNew, casesOld);
            }
            if(record.FS_AceptaRespuesta__c == 'Si' && record.Status == 'Validación de Respuesta (Cliente)' && record.FS_AceptaRespuesta__c != caso.FS_AceptaRespuesta__c) {
                CaseTriggerHelper.crearHistorialAprobaciones(record); 
                // casesNew.add(record);
                // casesOld.put(caso.Id, caso);
                // CreateJiraRecord.updateIssueJira(casesNew, casesOld); 
            }
            if(record.FS_AceptaRespuesta__c == 'No' && record.Status == 'Validación de Respuesta (Cliente)' && record.FS_AceptaRespuesta__c != caso.FS_AceptaRespuesta__c) {
                CaseTriggerHelper.crearHistorialAprobaciones(record);
                // casesNew.add(record);
                // casesOld.put(caso.Id, caso);
                //editado para no enviar doble notificacion por cambio de estado en el metodo updateJiraRecordPMPS.
                //CreateJiraRecord.updateIssueJira(casesNew, casesOld);
            }
            if(record.FS_Fecha_Puesta_en_Produccion__c != null && record.FS_Fecha_Puesta_en_Produccion__c != caso.FS_Fecha_Puesta_en_Produccion__c) {
                // casesNew.add(record);
                // casesOld.put(caso.Id, caso);
                // CreateJiraRecord.updateIssueJira(casesNew, casesOld);
            }
            if(record.FS_Quiere_Finalizar_la_Atencion_del_Caso__c == true && record.FS_Quiere_Finalizar_la_Atencion_del_Caso__c != caso.FS_Quiere_Finalizar_la_Atencion_del_Caso__c) {
                record.Status = 'Pendiente de Respuesta CSAT';  
                record.FS_EncuestaEnviada__c = true;
                record.FS_FechaEnvioEncuesta__c = System.now();
                CaseTriggerHelper.crearEncuesta(record);
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.updateIssueJira(casesNew, casesOld);
                CaseTriggerHelper.envioCorreo(record, 'FS_Encuesta', true);
                record.FS_EnviarNotificacionProduccion__c = false; 
                record.FS_Quiere_Finalizar_la_Atencion_del_Caso__c = false;
                //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                String titulo = 'EL CLIENTE APROBO EL ENVIO A PRODUCCIÓN '+record.CaseNumber;
                String descripcion = 'El caso '+ record.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                if(!Test.isRunningTest()){
                    CaseTriggerHelper.enviarNotificacion(record.OwnerId, record.Id, titulo, descripcion);
                }
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.updateIssueJira(casesNew, casesOld);
            }
            if(record.Status == 'Dado de Baja' && record.Status != caso.Status) {
                record.FS_EncuestaEnviada__c = true;
                record.FS_FechaEnvioEncuesta__c = System.now();
                CaseTriggerHelper.crearEncuesta(record);
                CaseTriggerHelper.envioCorreo(record, 'FS_Encuesta', true);
            }
        }    
    }

    /**
     * @method      updateJiraRecordPMPS
     * @description Method to update Jira Record
     * @author      Intellect Systems - 2025-02-12
     * @param       records
     * @param      oldRecords
     */
    public static void updateJiraRecordPMPS(List<Case> records, Map<Id, Case> oldRecords) {
        List<Case> casesNew = new List<Case>();
        Map<Id, Case> casesOld = new Map<Id, Case>();
        for (Case record : records) {
            Case caso = oldRecords.get(record.Id);
            if((record.Status == 'Estimación Macro' || record.Status == 'Documento de Especificación Funcional' || record.Status == 'En Propuesta Económica' || record.Status == 'En Desarrollo' || record.Status == 'Validación de Respuesta (Cliente)' || record.Status == 'En Revisión Entregado' || record.Status == 'Certificado' || record.Status == 'En Revisión Certificado' || record.Status == 'En Producción'|| record.Status == 'En Revisión en Producción' || record.Status == 'En Espera de Respuesta del Cliente' || record.Status == 'Dado de Baja' || record.Status == 'Cerrado') && record.Status != caso.Status) {
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.updateIssueJira(casesNew, casesOld);
                
            }  
        } 
    }

    /**
     * @method      sendNotification
     * @description Send notification when Notificaciones fields value change
     * @author      Intellect Systems - 2024-01-31
     * @param       records
     * @param       oldRecord
     */
    public static void sendNotification(List<Case> records, Map<Id, Case> oldRecords) {      
        Case caseNotification;
        String emailTemplateName;
        Boolean esContacto = true;
        for (Case record : records) {
            Case caso = oldRecords.get(record.Id); 
            if(record.Status == 'Estimación Macro' && record.Status != caso.Status) {
                caseNotification = record;
                emailTemplateName = 'FS_AprobacionNotificacion';
            } else if(record.Status == 'Documento de Especificación Funcional' && record.Status != caso.Status) {
                caseNotification = record;
                emailTemplateName = 'FS_AprobacionNotificacion';
            } else if(record.Status == 'En Propuesta Económica' && record.Status != caso.Status) {
                caseNotification = record;
                emailTemplateName = 'FS_AprobacionNotificacion';
            } else if(record.Status == 'En Planificación' && record.Status != caso.Status) {   
                caseNotification = record;
                emailTemplateName = 'FS_AprobacionNotificacion';
            } else if(record.Status == 'En Espera de Respuesta del Cliente' && record.Status != caso.Status) { 
                caseNotification = record;
                emailTemplateName = 'FS_AprobacionNotificacion';
                record.Status = 'En Espera de Respuesta del Cliente';
            } else if(record.Status == 'En Propuesta Económica' && record.FS_Acepta_Propuesta_Economica__c == 'Si' && record.FS_Acepta_Propuesta_Economica__c != caso.FS_Acepta_Propuesta_Economica__c) {
                caseNotification = record;
                emailTemplateName = 'FS_Cliente_Acepta_Propuesta_Economica';
                esContacto = false;
            } else if(record.Status == 'Validación de Respuesta (Cliente)' && record.Status != caso.Status) {
                caseNotification = record;
                emailTemplateName = 'FS_Notificacion_Estado_Entregado';
                String descripcion = 'Estimado cliente '+record.FS_NombreContacto__c+'\n\n\nSe ha realizado la entrega de la solución al caso '+record.CaseNumber+', la cual se puede descargar en la herramienta Azure Explorer en el siguiente directorio '+record.FS_URLParcheCliente__c +'\n\nLe recordamos que tiene 15 días para descargar el parche.\n\nGracias\nProfessional Services Team';
                insert new FeedItem(ParentId = record.Id, Body = descripcion, Visibility = 'AllUsers');
            } else if(record.Status == 'Cerrado' && record.FS_FechaContestacionEncuesta__c != null && record.FS_FechaContestacionEncuesta__c != caso.FS_FechaContestacionEncuesta__c) {
                caseNotification = record;
                emailTemplateName = 'FS_Cliente_Contesto_Encuesta';
                esContacto = false;
            }
			
            if(caseNotification != null && !Test.isRunningTest()) {
                CaseTriggerHelper.envioCorreo(record, emailTemplateName, esContacto);    
            }
        }      
    }

    /**
     * @method      actualizacionDescripcion
     * @description Method to create record in Object Historial Descripción Caso
     * @author      Intellect Systems - 2024-02-16
     * @param       newCaseList
     * @param       oldCaseMap
     */
    public static void actualizacionDescripcion(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_DescripcionCliente__c != item.FS_DescripcionCliente__c){
                CaseTriggerHelper.crearHistorialDescripcion(item, caso.FS_DescripcionCliente__c, item.FS_DescripcionCliente__c);
            }
        }
    }
    
    /**
     * @method      informacionCompleta
     * @description method of sending notification for missing customer information
     * @author      Intellect Systems - 2024-02-16
     * @param       newCaseList
     * @param       oldCaseMap
     */
    
    public static void informacionCompleta(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<String> listAccount = new  List<String>();
        List<String> listProductos = new  List<String>();
        List<User> ltsUser = new  List<User>();
        Set<Id> ContactIdSt = new Set<Id>();
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            //ContactIdSt.add(item.ContactId);

            if(String.isBlank(item.FS_SubModulo__c)) {
                listAccount.add(item.AccountId);
            }
        }
        
        /*ltsUser = [select id, username from user where ContactId =:ContactIdSt];
        String UserId;
        for(User u: ltsUser){
            UserId = u.Id;
        }*/

        for(FS_ProductoAdquirido__c item: [ SELECT  FS_Cuenta__c, FS_Producto__c, FS_Modulo__c, FS_SubModulo__c 
                                            FROM    FS_ProductoAdquirido__c 
                                            WHERE   FS_Cuenta__c = :listAccount ]) {

            String prod = item.FS_Cuenta__c  + item.FS_Producto__c + item.FS_Modulo__c + item.FS_SubModulo__c;
            listProductos.add(prod);
        }

        for(Case item: newCaseList) {
            Case caso = oldCaseMap.get(item.Id);

            if(caso.FS_RequiereInformacionAdicional__c != item.FS_RequiereInformacionAdicional__c) {
                if(item.FS_RequiereInformacionAdicional__c == false) {
                    /*String prod = item.AccountId  + item.FS_Producto__c + item.FS_Modulo__c + item.FS_SubModulo__c;
                    String msjError = 'Debe Completar los siguientes campos: ';
                    msjError += String.isBlank(item.FS_SubModulo__c) && !listProductos.contains(prod) ? 'Sub Módulo, ' : '';
                    
                    if(msjError.length() > 38) {
                        item.addError(msjError.substring(0, msjError.length() - 2));
                    }*/
                    
                } else if(item.FS_RequiereInformacionAdicional__c == true && item.Status != 'Pendiente de Respuesta CSAT' && item.Status != 'Cerrado' && item.Status != 'Dado de Baja') {
                    CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'FS_NotificacionServicio'];
                    User CommunityUser = new User();
                     if(!Test.isRunningTest()){
                         	 CommunityUser = [SELECT Id, username FROM user WHERE ContactId =:item.ContactId];
                     }else{
                         	 CommunityUser = [SELECT Id, username FROM user WHERE Id =: UserInfo.getUserId()];
                     }
                    
                    item.FS_EstadoAnterior__c = caso.Status;
                    item.status = 'En Espera de Respuesta del Cliente';
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Informacion Adicional');
                    customNotificationObj.setTitle('Requerimos tu ayuda con información adicional del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(CommunityUser.Id);
                    customNotificationObj.setTargetId(item.Id);
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_InformacionFaltante', true);
                        customNotificationObj.send(new Set<String> {CommunityUser.Id});
                    }
                    
                }else if(item.FS_RequiereInformacionAdicional__c == true && (item.Status == 'Pendiente de Respuesta CSAT' || item.Status == 'Cerrado' || item.Status == 'Dado de Baja')){
                    String msjError = 'No se puede solicitar informacion adicional en este estado';
                    item.addError(msjError.substring(0, msjError.length()));
                }
            }
        }
    }

    public static void aceptaRespuesta(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'FS_NotificacionServicio'];
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AceptaAnalisisPrevio__c != item.FS_AceptaAnalisisPrevio__c && item.FS_AceptaAnalisisPrevio__c != null){
                CaseTriggerHelper.crearHistorialAprobaciones(item);
                Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                if(item.FS_AceptaAnalisisPrevio__c == 'Si' && item.Status == 'Análisis Previo'){
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.Status = 'Estimación Macro';
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_EnvioNotificacion__c = false;
                    item.FS_FechaAprobacionCliente__c = date.valueOf(item.LastModifiedDate);
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    customNotificationObj.setBody('El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento');
                    customNotificationObj.setTitle('EL CLIENTE APROBO EL ANALISIS PREVIO '+item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.OwnerId);
                    customNotificationObj.setTargetId(item.Id);

                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_PMClienteAceptaAnalisisPrevio', false);
                        customNotificationObj.send(new Set<String> {item.OwnerId});
                    }                    
                }else if(item.FS_AceptaAnalisisPrevio__c == 'No'){
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.Status = 'Dado de Baja';
                    item.FS_EnvioNotificacion__c = false;
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
                    item.FS_FechaCompromisoEntrega__c = null;
                    item.FS_MotivoCambioFechaEntrega__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_EncuestaEnviada__c = true;
                    item.FS_FechaEnvioEncuesta__c = System.now();
                    CaseTriggerHelper.crearEncuesta(item);
                    customNotificationObj.setBody('El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento');
                    customNotificationObj.setTitle('EL CLIENTE RECHAZO EL ANALISIS PREVIO '+item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.OwnerId);
                    customNotificationObj.setTargetId(item.Id);

                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.OwnerId});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PMClienteRechazaAnalisisPrevio', false);
                        CaseTriggerHelper.envioCorreo(item, 'FS_Encuesta', true);
                    }
                }
            }
            
            if(caso.FS_AceptaEstimacionMacro__c != item.FS_AceptaEstimacionMacro__c && item.FS_AceptaEstimacionMacro__c != null){
                CaseTriggerHelper.crearHistorialAprobaciones(item);
                Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                if(item.FS_AceptaEstimacionMacro__c == 'Si' && item.Status == 'Estimación Macro'){
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.Status = 'Documento de Especificación Funcional';
                    item.FS_EnvioNotificacionEM__c = false;
                    item.FS_FechaAprobacionClienteEM__c = date.valueOf(item.LastModifiedDate);
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    customNotificationObj.setBody('El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento');
                    customNotificationObj.setTitle('EL CLIENTE APROBO LA ESTIMACION MACRO '+item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.OwnerId);
                    customNotificationObj.setTargetId(item.Id);

                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_PMClienteAceptaAprobacionEstimacioMacro', false);
                        customNotificationObj.send(new Set<String> {item.OwnerId});
                    }

                }else if(item.FS_AceptaEstimacionMacro__c == 'No'){
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.Status = 'Dado de Baja';
                    item.FS_EnvioNotificacionEM__c = false;
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
                    item.FS_FechaCompromisoEntrega__c = null;
                    item.FS_MotivoCambioFechaEntrega__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_FechaAprobacionClienteEM__c = date.valueOf(item.LastModifiedDate);
                    item.FS_EncuestaEnviada__c = true;
                    item.FS_FechaEnvioEncuesta__c = System.now();
                    CaseTriggerHelper.crearEncuesta(item);
                    customNotificationObj.setBody('El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento');
                    customNotificationObj.setTitle('EL CLIENTE RECHAZO LA ESTIMACION MACRO '+item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.OwnerId);
                    customNotificationObj.setTargetId(item.Id);

                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.OwnerId});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PMClienteRechazaEstimacionMacro', false);
                        CaseTriggerHelper.envioCorreo(item, 'FS_Encuesta', true);
                    }
                }
            }
            
            if(caso.FS_AceptaDEF__c != item.FS_AceptaDEF__c && item.FS_AceptaDEF__c != null){
                CaseTriggerHelper.crearHistorialAprobaciones(item);
                Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                if(item.FS_AceptaDEF__c == 'Si' && item.Status == 'Documento de Especificación Funcional'){
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.Status = 'En Propuesta Económica';
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_EnvioNotificacionDEF__c = false;
                    item.FS_FechaAprobacionClienteDEF__c = date.valueOf(item.LastModifiedDate);                
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    customNotificationObj.setBody('El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento');
                    customNotificationObj.setTitle('EL CLIENTE APROBO EL DOCUMENTO DE ESPECIFICACIÓN FUNCIONAL '+item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.OwnerId);
                    customNotificationObj.setTargetId(item.Id);
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_PMClienteAceptaAprobacionDefinicionEspecificacionFuncionalDEF', false);
                        customNotificationObj.send(new Set<String> {item.OwnerId});
                    }
                }else if(item.FS_AceptaDEF__c == 'No'){
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.Status = 'Dado de Baja';
                    item.FS_EnvioNotificacionDEF__c = false;
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
                    item.FS_FechaCompromisoEntrega__c = null;
                    item.FS_MotivoCambioFechaEntrega__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_FechaAprobacionClienteDEF__c = date.valueOf(item.LastModifiedDate);
                    item.FS_EncuestaEnviada__c = true;
                    item.FS_FechaEnvioEncuesta__c = System.now();
                    CaseTriggerHelper.crearEncuesta(item);
                    customNotificationObj.setBody('El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento');
                    customNotificationObj.setTitle('EL CLIENTE RECHAZO EL DOCUMENTO DE ESPECIFICACIÓN FUNCIONAL '+item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.OwnerId);
                    customNotificationObj.setTargetId(item.Id);

                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.OwnerId});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PMClienteRechazaDefinicionEspecificacionFuncionalDEF', false);
                        CaseTriggerHelper.envioCorreo(item, 'FS_Encuesta', true);
                    }
                }
            }
            
            if(caso.FS_Aplica_Licencia_Recurrente__c != item.FS_Aplica_Licencia_Recurrente__c && item.FS_Aplica_Licencia_Recurrente__c != null ){
                if(item.FS_Acepta_Propuesta_Economica__c == 'Si' && item.Status == 'En Propuesta Económica' && item.FS_Aplica_Licencia_Recurrente__c != null && UserInfo.getUserType() != 'Guest'){
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.FS_DiasProyecto__c = null;
                    item.Status = 'En Planificación';
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_EnvioNotificacionPE__c = false;
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL Caso se encuentra en Planificacion '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }
            }
            
            if(caso.FS_Acepta_Propuesta_Economica__c != item.FS_Acepta_Propuesta_Economica__c && item.FS_Acepta_Propuesta_Economica__c != null) {
                Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                if(item.FS_Acepta_Propuesta_Economica__c == 'Si' && item.Status == 'En Propuesta Económica' && UserInfo.getUserType() != 'Guest'){ 
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.FS_EnvioNotificacionPE__c = false;
                    item.FS_FechaAprobacionClientePE__c = date.valueOf(item.LastModifiedDate);
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    customNotificationObj.setBody('El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento');
                    customNotificationObj.setTitle('EL CLIENTE APROBO LA PROPUESTA ECONÓMICA '+item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.OwnerId);
                    customNotificationObj.setTargetId(item.Id);
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_PMClienteAceptaAprobacionPropuestaEconomica', false);
                        customNotificationObj.send(new Set<String> {item.OwnerId});
                    }
                }else if(item.FS_Acepta_Propuesta_Economica__c == 'No'){
                    item.Status = 'Dado de Baja';
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.FS_EnvioNotificacionPE__c = false;
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
                    item.FS_FechaCompromisoEntrega__c = null;
                    item.FS_MotivoCambioFechaEntrega__c = null;
                    item.FS_FechaAprobacionClientePE__c = date.valueOf(item.LastModifiedDate);
                    item.FS_EncuestaEnviada__c = true;
                    item.FS_FechaEnvioEncuesta__c = System.now();
                    CaseTriggerHelper.crearEncuesta(item);
                    customNotificationObj.setBody('El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento');
                    customNotificationObj.setTitle('EL CLIENTE RECHAZO LA PROPUESTA ECONÓMICA '+item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.OwnerId);
                    customNotificationObj.setTargetId(item.Id);
                    
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.OwnerId});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PMClienteRechazaPropuestaEconomica', false);
                        CaseTriggerHelper.envioCorreo(item, 'FS_Encuesta', true);
                    }
                }
            }
            
            if(caso.FS_AceptaRespuesta__c != item.FS_AceptaRespuesta__c && item.FS_AceptaRespuesta__c != null){
                if(item.FS_AceptaRespuesta__c == 'Si' && (item.Status == 'Validación de Respuesta (Cliente)' || item.Status == 'En Revisión Entregado')){ 
                    item.Status = 'Certificado'; 
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_EnviarNotificacionEntregado__c = false;
                    item.FS_EnviarNotificacionCertificado__c = true;
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_DiasProyecto__c = null;
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL CLIENTE APROBO LA VALIDACION DEL PARCHE '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }else if(item.FS_AceptaRespuesta__c == 'No' && (item.Status == 'Validación de Respuesta (Cliente)' || item.Status == 'En Revisión Entregado')){
                    item.Status = 'En Revisión Entregado';
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.FS_EnviarNotificacionEntregado__c = false;
                    String titulo = 'RECHAZO DEL CLIENTE PARA EL CASO NÚMERO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }
            }
        
            if(caso.FS_AceptaSolucionEnProduccion__c != item.FS_AceptaSolucionEnProduccion__c && item.FS_AceptaSolucionEnProduccion__c != null){
                CaseTriggerHelper.crearHistorialAprobaciones(item);
                if(item.FS_AceptaSolucionEnProduccion__c == 'Si' && (item.Status == 'Certificado' || item.Status == 'En Revisión Certificado')){ 
                    item.FS_EnviarNotificacionCertificado__c = false;
                    item.Status = 'En Producción';
                    item.FS_EnviarNotificacionProduccion__c = true;
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL CLIENTE APROBO LA CERTIFICACION '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }else if(item.FS_AceptaSolucionEnProduccion__c == 'No'){
                    item.FS_AceptaSolucionEnProduccion__c = '';
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.Status = 'En Revisión Certificado';
                    item.FS_EnviarNotificacionCertificado__c = false;
                    String titulo = 'RECHAZO DEL CLIENTE PARA EL CASO NÚMERO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }
            }
            
            if(caso.FS_AceptacionSolucionSalesforce__c != item.FS_AceptacionSolucionSalesforce__c && item.FS_AceptacionSolucionSalesforce__c != null){
                CaseTriggerHelper.crearHistorialAprobaciones(item);
                if(item.FS_AceptacionSolucionSalesforce__c == 'Si' && (item.Status == 'En Producción' || item.Status == 'En Revisión en Producción') ){ 
                    item.FS_EnviarNotificacionProduccion__c = false;
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.Status = 'Pendiente de Respuesta CSAT';  
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL CLIENTE APROBO EL ENVIO A PRODUCCIÓN '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }else if(item.FS_AceptacionSolucionSalesforce__c == 'No'){
                    item.FS_AceptacionSolucionSalesforce__c = '';
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    item.FS_MotivoRechazo__c = '';
                    item.Status = 'En Revisión en Producción';
                    item.FS_EnviarNotificacionProduccion__c = false;
                    String titulo = 'RECHAZO DEL CLIENTE PARA EL CASO NÚMERO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }
            }
        }
    }
    
    public static void envioNotificacionComunidad(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'FS_NotificacionServicio'];
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_EnvioNotificacion__c != item.FS_EnvioNotificacion__c && item.FS_EnvioNotificacion__c != null){
                if(item.FS_EnvioNotificacion__c == true && item.Status == 'Análisis Previo'){
                    User CommunityUser = [SELECT Id, username FROM user WHERE ContactId =:item.ContactId];
                    item.FS_FechaEntregaAnalisisPrevio__c = date.valueOf(item.LastModifiedDate);
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de Analisis Previo');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(CommunityUser.Id);
                    customNotificationObj.setTargetId(item.Id);
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {CommunityUser.Id});
                    }
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacionAnalisisPrevio', true);
                    }
                }
            }
            
            if(caso.FS_EnvioNotificacionEM__c != item.FS_EnvioNotificacionEM__c && item.FS_EnvioNotificacionEM__c != null){
                if(item.FS_EnvioNotificacionEM__c == true && item.Status == 'Estimación Macro'){
                    User CommunityUser = [SELECT Id, username FROM user WHERE ContactId =:item.ContactId];
                    item.FS_FechaEntregaEstimacionMacro__c = date.valueOf(item.LastModifiedDate);
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de Estimación Macro');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(CommunityUser.Id);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {CommunityUser.Id});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacionEstimacionMacro', true);
                    }
                }
            }
            
            if(caso.FS_EnvioNotificacionDEF__c != item.FS_EnvioNotificacionDEF__c && item.FS_EnvioNotificacionDEF__c != null){
                if(item.FS_EnvioNotificacionDEF__c == true && item.Status == 'Documento de Especificación Funcional'){
                    User CommunityUser = [SELECT Id, username FROM user WHERE ContactId =:item.ContactId];
                    item.FS_FechaEntregaDEF__c = date.valueOf(item.LastModifiedDate);
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de Documento de Especificación Funcional');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(CommunityUser.Id);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {CommunityUser.Id});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacionDEF', true);
                    }
                }
            }
            
            if(caso.FS_EnvioNotificacionPE__c != item.FS_EnvioNotificacionPE__c && item.FS_EnvioNotificacionPE__c != null){
                if(item.FS_EnvioNotificacionPE__c == true && item.Status == 'En Propuesta Económica'){
                    User CommunityUser = [SELECT Id, username FROM user WHERE ContactId =:item.ContactId];
                    item.FS_FechaEntregaPropuestaEconomica__c = date.valueOf(item.LastModifiedDate);
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de la Propuesta Económica');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(CommunityUser.Id);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {CommunityUser.Id});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacionPropuestaEconomica', true);
                    }
                }
                
            }

            if(caso.Status != item.Status && (item.Status == 'Validación de Respuesta (Cliente)')){
                //estado igual a 'Entregado'
                item.FS_EnviarNotificacionEntregado__c = true;
            }
            
            if(caso.FS_URLParcheCliente__c != item.FS_URLParcheCliente__c && (item.Status == 'En Revisión Entregado')){
                //estado igual a 'Entregado'
                item.FS_EnviarNotificacionEntregado__c = true;
            }
            
            

            if(caso.FS_EnviarNotificacionEntregado__c != item.FS_EnviarNotificacionEntregado__c && item.FS_EnviarNotificacionEntregado__c != null){
                //estado igual a 'entregado'
                if(item.FS_EnviarNotificacionEntregado__c == true && (item.Status == 'Validación de Respuesta (Cliente)' || item.Status == 'En Revisión Entregado')){
                    //item.FS_Fecha_Entrega_Cliente__c = date.valueOf(item.LastModifiedDate);
                    item.FS_Fecha_Entrega_Cliente__c = System.now();
                    User CommunityUser = [SELECT Id, username FROM user WHERE ContactId =:item.ContactId];
                    item.FS_AceptaRespuesta__c = '';
                    item.FS_Tipo_de_Aprobacion__c = '';
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion del parche');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(CommunityUser.Id);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {CommunityUser.Id});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacion_estado', true);
                    }
                }
            }

            if(caso.FS_EnviarNotificacionCertificado__c != item.FS_EnviarNotificacionCertificado__c && item.FS_EnviarNotificacionCertificado__c != null){
                if(item.FS_EnviarNotificacionCertificado__c == true && (item.Status == 'Certificado' || item.Status == 'En Revisión Certificado')){
                    User CommunityUser = [SELECT Id, username FROM user WHERE ContactId =:item.ContactId];
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de Certificado');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(CommunityUser.Id);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {CommunityUser.Id});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacion_estado', true);
                    }
                }
            }

            if(caso.FS_EnviarNotificacionProduccion__c != item.FS_EnviarNotificacionProduccion__c && item.FS_EnviarNotificacionProduccion__c != null){
                if(item.FS_EnviarNotificacionProduccion__c == true && (item.Status == 'En Producción' || item.Status == 'En Revisión en Producción')){
                    User CommunityUser = [SELECT Id, username FROM user WHERE ContactId =:item.ContactId];
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion en Produccion');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(CommunityUser.Id);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {CommunityUser.Id});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacion_estado', true);
                    }
                }
            }
        }
    }
    
    public static void envioNotificacionFinanzas(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        system.debug('llego a finanzas');
        
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            system.debug('estado en finanzas: '+ item.Status);
            if((caso.Status != item.Status && ( item.Status == 'Dado de Baja' || item.Status == 'En Planificación')) || (caso.FS_AceptaAnalisisPrevio__c != item.FS_AceptaAnalisisPrevio__c && item.FS_AceptaAnalisisPrevio__c == 'No') ||
                (caso.FS_Acepta_Propuesta_Economica__c != item.FS_Acepta_Propuesta_Economica__c && item.FS_Acepta_Propuesta_Economica__c == 'No') || (caso.FS_AceptaEstimacionMacro__c != item.FS_AceptaEstimacionMacro__c && item.FS_AceptaEstimacionMacro__c == 'No') || 
                (caso.FS_AceptaDEF__c != item.FS_AceptaDEF__c && item.FS_AceptaDEF__c == 'No')){
                system.debug('entro en dado de baja');
                String titulo;
                String Plantilla = 'FS_PMNotificacionCobroClienteNoAcepta';
                decimal contadorDias;
                decimal Total ;

                if(item.Status == 'Dado de Baja'){
                    titulo = 'RECHAZO DEL CLIENTE PARA EL CASO NÚMERO '+item.CaseNumber;
                }else{
                    titulo = 'El Cliente Aprobo la Propuesta economica del Caso Numero: '+item.CaseNumber;
                }

                String descripcion = 'El caso '+ item.CaseNumber+ ' para el cliente '+ item.FS_NombreContacto__c +  ' ha cambiado de estado, por favor dar seguimiento. \n \n';

                if(item.FS_AceptaAnalisisPrevio__c == 'Si' && item.FS_Buscar_Proyecto__r.FS_Es_Pre_contratado__c == false){
                    descripcion = descripcion + 'El Cliente acepto el Analisis Previo con la cantidad de Dias: '+ item.FS_DiasAprobacionAnalisisPrevio__c + 
                    ', mas la Tarifa: ' + item.FS_Tarifa_Dias_Hombre__c + ' y el total USD: ' + item.FS_TotalUSDAnalisisPrevio__c + ' \n' ;
                }

                if(item.FS_AceptaEstimacionMacro__c == 'Si' && item.FS_Buscar_Proyecto2__r.FS_Es_Pre_contratado__c == false){
                    descripcion = descripcion + 'El Cliente acepto la Estimacion Macro con la cantidad de Dias: ' + item.FS_DiasAprobacionEstimacionMacro__c +
                    ', mas la Tarifa: ' + item.FS_Tarifa_Dias_Hombre2__c + ' y el total USD: ' + item.FS_TotalUSDEstimacionMacro__c + ' \n' ;
                } else if(item.FS_AceptaEstimacionMacro__c == 'No' && item.FS_Buscar_Proyecto2__r.FS_Es_Pre_contratado__c == false){
                    descripcion = descripcion + 'El Cliente rechazo la Estimacion Macro, la cantidad de Dias DEF fueron: ' + item.FS_DiasDEF__c + 
                    ', la tarifa es la siguiente: ' + + item.FS_Tarifa_Dias_Hombre2__c + ' \n' ;
                }

                if(item.FS_Acepta_Propuesta_Economica__c == 'Si' && item.FS_Buscar_Proyecto4__r.FS_Es_Pre_contratado__c == false){
                    descripcion = descripcion + 'El Cliente acepto la Propuesta Economica con la cantidad de Dias: ' + item.FS_DiasAprobacionPropuestaEconomica__c +
                    ', mas la Tarifa: ' + item.FS_Tarifa_Dias_Hombre4__c + ' y el total USD: ' + item.FS_TotalUSDPropuestaEconomicaF__c + 
                    ', \nAplica Licencia Recurrente: ' + item.FS_Aplica_Licencia_Recurrente__c + ', Cuándo Aplica LR: ' + item.FS_Cuando_Aplica_LR__c + 
                    ', Días que Aplica LR: ' + item.FS_Dias_que_Aplica_LR__c + ' \n' ;
                    Plantilla = 'FS_PMNotificacionCobroCliente';
                }

                //envio de correo Finanzas
                String correo = System.Label.FS_CorreoFinanzas;
                //CaseTriggerHelper.envioCorreo(item, Plantilla, true);
                enviarCorreoSimple(correo, Plantilla, caso.Id, item);
            } 
        }
    }
    
    /**
     * @method      enviarCorreoSimple
     * @description Method to send email
     * @author      Intellect Systems - 2024-12-19
     * @param       address
     * @param       subject
     * @param       descripcion
     * @param       recordId
     */

    public static void enviarCorreoSimple(String address, String nombrePlantilla, String recordId, Case caso) {
        OrgWideEmailAddress owea = [select Id from OrgWideEmailAddress where Address = :Label.FS_CorreoElectronicoServicio];
        system.debug('envio en dado de baja');
        
        mapPlantillasPMPS = new Map<String, EmailTemplate>();
        
        for(EmailTemplate plantilla :[Select Id, Subject, HTMLValue,DeveloperName from EmailTemplate Where DeveloperName = :nombrePlantilla Limit 1]){
            mapPlantillasPMPS.put(plantilla.DeveloperName, plantilla);
        }

        // Create an email message object
        EmailTemplate plantilla = mapPlantillasPMPS.get(nombrePlantilla);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String asunnto = CaseTriggerHelper.reemplazarCampos(caso, plantilla.Subject, 'Case');
        String html = CaseTriggerHelper.reemplazarCampos(caso, plantilla.HTMLValue, 'Case');
        String urlLogo = CaseTriggerHelper.getLogoImagen();
        html = CaseTriggerHelper.getLogoImagen() + html.replace('{urlSiteServicios}', Label.FS_UrlPortalServicios);
        html = html.replace('{urlSiteEncuestas}', Label.FS_UrlPortalEncuestas);
        html = html.replace('{urlSalesforceOrg}', Label.FS_urlSalesforceOrg);
        html = html.replace(']]>', '') + '</td><td style="width: 25%;" /></table></body></html>';
        html = html.replace('<![CDATA[', '');
        mail.setSubject(asunnto);
        mail.setHtmlBody(html);
        String[] toAddresses = new String[] {address};
        mail.setToAddresses(toAddresses);
        //mail.setSubject(subject);
        //mail.setPlainTextBody(descripcion);
        mail.setWhatId(caso.Id);
        mail.setOrgWideEmailAddressId(owea.Id);
        mail.saveAsActivity = true;
        //mail.saveAsActivity = false;
        //mail.setTargetObjectId(caso.ContactId);
        try{
            if(!Test.isRunningTest()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }catch(Exception ex){
            System.debug(ex.getMessage()+'Error Correo Simple ----- '+ex.getLineNumber());
        }
    }

}