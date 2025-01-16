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
        CaseTriggerHelper.validacionCorreoNuevo(newCaseList);
        CaseTriggerHelper.historialCaso(newCaseList);
    }
    
    public static void beforeUpdate(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<Case> lstCaseRecord = new List<Case>();
        Map<Id, Case> mpCaseRecord = new Map<Id, Case>();
        for(Case record : newCaseList) {
            Case caso = oldCaseMap.get(record.Id);
            if(record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO) {
                lstCaseRecord.add(record);
                mpCaseRecord.put(caso.Id, caso);
            }
        }

        CaseTriggerHelper.validacionEstado(newCaseList, oldCaseMap);
        CaseTriggerHelperPMPS.preventChangeCaseValues(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAgenteN2(newCaseList);

        CaseTriggerHelper.validacionSubEstado(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionCamposAprobacion(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionProducto(newCaseList, oldCaseMap);
        CaseTriggerHelper.informacionCompleta(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionTipo(newCaseList, oldCaseMap);
        CaseTriggerHelper.aceptaRespuesta(newCaseList, oldCaseMap);
        CaseTriggerHelper.actualizacionDescripcion(newCaseList, oldCaseMap);
        CaseTriggerHelper.horasSolicitud(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAprobacionSolucion(newCaseList, oldCaseMap);
        CaseTriggerHelper.acepta1erCosto(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionFechaEntrega(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionTipoIncidente(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionURLResultadoAnalasis(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAutorizacionSolucionIPN2(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAprobacionSolucionIPRelease(newCaseList, oldCaseMap);        
        CaseTriggerHelper.validacionSolucionCortoPlazo(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionURLDisenioTecnico(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAprobacionDisenioTecnico(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionURLCodigoFuente(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionURLSolucionDefinitiva(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAprobacionSolucionDefinitivaN2(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAprobacionSolucionDefinitivaRelease(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionURLPlanPruebas(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAprobacionPlanPruebas(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionURLAmbientePruebas(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAprobacionInstalacionRelease(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionURLEvidenciaPruebas(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAprobacionCertificacionQA(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionUrlEntregaParche(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAceptaInstalacionParche(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionAceptaPaseProduccion(newCaseList, oldCaseMap);
        CaseTriggerHelper.validacionIngProducto(newCaseList, oldCaseMap);
        CaseTriggerHelper.asignarAprobadorActual(newCaseList, oldCaseMap);
        CaseTriggerHelper.llenarOrigen(newCaseList, oldCaseMap);
        CaseTriggerHelper.mapeoFechaEstado(newCaseList, oldCaseMap);
        CaseTriggerHelper.assignDeliveryDate(newCaseList, oldCaseMap);
        
        if(!lstCaseRecord.isEmpty()) {
            CaseTriggerHelperPMPS.sendToJiraPMPS(newCaseList, oldCaseMap);
            CaseTriggerHelperPMPS.sendNotification(newCaseList, oldCaseMap);
            CaseTriggerHelperPMPS.actualizacionDescripcion(newCaseList, oldCaseMap);
            CaseTriggerHelperPMPS.informacionCompleta(newCaseList, oldCaseMap);
            CaseTriggerHelperPMPS.aceptaRespuesta(newCaseList, oldCaseMap);
            CaseTriggerHelper.validacionProducto(newCaseList, oldCaseMap);
            CaseTriggerHelperPMPS.envioNotificacionFinanzas(newCaseList, oldCaseMap);
            if(UserInfo.getUserType() != 'Guest'){
                CaseTriggerHelperPMPS.envioNotificacionComunidad(newCaseList, oldCaseMap);
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