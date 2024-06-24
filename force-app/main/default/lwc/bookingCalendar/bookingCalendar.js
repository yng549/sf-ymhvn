import { LightningElement, track, wire, api } from "lwc";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import FullCalendarJS from "@salesforce/resourceUrl/FullCalendarJS";
import CalendarMinJs510 from "@salesforce/resourceUrl/CalendarMinJs510";
import CalendarMinCss510 from "@salesforce/resourceUrl/CalendarMinCss510";


import getBookinhServiceAll from "@salesforce/apex/BookingCalendarController.getBookinhServiceAll";
import getBookingServiceByCondition from "@salesforce/apex/BookingCalendarController.getBookingServiceByCondition";
import deleteEvent from "@salesforce/apex/FullCalendarController.deleteEvent";

import getRecentlyViewed from "@salesforce/apex/LwcEditTouchpointController.getRecentlyViewed";
import getRecentlyContactViewed from "@salesforce/apex/BookingCalendarController.getRecentlyContactViewed";
import { refreshApex } from "@salesforce/apex";
/**
 * @description: FullcalendarJs class with all the dependencies
 */
export default class BookingCalendar extends LightningElement {
  errors = [];
  recentlyViewed = [];
  _selection = [];
  @track strInput = [];
  @track strInputDetailing = [];
  @track disabledContact = true;
  @track lstIdAccount = [];
  @track lstContact = [];
  @track flagContact = true;
  @track defaultDate = new Date();

  dropdownSelectedContact = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
  dropdownUnSelectedContact = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center';

  @api
  values = [];

    
    /**
   * Load the fullcalendar.io in this lifecycle hook method
   */
  renderedCallback() {
    // Performs this operation only on first render
    if (this.fullCalendarJsInitialised) {
      return;
    }
    this.fullCalendarJsInitialised = true;

    // Executes all loadScript and loadStyle promises
    // and only resolves them once all promises are done
    Promise.all([
      loadScript(this, FullCalendarJS + "/jquery.min.js"),
      loadScript(this, FullCalendarJS + "/moment.min.js"),
      // loadScript(this, FullCalendarJS + "/fullcalendar.min.js"),
      // loadStyle(this, FullCalendarJS + "/fullcalendar.min.css"),

      //loadScript(this, MainFullJS),
      
      
      loadScript(this, CalendarMinJs510),
      loadStyle(this, CalendarMinCss510)
      //loadStyle(this, CalendarCss)
    ])
      .then(() => {
        //initialize the full calendar
        this.initialiseFullCalendarJs();
      })
      .catch((error) => {
        console.error({
          message: "Error occured on FullCalendarMain",
          error,
        });
      });
  }

  Prev() {
    console.log('this.defaultDate Prev:', this.defaultDate);
    this.defaultDate.setDate(this.defaultDate.getDate() - 1);
    this.handleFilterByParam(this.defaultDate);
    this.calendar.gotoDate(this.defaultDate);
  }
    
    

  next() {
    console.log('this.defaultDate Next:', this.defaultDate);
    this.defaultDate.setDate(this.defaultDate.getDate() + 1);
    this.handleFilterByParam(this.defaultDate);
    this.calendar.gotoDate(this.defaultDate);
  }

  changeDatePicker() {
    this.defaultDate = new Date(this.template.querySelector("lightning-input[data-id=datepicker]").value);
  
  }

  viewTimeWeek() {
    this.calendar.changeView('timeGridWeek');
  }

  @track calendar;
  initialiseFullCalendarJs() {
    const _this = this;
    const FullCalendar = window.FullCalendar;
    var tooltip = null;
    //const ele = this.template.querySelector("div.fullcalendarjs");
    var calendarEl = this.template.querySelector("div.fullcalendarjs");
    const modal = this.template.querySelector("div.modalclass");

    var self = this;
    this.calendar = new FullCalendar.Calendar(calendarEl, {
      schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
      initialView: 'resourceTimelineDay',
      headerToolbar: {
        left: '',
        center: 'title',
        right: ''
      },
      editable: true,
      resourceAreaHeaderContent: 'Employee Name',
      resources:  _this.resourcs,
      events: _this.events,
      eventClick: function(info) {
        info.jsEvent.preventDefault(); // don't let the browser navigate
    
        if (info.event.url) {
          console.log('RUL');
          console.log(info.event.url);
          window.open(info.event.url);
        }
      },
      eventDidMount: function(info) {
        console.log(1);
        console.log('LOGRENDER');
        info.el.innerHTML = '<div class="dot"></div>'+info.event.title;
        console.log(info.el.innerHTML);
      }
    });

    this.calendar.render();
  }



  @wire(getBookinhServiceAll)
  lstBookingServiceDTO(value) {
    this.eventOriginalData = value; //To use in refresh cache

    const { data, error } = value;
    if (data) {
      let events = [];
      data.forEach(e => {
        if(e.lstOrderDTO.length) {
          // e.lstOrderDTO.forEach.(element => {
          //   events.push(this.fortmatvalue(element));
          // });
          events.push(this.fortmatvalue(e.lstOrderDTO));
        }
      });
      let resourcs = this.fortmatResource(data);
      this.resourcs = JSON.parse(JSON.stringify(resourcs));
      //format as fullcalendar event object
      console.log('resourcs', resourcs);
      //let events = this.fortmatvalue(data);
      this.events = events;
      console.log('events', this.events);
      this.error = undefined;
      if (!this.eventsRendered) {
        this.resourcs.map((resource) => {
          this.calendar.addResource(resource);
        });
        console.log('this.events',this.events); 

        this.events.map((event) => {
          for(var i=0; i < event.length;i++) {
            this.calendar.addEvent( 
              {
                id: event[i].id
                , title: event[i].title
                , resourceId: event[i].resourceId
                , start: event[i].start
                , end: event[i].end
                , url: window.location.origin + '/' + event[i].id
              }
            );
          }
        });
        this.eventsRendered = true;
      }
    } else if (error) {
      this.events = [];
      this.error = "No events are found";
    }
  }

  //To save the event
  handleFilter() {
    this.openSpinner = true;
    this.events = [];
    //Close the modal
    //this.openModal = false;
    //Server call to create the event
    console.log('this.strInput', this.strInput);
    console.log('this.strInputDetailing', this.strInputDetailing);
    getBookingServiceByCondition({ 
      lstContactMechenic: this.strInput,
      lstContactDetailingStaff: this.strInputDetailing,
      dateInput: this.defaultDate})
      .then((data) => {
        let events = [];
        data.forEach(e => {
          if(e.lstOrderDTO.length) {
            // e.lstOrderDTO.forEach.(element => {
            //   events.push(this.fortmatvalue(element));
            // });
            events.push(this.fortmatvalue(e.lstOrderDTO));
          }
        });
        this.events = events;
        let resourcs = this.fortmatResource(data);

        this.calendar.removeAllEvents();// Delete Event Init

        this.resourcs.map((event) => {
          var resourceId = this.calendar.getResourceById(event.id);
          if(resourceId) {
            resourceId.remove();
          }
        });

        this.resourcs = JSON.parse(JSON.stringify(resourcs));
        this.resourcs.map((resource) => {
          this.calendar.addResource(resource);
        });

        this.events.map((event) => {
          for(var i=0; i < event.length;i++) {
            this.calendar.addEvent(
              {
                id: event[i].id
                , title: event[i].title
                , resourceId: event[i].resourceId
                , start: event[i].start
                , end: event[i].end
                , url: window.location.origin + '/' + event[i].id
              }
            );
          }
        });
        this.openSpinner = false;
        this.calendar.gotoDate(this.defaultDate);
        //show toast message
        this.showNotification(
          "Success!!",
          "Searching successfully !",
          "success" 
        );
        //return refreshApex(this.eventOriginalData);
      })
      .catch((error) => {
        console.log(error);
        this.openSpinner = false;

        //show toast message - TODO
        this.showNotification(
          "Oops",
          "Something went wrong, please review console",
          "error"
        );
      });
  }

  handleFilterByParam(value) {
    this.openSpinner = true;
    this.events = [];
    //Close the modal
    //this.openModal = false;
    //Server call to create the event
    getBookingServiceByCondition({ 
      lstContactMechenic: this.strInput,
      lstContactDetailingStaff: this.strInputDetailing,
      dateInput: value})
      .then((data) => {
        let events = [];
        data.forEach(e => {
          if(e.lstOrderDTO.length) {
            // e.lstOrderDTO.forEach.(element => {
            //   events.push(this.fortmatvalue(element));
            // });
            events.push(this.fortmatvalue(e.lstOrderDTO));
          }
        });
        this.events = events;
        console.log('events filter', this.events);
        let resourcs = this.fortmatResource(data);
        // //format as fullcalendar event object
        console.log('resourcs Filter', this.resourcs);
        // console.log('events Filter', this.events);

        this.calendar.removeAllEvents();// Delete Event Init

        this.resourcs.map((event) => {
          console.log('event.StaffId Filter', event.id);
          var resourceId = this.calendar.getResourceById(event.id);
          if(resourceId) {
            console.log('resourceId 0 ' + resourceId);
            resourceId.remove();
          }
        });

        this.resourcs = JSON.parse(JSON.stringify(resourcs));
        this.resourcs.map((resource) => {
          console.log('resource Add0',resource);
          this.calendar.addResource(resource);
        });

        this.events.map((event) => {
          console.log('event 0' + event[0].id);
          for(var i=0; i < event.length;i++) {
            let dot = "";
            dot = `<span class="fc-event-dot" style="background-color: rgb(8, 179, 148);"></span>`;
            this.calendar.addEvent(
              {
                id: event[i].id
                , title: dot  + event[i].title
                , resourceId: event[i].resourceId
                , start: event[i].start
                , end: event[i].end
              }
            );
          }
        });
        this.openSpinner = false;

        //show toast message
        this.showNotification(
          "Success!!",
          "Searching successfully !",
          "success" 
        );
        //return refreshApex(this.eventOriginalData);
      })
      .catch((error) => {
        console.log(error);
        this.openSpinner = false;

        //show toast message - TODO
        this.showNotification(
          "Oops",
          "Something went wrong, please review console",
          "error"
        );
      });
  }

  fortmatResource(data) {
    let resourcs = [];
    
    data.map((event) => {
      const start =  moment(event.DateTimeFrom).format("HH:mm:ss");
      const end =  moment(event.DateTimeTo).format("HH:mm:ss");
      const resourc = {
        id: event.StaffId,
        title: event.Name + " " + `(${start})` + ' ' + `(${end})`,
      };
      resourcs.push(resourc);
    });
    return resourcs;
  }

  fortmatvalue(data) {
    let events = [];
    data.map((event) => {
      const start =  moment(event.StartDate).format("YYYY-MM-DD HH:mm:ss");
      const end =  moment(event.EndDate).format("YYYY-MM-DD HH:mm:ss");
      let description = "";
      let popoverContent = "";

      description = `
        <p style="font-size:13px;font-weight:bold;">${
          event.OrderNumber ? event.OrderNumber : ""
        }</p>
        ${start}
        <br/>
        ${end}`;

        popoverContent = `
            <article>
            <div class="tooltip-header">
                <h2 class="slds-card__header-title">
                <a href="#" class="slds-card__header-link slds-truncate" title="${event.OrderNumber}">
                    <span>${event.OrderNumber}</span>
                </a>
                </h2>
            </div>
            <dl class="tooltip-content">
                <dt>Loại dịch vụ: </dt>
                <dd>${event.RecordTypeName ? event.RecordTypeName : ""}</dd>
            </dl>
            <dl class="tooltip-content">
                <dt>StartDate: </dt>
                <dd>${start}</dd>
            </dl>
            <dl class="tooltip-content">
                <dt>EndDate: </dt>
                <dd>${end}</dd>
            </dl>          
            </article>        
      `;
      const calendarEvent = {
        id: event.Id,
        title: event.OrderNumber,
        resourceId: event.ResourceId,
        start: start,
        end: end,
        // //allDay : event.IsAllDayEvent,
        description: description,
        popoverContent: popoverContent
      };
      events.push(calendarEvent);
    });
    return events;
  }




    @api
    detailingValues = [];

    @track
    selectedvalues = [];

    @api
    picklistlabel = 'Status';

    showdropdown;
    showdropdownDetailing;

    handleleave() {
        let sddcheck= this.showdropdown;

        if(sddcheck){
            this.showdropdown = false;
            this.fetchSelectedValues();
        }
    }

    //START POPUP EDIT
    @track selectedEvent = undefined;
    recordIdBooking = '';


    closeModal(){
      this.selectedEvent = undefined;
    }

    handleSuccess(event) {
      console.log('Record Id ' + event.detail.id);
      const evt = new ShowToastEvent({
          title: "The Booking updated",
          message: "The booking has been update.",
          variant: "success"
      });
      this.dispatchEvent(evt);
      setTimeout(() => {
          this.selectedEvent = undefined;
      }, 3000);
      setTimeout(() => {
        window.location.reload();
    }, 4500);
      
    }
    //END POPUP EDIT

    handleleaveDetailing() {
        let sddcheck= this.showdropdownDetailing;

        if(sddcheck){
            this.showdropdownDetailing = false;
        }
    }

    //Selected push value status in avarible
    fetchSelectedValues() {
        this.selectedvalues = [];
        //get all the selected values
        this.template.querySelectorAll('c-list-item-status').forEach(
            element => {
                if(element.selected){
                    console.log(element.value);
                    this.selectedvalues.push(element.value);
                }
            }
        );
        //refresh original list
        this.refreshOrginalList();
    }

    refreshOrginalList() {
        //update the original value array to shown after close
        const picklistvalues = this.values.map(eachvalue => ({...eachvalue}));
        picklistvalues.forEach((element, index) => {
            if(this.selectedvalues.includes(element.value)){
                picklistvalues[index].selected = true;
            }else{
                picklistvalues[index].selected = false;
            }
        });

        this.values = picklistvalues;
    }

    handleShowdropdown(){
        let sdd = this.showdropdown;
        if(sdd){
            this.showdropdown = false;
            this.fetchSelectedValues();
        }else{
            this.showdropdown = true;
        }
    }

    closePill(event){
        console.log(event.target.dataset.value);
        let selection = event.target.dataset.value;
        let selectedpills = this.selectedvalues;
        console.log(selectedpills);
        let pillIndex = selectedpills.indexOf(selection);
        console.log(pillIndex);
        this.selectedvalues.splice(pillIndex, 1);
        this.refreshOrginalList();
    }

    get selectedmessage() {
        return this.selectedvalues.length + ' values are selected';
    }

    get selectedContactMessage() {
        return this.strInput.length + ' values are selected'; 
    }

    get selectedContactDetaillingMessage() {
        return this.strInputDetailing.length + ' values are selected'; 
    }

  @wire(getRecentlyViewed)
  getRecentlyViewed({ data }) {
    if (data) {
      this.recentlyViewed = data;
      this.initLookupDefaultResults();
    }
  }

  connectedCallback() {
    this.initLookupDefaultResults();
    //this.handleInitStatus();
    this.handleLookupSelectionChange();
    this.handleLookupSelectionDetailingChange();
  }

  /**
   * Initializes the lookup default results with a list of recently viewed records (optional)
   */
  initLookupDefaultResults() {
    // Make sure that the lookup is present and if so, set its default results
    const lookup = this.template.querySelector("c-lookup");
    if (lookup) {
      lookup.setDefaultResults(this.recentlyViewed);
    }
  }

  @api
  isValid() {
    this.checkForErrors();
    return !this.errors.length;
  }

  // handleInitStatus() {
  //   let options = [];
  //   getStatusInitial()
  //       .then((result) => {
  //       for(var key in result){
  //           let option = {
  //               value: key,
  //               label: result[key],
  //               selected: false
  //           };
  //           options.push(option);
  //       }
        
  //       this.values = options;
  //       console.log(this.values);
  //   });
  //   this.checkForErrors();
  // }

  // User has changed the selection
  handleLookupSelectionChange() {
    let options = [
      {
        value: "All",
        label: "All",
        class: 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small'
      },
    ];
    this.disabledContact = false;
    getRecentlyContactViewed({strContactType : 'Mechanic'})
    .then((result) => {
        this.lstContact = result;
        for (let obj of result) {
        let option = {
            value: obj.Id,
            label: obj.Name,
            class: 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small'
        };
            options.push(option);
        }
        this.inputOptions = options;
    })
    .catch((e) => {});
    this.checkForErrors();
  }

  // User has changed the selection
  handleLookupSelectionDetailingChange() {
    let options = [
      {
        value: "All",
        label: "All",
        class: 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small'
      },
    ];
    this.disabledContact = false;
    getRecentlyContactViewed({strContactType : 'Detailing Staff'})
    .then((result) => {
        for (let obj of result) {
        let option = {
            value: obj.Id,
            label: obj.Name,
            class: 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small'
        };
            options.push(option);
        }
        this.inputOptionStatus = options;
    })
    .catch((e) => {});
    this.checkForErrors();
  }

  // Displays an error message if something is wrong
  checkForErrors() {
    this.errors = [];
  }

  //c/assignmentRuleItem
  @api label = "Staff";
  _disabled = false;
  @api
  get disabled() {
    return this._disabled;
  }
  set disabled(value) {
    this._disabled = value;
    this.handleDisabled();
  }
  @track inputOptions;
  @track inputOptionStatus;

  @api
  get options() {
    return this.inputOptions.filter((option) => option.value !== "All");
  }
  set options(value) {
    let options = [
      {
        value: "All",
        label: "All",
      },
    ];
    this.inputOptions = options.concat(value);
  }

  @api
  get optionDetailings() {
    return this.inputOptionStatus.filter((option) => option.value !== "All");
  }
  set optionDetailings(value) {
    let options = [
      {
        value: "All",
        label: "All",
      },
    ];
    this.inputOptionStatus = options.concat(value);
  }

  @api
  clear() {
    this.handleAllOption();
  }
  value = [];

  handleDisabled() {
    let input = this.template.querySelector("input");
    if (input) {
      input.disabled = this.disabled;
    }
  }

  comboboxIsRendered;
  handleClick() {
    // Khi click vào combobox
    let sldsCombobox = this.template.querySelector(".slds-combobox");
    sldsCombobox.classList.toggle("slds-is-open");
    if (!this.comboboxIsRendered) {
      this.comboboxIsRendered = true;
    }
  }

  comboboxDetaillingIsRendered;
  handleClickDetailling() {
    let checkClick = this.showdropdownDetailing;
    if(!checkClick) {
        this.showdropdownDetailing = true;
        // Khi click vào combobox
        let sldsCombobox = this.template.querySelector(".slds-combobox_detailing");
        sldsCombobox.classList.toggle("slds-is-open");
        if (!this.comboboxDetaillingIsRendered) {
        this.comboboxDetaillingIsRendered = true;
        }
    }  else {
        this.showdropdownDetailing = false;
    }
  }

  handleSelection(event) {
    let value = event.currentTarget.dataset.value;
    if (value === "All") {
      this.handleAllOption();
    } else {
      this.handleOption(event, value);
      let input = this.template.querySelector("input");
        input.focus();
        let values = [];
        for (const valueObject of this.value) {
            values.push(valueObject.value);
        }
        this.strInput = values;
    }
    console.log(this.strInput);
  }

  handleAllOption() {
    this.strInput = [];
    for (let i = 0; i < this.inputOptions.length; i++) {
        if(this.inputOptions[i].label != 'All') {
            if(this.inputOptions[i].class.includes('slds-is-selected')) {
                this.inputOptions[i].class = this.dropdownUnSelectedContact;
            } else {
                this.strInput.push(this.inputOptions[i].value);
                this.inputOptions[i].class = this.dropdownSelectedContact;
            }
        }
    }
    this.closeDropbox();
  }

  handleOption(event, value) {
    let listBoxOption = event.currentTarget.firstChild;
    if (listBoxOption.classList.contains("slds-is-selected")) {
      this.value = this.value.filter((option) => option.value !== value);
    } else {
      let allOption = this.template.querySelector('[data-id="All"]');
      allOption.firstChild.classList.remove("slds-is-selected");
      let option = this.options.find((option) => option.value === value);
      this.value.push(option);
    }
    if (this.value.length > 1) {
      this.inputValue = this.value.length + " options selected";
    } else if (this.value.length === 1) {
      this.inputValue = this.value[0].label;
    }
    listBoxOption.classList.toggle("slds-is-selected");
  }

  //DETAILING
  valueDetailing  = [];
  handleSelectionDetailing(event) {
    let value = event.currentTarget.dataset.value;
    if (value === "All") {
      this.handleAllOptionDetailing();
    } else {
      this.handleDetailingOption(event, value);
        let values = [];
        for (const valueObject of this.valueDetailing) {
            values.push(valueObject.value);
        }
        this.strInputDetailing = values;
    }
    console.log(this.strInputDetailing);
  }

  handleAllOptionDetailing() {
    this.strInputDetailing = [];
    for (let i = 0; i < this.inputOptionStatus.length; i++) {
        if(this.inputOptionStatus[i].label != 'All') {
            if(this.inputOptionStatus[i].class.includes('slds-is-selected')) {
                this.inputOptionStatus[i].class = this.dropdownUnSelectedContact;
            } else {
                this.strInputDetailing.push(this.inputOptionStatus[i].value);
                this.inputOptionStatus[i].class = this.dropdownSelectedContact;
            }
        }
    }
    this.closeDetailingDropbox();
  }

  handleDetailingOption(event, value) {
    let listBoxOption = event.currentTarget.firstChild;
    if (listBoxOption.classList.contains("slds-is-selected")) {
        this.valueDetailing = this.valueDetailing.filter((option) => option.value !== value);
    } else {
      let allOption = this.template.querySelector('[data-id="All"]');
      allOption.firstChild.classList.remove("slds-is-selected");
      let option = this.optionDetailings.find((option) => option.value === value);
      this.valueDetailing.push(option);
    }
    this.strInputDetailing = this.valueDetailing;
    for (let i = 0; i < this.inputOptionStatus.length; i++) {
      if(this.inputOptionStatus[i].label != 'All') {
        if(this.inputOptionStatus[i].value == value) {
          if(this.inputOptionStatus[i].class.includes('slds-is-selected')) {
              this.inputOptionStatus[i].class = this.dropdownUnSelectedContact;
          } else {
              this.inputOptionStatus[i].class = this.dropdownSelectedContact;
          }
        }
      }
  }
  }

  //MECHANIC
  dropDownInFocus = false;
  handleBlur() {
    if (!this.dropDownInFocus) {
      this.closeDropbox();
    }
  }

  handleMouseleave() {
    this.dropDownInFocus = false;
  }
  handleMouseEnter() {
    this.dropDownInFocus = true;
  }
  closeDropbox() {
    let sldsCombobox = this.template.querySelector(".slds-combobox");
    sldsCombobox.classList.remove("slds-is-open");
  }

  //Start DETAILING
  dropDownDetaillingInFocus = false;
  handleBlurStatus() {
    if (!this.dropDownDetaillingInFocus) {
      this.closeDetailingDropbox();
    }
  }

  handleDetailingMouseleave() {
    this.dropDownDetaillingInFocus = false;
  }
  handleDetailingMouseEnter() {
    this.dropDownDetaillingInFocus = true;
  }
  closeDetailingDropbox() {
    let sldsCombobox = this.template.querySelector(".slds-combobox_detailing");
    sldsCombobox.classList.remove("slds-is-open");
  }
  //End Colunm 2-12

  //To avoid the recursion from renderedcallback
  fullCalendarJsInitialised = false;

  //Fields to store the event data -- add all other fields you want to add
  popover = null;
  title;
  startDate;
  endDate;

  eventsRendered = false; //To render initial events only once
  openSpinner = false; //To open the spinner in waiting screens
  openModal = false; //To open form

  @track
  events = []; //all calendar events are stored in this field
  @track resourcs = [];
  //To store the orignal wire object to use in refreshApex method
  eventOriginalData = [];

  //Get data from server - in this example, it fetches from the event object
  
  

  //TODO: add the logic to support multiple input texts
  handleKeyup(event) {
    this.title = event.target.value;
  }

  //To close the modal form
  handleCancel(event) {
    this.openModal = false;
  }


  /**
   * @documentation: https://fullcalendar.io/docs/v3/removeEvents
   */
  removeEvent(event) {
    //open the spinner
    this.openSpinner = true;

    //delete the event from server and then remove from UI
    let eventid = event.target.value;
    deleteEvent({ eventid: eventid })
      .then((result) => {
        console.log(result);
        const ele = this.template.querySelector("div.fullcalendarjs");
        console.log(eventid);
        $(ele).fullCalendar("removeEvents", [eventid]);

        this.openSpinner = false;

        //refresh the grid
        return refreshApex(this.eventOriginalData);
      })
      .catch((error) => {
        console.log(error);
        this.openSpinner = false;
      });
  }

  /**
   *  @description open the modal by nullifying the inputs
   */
  addEvent(event) {
    this.startDate = null;
    this.endDate = null;
    this.title = null;
    this.openModal = true;
  }

  /**
   * @description method to show toast events
   */
  showNotification(title, message, variant) {
    console.log("enter");
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(evt);
  }

  get popoverContentElement() {
    return this.template.querySelector('[data-id="popovercontent"]');
  }

  get containerElement() {
    return this.template.querySelector('[data-id="fullCalendarContainer"]');
  }

  constructor() {
    super();
  }
}