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
**************************************************************************************************************
*/
public with sharing class CaseTriggerHelperPMPS {

    public static final String REQUERIMIENTO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();
    
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
                if((record.Status == 'Dado de Baja' || record.Status == 'Cerrado') && record.status == caso.Status && record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO && (profileName != 'Customer Community User' ||  profileName != 'Encuestas Servicio al Cliente. Perfil') ) {
                    record.addError('Privilegios insuficientes para modificar el caso en el estado actual.');
                }
                if(record.FS_TipoRequerimiento__c != 'Master' && record.FS_TipoRequerimiento__c != caso.FS_TipoRequerimiento__c && record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO) {
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
            if(REQUERIMIENTO_TIPO_REGISTRO == lstCase.RecordTypeId && mapRecords.size() > 0) {	
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
            if(record.FS_TipoRequerimiento__c == 'Master' && record.FS_TipoRequerimiento__c != caso.FS_TipoRequerimiento__c) {
                record.Status = 'En Análisis';
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.createJira(casesNew, casesOld);
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
                //record.Status = 'Certificado';
                CaseTriggerHelper.crearHistorialAprobaciones(record); 
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.updateIssueJira(casesNew, casesOld); 
            }
            if(record.FS_AceptaRespuesta__c == 'No' && record.Status == 'Validación de Respuesta (Cliente)' && record.FS_AceptaRespuesta__c != caso.FS_AceptaRespuesta__c) {
                //record.Status = 'En Desarrollo'; 
                CaseTriggerHelper.crearHistorialAprobaciones(record);
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.updateIssueJira(casesNew, casesOld);
            }
            if(record.FS_Fecha_Puesta_en_Produccion__c != null && record.FS_Fecha_Puesta_en_Produccion__c != caso.FS_Fecha_Puesta_en_Produccion__c) {
                //record.Status = 'En Producción';  
                CaseTriggerHelper.crearHistorialAprobaciones(record);
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.updateIssueJira(casesNew, casesOld);
            }
            if(record.FS_Quiere_Finalizar_la_Atencion_del_Caso__c == true && record.FS_Quiere_Finalizar_la_Atencion_del_Caso__c != caso.FS_Quiere_Finalizar_la_Atencion_del_Caso__c) {
                record.Status = 'Pendiente de Respuesta CSAT';  
                record.FS_EncuestaEnviada__c = true;
                record.FS_FechaEnvioEncuesta__c = System.now();
                CaseTriggerHelper.crearHistorialAprobaciones(record);
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
            } 
            if(record.Status == 'Cerrado' && record.Status != caso.Status) {
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
        
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);

            if(String.isBlank(item.FS_SubModulo__c)) {
                listAccount.add(item.AccountId);
            }
        }

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
                    String prod = item.AccountId  + item.FS_Producto__c + item.FS_Modulo__c + item.FS_SubModulo__c;
                    String msjError = 'Debe Completar los siguientes campos: ';
                    //msjError += String.isBlank(item.FS_Proyecto__c) ? 'Proyecto, ' : '';
                    msjError += String.isBlank(item.FS_SubModulo__c) && !listProductos.contains(prod) ? 'Sub Módulo, ' : '';
                    
                    if(msjError.length() > 38) {
                        item.addError(msjError.substring(0, msjError.length() - 2));
                    }
                    
                } else if(item.FS_RequiereInformacionAdicional__c == true && item.Status != 'Pendiente de Respuesta CSAT' && item.Status != 'Cerrado' && item.Status != 'Dado de Baja') {
                    CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'FS_NotificacionServicio'];
                    item.FS_EstadoAnterior__c = caso.Status;
                    item.status = 'En Espera de Respuesta del Cliente';
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Informacion Adicional');
                    customNotificationObj.setTitle('Requerimos tu ayuda con información adicional del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.CreatedById);
                    customNotificationObj.setTargetId(item.Id);
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_InformacionFaltante', true);
                        customNotificationObj.send(new Set<String> {item.CreatedById});
                    }
                    
                }else if(item.FS_RequiereInformacionAdicional__c == true && (item.Status == 'Pendiente de Respuesta CSAT' || item.Status == 'Cerrado' || item.Status == 'Dado de Baja')){
                    String msjError = 'No se puede solicitar informacion adicional en este estado';
                    item.addError(msjError.substring(0, msjError.length()));
                }
            }
        }
    }

    public static void aceptaRespuesta(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AceptaAnalisisPrevio__c != item.FS_AceptaAnalisisPrevio__c && item.FS_AceptaAnalisisPrevio__c != null){
                CaseTriggerHelper.crearHistorialAprobaciones(item);
                if(item.FS_AceptaAnalisisPrevio__c == 'Si' && item.Status == 'En Análisis'){
                    item.FS_AceptaRespuesta__c = '';
                    item.Status = 'Estimación Macro';
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_EnvioNotificacion__c = false;
                    item.FS_FechaAprobacionCliente__c = date.valueOf(item.LastModifiedDate);
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL CLIENTE APROBO EL ANALISIS PREVIO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }                    
                }else if(item.FS_AceptaAnalisisPrevio__c == 'No'){
                    item.FS_AceptaRespuesta__c = '';
                    item.Status = 'Dado de Baja';
                    item.FS_EnvioNotificacion__c = false;
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
                    item.FS_FechaCompromisoEntrega__c = null;
                    item.FS_MotivoCambioFechaEntrega__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;

                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_RechazoRespuesta', false);
                    }
                    
                    String titulo = 'RECHAZO DEL CLIENTE PARA EL CASO NÚMERO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }
            }
            
            if(caso.FS_AceptaEstimacionMacro__c != item.FS_AceptaEstimacionMacro__c && item.FS_AceptaEstimacionMacro__c != null){
                CaseTriggerHelper.crearHistorialAprobaciones(item);
                if(item.FS_AceptaEstimacionMacro__c == 'Si' && item.Status == 'Estimación Macro'){
                     item.FS_AceptaRespuesta__c = '';
                    item.Status = 'Documento de Especificación Funcional';
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_EnvioNotificacionEM__c = false;
                    item.FS_FechaAprobacionClienteEM__c = date.valueOf(item.LastModifiedDate);
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL CLIENTE APROBO LA ESTIMACION MACRO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }

                }else if(item.FS_AceptaEstimacionMacro__c == 'No'){
                    item.FS_AceptaRespuesta__c = '';
                    item.Status = 'Dado de Baja';
                    item.FS_EnvioNotificacionEM__c = false;
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
                    item.FS_FechaCompromisoEntrega__c = null;
                    item.FS_MotivoCambioFechaEntrega__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_FechaAprobacionClienteEM__c = date.valueOf(item.LastModifiedDate);

                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_RechazoRespuesta', false);
                    }
                    
                    String titulo = 'RECHAZO DEL CLIENTE PARA EL CASO NÚMERO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }
            }
            
            if(caso.FS_AceptaDEF__c != item.FS_AceptaDEF__c && item.FS_AceptaDEF__c != null){
                CaseTriggerHelper.crearHistorialAprobaciones(item);
                if(item.FS_AceptaDEF__c == 'Si' && item.Status == 'Documento de Especificación Funcional'){
                    item.FS_AceptaRespuesta__c = '';
                    item.Status = 'En Propuesta Económica';
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_EnvioNotificacionDEF__c = false;
                    item.FS_FechaAprobacionClienteDEF__c = date.valueOf(item.LastModifiedDate);                
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL CLIENTE APROBO EL DOCUMENTO DE ESPECIFICACIÓN FUNCIONAL '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }else if(item.FS_AceptaDEF__c == 'No'){
                    item.FS_AceptaRespuesta__c = '';
                    item.Status = 'Dado de Baja';
                    item.FS_EnvioNotificacionDEF__c = false;
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
                    item.FS_FechaCompromisoEntrega__c = null;
                    item.FS_MotivoCambioFechaEntrega__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_FechaAprobacionClienteDEF__c = date.valueOf(item.LastModifiedDate);

                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_RechazoRespuesta', false);
                    }
                    
                    String titulo = 'RECHAZO DEL CLIENTE PARA EL CASO NÚMERO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                    
                    
                }
            }
            
            if(caso.FS_Aplica_Licencia_Recurrente__c != item.FS_Aplica_Licencia_Recurrente__c && item.FS_Aplica_Licencia_Recurrente__c != null ){
                //CaseTriggerHelper.crearHistorialAprobaciones(item);
                if(item.FS_Acepta_Propuesta_Economica__c == 'Si' && item.Status == 'En Propuesta Económica' && item.FS_Aplica_Licencia_Recurrente__c != null && UserInfo.getUserType() != 'Guest'){
                    item.FS_AceptaRespuesta__c = '';
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
                //CaseTriggerHelper.crearHistorialAprobaciones(item);
                if(item.FS_Acepta_Propuesta_Economica__c == 'Si' && item.Status == 'En Propuesta Económica' && UserInfo.getUserType() != 'Guest'){ 
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_EnvioNotificacionPE__c = false;
                    item.FS_FechaAprobacionClientePE__c = date.valueOf(item.LastModifiedDate);
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL CLIENTE APROBO LA PROPUESTA ECONÓMICA '+item.CaseNumber;
                    String descripcion = 'Para el caso '+ item.CaseNumber+' se aprobo la propuesta económica, favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }else if(item.FS_Acepta_Propuesta_Economica__c == 'No'){
                    item.Status = 'Dado de Baja';
                    item.FS_EnvioNotificacionPE__c = false;
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
                    item.FS_FechaCompromisoEntrega__c = null;
                    item.FS_MotivoCambioFechaEntrega__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_FechaAprobacionClientePE__c = date.valueOf(item.LastModifiedDate);

                    CaseTriggerHelper.envioCorreo(item, 'FS_RechazoRespuesta', false);
                    
                    String titulo = 'RECHAZO DEL CLIENTE PARA EL CASO NÚMERO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    } 
                }
            }
            
            if(caso.FS_AceptaRespuesta__c != item.FS_AceptaRespuesta__c && item.FS_AceptaRespuesta__c != null){
                CaseTriggerHelper.crearHistorialAprobaciones(item);
                if(item.FS_AceptaRespuesta__c == 'Si' && item.Status == 'Validación de Respuesta (Cliente)'){ 
                    item.Status = 'Certificado'; 
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_FechaCertificacionCliente__c = date.valueOf(item.LastModifiedDate);
                    item.FS_EnviarNotificacionEntregado__c = false;
                    item.FS_AceptaRespuesta__c = '';
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL CLIENTE APROBO LA VALIDACION DEL PARCHE '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }else if(item.FS_AceptaRespuesta__c == 'No'){
                    item.Status = 'En Revisión Entregado';
                    item.FS_AceptaRespuesta__c = '';
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
                if(item.FS_AceptaSolucionEnProduccion__c == 'Si' && item.Status == 'Certificado'){ 
                    item.FS_EnviarNotificacionCertificado__c = false;
                    item.Status = 'En Producción';
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL CLIENTE APROBO LA CERTIFICACION '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }else if(item.FS_AceptaSolucionEnProduccion__c == 'No'){
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
                if(item.FS_AceptacionSolucionSalesforce__c == 'Si' && item.Status == 'En Producción'){ 
                    item.FS_EnviarNotificacionProduccion__c = false;
                    item.Status = 'Pendiente de Respuesta CSAT';  
                    //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    String titulo = 'EL CLIENTE APROBO EL ENVIO A PRODUCCIÓN '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    }
                }else if(item.FS_AceptacionSolucionSalesforce__c == 'No'){
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
                //CaseTriggerHelper.crearHistorialAprobaciones(item);
                if(item.FS_EnvioNotificacion__c == true && item.Status == 'En Análisis'){
                    item.FS_FechaEntregaAnalisisPrevio__c = date.valueOf(item.LastModifiedDate);
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de Analisis Previo');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.CreatedById);
                    customNotificationObj.setTargetId(item.Id);
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.CreatedById});
                    }
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacion_estado', true);
                    }
                }
            }
            
            if(caso.FS_EnvioNotificacionEM__c != item.FS_EnvioNotificacionEM__c && item.FS_EnvioNotificacionEM__c != null){
                if(item.FS_EnvioNotificacionEM__c == true && item.Status == 'Estimación Macro'){
                    item.FS_FechaEntregaEstimacionMacro__c = date.valueOf(item.LastModifiedDate);
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de Estimación Macro');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.CreatedById);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.CreatedById});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacion_estado', true);
                    }
                }
            }
            
            if(caso.FS_EnvioNotificacionDEF__c != item.FS_EnvioNotificacionDEF__c && item.FS_EnvioNotificacionDEF__c != null){
                if(item.FS_EnvioNotificacionDEF__c == true && item.Status == 'Documento de Especificación Funcional'){
                    item.FS_FechaEntregaDEF__c = date.valueOf(item.LastModifiedDate);
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de Documento de Especificación Funcional');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.CreatedById);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.CreatedById});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacion_estado', true);
                    }
                }
            }
            
            if(caso.FS_EnvioNotificacionPE__c != item.FS_EnvioNotificacionPE__c && item.FS_EnvioNotificacionPE__c != null){
                if(item.FS_EnvioNotificacionPE__c == true && item.Status == 'En Propuesta Económica'){
                    item.FS_FechaEntregaPropuestaEconomica__c = date.valueOf(item.LastModifiedDate);
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de la Propuesta Económica');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.CreatedById);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.CreatedById});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacion_estado', true);
                    }
                }
                
            }
            
            if(caso.FS_URLParcheCliente__c != item.FS_URLParcheCliente__c && item.FS_URLParcheCliente__c != null){
                //estado igual a 'entregado'
                if(item.FS_URLParcheCliente__c != null && (item.Status == 'Validación de Respuesta (Cliente)' || item.Status == 'En Revisión Entregado')){
                    item.FS_EnviarNotificacionEntregado__c = true;
                    item.status = 'Validación de Respuesta (Cliente)';
                }
            }
            
            if(caso.FS_EnviarNotificacionEntregado__c != item.FS_EnviarNotificacionEntregado__c && item.FS_EnviarNotificacionEntregado__c != null){
                //estado igual a 'entregado'
                if(item.FS_EnviarNotificacionEntregado__c == true && item.Status == 'Validación de Respuesta (Cliente)'){
                    //item.FS_Fecha_Entrega_Cliente__c = date.valueOf(item.LastModifiedDate);
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion del parche');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.CreatedById);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.CreatedById});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacion_estado', true);
                    }
                }
            }
            
            if(caso.FS_EnviarNotificacionCertificado__c != item.FS_EnviarNotificacionCertificado__c && item.FS_EnviarNotificacionCertificado__c != null){
                if(item.FS_EnviarNotificacionCertificado__c == true && item.Status == 'Certificado'){
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    item.FS_AceptaSolucionEnProduccion__c = '';
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de Certificado');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.CreatedById);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.CreatedById});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacion_estado', true);
                    }
                }
            }
            
            if(caso.FS_EnviarNotificacionProduccion__c != item.FS_EnviarNotificacionProduccion__c && item.FS_EnviarNotificacionProduccion__c != null){
                if(item.FS_EnviarNotificacionProduccion__c == true && item.Status == 'En Producción'){
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    item.FS_AceptacionSolucionSalesforce__c = '';
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion en Produccion');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.CreatedById);
                    customNotificationObj.setTargetId(item.Id);
                    //envio de correo cliente
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.CreatedById});
                        CaseTriggerHelper.envioCorreo(item, 'FS_PendienteInformacion_estado', true);
                    }
                }
            }
        }
    }
    
    public static void envioNotificacionFinanzas(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.Status != item.Status && ( item.Status == 'Dado de Baja' || item.Status == 'En Planificación') ){
                String titulo;
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
                }
                
                //envio de correo Finanzas
                String correo = System.Label.FS_CorreoFinanzas;
                enviarCorreoSimple(correo, titulo, descripcion, caso.Id);
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

    public static void enviarCorreoSimple(String address, String subject, String descripcion, String recordId) {
        OrgWideEmailAddress owea = [select Id from OrgWideEmailAddress where Address = :Label.FS_CorreoElectronicoServicio];

        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {address};
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(descripcion);
        mail.setWhatId(recordId);
        mail.setOrgWideEmailAddressId(owea.Id);
        //mail.saveAsActivity = false;
        try{
            if(!Test.isRunningTest()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }catch(Exception ex){
            System.debug(ex.getMessage()+'Error Correo Simple ----- '+ex.getLineNumber());
        }
    }
    
    /**
     * @method      enviarNotificacionCampana
     * @description Método muestra las notificaciones en la campana
     * @author      Intellect Systems - 2025-01-16
     * @param       wrapper
     */
    /*private static void enviarNotificacionCampana(wrapperNotificacion wrapper) {
        Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
        customNotificationObj.setBody(wrapper.body);
        customNotificationObj.setTitle(wrapper.title);
        customNotificationObj.setNotificationTypeId(wrapper.notification);
        customNotificationObj.setSenderId(wrapper.sender);
        customNotificationObj.setTargetId(wrapper.target);
        if(!Test.isRunningTest()){
            customNotificationObj.send(new Set<String> {wrapper.createdById});
        }
    }

    public class wrapperNotificacion {
        public String createdById { get; private set; }
        public String body { get; private set; }
        public String title { get; private set; }
        public String notification { get; private set; }
        public String sender { get; private set; }
        public String target { get; private set; }

        // Fluent methods for setting properties
        public wrapperNotificacion setCreatedById(String createdById) {
            this.createdById = createdById;
            return this;
        }

        public wrapperNotificacion setBody(String body) {
            this.body = body;
            return this;
        }

        public wrapperNotificacion setTitle(String title) {
            this.title = body;
            return this;
        }

        public wrapperNotificacion setNotification(String notification) {
            this.notification = notification;
            return this;
        }

        public wrapperNotificacion setSender(String sender) {
            this.sender = sender;
            return this;
        }

        public wrapperNotificacion setTarget(String target) {
            this.target = target;
            return this;
        }
    }*/

}