/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             ControladorCrearCaso
* @description      Class to create case since community
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2023-07-18   Intellect Systems             Initial version.
* 2024-01-25   Intellect Systems             Se añade asignación al Project Manager para casos de tipo de Requerimiento desde la comunidad, ajuste en el Método: guardarCaso.
* 2024-01-26   Intellect Systems             Se añade el paso de los correos al campo en el caso , para el envio de los correos en la cuentas listadas.
* 2024-01-29   Intellect Systems             Se añade área PS, si el caso es de tipo: Requerimiento.
* 2024-04-26   Intellect Systems             Se añade filtro en método: getProductosAdquiridos, para mostrar solo los productos activos.
**************************************************************************************************************
*/

public without sharing class ControladorCrearCaso {

    /**
     * @method      getProductosAdquiridos
     * @description Consult the products related to the account
     * @author      Intellect Systems - 2023-18-07
     * @return      ContactoWrapper
     */
    @AuraEnabled
    public static ContactoWrapper getProductosAdquiridos(){
        ContactoWrapper respuesta = new ContactoWrapper();
        user usuario = [    SELECT  Id, Alias, ContactId, Contact.AccountId 
                            FROM    User  
                            WHERE   Id = :userInfo.getUserId()  ];

        respuesta.contactId = usuario.ContactId;
        respuesta.cuentaId = usuario.Contact.AccountId;
        respuesta.listTodosProductos = new List<Producto>();
        respuesta.listTiporegistro = new List<PickListOption>();
        for(FS_ProductoAdquirido__c item: [ SELECT  FS_Producto__c, FS_Modulo__c, FS_SubModulo__c 
                                            FROM    FS_ProductoAdquirido__c 
                                            WHERE   FS_Cuenta__c =: respuesta.cuentaId and FS_Esta_activo__c = true ]) {

            Producto p = new Producto();
            p.producto = item.FS_Producto__c;
            p.modulo = item.FS_Modulo__c;
            p.subModulo = item.FS_SubModulo__c;
            respuesta.listTodosProductos.add(p);
        }
        for(RecordType item : [ SELECT  Id, Name 
                                FROM    RecordType 
                                WHERE   SObjectType = 'Case' AND IsActive = true AND name != 'Control de Cambios' 
                                AND name != 'Tiempo y Materiales' AND name != 'Tiempo y Materiales - Con Sprints'
                                Order by Name asc  ]) {

            PickListOption p = new PickListOption();
            p.value = item.Id;
            p.label = item.Name;
            respuesta.listTiporegistro.add(p);
        }
        respuesta.listMotivo = getPickListOption('Case', 'Reason');
        return respuesta;
    }
    
    /**
     * @method      getCaso
     * @description Get case record
     * @author      Intellect Systems - 2023-18-07
     * @param       casoId       
     * @return      CasoWrapper
     */
    @AuraEnabled
    public static CasoWrapper getCaso(String casoId){
        CasoWrapper respuesta = new CasoWrapper();
        respuesta.caso = DataBase.query(getQueryCaso() + ' Where Id = :casoId');
        respuesta.listAceptaRespuesta = getPickListOption('Case', 'FS_AceptaRespuesta__c');
        respuesta.listMotivosRechazo = getPickListOption('Case', 'FS_MotivoRechazo__c');
        respuesta.listMotivosRechazoParche = getPickListOption('Case', 'FS_MotivosRechazoInstalacionParche__c');
        respuesta.listTipoAprobacion = getPickListOption('Case', 'FS_Tipo_de_Aprobacion__c');
        return respuesta;
    }
    
    /**
     * @method      getCasos
     * @description Get case record by user
     * @author      Intellect Systems - 2023-18-07
     * @return      ListCasos
     */
    @AuraEnabled
    public static ListCasos getCasos(){
        user usuario = [    SELECT  ContactId, Contact.AccountId 
                            FROM    User 
                            WHERE   Id = :userInfo.getUserId()    ];

        return queyCasos(usuario.Contact.AccountId);
    }
    
    /**
     * @method      queyCasos
     * @description Consult case record list
     * @author      Intellect Systems - 2023-18-07
     * @param       recordId   
     * @return      ListCasos
     */
    public static ListCasos queyCasos(Id recordId){
        ListCasos lista = new ListCasos ();
        lista.casosAbiertos = new List<Case>();
        lista.casosCerrados = new List<Case>();
        lista.casosMostrados = new List<Case>();
        DateTime hoy = DateTime.now().addDays(-5);
        for(Case item: DataBase.query(getQueryCaso() + ' Where AccountId = \'' + recordId + '\'  and FS_OrigenCaso__c = \'Web\' order By CreatedDate desc ')){
            item.FS_DescripcionCLiente__c = String.isNotBlank(item.FS_DescripcionCLiente__c) ? item.FS_DescripcionCLiente__c : '';
            item.FS_DescripcionCLiente__c = item.FS_DescripcionCLiente__c.stripHtmlTags();
            item.Status = item.FS_SubEstado__c == 'En Espera de Respuesta del Cliente' ? 'Pendiente Respuesta Cliente' : item.Status;
            if(item.Status == 'Validación de Respuesta (Cliente)'){
                item.Status = 'Entregado';    
            }
            if(item.IsClosed){
                lista.casosCerrados.add(item);
            }else if(!item.IsClosed){
                lista.casosAbiertos.add(item);
            }
            if(item.LastModifiedDate > hoy && lista.casosMostrados.size() < 50){
                lista.casosMostrados.add(item);
            }
        }
        return lista;
    }
    
    /**
     * @method      getQueryCaso
     * @description Get case fields
     * @author      Intellect Systems - 2023-18-07
     * @return      String
     */
    public static String getQueryCaso(){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
        String query = 'Select Contact.Name,';
        for(Schema.SObjectField sfield : fieldMap.Values()){
            schema.describefieldresult dfield = sfield.getDescribe();
            query += dfield.getName() + ',';
        }
        return  query.substring(0, query.length() - 1) + ' From Case ';
    }
    
    /**
     * @method      guardarCaso
     * @description Save case record
     * @author      Intellect Systems - 2023-18-07
     * @param       casoJSON  
     * @param       archivosJSON  
     * @return      Id
     */
    @AuraEnabled
    public static Id guardarCaso(String casoJSON, String archivosJSON){
        List<String> listContentDocumentId = new List<String>();
        Case caso = (Case) JSON.deserialize(casoJSON, Case.class);
        Boolean crearCaso = String.isBlank(caso.Id);
        
        List<String> listRecordType = new List<String>();
        listRecordType.add(Schema.SObjectType.Case.RecordTypeInfosByDeveloperName.get('FS_Requerimiento').RecordTypeId);
        listRecordType.add(Schema.SObjectType.Case.RecordTypeInfosByDeveloperName.get('FS_TiempoMateriales').RecordTypeId);
        
        if(crearCaso){
            user usuario = [    SELECT  Contact.Account.FS_Carterizacion__c, Contact.Account.FS_ServicioRemoto__c, Contact.Account.FS_ColaAtencion__c, Contact.Account.FS_CorreosNotificacionesServicios__c, Contact.Account.FS_Correos_Notificaciones_PS__c  
                                FROM    user  
                                WHERE   Id =: userInfo.getUserId()    ];

            Boolean esCore = CaseTriggerHelper.ProductoCore(caso);
            if(!listRecordType.contains(caso.RecordTypeId)) {
                caso.FS_Area__c = esCore ? 'N1. CORE' : 'N1. OMNIA';
            } else {
                caso.FS_Area__c = 'PS';
            }
            caso.FS_Carterizacion__c = usuario.Contact.Account.FS_Carterizacion__c;
            caso.FS_CorreosNotificacionesServicios__c = usuario.Contact.Account.FS_CorreosNotificacionesServicios__c;
            caso.FS_Correos_Notificaciones_PS__c = usuario.Contact.Account.FS_Correos_Notificaciones_PS__c;
            caso.EntitlementId = CaseTriggerHelper.entitlementCaseId(caso.RecordTypeId);
            caso.FS_FechaEstadoActual__c = System.now();
            caso.FS_FechaSubEstadoActual__c = System.now();

            if(!listRecordType.contains(caso.RecordTypeId)) {
                if(usuario.Contact.Account.FS_ServicioRemoto__c){
                    caso.OwnerId = [Select Id from Group Where DeveloperName = :usuario.Contact.Account.FS_ColaAtencion__c and Type = 'Queue'].Id;
                }else{
                    caso.OwnerId = [Select Id from Group Where DeveloperName = :(esCore ? CaseTriggerHelper.COLA_ATENCION_N1_CORE : CaseTriggerHelper.COLA_ATENCION_N1_OMNIA) and Type = 'Queue'].Id;
                }
            } else {                
                map<String, FS_Gestor_Cuenta__c> mapRecords = new map<String, FS_Gestor_Cuenta__c>([	SELECT 	Id, FS_Project_Manager__c  
                                                                                                        FROM 	FS_Gestor_Cuenta__c
                                                                                                        WHERE 	FS_Cuenta__c =: caso.AccountId and FS_Principal__c =: true	 ]);
                
				if(listRecordType.contains(caso.RecordTypeId) && mapRecords.size() > 0) {	
                    for(Id key : mapRecords.keySet()) {
                        caso.OwnerId = mapRecords.get(key).FS_Project_Manager__c;    
                    }
                }   
            }

            caso.FS_OrigenCaso__c = 'Web';
            caso.FS_SubEstado__c = 'Apertura de caso';
            caso.Origin = caso.FS_SubEstado__c;
            for(PickListOption item: (List<PickListOption>) JSON.deserialize(archivosJSON, List<PickListOption>.class)){
                listContentDocumentId.add(item.value);
            }
        }

        //Assigning default value to the field: Tipo de Aprobacion
        if(caso.FS_Acepta_Propuesta_Economica__c == 'Si' && caso.Status == 'En Propuesta Económica') {
            caso.FS_Tipo_de_Aprobacion__c = 'Propuesta Económica';
            caso.FS_DiasProyecto__c = caso.FS_DiasAprobacionPropuestaEconomica__c;
            caso.FS_Fecha_Aprobacion_PE__c = System.now();
        }
        if(caso.FS_AceptaAnalisisPrevio__c == 'Si' && caso.Status == 'Análisis Previo') {
            caso.FS_Tipo_de_Aprobacion__c = 'Análisis Previo';
            caso.FS_DiasProyecto__c = caso.FS_DiasAprobacionAnalisisPrevio__c;
            caso.FS_AceptaRespuesta__c = 'Si';
        }
        if(caso.FS_AceptaPropuestaServicio__c == 'Si' && caso.Status == 'Propuesta de Servicio') {
            caso.FS_Tipo_de_Aprobacion__c = 'Aprobación de Propuesta de Servicio';
            caso.FS_DiasProyecto__c = caso.FS_DiasAprobacionPropuestaServicio__c;
            caso.FS_AceptaRespuesta__c = 'Si';
        }
        if(caso.FS_AceptaEstimacionMacro__c == 'Si' && caso.Status == 'Estimación Macro') {
            caso.FS_Tipo_de_Aprobacion__c = 'Estimación Macro';
            caso.FS_DiasProyecto__c = caso.FS_DiasAprobacionEstimacionMacro__c;
            caso.FS_AceptaRespuesta__c = 'Si';
        }
        if(caso.FS_AceptaDEF__c == 'Si' && caso.Status == 'Documento de Especificación Funcional') {
            caso.FS_Tipo_de_Aprobacion__c = 'Documento de Especificación Funcional';
            caso.FS_AceptaRespuesta__c = 'Si';
        }
        if(caso.FS_AceptaRespuesta__c == 'Si' && caso.Status == 'Validación de Respuesta (Cliente)' && caso.FS_NombreTipoRegistro__c != 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'Aceptación Solución';
        }
        if(caso.FS_AceptaRespuesta__c == 'Si' && caso.Status == 'Validación de Respuesta (Cliente)' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'Entregado';
        }
        if(caso.FS_AceptaRespuesta__c == 'Si' && caso.Status == 'En Revisión Entregado' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'En Revisión Entregado';
        }
        if(caso.FS_Fecha_Puesta_en_Produccion__c != null && caso.Status == 'Certificado' && caso.FS_NombreTipoRegistro__c != 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'Puesta en Producción';
        }
        if(caso.FS_AceptaSolucionEnProduccion__c == 'Si' && caso.Status == 'Certificado' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'Certificado';
            caso.FS_AceptaRespuesta__c = 'Si';
        }
        if(caso.FS_AceptaSolucionEnProduccion__c == 'Si' && caso.Status == 'En Revisión Certificado' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'En Revisión Certificado';
            caso.FS_AceptaRespuesta__c = 'Si';
        }
        if(caso.FS_Quiere_Finalizar_la_Atencion_del_Caso__c == true && caso.Status == 'En Producción' && caso.FS_NombreTipoRegistro__c != 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'Finalizar Atención';
        }
        if(caso.FS_AceptacionSolucionSalesforce__c == 'Si' && caso.Status == 'En Producción' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'En Producción';
            caso.FS_AceptaRespuesta__c = 'Si';
        }
        if(caso.FS_AceptacionSolucionSalesforce__c == 'Si' && caso.Status == 'En Revisión en Producción' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'En Revisión en Producción';
            caso.FS_AceptaRespuesta__c = 'Si';
        }
        
        if(caso.FS_Acepta_Propuesta_Economica__c == 'No' && caso.Status == 'En Propuesta Económica') {
            caso.FS_Tipo_de_Aprobacion__c = 'Propuesta Económica';
            caso.FS_AceptaRespuesta__c = 'No';
            caso.FS_DiasProyecto__c = caso.FS_DiasAprobacionPropuestaEconomica__c;
            caso.FS_Fecha_Aprobacion_PE__c = System.now();
        }
        if(caso.FS_AceptaEstimacionMacro__c == 'No' && caso.Status == 'Estimación Macro') {
            caso.FS_Tipo_de_Aprobacion__c = 'Estimación Macro';
            caso.FS_AceptaRespuesta__c = 'No';
            caso.FS_DiasProyecto__c = caso.FS_DiasAprobacionEstimacionMacro__c;
        }
        if(caso.FS_AceptaAnalisisPrevio__c == 'No' && caso.Status == 'Análisis Previo') {
            caso.FS_Tipo_de_Aprobacion__c = 'Análisis Previo';
            caso.FS_AceptaRespuesta__c = 'No';
            caso.FS_DiasProyecto__c = caso.FS_DiasAprobacionAnalisisPrevio__c;
        }
        if(caso.FS_AceptaPropuestaServicio__c == 'No' && caso.Status == 'Propuesta de Servicio') {
            caso.FS_Tipo_de_Aprobacion__c = 'Rechazo de Propuesta de Servicio';
            caso.FS_AceptaRespuesta__c = 'No';
            caso.FS_DiasProyecto__c = caso.FS_DiasAprobacionPropuestaServicio__c;
        }
        if(caso.FS_AceptaDEF__c == 'No' && caso.Status == 'Documento de Especificación Funcional') {
            caso.FS_Tipo_de_Aprobacion__c = 'Documento de Especificación Funcional';
            caso.FS_AceptaRespuesta__c = 'No';
        }
        if(caso.FS_AceptaRespuesta__c == 'No' && caso.Status == 'Validación de Respuesta (Cliente)' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'Entregado';
            caso.FS_AceptaRespuesta__c = 'No';
        }
        if(caso.FS_AceptaRespuesta__c == 'No' && caso.Status == 'En Revisión Entregado' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'En Revisión Entregado';
            caso.FS_AceptaRespuesta__c = 'No';
        }
        if(caso.FS_AceptaSolucionEnProduccion__c == 'No' && caso.Status == 'Certificado' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'Certificado';
            caso.FS_AceptaRespuesta__c = 'No';
        }
        if(caso.FS_AceptaSolucionEnProduccion__c == 'No' && caso.Status == 'En Revisión Certificado' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'En Revisión Certificado';
            caso.FS_AceptaRespuesta__c = 'No';
        }
        if(caso.FS_AceptacionSolucionSalesforce__c == 'No' && caso.Status == 'En Producción' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'En Producción';
            caso.FS_AceptaRespuesta__c = 'No';
        }
        if(caso.FS_AceptacionSolucionSalesforce__c == 'No' && caso.Status == 'En Revisión en Producción' && caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
            caso.FS_Tipo_de_Aprobacion__c = 'En Revisión en Producción';
            caso.FS_AceptaRespuesta__c = 'No';
        }
        

        upsert caso;
        if(crearCaso){
            recuperArchivo(caso, listContentDocumentId);
        }
        return caso.Id;
    }
    
    /**
     * @method      recuperArchivo
     * @description Deletec ContentDocumentLink record
     * @author      Intellect Systems - 2023-18-07
     * @param       caso 
     * @param       listContentDocumentId 
     */
    public static void recuperArchivo(Case caso, List<String> listContentDocumentId){
        list<Id> listIds = new  list<Id>();
        list<Id> listDocumentos = new  list<Id>();
        listIds.add(caso.ContactId);
        
        List<ContentDocumentLink> listArchivos = [Select Id,LinkedEntityId, ContentDocumentId from ContentDocumentLink Where LinkedEntityId in :listIds and ContentDocumentId in :listContentDocumentId];
        for(ContentDocumentLink item: listArchivos){
            listDocumentos.add(item.ContentDocumentId);
        }
        for(ContentVersion item: [Select ContentDocumentId from ContentVersion Where ContentDocumentId in :listDocumentos]){
            try{
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = item.ContentDocumentId;
                cdl.LinkedEntityId = caso.Id;
                cdl.ShareType = 'V';
                insert cdl;
            }catch(Exception ex){
                System.debug('Error: '+ex.getMessage());
            }
        }
        delete listArchivos;
    }
    
    /**
     * @method      getPickListOption
     * @description get values of PickList
     * @author      Intellect Systems - 2023-18-07
     * @param       objeto 
     * @param       campo 
     * return       List<PickListOption>
     */
    public static List<PickListOption> getPickListOption(String objeto, String campo){
        List<PickListOption> listOptions = new List<PickListOption>();
        SObjectType objectType = Schema.getGlobalDescribe().get(objeto);
        List<Schema.PicklistEntry> ple = objectType.getDescribe().fields.getMap()
            .get(campo).getDescribe().getPickListValues();
        for(Schema.PicklistEntry entry : ple)  {
            PickListOption p = new PickListOption();
            p.label = entry.getLabel();
            p.value = entry.getvalue();
            listOptions.add(p);
        }
        return listOptions;
    }
    
    @AuraEnabled
    public static Boolean childrenCaseValidation(String idCase){
      Boolean flagCase = false;
      String recordTypeIdControlC = Schema.SObjectType.Case.RecordTypeInfosByDeveloperName.get('FS_ControlCambios').RecordTypeId;
      List<Case> listCasosHijos = [Select Id from Case Where ParentId = :idCase and recordTypeId =: recordTypeIdControlC and Status != 'Cerrado' and Status != 'Dado de Baja'];
      if (String.isNotBlank(idCase)){
          if(listCasosHijos.size() > 0){
            flagCase = true; 
          }
      }
      return flagCase;
    }
    
    public class ContactoWrapper{
        @AuraEnabled public String cuentaId {get;set;}
        @AuraEnabled public String contactId {get;set;}
        @AuraEnabled public List<Producto> listTodosProductos {get;set;}
        @AuraEnabled public List<PickListOption> listTiporegistro {get;set;}
        @AuraEnabled public List<PickListOption> listMotivo {get;set;}
    }
    
    public class CasoWrapper{
        @AuraEnabled public Case caso {get;set;}
        @AuraEnabled public List<PickListOption> listAceptaRespuesta {get;set;}
        @AuraEnabled public List<PickListOption> listMotivosRechazo {get;set;}
        @AuraEnabled public List<PickListOption> listMotivosRechazoParche {get;set;}
        @AuraEnabled public List<PickListOption> listTipoAprobacion {get;set;}
    }
    
    public class ListCasos{
        @AuraEnabled public List<Case> casosAbiertos {get;set;}
        @AuraEnabled public List<Case> casosCerrados {get;set;}
        @AuraEnabled public List<Case> casosMostrados {get;set;}
    }
    
    public class Producto{
        @AuraEnabled public String producto{get;set;}
        @AuraEnabled public String modulo{get;set;}
        @AuraEnabled public String subModulo{get;set;}
    }
    
    public class PickListOption{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
    }
}