/**
**************************************************************************************************************
* @author           Intellect Systems
* @project          Fisa Ecuador - Implementación CRM
* @name             DuplicateChecker
* @description      Prevent duplicates by checking existing records and new ones.
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-11-27   Intellect Systems             Initial version.
**************************************************************************************************************
*/

public without sharing class DuplicateChecker {
    
    /**
     * @method      preventDuplicates
     * @description Method to Check for duplicates
     * @author      Intellect Systems - 2024-11-27
     */
    public static void preventDuplicates(List<FS_Proyecto__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }
        
        // Step 1: Extract unique field values from new records
        Set<String> newFieldIds = new Set<String>();
        Set<String> newFieldValues = new Set<String>();
        Set<String> newFieldValues2 = new Set<String>();
        for (FS_Proyecto__c record : newRecords) {
            if (record.Name != null) {
                newFieldIds.add(record.Id);
                newFieldValues.add(record.Name);
                newFieldValues2.add(record.FS_Cliente__c);
            }
        }
        
        // Step 2: Query existing records with matching unique field values
        Map<String, FS_Proyecto__c> existingRecordsMap = new Map<String, FS_Proyecto__c>();
        if (!newFieldValues.isEmpty()) {
            for (FS_Proyecto__c record : [	SELECT	Id, Name, FS_Cliente__c
                                            FROM	FS_Proyecto__c
                                            WHERE	Name IN: newFieldValues and FS_Cliente__c IN: newFieldValues2 and Id !=: newFieldIds  ]) {
                existingRecordsMap.put(record.Name, record);
            }
        }
        
        // Step 3: Check for duplicates
        for (FS_Proyecto__c record : newRecords) {
            if (record.Name != null && existingRecordsMap.containsKey(record.Name)) {
                //throw new DmlException('Duplicate found: ' + record.Name);
                record.addError('Registro duplicado: ' + record.Name);
            }
        }
    }
}