@isTest
public class ContactTriggerHelper_Test {
    
    public static final String ACCOUNT_NAME = 'Test New Account';
    
	@isTest
    static void setup(){ 
        Account acc = DataFactory.insertNewAccount(true, ACCOUNT_NAME);
        DataFactory.insertProduct(acc, 'FISA System', 'Núcleo del Sistema', 'Seguridades (Modulo 90)');
        FS_Gestor_Cuenta__c gs = DataFactory.insertNewManager(true, acc);
        Contact cont = DataFactory.insertContact(acc);
        update cont;
    }
}