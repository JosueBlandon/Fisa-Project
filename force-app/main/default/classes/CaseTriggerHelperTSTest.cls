/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             CaseTriggerHelperPMPSTest
* @description      Test class to CaseTriggerHelperTS
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-02-19   Intellect Systems             Initial version.
**************************************************************************************************************
*/
@isTest
public class CaseTriggerHelperTSTest {
    public static final String TIPO_REGISTRO_CON = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Consulta').getRecordTypeId();
    public static final String TIPO_REGISTRO_SOL = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Solicitud').getRecordTypeId();
    public static final String TIPO_REGISTRO_INC = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Incidente').getRecordTypeId();
    public static final String TIPO_REGISTRO_REQ = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();
    public static final String TIPO_REGISTRO_TM = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_TiempoMateriales').getRecordTypeId();
    public static final String TIPO_REGISTRO_TMS = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_TiempoMaterialesSprints').getRecordTypeId();

	@testSetup
    static void setup() {  
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        User user = DataFactory.insertUserCommunity(cont);
        FS_ProductoAdquirido__c product = DataFactory.insertProductTS(acc, 'FISA System', 'Colocaciones (Módulo 6)', '');
        Case caseCon = DataFactory.insertCase2(acc, cont, TIPO_REGISTRO_CON);
        Case caseSol = DataFactory.insertCase2(acc, cont, TIPO_REGISTRO_SOL);
        Case caseInc = DataFactory.insertCase2(acc, cont, TIPO_REGISTRO_INC);
        Case caseReq = DataFactory.insertCase2(acc, cont, TIPO_REGISTRO_REQ);
        
    }
    
    @isTest
    static void caseConsulta() {
        Case record = [SELECT Id, Subject, FS_Producto__c, FS_Modulo__c, FS_SubModuloCatalogo__c, FS_Area__c FROM Case Where RecordType.Id =: TIPO_REGISTRO_CON];

        Profile serviceProfile = [SELECT Id FROM Profile WHERE Name = 'Servicio al Cliente' LIMIT 1];
        User serviceUser = new User(
            FirstName = 'Service8',
            LastName = 'User',
            Email = 'service@test.com',
            Username = 'serviceuser8@test.com',
            Alias = 'service',
            ProfileId = serviceProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert serviceUser;

        System.runAs(serviceUser) {
            record.Subject = 'Subject Changed';
            record.FS_Producto__c = 'FISA System';
            record.FS_Modulo__c = 'Colocaciones (Módulo 6)';
            record.FS_esTesoreria__c = true;
            //record.FS_SubModuloCatalogo__c = 'Crédito Hipotecario'; 
            record.FS_Area__c = 'N1. TESORERIA';
            record.OwnerId = serviceUser.Id;
            //record.FS_UstedPudoSolventarTS__c = true;
            //record.FS_FechaCompromisoEntrega__c = System.today();
            update record;  
    
            record.FS_EnviarAnalisisN1__c = true; 
            update record;
            
            record.FS_UstedPudoSolventarTS__c = true;
            update record;
            
            
            record.FS_AceptaRespuesta__c = 'Si';
            update record;
            
            record.FS_ResultadoEncuesta__c = 'Muy Insatisfecho';
            record.FS_ResultadoEncuestaNumero__c = '3';
            update record;
            
            /*record.FS_AceptaRespuesta__c = 'No';    
            update record;*/
            
        }    
    }
    
    @isTest
    static void casePruebaTesoreria() {
        Case record = [SELECT Id, Subject, FS_Producto__c, FS_Modulo__c, FS_SubModuloCatalogo__c, FS_Area__c, AccountId FROM Case Where RecordType.Id =: TIPO_REGISTRO_CON];
        Boolean esTesoreria = false;
        Test.startTest();
        esTesoreria = CaseTriggerHelperTS.productoTesoreria(record);
        Test.stopTest();
        //System.assertEquals(true, esTesoreria);
   
    }

    
    @isTest
    static void caseIncidentePuntual() {
        Case record = [	SELECT	Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c, AccountId, FS_Producto__c, FS_Modulo__c, FS_SubModuloCatalogo__c 
                        FROM	Case 
                        WHERE	RecordType.Id =: TIPO_REGISTRO_INC
                        LIMIT 	1  ];

        Profile serviceProfile = [SELECT Id FROM Profile WHERE Name = 'Administrador del Sistema' or Name = 'System Administrator' LIMIT 1];
        User serviceUser = new User(
            FirstName = 'Service5',
            LastName = 'User',
            Email = 'service@test.com',
            Username = 'serviceuser5@test.com',
            Alias = 'service',
            ProfileId = serviceProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert serviceUser;

        System.runAs(serviceUser) {
            record.Subject = 'Subject Changed';
            record.FS_Producto__c = 'FISA System';
            record.FS_Modulo__c = 'Colocaciones (Módulo 6)';
            record.FS_esTesoreria__c = true;
            //record.FS_SubModuloCatalogo__c = 'Crédito Hipotecario';
            record.FS_EnviarAnalisisN1__c = true;
            record.Status = 'Análisis Previo';    
            record.FS_SubEstado__c = 'Análisis N1';
            //record.FS_InformacionCompleta__c = 'Si';
            
            //record.FS_FechaCompromisoEntrega__c = System.today();
            //record.FS_SubEstado__c = 'Aprobación Plan de Pruebas';
            record.FS_Proyecto__c = 'FSDE238 - Precontratados BMR por 250 días Q2';
            update record;
            
            record.FS_TipoIncidente__c = 'Puntual';
            update record;
            
            record.FS_URLEntregaSolucion__c = 'https://testlink.com';
            record.Status = 'En Desarrollo';    
            record.FS_SubEstado__c = 'Desarrollo Incidente Puntual';
            update record;
            
            record.FS_RequiereInformacionAdicional__c = true;
            update record;
            
            record.FS_DescripcionCliente__c = 'ajuste';
            update record;
            

            CaseTriggerHelper.crearEncuesta(record);
        }  
    }
    
    
    @isTest
    static void caseMilestone() {
        CaseTriggerHelper.entitlementCaseId(CaseTriggerHelper.CONSULTA_TIPO_REGISTRO); 
    }

}