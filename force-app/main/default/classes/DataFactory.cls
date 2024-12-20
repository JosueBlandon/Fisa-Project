/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             DataFactory
* @description      Class to create fake data test
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2023-09-04   Intellect Systems             Initial version.
* 2024-10-29   Intellect Systems             Add @isTest to apex class.
**************************************************************************************************************
*/

@isTest
public without sharing class DataFactory {
    
    private static final String USER_FIRST_NAME = 'TestUser';
    private static final String USER_LAST_NAME = 'TestLastName';
    private static final String USER_EMAIL = 'user.email@test.com';
    
    public static User createUser(String profileName, Boolean doInsert) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;

        UserRole userrole = [   SELECT  Id, DeveloperName 
                                FROM    UserRole 
                                WHERE   DeveloperName = 'Presidente' Limit 1   ];

        Profile profile = [ SELECT  Id 
                            FROM    Profile 
                            WHERE   Name =: profileName 
                            LIMIT 1 ];

        User user = new User(
            firstName = USER_FIRST_NAME,
            lastName = USER_LAST_NAME,
            UserRoleId = userRole.Id,
            profileId = profile.id,
            username = USER_EMAIL,
            email = USER_EMAIL,
            EmailEncodingKey = 'ISO-8859-1',
            Alias = uniqueName.substring(18, 23),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );

        if(doInsert) {
            try {
                insert user;    
            } catch (Exception ex) {
                System.debug('Erro al insetar usuario de prueba: '+ ex.getLineNumber() + '**' + ex.getMessage());
            }
        }

        return user;
    }
    
    public static Account insertAccount(){
        User adminUser = [  SELECT  Id, UserRoleId 
                            FROM    User 
                            WHERE   (Profile.Name='Administrador del sistema' or  Profile.Name='System Administrator') and IsActive = true
                            LIMIT 1 ];

        Account acc = new Account();
        acc.Name = 'Account Test';
        acc.OwnerId = adminUser.Id;
        insert acc;
        return acc;
    }
    
    public static Account insertNewAccount(Boolean doInsert, String name){
        User adminUser = [  SELECT  Id, UserRoleId 
                            FROM    User 
                            WHERE   (Profile.Name='Administrador del sistema' or  Profile.Name='System Administrator') and IsActive = true
                            LIMIT 1 ];

        Account acc = new Account();
        acc.Name = name;
        acc.OwnerId = adminUser.Id;
        
        if(doInsert) {
        	insert acc;    
        }
        
        return acc;
    }
    
    public static FS_Gestor_Cuenta__c insertNewManager(Boolean doInsert, Account acc){
                
        
        FS_Gestor_Cuenta__c gestor = new FS_Gestor_Cuenta__c();
        gestor.FS_Cuenta__c = acc.Id;
        gestor.FS_Project_Manager__c = userInfo.getUserId();
        gestor.FS_Area__c = 'Core';
        gestor.FS_Principal__c = false;        
        
        if(doInsert) {
        	insert gestor;    
        }
        
        return gestor;
    }
    
    public static Contact insertContact(Account acc){
        Contact contc = new Contact();
        contc.FirstName = 'FistName Test';
        contc.LastName = 'LastName Test';
        contc.AccountId = acc.Id;
        contc.Email = 'test@test.com';
        insert contc;
        return contc;
    }
    
    public static List<FS_Gestor_Cuenta__c> insertManager(Account acc){
        
        Account cuenta =  [     SELECT	Id, Name  
                                FROM 	Account 
                                WHERE	Id =: acc.Id    ];
        
        
        FS_Gestor_Cuenta__c gestor = new FS_Gestor_Cuenta__c();
        gestor.FS_Cuenta__c = cuenta.Id;
        gestor.FS_Project_Manager__c = userInfo.getUserId();
        gestor.FS_Area__c = 'Core';
        gestor.FS_Principal__c = false;
        
        FS_Gestor_Cuenta__c gestor1 = new FS_Gestor_Cuenta__c();
        gestor1.FS_Cuenta__c = cuenta.Id;
        gestor1.FS_Project_Manager__c = userInfo.getUserId();
        gestor1.FS_Area__c = 'Omnia';
        gestor1.FS_Principal__c = false;
        
        FS_Gestor_Cuenta__c gestor2 = new FS_Gestor_Cuenta__c();
        gestor2.FS_Cuenta__c = cuenta.Id;
        gestor2.FS_Project_Manager__c = userInfo.getUserId();
        gestor2.FS_Area__c = 'KAM';
        gestor2.FS_Principal__c = false;
        
        FS_Gestor_Cuenta__c gestor3 = new FS_Gestor_Cuenta__c();
        gestor3.FS_Cuenta__c = cuenta.Id;
        gestor3.FS_Project_Manager__c = userInfo.getUserId();
        gestor3.FS_Area__c = 'PM-PS';
        gestor3.FS_Principal__c = false;
        
        FS_Gestor_Cuenta__c gestor4 = new FS_Gestor_Cuenta__c();
        gestor4.FS_Cuenta__c = cuenta.Id;
        gestor4.FS_Project_Manager__c = userInfo.getUserId();
        gestor4.FS_Area__c = 'PM-PS';
        gestor4.FS_Principal__c = true;
        
        FS_Gestor_Cuenta__c gestor5 = new FS_Gestor_Cuenta__c();
        gestor5.FS_Cuenta__c = cuenta.Id;
        gestor5.FS_Project_Manager__c = userInfo.getUserId();
        gestor5.FS_Area__c = 'PM-PS';
        gestor5.FS_Principal__c = true;
        
        insert gestor;
        insert gestor1;
        insert gestor2;
        insert gestor3;
        insert gestor4;
        insert gestor5;
        
        List<FS_Gestor_Cuenta__c> ltsRecords = new List<FS_Gestor_Cuenta__c>();
        ltsRecords.add(gestor);
        ltsRecords.add(gestor1);
        ltsRecords.add(gestor2);
        ltsRecords.add(gestor3);
        ltsRecords.add(gestor4);
        return ltsRecords;
    }
    
    public static FS_ProductoAdquirido__c insertProduct(Account acc, String prod, String mod, String subM){
        FS_ProductoAdquirido__c p = new FS_ProductoAdquirido__c();
        p.FS_Cuenta__c = acc.Id;
        p.FS_Producto__c = prod;
        p.FS_Modulo__c = mod;
        p.FS_SubModulo__c = subM;
        p.FS_Esta_activo__c = true;
        insert p;
        return p;
    }
    
    public static Case insertCase(Account acc, Contact cont, FS_ProductoAdquirido__c p, String tipoRegistro){
        FS_Proyecto__c newProyect = new FS_Proyecto__c();
        List<FS_Proyecto__c> newProyectls = [SELECT ID FROM FS_Proyecto__c WHERE Name = 'Test1'];
        String proyectId;
        for(FS_Proyecto__c lts : newProyectls){
            proyectId = lts.Id;
        }
        
        if(proyectId == null){
            newProyect.Name = 'Test1';
            newProyect.FS_Cliente__c = acc.Id;
            newProyect.FS_Tipo_de_Caso__c = 'Requerimiento';
            newProyect.FS_Tarifa_Dias_Hombre__c = 56;
            newProyect.FS_Numero_de_dias_contratados__c = 15;
            newProyect.FS_Fecha_Inicio_Proyecto__c = system.today();
            newProyect.FS_Fecha_Fin_Proyecto__c = system.today() + 30;
            insert newProyect;
            
            proyectId = newProyect.Id;
        }
        
        
        
        Case caso = new Case();
        caso.AccountId = acc.Id;
        caso.ContactId = cont.Id;
        caso.FS_Producto__c = p.FS_Producto__c;
        caso.FS_Buscar_Proyecto__c = proyectId;
        caso.FS_Modulo__c = p.FS_Modulo__c;
        caso.FS_SubModulo__c = p.FS_SubModulo__c;
        caso.FS_DescripcionCliente__c = '<p>Test</p>';
        caso.FS_TipoIncidente__c = 'Puntual';
        caso.FS_AgenteQA__c = userInfo.getUserId();
        caso.FS_AgenteN2__c = userInfo.getUserId();
        caso.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(tipoRegistro).getRecordTypeId();
        insert caso;
        return caso;
    }
    
    public static Case insertCase2(Account acc, Contact cont, String tipoRegistro){
        FS_Proyecto__c newProyect = new FS_Proyecto__c();
        List<FS_Proyecto__c> newProyectls = [SELECT ID FROM FS_Proyecto__c WHERE Name = 'Test1'];
        String proyectId;
        for(FS_Proyecto__c lts : newProyectls){
            proyectId = lts.Id;
        }        
        
        Case caso = new Case();
        caso.Status = 'Nuevo';
        caso.FS_SubEstado__c = 'Apertura de caso';
        caso.FS_TipoIncidente__c = 'Puntual';
        caso.AccountId = acc.Id;
        caso.ContactId = cont.Id;
        caso.FS_Buscar_Proyecto__c = proyectId;
        caso.FS_DescripcionCliente__c = 'Test';
        caso.RecordTypeId = tipoRegistro;
        caso.FS_RequiereInformacionAdicional__c = false;
        insert caso;
        return caso;
    }
    
    public static User insertUserCommunity(Contact cont){

        UserRole userrole = [   SELECT  Id, DeveloperName 
                                FROM    UserRole 
                                WHERE   DeveloperName = 'Presidente' Limit 1   ];

        User adminUser = [  SELECT  Id, UserRoleId 
                            FROM    User 
                            WHERE   (Profile.Name='Administrador del sistema' or  Profile.Name='System Administrator') and IsActive = true
                            LIMIT 1 ];

        adminUser.UserRoleId = userRole.Id;
        
        try {
        update adminUser;
        } catch (Exception e) {
            System.debug('An error occurred');
        }     

        User u = new User();

        System.runAs(adminUser) {
            u.Alias = 'test'; 
            u.Email='test@myorg.com'; 
            u.EmailEncodingKey='UTF-8'; 
            u.LastName='Testing'; 
            u.LanguageLocaleKey='en_US'; 
            u.ContactId = cont.Id;
            u.LocaleSidKey='en_US'; 
            u.ProfileId = [Select Id from Profile Where Name = 'Customer Community User' or Name = 'Customer Community Plus User' limit 1].Id;
            u.TimeZoneSidKey='America/New_York';
            u.UserName= 'test@myorg.com';
            insert u;
        }
        return u;
    }
    
    public static FS_ConfiguracionSLA__c insertConfiguracionSLA(String acc) {
        FS_ConfiguracionSLA__c SLA = new FS_ConfiguracionSLA__c();
        SLA.FS_NombreDeCuenta__c = acc;
        SLA.FS_NombreTipoRegistro__c = 'Incidente'; 
        SLA.FS_SLA__c = 72; 
        SLA.FS_SubEstado__c = 'Apertura de caso;Entrega 1a respuesta;Información validada;Análisis N1;Desarrollo Incidente Definitivo;Revisión Documentación N2;Desarrollo Incidente Puntual;Aprobación de Solución IP-Release;Costo Aceptado;Costo Rechazado;Análisis Falla Operativa;Escalado a N2;Análisis N2;Envío de respuesta;Respuesta aceptada;Respuesta rechazada;En reproceso por rechazo;Elaboración Diseño Técnico;Aprobación Diseño Técnico;Validación-Entrega de Fuentes;Elaboración Solución Definitiva;Aprobación Solución Definitiva N2;Aprobación Solución Definitiva Releases;Escalado a QA;Elaboración Plan de Pruebas;Aprobación Plan de Pruebas;Instalación Parche Releases;Aprobación Instalación Parche - Releases;Certificación Parche QA;Aprobación Certificación Parche QA;Entrega de Parche;Instalación de Parche;Paso a Producción;Paso a Producción No Confirmado;Paso a Producción Confirmado;Aprobación Solución IP-N2'; 
        SLA.FS_EsCliente__c = false; 
        SLA.FS_Activo__c = true;
        insert SLA;
        
        return SLA;
    }    
    
}