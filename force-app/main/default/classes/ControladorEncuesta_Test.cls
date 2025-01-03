@isTest
public class ControladorEncuesta_Test {
    
    @TestSetup
    static void setup(){
        test.startTest();
            Account acc = DataFactory.insertAccount();
            Contact cont = DataFactory.insertContact(acc);
            FS_ProductoAdquirido__c p = DataFactory.insertProduct(acc, 'FISA System', 'Núcleo del Sistema', 'Parametros Generales (Módulo 1)');
            DataFactory.insertCase(acc, cont, p, 'FS_Consulta');
            DataFactory.insertProduct(acc, 'FISA FISS', 'IMS', '');
        test.stopTest();
    }

    @isTest
    static void ControladorEncuesta() {
        Case caso =  [Select Id, RecordType.DeveloperName, ContactId from Case Where RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
        Test.startTest();
        caso.FS_AceptaRespuesta__c = 'Si';
        update caso;
        ControladorEncuesta.actualizarCaso(JSON.serialize(ControladorEncuesta.getCaso(caso.Id, 'Muy Insatisfecho', '1')));
        Test.stopTest();
    }

}