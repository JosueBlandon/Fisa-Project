/**
**************************************************************************************************************
* @author           Intellect Systems
* @project          Fisa Ecuador - Implementación CRM
* @name             EnviarEmailCreacionCaso
* @description      Class to send emails
* @changes
* ----------   ---------------------------   -----------------------------------------------------------------
* Date         Author                        Description
* ----------   ---------------------------   -----------------------------------------------------------------
* 2025-01-26   Intellect Systems             Initial version.
**************************************************************************************************************
*/

public without sharing class EnviarEmailCreacionCaso {
	public static Map<String, String> mapColas;
    public static Map<String, EmailTemplate> mapPlantillas;
    public static Map<String, User> mapUser;
    public static OrgWideEmailAddress owea;
    public static CustomNotificationType notificacion;
    
    public static final String REQUERIMIENTO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_Requerimiento').getRecordTypeId();
    public static final String CONTROLDECAMBIO_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_ControlCambios').getRecordTypeId();
    public static final String TIEMPOMATERIALES_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_TiempoMateriales').getRecordTypeId();
    public static final String TIEMPOMATERIALSPRINTS_TIPO_REGISTRO = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FS_TiempoMaterialesSprints').getRecordTypeId();
    static{
        mapColas = new Map<String, String>();
        mapPlantillas = new Map<String, EmailTemplate>();
        mapUser = new Map<String, User>();
        
        owea = [select Id from OrgWideEmailAddress where Address = :Label.FS_CorreoElectronicoServicio];
        notificacion = [SELECT Id FROM CUstomNotificationType Where DeveloperName = 'FS_NotificacionServicio' LIMIT 1];
        
        for(Group item: [Select Id, DeveloperName from Group Where DeveloperName Like '%FS_%' and Type = 'Queue']){
            mapColas.put(item.DeveloperName, item.Id);
        }
        for(User item: [Select Id, Email, Name, FirstName, Lastname, UserRole.DeveloperName, Profile.Name from User Where IsActive = true]){
            mapUser.put(item.Id, item);
        }
        for(EmailTemplate plantilla :[Select Id, Subject, HTMLValue,DeveloperName from EmailTemplate Where DeveloperName Like '%FS_%']){
            mapPlantillas.put(plantilla.DeveloperName, plantilla);
        }
    }

    /**
     * @method      enviarEmailCliente
     * @description Method to be invoqued since Flow
     * @author      Intellect Systems - 2025-01-26
     * @param       values
     */
	@InvocableMethod    
    public static void enviarEmailCliente(List<String> values) {
        Case record = [	SELECT	Id,CaseNumber,Subject,Status,RecordTypeId,FS_OrigenCaso__c,FS_NombrePropietario__c,FS_NombreContacto__c,FS_CorreosNotificacionesServicios__c,FS_NombreCuenta__c,FS_NombreTipoRegistro__c,Owner.Email,Contact.Email,CreatedBy.Email,ContactId, FS_esTesoreria__c
                        FROM	Case 
                        WHERE	Id In: values ];

        if(record.RecordTypeId == TIEMPOMATERIALSPRINTS_TIPO_REGISTRO){
            EnviarEmailCreacionCaso.envioCorreo(record, 'FS_CreacionCasoTM', true);
        }else if(record.FS_esTesoreria__c == true){
            EnviarEmailCreacionCaso.envioCorreo(record, 'FS_AperturaTicketTesoreria', true);
        }else{
            EnviarEmailCreacionCaso.envioCorreo(record, 'FS_CreacionCaso', true);
        }
        //EnviarEmailCreacionCaso.envioCorreo(record, 'FS_CreacionCaso', true);
        
        if(record.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO || record.RecordTypeId == TIEMPOMATERIALSPRINTS_TIPO_REGISTRO) {
            EnviarEmailCreacionCaso.envioCorreo(record, 'FS_Creacion_de_Caso_Notificacion_al_PM', false);
            //envioCorreo
            //CaseTriggerHelper.envioCorreo(record, 'FS_Creacion_de_Caso_Notificacion_al_PM', false);    
        }
	}

    /**
     * @method      reemplazarCampos
     * @description Method to replace fields in email template
     * @author      Intellect Systems - 2025-01-26
     * @param       caso
     * @param       html
     * @param       objeto
     * @return      String
     */
    public static String reemplazarCampos(Case caso, String html, String objeto){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objeto).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.Values()){
            schema.describefieldresult dfield = sfield.getDescribe();
            String campo = dfield.getname();
            String objCampo = '{!' + objeto + '.' + campo +'}';
            if(html.contains(objCampo)){
                String valorCampo = caso.get(campo) != null ? String.valueOf(caso.get(campo)) : '';
                html = html.replace(objCampo, valorCampo);
            }
        }

        return html;
    }

    /**
     * @method      getLogoImagen
     * @description Method to assign logo in Email Template
     * @author      Intellect Systems - 2025-01-26
     * @return      String
     */
    public static String getLogoImagen(){
        StaticResource staticResource = [   SELECT Id, SystemModStamp, Name, Body
                                            FROM StaticResource 
                                            WHERE Name = 'FS_FisaLogo'
                                            LIMIT 1 ];
                                            
        String urlRecurso = '<html xmlns="http://www.w3.org/1999/xhtml"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta  name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0," /></head><body>';
        urlRecurso += '<table width="100%" ><td style="width: 25%;" /><td style="width: 50%;" ><table><tr><td><img src="';
        urlrecurso += 'data:image/png;base64,' + EncodingUtil.base64Encode(staticResource.Body);
        urlRecurso += '"/></td></tr></table>';

        return urlRecurso;
    }

    /**
     * @method      envioCorreo
     * @description Method to send email
     * @author      Intellect Systems - 2025-01-26
     * @param       caso
     * @param       nombrePlantilla
     * @param       esContacto
     */
    public static void envioCorreo(Case caso, String nombrePlantilla, Boolean esContacto){
        try{
            if(esContacto && caso.FS_OrigenCaso__c != 'Web'){
                return;
            }
            List<Messaging.SingleEmailMessage> MessageList = new List<Messaging.SingleEmailMessage>();
            EmailTemplate plantilla = mapPlantillas.get(nombrePlantilla);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String asunnto = reemplazarCampos(caso, plantilla.Subject, 'Case');
            String html = reemplazarCampos(caso, plantilla.HTMLValue, 'Case');
            String urlLogo = getLogoImagen();
            html = getLogoImagen() + html.replace('{urlSiteServicios}', Label.FS_UrlPortalServicios);
            html = html.replace('{urlSiteEncuestas}', Label.FS_UrlPortalEncuestas);
            html = html.replace('{urlSalesforceOrg}', Label.FS_urlSalesforceOrg);
            html = html.replace(']]>', '') + '</td><td style="width: 25%;" /></table></body></html>';
            html = html.replace('<![CDATA[', '');
            mail.setSubject(asunnto);
            mail.setHtmlBody(html);
            //mail.saveAsActivity = esContacto;
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setSaveAsActivity(true);
            mail.setWhatId(caso.Id);

            if(esContacto){
                User usuario = mapUser.get(userInfo.getUserId());
                if(usuario.Profile.Name != 'Customer Community User' || usuario.Profile.Name != 'Customer Community Plus User'){
                    mail.setWhatId(caso.Id);
                }

                mail.setTargetObjectId(caso.ContactId);
                String allMails = ' ';
                if(String.isNotBlank(caso.FS_CorreosNotificacionesServicios__c)){
                    if(String.isNotBlank(caso.FS_Correos_Notificaciones_PS__c) && caso.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO) {
                        allMails = caso.FS_CorreosNotificacionesServicios__c + ',' + caso.FS_Correos_Notificaciones_PS__c;
                    }else{
                        allMails = caso.FS_CorreosNotificacionesServicios__c;
                    }                
                    mail.setCcAddresses(allMails.split(','));
                }
            } else {
                //mail.setTargetObjectId(caso.Id);
                User usuario = mapUser.get(caso.OwnerId);
                mail.setBccAddresses( nombrePlantilla != 'FS_PaseProduccionAceptado' ? new List<String>{usuario.Email} : Label.FS_CorreosPaseProduccionAceptado.split(','));
                if(caso.RecordTypeId == REQUERIMIENTO_TIPO_REGISTRO && caso.Status == 'Cerrado' && caso.FS_FechaContestacionEncuesta__c != null) {
                    mail.setCcAddresses(Label.FS_KAM_Email.split(','));    
                }
            }
            MessageList.add(mail);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(MessageList);
        } catch(Exception ex) {
            System.debug(ex.getMessage()+'Error Correo ----- '+ex.getLineNumber());
        }
    }
}