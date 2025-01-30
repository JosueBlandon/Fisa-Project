/**
**************************************************************************************************************
* @author           Intellect Systems
* @project          Fisa Ecuador - Implementación CRM
* @name             EnviarEmailCreacionCasoTest
* @description      Test class to EnviarEmailCreacionCaso
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2025-01-26   Intellect Systems             Initial version.
**************************************************************************************************************
*/

@isTest
public class EnviarEmailCreacionCasoTest {
    
    public static final String TIPO_REGISTRO_REQ = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();

    /**
     * @method      setup
     * @description Method to create fake data
     * @author      Intellect Systems - 2025-01-29
     */
    @testSetup
    static void setup() {  
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        User user = DataFactory.insertUserCommunity(cont);
        Case caseReq = DataFactory.insertCase2(acc, cont, TIPO_REGISTRO_REQ);
        FS_ProductoAdquirido__c product = DataFactory.insertProduct(acc, 'FISA System', 'Colocaciones (Módulo 6)', 'Crédito Hipotecario');
    }

    /**
     * @method      caseRequerimiento
     * @description Method to validate case creation and email sending
     * @author      Intellect Systems - 2025-01-29
     */
    @isTest
    static void caseRequerimiento() {
        List<String> caseIds = new List<String>();
        List<Case> record = [SELECT Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c FROM Case Where RecordType.Id =: TIPO_REGISTRO_REQ];
        
        for(Case c: record){
            caseIds.add(c.Id);  
        }

        EnviarEmailCreacionCaso.enviarEmailCliente(caseIds);
    }

}