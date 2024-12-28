import { LightningElement, track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import logoFisa from '@salesforce/resourceUrl/FS_FisaLogo';
import logoLike from '@salesforce/resourceUrl/FS_LogoLike';
import logoMuyInsatisfecho from '@salesforce/resourceUrl/FS_LogoMuyInsatisfecho';
import logoInsatisfecho from '@salesforce/resourceUrl/FS_LogoInsatisfecho';
import logoNeutral from '@salesforce/resourceUrl/FS_LogoNeutral';
import logoSatisfecho from '@salesforce/resourceUrl/FS_LogoSatisfecho';
import logoMuySatisfecho from '@salesforce/resourceUrl/FS_LogoMuySatisfecho';
import getCaso from "@salesforce/apex/ControladorEncuesta.getCaso";
import actualizarCaso from "@salesforce/apex/ControladorEncuesta.actualizarCaso";
import logoUno from '@salesforce/resourceUrl/FS_Uno';
import logoDos from '@salesforce/resourceUrl/FS_Dos';
import logoTres from '@salesforce/resourceUrl/FS_Tres';
import logoCuatro from '@salesforce/resourceUrl/FS_Cuatro';
import logoCinco from '@salesforce/resourceUrl/FS_Cinco';
import logoSeis from '@salesforce/resourceUrl/FS_Seis';
import logoSiete from '@salesforce/resourceUrl/FS_Siete';
import logoOcho from '@salesforce/resourceUrl/FS_Ocho';
import logoNueve from '@salesforce/resourceUrl/FS_Nueve';
import logoDiez from '@salesforce/resourceUrl/FS_Diez';

export default class Fs_Encuesta extends LightningElement {

    @track data = {
        logoFisa: logoFisa,
        logoMuyInsatisfecho: logoMuyInsatisfecho,
        logoInsatisfecho: logoInsatisfecho,
        logoNeutral: logoNeutral,
        logoSatisfecho: logoSatisfecho,
        logoMuySatisfecho: logoMuySatisfecho,
        logoLike: logoLike,
        logoUno: logoUno,
        logoDos: logoDos,
        logoTres: logoTres,
        logoCuatro: logoCuatro,
        logoCinco: logoCinco,
        logoSeis: logoSeis,
        logoSiete: logoSiete,
        logoOcho: logoOcho,
        logoNueve: logoNueve,
        logoDiez: logoDiez,
        casoObjeto: {},
        parametros: {}
    }

    showSpinner = true;

    connectedCallback() {
        this.data.parametros = this.getQueryParameters();
        console.log(this.data.parametros.recordId);
        this.getColorBlanco();
        this.init();
    }

    init() {
        this.showSpinner = true;
        getCaso({recordId: this.data.parametros.recordId, resultado: this.data.casoObjeto.resultadoEncuesta, resultadoNumero: this.data.casoObjeto.resultadoEncuestaNumero}).then(response => {
            this.data.casoObjeto = response;
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            console.log("Error: "+JSOn.stringify(error));
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su administrador.');
        });
    }

    onclickImg(event){
        this.getColorBlanco();
        const name = event.target.name;
        this.data.casoObjeto.mostrarMotivo = false;
        let color = "background-color:#57b888;";
        if(name === "logoMuyInsatisfecho"){
            this.data.styleLogoMuyInsatisfecho = color;
            this.data.casoObjeto.mostrarMotivo = true;
            this.data.casoObjeto.resultadoEncuesta = "Muy Insatisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoInsatisfecho"){
            this.data.styleLogoInsatisfecho= color;
            this.data.casoObjeto.mostrarMotivo = true;
            this.data.casoObjeto.resultadoEncuesta = "Insatisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoNeutral"){
            this.data.styleLogoNeutral= color;
            this.data.casoObjeto.resultadoEncuesta = "Neutral";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoSatisfecho"){
            this.data.styleLogoSatisfecho= color;
            this.data.casoObjeto.resultadoEncuesta = "Satisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoMuySatisfecho"){
            this.data.styleLogoMuySatisfecho = color;
            this.data.casoObjeto.resultadoEncuesta = "Muy Satisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoUno"){
            this.data.stylelogoUno = color;
            this.data.casoObjeto.mostrarMotivo = true;
            this.data.casoObjeto.resultadoEncuestaNumero = "1";
            this.data.casoObjeto.resultadoEncuesta = "Muy Insatisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoDos"){
            this.data.stylelogoDos = color;
            this.data.casoObjeto.mostrarMotivo = true;
            this.data.casoObjeto.resultadoEncuestaNumero = "2";
            this.data.casoObjeto.resultadoEncuesta = "Muy Insatisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoTres"){
            this.data.stylelogoTres = color;
            this.data.casoObjeto.mostrarMotivo = true;
            this.data.casoObjeto.resultadoEncuestaNumero = "3";
            this.data.casoObjeto.resultadoEncuesta = "Muy Insatisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoCuatro"){
            this.data.stylelogoCuatro = color;
            this.data.casoObjeto.mostrarMotivo = true;
            this.data.casoObjeto.resultadoEncuestaNumero = "4";
            this.data.casoObjeto.resultadoEncuesta = "Muy Insatisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoCinco"){
            this.data.stylelogoCinco= color;
            this.data.casoObjeto.mostrarMotivo = true;
            this.data.casoObjeto.resultadoEncuestaNumero = "5";
            this.data.casoObjeto.resultadoEncuesta = "Insatisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoSeis"){
            this.data.stylelogoSeis= color;
            this.data.casoObjeto.mostrarMotivo = true;
            this.data.casoObjeto.resultadoEncuestaNumero = "6";
            this.data.casoObjeto.resultadoEncuesta = "Insatisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoSiete"){
            this.data.stylelogoSiete= color;
            this.data.casoObjeto.resultadoEncuestaNumero = "7";
            this.data.casoObjeto.resultadoEncuesta = "Neutral";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoOcho"){
            this.data.stylelogoOcho= color;
            this.data.casoObjeto.resultadoEncuestaNumero = "8";
            this.data.casoObjeto.resultadoEncuesta = "Neutral";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoNueve"){
            this.data.stylelogoNueve= color;
            this.data.casoObjeto.resultadoEncuestaNumero = "9";
            this.data.casoObjeto.resultadoEncuesta = "Satisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }else if(name === "logoDiez"){
            this.data.stylelogoDiez = color;
            this.data.casoObjeto.resultadoEncuestaNumero = "10";
            this.data.casoObjeto.resultadoEncuesta = "Muy Satisfecho";
            this.template.querySelector('form').reset();
            this.init();
        }
        this.habilitarBoton();
    }

    getColorBlanco(){
        let style = "background-color: ffffff; ";
        this.data.styleLogoMuyInsatisfecho = style;
        this.data.styleLogoInsatisfecho = style;
        this.data.styleLogoNeutral= style;
        this.data.styleLogoSatisfecho = style;
        this.data.styleLogoMuySatisfecho = style;

        this.data.stylelogoUno = style;
        this.data.stylelogoDos = style;
        this.data.stylelogoTres = style;
        this.data.stylelogoCuatro = style;
        this.data.stylelogoCinco = style;
        this.data.stylelogoSeis = style;
        this.data.stylelogoSiete = style;
        this.data.stylelogoOcho = style;
        this.data.stylelogoNueve = style;
        this.data.stylelogoDiez = style;
    }

    onchangeMotivo(event){
        const name = event.target.name;
        const value = event.detail.value.trim() != "" ? event.detail.value.trim() : null;

        if(name === "motivo") {
            this.data.casoObjeto.motivoSeleccionado = value;
        }else if(name === "comentarios") {
            this.data.casoObjeto.comentarios = value;
        }
        this.habilitarBoton();
    }

    habilitarBoton() {
        let resultadoEncuesta = this.data.casoObjeto.resultadoEncuesta;
        let resultadoEncuestaNumero = this.data.casoObjeto.resultadoEncuestaNumero;
        if(resultadoEncuesta === 'Satisfecho' || resultadoEncuesta === 'Muy Satisfecho' || resultadoEncuestaNumero === '9' || resultadoEncuestaNumero === '10') {
            this.data.casoObjeto.deshabilitarBoton = false;
        } else if(this.data.casoObjeto.motivoSeleccionado != null && (this.data.casoObjeto.comentarios != null || this.data.casoObjeto.comentarios != undefined)) {
            this.data.casoObjeto.deshabilitarBoton = false;
        } else {
            this.data.casoObjeto.deshabilitarBoton = true;
        }
    }

    enviarEncuesta(){
        this.showSpinner = true;
        actualizarCaso({jsonCaso: JSON.stringify(this.data.casoObjeto)}).then(response => {
            this.pushMessage('Exitoso', 'success', 'Encuesta creada exitosamente.');
            this.showSpinner = false;
            this.data.casoObjeto.esCerrado = true;
        }).catch(error => {
            this.showSpinner = false;
            if(JSON.stringify(error).includes('Debe ingresar el Motivo de Calificación de la encuesta.')) {
                this.pushMessage('Error', 'error', 'Debe ingresar el Motivo de Calificación de la encuesta.');
            } else {
                this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su administrador.');
            }
        });
    }

    getQueryParameters() {
        var params = {};
        var search = location.search.substring(1);
        if (search) {
            params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
                return key === "" ? value : decodeURIComponent(value)
            });
        }
        return params;
    }

    pushMessage(title,variant,msj){
        const message = new ShowToastEvent({
            "title": title,
            "variant": variant,
            "message": msj
            });
        this.dispatchEvent(message);
    }
}