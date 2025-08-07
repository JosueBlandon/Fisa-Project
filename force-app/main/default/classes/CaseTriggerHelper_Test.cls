@isTest
public class CaseTriggerHelper_Test {

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
        Case caseCon = DataFactory.insertCase2(acc, cont, TIPO_REGISTRO_CON);
        Case caseSol = DataFactory.insertCase2(acc, cont, TIPO_REGISTRO_SOL);
        Case caseInc = DataFactory.insertCase2(acc, cont, TIPO_REGISTRO_INC);
        Case caseReq = DataFactory.insertCase2(acc, cont, TIPO_REGISTRO_REQ);
        FS_ProductoAdquirido__c product = DataFactory.insertProduct(acc, 'FISA System', 'Colocaciones (Módulo 6)', 'Crédito Hipotecario');
    }
    
    @isTest
    static void caseConsulta() {
        Case record = [SELECT Id, Subject, FS_Producto__c, FS_Modulo__c, FS_SubModulo__c, FS_Area__c FROM Case Where RecordType.Id =: TIPO_REGISTRO_CON];

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
            record.FS_SubModulo__c = 'Crédito Hipotecario'; 
            record.FS_Area__c = 'N1. CORE';    
            record.FS_PudeSolventarPregunta__c = 'Si';
            record.FS_FechaCompromisoEntrega__c = System.today();
            update record;  
    
            record.FS_PudeSolventarPregunta__c = 'No'; 
            update record;    
        }    
    }

    @isTest
    static void caseSolicitud() {
        Case record = [SELECT Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c FROM Case Where RecordType.Id =: TIPO_REGISTRO_SOL];	    

        Profile serviceProfile = [SELECT Id FROM Profile WHERE Name = 'Administrador del Sistema' or Name = 'System Administrator' LIMIT 1];
        User serviceUser = new User(
            FirstName = 'Service1',
            LastName = 'User',
            Email = 'service@test.com',
            Username = 'serviceuser1@test.com',
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
            record.FS_SubModulo__c = 'Crédito Hipotecario';
            record.Status = 'Análisis Previo';   
            record.FS_Area__c = 'N1. CORE';    
            record.FS_SubEstado__c = 'Análisis N1';
            record.Type = 'Puntual';
            record.FS_AprobacionSolucion__c = 'No';
            record.FS_ComentariosRechazoSolucion__c = 'Rechazado';    
            record.FS_NumeroHorasSolicitud__c = 0;        
            update record;  

            try{    
                record.FS_DescripcionCliente__c = 'Test Descripcion Cliente';
                record.FS_SubEstado__c = 'En Espera de Respuesta del Cliente';
                record.FS_CorreosNotificacionesServicios__c = 'test001@gmail.com';     
                record.FS_NumeroHorasSolicitud__c = 20;    
                update record;    
            } catch (Exception ex) {
                System.debug('Error: '+ex.getLineNumber()+'---'+ex.getMessage());
            }   
        }
    }

    @isTest
    static void caseIncidenteApobado() {
        Case record = [	SELECT	Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c, AccountId, FS_Producto__c, FS_Modulo__c, FS_SubModulo__c 
                        FROM	Case 
                        WHERE	RecordType.Id =: TIPO_REGISTRO_INC  
                        LIMIT 	1  ];
        
        Profile serviceProfile = [SELECT Id FROM Profile WHERE Name = 'Administrador del Sistema' or Name = 'System Administrator' LIMIT 1];
        User serviceUser = new User(
            FirstName = 'Service2',
            LastName = 'User',
            Email = 'service@test.com',
            Username = 'serviceuser2@test.com',
            Alias = 'service',
            ProfileId = serviceProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert serviceUser;

        System.runAs(serviceUser) {
            try{
                record.Subject = 'Subject Changed';
                record.FS_Producto__c = 'FISA System';
                record.FS_Modulo__c = 'Colocaciones (Módulo 6)';
                record.FS_SubModulo__c = 'Crédito Hipotecario'; 
                record.Status = 'Análisis Previo';    
                record.FS_SubEstado__c = 'Análisis N1';
                record.FS_SubEstadoAnterior__c = 'Apertura de caso';     
                record.FS_RequiereInformacionAdicional__c = false;              
                record.FS_EnviarAprobacionSolucionIPN2__c = false;   
                record.FS_EnviarAprobacionDisenioTecnico__c = true;
                record.FS_EnviarAprobacionSolucionDN2__c = true;
                record.FS_URLParcheCliente__c = 'http://www.parche.com';
                record.FS_IngenieroProducto__c = null;
                record.FS_IngenieroProductoQA__c = null;

                update record;   

                record.FS_SolucionCortoPlazo__c = 'Si';
                record.FS_PropietarioCasoSolucionCortoPlazo__c = serviceUser.Id;       
                record.FS_AprobacionSolucionDefinitivaN2__c = 'Si';
                record.FS_AprobacionSolucionDefinitivaRelease__c = 'Si';
                record.FS_AprobacionPlanPruebas__c = 'Si';   
                record.FS_AprobacionInstalacionParcheRelease__c = 'Si';
                record.FS_UrlAmbientePruebas__c = 'http://www.test.com';
                record.FS_AprobacionCertificacionParcheQA__c = 'Si';  
                record.FS_URLParcheCliente__c = '';
                record.FS_AceptaInstalacionParche__c = 'Si';
                record.FS_AceptaPaseProducion__c = 'Si';
                record.FS_AceptaRespuesta__c = 'No'; 

                update record;    

                record.FS_AceptaRespuesta__c = 'Si';
                record.FS_RequiereInformacionAdicional__c = true;
                record.FS_EnviarAprobacionSolucionIPN2__c = true;      
                record.FS_AprobacionSolucion__c = 'Si';     
                record.FS_AprobacionSolucionIPN2__c = 'Si'; 
                record.FS_AprobacionSolucionIPRelease__c = 'Si';  
                record.FS_AprobacionDisenioTecnico__c = 'Si';
                record.FS_EnviarAprobacionPlanPruebas__c = true; 
                update record;   

                record.FS_SubEstado__c = 'Aprobación Solución IP-N2';
                record.FS_UsuarioAprobadorSolucionIPN2__c = serviceUser.Id;
                update record;
            } catch (Exception ex) {
                System.debug('Error: '+ex.getLineNumber()+'---'+ex.getMessage());
            } 
        }  
    }
    
    @isTest
    static void caseIncidenteNoAprobado() {
        try {
        Case record = [	SELECT	Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c, AccountId, FS_Producto__c, FS_Modulo__c, FS_SubModulo__c 
                        FROM	Case 
                        WHERE	RecordType.Id =: TIPO_REGISTRO_INC  
                        LIMIT 	1  ];

        Profile serviceProfile = [SELECT Id FROM Profile WHERE Name = 'Administrador del Sistema' or Name = 'System Administrator' LIMIT 1];
        User serviceUser = new User(
            FirstName = 'Service3',
            LastName = 'User',
            Email = 'service@test.com',
            Username = 'serviceuser3@test.com',
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
            record.FS_SubModulo__c = 'Crédito Hipotecario';   
            record.Status = 'Análisis Previo';    
            record.FS_SubEstado__c = 'Análisis N1'; 
            record.FS_AprobacionSolucion__c = 'No';
            record.FS_ComentariosRechazoSolucion__c = 'Test'; 
            record.FS_AprobacionSolucionIPN2__c = 'No';
            record.FS_MotivosRechazoAprobacionIPN2__c = 'Desarrollo incompleto';        
            record.FS_AprobacionSolucionIPRelease__c = 'No';
            record.FS_MotivoRechazoAprobacionIPRealease__c = 'Desarrollo incompleto'; 
            record.FS_AprobacionDisenioTecnico__c = 'No';    
            record.FS_SolucionCortoPlazo__c = 'No';
            record.FS_AprobacionSolucionDefinitivaN2__c = 'No';     
            record.FS_AprobacionSolucionDefinitivaN2__c = 'No'; 
            record.FS_MotivoRechazoSDN2__c = 'Desarrollo incompleto';    
            record.FS_AprobacionSolucionDefinitivaRelease__c = 'No';
            record.FS_MotivoRechazoSDRelease__c = 'Falta de aprobación PR'; 
            record.FS_AprobacionPlanPruebas__c = 'No';
            record.FS_MotivosRechazoDT__c = 'Desarrollo incompleto';
            record.FS_MotivoRechazoPlanPruebas__c = 'Incosistencia en plan de pruebas';   
            record.FS_AprobacionInstalacionParcheRelease__c = 'No';
            record.FS_MotivosRechazoInstalacionParche__c = 'Error en compilación';
            record.FS_AceptaPaseProducion__c = 'No';

            update record;  
		} 
        } catch(Exception ex) {
            System.debug('Error en caseIncidenteNoAprobado'+ex.getLineNumber());    
        }    
    }

    @isTest
    static void caseIncidenteChangeSubStado() {
        Case record = [	SELECT	Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c, AccountId, FS_Producto__c, FS_Modulo__c, FS_SubModulo__c 
                        FROM	Case 
                        WHERE	RecordType.Id =: TIPO_REGISTRO_INC
                        LIMIT 	1  ];

        Profile serviceProfile = [SELECT Id FROM Profile WHERE Name = 'Administrador del Sistema' or Name = 'System Administrator' LIMIT 1];
        User serviceUser = new User(
            FirstName = 'Service4',
            LastName = 'User',
            Email = 'service@test.com',
            Username = 'serviceuser4@test.com',
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
            record.FS_SubModulo__c = 'Crédito Hipotecario';   
            record.Status = 'Análisis Previo';
            record.FS_SubEstado__c = 'Aprobación Solución IP-N2';
            record.FS_UsuarioAprobadorSolucionIPN2__c = serviceUser.Id;
            update record; 

            record.FS_SubEstado__c = 'Aprobación Diseño Técnico';
            update record;

            record.FS_SubEstado__c = 'Aprobación Plan de Pruebas';
            update record;

            record.FS_SubEstado__c = 'Aprobación Consulta N2';
            update record;
        }  
    }
    
    @isTest
    static void caseIncidentePuntual() {
        Case record = [	SELECT	Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c, AccountId, FS_Producto__c, FS_Modulo__c, FS_SubModulo__c 
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
            record.FS_SubModulo__c = 'Crédito Hipotecario';
            record.Status = 'Análisis Previo';    
            record.FS_SubEstado__c = 'Análisis N1';
            record.FS_InformacionCompleta__c = 'Si';
            record.FS_TipoIncidente__c = 'Puntual';
            record.FS_FechaCompromisoEntrega__c = System.today();
            record.FS_SubEstado__c = 'Aprobación Plan de Pruebas';
            record.FS_Proyecto__c = 'FSDE238 - Precontratados BMR por 250 días Q2';
            update record;
            
            record.FS_SubEstado__c = 'Desarrollo Incidente Puntual';
            update record;

            CaseTriggerHelper.crearEncuesta(record);
        }  
    }
    
    @isTest
    static void caseIncidenteDefinitivo() {
        Case record = [	SELECT	Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c, AccountId, FS_Producto__c, FS_Modulo__c, FS_SubModulo__c 
                        FROM	Case 
                        WHERE	RecordType.Id =: TIPO_REGISTRO_INC
                        LIMIT 	1  ];
        
        Profile serviceProfile = [SELECT Id FROM Profile WHERE Name = 'Administrador del Sistema' or Name = 'System Administrator' LIMIT 1];
        User serviceUser = new User(
            FirstName = 'Service6',
            LastName = 'User',
            Email = 'service@test.com',
            Username = 'serviceuser6@test.com',
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
            record.FS_SubModulo__c = 'Crédito Hipotecario';
            record.Status = 'Análisis Previo';    
            record.FS_SubEstado__c = 'Análisis N1';
            record.FS_InformacionCompleta__c = 'Si';
            record.FS_TipoIncidente__c = 'Definitivo';
            record.FS_SubEstado__c = 'Aprobación Plan de Pruebas';
            record.FS_Proyecto__c = 'FSDE238 - Precontratados BMR por 250 días Q2	';
            update record;

            record.FS_SubEstado__c = 'Desarrollo Incidente Definitivo';
            update record;

            record.FS_SubEstado__c = 'Validación-Entrega de Fuentes';
            update record;
        }  
    }
    
    @isTest
    static void caseRequerimiento() {
        Case record = [SELECT Id, RecordType.DeveloperName, FS_NombreTipoRegistro__c, FS_TipoIncidente__c FROM Case Where RecordType.Id =: TIPO_REGISTRO_REQ];	    

        Profile serviceProfile = [SELECT Id FROM Profile WHERE Name = 'Administrador del Sistema' or Name = 'System Administrator' LIMIT 1];
        User serviceUser = new User(
            FirstName = 'Service7',
            LastName = 'User',
            Email = 'service@test.com',
            Username = 'serviceuser7@test.com',
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
            record.FS_SubModulo__c = 'Crédito Hipotecario';
            record.Status = 'Análisis Previo';    
            record.FS_SubEstado__c = 'Análisis N1';
            record.FS_RequiereInformacionAdicional__c = false;  
            record.FS_Acepta1erCosto__c = 'No';
            update record;  

            record.FS_Acepta1erCosto__c = 'Si';
            record.Status = 'Aprobación 1er Costo';
            record.FS_SubEstado__c = 'Costo Aceptado';    
            update record;     
        }
    }
    
    @isTest
    static void caseMilestone() {
        CaseTriggerHelper.entitlementCaseId(CaseTriggerHelper.CONSULTA_TIPO_REGISTRO); 
    }
}