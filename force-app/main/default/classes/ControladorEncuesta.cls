public without sharing class ControladorEncuesta {

    @AuraEnabled
    public static EncuestaWrapper getCaso(String recordId, String resultado, String resultadoNumero) {
        EncuestaWrapper respuesta = new EncuestaWrapper();
        respuesta.listMotivoInsatisfaccion = new List<PickListOption>();
        Case caso = [Select CaseNumber, Status, FS_Acepta_Propuesta_Economica__c, FS_AceptaAnalisisPrevio__c, FS_AceptaEstimacionMacro__c, FS_AceptaDEF__c   From Case Where id = :recordId];
        respuesta.numeroCaso = caso.CaseNumber;
        respuesta.idCaso = caso.Id;
        respuesta.esCerrado = caso.Status == 'Cerrado';
        respuesta.deshabilitarBoton = true;
        respuesta.aceptaPropuestaEconomica = caso.FS_Acepta_Propuesta_Economica__c;
        respuesta.AceptaAnalisisPrevio = caso.FS_AceptaAnalisisPrevio__c;
        respuesta.AceptaEstimacionMacro = caso.FS_AceptaEstimacionMacro__c;
        respuesta.AceptaDEF = caso.FS_AceptaDEF__c;

        list<string> lst1 = new List<string>(); 
        lst1.add('Información Incompleta'); 
        lst1.add('Tiempo de entrega'); 
        lst1.add('No se ofrece alternativas');
        lst1.add('Entrega tiene errores');
        lst1.add('Desconocimiento del negocio');
        lst1.add('Precio');
        lst1.add('Servicio');

        list<string> lst2 = new List<string>(); 
        lst2.add('Información completa'); 
        lst2.add('Servicio y calidad'); 
        lst2.add('Conocimiento del negocio');
        lst2.add('Brindaron alternativas de solución');
        lst2.add('Tiempo de entrega	');
        lst2.add('Precio');

        if(resultado == 'Muy Insatisfecho' || resultado == 'Insatisfecho' || resultado == 'Neutral') {
            for(string str : lst1) {
                PickListOption p = new PickListOption();              
                p.label = str;
                p.value = str; 
                respuesta.listMotivoInsatisfaccion.add(p);    
                respuesta.resultadoEncuesta = resultado; 
                respuesta.resultadoEncuestaNumero = resultadoNumero;
            }            
        } else if(resultado == 'Muy Satisfecho' || resultado == 'Satisfecho') {
            for(string str : lst2) {
                PickListOption p = new PickListOption();              
                p.label = str;
                p.value = str; 
                respuesta.listMotivoInsatisfaccion.add(p);  
                respuesta.resultadoEncuesta = resultado;  
                respuesta.resultadoEncuestaNumero = resultadoNumero;
            }
        }

        /*SObjectType objectType = Schema.getGlobalDescribe().get('Case');
        List<Schema.PicklistEntry> ple = objectType.getDescribe().fields.getMap()
            .get('FS_MotivoInsatisfaccion__c').getDescribe().getPickListValues();
        for(Schema.PicklistEntry entry : ple)  {
            PickListOption p = new PickListOption();
            p.label = entry.getLabel();
            p.value = entry.getvalue();
            respuesta.listMotivoInsatisfaccion.add(p);
        }*/

        return respuesta;
    }
    
    @AuraEnabled
    public static void actualizarCaso(String jsonCaso) {
        EncuestaWrapper casoObj = (EncuestaWrapper) JSON.deserialize(jsonCaso, EncuestaWrapper.class);
        Case caso = new Case();
        caso.Id = casoObj.idCaso;
        caso.FS_ResultadoEncuesta__c = casoObj.resultadoEncuesta;
        caso.FS_ResultadoEncuestaNumero__c = casoObj.resultadoEncuestaNumero;
        caso.FS_MotivoInsatisfaccion__c = casoObj.motivoSeleccionado;       
        caso.FS_ComentariosEncuesta__c = casoObj.comentarios;
        caso.FS_SurveyAnswered__c = UserInfo.getUserId();
        caso.FS_FechaContestacionEncuesta__c = System.now();
        if(casoObj.aceptaPropuestaEconomica == 'No' || casoObj.AceptaAnalisisPrevio == 'No' || casoObj.AceptaEstimacionMacro == 'No' || casoObj.AceptaDEF == 'No'  ) {
            caso.Status = 'Dado de Baja';    
        }else {
            caso.Status = 'Cerrado';
        }
        update caso;
        
        FS_Encuesta__c encuesta = [Select Id, FS_MotivoInsatisfaccion__c, FS_ResultadoEncuesta__c, FS_Comentarios__c, FS_ResultadoEncuestaNumero__c from FS_Encuesta__c Where FS_Caso__c = :caso.Id limit 1];
        encuesta.FS_MotivoInsatisfaccion__c = casoObj.motivoSeleccionado;
        encuesta.FS_ResultadoEncuesta__c = casoObj.resultadoEncuesta;
        encuesta.FS_ResultadoEncuestaNumero__c = casoObj.resultadoEncuestaNumero;
        encuesta.FS_Comentarios__c = casoObj.comentarios;
        update encuesta;
    }

    public class EncuestaWrapper{
        @AuraEnabled public String numeroCaso{get;set;}
        @AuraEnabled public String idCaso{get;set;}
        @AuraEnabled public String motivoSeleccionado{get;set;}
        @AuraEnabled public String mostrarMotivo{get;set;}
        @AuraEnabled public String comentarios{get;set;}
        @AuraEnabled public String resultadoEncuesta{get;set;}
        @AuraEnabled public String resultadoEncuestaNumero{get;set;}
        @AuraEnabled public Boolean esCerrado{get;set;}
        @AuraEnabled public Boolean deshabilitarBoton{get;set;}
        @AuraEnabled public List<PickListOption> listMotivoInsatisfaccion{get;set;}
        @AuraEnabled public String aceptaPropuestaEconomica {get;set;}
        @AuraEnabled public String AceptaAnalisisPrevio {get;set;}
        @AuraEnabled public String AceptaEstimacionMacro {get;set;}
        @AuraEnabled public String AceptaDEF {get;set;}
    }
    
    public class PickListOption{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
    }
}