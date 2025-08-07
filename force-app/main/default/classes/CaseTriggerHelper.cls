/**
**************************************************************************************************************
* @author           Intellect Systems href=<info@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             ControladorCrearCaso
* @description      Class helper to CaseTriggerHandler
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2023-07-18   Intellect Systems             Initial version.
* 2024-03-24   Intellect Systems             Methods are eliminated: validationChatter and deleteChatter, after reviewing that they are unnecessary.
* 2024-03-20   Intellect Systems             Validation of Fecha de Compromiso de Entrega field is removed, in informacionCompleta method.
* 2024-03-20   Intellect Systems             Method adjustments: solventarPregunta, aprobacionConsSolic, enviarNotificacion
* 2024-03-26   Intellect Systems             New method called: assignDeliveryDate
* 2024-04-26   Intellect Systems             Modify method called: validacionProducto, to validate products related to account.  
* 2024-05-02   Intellect Systems             Se añade validación en el método: validacionUser, se incluye perfil: Servicio al Cliente.
* 2024-09-24   Intellect Systems             Se añade metodo para actualizacion de campos post actualizacion.
**************************************************************************************************************
*/

public without sharing class CaseTriggerHelper {

    public static final String COLA_ATENCION_N1_CORE ='FS_AtencionN1Core';
    public static final String COLA_ATENCION_N2_CORE ='FS_AtencionN2Core';
    public static final String COLA_ATENCION_N1_OMNIA ='FS_AtencionN1Omnia';
    public static final String COLA_ATENCION_N2_OMNIA ='FS_AtencionN2Omnia';
    public static final String COLA_ATENCION_QA_OMNIA ='FS_AtencionQAOmnia';
    public static final String COLA_ATENCION_QA_CORE ='FS_AtencionQACore';
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
        for(EmailTemplate plantilla :[Select Id, Subject, HTMLValue,DeveloperName from EmailTemplate Where DeveloperName Like '%FS_%']){
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

            if(item.Status != 'Dado de Baja' && item.Status != 'Cerrado' && caso.Status != item.Status && caso.Status != 'En Espera de Respuesta del Cliente' && item.RecordTypeId == caso.RecordTypeId && item.RecordTypeId != CONTROLDECAMBIO_TIPO_REGISTRO && item.RecordTypeId != CONSULTA_TIPO_REGISTRO) {
                item.Status.addError('Privilegios insuficiente para modificar el estado del caso');
            }else if(item.Status != 'Dado de Baja' && item.Status != 'Análisis Previo' && item.Status != 'Cerrado' && caso.Status != item.Status && caso.Status != 'En Espera de Respuesta del Cliente' && item.RecordTypeId == caso.RecordTypeId && item.RecordTypeId == CONTROLDECAMBIO_TIPO_REGISTRO){
                item.Status.addError('Privilegios insuficiente para modificar el estado del caso');
            }else if(item.Status != 'Dado de Baja' && item.Status != 'Análisis Previo' && item.Status != 'Cerrado' && caso.Status != item.Status && caso.Status != 'En Espera de Respuesta del Cliente' && item.RecordTypeId == caso.RecordTypeId && item.RecordTypeId == CONSULTA_TIPO_REGISTRO && item.FS_PudeSolventarPregunta__c == caso.FS_PudeSolventarPregunta__c ){
                item.Status.addError('Privilegios insuficiente para modificar el estado del caso en consulta');
            }
        }
    }
    
    public static void validacionSubEstado(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        if(validacionUser(true)){
            return;
        }
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(item.FS_SubEstado__c != null && !item.FS_SubEstado__c.contains('Aprobación') && item.OwnerId != UserInfo.getUserId() && item.RecordTypeId == caso.RecordTypeId){
                item.addError('Solo el propietario del caso puede modificarlo.');
            }else if(item.FS_SubEstado__c == 'Aprobación Solución IP-N2' && item.FS_UsuarioAprobadorSolucionIPN2__c != UserInfo.getUserId() ){
                item.addError('El caso se encuentra en Aprobación de Solución IP-N2 y no tiene permisos para modificarlo.');
            } else if(item.FS_SubEstado__c == 'Elaboración Diseño Técnico' && item.FS_FechaEntregaDesarrollo__c == null){
                item.addError('El caso se encuentra en Elaboración Diseño Técnico y no tiene permisos para modificarlo.');
            }else if(item.FS_SubEstado__c == 'Aprobación Diseño Técnico' && item.FS_UsuarioAprobadorDT__c != UserInfo.getUserId()){
                item.addError('El caso se encuentra en Aprobación de Diseño Técnico y no tiene permisos para modificarlo.');
            }else if(item.FS_SubEstado__c == 'Aprobación Solución Definitiva N2' && item.FS_UsuarioAprobadorDT__c != UserInfo.getUserId()){
                item.addError('El caso se encuentra en Aprobación Solución Definitiva N2 y no tiene permisos para modificarlo.');
            } else if(item.FS_SubEstado__c == 'Aprobación Plan de Pruebas' && item.FS_UsuarioAprobadorPlanPruebas__c != UserInfo.getUserId()){
                item.addError('El caso se encuentra en Aprobación Plan de Pruebas y no tiene permisos para modificarlo.');
            } else if(item.FS_SubEstado__c == 'Aprobación Certificación Parche QA' && item.OwnerId != UserInfo.getUserId()){
                item.addError('El caso se encuentra en Aprobación Certificación Parche QA y no tiene permisos para modificarlo.');
            } else if(item.FS_SubEstado__c == 'Aprobación Consulta N2' && item.FS_UsuarioAprobadorSolucion__c != UserInfo.getUserId()){
                item.addError('El caso se encuentra en Aprobación Consulta N2 y no tiene permisos para modificarlo.');
            }else if(item.FS_SubEstado__c == 'Aprobación Solicitud N2' && item.FS_UsuarioAprobadorSolucion__c != UserInfo.getUserId()){
                item.addError('El caso se encuentra en Aprobación Solicitud N2 y no tiene permisos para modificarlo.');
            }else if(item.FS_PudeSolventarPregunta__c != caso.FS_PudeSolventarPregunta__c &&  (item.FS_InformacionCompleta__c != caso.FS_InformacionCompleta__c || item.FS_RequiereInformacionAdicional__c != caso.FS_RequiereInformacionAdicional__c)){
                item.FS_PudeSolventarPregunta__c.addError('No puede modicar este campo a la vez con Información Completa.');
            }
        }
    }
    
    public static void validacionCamposAprobacion(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        if(validacionUser(true) ){
            return;
        }
        List<String> camposAprobacion = Label.FS_CamposProtegidosAprobacion.split(',');
        for(Case item : newCaseList){
            if(item.FS_SubEstado__c != null && !item.FS_SubEstado__c.contains('Aprobación')){
                Case caso = oldCaseMap.get(item.Id);
                for(String campo : camposAprobacion){
                    if(item.get(campo) != caso.get(campo)){
                        item.addError('No tiene permisos para modificar la información de aprobación');
                    }
                }
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
    
    /**
     * @method      validacionProducto
     * @description Method to validate products related to account
     * @author      Intellect Systems - 2023-07-18
     * @param       newCaseList
     * @param       oldCaseMap
     */
    public static void validacionProducto(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Boolean flag = false;
        Boolean isActive = true;
        List<String> listAccount = new  List<String>();

        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_Producto__c != item.FS_Producto__c || caso.FS_Modulo__c != item.FS_Modulo__c || caso.FS_SubModulo__c != item.FS_SubModulo__c || caso.FS_TipoRequerimiento__c != item.FS_TipoRequerimiento__c || item.FS_Buscar_Proyecto__c == null){
                flag = true;
                listAccount.add(item.AccountId);
                if(item.FS_TipoRequerimiento__c != null && item.FS_Buscar_Proyecto__c == null){
                        item.addError('Debe seleccionar un proyecto para continuar');
                    }
            }
        }

        if(flag){
            List<FS_ProductoAdquirido__c> productos = [     SELECT  FS_Cuenta__c, FS_Producto__c, FS_Modulo__c, FS_SubModulo__c, FS_Esta_activo__c 
                                                            FROM    FS_ProductoAdquirido__c 
                                                            WHERE   FS_Cuenta__c in: listAccount    ];

            for(Case item: newCaseList) {
                flag = false;
                isActive = true;
                for(FS_ProductoAdquirido__c p :productos) {
                    if(item.AccountId == p.FS_Cuenta__c && item.FS_Producto__c == p.FS_Producto__c && item.FS_Modulo__c == p.FS_Modulo__c && item.FS_SubModulo__c == p.FS_SubModulo__c){
                        flag = true;
                    }
                    if(item.AccountId == p.FS_Cuenta__c && item.FS_Producto__c == p.FS_Producto__c && item.FS_Modulo__c == p.FS_Modulo__c && item.FS_SubModulo__c == p.FS_SubModulo__c && p.FS_Esta_activo__c == false) {
                        isActive = false;
                    }
                    
                    if(item.AccountId == p.FS_Cuenta__c && item.FS_Producto__c == p.FS_Producto__c && item.FS_Modulo__c == p.FS_Modulo__c && item.FS_SubModulo__c == p.FS_SubModulo__c && item.FS_TipoRequerimiento__c != ''){
                        flag = true;
                    }
                }

                if(!flag && item.Status != 'Nuevo' && item.Status != 'En Espera de Respuesta del Cliente' ) {
                    item.addError('El cliente no tiene la combinación de productos seleccionados');
                } else {
                    Case caso = oldCaseMap.get(item.Id);
                    if(caso.FS_Producto__c != item.FS_Producto__c) {
                        Boolean esCore = productoCore(item) ;
                        item.FS_Area__c = esCore ? 'N1. CORE' : 'N1. OMNIA';
                        item.OwnerId = [    SELECT  Id 
                                            FROM    Group 
                                            WHERE   DeveloperName =: (esCore ? COLA_ATENCION_N1_CORE : COLA_ATENCION_N1_OMNIA) and Type = 'Queue'].Id;

                        validarTareas(item);
                    }
                }

                if(!isActive) {
                    item.addError('El producto seleccionado está inactivo');
                }
            }      
        }   
    }   

    /**
     * @method      informacionCompleta
     * @description Method to validate required case data, assign values to specific fields and send notifications emails.
     * @author      Intellect Systems - 2023-07-18
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
            
            if(caso.FS_InformacionCompleta__c != item.FS_InformacionCompleta__c) {
                if(item.FS_InformacionCompleta__c == 'Si') {
                    String prod = item.AccountId  + item.FS_Producto__c + item.FS_Modulo__c + item.FS_SubModulo__c;
                    String msjError = 'Debe Completar los siguientes campos: ';
                    msjError += String.isBlank(item.FS_Proyecto__c) ? 'Proyecto, ' : '';
                    msjError += String.isBlank(item.FS_SubModulo__c) && !listProductos.contains(prod) ? 'Sub Módulo, ' : '';
                    
                    if(msjError.length() > 38) {
                        item.addError(msjError.substring(0, msjError.length() - 2));
                    }
                    if(item.FS_TipoIncidente__c != null && item.RecordTypeId == INCIDENTE_TIPO_REGISTRO) {
                        item.FS_SubEstado__c = item.FS_TipoIncidente__c == 'Puntual' ? 'Desarrollo Incidente Puntual' : 'Desarrollo Incidente Definitivo';
                        item.Status = 'En Desarrollo';
                    } else if(item.FS_NombreTipoRegistro__c  == 'Solicitud (Falla Operativa)') {
                        item.FS_SubEstado__c = 'En Espera de Respuesta del Cliente';
                        item.Status = 'Análisis Previo';
                        item.FS_Acepta1erCosto__c = null;
                        envioCorreo(item, 'FS_AprobacionPrimerCosto', true);
                    } else {
                        item.FS_SubEstado__c = item.FS_Area__c == 'N2- CORE' || item.FS_Area__c == 'N2-OMNIA' ? 'Análisis N2' : 'Análisis N1';
                        item.Status = 'Análisis Previo';
                    }
                }  
                
                if(item.FS_InformacionCompleta__c == 'No') {
                    item.FS_SubEstadoQueSePideInformacion__c = item.FS_SubEstado__c;
                    item.FS_SubEstado__c = 'En Espera de Respuesta del Cliente'; 
                    envioCorreo(item, 'FS_InformacionFaltante', true);
                }
            }
        }
    }
    
    public static void validacionTipo(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.Type  != item.Type && item.RecordTypeId == SOLICITUD_TIPO_REGISTRO){
                item.Status = 'Análisis Previo';
                item.FS_SubEstado__c = 'Análisis N1';
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
                    envioCorreo(item, 'FS_ActualizacionInformacionCliente', false);
                }
            }
        }
    }
    
    /**
     * @method      solventarPregunta
     * @description Method to define actions based on field value: ¿Pude solventar?
     * @author      Intellect Systems - 2023-07-18
     * @param       newCaseList
     * @param       oldCaseMap
     */
    public static void solventarPregunta(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        list<Case> updateCaseList = new list<Case>();
        for(Case item: newCaseList) {
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_PudeSolventarPregunta__c != item.FS_PudeSolventarPregunta__c) {
                Case record = new Case(Id = item.Id);
                if(item.FS_PudeSolventarPregunta__c == 'Si') {
                    if(item.FS_Area__c == 'N1. CORE' || item.FS_Area__c == 'N1. OMNIA') {
                        aprobacionConsSolic2(item);
                        record.FS_SubEstado__c = item.recordTypeId == CONSULTA_TIPO_REGISTRO ? 'Aprobación Consulta N2' : 'Aprobación Solicitud N2';
                        updateCaseList.add(record);
                    } else {
                        record.FS_SubEstado__c = 'Envío de respuesta';
                        record.Status = 'Validación de Respuesta (Cliente)';
                        record.FS_AceptaRespuesta__c = null;
                        updateCaseList.add(record);
                        envioCorreo(item, 'FS_ValidacionInformacion', true);
                    }
                    validarTareas(item);
                } else if(item.FS_PudeSolventarPregunta__c == 'No') {
                    Boolean esCore = productoCore(item) ;
                    record.OwnerId =  String.isBlank(item.FS_UsuarioAprobadorSolucion__c) ? mapColas.get(esCore ? COLA_ATENCION_N2_CORE : COLA_ATENCION_N2_OMNIA) : item.FS_UsuarioAprobadorSolucion__c;
                    record.FS_Area__c =  esCore ? 'N2- CORE' : 'N2-OMNIA';
                    record.FS_SubEstado__c = String.isBlank(item.FS_UsuarioAprobadorSolucion__c) ? 'Escalado a N2' : 'Análisis N2'; 
                    record.IsEscalated = true;
                    record.FS_InformacionCompleta__c = null;
                    record.FS_RequiereInformacionAdicional__c = false;
                    updateCaseList.add(record);
                    validarTareas(item);
                    if(item.FS_UsuarioAprobadorSolucion__c != null) {
                        String titulo = 'Asignación de caso No '+item.CaseNumber;
                        String descripcion = 'El agente ' + UserInfo.getName() + ' ha escalado el caso '+item.CaseNumber +' \nPor favor dar seguimiento.';
                        enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                    }
                }
            }
        }
        if(!updateCaseList.isEmpty()) {
            update updateCaseList;
        }
    }
    
    public static void UpdateFields(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        list<Case> updateCaseList = new list<Case>();
        for(Case item: newCaseList) {
            if(item.FS_AceptaRespuesta__c == 'No') {
                Case record = new Case(Id = item.Id);
                record.FS_AceptaRespuesta__c = '';
                updateCaseList.add(record);
            }
        }
        if(!updateCaseList.isEmpty()) {
            update updateCaseList;
        }
    }
    
    public static void validacionAprobacionSolucion(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AprobacionSolucion__c != item.FS_AprobacionSolucion__c){
                if(item.FS_AprobacionSolucion__c == 'Si'){
                    item.FS_SubEstado__c = 'Envío de respuesta';
                    item.Status = 'Validación de Respuesta (Cliente)';
                    item.FS_AceptaRespuesta__c = null;
                    String nombrePlantilla = item.RecordTypeId == SOLICITUD_TIPO_REGISTRO ? 'FS_ValidacionInformacionSolicitud' : 'FS_ValidacionInformacion';
                    envioCorreo(item, nombrePlantilla, true);
                    String titulo = 'Aprobación de solución para caso '+item.CaseNumber;
                    String descripcion = 'El agente ' + UserInfo.getName() + ' ha aprobado de solución para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }else if(item.FS_AprobacionSolucion__c == 'No'){
                    item.FS_SubEstado__c = item.RecordTypeId == CONSULTA_TIPO_REGISTRO ? 'Análisis N1' : 'Análisis Falla Operativa';
                    String titulo = 'Rechazo de solución para caso '+item.CaseNumber;
                    String descripcion = 'El agente ' + UserInfo.getName() + ' ha rechazado de solución para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
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
                    item.FS_SubEstado__c = 'Respuesta aceptada';
                    item.Status = 'Pendiente de Respuesta CSAT';
                    item.FS_EncuestaEnviada__c = true;
                    item.FS_FechaEnvioEncuesta__c = System.now();
                    envioCorreo(item, 'FS_Encuesta', true);
                    crearEncuesta(item);
                }else if(item.FS_AceptaRespuesta__c == 'No'){
                    item.FS_SubEstado__c = item.FS_Area__c == 'N2- CORE' || item.FS_Area__c == 'N2-OMNIA' ? 'Análisis N2' : 'Análisis N1';
                    item.Status = item.RecordTypeId == SOLICITUD_TIPO_REGISTRO ? 'Análisis Falla Operativa' : 'Análisis Previo';
                    item.FS_SubEstado__c = item.RecordTypeId == SOLICITUD_TIPO_REGISTRO ? 'Análisis Falla Operativa' : item.FS_SubEstado__c ;
                    item.FS_PudeSolventarPregunta__c = null;
                    item.FS_NumeroHorasSolicitud__c = null;
                    item.FS_FechaCompromisoEntrega__c = null;
                    item.FS_MotivoCambioFechaEntrega__c = null;
                    item.FS_InformacionCompleta__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;

                    envioCorreo(item, 'FS_RechazoRespuesta', false);
                    
                    String titulo = 'RECHAZO DEL CLIENTE PARA EL CASO NÚMERO '+item.CaseNumber;
                    String descripcion = 'El caso '+ item.CaseNumber+' ha cambiado de estado, por favor dar seguimiento';
                    enviarNotificacion(caso.OwnerId, caso.Id, titulo, descripcion);
                    
                    if(item.RecordTypeId == INCIDENTE_TIPO_REGISTRO && item.FS_TipoIncidente__c == 'Puntual' ){
                        item.FS_SubEstado__c = 'Desarrollo Incidente Puntual';
                        item.Status = 'En Desarrollo';
                        item.FS_EnviarAprobacionSolucionIPN2__c = false;
                    }else if (item.RecordTypeId == INCIDENTE_TIPO_REGISTRO && item.FS_TipoIncidente__c == 'Definitivo'){
                        item.FS_SubEstado__c = 'Elaboración Diseño Técnico';
                        item.Status = 'En Desarrollo';
                        item.FS_URLDisenioTecnico__c = null;
                    }
                }
            }
        }
    }
    
    public static void acepta1erCosto(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_Acepta1erCosto__c  != item.FS_Acepta1erCosto__c){
                if(item.FS_Acepta1erCosto__c == 'Si'){
                    item.Status = 'Aprobación 1er Costo';
                    item.FS_SubEstado__c = 'Costo Aceptado';
                    item.FS_FechaAprobacion1erCosto__c = System.now();
                    item.FS_UsuarioAprobador1erCosto__c = UserInfo.getUserId();
                    String titulo = 'Aprobación de Primer Costo para caso '+item.CaseNumber;
                    String descripcion = 'El cliente '+UserInfo.getFirstName() + ' ha aceptado el 1er costo para el caso '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }else if(item.FS_Acepta1erCosto__c == 'No'){
                    item.Status = 'Análisis Previo';
                    item.FS_SubEstado__c = 'Análisis N1';
                    item.FS_InformacionCompleta__c = null;
                    item.FS_RequiereInformacionAdicional__c = false;
                    String titulo = 'Rechazo de primer costo para caso '+item.CaseNumber;
                    String descripcion = 'El cliente '+UserInfo.getFirstName() + ' ha rechazo el primer costo '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }
            }
        }
    }
    
    public static void horasSolicitud(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_NumeroHorasSolicitud__c  != item.FS_NumeroHorasSolicitud__c && item.FS_NumeroHorasSolicitud__c != null){
                if(item.FS_Area__c == 'N1. CORE' || item.FS_Area__c == 'N1. OMNIA'){
                    aprobacionConsSolic(item);
                    validarTareas(item);
                    item.FS_SubEstado__c = 'Aprobación Solicitud N2';
                }else{
                    item.FS_SubEstado__c = 'Envío de respuesta';
                    item.Status = 'Validación de Respuesta (Cliente)';
                    item.FS_AceptaRespuesta__c = null;
                    item.FS_PudeSolventarPregunta__c = 'Si';
                    envioCorreo(item, 'FS_ValidacionInformacionSolicitud', true);
                }
            }
        }
    }
    
    /**
     * @method      aprobacionConsSolic
     * @description Method to send notification to approver. Execute beforeUpdate.
     * @author      Intellect Systems - 2023-07-18
     * @param       item -- Record Case.
     */
    public static void aprobacionConsSolic(Case item) {
        String nombreRol = item.FS_Area__c == 'N1. CORE' ? 'FS_AgenteN2Core' : 'FS_AgenteN2Omnia';
        List<User> userRecord = new List<User>();

        List<User> userValue = [   SELECT      Id, FS_FechaUltimaAprobacion__c 
                                    FROM        User 
                                    WHERE       UserRole.DeveloperName =: nombreRol And Id !=: item.OwnerId and IsActive = true 
                                    ORDER BY    FS_FechaUltimaAprobacion__c ASC 
                                    LIMIT       1   ];

        for(User usuario : userValue) {
            usuario.FS_FechaUltimaAprobacion__c = System.now();
            userRecord.add(usuario);
        }

        if(!userRecord.isEmpty()) {
            update userRecord;
            Case record = new Case(Id = Item.Id);

            item.FS_UsuarioAprobadorSolucion__c = userRecord[0].Id;
            item.FS_AprobacionSolucion__c = null;
            item.FS_ComentariosRechazoSolucion__c = null;

            String titulo = 'Aprobación de solución para caso '+item.CaseNumber;
            String descripcion = 'El agente '+item.FS_NombrePropietario__c + ' necesita la aprobación de solución para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';

            if(item.FS_UsuarioAprobadorSolucion__c != null) {
                enviarNotificacion(item.FS_UsuarioAprobadorSolucion__c, item.Id, titulo, descripcion);
            } 
        }  else {
            item.addError('No existe aprobador Agente N2 - Core');    
        }    
    }

    /**
     * @method      aprobacionConsSolic2
     * @description Method to send notification to approver. Execute afterUpdate.
     * @author      Intellect Systems - 2024-06-06
     * @param       item -- Record Case.
     */
    public static void aprobacionConsSolic2(Case item) {
        String nombreRol = item.FS_Area__c == 'N1. CORE' ? 'FS_AgenteN2Core' : 'FS_AgenteN2Omnia';
        List<User> userRecord = new List<User>();
        List<Case> caseRecord = new List<Case>();

        List<User> userValue = [   SELECT      Id, FS_FechaUltimaAprobacion__c 
                                    FROM        User 
                                    WHERE       UserRole.DeveloperName =: nombreRol And Id !=: item.OwnerId and IsActive = true 
                                    ORDER BY    FS_FechaUltimaAprobacion__c ASC 
                                    LIMIT       1   ];

        for(User usuario : userValue) {
            usuario.FS_FechaUltimaAprobacion__c = System.now();
            userRecord.add(usuario);
        }

        if(!userRecord.isEmpty()) {                            
            update userRecord;
            Case record = new Case(Id = Item.Id);

            record.FS_UsuarioAprobadorSolucion__c = userRecord[0].Id;
            record.FS_AprobacionSolucion__c = null;
            record.FS_ComentariosRechazoSolucion__c = null;
            caseRecord.add(record);

            if(!caseRecord.isEmpty()) {
                update caseRecord;
            }

            String titulo = 'Aprobación de solución para caso '+item.CaseNumber;
            String descripcion = 'El agente '+item.FS_NombrePropietario__c + ' necesita la aprobación de solución para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';

            if(caseRecord[0].FS_UsuarioAprobadorSolucion__c != null) {
                enviarNotificacion(caseRecord[0].FS_UsuarioAprobadorSolucion__c, caseRecord[0].Id, titulo, descripcion);
            } 
        }  else {
            item.addError('No existe aprobador Agente N2 - Core');    
        }    
    }
    
    public static void validacionFechaEntrega(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_FechaCompromisoEntrega__c != item.FS_FechaCompromisoEntrega__c && (caso.FS_FechaCompromisoEntrega__c == null || item.FS_SubEstado__c == 'Análisis N1')){
                if(item.RecordTypeId == SOLICITUD_TIPO_REGISTRO){
                    item.Status = 'Análisis Falla Operativa';
                    item.FS_SubEstado__c = 'Análisis Falla Operativa';
                }else if(item.RecordTypeId == CONSULTA_TIPO_REGISTRO){
                    item.Status = 'Análisis Previo';        
                    item.FS_SubEstado__c = item.FS_Area__c == 'N2- CORE' || item.FS_Area__c == 'N2-OMNIA' ? 'Análisis N2' : 'Análisis N1';
                }
                
            }
        }
    }
    
    public static void validacionURLResultadoAnalasis(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_EnviarAprobacionSolucionIPN2__c != item.FS_EnviarAprobacionSolucionIPN2__c && item.FS_EnviarAprobacionSolucionIPN2__c == true){
                item.FS_SubEstado__c = 'Aprobación Solución IP-N2';
                item.FS_AprobacionSolucionIPN2__c = null;
                item.FS_MotivosRechazoAprobacionIPN2__c = null;
                item.FS_UsuarioAprobadorSolucionIPN2__c = item.FS_UsuarioAprobadorSolucionIPN2__c == null ? getUsuario(item) : item.FS_UsuarioAprobadorSolucionIPN2__c;
                String titulo = 'Aprobación Solución IP-N2 para caso '+item.CaseNumber;
                String descripcion = 'El agente '+item.FS_NombrePropietario__c + ' necesita Aprobación de Solución IP-N2 para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                enviarNotificacion(item.FS_UsuarioAprobadorSolucionIPN2__c, item.Id, titulo, descripcion);
                validarTareas(item);
            }
        }
    }
    
    public static void validacionAutorizacionSolucionIPN2(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AprobacionSolucionIPN2__c != item.FS_AprobacionSolucionIPN2__c){
                if(item.FS_AprobacionSolucionIPN2__c == 'Si'){
                    item.FS_AprobacionSolucionIPRelease__c = null;
                    item.FS_MotivoRechazoAprobacionIPRealease__c = null;
                    item.FS_ComentariosAprobacionSolucinRelease__c = null;
                    item.FS_UsuarioAprobacionSolucionRelease__c = null;
                    item.FS_SubEstado__c = 'Aprobación de Solución IP-Release';
                }else if(item.FS_AprobacionSolucionIPN2__c == 'No'){
                    item.FS_EnviarAprobacionSolucionIPN2__c = false;
                    item.FS_SubEstado__c = 'Desarrollo Incidente Puntual';
                    String titulo = 'Rechazo de Aprobación Solución IP-N2 para caso '+item.CaseNumber;
                    String descripcion = 'El agente '+UserInfo.getFirstName() + ' ha rechzado la Aprobación de Solución IP-N2 para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }
            }
        }
    }
    
    public static void validacionAprobacionSolucionIPRelease(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AprobacionSolucionIPRelease__c != item.FS_AprobacionSolucionIPRelease__c){
                if(item.FS_AprobacionSolucionIPRelease__c == 'Si'){
                    item.FS_SubEstado__c = 'Envío de respuesta';
                    item.Status = 'Validación de Respuesta (Cliente)';
                    item.FS_AceptaRespuesta__c = null;
                    
                    String titulo = 'Aprobación de Solución IP-Release para caso '+item.CaseNumber;
                    String descripcion = 'El Jefe de Release ' + item.FS_UsuarioAprobacionSolucionRelease__c + ' ha aprobado la Solución IP-Release para el caso número '+item.CaseNumber +'\nMuchas gracias.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                    envioCorreo(item, 'FS_ValidacionInformacionIncidentePuntual', true);
                    descripcion = 'Estimado cliente '+item.FS_NombreContacto__c+'\n\n\nSe ha realizado la entrega de la solución al caso '+item.CaseNumber+', la cual se puede descargar en la herramienta Azure Explorer en el siguiente directorio '+item.FS_URLCodigoFuente__c +'\n\nLe recordamos que tiene 15 días para descargar el parche.\n\nGracias\nCustomer Care Team';
                    insert new FeedItem(ParentId = item.Id, Body = descripcion, Visibility = 'AllUsers');
                }else if(item.FS_AprobacionSolucionIPRelease__c == 'No'){
                    item.FS_EnviarAprobacionSolucionIPN2__c = false;
                    item.FS_SubEstado__c = 'Desarrollo Incidente Puntual';
                    String titulo = 'Rechazo de Solución IP-Release para caso '+item.CaseNumber;
                    String descripcion = 'El Jefe de Release ' + item.FS_UsuarioAprobacionSolucionRelease__c + ' ha rechzado la Solución IP-Release para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }
            }
        }
    }
    
    public static void validacionTipoIncidente(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_TipoIncidente__c != item.FS_TipoIncidente__c){
                item.Status = 'Análisis Previo';
                Boolean esCore = productoCore(item) ;
                if(item.IsEscalated){
                    item.FS_SubEstado__c = 'Revisión Documentación N2';
                    item.FS_URLCodigoFuente__c = null;
                }else{
                    item.OwnerId = mapColas.get(esCore ? COLA_ATENCION_N2_CORE : COLA_ATENCION_N2_OMNIA);
                    item.FS_Area__c =  esCore ? 'N2- CORE' : 'N2-OMNIA';
                    item.FS_SubEstado__c = 'Escalado a N2';
                    item.IsEscalated = true;
                }

                item.FS_InformacionCompleta__c = null;
                item.FS_RequiereInformacionAdicional__c = false;
                item.Type = item.FS_TipoIncidente__c;
                validarTareas(item);
            }
        }
    }

    public static void validacionSolucionCortoPlazo(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_SolucionCortoPlazo__c != item.FS_SolucionCortoPlazo__c && String.isNotBlank(item.FS_SolucionCortoPlazo__c)){
                if(item.FS_SolucionCortoPlazo__c == 'Si'){
                    if(String.isBlank(item.FS_PropietarioCasoSolucionCortoPlazo__c)){
                        item.FS_PropietarioCasoSolucionCortoPlazo__c.addError('Debe completar el propietario del caso que esta por crearse.');
                        return;
                    }
                    Case casoHijo = item.clone(false, false, false, false);
                    casoHijo.OwnerId = item.FS_PropietarioCasoSolucionCortoPlazo__c;
                    casoHijo.Subject += ' Caso hijo de ' + Item.CaseNumber;
                    casoHijo.Status = 'Análisis Previo';
                    casoHijo.FS_SubEstado__c = 'Revisión Documentación N2';
                    casoHijo.ParentId = item.Id;
                    casoHijo.FS_TipoIncidente__c = 'Puntual';
                    casoHijo.FS_SolucionCortoPlazo__c = null;
                    casoHijo.FS_FechaCompromisoEntrega__c = null;
                    casoHijo.FS_InformacionCompleta__c = '';
                    insert casoHijo;
                    casoHijo = [Select Id, CaseNumber From Case where Id =: casoHijo.Id];
                    String titulo = 'Asignación de caso No. '+casoHijo.CaseNumber;
                    String descripcion = 'El agente ' + UserInfo.getName()  + ' ha creado el caso '+casoHijo.CaseNumber +' como solución a corto plazo del caso ' + item.CaseNumber + '\nPor favor dar seguimiento.';
                    enviarNotificacion(item.FS_PropietarioCasoSolucionCortoPlazo__c, casoHijo.Id, titulo, descripcion);
                }
                item.FS_SubEstado__c = item.FS_SubEstado__c == 'Desarrollo Incidente Definitivo' ? 'Elaboración Diseño Técnico' : item.FS_SubEstado__c;
            }
        }
    }
    
    public static void validacionURLDisenioTecnico(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_EnviarAprobacionDisenioTecnico__c != item.FS_EnviarAprobacionDisenioTecnico__c && item.FS_EnviarAprobacionDisenioTecnico__c == true){
                item.FS_SubEstado__c = 'Aprobación Diseño Técnico';
                item.FS_AprobacionDisenioTecnico__c = null;
                item.FS_MotivosRechazoDT__c = null;
                item.FS_UsuarioAprobadorDT__c = item.FS_UsuarioAprobadorDT__c == null ? getUsuario(item) : item.FS_UsuarioAprobadorDT__c;
                String titulo = 'Aprobación Diseño Técnico para caso '+item.CaseNumber;
                String descripcion = 'El agente '+item.FS_NombrePropietario__c + ' necesita Aprobación Diseño Técnico para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                enviarNotificacion(item.FS_UsuarioAprobadorDT__c, item.Id, titulo, descripcion);
                validarTareas(item);
            }
        }
    }
    
    public static void validacionAprobacionDisenioTecnico(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AprobacionDisenioTecnico__c  != item.FS_AprobacionDisenioTecnico__c){
                if(item.FS_AprobacionDisenioTecnico__c == 'Si'){
                    item.FS_SubEstado__c = 'Validación-Entrega de Fuentes';
                }else if(item.FS_AprobacionDisenioTecnico__c == 'No'){
                    item.FS_EnviarAprobacionDisenioTecnico__c = false;
                    item.FS_SubEstado__c = 'Elaboración Diseño Técnico';
                    String titulo = 'Rechazo Diseño Técnico para caso '+item.CaseNumber;
                    String descripcion = 'El agente '+UserInfo.getName() + ' ha rechazado el diseño técnico para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }
            }
        }
    }

    public static void validacionURLCodigoFuente(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_URLCodigoFuente__c != item.FS_URLCodigoFuente__c  && String.isBlank(caso.FS_URLCodigoFuente__c) && item.FS_TipoIncidente__c == 'Definitivo'){
                item.FS_SubEstado__c = 'Elaboración Solución Definitiva';
            }
        }
    }

    public static void validacionURLSolucionDefinitiva(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_EnviarAprobacionSolucionDN2__c != item.FS_EnviarAprobacionSolucionDN2__c && item.FS_EnviarAprobacionSolucionDN2__c == true){
                item.FS_SubEstado__c = 'Aprobación Solución Definitiva N2';
                item.FS_AprobacionSolucionDefinitivaN2__c = null;
                item.FS_MotivoRechazoSDN2__c = null;
                String titulo = 'Aprobación Solución Definitiva N2 para caso '+item.CaseNumber;
                String descripcion = 'El agente '+item.FS_NombrePropietario__c + ' necesita Aprobación Solución Definitiva N2 para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                enviarNotificacion(item.FS_UsuarioAprobadorDT__c, item.Id, titulo, descripcion);
				validarTareas(item);
            }
        }
    }
    
    public static void validacionAprobacionSolucionDefinitivaN2(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AprobacionSolucionDefinitivaN2__c != item.FS_AprobacionSolucionDefinitivaN2__c ){
                if(item.FS_AprobacionSolucionDefinitivaN2__c == 'Si'){
                    item.FS_SubEstado__c = 'Aprobación Solución Definitiva Releases';
                    item.FS_AprobacionSolucionDefinitivaRelease__c = null;
                    item.FS_MotivoRechazoSDRelease__c = null;
                    item.FS_ComentariosAprobacionSolucinRelease__c = null;
                    item.FS_UsuarioAprobacionSolucionRelease__c = null;
                }else if(item.FS_AprobacionSolucionDefinitivaN2__c == 'No'){
                    item.FS_EnviarAprobacionSolucionDN2__c = false;
                    //item.FS_AprobacionSolucionDefinitivaRelease__c = null;
                    item.FS_SubEstado__c = 'Elaboración Solución Definitiva';
                    String titulo = 'Rechazo de Solución Definitiva N2 para caso '+item.CaseNumber;
                    String descripcion = 'El agente '+UserInfo.getName() + ' ha rechazado la Solución Definitiva N2 para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }
            }
        }
    }
    
    public static void validacionAprobacionSolucionDefinitivaRelease(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AprobacionSolucionDefinitivaRelease__c != item.FS_AprobacionSolucionDefinitivaRelease__c){
                if(item.FS_AprobacionSolucionDefinitivaRelease__c == 'Si'){
                    if(String.isNotBlank(item.FS_SubEstadoAnterior__c)){
                        item.FS_SubEstadoAnterior__c = null;
                        item.FS_SubEstado__c = 'Instalación Parche Releases';
                        item.FS_AprobacionInstalacionParcheRelease__c = null;
                        item.FS_MotivosRechazoInstalacionParche__c = null;
                        item.FS_ComentariosAprobacionInstalacionParch__c = null;
                        item.OwnerId = String.isBlank(item.FS_AgenteQA__c) ? item.OwnerId : item.FS_AgenteQA__c;
                        String titulo = 'Instalación Parche Releases para caso No '+item.CaseNumber;
                        String descripcion = 'El caso No '+item.CaseNumber + ' que anteriormente tenías se ha reasignado ya que llego a Sub Estado Instalación Parche Releases \nPor favor dar seguimiento.';
                        enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                    }else{
                        Boolean esCore = productoCore(item) ;
                        item.OwnerId = mapColas.get(esCore ? COLA_ATENCION_QA_CORE : COLA_ATENCION_QA_OMNIA);
                        item.FS_Area__c =  esCore ? 'QA CC-CORE' : 'QA CC-OMNIA';
                        item.FS_SubEstado__c = String.isBlank(item.FS_AgenteQA__c) ? 'Escalado a QA' : 'Elaboración Plan de Pruebas';
                        item.OwnerId = String.isBlank(item.FS_AgenteQA__c) ? item.OwnerId : item.FS_AgenteQA__c;  
                        item.FS_EnviarAprobacionPlanPruebas__c = false;
                        validarTareas(item);
                        if(String.isNotBlank(item.FS_AgenteQA__c)){
                            String titulo = 'Asígnación de caso No '+item.CaseNumber;
                            String descripcion = 'Se ha reasignado el caso No '+item.CaseNumber + ' que anteriormente tenías se ha asigando. \nPor favor dar seguimiento.';
                            enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                        }
                    }
                }else if(item.FS_AprobacionSolucionDefinitivaRelease__c == 'No'){
                    item.FS_EnviarAprobacionSolucionDN2__c = false;
                    item.FS_SubEstado__c = 'Elaboración Solución Definitiva';
                    item.OwnerId = item.FS_AgenteN2__c;
                    String titulo = 'Rechazo de Solución Definitiva N2 para caso '+item.CaseNumber;
                    String descripcion = 'El agente Release '+ item.FS_UsuarioAprobacionSolucionRelease__c +' ha rechazado la Solución Definitiva N2 para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }
            }
        }
    }

    public static void validacionURLPlanPruebas(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_EnviarAprobacionPlanPruebas__c != item.FS_EnviarAprobacionPlanPruebas__c  && item.FS_EnviarAprobacionPlanPruebas__c == true){
                item.FS_SubEstado__c = 'Aprobación Plan de Pruebas';
                item.FS_AprobacionPlanPruebas__c = null;
                item.FS_MotivoRechazoPlanPruebas__c = null;
                item.FS_UsuarioAprobadorPlanPruebas__c = item.FS_UsuarioAprobadorPlanPruebas__c == null ? getUsuario(item) : item.FS_UsuarioAprobadorPlanPruebas__c;
                String titulo = 'Aprobación Plan de pruebas para caso '+item.CaseNumber;
                String descripcion = 'El agente '+item.FS_NombrePropietario__c + ' necesita Aprobación de Plan de pruebas para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                enviarNotificacion(item.FS_UsuarioAprobadorPlanPruebas__c, item.Id, titulo, descripcion);
				validarTareas(item);
            }
        }
    }

    public static void validacionAprobacionPlanPruebas(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AprobacionPlanPruebas__c != item.FS_AprobacionPlanPruebas__c){
                if(item.FS_AprobacionPlanPruebas__c == 'Si'){
                    item.FS_SubEstado__c = 'Aprobación Instalación Parche - Releases';
                    item.FS_AprobacionInstalacionParcheRelease__c = null;
                    item.FS_MotivosRechazoInstalacionParche__c = null;
                    item.FS_UsuarioAprobadorInstalacionParcheRele__c = null;
                    item.FS_ComentariosAprobacionInstalacionParch__c = null;
                }else if(item.FS_AprobacionPlanPruebas__c == 'No'){
                    item.FS_EnviarAprobacionPlanPruebas__c = false;
                    item.FS_SubEstado__c = 'Elaboración Plan de Pruebas';
                    String titulo = 'Rechazo Plan de pruebas para caso '+item.CaseNumber;
                    String descripcion = 'El agente '+UserInfo.getName() + ' ha rechazado el Plan de Pruebas para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }
            }
        }
    }

    public static void validacionAprobacionInstalacionRelease(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AprobacionInstalacionParcheRelease__c  != item.FS_AprobacionInstalacionParcheRelease__c ){
                if(item.FS_AprobacionInstalacionParcheRelease__c == 'Si'){
                    item.FS_SubEstado__c = 'Instalación Parche Releases';
                    item.OwnerId = item.FS_AgenteQA__c;
                }else if(item.FS_AprobacionInstalacionParcheRelease__c == 'No'){
                    item.FS_SubEstadoAnterior__c = item.FS_SubEstado__c;
                    item.FS_EnviarAprobacionSolucionDN2__c = false;
                    item.FS_SubEstado__c = 'Elaboración Solución Definitiva';
                    item.OwnerId = item.FS_AgenteN2__c;
                    String titulo = 'Rechazo de Instalación Parche - Releases para caso '+item.CaseNumber;
                    String descripcion = 'El agente ' + item.FS_UsuarioAprobadorInstalacionParcheRele__c  + ' ha rechazado la Instalación Parche - Releases para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }
            }
        }
    }

    public static void validacionURLAmbientePruebas(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_UrlAmbientePruebas__c != item.FS_UrlAmbientePruebas__c && String.isBlank(caso.FS_UrlAmbientePruebas__c)){
                item.FS_SubEstado__c = 'Certificación Parche QA';
            }
        }
    }

    public static void validacionURLEvidenciaPruebas(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_UrlEvidenciaPruebas__c != item.FS_UrlEvidenciaPruebas__c && String.isBlank(caso.FS_UrlEvidenciaPruebas__c)){
                item.FS_SubEstado__c = 'Aprobación Certificación Parche QA';
                String titulo = 'Aprobación Certificación Parche QA para caso '+item.CaseNumber;
                String descripcion = 'Se necesita Aprobación Certificación Parche QA para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                item.FS_AprobacionCertificacionParcheQA__c = null;
                item.FS_MotivoRechazoEntregaParche__c = null;
            }
        }
    }

    public static void validacionAprobacionCertificacionQA(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AprobacionCertificacionParcheQA__c != item.FS_AprobacionCertificacionParcheQA__c && item.FS_AprobacionCertificacionParcheQA__c != null){
                validarTareas(item);
                if(item.FS_AprobacionCertificacionParcheQA__c  == 'Si'){
                    item.FS_SubEstado__c = String.isBlank(caso.FS_URLParcheCliente__c) ? 'Entrega de Parche' : 'Instalación de Parche';
                    item.Status = String.isBlank(caso.FS_URLParcheCliente__c) ? item.Status : 'Validación de Respuesta (Cliente)';
                }else if(item.FS_AprobacionCertificacionParcheQA__c  == 'No'){
                    item.FS_EnviarAprobacionSolucionDN2__c = false;
                    item.FS_SubEstado__c = 'Elaboración Solución Definitiva';
                    item.OwnerId = item.FS_AgenteN2__c;
                    item.FS_SubEstadoAnterior__c = '';
                    String titulo = 'Rechazo de Certificación Parche QA para caso '+item.CaseNumber;
                    String descripcion = 'El agente ' + UserInfo.getName()  + ' ha rechazado la Certificación Parche QA para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }
                validarTareas(item);
            }
        }
    }

    public static void validacionUrlEntregaParche(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_URLParcheCliente__c  != item.FS_URLParcheCliente__c  && String.isBlank(caso.FS_URLParcheCliente__c)){
                item.FS_SubEstado__c = 'Instalación de Parche';
                item.Status = 'Validación de Respuesta (Cliente)';
                item.FS_AceptaRespuesta__c = null;
                item.FS_AceptaInstalacionParche__c = null;
                item.FS_MotivoRechazo__c = null;
                item.FS_ComentariosRespuesta__c = null;
                String descripcion = 'Estimado Cliente\n\n\nHemos entregado la respuesta al caso, la solución se encuentra disponible en la siguiente URL para su validación '+item.FS_URLParcheCliente__c +'\n\nTus comentarios son importantes para nosotros.\n\nGracias\nCustomer Care Team\n\nSaludos';
                insert new FeedItem(ParentId = item.Id, Body = descripcion, Visibility = 'AllUsers');
                envioCorreo(item, 'FS_ValidacionInformacionIncidenteDefinitivo', true);
            }
        }
    }

    public static void validacionAceptaInstalacionParche(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AceptaInstalacionParche__c != item.FS_AceptaInstalacionParche__c && item.FS_AceptaInstalacionParche__c != null){
                item.FS_AceptaRespuesta__c = item.FS_AceptaInstalacionParche__c;
                crearHistorialAprobaciones(item);
                if(item.FS_AceptaInstalacionParche__c == 'Si'){
                    item.FS_SubEstado__c = 'Paso a Producción';
                    item.FS_AceptaPaseProducion__c = null;
                    envioCorreo(item, 'FS_PaseProduccion', true);
                }else if(item.FS_AceptaInstalacionParche__c == 'No'){
                    item.FS_SubEstado__c = 'Elaboración Solución Definitiva'; 
                    item.Status = 'En Desarrollo';
                    item.FS_EnviarAprobacionDisenioTecnico__c = false;
                    item.FS_EnviarAprobacionSolucionDN2__c = false;
                    item.FS_EnviarAprobacionPlanPruebas__c = false;
                    item.FS_EnviarAprobacionSolucionIPN2__c  = false;
                    item.OwnerId = item.FS_AgenteN2__c;
                    String titulo = 'Rechazo de Instalación de Parche para caso No '+item.CaseNumber;
                    String descripcion = 'El cliente ' + item.FS_NombreCuenta__c  + ' ha rechazado la Instalación de Parche para el caso número '+item.CaseNumber +' \nPor favor dar seguimiento.';
                    enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
                }
            }
        }
    }

    public static void validacionAceptaPaseProduccion(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_AceptaPaseProducion__c  != item.FS_AceptaPaseProducion__c ){
                if(item.FS_AceptaPaseProducion__c == 'Si'){
                    item.Status = 'Pendiente de Respuesta CSAT';
                    item.FS_SubEStado__c = 'Paso a Producción Confirmado';
                    item.FS_EncuestaEnviada__c = true;
                    item.FS_FechaEnvioEncuesta__c = System.now();
                    envioCorreo(item, 'FS_Encuesta', true);
                    crearEncuesta(item);
                    envioCorreo(item, 'FS_PaseProduccionAceptado', false);
                }else if(item.FS_AceptaPaseProducion__c == 'No'){
                    item.FS_SubEstado__c = 'Paso a Producción No Confirmado';
                    String rollUsuario = productoCore(item) ? 'FS_JefeCore' : 'FS_JefeOmnia';
                    String titulo = 'Pase a Producción rechazado para caso No '+item.CaseNumber;
                    String descripcion = 'Buen día\n\n Se ha rechazado el pase a producción del caso No ' + item.CaseNumber +' \nPor favor dar seguimiento.';
                    for(String userId: mapUser.keySet()){
                        User u = mapUser.get(userId);
                        if(u.UserRole.DeveloperName == rollUsuario){
                            enviarNotificacion(u.Id, item.Id, titulo, descripcion);
                        }
                    }                    
                }
            }
        }
    }

    public static void validacionIngProducto(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            Case caso = oldCaseMap.get(item.Id);
            String titulo = 'Asignación de caso No. '+item.CaseNumber;
            String descripcion = 'El agente ' + UserInfo.getName()  + ' le ha asignado el caso '+item.CaseNumber +' \nPor favor dar seguimiento.';
            if(caso.FS_IngenieroProducto__c  != item.FS_IngenieroProducto__c && caso.FS_IngenieroProducto__c != null){
                item.OwnerId = caso.FS_IngenieroProducto__c;
                enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
            }
            if(caso.FS_IngenieroProductoQA__c  != item.FS_IngenieroProductoQA__c && caso.FS_IngenieroProductoQA__c != null){
                item.OwnerId = caso.FS_IngenieroProductoQA__c;
                enviarNotificacion(item.OwnerId, item.Id, titulo, descripcion);
            }
        }
    }

    public static void asignarAprobadorActual(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for(Case item: newCaseList){
            item.FS_AprobadorActual__c = null;
            if(item.FS_SubEstado__c == 'Aprobación Solución IP-N2'){
                item.FS_AprobadorActual__c = item.FS_UsuarioAprobadorSolucionIPN2__c;
            }else if(item.FS_SubEstado__c == 'Aprobación Diseño Técnico' || item.FS_SubEstado__c == 'Aprobación Solución Definitiva N2'){
                item.FS_AprobadorActual__c = item.FS_UsuarioAprobadorDT__c;
            }else if(item.FS_SubEstado__c == 'Aprobación Plan de Pruebas'){
                item.FS_AprobadorActual__c = item.FS_UsuarioAprobadorPlanPruebas__c;
            }else if(item.FS_SubEstado__c == 'Aprobación Certificación Parche QA'){
                item.FS_AprobadorActual__c = item.OwnerId;
            }else if(item.FS_SubEstado__c == 'Aprobación Consulta N2' || item.FS_SubEstado__c == 'Aprobación Solicitud N2'){
                item.FS_AprobadorActual__c = item.FS_UsuarioAprobadorSolucion__c;
            }
        }
    }

    public static void historialCaso(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
        String camposEstandar = 'Subject,ParentId,Description,Status,Type';
        String camposCustom = 'FS_RolPropietario__c,FS_DescripcionCliente__c';
        List<FS_HistorialCampos__c > listHistorial = new List<FS_HistorialCampos__c >();
        for(Schema.SObjectField sfield : fieldMap.Values()){
            schema.describefieldresult dfield = sfield.getDescribe();
            String apiCampo = dfield.getName();
            if(camposEstandar.contains(apiCampo) || (apiCampo.contains('__c') && !camposCustom.contains(apiCampo))){
                for(Case item: newCaseList){
                    String valorOriginal = String.valueOf(oldCaseMap.get(item.Id).get(apiCampo));
                    String valorNuevo = String.valueOf(item.get(apiCampo));
                    String tipoCampo = String.valueOf(dfield.getType());
                    if(valorOriginal != valorNuevo){
                        if(tipoCampo == 'DATETIME'){
                            valorOriginal = valorOriginal != null ? String.valueOf(DateTime.valueOf( valorOriginal ).format() ) : valorOriginal;
                            valorNuevo = valorNuevo != null ? String.valueOf( DateTime.valueOf( valorNuevo ).format() ) : valorNuevo;
                        }else if(tipoCampo == 'DATE'){
                            valorOriginal = valorOriginal != null ? String.valueOf(Date.valueOf( valorOriginal ).format() ) : valorOriginal;
                            valorNuevo = valorNuevo != null ? String.valueOf( Date.valueOf( valorNuevo ).format() ) : valorNuevo;
                        }
                        listHistorial.add(new FS_HistorialCampos__c(
                            FS_Caso__c = item.Id,
                            FS_NombreCampo__c  = dfield.getLabel(),
                            FS_NombreApiCampo__c  = apiCampo,
                            FS_ValorOriginal__c  = valorOriginal,
                            FS_ValorNuevo__c = valorNuevo));
                    }
                }
            }
        }
        DataBase.insert(listHistorial, false);
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

    public static void historialCaso(List<Case> newCaseList){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
        List<FS_HistorialCampos__c > listHistorial = new List<FS_HistorialCampos__c >();
        for(Case item: newCaseList){
            listHistorial.add(new FS_HistorialCampos__c(
                FS_Caso__c = item.Id,
                FS_NombreCampo__c  = 'Fecha de creación',
                FS_NombreApiCampo__c  = 'CreatedDate',
                FS_ValorOriginal__c  = null,
                FS_ValorNuevo__c = String.valueOf( DateTime.valueOf( item.CreatedDate ).format() ))); 
        }
        DataBase.insert(listHistorial, false); 
    }

    public static Id getUsuario(Case caso) {
        Id userId;

        List<User> updateUser = new List<User>();
        for(User usuario : [Select Id, FS_FechaUltimaAprobacion__c from User where UserRoleId = :caso.FS_RolPropietario__c And Id != :caso.OwnerId and IsActive = true Order by FS_FechaUltimaAprobacion__c asc limit 1]){
            usuario.FS_FechaUltimaAprobacion__c = System.now();
            updateUser.add(usuario);
            userId = usuario.Id;
        }

        if(!updateUser.isEmpty()) {
          update updateUser;
        }

        return userId;
    }
    
    public static Boolean productoCore(Case caso){
        return caso.FS_Producto__c == 'Fisa System' || caso.FS_Producto__c == 'Fisa CreditCard' || caso.FS_Producto__c == 'FISA FISS';
    }
    
    public static void upsertCaseJira(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<Case> casesNewIP = new List<Case>();
        List<Case> casesNewID = new List<Case>();
        Map<Id, Case> casesOldIP = new Map<Id, Case>();
        Map<Id, Case> casesOldID = new Map<Id, Case>();

        List<Case> casesNewUpdateIP = new List<Case>();
        List<Case> casesNewUpdateID = new List<Case>();
        Map<Id, Case> casesOldUpdateIP = new Map<Id, Case>();
        Map<Id, Case> casesOldUpdateID = new Map<Id, Case>();

        for(Case item: newCaseList){   
            Case caso = oldCaseMap.get(item.Id);
            if(caso.FS_SubEstado__c != item.FS_SubEstado__c && item.FS_TipoIncidente__c == 'Puntual'){
                if(item.FS_SubEstado__c == 'Desarrollo Incidente Puntual' && (caso.FS_SubEstado__c == 'Revisión Documentación N2' || caso.FS_SubEstado__c == 'Escalado a N2')){
                    casesNewIP.add(item);
                    casesOldIP.put(caso.Id, caso);
                    CreateJiraRecord.createJira(casesNewIP, casesOldIP);
                }else if(item.FS_SubEstado__c == 'Aprobación de Solución IP-Release' || item.FS_SubEstado__c == 'Aprobación Solución IP-N2' ||
                    item.FS_SubEstado__c == 'Desarrollo Incidente Puntual'){
                    casesNewUpdateIP.add(item);
                    casesOldUpdateIP.put(caso.Id, caso);
                    CreateJiraRecord.updateIssueJira(casesNewUpdateIP, casesOldUpdateID);
                }
            }

            if(caso.FS_SubEstado__c != item.FS_SubEstado__c && item.FS_TipoIncidente__c == 'Definitivo') {
                if(item.FS_SubEstado__c == 'Desarrollo Incidente Definitivo' && (caso.FS_SubEstado__c == 'Revisión Documentación N2' || caso.FS_SubEstado__c == 'Escalado a N2')){
                    casesNewID.add(item);
                    casesOldID.put(caso.Id, caso);
                    CreateJiraRecord.createJira(casesNewID, casesOldID);
                } else if(item.FS_SubEstado__c == 'Validación-Entrega de Fuentes' || item.FS_SubEstado__c == 'Elaboración Diseño Técnico' ||
                            item.FS_SubEstado__c == 'Aprobación Solución Definitiva Releases' || item.FS_SubEstado__c == 'Elaboración Solución Definitiva' ||
                            item.FS_SubEstado__c == 'Escalado a QA' || item.FS_SubEstado__c == 'Instalación Parche Releases' ||
                            item.FS_SubEstado__c == 'Elaboración Plan de Pruebas' || item.FS_SubEstado__c == 'Certificación Parche QA' ||
                            item.FS_SubEstado__c == 'Validación-Entrega de Fuentes' || item.FS_SubEstado__c == 'Entrega de Parche' ||
                            item.FS_SubEstado__c == 'Paso a Producción' || item.FS_SubEstado__c == 'Paso a Producción No Confirmado' ||
                            item.FS_SubEstado__c == 'Paso a Producción Confirmado' || item.FS_SubEstado__c == 'Desarrollo Incidente Definitivo' ||
                            item.FS_SubEstado__c == 'Aprobación Diseño Técnico' || item.FS_SubEstado__c == 'Aprobación Solución Definitiva N2'||
                            item.FS_SubEstado__c == 'Aprobación Instalación Parche - Releases' || item.FS_SubEstado__c == 'Aprobación Plan de Pruebas' ||
                            item.FS_SubEstado__c == 'Aprobación Certificación Parche QA' || item.FS_SubEstado__c == 'Instalación de Parche'){
                                casesNewUpdateID.add(item);
                                casesOldUpdateID.put(caso.Id, caso);
                                CreateJiraRecord.updateIssueJira(casesNewUpdateID, casesOldUpdateID);
                }
            }
        }   
    }

    public static void envioCorreo(Case caso, String nombrePlantilla, Boolean esContacto){
        try{
            if(esContacto && caso.FS_OrigenCaso__c != 'Web'){
                return;
            }
            List<Messaging.SingleEmailMessage> MessageList = new List<Messaging.SingleEmailMessage>();
            EmailTemplate plantilla = mapPlantillas.get(nombrePlantilla);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String asunnto = reemplazarCampos(caso, plantilla.Subject, 'Case');
            String html = reemplazarCampos(caso, plantilla.HTMLValue, 'Case');
            String urlLogo = getLogoImagen();
            html = getLogoImagen() + html.replace('{urlSiteServicios}', Label.FS_UrlPortalServicios);
            html = html.replace('{urlSiteEncuestas}', Label.FS_UrlPortalEncuestas);
            html = html.replace('{urlSalesforceOrg}', Label.FS_urlSalesforceOrg);
            html = html.replace(']]>', '') + '</td><td style="width: 25%;" /></table></body></html>';
            html = html.replace('<![CDATA[', '');
            mail.setSubject(asunnto);
            mail.setHtmlBody(html);
            //mail.saveAsActivity = esContacto;
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setSaveAsActivity(true);
            mail.setWhatId(caso.Id);

            if(esContacto){
                User usuario = mapUser.get(userInfo.getUserId());
                if(usuario.Profile.Name != 'Customer Community User' || usuario.Profile.Name != 'Customer Community Plus User'){
                    //mail.setWhatId(caso.Id);
                    //mail.setSaveAsActivity(true);
                }

                mail.setTargetObjectId(caso.ContactId);
                String allMails = ' ';
                if(String.isNotBlank(caso.FS_CorreosNotificacionesServicios__c)){
                    if(String.isNotBlank(caso.FS_Correos_Notificaciones_PS__c) && caso.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO) {
                        allMails = caso.FS_CorreosNotificacionesServicios__c + ',' + caso.FS_Correos_Notificaciones_PS__c;
                    }else{
                        allMails = caso.FS_CorreosNotificacionesServicios__c;
                    }                
                    mail.setCcAddresses(allMails.split(','));
                }
            } else {
                User usuario = mapUser.get(caso.OwnerId);
                mail.setBccAddresses( nombrePlantilla != 'FS_PaseProduccionAceptado' ? new List<String>{usuario.Email} : Label.FS_CorreosPaseProduccionAceptado.split(','));
                if(caso.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO && caso.Status == 'Cerrado' && caso.FS_FechaContestacionEncuesta__c != null) {
                    mail.setCcAddresses(Label.FS_KAM_Email.split(','));    
                }
            }
            MessageList.add(mail);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(MessageList);
        } catch(Exception ex) {
            System.debug(ex.getMessage()+'Error Correo ----- '+ex.getLineNumber());
        }
    }

    /**
     * @method      enviarNotificacion
     * @description Method to send email notification
     * @author      Intellect Systems - 2023-07-18
     * @param       usuarioId
     * @param       recordId
     * @param       titulo
     * @param       descripcion
     */
    public static void enviarNotificacion(String usuarioId, String recordId, String titulo, String descripcion) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(titulo);
        notification.setBody(descripcion);
        notification.setNotificationTypeId(notificacion.Id);
        notification.setTargetId(recordId); 
        notification.send(new Set<String> { usuarioId }); 

        List<Messaging.SingleEmailMessage> MessageList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        EmailTemplate plantilla = mapPlantillas.get('FS_NotificacionInterna');

        String baseUrl = URL.getOrgDomainUrl().toExternalForm() + '/' + recordId;
        String urlLogo = getLogoImagen();
        String asunnto = titulo;
        String html = plantilla.HTMLValue.replace('{contenido}', descripcion.replace('\n', '<br/>'));
        html = html.replace('{linkRecord}', baseUrl);
        html = getLogoImagen() + html;
        html = html.replace(']]>', '') + '</td><td style="width: 25%;" /></table></body></html>';
        html = html.replace('<![CDATA[', '');
        mail.setSubject(titulo);
        mail.setHtmlBody(html);
        mail.saveAsActivity = true;
        mail.setWhatId(recordId);
        mail.setOrgWideEmailAddressId(owea.Id);

        try{
            User usuario = !Test.isRunningTest() ? mapUser.get(usuarioId) : new User(Email = Label.FS_CorreoElectronicoServicio);
            mail.setBccAddresses(  new List<String>{usuario.Email});
            MessageList.add(mail);          
            Messaging.SendEmailResult[] results = Messaging.sendEmail(MessageList);
        }catch(Exception ex){
            System.debug(ex.getMessage()+' ----- '+ex.getLineNumber());
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

    public static void validarTareas(Case caso){
        if([Select count() from Task where WhatId = :caso.Id and Status != 'Finalizada'] > 0){
            caso.addError('El caso no se puede escalar ya que tiene tareas pendiente por cerrar.');
        }
    }

    public static String getLogoImagen(){
        StaticResource staticResource = [   SELECT Id, SystemModStamp, Name, Body
                                            FROM StaticResource 
                                            WHERE Name = 'FS_FisaLogo'
                                            LIMIT 1];
                                            
        String urlRecurso = '<html xmlns="http://www.w3.org/1999/xhtml"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta  name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0," /></head><body>';
        urlRecurso += '<table width="100%" ><td style="width: 25%;" /><td style="width: 50%;" ><table><tr><td><img src="';
        urlrecurso += 'data:image/png;base64,' + EncodingUtil.base64Encode(staticResource.Body);
        urlRecurso += '"/></td></tr></table>';
        return urlRecurso;
    }

    public static String reemplazarCampos(Case caso, String html, String objeto){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objeto).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.Values()){
            schema.describefieldresult dfield = sfield.getDescribe();
            String campo = dfield.getname();
            String objCampo = '{!' + objeto + '.' + campo +'}';
            if(html.contains(objCampo)){
                String valorCampo = caso.get(campo) != null ? String.valueOf(caso.get(campo)) : '';
                html = html.replace(objCampo, valorCampo);
            }
        }
        return html;
    }

    public static Id entitlementCaseId(string recordTypeName){
        List<Entitlement> ltsEntitlement = new List<Entitlement>();
        List<recordtype> ltsrecordtype = new List<recordtype>();

        ltsEntitlement = [  SELECT  Id, Name 
                            FROM    Entitlement    ];

        ltsrecordtype = [   SELECT  Id, Name 
                            FROM    Recordtype 
                            WHERE   Id =: recordTypeName    ];

        String Consulta;
        String consultaCliente;
        String Incidente;
        id entitlementId;
        String nameRT;

        for(recordtype recordTypeList: ltsrecordtype){
            nameRT = recordTypeList.Name;
        }

        for(Entitlement lstEMT: ltsEntitlement){
            if(lstEMT.Name == 'SLA Consulta'){
                Consulta = lstEMT.id;
            }else if(lstEMT.Name == 'SLA Incidente'){
                Incidente = lstEMT.id;
            }else if(lstEMT.Name == 'SLA Consulta - Cliente'){
                consultaCliente = lstEMT.id;
            }
        }

        if(nameRT == 'Consulta'){
            entitlementId = Consulta;
        }else if(nameRT == 'Incidente'){
            entitlementId = Incidente;
        }

        return entitlementId;

    }

    public static void esCliente(List<Case> newCaseList) {
        try{
            set<Id> caseId = new set<id>();
            set<Id> accId = new set<id>();
            String SubEstado;

            for(Case lstCase: newCaseList) {
                if(REQUERIMIENTO_TIPO_REGISTRO != lstCase.RecordTypeId) {
                    caseId.add(lstCase.Id);
                    accId.add(lstCase.AccountId);
                    SubEstado = lstCase.FS_SubEstado__c;
                }    
            }

            if(!caseId.isEmpty()) {    
                Case c = [  SELECT  Priority, RecordType.Name, FS_SubEstado__c, AccountId 
                            FROM    Case 
                            WHERE   Id =: caseId    ];

                FS_ConfiguracionSLA__c slaLs = [    SELECT  Id, FS_NombreDeCuenta__c, FS_NombreTipoRegistro__c, FS_SLA__c, FS_SubEstado__c, FS_EsCliente__c, FS_Activo__c 
                                                    FROM    FS_ConfiguracionSLA__c 
                                                    WHERE   FS_Activo__c = true AND FS_NombreTipoRegistro__c =: c.RecordType.Name AND FS_SubEstado__c INCLUDES(:SubEstado) AND FS_NombreDeCuenta__c =:accId limit 1    ];

                for(Case lstCase: newCaseList){
                    if(slaLs.FS_EsCliente__c == true){
                        lstCase.FS_Es_cliente__c = true;  
                    }else if(slaLs.FS_EsCliente__c == false){
                        lstCase.FS_Es_cliente__c = false;
                    }
                    
                }
            }    
        } catch(Exception ex) {
            System.debug('Error en helper de casos: '+ex.getLineNumber()+'--'+ex.getMessage());
        }

    }

    /**
     * @method      assignDeliveryDate
     * @description Method that assigns value in the called field: Fecha de entrega. 
     * @author      Intellect Systems - 2024-03-26
     * @param       newCaseList
     * @param       oldCaseMap 
     */
    public static void assignDeliveryDate(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        for(Case record : newCaseList) {
            if(record.FS_Fecha_de_entrega__c == null && record.Status == 'Validación de Respuesta (Cliente)') {
                record.FS_Fecha_de_entrega__c = record.LastModifiedDate.date();
            }
        }
    }

    public static void validacionAgenteN2(List<Case> newCaseList) {
        for(Case record : newCaseList) {
            if(record.OwnerId.getSobjectType() != Group.SobjectType && record.FS_Area__c != 'QA CC-CORE' && record.FS_Area__c != 'QA CC-OMNIA' ){
                record.FS_AgenteN2__c = record.OwnerId;
            }else if(record.OwnerId.getSobjectType() != Group.SobjectType && record.FS_Area__c == 'QA CC-CORE' && record.FS_Area__c == 'QA CC-OMNIA' ){
                record.FS_AgenteQA__c = record.OwnerId;
            }
        }
    }
}