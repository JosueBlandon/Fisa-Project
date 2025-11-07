/**
**************************************************************************************************************
* @author           Intellect Systems href=<info@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             ProductsPurchasedTriggerHelper
* @description      Helper to ProductsPurchasedTriggerHandler class.
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-05-27   Intellect Systems             Initial version.
**************************************************************************************************************
*/

public without sharing class ProductsPurchasedTriggerHelper {
    
	/**
     * @method      assignProducts
     * @description Method to assign related products to contact field 
     * @author      Intellect Systems - 2024-05-27
     * @param       records - FS_ProductoAdquirido__c List
     */
    
    
    public static void assignProducts(List<FS_ProductoAdquirido__c> records) {
        Set<Id> accountsIds = new Set<Id>();
    	//Get AccountId
        for(FS_ProductoAdquirido__c record : records) {
        	accountsIds.add(record.FS_Cuenta__c);
        }
        //Search related Contacts
        Map<Id, Contact> contactsList = new Map<Id, Contact>([	SELECT	Id, Name, AccountId, FS_Producto_1__c,
                                                                FS_Producto_2__c, FS_Producto_3__c, FS_Producto_4__c
                                               					FROM	Contact
                                               					WHERE	AccountId IN: accountsIds	]);
        
        //Search related Products
        Map<Id, FS_ProductoAdquirido__c> productsList = new Map<Id, FS_ProductoAdquirido__c>([	SELECT	Id, FS_Cuenta__c, FS_Producto__c, FS_Modulo__c, FS_SubModuloCatalogo__c, FS_Esta_activo__c
                                               													FROM	FS_ProductoAdquirido__c
                                               													WHERE	FS_Cuenta__c IN: accountsIds	]);
        
        //Assign all active related ProductsPurchased to Contact
        Set<String> listAllProducts = new Set<String>();
        
        for(Id keyProduct : productsList.keySet()) {
            Id accountId = productsList.get(keyProduct).FS_Cuenta__c;
            
            
            if(productsList.get(keyProduct).FS_Esta_activo__c == true && accountId == productsList.get(keyProduct).FS_Cuenta__c ) {
                listAllProducts.add(productsList.get(keyProduct).FS_Producto__c);
                for(Id keyContact : contactsList.keySet()) {
                    if(contactsList.get(keyContact).AccountId == productsList.get(keyProduct).FS_Cuenta__c) {
                        if(listAllProducts.contains('FISA System')){
                            contactsList.get(keyContact).FS_Producto_1__c = 'FISA System';
                        }else{
                            contactsList.get(keyContact).FS_Producto_1__c = '';
                        }
                        
                        if(listAllProducts.contains('FISA CreditCard')){
                            contactsList.get(keyContact).FS_Producto_2__c = 'FISA CreditCard';
                        }else{
                            contactsList.get(keyContact).FS_Producto_2__c = '';
                        }
                        
                        if(listAllProducts.contains('OMNIA')){
                            contactsList.get(keyContact).FS_Producto_3__c = 'OMNIA';
                        }else{
                            contactsList.get(keyContact).FS_Producto_3__c = '';
                        }
                        
                        if(listAllProducts.contains('FISA FISS')){
                            contactsList.get(keyContact).FS_Producto_4__c = 'FISA FISS';
                        }else{
                            contactsList.get(keyContact).FS_Producto_4__c = '';
                        }   
                    }    
                }
            }   
            
             
        }//
        if(contactsList.size() > 0) {
        	update contactsList.values();}
        
        
        
    }
    
    public static void deleteProducts(List<FS_ProductoAdquirido__c> oldRecords){
        
    
        Set<Id> accountsIds = new Set<Id>();
    	//Get AccountId
        for(FS_ProductoAdquirido__c record : oldRecords) {
        	accountsIds.add(record.FS_Cuenta__c);
        }
        //Search related Contacts
        Map<Id, Contact> contactsList = new Map<Id, Contact>([	SELECT	Id, Name, AccountId, FS_Producto_1__c,
                                                                FS_Producto_2__c, FS_Producto_3__c, FS_Producto_4__c
                                               					FROM	Contact
                                               					WHERE	AccountId IN: accountsIds	]);
        
        //Search related Products
        Map<Id, FS_ProductoAdquirido__c> productsList = new Map<Id, FS_ProductoAdquirido__c>([	SELECT	Id, FS_Cuenta__c, FS_Producto__c, FS_Modulo__c, FS_SubModuloCatalogo__c, FS_Esta_activo__c
                                               													FROM	FS_ProductoAdquirido__c
                                               													WHERE	FS_Cuenta__c IN: accountsIds and Id IN:	oldRecords ALL ROWS]);
        
        //Assign all active related ProductsPurchased to Contact
        Set<String> listAllProducts = new Set<String>();
        
        for(Id keyProduct : productsList.keySet()) {
            Id accountId = productsList.get(keyProduct).FS_Cuenta__c;

            if(productsList.get(keyProduct).FS_Esta_activo__c == true && accountId == productsList.get(keyProduct).FS_Cuenta__c ) {
                listAllProducts.add(productsList.get(keyProduct).FS_Producto__c);
                for(Id keyContact : contactsList.keySet()) {
                    if(contactsList.get(keyContact).AccountId == productsList.get(keyProduct).FS_Cuenta__c) {
                        
                        if(listAllProducts.contains('FISA System')){
                            contactsList.get(keyContact).FS_Producto_1__c = '';
                        }
                        
                        if(listAllProducts.contains('FISA CreditCard')){
                            contactsList.get(keyContact).FS_Producto_2__c = '';
                        }
                        
                        if(listAllProducts.contains('OMNIA')){
                            contactsList.get(keyContact).FS_Producto_3__c = '';
                        }
                        
                        if(listAllProducts.contains('FISA FISS')){
                            contactsList.get(keyContact).FS_Producto_4__c = '';
                        }
                    }
                }
            }
        }
        
        if(contactsList.size() > 0) {
        	update contactsList.values();}

    }
    
}