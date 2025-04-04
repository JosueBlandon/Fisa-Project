import { LightningElement, track } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCaso from "@salesforce/apex/ControladorCrearCaso.getCaso";
import guardarCaso from "@salesforce/apex/ControladorCrearCaso.guardarCaso";
import urlEncuesta from '@salesforce/label/c.FS_UrlPortalEncuestas';

export default class Fs_CampoPendienteCaso extends LightningElement {

  casoId;
  showSpinner = true;
  @track data = {
    caso: {},
    listAceptaRespuesta: [],
    listMotivosRechazo: [],
    listTipoAprobacion: [],
    esConsulta: false,
    esSolicitud: false,
    esIncidentePuntual: false,
    esIncidenteDefinitivo: false,
    pendienteEncuesta: false,
    pendienteEncuestaDetalle: false,
    pendienteRespuesta: false,
    pendienteRespuestaDetalle: false,
    mostrarRechazo: false,
    botonDeshabilitado: true,
    pendienteHorasDetalle: false,
    pendienteHoras: false,
    pendienteInformacionDetalle: false,
    pendienteInformacion: false,
    pendienteInstalacionParcheDetalle: false,
    pendienteInstalacionParche: false,
    pendientePaseProduccionDetalle: false,
    pendientePaseProduccion: false,
    pendienteRespuestaPropuestaEconomica: false,
    pendienteRespuestaEntregado: false,
    pendienteRespuestaCertificado: false,
    pendienteRespuestaEnProduccion: false,
    pendientePropuestaEconomica: false,
    pendienteAnalisisPrevio: false,
    pendienteEstadoEntregado: false,
    pendienteEstadoCertificado: false,
    pendienteEstadoEnProduccion: false,
    pendienteEstadoEnProduccionRequerimiento: false,
    FechaRequerida: false,
    FechaRequeridaProd: false,
    mostrarFechaEntrega: false,
    mostrarFechaPaseProd: false,
    cometarioRequerido: false

  }

  connectedCallback() {
    this.getQueryParameters();
    this.init();
  }

  init() {
    this.showSpinner = true;
    getCaso({ casoId: this.casoId }).then(response => {
      this.data.caso = response.caso;
      console.log(this.data.caso.FS_ComentariosRespuesta__c);
      this.data.esConsulta = response.caso.FS_NombreTipoRegistro__c == 'Consulta';
      this.data.esSolicitud = response.caso.FS_NombreTipoRegistro__c == 'Solicitud (Falla Operativa)';
      this.data.esIncidentePuntual = response.caso.FS_NombreTipoRegistro__c == 'Incidente' && response.caso.FS_TipoIncidente__c == 'Puntual';
      this.data.esIncidenteDefinitivo = response.caso.FS_NombreTipoRegistro__c == 'Consulta' && response.caso.FS_TipoIncidente__c == 'Definitivo';
      this.data.listAceptaRespuesta = response.listAceptaRespuesta;
      this.data.listMotivosRechazo = response.listMotivosRechazo;
      this.data.listTipoAprobacion = response.listTipoAprobacion;
      this.data.listMotivosRechazoParche = response.listMotivosRechazoParche;
      this.data.caso.FS_Tipo_de_Aprobacion__c = '';
      this.data.caso.FS_Fecha_de_Pase_Produccion__c = '';
      this.data.caso.FS_ComentariosRespuesta__c = '';
      if (response.caso.Status === 'Certificado' && response.caso.FS_NombreTipoRegistro__c != 'Requerimiento') {
        this.data.pendienteEstadoCertificado = true;
        this.data.pendienteRespuestaCertificado = true;
      } else if ((response.caso.Status === 'Certificado' || response.caso.Status === 'En Revisión Certificado') && response.caso.FS_EnviarNotificacionCertificado__c == true) {
        this.data.pendienteEstadoCertificado = true;
        this.data.pendienteRespuestaCertificado = true;
      } else if (response.caso.Status === 'En Producción' && response.caso.FS_Quiere_Finalizar_la_Atencion_del_Caso__c == false && response.caso.FS_NombreTipoRegistro__c != 'Requerimiento') {
        this.data.pendienteEstadoEnProduccion = true;
        this.data.pendienteRespuestaEnProduccion = true;
      } else if ((response.caso.Status === 'En Producción' || response.caso.Status === 'En Revisión en Producción') && response.caso.FS_EnviarNotificacionProduccion__c == true) {
        this.data.pendienteEstadoEnProduccionRequerimiento = true;
        this.data.pendienteRespuestaEnProduccionRequerimiento = true;
      } else if (response.caso.Status === "Análisis Previo" && response.caso.FS_EnvioNotificacion__c === true) {
        this.data.pendienteAnalisisPrevio = true;
        this.data.pendienteRespuestaAnalisisPrevio = true;
      } else if (response.caso.Status === "Estimación Macro" && response.caso.FS_EnvioNotificacionEM__c === true) {
        this.data.pendienteEstimacionMacro = true;
        this.data.pendienteRespuestaEstimacionMacro = true;
      } else if (response.caso.Status === "Documento de Especificación Funcional" && response.caso.FS_EnvioNotificacionDEF__c === true) {
        this.data.pendienteDEF = true;
        this.data.pendienteRespuestaDEF = true;
      } else if (response.caso.Status === "En Propuesta Económica" && response.caso.FS_EnvioNotificacionPE__c === true) {
        this.data.pendientePropuestaEconomica = true;
        this.data.pendienteRespuestaPropuestaEconomica = true;
      } else if ((response.caso.Status === "Validación de Respuesta (Cliente)" || response.caso.Status === "En Revisión Entregado") && response.caso.FS_EnviarNotificacionEntregado__c == true && response.caso.FS_NombreTipoRegistro__c == 'Requerimiento') {
        this.data.pendienteEstadoEntregado = true;
        this.data.pendienteRespuestaEntregado = true;
      } else if ((response.caso.FS_Acepta_Propuesta_Economica__c === "No" || response.caso.Status === "Pendiente de Respuesta CSAT") && (response.caso.Status != 'Dado de Baja' && response.caso.Status != 'Cerrado')) {
        this.data.pendienteEncuesta = true;
        this.data.pendienteEncuestaDetalle = true;
      } else if (response.caso.FS_SubEstado__c === "Envío de respuesta" && response.caso.FS_AceptaRespuesta__c === undefined) {
        this.data.pendienteRespuesta = true;
        this.data.pendienteRespuestaDetalle = true;
      } else if (response.caso.FS_SubEstado__c === "Respuesta aceptada" && response.caso.Status === "Pendiente de Respuesta CSAT") {
        this.data.pendienteEncuesta = true;
        this.data.pendienteEncuestaDetalle = true;
      } else if (response.caso.FS_NombreTipoRegistro__c == 'Requerimiento' && response.caso.Status === "Dado de Baja" && response.caso.FS_FechaContestacionEncuesta__c == null) {
        this.data.pendienteEncuesta = true;
        this.data.pendienteEncuestaDetalle = true;
      } else if (response.caso.FS_SubEstado__c === "En Espera de Respuesta del Cliente" && response.caso.FS_RequiereInformacionAdicional__c === false) {
        this.data.pendienteHorasDetalle = true;
        this.data.pendienteHoras = true;
      } else if (response.caso.Status === "En Espera de Respuesta del Cliente" && response.caso.FS_RequiereInformacionAdicional__c === true) {
        this.data.pendienteInformacionDetalle = true;
        this.data.pendienteInformacion = true;
      } else if (response.caso.Status === "Análisis Previo" && response.caso.FS_RequiereInformacionAdicional__c === true) {
        this.data.pendienteInformacionDetalle = true;
        this.data.pendienteInformacion = true;
      } else if (response.caso.Status === "Estimación Macro" && response.caso.FS_RequiereInformacionAdicional__c === true) {
        this.data.pendienteInformacionDetalle = true;
        this.data.pendienteInformacion = true;
      } else if (response.caso.Status === "Documento de Especificación Funcional" && response.caso.FS_RequiereInformacionAdicional__c === true) {
        this.data.pendienteInformacionDetalle = true;
        this.data.pendienteInformacion = true;
      } else if (response.caso.FS_SubEstado__c === "En Espera de Respuesta del Cliente" && response.caso.FS_RequiereInformacionAdicional__c === true) {
        this.data.pendienteInformacionDetalle = true;
        this.data.pendienteInformacion = true;
      } else if ((response.caso.FS_SubEstado__c === "Instalación de Parche" && response.caso.FS_NombreTipoRegistro__c != 'Requerimiento') || (response.caso.FS_EnviarNotificacionEntregado__c == true && response.caso.Status === 'Validación de Respuesta (Cliente)')) {
        this.data.pendienteInstalacionParcheDetalle = true;
        this.data.pendienteInstalacionParche = true;
      } else if (response.caso.FS_SubEstado__c === "Paso a Producción" && response.caso.FS_NombreTipoRegistro__c != 'Requerimiento') {
        this.data.pendientePaseProduccionDetalle = true;
        this.data.pendientePaseProduccion = true;
      } else if (response.caso.FS_SubEstado__c === "Paso a Producción" && response.caso.FS_EnviarNotificacionCertificado__c == true) {
        this.data.pendientePaseProduccionDetalle = true;
        this.data.pendientePaseProduccion = true;
      } else if (response.caso.FS_SubEstado__c === "Paso a Producción Confirmado" && response.caso.Status === "Pendiente de Respuesta CSAT") {
        this.data.pendienteEncuesta = true;
        this.data.pendienteEncuestaDetalle = true;
      }
      this.showSpinner = false;
    }).catch(error => {
      this.showSpinner = false;
      this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su administrador.');
    });
  }

  getQueryParameters() {
    let urlCompleta = window.location.href;
    urlCompleta = urlCompleta.split("case/")[1];
    this.casoId = urlCompleta.split("/")[0];
    console.log("Caso Id: " + this.casoId)
    this.data.urlEncuesta = urlEncuesta + '/encuesta?recordId=' + this.casoId;
  }

  pushMessage(title, variant, msj) {
    const message = new ShowToastEvent({
      "title": title,
      "variant": variant,
      "message": msj
    });
    this.dispatchEvent(message);
  }

  cancelar() {
    this.data.pendienteEncuesta = false;
    this.data.pendienteRespuesta = false;
    this.data.pendienteHoras = false;
    this.data.pendienteInformacion = false;
    this.data.pendienteInstalacionParche = false;
    this.data.pendientePaseProduccion = false;
    this.data.pendientePropuestaEconomica = false;
    this.data.pendienteAnalisisPrevio = false;
    this.data.pendienteEstimacionMacro = false;
    this.data.pendienteDEF = false;
    this.data.pendienteEstadoEntregado = false;
    this.data.pendienteEstadoCertificado = false;
    this.data.pendienteEstadoEnProduccion = false;
    this.data.pendienteEstadoEnProduccionRequerimiento = false;
  }

  handleChange(event) {
    const name = event.target.name;
    const value = event.detail.value.trim() != "" ? event.detail.value.trim() : null;
    this.data.botonDeshabilitado = true;
    this.data.cometarioRequerido = false;
    console.log('name: ' + name);
    if (name === "aceptaResp") {
      this.data.caso.FS_AceptaRespuesta__c = value;
      this.data.mostrarRechazo = (value != "Si");
      this.data.caso.FS_MotivoRechazo__c = !this.data.mostrarRechazo ? null : this.data.caso.FS_MotivoRechazo__c;
    } else if (name === "aceptaAnalisisPrevio") {
      this.data.caso.FS_AceptaAnalisisPrevio__c = value;
      this.data.caso.FS_EnvioNotificacion__c = false;
      this.data.mostrarRechazo = (value != "Si");
      this.data.caso.FS_MotivoRechazo__c = !this.data.mostrarRechazo ? null : this.data.caso.FS_MotivoRechazo__c;
    } else if (name === "aceptaEstimacionMacro") {
      this.data.caso.FS_AceptaEstimacionMacro__c = value;
      this.data.caso.FS_EnvioNotificacionEM__c = false;
      this.data.mostrarRechazo = (value != "Si");
      this.data.caso.FS_MotivoRechazo__c = !this.data.mostrarRechazo ? null : this.data.caso.FS_MotivoRechazo__c;
    } else if (name === "aceptaDEF") {
      this.data.caso.FS_AceptaDEF__c = value;
      this.data.caso.FS_EnvioNotificacionDEF__c = false;
      this.data.mostrarRechazo = (value != "Si");
      this.data.caso.FS_MotivoRechazo__c = !this.data.mostrarRechazo ? null : this.data.caso.FS_MotivoRechazo__c;
    } else if (name === "motivoRechazo") {
      this.data.cometarioRequerido = true;
      this.data.caso.FS_MotivoRechazo__c = value;
      this.data.caso.FS_ComentariosRespuesta__c = '';
    } else if (name === "comentarioResp") {
      this.data.cometarioRequerido = true;
      this.data.caso.FS_ComentariosRespuesta__c = value;
    } else if (name === "aceptaHoras") {
      this.data.caso.FS_Acepta1erCosto__c = value;
    } else if (name === "motivoRechazoParche") {
      this.data.caso.FS_MotivoRechazo__c = value;
    } else if (name === "comentarioParch") {
      this.data.caso.FS_ComentariosRespuesta__c = value;
    } else if (name === "aceptaParche") {
      this.data.caso.FS_AceptaInstalacionParche__c = value;
      this.data.mostrarRechazo = (value != "Si");
      this.data.caso.FS_MotivoRechazo__c = !this.data.mostrarRechazo ? null : this.data.caso.FS_MotivoRechazo__c;
    } else if (name === "aceptaPase") {
      this.data.caso.FS_AceptaPaseProducion__c = value;
    } else if (name === "aceptaPropuesta") {
      this.data.caso.FS_Acepta_Propuesta_Economica__c = value;
      if (value == "Si") {
        this.data.botonDeshabilitado = false;
      }
      this.data.caso.FS_RequiereInformacionAdicional__c = false;
      this.data.caso.FS_EnvioNotificacionPE__c = false;
      this.data.mostrarRechazo = (value != "Si");
      this.data.caso.FS_MotivoRechazo__c = !this.data.mostrarRechazo ? null : this.data.caso.FS_MotivoRechazo__c;
    } else if (name === "aceptaEstadoEntregado") {
      //estado igual a EnTregado o En revision Entregado
      this.data.cometarioRequerido = true;
      this.data.caso.FS_AceptaRespuesta__c = value;
      this.data.mostrarRechazo = (value != "Si");
      this.data.caso.FS_MotivoRechazo__c = !this.data.mostrarRechazo ? null : this.data.caso.FS_MotivoRechazo__c;
      this.data.caso.FS_Tipo_de_Aprobacion__c = !this.data.tipoAprobacion ? null : this.data.caso.FS_Tipo_de_Aprobacion__c;
      this.data.caso.FS_ComentariosRespuesta__c = value;
      if (value == "Si") {
        //this.data.botonDeshabilitado = true;
        this.data.mostrarFechaEntrega = true;
        this.data.FechaRequerida = true;
      } else {
        this.data.mostrarFechaEntrega = false;
        this.data.FechaRequerida = false;
      }
    } else if (name === "tipoAprobacion") {
      this.data.caso.FS_Tipo_de_Aprobacion__c = value;
    } else if (name === "fechaPaseProd") {
      this.data.caso.FS_Fecha_Puesta_en_Produccion__c = '';
      this.data.caso.FS_Fecha_Puesta_en_Produccion__c = value;
      if (value == null || value == '') {
        this.data.botonDeshabilitado = true;
      }
    } else if (name === "aceptaEstadoEnProduccion") {
      //estado igual a En produccion o En revision Produccion
      this.data.caso.FS_AceptacionSolucionSalesforce__c = value;
      this.data.caso.FS_EnviarNotificacionProduccion__c = false;
      this.data.cometarioRequerido = true;
      this.data.mostrarRechazo = (value != "Si");
      this.data.caso.FS_MotivoRechazo__c = !this.data.mostrarRechazo ? null : this.data.caso.FS_MotivoRechazo__c;
      if (value == "Si") {
        //this.data.caso.Status = 'Pendiente de Respuesta CSAT';
        this.data.caso.FS_Quiere_Finalizar_la_Atencion_del_Caso__c = true;
      }
    } else if (name === "PuestaEnProduccion") {
      //estado igual a certificado o en revision certificado
      this.data.caso.FS_AceptaSolucionEnProduccion__c = value;
      this.data.cometarioRequerido = true;
      this.data.mostrarRechazo = (value != "Si");
      this.data.caso.FS_MotivoRechazo__c = !this.data.mostrarRechazo ? null : this.data.caso.FS_MotivoRechazo__c;
      if (value == "Si") {
        this.data.mostrarFechaPaseProd = true;
        this.data.FechaRequeridaProd = true;
      } else {
        this.data.mostrarFechaPaseProd = false;
        this.data.FechaRequeridaProd = false;
      }

    } else if (name === "fechaEntregaCliente") {
      this.data.caso.FS_FechaCertificacionCliente__c = '';
      this.data.caso.FS_FechaCertificacionCliente__c = value;
      if (value == null || value == '') {
        this.data.botonDeshabilitado = true;
      }
    }

    this.validarBotonPendResp();
  }

  handleChangeCheckBox(event) {
    let name = event.target.name;
    if (name === 'aceptaEstadoEnProduccion') {
      this.data.caso.FS_Quiere_Finalizar_la_Atencion_del_Caso__c = event.target.checked;
    }
  }

  guardarCaso() {
    this.data.botonDeshabilitado = true;
    if (this.data.pendienteInformacion) {
      this.data.pendienteInformacion = false;
      return;
    }
    this.showSpinner = true;
    console.log("Caso: " + this.casoId)
    guardarCaso({ casoJSON: JSON.stringify(this.data.caso) }).then(response => {
      this.cancelar();
      this.data.pendienteEncuestaDetalle = false;
      this.data.pendienteRespuestaDetalle = false;
      this.data.pendienteHorasDetalle = false;
      this.data.pendienteInformacionDetalle = false;
      this.data.pendienteInstalacionParcheDetalle = false;
      this.data.pendientePaseProduccionDetalle = false;
      this.data.pendienteRespuestaPropuestaEconomica = false;
      this.data.pendienteRespuestaEntregado = false;
      this.data.pendienteRespuestaCertificado = false;
      this.data.pendienteRespuestaEnProduccion = false;
      this.data.pendienteRespuestaEnProduccionRequerimiento = false;
      this.data.pendientePropuestaEconomica = false;
      this.data.pendienteAnalisisPrevio = false;
      this.data.pendienteEstimacionMacro = false;
      this.data.pendienteDEF = false;
      this.data.pendienteEstadoEntregado = false;
      this.data.pendienteEstadoCertificado = false;
      this.data.pendienteEstadoEnProduccion = false;
      this.data.pendienteEstadoEnProduccionRequerimiento = false;
      this.init();
      this.showSpinner = false;
      this.pushMessage('Exitoso', 'success', 'Datos guardados exitosamente');
    }).catch(error => {
      this.showSpinner = false;
      this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su administrador.');
    });
  }

  validarBotonPendResp() {
    window.console.log('entro');
    if ((this.data.caso.FS_AceptaRespuesta__c === "Si" || this.data.caso.FS_AceptaInstalacionParche__c === "Si") && (this.data.caso.Status != "Validación de Respuesta (Cliente)" && this.data.caso.Status != "En Revisión Entregado")) {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo1');
    } else if (this.data.caso.FS_AceptaRespuesta__c === "No" && this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.FS_ComentariosRespuesta__c != '') {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo4');
    } else if (this.data.caso.FS_AceptaInstalacionParche__c === "No" && this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.FS_ComentariosRespuesta__c != '') {
      window.console.log('Habilito campo14');
      this.data.botonDeshabilitado = false;
    } else if (this.data.caso.FS_Acepta1erCosto__c != null && this.data.caso.FS_SubEstado__c === "En Espera de Respuesta del Cliente") {
      window.console.log('Habilito campo13');
      this.data.botonDeshabilitado = false;
    } else if (this.data.FS_Acepta_Propuesta_Economica__c == "Si" && this.data.caso.Status == "En Propuesta Económica") {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo6');
    } else if (this.data.caso.FS_AceptaRespuesta__c === "Si" && (this.data.caso.Status != "Validación de Respuesta (Cliente)" && this.data.caso.Status != "En Revisión Entregado")) {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo2');
    } else if (this.data.caso.FS_AceptaAnalisisPrevio__c === "Si" && this.data.caso.Status == "Análisis Previo") {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo7');
    } else if (this.data.caso.FS_AceptaEstimacionMacro__c === "Si" && this.data.caso.Status == "Estimación Macro") {
      this.data.botonDeshabilitado = false;
    } else if (this.data.caso.FS_AceptaDEF__c === "Si" && this.data.caso.Status == "Documento de Especificación Funcional") {
      window.console.log('Habilito campo8');
      this.data.botonDeshabilitado = false;
    } else if (this.data.caso.FS_AceptaAnalisisPrevio__c === "No" && this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.Status == "Análisis Previo" && this.data.caso.FS_ComentariosRespuesta__c != '') {
      window.console.log('Habilito campo9');
      this.data.botonDeshabilitado = false;
    } else if (this.data.caso.FS_AceptaEstimacionMacro__c === "No" && this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.Status == "Estimación Macro" && this.data.caso.FS_ComentariosRespuesta__c != '') {
      window.console.log('Habilito campo10');
      this.data.botonDeshabilitado = false;
    } else if (this.data.caso.FS_AceptaDEF__c === "No" && this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.Status == "Documento de Especificación Funcional" && this.data.caso.FS_ComentariosRespuesta__c != '') {
      window.console.log('Habilito campo11');
      this.data.botonDeshabilitado = false;
    } else if (this.data.caso.FS_AceptaRespuesta__c === "No" && this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.FS_ComentariosRespuesta__c != '') {
      window.console.log('Habilito campo12');
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo5');
    } else if (this.data.caso.FS_AceptaRespuesta__c === "Si" && this.data.caso.FS_FechaCertificacionCliente__c != null && (this.data.caso.Status == "Validación de Respuesta (Cliente)" || this.data.caso.Status == "En Revisión Entregado")) {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo3');
    } else if (this.data.caso.FS_AceptaSolucionEnProduccion__c === "Si" && this.data.caso.FS_Fecha_Puesta_en_Produccion__c != null && (this.data.caso.Status == "Certificado" || this.data.caso.Status == "En Revisión Certificado")) {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo15');
    } else if (this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.FS_AceptaSolucionEnProduccion__c === "No" && this.data.caso.FS_ComentariosRespuesta__c != '') {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo16');
    } else if (this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.FS_AceptaAnalisisPrevio__c === "No" && this.data.caso.Status == "Análisis Previo" && this.data.caso.FS_ComentariosRespuesta__c != '') {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo17');
    } else if (this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.FS_AceptaEstimacionMacro__c === "No" && this.data.caso.Status == "Estimación Macro" && this.data.caso.FS_ComentariosRespuesta__c != '') {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo18');
    } else if (this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.FS_AceptaDEF__c === "No" && this.data.caso.Status == "Documento de Especificación Funcional" && this.data.caso.FS_ComentariosRespuesta__c != '') {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo19');
    } else if (this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.FS_Acepta_Propuesta_Economica__c === "No" && this.data.caso.Status == "En Propuesta Económica" && this.data.caso.FS_ComentariosRespuesta__c != '') {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo20');
    } else if (this.data.caso.FS_AceptacionSolucionSalesforce__c === "Si" && (this.data.caso.Status == "En Producción" || this.data.caso.Status == "En Revisión en Producción")) {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo21');
    } else if (this.data.caso.FS_MotivoRechazo__c != null && this.data.caso.FS_AceptacionSolucionSalesforce__c === "No" && this.data.caso.FS_ComentariosRespuesta__c != '') {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo22');
    } else if (this.data.caso.FS_AceptaRespuesta__c === "Si" && this.data.caso.FS_NombreTipoRegistro__c != "Requerimiento") {
      this.data.botonDeshabilitado = false;
      window.console.log('Habilito campo23');
    }
  }

  popRespuesta() {
    if (this.data.pendienteRespuestaDetalle) {
      this.data.pendienteRespuesta = true;
    } else if (this.data.pendienteHorasDetalle) {
      this.data.pendienteHoras = true;
    } else if (this.data.pendienteInformacionDetalle) {
      this.data.pendienteInformacion = true;
    } else if (this.data.pendienteInstalacionParcheDetalle) {
      this.data.pendienteInstalacionParche = true;
    } else if (this.data.pendientePaseProduccionDetalle) {
      this.data.pendientePaseProduccion = true;
    } else if (this.data.pendienteRespuestaPropuestaEconomica) {
      this.data.pendientePropuestaEconomica = true;
    } else if (this.data.pendienteRespuestaEntregado) {
      this.data.pendienteEstadoEntregado = true;
    } else if (this.data.pendienteRespuestaCertificado) {
      this.data.pendienteEstadoCertificado = true;
    } else if (this.data.pendienteRespuestaEnProduccion) {
      this.data.pendienteEstadoEnProduccion = true;
    } else if (this.data.pendienteRespuestaEnProduccionRequerimiento) {
      this.data.pendienteEstadoEnProduccionRequerimiento = true;
    } else if (this.data.pendienteRespuestaAnalisisPrevio) {
      this.data.pendienteAnalisisPrevio = true;
    } else if (this.data.pendienteRespuestaEstimacionMacro) {
      this.data.pendienteEstimacionMacro = true;
    } else if (this.data.pendienteRespuestaDEF) {
      this.data.pendienteDEF = true;
    }
  }

  get SiNo() {
    return [
      { label: 'Si', value: 'Si' },
      { label: 'No', value: 'No' },
    ];
  }

}