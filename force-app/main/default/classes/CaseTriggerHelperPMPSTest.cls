/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             CaseTriggerHelperPMPSTest
* @description      Test class to CaseTriggerHelperPMPS
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-02-19   Intellect Systems             Initial version.
**************************************************************************************************************
*/

@isTest
public class CaseTriggerHelperPMPSTest {

    private static final String TEST_ACCOUNT_NAME = 'My Business Account';
    private static final String REQUERIMIENTO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();


    /**
     * @method      setupTestData
     * @description Method that generates the test data used in test methods
     * @author      Intellect Systems - 2024-02-19
     */
	@TestSetup
    static void setupTestData(){ 
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        User user = DataFactory.insertUserCommunity(cont);
        System.runAs(user){
            FS_ProductoAdquirido__c p = DataFactory.insertProduct(acc, 'FISA System', 'Núcleo del Sistema', '');
            test.startTest();
            DataFactory.insertCase(acc, cont, p, 'FS_Requerimiento');
            DataFactory.insertCase(acc, cont, p, 'FS_Consulta');
            DataFactory.insertProduct(acc, 'FISA System', 'Núcleo del Sistema', 'Seguridades (Modulo 90)');
            test.stopTest();
        }
        
    }

    /**
     * @method      caseTypeRequerimiento
     * @description Method to generate basic Requerimiento case type
     * @author      Intellect Systems - 2024-02-19
     */
    @isTest
    static void caseTypeRequerimiento() {
        List<Case> casosRequerimiento =  [	SELECT	Id, Status, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c  
                                            FROM 	Case 
                                            WHERE	RecordTypeId =: REQUERIMIENTO_TIPO_REGISTRO];

        List<Case> updateCasos = new List<Case>();
        List<Case> updateCasos2 = new List<Case>();
        List<Case> updateCasos3 = new List<Case>();
        List<Case> updateCasos4 = new List<Case>();
        Map<Id, Case> oldRecords = new Map<Id, Case>();
        Map<Id, Case> oldRecords2 = new Map<Id, Case>();
        Map<Id, Case> oldRecords3 = new Map<Id, Case>();
        Date day = System.today();
        Case newCaseClone = new Case();
        Case newCaseClone2 = new Case();
        
        for(Case record : casosRequerimiento) {
            oldRecords.put(record.Id, record);
            
            record.FS_TipoRequerimiento__c = 'Master';
            record.FS_Notificaciones__c = 'Estimación Macro';
            record.FS_Aplica_Licencia_Recurrente__c = 'Si';
            record.FS_Cuando_Aplica_LR__c = 'Entrega de Solución';
            record.FS_Dias_que_Aplica_LR__c = 5;
            record.FS_Acepta_Propuesta_Economica__c = 'Si';
            record.FS_AceptaRespuesta__c = 'Si';
            record.Status = 'Validación de Respuesta (Cliente)';
            record.FS_Fecha_Puesta_en_Produccion__c = day;
            record.FS_Quiere_Finalizar_la_Atencion_del_Caso__c = true;
            record.FS_DescripcionCliente__c = 'TestDescripton';
            updateCasos.add(record);
        }

        
        update updateCasos;
        update oldRecords.values();
        CaseTriggerHelperPMPS.sendToJiraPMPS(updateCasos, oldRecords);

        List<Case> updateCasosThree = new List<Case>();
        Map<Id, Case> oldRecordsThree = new Map<Id, Case>();

        for(Case record : casosRequerimiento) {
            oldRecordsThree.put(record.Id, record);
            record.FS_Acepta_Propuesta_Economica__c = 'No';
            updateCasosThree.add(record);
        }

        update updateCasosThree;

        CaseTriggerHelperPMPS.sendToJiraPMPS(updateCasosThree, oldRecordsThree);

        //Start validate change of case record type
        List<Case> casosConsulta =  [	SELECT	Id, Status, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c  
                                        FROM 	Case 
                                        WHERE	RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
    
        List<Case> updateCasosTwo = new List<Case>();
        Map<Id, Case> oldRecordsTwo = new Map<Id, Case>();
    
        for(Case record : casosConsulta) {
            oldRecordsTwo.put(record.Id, record);
            record.RecordTypeId = REQUERIMIENTO_TIPO_REGISTRO;
            updateCasosTwo.add(record);
        }

        update updateCasosTwo;
    }
    
    /**
     * @method      caseDocumentoFuncional
     * @description Method to generate cliente notification
     * @author      Intellect Systems - 2024-02-19
     */
    @isTest
    static void caseDocumentoFuncional() {
        List<Case> casosRequerimiento =  [	SELECT	Id, Status, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c, FS_Buscar_Proyecto__c  
                                            FROM 	Case 
                                            WHERE	RecordTypeId =: REQUERIMIENTO_TIPO_REGISTRO];

        List<Case> updateCasos = new List<Case>();
        Map<Id, Case> oldRecords = new Map<Id, Case>();
        Date day = System.today();
        
        for(Case record : casosRequerimiento) {
            oldRecords.put(record.Id, record);
            record.FS_TipoRequerimiento__c = 'Master';
            record.FS_Notificaciones__c = 'Documento de Especificación Funcional';
            updateCasos.add(record);
        }

        update updateCasos;
        update oldRecords.values();

        CaseTriggerHelperPMPS.sendToJiraPMPS(updateCasos, oldRecords);
    }
    
    /**
     * @method      casePropuestaEconomica
     * @description Method to generate cliente notification
     * @author      Intellect Systems - 2024-02-19
     */
    @isTest
    static void casePropuestaEconomica() {
        List<Case> casosRequerimiento =  [	SELECT	Id, Status, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c  
                                            FROM 	Case 
                                            WHERE	RecordTypeId =: REQUERIMIENTO_TIPO_REGISTRO];

        List<Case> updateCasos = new List<Case>();
        Map<Id, Case> oldRecords = new Map<Id, Case>();
        Date day = System.today();
        
        for(Case record : casosRequerimiento) {
            oldRecords.put(record.Id, record);
            record.FS_TipoRequerimiento__c = 'Master';
            record.FS_Notificaciones__c = 'En Propuesta Económica';
            updateCasos.add(record);
        }

        update updateCasos;
        update oldRecords.values();

        CaseTriggerHelperPMPS.sendToJiraPMPS(updateCasos, oldRecords);
    }
    
    /**
     * @method      caseEsperaRespuestaCliente
     * @description Method to generate cliente notification
     * @author      Intellect Systems - 2024-02-19
     */
    @isTest
    static void caseEsperaRespuestaCliente() {
        List<Case> casosRequerimiento =  [	SELECT	Id, Status, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c  
                                            FROM 	Case 
                                            WHERE	RecordTypeId =: REQUERIMIENTO_TIPO_REGISTRO];

        List<Case> updateCasos = new List<Case>();
        Map<Id, Case> oldRecords = new Map<Id, Case>();
        Date day = System.today();
        
        for(Case record : casosRequerimiento) {
            oldRecords.put(record.Id, record);
            record.FS_TipoRequerimiento__c = 'Master';
            record.FS_Notificaciones__c = 'En Espera de Respuesta del Cliente';
            updateCasos.add(record);
        }

        update updateCasos;
        update oldRecords.values();

        CaseTriggerHelperPMPS.sendToJiraPMPS(updateCasos, oldRecords);
    }
    
    /**
     * @method      preventChangeCaseValues
     * @description Method to test prevention in case modification by user
     * @author      Intellect Systems - 2024-02-19
     */
    @isTest
    static void preventChangeCaseValues() {
        List<Case> casosRequerimiento =  [	SELECT	Id, Status, OwnerId, ContactId, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c  
                                            FROM 	Case 
                                            WHERE	RecordTypeId =: REQUERIMIENTO_TIPO_REGISTRO];
        
        User user = DataFactory.createUser('PM-PS', true);
        
        System.runAs(user) {
            List<Case> updateCasos = new List<Case>();
            Map<Id, Case> oldRecords = new Map<Id, Case>();
            Date day = System.today();
    
            for(Case record : casosRequerimiento) {
                oldRecords.put(record.Id, record);
                record.OwnerId = User.Id;
                record.Status = 'Dado de Baja';
                record.FS_TipoRequerimiento__c = 'Master';
                updateCasos.add(record);
            }

            CaseTriggerHelperPMPS.preventDeleteRecords(casosRequerimiento);
            CaseTriggerHelperPMPS.preventChangeCaseValues(updateCasos, oldRecords);
        }    
    }
    
    @isTest
    static void caseTypeRequerimiento2() {
        List<Case> casosRequerimiento =  [	SELECT	Id, Status, AccountId, ContactId, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c,  
                                            FS_Producto__c, FS_Buscar_Proyecto__c, FS_Modulo__c, FS_SubModulo__c, FS_DescripcionCliente__c, FS_AgenteQA__c, FS_AgenteN2__c
                                            FROM 	Case 
                                            WHERE	RecordTypeId =: REQUERIMIENTO_TIPO_REGISTRO];

        List<Case> updateCasos = new List<Case>();
        List<Case> updateCasos2 = new List<Case>();
        Map<Id, Case> oldRecords = new Map<Id, Case>();
        Date day = System.today();
        Case newCaseClone = new Case();
        
        for(Case record : casosRequerimiento) {
            oldRecords.put(record.Id, record);
            newCaseClone.Status = 'Nuevo';
            newCaseClone.AccountId = record.AccountId;
            newCaseClone.ContactId = record.ContactId;
            newCaseClone.FS_Producto__c = record.FS_Producto__c;
            newCaseClone.FS_Buscar_Proyecto__c = record.FS_Buscar_Proyecto__c;
            newCaseClone.FS_Modulo__c = record.FS_Modulo__c;
            newCaseClone.FS_SubModulo__c = record.FS_SubModulo__c;
            newCaseClone.RecordTypeId = REQUERIMIENTO_TIPO_REGISTRO;
            newCaseClone.Subject = 'Prueba1';
        }

        Insert newCaseClone;
        newCaseClone.FS_TipoRequerimiento__c = 'Master';
        newCaseClone.FS_RequiereInformacionAdicional__c = true;
        update newCaseClone;
        
        newCaseClone.FS_RequiereInformacionAdicional__c = false;
        newCaseClone.Status = 'Análisis Previo';
        newCaseClone.FS_DiasAprobacionAnalisisPrevio__c = 5;
        newCaseClone.FS_AceptaAnalisisPrevio__c = 'Si';
        update newCaseClone;
        
        newCaseClone.FS_AceptaAnalisisPrevio__c = 'No';
        update newCaseClone;
        
        newCaseClone.FS_AceptaEstimacionMacro__c = 'Si';
        newCaseClone.FS_DiasAprobacionEstimacionMacro__c = 5;
        newCaseClone.FS_DiasDEF__c = 5;
        newCaseClone.FS_AceptaAnalisisPrevio__c = 'Si';
        newCaseClone.Status = 'Estimación Macro'; 
        update newCaseClone;
        
        newCaseClone.FS_AceptaEstimacionMacro__c = 'No';
        update newCaseClone;
        
        newCaseClone.FS_AceptaDEF__c = 'Si';
        newCaseClone.FS_AceptaEstimacionMacro__c = 'Si';
        newCaseClone.Status = 'Documento de Especificación Funcional';
        update newCaseClone;
        
        //newCaseClone.FS_AceptaDEF__c = 'No';
        //update newCaseClone;
    }
    
    @isTest
    static void caseTypeRequerimiento3() {
        List<Case> casosRequerimiento =  [	SELECT	Id, Status, AccountId, ContactId, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c,  
                                            FS_Producto__c, FS_Buscar_Proyecto__c, FS_Modulo__c, FS_SubModulo__c, FS_DescripcionCliente__c, FS_AgenteQA__c, FS_AgenteN2__c
                                            FROM 	Case 
                                            WHERE	RecordTypeId =: REQUERIMIENTO_TIPO_REGISTRO];
        
        List<Case> updateCasos = new List<Case>();
        List<Case> updateCasos2 = new List<Case>();
        Map<Id, Case> oldRecords = new Map<Id, Case>();
        Date day = System.today();
        Case newCaseClone = new Case();
        
        for(Case record : casosRequerimiento) {
            oldRecords.put(record.Id, record);
            newCaseClone.Status = 'Nuevo';
            newCaseClone.AccountId = record.AccountId;
            newCaseClone.ContactId = record.ContactId;
            newCaseClone.FS_Producto__c = record.FS_Producto__c;
            newCaseClone.FS_Buscar_Proyecto__c = record.FS_Buscar_Proyecto__c;
            newCaseClone.FS_Modulo__c = record.FS_Modulo__c;
            newCaseClone.FS_SubModulo__c = record.FS_SubModulo__c;
            newCaseClone.RecordTypeId = REQUERIMIENTO_TIPO_REGISTRO;
            newCaseClone.Subject = 'Prueba2';
        }
        
        Insert newCaseClone;
        newCaseClone.FS_EnvioNotificacion__c = true;
        newCaseClone.Status = 'Análisis Previo';
        update newCaseClone;
        
        newCaseClone.FS_EnvioNotificacion__c = false;
        update newCaseClone;
        
        newCaseClone.FS_EnvioNotificacionEM__c = true;
        newCaseClone.Status = 'Estimación Macro';
        update newCaseClone;
        
        newCaseClone.FS_EnvioNotificacionEM__c = false;
        update newCaseClone;
        
        newCaseClone.FS_EnvioNotificacionDEF__c = true;
        newCaseClone.Status = 'Documento de Especificación Funcional';
        update newCaseClone;
        
        newCaseClone.FS_EnvioNotificacionPE__c = true;
        newCaseClone.Status = 'En Propuesta Económica';
        update newCaseClone;
        
        newCaseClone.FS_AprobacionSolucion__c = 'Si';
        newCaseClone.Status = 'Validación de Respuesta (Cliente)';
        update newCaseClone;
        
        //newCaseClone.FS_AprobacionSolucion__c = 'No';
        //newCaseClone.FS_ComentariosRechazoSolucion__c = 'prueba';
        //update newCaseClone;
        
        newCaseClone.Status = 'En Espera de Respuesta del Cliente';
        //update newCaseClone;        
    }
    
    
    @isTest
    static void caseTypeRequerimiento4() {
        List<Case> casosRequerimiento =  [	SELECT	Id, Status, AccountId, ContactId, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c,  
                                            FS_Producto__c, FS_Buscar_Proyecto__c, FS_Modulo__c, FS_SubModulo__c, FS_DescripcionCliente__c, FS_AgenteQA__c, FS_AgenteN2__c
                                            FROM 	Case 
                                            WHERE	RecordTypeId =: REQUERIMIENTO_TIPO_REGISTRO];

        List<Case> updateCasos = new List<Case>();
        List<Case> updateCasos2 = new List<Case>();
        Map<Id, Case> oldRecords = new Map<Id, Case>();
        Date day = System.today();
        Case newCaseClone = new Case();
        
        for(Case record : casosRequerimiento) {
            oldRecords.put(record.Id, record);
            newCaseClone.Status = 'Nuevo';
            newCaseClone.AccountId = record.AccountId;
            newCaseClone.ContactId = record.ContactId;
            newCaseClone.FS_Producto__c = record.FS_Producto__c;
            newCaseClone.FS_Buscar_Proyecto__c = record.FS_Buscar_Proyecto__c;
            newCaseClone.FS_Modulo__c = record.FS_Modulo__c;
            newCaseClone.FS_SubModulo__c = record.FS_SubModulo__c;
            newCaseClone.FS_DescripcionCliente__c = '<p>Test</p>';
            newCaseClone.FS_TipoIncidente__c = 'Puntual';
            newCaseClone.FS_AgenteQA__c = record.FS_AgenteQA__c;
            newCaseClone.FS_AgenteN2__c = record.FS_AgenteN2__c;
            newCaseClone.RecordTypeId = REQUERIMIENTO_TIPO_REGISTRO;
            newCaseClone.Subject = 'Prueba1';
        }

        Insert newCaseClone;

        newCaseClone.FS_Acepta_Propuesta_Economica__c = 'Si';
        newCaseClone.FS_AceptaDEF__c = 'Si';
        newCaseClone.Status = 'En Propuesta Económica';
        newCaseClone.FS_Aplica_Licencia_Recurrente__c = 'Si';
        newCaseClone.FS_Dias_que_Aplica_LR__c = 5;
        newCaseClone.FS_DiasAprobacionPropuestaEconomica__c = 5;
        newCaseClone.FS_Cuando_Aplica_LR__c = 'Entrega de Solución';
        update newCaseClone;
        
        
        
        
        newCaseClone.FS_Acepta_Propuesta_Economica__c = 'No';
        update newCaseClone;
        
        newCaseClone.FS_EnviarNotificacionEntregado__c = true;
        newCaseClone.Status = 'Validación de Respuesta (Cliente)';
        newCaseClone.FS_AceptaRespuesta__c = 'Si';
        update newCaseClone;
        
        newCaseClone.FS_EnviarNotificacionCertificado__c = true;
        newCaseClone.Status = 'Certificado';
        update newCaseClone;
        
        newCaseClone.FS_EnviarNotificacionProduccion__c = true;
        newCaseClone.Status = 'En Producción';
        update newCaseClone;
        
    }
    
    @isTest
    static void caseTypeRequerimiento5() {
        List<Case> casosRequerimiento =  [	SELECT	Id, Status, AccountId, ContactId, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c,  
                                            FS_Producto__c, FS_Buscar_Proyecto__c, FS_Modulo__c, FS_SubModulo__c, FS_DescripcionCliente__c, FS_AgenteQA__c, FS_AgenteN2__c
                                            FROM 	Case 
                                            WHERE	RecordTypeId =: REQUERIMIENTO_TIPO_REGISTRO];
        
        List<Case> updateCasos = new List<Case>();
        List<Case> updateCasos2 = new List<Case>();
        Map<Id, Case> oldRecords = new Map<Id, Case>();
        Date day = System.today();
        Case newCaseClone = new Case();
        
        for(Case record : casosRequerimiento) {
            oldRecords.put(record.Id, record);
            newCaseClone.Status = 'Nuevo';
            newCaseClone.AccountId = record.AccountId;
            newCaseClone.ContactId = record.ContactId;
            newCaseClone.FS_Producto__c = record.FS_Producto__c;
            newCaseClone.FS_Buscar_Proyecto__c = record.FS_Buscar_Proyecto__c;
            newCaseClone.FS_Modulo__c = record.FS_Modulo__c;
            newCaseClone.FS_SubModulo__c = record.FS_SubModulo__c;
            newCaseClone.RecordTypeId = REQUERIMIENTO_TIPO_REGISTRO;
            newCaseClone.Subject = 'Prueba2';
        }
        
        Insert newCaseClone;

        newCaseClone.Status = 'Documento de Especificación Funcional';
        
        newCaseClone.FS_AceptaDEF__c = 'No';
        update newCaseClone;
        
        newCaseClone.Status = 'Validación de Respuesta (Cliente)';
        update newCaseClone;
        
        newCaseClone.FS_AprobacionSolucion__c = 'No';
        newCaseClone.FS_ComentariosRechazoSolucion__c = 'prueba';
        update newCaseClone;
        
        newCaseClone.Status = 'En Espera de Respuesta del Cliente';
        update newCaseClone; 
        
        
    }
}