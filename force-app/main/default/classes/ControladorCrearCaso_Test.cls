/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             ControladorCrearCaso_Test
* @description      Test Class to ControladorCrearCaso
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2023-09-05   Intellect Systems             Initial version.
**************************************************************************************************************
*/

@isTest
public class ControladorCrearCaso_Test {

    /**
     * @method      setup
     * @description Method that generates the test data used in test methods
     * @author      Intellect System - 2023-09-05
     */
    @TestSetup
    static void setup(){
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        FS_ProductoAdquirido__c p = DataFactory.insertProduct(acc, 'FISA System', 'Núcleo del Sistema', 'Parametros Generales (Módulo 1)');
        DataFactory.insertCase(acc, cont, p, 'FS_Consulta');
        DataFactory.insertCase(acc, cont, p, 'FS_Requerimiento');
        DataFactory.insertProduct(acc, 'FISA System', 'Núcleo del Sistema', 'Clientes (Módulo 2)');
    }
    
    /**
     * @method      ControladorCrearCaso
     * @description Method to create fake cases
     * @author      Intellect System - 2023-09-05
     */
    @isTest
    static void ControladorCrearCaso() {        
        Case caso =  [Select Id, RecordType.DeveloperName, ContactId, AccountId from Case Where RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
        Case casoRequerimiento =  [Select Id, RecordType.DeveloperName, ContactId, AccountId from Case Where RecordTypeId = :CaseTriggerHelper.REQUERIMIENTO_TIPO_REGISTRO];
        
        Blob fileBody = Blob.valueof('Test');
        String fileName = 'Test';
        
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.ContentDocumentId = null;
        cv.VersionData = fileBody; // Variable del archivo tipo Blob
        cv.Title = fileName; // variable nombre del archivo tipo string
        cv.PathOnClient = fileName; // variable nombre del archivo tipo string
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = caso.ContactId; // id del caso
        cdl.ShareType = 'V';
        insert cdl;
        
        List<ControladorCrearCaso.PickListOption> listArchivos = new List<ControladorCrearCaso.PickListOption>();
        ControladorCrearCaso.PickListOption archivo = new ControladorCrearCaso.PickListOption();
        archivo.label = cdl.ContentDocumentId;
        archivo.value = cdl.ContentDocumentId;
        listArchivos.add(archivo);
        
        ControladorCrearCaso.getProductosAdquiridos();
        ControladorCrearCaso.getCaso(caso.Id);
        caso.Id = null;
        caso.FS_TipoIncidente__c = 'Puntual';
        ControladorCrearCaso.guardarCaso(JSON.serialize(caso), JSON.serialize(listArchivos));        
        ControladorCrearCaso.queyCasos(caso.AccountId);
                
        ControladorCrearCaso.getCaso(casoRequerimiento.Id);
        casoRequerimiento.Id = null;
        casoRequerimiento.FS_Acepta_Propuesta_Economica__c = 'Si';
        casoRequerimiento.Status = 'En Propuesta Económica';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        
        casoRequerimiento.FS_AceptaAnalisisPrevio__c = 'Si';
        casoRequerimiento.Status = 'Análisis Previo';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptaEstimacionMacro__c = 'Si';
        casoRequerimiento.Status = 'Estimación Macro';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptaDEF__c = 'Si';
        casoRequerimiento.Status = 'Documento de Especificación Funcional';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptaRespuesta__c = 'Si';
        casoRequerimiento.Status = 'Validación de Respuesta (Cliente)';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
    }
    
    @isTest
    static void ControladorCrearCaso2() {        
        Case caso =  [Select Id, RecordType.DeveloperName, ContactId, AccountId from Case Where RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
        Case casoRequerimiento =  [Select Id, RecordType.DeveloperName, ContactId, AccountId from Case Where RecordTypeId = :CaseTriggerHelper.REQUERIMIENTO_TIPO_REGISTRO];
        
        Blob fileBody = Blob.valueof('Test');
        String fileName = 'Test';
        
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.ContentDocumentId = null;
        cv.VersionData = fileBody; // Variable del archivo tipo Blob
        cv.Title = fileName; // variable nombre del archivo tipo string
        cv.PathOnClient = fileName; // variable nombre del archivo tipo string
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = caso.ContactId; // id del caso
        cdl.ShareType = 'V';
        insert cdl;
        
        List<ControladorCrearCaso.PickListOption> listArchivos = new List<ControladorCrearCaso.PickListOption>();
        ControladorCrearCaso.PickListOption archivo = new ControladorCrearCaso.PickListOption();
        archivo.label = cdl.ContentDocumentId;
        archivo.value = cdl.ContentDocumentId;
        listArchivos.add(archivo);
        
        ControladorCrearCaso.getProductosAdquiridos();
        ControladorCrearCaso.getCaso(caso.Id);
        caso.Id = null;
        caso.FS_TipoIncidente__c = 'Puntual';
        ControladorCrearCaso.guardarCaso(JSON.serialize(caso), JSON.serialize(listArchivos));        
        ControladorCrearCaso.queyCasos(caso.AccountId);
                
        ControladorCrearCaso.getCaso(casoRequerimiento.Id);
        casoRequerimiento.Id = null;
        casoRequerimiento.FS_AceptaRespuesta__c = 'Si';
        casoRequerimiento.Status = 'En Revisión Entregado';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptaSolucionEnProduccion__c = 'Si';
        casoRequerimiento.Status = 'Certificado';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptaSolucionEnProduccion__c = 'Si';
        casoRequerimiento.Status = 'En Revisión Certificado';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptacionSolucionSalesforce__c = 'Si';
        casoRequerimiento.Status = 'En Producción';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptacionSolucionSalesforce__c = 'Si';
        casoRequerimiento.Status = 'En Revisión en Producción';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
    }
    
    @isTest
    static void ControladorCrearCaso3() {        
        Case caso =  [Select Id, RecordType.DeveloperName, ContactId, AccountId from Case Where RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
        Case casoRequerimiento =  [Select Id, RecordType.DeveloperName, ContactId, AccountId from Case Where RecordTypeId = :CaseTriggerHelper.REQUERIMIENTO_TIPO_REGISTRO];
        
        Blob fileBody = Blob.valueof('Test');
        String fileName = 'Test';
        
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.ContentDocumentId = null;
        cv.VersionData = fileBody; // Variable del archivo tipo Blob
        cv.Title = fileName; // variable nombre del archivo tipo string
        cv.PathOnClient = fileName; // variable nombre del archivo tipo string
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = caso.ContactId; // id del caso
        cdl.ShareType = 'V';
        insert cdl;
        
        List<ControladorCrearCaso.PickListOption> listArchivos = new List<ControladorCrearCaso.PickListOption>();
        ControladorCrearCaso.PickListOption archivo = new ControladorCrearCaso.PickListOption();
        archivo.label = cdl.ContentDocumentId;
        archivo.value = cdl.ContentDocumentId;
        listArchivos.add(archivo);
        
        ControladorCrearCaso.getProductosAdquiridos();
        ControladorCrearCaso.getCaso(caso.Id);
        caso.Id = null;
        caso.FS_TipoIncidente__c = 'Puntual';
        ControladorCrearCaso.guardarCaso(JSON.serialize(caso), JSON.serialize(listArchivos));        
        ControladorCrearCaso.queyCasos(caso.AccountId);
                
        ControladorCrearCaso.getCaso(casoRequerimiento.Id);
        //casoRequerimiento.Id = null;
        casoRequerimiento.FS_AceptaRespuesta__c = 'No';
        casoRequerimiento.Status = 'En Revisión Entregado';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptaSolucionEnProduccion__c = 'No';
        casoRequerimiento.Status = 'Certificado';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptaSolucionEnProduccion__c = 'No';
        casoRequerimiento.Status = 'En Revisión Certificado';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptacionSolucionSalesforce__c = 'No';
        casoRequerimiento.Status = 'En Producción';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptacionSolucionSalesforce__c = 'No';
        casoRequerimiento.Status = 'En Revisión en Producción';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
    }
    
    @isTest
    static void ControladorCrearCaso4() {        
        Case caso =  [Select Id, RecordType.DeveloperName, ContactId, AccountId from Case Where RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
        Case casoRequerimiento =  [Select Id, RecordType.DeveloperName, ContactId, AccountId from Case Where RecordTypeId = :CaseTriggerHelper.REQUERIMIENTO_TIPO_REGISTRO];
        
        Blob fileBody = Blob.valueof('Test');
        String fileName = 'Test';
        
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.ContentDocumentId = null;
        cv.VersionData = fileBody; // Variable del archivo tipo Blob
        cv.Title = fileName; // variable nombre del archivo tipo string
        cv.PathOnClient = fileName; // variable nombre del archivo tipo string
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = caso.ContactId; // id del caso
        cdl.ShareType = 'V';
        insert cdl;
        
        List<ControladorCrearCaso.PickListOption> listArchivos = new List<ControladorCrearCaso.PickListOption>();
        ControladorCrearCaso.PickListOption archivo = new ControladorCrearCaso.PickListOption();
        archivo.label = cdl.ContentDocumentId;
        archivo.value = cdl.ContentDocumentId;
        listArchivos.add(archivo);
        
        ControladorCrearCaso.getProductosAdquiridos();
        ControladorCrearCaso.getCaso(caso.Id);
        caso.Id = null;
        caso.FS_TipoIncidente__c = 'Puntual';
        ControladorCrearCaso.guardarCaso(JSON.serialize(caso), JSON.serialize(listArchivos));        
        ControladorCrearCaso.queyCasos(caso.AccountId);
                
        ControladorCrearCaso.getCaso(casoRequerimiento.Id);
        casoRequerimiento.Id = null;
        casoRequerimiento.FS_Acepta_Propuesta_Economica__c = 'No';
        casoRequerimiento.Status = 'En Propuesta Económica';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        
        casoRequerimiento.FS_AceptaAnalisisPrevio__c = 'No';
        casoRequerimiento.Status = 'Análisis Previo';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptaEstimacionMacro__c = 'No';
        casoRequerimiento.Status = 'Estimación Macro';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptaDEF__c = 'No';
        casoRequerimiento.Status = 'Documento de Especificación Funcional';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
        casoRequerimiento.FS_AceptaRespuesta__c = 'No';
        casoRequerimiento.Status = 'Validación de Respuesta (Cliente)';
        ControladorCrearCaso.guardarCaso(JSON.serialize(casoRequerimiento), JSON.serialize(listArchivos));
        ControladorCrearCaso.queyCasos(casoRequerimiento.AccountId);
        
    }
    
    

}