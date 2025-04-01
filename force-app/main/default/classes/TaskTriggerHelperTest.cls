/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             TaskTriggerHelperTest
* @description      Test class to TaskTrigger, TaskTriggerHandler and TaskTriggerHelper
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-02-20   Intellect Systems             Initial version.
**************************************************************************************************************
*/

@IsTest
public class TaskTriggerHelperTest {
    
    private static final String REQUERIMIENTO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();
    
    /**
     * @method      setupTestData
     * @description Method that generates the test data used in test methods
     * @author      Intellect Systems - 2024-02-20
     */
	@TestSetup
    static void setupTestData(){ 
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        User user = DataFactory.createUser('PM-PS', true);
        FS_ProductoAdquirido__c p = DataFactory.insertProduct(acc, 'FISA System', 'Núcleo del Sistema', '');
        DataFactory.insertCase(acc, cont, p, 'FS_Requerimiento');
    }
    
	/**
     * @method      upsertTask
     * @description Method to create and prevent modify task record.
     * @author      Intellect Systems - 2024-02-20
     */
    @isTest
    static void upsertTask() {        
        List<Case> casosRequerimiento =  [	SELECT	Id, Status, OwnerId, ContactId, RecordType.DeveloperName, FS_TipoRequerimiento__c, FS_Aplica_Licencia_Recurrente__c, FS_Cuando_Aplica_LR__c, FS_Dias_que_Aplica_LR__c, FS_Acepta_Propuesta_Economica__c, FS_AceptaRespuesta__c, FS_Fecha_Puesta_en_Produccion__c, FS_Quiere_Finalizar_la_Atencion_del_Caso__c  
                                            FROM 	Case 
                                            WHERE	RecordTypeId =: REQUERIMIENTO_TIPO_REGISTRO];
        
        
        
        User user = [Select Id From User Where Profile.Name = 'PM-PS' and IsActive = true Limit 1];
        
        System.runAs(user) {
            
            Test.StartTest();
			Task tarea = new Task();
            tarea.WhatId = casosRequerimiento[0].Id;
            tarea.Subject = 'Test Task';
            tarea.TaskSubType = 'Email'; 
                
            insert tarea;
            
            try {
                tarea.Subject = 'Test Task Modify';
                update tarea;
            } catch(Exception ex) {
                System.debug(ex.getMessage());
            } 
            Test.StopTest();
        }    
	}  
}