/**
**************************************************************************************************************
* @author           Intellect Systems href=<infor@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             FeedCommentTriggerHelper_Test
* @description      Test Class to FeedCommentTriggerHelper
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2023-09-06   Intellect Systems             Initial version.
**************************************************************************************************************
*/

@isTest
public class FeedCommentTriggerHelper_Test {
    
    /**
     * @method      setup
     * @description Method that generates the test data used in test methods
     * @author      Intellect System - 2023-09-06
     */
    @TestSetup
    static void setup(){
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        DataFactory.insertUserCommunity(cont);
        FS_ProductoAdquirido__c p = DataFactory.insertProduct(acc, 'FISA System', 'Núcleo del Sistema', '');
        DataFactory.insertCase(acc, cont, p, 'FS_Consulta');
        DataFactory.insertCase(acc, cont, p, 'FS_Solicitud');
        DataFactory.insertCase(acc, cont, p, 'FS_Incidente');
        DataFactory.insertProduct(acc, 'FISA FISS', 'ECCO', '');
    }
    
    /**
     * @method      FeedCommentServiceUser
     * @description Method to create fake data to Service User
     * @author      Intellect System - 2024-05-20
     */
    @isTest
    static void FeedCommentServiceUser() {
        
        User u = DataFactory.createUser('Servicio al Cliente', true);
        
        Test.startTest();
        
            Case caso =  [Select Id, RecordType.DeveloperName, FS_SubEstadoQueSePideInformacion__c, FS_SubEstado__c from Case Where RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
        
            
            System.runAs(u) {
                FeedItem fi = new FeedItem(ParentId = caso.Id, Body = 'Test', Visibility = 'AllUsers');
                insert fi;
			
                FeedComment df = new FeedComment (FeedItemId = fi.Id, CommentBody = fi.Body);
                insert df;    
                
                Database.delete(df, false);
                Database.delete(fi, false);  
            }    
        Test.stopTest();       
    }
    
    /**
     * @method      FeedCommentByStatusCaseWaiting
     * @description Method to create fake data
     * @author      Intellect System - 2024-05-20
     */
    @isTest
    static void FeedCommentByStatusCaseWaiting() {      
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        FS_ProductoAdquirido__c p = DataFactory.insertProduct(acc, 'FISA System', 'Colocaciones (Módulo 6)', 'Crédito Hipotecario');
        Case caso = DataFactory.insertCase(acc, cont, p, 'FS_Requerimiento');
        caso.Status = 'En Espera de Respuesta del Cliente';
        update caso; 
        
        Test.startTest();
            caso.FS_RequiereInformacionAdicional__c = true;
            update caso;
            
            FeedItem fi = new FeedItem(ParentId = caso.Id, Body = 'Test', Visibility = 'AllUsers');
            insert fi;
                
            FeedComment df = new FeedComment (FeedItemId = fi.Id, CommentBody = fi.Body);
            insert df;
            update df;
                
            Database.delete(df, false);
            Database.delete(fi, false);           
        Test.stopTest(); 
    }
    
    /**
     * @method      FeedCommentByStatusCaseWaiting
     * @description Method to create fake data
     * @author      Intellect System - 2024-05-20
     */
    @isTest
    static void FeedCommentByStatusCasePending() {      
        Account acc = DataFactory.insertAccount();
        Contact cont = DataFactory.insertContact(acc);
        FS_ProductoAdquirido__c p = DataFactory.insertProduct(acc, 'FISA System', 'Colocaciones (Módulo 6)', 'Crédito Hipotecario');
        Case caso = DataFactory.insertCase(acc, cont, p, 'FS_Requerimiento');
        caso.Status = 'Pendiente de Respuesta CSAT';
        update caso; 
        
        Test.startTest();
            try {
                caso.FS_RequiereInformacionAdicional__c = true;
                update caso;
            
                FeedItem fi = new FeedItem(ParentId = caso.Id, Body = 'Test', Visibility = 'AllUsers');
                insert fi;
                
                FeedComment df = new FeedComment (FeedItemId = fi.Id, CommentBody = fi.Body);
                insert df;
                update df;
                
                Database.delete(df, false);
                Database.delete(fi, false);  
            } catch(System.DmlException ex) {
                System.debug('Error en FeedCommentTriggerHelper_Test: '+ex.getMessage());
            }    
        Test.stopTest(); 
    }
    
    /**
     * @method      FeedCommentUserAdmin
     * @description Method to create fake data to Admin User
     * @author      Intellect System - 2024-02-20
     */
    @isTest
    static void FeedCommentUserAdmin() {
        Case caso =  [Select Id, RecordType.DeveloperName, FS_SubEstadoQueSePideInformacion__c, FS_SubEstado__c from Case Where RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
        caso.FS_SubEstado__c = 'Apertura de caso';
        caso.FS_SubEstadoQueSePideInformacion__c = caso.FS_SubEstado__c;
        update caso;
        
        Test.startTest();
            caso.FS_RequiereInformacionAdicional__c = true;
            update caso;
            
            FeedItem fi = new FeedItem(ParentId = caso.Id, Body = 'Test', Visibility = 'AllUsers');
            insert fi;
                
            FeedComment df = new FeedComment (FeedItemId = fi.Id, CommentBody = fi.Body);
            insert df;
            update df;
                
            Database.delete(df, false);
            Database.delete(fi, false);           
        Test.stopTest();       
    }
    
    /**
     * @method      FeedCommentCaseStatus
     * @description Method to prevent create fake data of feed comment when case is closed
     * @author      Intellect System - 2024-02-20
     */
    @isTest
    static void FeedCommentCaseStatus() {
        User u = [Select Id from User Where (Profile.Name = 'Customer Community User' or Profile.Name = 'Customer Community Plus User') and IsActive = true limit 1];
        Case caso =  [Select Id, RecordType.DeveloperName, FS_SubEstadoQueSePideInformacion__c, FS_SubEstado__c from Case Where RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
        caso.Status = 'Cerrado';
        update caso;

        Test.startTest();
            caso.FS_RequiereInformacionAdicional__c = true;
            update caso;
            System.runAs(u){
                try { 
                    FeedItem fi = new FeedItem(ParentId = caso.Id, Body = 'Test', Visibility = 'AllUsers');
                    insert fi;
                    
                    FeedComment df = new FeedComment (FeedItemId = fi.Id, CommentBody = fi.Body);
                    insert df;
                } catch ( Exception ex) {
                    System.debug(ex.getMessage() ); 
                }      
            }
        Test.stopTest();       
    }
    
    /**
     * @method      FeedItemEdit
     * @description Method to create fake data of Feed Item
     * @author      Intellect System - 2024-02-20
     */
    @isTest
    static void FeedItemEdit() {
        Case caso =  [Select Id, RecordType.DeveloperName, FS_SubEstadoQueSePideInformacion__c, FS_SubEstado__c from Case Where RecordTypeId = :CaseTriggerHelper.CONSULTA_TIPO_REGISTRO];
        caso.FS_SubEstado__c = 'Apertura de caso';
        caso.FS_SubEstadoQueSePideInformacion__c = caso.FS_SubEstado__c;
        update caso;

        Test.startTest();
            caso.FS_RequiereInformacionAdicional__c = true;
            update caso;
            
            FeedItem fi = new FeedItem(ParentId = caso.Id, Body = 'Test', Visibility = 'AllUsers');
            insert fi;
                
            fi.Body = 'Test2';
            update fi;       
        Test.stopTest();       
    }

}