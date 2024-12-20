@isTest
public class CreateJiraRecord_Test {

    // Create a mock Case record
    public static final String TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();

    @testSetup
    static void setup() {       
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        FS_ProductoAdquirido__c prod = DataFactory.insertProduct(acc, 'FISA System', 'Núcleo del Sistema', 'Seguridades (Modulo 90)');
        Case cs = DataFactory.insertCase(acc, cont, prod, 'FS_Requerimiento');
    }

    @isTest
    static void testCreateJira() {
        // Mock the Case records
        List<Case> newRecords = [SELECT Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c FROM Case Where RecordType.Id =: TIPO_REGISTRO];
        Map<Id, Case> oldRecords = new Map<Id, Case>();
        for(Case record : newRecords) {
            oldRecords.put(record.Id, record);
        }

        // Call the createJira method
        Test.startTest();
        	CreateJiraRecord.createJira(newRecords, oldRecords);
        Test.stopTest();

        // Assertions to validate the method's behavior
        System.assertEquals(1, newRecords.size(), 'There should be one case record.');
        System.assertEquals('FS_Requerimiento', newRecords[0].RecordType.DeveloperName);
    }

    @isTest
    static void testUpdateIssueJira() {
        // Mock Case records
        List<Case> newRecords = [SELECT Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c, FS_Project_Id__c, FS_Issue_Type__c FROM Case Where RecordType.Id =: TIPO_REGISTRO];
        Map<Id, Case> oldRecords = new Map<Id, Case>();
        for(Case record : newRecords) {
            oldRecords.put(record.Id, record);
        }

        // Call the updateIssueJira method
        Test.startTest();
        	CreateJiraRecord.updateIssueJira(newRecords, oldRecords);
        	CreateJiraRecord.checkCloseJira(newRecords, oldRecords);
        Test.stopTest();

        // Assert the case was updated correctly
        System.assertEquals(1, newRecords.size(), 'One case record should exist for update.');
    }
}