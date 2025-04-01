/**
**************************************************************************************************************
* @author           Intellect Systems href=<info@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             ContactTriggerHelper
* @description      Helper to ContactTriggerHandler class.
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-05-24   Intellect Systems             Initial version.
**************************************************************************************************************
*/

public without sharing class ContactTriggerHelper {
    
    /**
     * @method      assignProducts
     * @description Method to fill values in FS_Productos__c contact field 
     * @author      Intellect Systems - 2024-05-24
     * @param       records - Contact List 
     */
    public static void assignProducts(List<Contact> records) {
        Set<Id> accountsIds = new Set<Id>();
    	//Get AccountId
        for(Contact record : records) {
        	accountsIds.add(record.AccountId);
        }

        //Search related Products
        Map<Id, FS_ProductoAdquirido__c> productsList = new Map<Id, FS_ProductoAdquirido__c>([	SELECT	Id, FS_Cuenta__c, FS_Modulo__c, FS_Producto__c, FS_SubModulo__c, FS_Esta_activo__c
                                               													FROM	FS_ProductoAdquirido__c
                                               													WHERE	FS_Cuenta__c IN: accountsIds	]);
        
         //Search related Manager
        Map<Id, FS_Gestor_Cuenta__c> managerList = new Map<Id, FS_Gestor_Cuenta__c>([	SELECT	Id, FS_Cuenta__c, FS_Principal__c, FS_Area__c, FS_Project_Manager__r.name
                                               											FROM	FS_Gestor_Cuenta__c
                                               											WHERE	FS_Cuenta__c IN: accountsIds	]);

        //Find all active related products
        Set<String> listAllProducts = new Set<String>();
        for(Id key : productsList.keySet()) {
            Id accountId = productsList.get(key).FS_Cuenta__c;
            if(productsList.get(key).FS_Esta_activo__c == true && accountId == productsList.get(key).FS_Cuenta__c) {
                listAllProducts.add(productsList.get(key).FS_Producto__c);
            }    
        }
        
        //Find all active related Manager
        Set<String> listAllManager = new Set<String>();
        for(Id keyManager : managerList.keySet()) {
            Id accountId = managerList.get(keyManager).FS_Cuenta__c;
            if(accountId == managerList.get(keyManager).FS_Cuenta__c) {
           		//validates if the manager is the primary pm-ps.
           		for(Contact record : records) {
                	if(managerList.get(keyManager).FS_Principal__c == true && managerList.get(keyManager).FS_Area__c == 'PM-PS'){
                    	record.FS_PMPSPrincipal__c = managerList.get(keyManager).FS_Project_Manager__r.name;
                	}
                	//valida si el gestor es el pm-ps.
                	if(managerList.get(keyManager).FS_Principal__c == false && managerList.get(keyManager).FS_Area__c == 'PM-PS'){
                    	record.FS_PMPSSecundario__c = managerList.get(keyManager).FS_Project_Manager__r.name;
                	}               	
					//validates if the manager is pm-core.
                	if(managerList.get(keyManager).FS_Principal__c == false && managerList.get(keyManager).FS_Area__c == 'Core'){
                    	record.FS_PMCore__c = managerList.get(keyManager).FS_Project_Manager__r.name;
                	}
                	//validates if the manager is PM-Omnia.
                	if(managerList.get(keyManager).FS_Principal__c == false && managerList.get(keyManager).FS_Area__c == 'Omnia'){
                    	record.FS_PMOmnia__c = managerList.get(keyManager).FS_Project_Manager__r.name;
                	}
                	//validates if the manager is the PM-KAM.
                	if(managerList.get(keyManager).FS_Principal__c == false && managerList.get(keyManager).FS_Area__c == 'KAM'){
                    	record.FS_KAM__c = managerList.get(keyManager).FS_Project_Manager__r.name; 
                	}
                }
            }    
        }

        //Update products in contact
        if(!productsList.IsEmpty()) {
        	for(Contact record : records) {
                if(listAllProducts.contains('FISA System')){
                    record.FS_Producto_1__c = 'FISA System';
                }
                if(listAllProducts.contains('FISA CreditCard')){
                     record.FS_Producto_2__c = 'FISA CreditCard';
                }
                if(listAllProducts.contains('OMNIA')){
                     record.FS_Producto_3__c = 'OMNIA';
                }
                if(listAllProducts.contains('FISA FISS')){
                     record.FS_Producto_4__c = 'FISA FISS';
                }
            }	   
        }
    }
}