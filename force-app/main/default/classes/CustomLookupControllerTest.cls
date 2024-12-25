/**
**************************************************************************************************************
* @author           Intellect Systems
* @project          Fisa Ecuador - Implementación CRM
* @name             CustomLookupControllerTest
* @description      Test class to CustomLookupController
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-12-24   Intellect Systems             Initial version.
**************************************************************************************************************
*/

@isTest
public class CustomLookupControllerTest {

    public static final String TIPO_REGISTRO_REQ = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();
    public static final String PROJECT_NAME = 'Test Project';

    /**
     * @method      setup
     * @description Create fake data
     * @author      Intellect Systems - 2024-12-24
     */
    @testSetup
    static void setup() {  
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        Case caseSol = DataFactory.insertCase2(acc, cont, TIPO_REGISTRO_REQ);
        FS_Proyecto__c proyect = DataFactory.insertProyect(true, PROJECT_NAME, acc.Id);
        FS_ProductoAdquirido__c product = DataFactory.insertProduct(acc, 'FISA System', 'Colocaciones (Módulo 6)', 'Crédito Hipotecario');
    }
    
    /**
     * @method      testCreateCase
     * @description Create fake case
     * @author      Intellect Systems - 2024-12-24
     */
    @isTest
    static void testCreateCase() {
        Case record = [SELECT Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c FROM Case Where RecordType.Id =: TIPO_REGISTRO_REQ];	    

        record.Subject = 'Subject Changed';
        record.FS_Producto__c = 'FISA System';
        record.FS_Modulo__c = 'Colocaciones (Módulo 6)';
        record.FS_SubModulo__c = 'Crédito Hipotecario';
        record.Status = 'Nuevo';    
        update record;      

        Test.startTest();
            List<Case> result = CustomLookupController.findCase(record.Id);
        Test.stopTest();

        // Validate the result
        System.assertEquals(1, result.size(), 'Should return exactly one Case');
        System.assertEquals(record.Id, result[0].Id, 'Returned Case ID should match the queried Case ID');
    }

    /**
     * @method      testNuevo
     * @description Create fake case in Status: Nuevo
     * @author      Intellect Systems - 2024-12-24
     */
    @isTest
    static void testNuevo() {
        Case record = [SELECT Id, FS_Buscar_Proyecto__c, FS_Buscar_Proyecto2__c, FS_Buscar_Proyecto3__c, FS_Buscar_Proyecto4__c FROM Case Where RecordType.Id =: TIPO_REGISTRO_REQ];	    

        record.Status = 'Nuevo';
        record.FS_Producto__c = 'FISA System';
        record.FS_Modulo__c = 'Colocaciones (Módulo 6)';
        record.FS_SubModulo__c = 'Crédito Hipotecario';
        update record;      

        FS_Proyecto__c project = [SELECT Id,Name FROM FS_Proyecto__c Where Name =: PROJECT_NAME];	    

        String caseId = record.Id;
        String projectId = project.Id;

        Test.startTest();
            Case updatedCase = CustomLookupController.saveProyect(record.Id, project.Id);
        Test.stopTest();

        // Validate the updates for "Nuevo" status
        System.assertEquals(projectId, updatedCase.FS_Buscar_Proyecto__c, 'FS_Buscar_Proyecto__c should not be updated');
        System.assertEquals(projectId, updatedCase.FS_Buscar_Proyecto2__c, 'FS_Buscar_Proyecto2__c should be updated');
        System.assertEquals(projectId, updatedCase.FS_Buscar_Proyecto3__c, 'FS_Buscar_Proyecto3__c should not be updated');
        System.assertEquals(projectId, updatedCase.FS_Buscar_Proyecto4__c, 'FS_Buscar_Proyecto4__c should not be updated');
    }
    
    /**
     * @method      testEstimacionMacro
     * @description Create fake case in Status: Estimación Macro
     * @author      Intellect Systems - 2024-12-24
     */
    @isTest
    static void testEstimacionMacro() {
        Case record = [SELECT Id, FS_Buscar_Proyecto__c, FS_Buscar_Proyecto2__c, FS_Buscar_Proyecto3__c, FS_Buscar_Proyecto4__c FROM Case Where RecordType.Id =: TIPO_REGISTRO_REQ];	    

        record.Status = 'Nuevo';
        record.FS_Producto__c = 'FISA System';
        record.FS_Modulo__c = 'Colocaciones (Módulo 6)';
        record.FS_SubModulo__c = 'Crédito Hipotecario';
        update record;  

        record.Status = 'Estimación Macro';
        update record; 

        FS_Proyecto__c project = [SELECT Id,Name FROM FS_Proyecto__c Where Name =: PROJECT_NAME];	    

        String caseId = record.Id;
        String projectId = project.Id;

        Test.startTest();
            Case updatedCase = CustomLookupController.saveProyect(record.Id, project.Id);
        Test.stopTest();

        // Validate the updates for "Estimación Macro" status
        System.assertEquals(projectId, updatedCase.FS_Buscar_Proyecto2__c, 'FS_Buscar_Proyecto2__c should be updated');
    }
    
    /**
     * @method      testDocumentoEF
     * @description Create fake case in Status: Documento de Especificación Funcional
     * @author      Intellect Systems - 2024-12-24
     */
    @isTest
    static void testDocumentoEF() {
        Case record = [SELECT Id, FS_Buscar_Proyecto__c, FS_Buscar_Proyecto2__c, FS_Buscar_Proyecto3__c, FS_Buscar_Proyecto4__c FROM Case Where RecordType.Id =: TIPO_REGISTRO_REQ];	    

        record.Status = 'Nuevo';
        record.FS_Producto__c = 'FISA System';
        record.FS_Modulo__c = 'Colocaciones (Módulo 6)';
        record.FS_SubModulo__c = 'Crédito Hipotecario';
        update record;  

        record.Status = 'Documento de Especificación Funcional';
        update record; 

        FS_Proyecto__c project = [SELECT Id,Name FROM FS_Proyecto__c Where Name =: PROJECT_NAME];	    

        String caseId = record.Id;
        String projectId = project.Id;

        Test.startTest();
            Case updatedCase = CustomLookupController.saveProyect(record.Id, project.Id);
        Test.stopTest();

        // Validate the updates for "Documento de Especificación Funcional" status
        System.assertEquals(projectId, updatedCase.FS_Buscar_Proyecto3__c, 'FS_Buscar_Proyecto3__c should be updated');
    }
    
    /**
     * @method      testPropuestaEconomica
     * @description Create fake case in Status: En Propuesta Económica
     * @author      Intellect Systems - 2024-12-24
     */
    @isTest
    static void testPropuestaEconomica() {
        Case record = [SELECT Id, FS_Buscar_Proyecto__c, FS_Buscar_Proyecto2__c, FS_Buscar_Proyecto3__c, FS_Buscar_Proyecto4__c FROM Case Where RecordType.Id =: TIPO_REGISTRO_REQ];	    

        record.Status = 'Nuevo';
        record.FS_Producto__c = 'FISA System';
        record.FS_Modulo__c = 'Colocaciones (Módulo 6)';
        record.FS_SubModulo__c = 'Crédito Hipotecario';
        update record;  

        record.Status = 'En Propuesta Económica';
        update record; 

        FS_Proyecto__c project = [SELECT Id,Name FROM FS_Proyecto__c Where Name =: PROJECT_NAME];	    

        String caseId = record.Id;
        String projectId = project.Id;

        Test.startTest();
            Case updatedCase = CustomLookupController.saveProyect(record.Id, project.Id);
        Test.stopTest();

        // Validate the updates for "En Propuesta Económica" status
        System.assertEquals(projectId, updatedCase.FS_Buscar_Proyecto4__c, 'FS_Buscar_Proyecto4__c should be updated');
    }

}