@isTest
public class EmailMessageTriggerHelperTest {
    
    @isTest
    static void testDeleteInternalEmail() {
        
        // Crear una cuenta de prueba
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Crear un contacto de prueba y asociarlo a la cuenta
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'contact@example.com',
            AccountId = testAccount.Id  // Relacionamos el contacto con la cuenta
        );
        insert testContact;
        
        // Crear un caso de prueba y asignarle el contacto
        Case testCase = new Case(
            Subject = 'Test Case',
            //ContactEmail = 'contact@example.com',
            ContactId = testContact.Id  // Relacionamos el caso con el contacto
        );
        insert testCase;
        
        // Crear dos correos electrónicos relacionados con el caso
        EmailMessage email1 = new EmailMessage(
            Subject = 'Test Email 1',
            ToAddress = 'contact@example.com',
            RelatedToId = testCase.Id
        );
        EmailMessage email2 = new EmailMessage(
            Subject = 'Test Email 2',
            ToAddress = 'wrong@example.com',
            RelatedToId = testCase.Id
        );
        
        // Insertar los correos electrónicos
        insert new List<EmailMessage>{email1, email2};
        
        // Obtener los correos electrónicos para simular el disparador
        List<EmailMessage> emailList = [SELECT Id, ToAddress, RelatedToId FROM EmailMessage WHERE Id IN :new List<Id>{email1.Id, email2.Id}];
        
        // Llamar al método deleteInternalEmail
        Test.startTest();
        EmailMessageTriggerHelper.deleteInternalEmail(emailList);
        Test.stopTest();
        
        // Verificar que solo el correo incorrecto haya sido eliminado
        List<EmailMessage> remainingEmails = [SELECT Id FROM EmailMessage WHERE Id IN :new List<Id>{email1.Id, email2.Id}];
        
        // Asegurarse de que solo el correo con la dirección incorrecta fue eliminado
        System.assertEquals(1, remainingEmails.size(), 'Solo un correo electrónico debería quedar');
        System.assertEquals(email1.Id, remainingEmails[0].Id, 'El correo correcto debe quedar');
        
    }
}