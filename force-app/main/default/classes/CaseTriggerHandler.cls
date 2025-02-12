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

    public static void beforeInsert(List<Case> newCaseList){
        CaseTriggerHelperPMPS.assignCases(newCaseList);
    }
    
    public static void afterInsert(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        CaseTriggerHelper.historialDescripcion(newCaseList);
        CaseTriggerHelper.historialCaso(newCaseList);
    }
    
    public static void beforeUpdate(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<Case> lstCaseRequerimiento = new List<Case>();
        Map<Id, Case> mpCaseRequerimiento = new Map<Id, Case>();

        List<Case> lstCaseRecordCare = new List<Case>();
        Map<Id, Case> mpCaseRecordCare = new Map<Id, Case>();

        for(Case record : newCaseList) {
            Case caso = oldCaseMap.get(record.Id);
            if(record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO) {
                lstCaseRequerimiento.add(record);
                mpCaseRequerimiento.put(caso.Id, caso);
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
        }
        
        if(!lstCaseRequerimiento.isEmpty()) {
            CaseTriggerHelperPMPS.preventChangeCaseValues(lstCaseRecordCare, mpCaseRecordCare);
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
    }
    
    public static void afterUpdate(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Boolean executeFlag = true;

        for(Case record : newCaseList) {
            if(record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO) {
                executeFlag = false;
            }
        }

        CaseTriggerHelper.historialCaso(newCaseList, oldCaseMap);
        CaseTriggerHelper.UpdateFields(newCaseList, oldCaseMap);
        
        if(executeFlag) {
            CaseTriggerHelper.solventarPregunta(newCaseList, oldCaseMap);
            CaseTriggerHelper.upsertCaseJira(newCaseList, oldCaseMap);
        }
    }
    
    public static void afterDelete(List<Case> newCaseList) {
        CaseTriggerHelperPMPS.preventDeleteRecords(newCaseList);      
    }
    
}