/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             CaseTriggerHandler
* @description      Handler class to case Trigger called: CaseTrigger
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2023-07-14   Intellect Systems             Initial version.
* 2024-24-03   Intellect Systems             Method removed: validationChatter, after reviewing that they are unnecessary.
**************************************************************************************************************
*/

public without sharing class CaseTriggerHandler {

    public static final String REQUERIMIENTO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();
    public static final String CONTROLDECAMBIO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_ControlCambios').getRecordTypeId();
    public static final String TIEMPOMATERIALES_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_TiempoMateriales').getRecordTypeId();
    public static final String TIEMPOMATERIALSPRINTS_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_TiempoMaterialesSprints').getRecordTypeId();


    public static void beforeInsert(List<Case> newCaseList){
        System.debug('CPU Time (ms): ' + Limits.getCpuTime() + ' / ' + Limits.getLimitCpuTime());
        System.debug('Heap Size (bytes): ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize());
        CaseTriggerHelperPMPS.assignCases(newCaseList);
    }
    
    public static void afterInsert(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        CaseTriggerHelper.historialDescripcion(newCaseList);
        CaseTriggerHelper.historialCaso(newCaseList);
        
        List<Case> lstCaseTiempoMateriales = new List<Case>();
        Map<Id, Case> mpCaseCaseTiempoMateriales = new Map<Id, Case>();
        
        for(Case record : newCaseList) {
            if(record.RecordTypeId == TIEMPOMATERIALES_TIPO_REGISTRO || record.RecordTypeId == TIEMPOMATERIALSPRINTS_TIPO_REGISTRO){
                lstCaseTiempoMateriales.add(record);
            }
        }
        
        if(!lstCaseTiempoMateriales.isEmpty()){
            CaseTriggerHelperTM.sendToJiraTM(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
        }
        
    }
    
    public static void beforeUpdate(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<Case> lstCaseRequerimiento = new List<Case>();
        Map<Id, Case> mpCaseRequerimiento = new Map<Id, Case>();
        
        List<Case> lstCaseTiempoMateriales = new List<Case>();
        Map<Id, Case> mpCaseCaseTiempoMateriales = new Map<Id, Case>();

        List<Case> lstCaseRecordCare = new List<Case>();
        Map<Id, Case> mpCaseRecordCare = new Map<Id, Case>();
        
        List<Case> lstCaseRecordTesoreria = new List<Case>();
        Map<Id, Case> mpCaseRecordTesoreria = new Map<Id, Case>();
        
        Set<String> ProductoCase = new Set<String>();
        Set<String> ModuloCase = new Set<String>();
        Set<String> SubModuloCase = new Set<String>();
        Set<String> accCase = new Set<String>();
        /*for(Case record : newCaseList) {
            ProductoCase.add(record.FS_Producto__c);
            ModuloCase.add(record.FS_Modulo__c);
            SubModuloCase.add(record.FS_SubModuloCatalogo__c);
            accCase.add(record.AccountId);
        }
        
        List<FS_ProductoAdquirido__c> ltsProductosAdq = [     SELECT  FS_Cuenta__c, FS_Producto__c, FS_Modulo__c, FS_SubModuloCatalogo__c, FS_Esta_activo__c 
                                                            FROM    FS_ProductoAdquirido__c 
                                                            WHERE   FS_Cuenta__c IN: accCase AND FS_Producto__c IN: ProductoCase AND FS_Modulo__c IN: ModuloCase
                                                            AND     FS_SubModuloCatalogo__c IN: SubModuloCase  AND FS_ProductoTesoreria__c = true];
        
        Map<String, FS_ProductoAdquirido__c> productoMap = new Map<String, FS_ProductoAdquirido__c>();
        for (FS_ProductoAdquirido__c pa : ltsProductosAdq) {
            //
            String key = pa.FS_Cuenta__c + '-' + pa.FS_Producto__c + '-' + pa.FS_Modulo__c;// + '-' + pa.FS_SubModuloCatalogo__c;
            productoMap.put(key, pa);
        }*/

        for(Case record : newCaseList) {
            Case caso = oldCaseMap.get(record.Id);
            String key = record.AccountId + '-' + record.FS_Producto__c + '-' + record.FS_Modulo__c; //+ '-' + record.FS_SubModuloCatalogo__c;
            if(record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO || record.RecordTypeId == CONTROLDECAMBIO_TIPO_REGISTRO) {
                lstCaseRequerimiento.add(record);
                mpCaseRequerimiento.put(caso.Id, caso);
            } else if(record.RecordTypeId == TIEMPOMATERIALES_TIPO_REGISTRO || record.RecordTypeId == TIEMPOMATERIALSPRINTS_TIPO_REGISTRO){
                lstCaseTiempoMateriales.add(record);
                mpCaseCaseTiempoMateriales.put(caso.Id, caso);
            } else if(record.FS_esTesoreria__c == true) {
                lstCaseRecordTesoreria.add(record);
                mpCaseRecordTesoreria.put(caso.Id, caso);
            } else {
                lstCaseRecordCare.add(record);
                mpCaseRecordCare.put(caso.Id, caso);
            }
            
        }

        CaseTriggerHelper.validacionEstado(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionProducto(newCaseList, oldCaseMap);
        CaseTriggerHelper.esCliente(newCaseList);

        if(!lstCaseRecordCare.isEmpty()) {
            CaseTriggerHelper.validacionAgenteN2(lstCaseRecordCare);
            CaseTriggerHelper.validacionSubEstado(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionCamposAprobacion(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.informacionCompleta(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionTipo(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.aceptaRespuesta(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.actualizacionDescripcion(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.horasSolicitud(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAprobacionSolucion(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.acepta1erCosto(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionFechaEntrega(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionTipoIncidente(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionURLResultadoAnalasis(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAutorizacionSolucionIPN2(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAprobacionSolucionIPRelease(lstCaseRecordCare, mpCaseRecordCare);        
            CaseTriggerHelper.validacionSolucionCortoPlazo(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionURLDisenioTecnico(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAprobacionDisenioTecnico(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionURLCodigoFuente(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionURLSolucionDefinitiva(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAprobacionSolucionDefinitivaN2(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAprobacionSolucionDefinitivaRelease(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionURLPlanPruebas(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAprobacionPlanPruebas(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionURLAmbientePruebas(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAprobacionInstalacionRelease(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionURLEvidenciaPruebas(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAprobacionCertificacionQA(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionUrlEntregaParche(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAceptaInstalacionParche(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionAceptaPaseProduccion(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.validacionIngProducto(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.asignarAprobadorActual(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.mapeoFechaEstado(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.assignDeliveryDate(lstCaseRecordCare, mpCaseRecordCare);
            CaseTriggerHelper.upsertCaseJira(lstCaseRecordCare, mpCaseRecordCare);
        }
        
        if(!lstCaseRequerimiento.isEmpty()) {
            CaseTriggerHelperPMPS.preventChangeCaseValues(lstCaseRecordCare, mpCaseRequerimiento);
            CaseTriggerHelperPMPS.sendToJiraPMPS(lstCaseRequerimiento, mpCaseRequerimiento);
            CaseTriggerHelperPMPS.sendNotification(lstCaseRequerimiento, mpCaseRequerimiento);
            CaseTriggerHelperPMPS.actualizacionDescripcion(lstCaseRequerimiento, mpCaseRequerimiento);
            CaseTriggerHelperPMPS.informacionCompleta(lstCaseRequerimiento, mpCaseRequerimiento);
            CaseTriggerHelper.validacionProducto(lstCaseRequerimiento, mpCaseRequerimiento);
            CaseTriggerHelperPMPS.envioNotificacionFinanzas(lstCaseRequerimiento, mpCaseRequerimiento);
            if(UserInfo.getUserType() != 'Guest'){
                CaseTriggerHelperPMPS.aceptaRespuesta(lstCaseRequerimiento, mpCaseRequerimiento);
                CaseTriggerHelperPMPS.envioNotificacionComunidad(lstCaseRequerimiento, mpCaseRequerimiento);
            }
        }
        
        
        if(!lstCaseTiempoMateriales.isEmpty()){
            CaseTriggerHelperTM.preventChangeCaseValues(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            CaseTriggerHelperTM.sendToJiraPMPS(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            CaseTriggerHelperTM.sendNotification(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            CaseTriggerHelperTM.actualizacionDescripcion(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            CaseTriggerHelperTM.informacionCompleta(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            CaseTriggerHelper.validacionProducto(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            //CaseTriggerHelperTM.envioNotificacionFinanzas(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            CaseTriggerHelperTM.validateChildrenCases(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            CaseTriggerHelperTM.UpdateTotalDays(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            if(UserInfo.getUserType() != 'Guest'){
                CaseTriggerHelperTM.aceptaRespuesta(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
                CaseTriggerHelperTM.envioNotificacionComunidad(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            }
        }
        
        //Tesoreria Flow
        if(!lstCaseRecordTesoreria.isEmpty()){
            CaseTriggerHelperTS.changeStatus(lstCaseRecordTesoreria, mpCaseRecordTesoreria);
            CaseTriggerHelperTS.aceptaRespuesta(lstCaseRecordTesoreria, mpCaseRecordTesoreria);
            CaseTriggerHelperTS.sendToJiraTS(lstCaseRecordTesoreria, mpCaseRecordTesoreria);
            CaseTriggerHelperTS.actualizacionDescripcion(lstCaseRecordTesoreria, mpCaseRecordTesoreria);
            CaseTriggerHelperTS.mapeoFechaEstado(lstCaseRecordTesoreria, mpCaseRecordTesoreria);
            //CaseTriggerHelperTS.updateJiraRecordTS(lstCaseRecordTesoreria, mpCaseRecordTesoreria);
        }
        

        List<Case> lstCase = new List<Case>();
        Map<Id, Case> mpCase = new Map<Id, Case>();
        for(Case record : newCaseList) {
            Case caso = oldCaseMap.get(record.Id); 
            if(record.RecordTypeId != caso.RecordTypeId) {
                lstCase.add(record);
                mpCase.put(caso.Id, caso);
            }
        }

        if(!lstCase.isEmpty()) {
            ChangeCaseRecordType.validateChangeRecordType(lstCase, mpCase);
        }
        
        for(Case record : newCaseList) {
            Case caso = oldCaseMap.get(record.Id);
            if(record.Status != caso.Status && (record.Status == 'Cerrado' || record.Status == 'Dado de Baja')) {
                List<Id> caseIds = new List<Id>();
            	CaseIds.add(record.Id);
            	//MilestoneClose.completeMilestone(caseIds);
                
            }
            
        }
     
    }
    
    public static void afterUpdate(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Boolean executeFlag = true;

        List<Case> lstCaseRequerimiento = new List<Case>();
        Map<Id, Case> mpCaseRequerimiento = new Map<Id, Case>();

        List<Case> lstCaseRecordCare = new List<Case>();
        Map<Id, Case> mpCaseRecordCare = new Map<Id, Case>();
        
        List<Case> lstCaseTiempoMateriales = new List<Case>();
        Map<Id, Case> mpCaseCaseTiempoMateriales = new Map<Id, Case>();
        
        List<Case> lstCaseRecordTesoreria = new List<Case>();
        Map<Id, Case> mpCaseRecordTesoreria = new Map<Id, Case>();

        for(Case record : newCaseList) {
            Case caso = oldCaseMap.get(record.Id);
            if(record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO || record.RecordTypeId == CONTROLDECAMBIO_TIPO_REGISTRO) {
                lstCaseRequerimiento.add(record);
                mpCaseRequerimiento.put(caso.Id, caso);
            } else if(record.RecordTypeId == TIEMPOMATERIALES_TIPO_REGISTRO || record.RecordTypeId == TIEMPOMATERIALSPRINTS_TIPO_REGISTRO){
                lstCaseTiempoMateriales.add(record);
                mpCaseCaseTiempoMateriales.put(caso.Id, caso);
            } else if(record.FS_esTesoreria__c == true){
                lstCaseRecordTesoreria.add(record);
                mpCaseRecordTesoreria.put(caso.Id, caso);
            } else {
                lstCaseRecordCare.add(record);
                mpCaseRecordCare.put(caso.Id, caso);
            }
        }

        CaseTriggerHelper.historialCaso(newCaseList, oldCaseMap);
        CaseTriggerHelper.UpdateFields(newCaseList, oldCaseMap);

        if(!lstCaseRecordCare.isEmpty()) {
            CaseTriggerHelper.solventarPregunta(lstCaseRecordCare, mpCaseRecordCare);
        }

        if(!lstCaseRequerimiento.isEmpty()) {
            CaseTriggerHelperPMPS.updateJiraRecordPMPS(lstCaseRequerimiento, mpCaseRequerimiento);
        }
        
        if(!lstCaseRecordTesoreria.isEmpty()) {
            CaseTriggerHelperTS.updateJiraRecordTS(lstCaseRecordTesoreria, mpCaseRecordTesoreria);
        }
        
        if(!lstCaseTiempoMateriales.isEmpty()) {
            CaseTriggerHelperTM.updateJiraRecordPMPS(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
            CaseTriggerHelperTM.changeStatus(lstCaseTiempoMateriales, mpCaseCaseTiempoMateriales);
        }
    }
    
    public static void afterDelete(List<Case> newCaseList) {
        CaseTriggerHelperPMPS.preventDeleteRecords(newCaseList);      
    }
    
}