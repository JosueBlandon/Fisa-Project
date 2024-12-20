/**
**************************************************************************************************************
* @author           Intellect Systems href=<info@intellectsystems.net>
* @project          Fisa Ecuador - Implementación CRM
* @name             ClassName
* @description      ClassDescription
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
    public static void createJira(List<Case> records, Map<Id, Case> oldRecords) { 
        // Get a list of records
        List<FS_Project_Jira__mdt> metadataRecords = [  SELECT  Id, FS_Tipo_de_Registro__c, FS_Sub_Tipo__c, FS_Project_Id__c, FS_Issue_Type__c
                                                        FROM    FS_Project_Jira__mdt 
                                                        WITH    SECURITY_ENFORCED  ];

        List<Case> casesNew = new List<Case>();
        List<Case> casesOld = new List<Case>();

        Set<Id> idRecords = new Set<Id>();

        for(FS_Project_Jira__mdt mdtRecord : metadataRecords) {
            for (Case record : records) {
                Case caso = oldRecords.get(record.Id); 
                if(mdtRecord.FS_Tipo_de_Registro__c == record.FS_NombreTipoRegistro__c) {
                    casesNew.add(record);
                    casesOld.add(caso);
                    if(mdtRecord.FS_Sub_Tipo__c != Null && record.FS_TipoIncidente__c != Null && mdtRecord.FS_Sub_Tipo__c == record.FS_TipoIncidente__c && record.FS_NombreTipoRegistro__c == 'Incidente') {
                        idRecords.add(record.Id);
                        fillCaseFields(idRecords, mdtRecord.FS_Project_Id__c, mdtRecord.FS_Issue_Type__c);
                        JCFS.API.createJiraIssue(mdtRecord.FS_Project_Id__c, mdtRecord.FS_Issue_Type__c, casesNew, casesOld);
                    } else if(record.FS_NombreTipoRegistro__c == 'Requerimiento'){
                        idRecords.add(record.Id);
                        fillCaseFields(idRecords, mdtRecord.FS_Project_Id__c, mdtRecord.FS_Issue_Type__c);
                        JCFS.API.createJiraIssue(mdtRecord.FS_Project_Id__c, mdtRecord.FS_Issue_Type__c, casesNew, casesOld);
                    }
                }
            }
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
                                                        FROM    FS_Project_Jira__mdt 
                                                        WITH    SECURITY_ENFORCED  ];

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