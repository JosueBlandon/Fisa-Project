@istest
public class ControladorBaseConocimientos_Test {
    
    @TestSetup
    static void setup(){
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        DataFactory.insertUserCommunity(cont);
        FS_ProductoAdquirido__c p = DataFactory.insertProduct(acc, 'FISA System', 'Colocaciones (Módulo 6)', 'Crédito Hipotecario');
        DataFactory.insertCase(acc, cont, p, 'FS_Consulta');
        DataFactory.insertCase(acc, cont, p, 'FS_Solicitud');
        DataFactory.insertCase(acc, cont, p, 'FS_Incidente');
        //DataFactory.insertProduct(acc, 'FISA System', 'Colocaciones (Módulo 6)', 'Líneas de Crédito');
        //DataFactory.inserBaseConocimientos(p);
    }
    
    @isTest
    static void BaseConocimientos() {
        Case caso =  [Select Id, ContactId from Case Where RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
        User u = [  SELECT  Id 
                    FROM    User 
                    WHERE   (Profile.Name = 'Customer Community User' or Profile.Name = 'Customer Community Plus User') and ContactId =: caso.ContactId 
                    LIMIT   1   ];
        Test.startTest();
        System.runAs(u){
            ControladorBaseConocimientos.gatListaBase();
        }
        Test.stopTest();
    }

}