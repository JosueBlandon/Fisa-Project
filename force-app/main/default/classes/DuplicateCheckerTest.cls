/**
**************************************************************************************************************
* @author           Intellect Systems
* @project          Fisa Ecuador - Implementación CRM
* @name             DuplicateCheckerTest
* @description      Test class to DuplicateChecker
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2024-12-16   Intellect Systems             Initial version.
**************************************************************************************************************
*/

@isTest
public class DuplicateCheckerTest {

    /**
     * @method      setup
     * @description Method that generates the test data used in test methods
     * @author      Intellect System - 2024-12-16
     */
    @TestSetup
    static void setup(){
        Account acc = DataFactory.insertAccount();
    }

    /**
     * @method      testPreventDuplicates_NoDuplicates
     * @description Test case to ensure no errors are thrown when no duplicates exist.
     * @author      Intellect System - 2024-12-16
     */
    @isTest
    static void testPreventDuplicatesNoDuplicates() {
        List<Account> account =  [	SELECT	Id, Name  
                                    FROM 	Account  ];

        // Arrange: Create a unique test record
        FS_Proyecto__c project1 = new FS_Proyecto__c(Name = 'UniqueProject1', FS_Cliente__c = account[0].Id);
        insert project1;

        // Create new records with no duplicates
        List<FS_Proyecto__c> newProjects = new List<FS_Proyecto__c>{
            new FS_Proyecto__c(Name = 'UniqueProject2', FS_Cliente__c = account[0].Id)
        };

        // Act: Call the method under test
        Test.startTest();
        DuplicateChecker.preventDuplicates(newProjects);
        Test.stopTest();

        // Assert: Ensure no errors were added to the records
        for (FS_Proyecto__c project : newProjects) {
            System.assertEquals(0, project.getErrors().size(), 'No errors should be added for unique records.');
        }
    }

    /**
     * @method      testPreventDuplicates_WithDuplicates
     * @description Test case to ensure duplicates are detected and appropriate errors are added.
     * @author      Intellect System - 2024-12-16
     */
    @isTest
    static void testPreventDuplicatesWithDuplicates() {

        List<Account> account =  [	SELECT	Id, Name  
                                    FROM 	Account  ];

        // Arrange: Insert an existing record
        FS_Proyecto__c existingProject = new FS_Proyecto__c(Name = 'DuplicateProject', FS_Cliente__c = account[0].Id);
        insert existingProject;

        // Create new records, one of which is a duplicate
        List<FS_Proyecto__c> newProjects = new List<FS_Proyecto__c>{
            new FS_Proyecto__c(Name = 'DuplicateProject', FS_Cliente__c = account[0].Id), // Duplicate
            new FS_Proyecto__c(Name = 'UniqueProject4', FS_Cliente__c = account[0].Id)
        };

        // Act: Call the method under test
        Test.startTest();
        DuplicateChecker.preventDuplicates(newProjects);
        Test.stopTest();

        // Assert: Ensure errors are added for the duplicate record
        System.assertEquals(1, newProjects[0].getErrors().size(), 'Duplicate record should have an error.');
        System.assertEquals(0, newProjects[1].getErrors().size(), 'Unique record should not have any errors.');
    }

    /**
     * @method      testPreventDuplicates_EmptyList
     * @description Test case to ensure no errors or issues occur when an empty list is passed.
     * @author      Intellect System - 2024-12-16
     */
    @isTest
    static void testPreventDuplicatesEmptyList() {
        // Arrange: Create an empty list of FS_Proyecto__c
        List<FS_Proyecto__c> emptyList = new List<FS_Proyecto__c>();

        // Act: Call the method under test
        Test.startTest();
        DuplicateChecker.preventDuplicates(emptyList);
        Test.stopTest();

        // Assert: No exceptions or errors should occur
        System.assert(true, 'No errors should occur for an empty list.');
    }

    /**
     * @method      testPreventDuplicates_NullList
     * @description Test case to ensure no errors occur when null is passed.
     * @author      Intellect System - 2024-12-16
     */
    @isTest
    static void testPreventDuplicatesNullList() {
        // Act: Call the method under test with null
        Test.startTest();
        DuplicateChecker.preventDuplicates(null);
        Test.stopTest();

        // Assert: No exceptions or errors should occur
        System.assert(true, 'No errors should occur for a null list.');
    }
}