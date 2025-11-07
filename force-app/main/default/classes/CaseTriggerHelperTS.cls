/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             CaseTriggerHelperTS
* @description      Class to manage new process in case called: Tesoreria.
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2025-22-09   Intellect Systems             Initial version.
* 2025-23-09   Intellect Systems             Add method called: .
**************************************************************************************************************
*/
public class CaseTriggerHelperTS {
    
    public static Map<String, String> mapColas;
    public static Map<String, User> mapUser;
    public static OrgWideEmailAddress owea;
    public static Map<String, EmailTemplate> mapPlantillas;
    public static CustomNotificationType notificacion;
    
    static{
        mapColas = new Map<String, String>();
        mapPlantillas = new Map<String, EmailTemplate>();
        mapUser = new Map<String, User>();
        
        owea = [select Id from OrgWideEmailAddress where Address = :Label.FS_CorreoElectronicoServicio];
        notificacion = [SELECT Id FROM CUstomNotificationType Where DeveloperName = 'FS_NotificacionServicio' LIMIT 1];
        
        for(Group item: [Select Id, DeveloperName from Group Where DeveloperName Like '%FS_%' and Type = 'Queue']){
            mapColas.put(item.DeveloperName, item.Id);
        }
        for(User item: [Select Id, Email, Name, FirstName, Lastname, UserRole.DeveloperName, Profile.Name from User Where IsActive = true]){
            mapUser.put(item.Id, item);
        }
        for(EmailTemplate plantilla :[Select Id, Subject, HTMLValue,DeveloperName from EmailTemplate Where DeveloperName Like '%FS_%' limit 1]){
            mapPlantillas.put(plantilla.DeveloperName, plantilla);
        }
    }
        
    public static final String CONSULTA_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Consulta').getRecordTypeId();
    public static final String SOLICITUD_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Solicitud').getRecordTypeId();
    public static final String INCIDENTE_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Incidente').getRecordTypeId();
    public static final String REQUERIMIENTO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();
    public static final String CONTROLDECAMBIO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_ControlCambios').getRecordTypeId();

    public static void validacionEstado(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
         User u = mapUser.get(UserInfo.getUserId());
        if(validacionUser(false) && u.Profile.Name != 'Servicio al Cliente'){ 
            return;
        } 
        
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);

            if(item.Status != 'Dado de Baja' && item.Status != 'Cerrado' && item.Status != 'Propuesta de Servicio' && caso.Status != item.Status && caso.Status != 'En Espera de Respuesta del Cliente' && item.RecordTypeId == caso.RecordTypeId && item.RecordTypeId != CONTROLDECAMBIO_TIPO_REGISTRO && item.RecordTypeId != CONSULTA_TIPO_REGISTRO) {
                item.Status.addError('Privilegios insuficiente para modificar el estado del caso');
            }else if(item.Status != 'Dado de Baja' && item.Status != 'Análisis Previo' && item.Status != 'Cerrado' && caso.Status != item.Status && caso.Status != 'En Espera de Respuesta del Cliente' && item.RecordTypeId == caso.RecordTypeId && item.RecordTypeId == CONTROLDECAMBIO_TIPO_REGISTRO){
                item.Status.addError('Privilegios insuficiente para modificar el estado del caso');
            }else if(item.Status != 'Dado de Baja' && item.Status != 'Análisis Previo' && item.Status != 'Cerrado' && caso.Status != item.Status && caso.Status != 'En Espera de Respuesta del Cliente' && item.RecordTypeId == caso.RecordTypeId && item.RecordTypeId == CONSULTA_TIPO_REGISTRO && item.FS_PudeSolventarPregunta__c == caso.FS_PudeSolventarPregunta__c ){
                item.Status.addError('Privilegios insuficiente para modificar el estado del caso en consulta');
            }
        }
    }
    
    
    
    public static Boolean validacionUser(Boolean userComunity){
        User u = mapUser.get(UserInfo.getUserId());
        Boolean flagPerfil = u.Profile.Name == 'Administrador del sistema' || u.Profile.Name == 'System Administrator' || u.Profile.Name == 'Servicio al Cliente' || u.Profile.Name == 'Usuario Fisa';
        flagPerfil = flagPerfil || (u.UserRole.DeveloperName != null && u.UserRole.DeveloperName.contains('FS_Jefe'));
        flagPerfil = flagPerfil || Label.FS_IdUsuarioJira == u.Id || ((u.Profile.Name == 'Customer Community User' || u.Profile.Name == 'Customer Community Plus User') && userComunity);
        flagPerfil = flagPerfil || u.Name.contains('invitado al sitio Web');
			return flagPerfil;  
    }
    
    /**
     * @method      historialDescripcion
     * @description Methos to create desciption history changes in case
     * @author      Intellect Systems - 2025-01-26
     * @param       newCaseList
     */
    public static void historialDescripcion(List<Case> newCaseList){
        for(Case item: newCaseList){
            crearHistorialDescripcion(item, null, item.FS_DescripcionCliente__c);
        }
    }
    
       
    
    public static void changeStatus(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        Case caseNotification;
        String emailTemplateName;
        Boolean esContacto = true;
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            
            if(caso.OwnerId != item.OwnerId && caso.OwnerId.getSObjectType() == Group.SObjectType && item.Status == 'Nuevo' && item.FS_SubEstado__c == 'Apertura de caso'){
                CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'FS_NotificacionServicio'];
                Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                item.FS_SubEstado__c = 'Entrega 1a respuesta';
                
                //Envio notificacion y Correo PM - Actualizacion de estado - cliente acepta
                    customNotificationObj.setBody('Tienes Asignado un nuevo Caso, favor dar seguimiento: '+ item.CaseNumber+'');
                    customNotificationObj.setTitle('NUEVO CASO '+item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.OwnerId);
                    customNotificationObj.setTargetId(item.Id); 

                    if(!Test.isRunningTest()){
						EnviarEmailCreacionCaso.envioCorreo(item, 'FS_Creacion_de_Caso_Notificacion_al_PM', false);
                        customNotificationObj.send(new Set<String> {item.OwnerId});
                    }                    
            }
            
            if(caso.FS_EnviarAnalisisN1__c  != item.FS_EnviarAnalisisN1__c && item.FS_EnviarAnalisisN1__c == true /*&& item.RecordTypeId == CONSULTA_TIPO_REGISTRO*/){
                item.Status = 'Análisis Previo';
                item.FS_SubEstado__c = 'Análisis N1';
                //envioCorreo(item, 'FS_ValidacionInformacion', true);
            }
            
            if(caso.FS_TipoIncidente__c != item.FS_TipoIncidente__c && item.RecordTypeId == INCIDENTE_TIPO_REGISTRO && item.FS_TipoIncidente__c == 'Puntual') {
                item.Status = 'En Desarrollo';
                item.FS_SubEstado__c = 'Desarrollo Incidente Puntual';
                //item.FS_Fecha_de_entrega__c = Date.today();
            }
            
            if(caso.FS_URLEntregaSolucion__c != item.FS_URLEntregaSolucion__c && item.RecordTypeId == INCIDENTE_TIPO_REGISTRO && item.FS_URLEntregaSolucion__c != null && item.Status == 'En Desarrollo') {
                CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'FS_NotificacionServicio'];
                //User CommunityUser = [SELECT Id, username FROM user WHERE ContactId =:item.ContactId];
                item.Status = 'Validación de Respuesta (Cliente)';
                item.FS_SubEstado__c = 'Envío de respuesta';
                //item.FS_FechaEntregaDesarrollo__c = Date.today();
                item.FS_Fecha_de_entrega__c = Date.today();
                caseNotification = item;
                emailTemplateName = 'FS_EnvioRespuestaComunidadTesoreria';
                String descripcion = 'Estimado cliente '+item.FS_NombreContacto__c+'\n\n\nSe ha realizado la entrega de la solución al caso '+item.CaseNumber+', la cual se puede descargar desde el siguiente repositorio: '+item.FS_URLEntregaSolucion__c +'\n\nLe recordamos que tiene 7 días para descargar la solución.\n\nGracias\nTesorería Team';
                insert new FeedItem(ParentId = item.Id, Body = descripcion, Visibility = 'AllUsers');
                //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de Entrega');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.CreatedById);
                    customNotificationObj.setTargetId(item.Id);
                    if(!Test.isRunningTest()){
                        customNotificationObj.send(new Set<String> {item.CreatedById});
                    }
            }
            
            if(caso.FS_PudeSolventarPregunta__c != item.FS_PudeSolventarPregunta__c && item.RecordTypeId == CONSULTA_TIPO_REGISTRO) {
                CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'FS_NotificacionServicio'];
                if(item.FS_PudeSolventarPregunta__c == 'Si') {
                    item.Status = 'Validación de Respuesta (Cliente)';
                    item.FS_SubEstado__c = 'Envío de respuesta';
                    item.FS_Fecha_de_entrega__c = Date.today();
                    caseNotification = item;
                	emailTemplateName = 'FS_ValidacionResolucionTesoreria';
                	String descripcion = 'Estimado cliente '+item.FS_NombreContacto__c+'\n\n\nHemos entregado la respuesta para el caso No. '+item.CaseNumber+''/*+item.FS_URLEntregaSolucion__c*/ +'\n\nTe invitamos a validarlo y enviarnos tu confirmación en un término de 96 horas.\n\nGracias\nTesorería Team';
                	insert new FeedItem(ParentId = item.Id, Body = descripcion, Visibility = 'AllUsers');
                    //envio de notificacion campana - comunidad
                    Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                    customNotificationObj.setBody('Se envio una Solicitud para aprobacion de Entrega');
                    customNotificationObj.setTitle('Tienes una nueva Notificacion pendiente por responder del caso No. ' + item.CaseNumber);
                    customNotificationObj.setNotificationTypeId(cnType.id);
                    customNotificationObj.setSenderId(item.CreatedById);
                    customNotificationObj.setTargetId(item.Id);
                    customNotificationObj.send(new Set<String> {item.CreatedById});

                }else if(item.FS_PudeSolventarPregunta__c == 'No') {
                    
                }
            }
            
            if(caso.Status != item.Status && item.Status == 'Cerrado' && item.FS_FechaContestacionEncuesta__c != null){
                item.FS_SubEstado__c = 'Respuesta aceptada';
                
            }
            
            if(caso.FS_ResultadoEncuesta__c != item.FS_ResultadoEncuesta__c && (item.FS_ResultadoEncuestaNumero__c == '1' || item.FS_ResultadoEncuestaNumero__c == '2' || item.FS_ResultadoEncuestaNumero__c == '3' || item.FS_ResultadoEncuestaNumero__c == '4' || item.FS_ResultadoEncuestaNumero__c == '5' || item.FS_ResultadoEncuestaNumero__c == '6')){
                String Plantilla = 'FS_Cliente_Contesto_Encuesta';
                //envio de correo Finanzas
                String correo = System.Label.FS_CorreoJefeTesoreria;
                //CaseTriggerHelper.envioCorreo(item, Plantilla, true);
                enviarCorreosExternos(correo, Plantilla, caso.Id, item);
            }
            
            if(item.FS_RequiereInformacionAdicional__c == true && item.Status != 'Pendiente de Respuesta CSAT' && item.Status != 'Cerrado' && item.Status != 'Dado de Baja') {
                CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'FS_NotificacionServicio'];
                User CommunityUser = new User();
                if(!Test.isRunningTest()){
                    CommunityUser = [SELECT Id, username FROM user WHERE ContactId =:item.ContactId];
                }else{
                    CommunityUser = [SELECT Id, username FROM user WHERE Id =: UserInfo.getUserId()];
                }
                
                item.FS_EstadoAnterior__c = item.Status;
                item.FS_SubEstadoQueSePideInformacion__c = item.FS_SubEstado__c;
                item.status = 'En Espera de Respuesta del Cliente';
                item.FS_SubEstado__c = 'En Espera de Respuesta del Cliente';
                //envio de notificacion campana - comunidad
                Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                customNotificationObj.setBody('Informacion Adicional');
                customNotificationObj.setTitle('Requerimos tu ayuda con información adicional del caso No. ' + item.CaseNumber);
                customNotificationObj.setNotificationTypeId(cnType.id);
                customNotificationObj.setSenderId(CommunityUser.Id);
                customNotificationObj.setTargetId(item.Id);
                if(!Test.isRunningTest()){
                    CaseTriggerHelper.envioCorreo(item, 'FS_SolicitudInformacionCasoTesoreria', true);
                    customNotificationObj.send(new Set<String> {CommunityUser.Id});
                }
            
            }else if(item.FS_RequiereInformacionAdicional__c == true && (item.Status == 'Pendiente de Respuesta CSAT' || item.Status == 'Cerrado' || item.Status == 'Dado de Baja')){
                String msjError = 'No se puede solicitar informacion adicional en este estado';
                item.addError(msjError.substring(0, msjError.length()));
            }
            
            if(caseNotification != null && !Test.isRunningTest()) {
                CaseTriggerHelper.envioCorreo(item, emailTemplateName, esContacto);    
            }
            
        }
    }//fin metodo changeStatus
    
    /**
     * @method      sendToJiraPMPS
     * @description Method to send case to jira
     * @author      Intellect Systems - 2024-01-30
     * @param       records     - New list of cases
     * @param       oldRecords  - Old map of cases
     */
    public static void sendToJiraTS(List<Case> records, Map<Id, Case> oldRecords) {
        List<Case> casesNew = new List<Case>();
        Map<Id, Case> casesOld = new Map<Id, Case>();
        for (Case record : records) {
            Case caso = oldRecords.get(record.Id);
            /*if(record.FS_TipoRequerimiento__c == 'Master' && record.FS_TipoRequerimiento__c != caso.FS_TipoRequerimiento__c ) {
                record.Status = 'Análisis Previo';
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.createJira(casesNew, casesOld);
            }*/
            
            if(record.Status == 'En Desarrollo' && record.Status != caso.Status && record.FS_SubEstado__c == 'Desarrollo Incidente Puntual' && record.RecordTypeId == INCIDENTE_TIPO_REGISTRO) {
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.createJira(casesNew, casesOld);
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
    public static void updateJiraRecordTS(List<Case> records, Map<Id, Case> oldRecords) {
        List<Case> casesNew = new List<Case>();
        Map<Id, Case> casesOld = new Map<Id, Case>();
        for (Case record : records) {
            Case caso = oldRecords.get(record.Id);
            if((record.Status == 'En Desarrollo' || record.Status == 'Validación de Respuesta (Cliente)' || record.Status == 'En Espera de Respuesta del Cliente' || record.Status == 'Dado de Baja' || record.Status == 'Cerrado') && record.Status != caso.Status) {
                casesNew.add(record);
                casesOld.put(caso.Id, caso);
                CreateJiraRecord.updateIssueJira(casesNew, casesOld);
                
            }  
        } 
    }
        
    
    public static void actualizacionDescripcion(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_DescripcionCliente__c != item.FS_DescripcionCliente__c){
                crearHistorialDescripcion(item, caso.FS_DescripcionCliente__c, item.FS_DescripcionCliente__c);
                if(item.FS_SubEstado__c == 'En Espera de Respuesta del Cliente'){
                    item.FS_SubEstado__c = item.FS_SubEstadoQueSePideInformacion__c;
                    item.FS_SubEstadoQueSePideInformacion__c = null;
                    item.Status = 'Análisis Previo';
                    item.FS_InformacionCompleta__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;
                    CaseTriggerHelper.envioCorreo(item, 'FS_ActualizacionInformacionCliente', false);
                }
            }
        }
    }
    
    

    public static void aceptaRespuesta(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AceptaRespuesta__c != item.FS_AceptaRespuesta__c && item.FS_AceptaRespuesta__c != null){
                crearHistorialAprobaciones(item);
                if(item.FS_AceptaRespuesta__c == 'Si'){
                    item.FS_SubEstado__c = 'Pendiente Respuesta Cliente';
                    item.Status = 'Pendiente de Respuesta CSAT';
                    item.FS_EncuestaEnviada__c = true;
                    item.FS_FechaEnvioEncuesta__c = System.now();
                    CaseTriggerHelper.envioCorreo(item, 'FS_Encuesta', true);
                    crearEncuesta(item);
                }else if(item.FS_AceptaRespuesta__c == 'No'){
                    item.FS_SubEstado__c = 'Análisis N1';
                    item.Status = 'Análisis Previo';
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
                    item.FS_FechaCompromisoEntrega__c = null;
                    item.FS_MotivoCambioFechaEntrega__c = null;
                    item.FS_InformacionCompleta__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;
                    item.FS_Fecha_de_entrega__c = null;

                    CaseTriggerHelper.envioCorreo(item, 'FS_RechazoRespuesta', false);
                    
                    String titulo = 'RECHAZO DEL CLIENTE PARA EL CASO NÚMERO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    CaseTriggerHelper.enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    
                    if(item.RecordTypeId == INCIDENTE_TIPO_REGISTRO && item.FS_TipoIncidente__c == 'Puntual' ){
                        item.FS_SubEstado__c = 'Desarrollo Incidente Puntual';
                        item.Status = 'En Desarrollo';
                    }else if (item.RecordTypeId == INCIDENTE_TIPO_REGISTRO && item.FS_TipoIncidente__c == 'Definitivo'){
                        item.FS_SubEstado__c = 'Elaboración Diseño Técnico';
                        item.Status = 'En Desarrollo';
                    }
                }
            }
        }
    }
    


    public static void mapeoFechaEstado(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(item.Status != caso.Status){
                item.FS_FechaEstadoActual__c = System.now();
            }
            if(item.FS_SubEstado__c != caso.FS_SubEstado__c){
                item.FS_FechaSubEstadoActual__c = System.now();
            }
        }
    }

    

    public static void crearHistorialAprobaciones(Case caso){
        FS_AceptacionRechazoCaso__c aceptacion = new FS_AceptacionRechazoCaso__c ();
        aceptacion.FS_Caso__c = caso.Id;
        aceptacion.FS_Cliente__c = caso.AccountId;
        if(caso.FS_AceptaRespuesta__c == 'Si'){
            aceptacion.FS_Tipo__c = 'Aceptación';
        }else if(caso.FS_AceptaRespuesta__c == 'No'){
            aceptacion.FS_Tipo__c = 'Rechazo';
        }
        //aceptacion.FS_Tipo__c = caso.FS_AceptaRespuesta__c == 'Si' ? 'Aceptación' : 'Rechazo';
        if(caso.Status == 'En Propuesta Económica'){
            aceptacion.FS_Tipo__c = caso.FS_Acepta_Propuesta_Economica__c == 'Si' ? 'Aceptación' : aceptacion.FS_Tipo__c;
        }
        aceptacion.FS_MotivoRechazo__c = caso.FS_MotivoRechazo__c;
        aceptacion.FS_Comentarios__c = caso.FS_ComentariosRespuesta__c;
        aceptacion.FS_Horas__c = caso.FS_NumeroHorasSolicitud__c;
        aceptacion.FS_DiasProyecto__c = caso.FS_DiasProyecto__c;
        aceptacion.FS_Tipo_de_Aprobacion__c = caso.FS_Tipo_de_Aprobacion__c;
        aceptacion.FS_Fecha_de_Pase_Produccion__c = caso.FS_Fecha_Puesta_en_Produccion__c;

        insert aceptacion;
    }

    public static void crearHistorialDescripcion(Case caso, String valorOriginal, String valorNuevo){
        FS_HistorialDescripcionCaso__c historial = new FS_HistorialDescripcionCaso__c  ();
        historial.FS_Caso__c = caso.Id;
        historial.FS_ValorOriginal__c = valorOriginal;
        historial.FS_ValorNuevo__c = valorNuevo;
        insert historial;
    }

    public static void crearEncuesta(Case caso){
        FS_Encuesta__c encuesta = new FS_Encuesta__c (FS_Caso__c = Caso.Id, FS_CreadoPor__c = UserInfo.getUserId());
        insert encuesta;
    }

    
    public static Boolean productoTesoreria(Case caso){
        
        Set<String> ProductoCase = new Set<String>();
        Set<String> ModuloCase = new Set<String>();
        Set<String> SubModuloCase = new Set<String>();
        Set<String> accCase = new Set<String>();
  
        ProductoCase.add(caso.FS_Producto__c);
        ModuloCase.add(caso.FS_Modulo__c);
        SubModuloCase.add(caso.FS_SubModuloCatalogo__c);
        accCase.add(caso.AccountId);

        
        List<FS_ProductoAdquirido__c> ltsProductosAdq = [     SELECT  FS_Cuenta__c, FS_Producto__c, FS_Modulo__c, FS_SubModuloCatalogo__c, FS_Esta_activo__c 
                                                            FROM    FS_ProductoAdquirido__c 
                                                            WHERE   FS_Cuenta__c IN: accCase AND FS_Producto__c IN: ProductoCase AND FS_Modulo__c IN: ModuloCase
                                                            /*AND     FS_SubModuloCatalogo__c IN: SubModuloCase  */AND FS_ProductoTesoreria__c = true limit 1]; 
        
        Map<String, FS_ProductoAdquirido__c> productoMap = new Map<String, FS_ProductoAdquirido__c>();
        for (FS_ProductoAdquirido__c pa : ltsProductosAdq) {
            //
            String key = pa.FS_Cuenta__c + '-' + pa.FS_Producto__c + '-' + pa.FS_Modulo__c; //+ '-' + pa.FS_SubModuloCatalogo__c;
            productoMap.put(key, pa);
        }
        
        String key = caso.AccountId + '-' + caso.FS_Producto__c + '-' + caso.FS_Modulo__c; //+ '-' + caso.FS_SubModuloCatalogo__c;
        
        if(productoMap.containsKey(key)){
            return true;
        }else{
            return false;
        }
        
    }
    
    /**
     * @method      enviarCorreosExternos
     * @description Method to send email
     * @author      Intellect Systems - 2025-10-20
     * @param       address
     * @param       subject
     * @param       descripcion
     * @param       recordId
     */

    public static void enviarCorreosExternos(String address, String nombrePlantilla, String recordId, Case caso) {
        OrgWideEmailAddress owea = [select Id from OrgWideEmailAddress where Address = :Label.FS_CorreoElectronicoServicio];
        system.debug('envio en correo Externos TS');

        // Create an email message object
        EmailTemplate plantilla = getEmailTemplateByDeveloperName(nombrePlantilla);
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
            System.debug(ex.getMessage()+'Error Correo Externo ----- '+ex.getLineNumber());
        }
    }

    public static EmailTemplate getEmailTemplateByDeveloperName(String developerName){
        EmailTemplate emailTem = [Select Id, Subject, HTMLValue,DeveloperName from EmailTemplate Where DeveloperName =: developerName];
        return emailTem;
    }

}