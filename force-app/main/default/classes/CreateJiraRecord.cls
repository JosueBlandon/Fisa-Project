/**
**************************************************************************************************************
* @author           Intellect Systems
* @project          Fisa Ecuador - Implementación CRM
* @name             CreateJiraRecord
* @description      Class to create and update jira records
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-10-28   Intellect Systems             Initial version.
**************************************************************************************************************
*/

public without sharing class CreateJiraRecord {

    /**
     * @method      createJira
     * @description Method to create Issue Jira
     * @author      Intellect Systems - 2024-10-28
     * @param       records
     * @param       oldRecords
     */
    public static void createJira(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        // Step 1: Load metadata and group by type/subtype
        Map<String, List<FS_Project_Jira__mdt>> metadataMap = new Map<String, List<FS_Project_Jira__mdt>>();
        
        for (FS_Project_Jira__mdt meta : [
            SELECT Id, FS_Tipo_de_Registro__c, FS_Sub_Tipo__c, FS_Project_Id__c, FS_Issue_Type__c
            FROM FS_Project_Jira__mdt
        ]) {
            String key = meta.FS_Tipo_de_Registro__c + ':' + (meta.FS_Sub_Tipo__c != null ? meta.FS_Sub_Tipo__c : '');
            if (!metadataMap.containsKey(key)) {
                metadataMap.put(key, new List<FS_Project_Jira__mdt>());
            }
            metadataMap.get(key).add(meta);
        }

        // Step 2: Group Cases by Metadata Match
        Map<FS_Project_Jira__mdt, Set<Id>> caseIdsByMeta = new Map<FS_Project_Jira__mdt, Set<Id>>();
        Map<FS_Project_Jira__mdt, List<Case>> casesNewByMeta = new Map<FS_Project_Jira__mdt, List<Case>>();
        Map<FS_Project_Jira__mdt, List<Case>> casesOldByMeta = new Map<FS_Project_Jira__mdt, List<Case>>();

        for (Case newCase : newCases) {
            Case oldCase = oldCasesMap.get(newCase.Id);
            if (oldCase == null) continue;

            String tipo = newCase.FS_NombreTipoRegistro__c;
            String subTipo = newCase.FS_TipoIncidente__c != null ? newCase.FS_TipoIncidente__c : '';
            String key = tipo + ':' + subTipo;

            List<FS_Project_Jira__mdt> matchingMetas = metadataMap.get(key);
            if (matchingMetas == null) continue;

            for (FS_Project_Jira__mdt meta : matchingMetas) {
                //Boolean isIncidente = tipo == 'Incidente' && meta.FS_Sub_Tipo__c != null && meta.FS_Sub_Tipo__c == newCase.FS_TipoIncidente__c;
                //Boolean isRequerimiento = tipo == 'Requerimiento';

                //if (isIncidente || isRequerimiento) {
                    if (!caseIdsByMeta.containsKey(meta)) {
                        caseIdsByMeta.put(meta, new Set<Id>());
                        casesNewByMeta.put(meta, new List<Case>());
                        casesOldByMeta.put(meta, new List<Case>());
                    }
                    caseIdsByMeta.get(meta).add(newCase.Id);
                    casesNewByMeta.get(meta).add(newCase);
                    casesOldByMeta.get(meta).add(oldCase);
                //}
            }
        }

        // Step 3: Bulk call fillCaseFields and createJiraIssue
        for (FS_Project_Jira__mdt meta : caseIdsByMeta.keySet()) {
            Set<Id> caseIds = caseIdsByMeta.get(meta);
            List<Case> newList = casesNewByMeta.get(meta);
            List<Case> oldList = casesOldByMeta.get(meta);

            fillCaseFields(caseIds, meta.FS_Project_Id__c, meta.FS_Issue_Type__c);
            JCFS.API.createJiraIssue(meta.FS_Project_Id__c, meta.FS_Issue_Type__c, newList, oldList);
        }
    }

    /**
     * @method      updateIssueJira
     * @description Method to update Issue Jira
     * @author      Intellect Systems - 2024-10-28
     * @param       records
     * @param       oldRecords
     */
    public static void updateIssueJira(List<Case> records, Map<Id, Case> oldRecords) {
        List<Case> casesOld = new List<Case>();

        for(Case record : records) {
            casesOld.add(record);
        }

        JCFS.API.pushUpdatesToJira(records, casesOld);
    }

    /**
     * @method      checkCloseJira
     * @description Method to check if actual Jira should be closed
     * @author      Intellect Systems - 2024-10-29
     * @param       records
     * @param       oldRecords
     */
    public static void checkCloseJira(List<Case> records, Map<Id, Case> oldRecords) {
        // Get a list of records
        List<FS_Project_Jira__mdt> metadataRecords = [  SELECT  Id, FS_Tipo_de_Registro__c, FS_Sub_Tipo__c, FS_Project_Id__c, FS_Issue_Type__c
                                                        FROM    FS_Project_Jira__mdt ];

        // Initialize lists before loop
        List<Case> casesNew = new List<Case>();
        Map<Id, Case> casesOld = new Map<Id, Case>();

        // Iterate over metadata and case records
        for(FS_Project_Jira__mdt record : metadataRecords) {
            for(Case caseRecord : records) {
                Case caso = oldRecords.get(caseRecord.Id);

                // Comparison of Project ID and Issue Type
                if(record.FS_Project_Id__c == caseRecord.FS_Project_Id__c && record.FS_Issue_Type__c != caseRecord.FS_Issue_Type__c) {
                        
                    // Update the *Cerrar caso en Jira* field
                    caseRecord.FS_Cerrar_caso_en_Jira__c = 'Si';
                    
                    // Add the case to lists for further processing
                    casesNew.add(caseRecord);
                    casesOld.put(caso.Id, caso);
                } else if(record.FS_Project_Id__c != caseRecord.FS_Project_Id__c && record.FS_Issue_Type__c != caseRecord.FS_Issue_Type__c) {
                    // Update the *Cerrar caso en Jira* field
                    caseRecord.FS_Cerrar_caso_en_Jira__c = 'Si';
                    
                    // Add the case to lists for further processing
                    casesNew.add(caseRecord);
                    casesOld.put(caso.Id, caso);   
                }
            }
        }

        // Execute methods only if there are cases to process
        if (!casesNew.isEmpty() && !casesOld.isEmpty()) {
            updateIssueJira(casesNew, casesOld);
        }
    }

    /**
     * @method      fillCaseFields
     * @description Methos to fill Case fields
     * @author      Intellect Systems - 2024-10-30
     * @param       records
     */
    @future(callout=true)
    private static void fillCaseFields(Set<Id> idRecords, String projectId, String issueType) {
        List<Case> records = [  SELECT  Id, FS_Project_Id__c, FS_Issue_Type__c
                                FROM    Case 
                                WHERE   Id In : idRecords   ];

        List<Case> updateRecord = new List<Case>();
        for(Case record : records) {
            record.FS_Project_Id__c = projectId;
            record.FS_Issue_Type__c = issueType;
            updateRecord.add(record);
        }

        if(!updateRecord.isEmpty()) {
            update updateRecord;
        }
    }
}