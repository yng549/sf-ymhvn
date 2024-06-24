import { LightningElement, track, wire, api } from "lwc";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import FullCalendarJS from "@salesforce/resourceUrl/FullCalendarJS";
import CalendarMinJs510 from "@salesforce/resourceUrl/CalendarMinJs510";
import CalendarMinCss510 from "@salesforce/resourceUrl/CalendarMinCss510";
import deleteEvent from "@salesforce/apex/FullCalendarController.deleteEvent";

import getRosterAll from "@salesforce/apex/CalendarRosterSalesController.getRosterAllByResource";
import getRosterByConditon from "@salesforce/apex/CalendarRosterSalesController.getRosterByConditon";
import getRecentlyContactViewed from "@salesforce/apex/CalendarRosterSalesController.getRecentlyContactViewed";

import { refreshApex } from "@salesforce/apex";

export default class CalendarRosterSales extends LightningElement {
  errors = [];
  recentlyViewed = [];
  _selection = [];
  @track strInput = [];
  @track strInputDetailing = [];
  @track disabledContact = true;
  @track lstContact = [];
  @track defaultDate = new Date();
  initDate = new Date().toISOString().substring(0, 10);

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
    console.log('this.defaultDate:', this.defaultDate);
    this.defaultDate.setMonth(this.defaultDate.getMonth() - 1);
    console.log('this.defaultDate Prev:', this.defaultDate);
    this.handleFilterByParam(this.defaultDate);
    this.calendar.gotoDate(this.defaultDate);
  }
    
  actionFilter() {
    this.handleFilterByParam(new Date(this.defaultDate).toISOString());
    this.calendar.gotoDate(new Date(this.defaultDate).toISOString());
  } 

  next() {
    console.log('this.defaultDate:', this.defaultDate);
    this.defaultDate.setMonth(this.defaultDate.getMonth() + 1);
    console.log('this.defaultDate Next:', this.defaultDate);
    this.initDate = this.defaultDate.toISOString().substring(0, 10);
    this.handleFilterByParam(this.defaultDate);
    this.calendar.gotoDate(this.defaultDate);
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
      initialView: 'resourceTimelineMonth',
      headerToolbar: {
        left: '',
        center: 'title',
        right: ''
      },
      slotLabelFormat: [
        { weekday: 'short' , day: '2-digit', month: '2-digit'}
      ],
      editable: true,
      resourceAreaHeaderContent: 'Employee Name',
      resources:  _this.resourcs,
      events: _this.events,
      eventStartditable: false,
      eventDurationEditable:false,
      displayEventTime: false,
      slotMinTime: "07:00",
      slotMaxTime: "18:00",
      businessHours: {
        // days of week. an array of zero-based day of week integers (0=Sunday)
        daysOfWeek: [ 1, 2, 3, 4, 5, 6, 7, 0], // Monday - Thursday
      
        startTime: '07:00', // a start time (10am in this example)
        endTime: '18:00', // an end time (6pm in this example)
      },
      eventRender: function(info) {
        console.log('Line132');
        // if (info.event.extendedProps.isAbsent) {
        //   info.el.style.backgroundColor = 'red';
        // } else {
        //   info.el.style.backgroundColor = 'green';
        // }
      },
      
      eventClick: function(info) {
        info.jsEvent.preventDefault(); // don't let the browser navigate
    
        if (info.event.url) {
          window.open(info.event.url);
        }
      }
    });

    this.calendar.render();
  }





  @wire(getRosterAll)
  getRosterManagementDTO(value) {
    this.eventOriginalData = value; //To use in refresh cache

    const { data, error } = value;
    if (data) {
      let events = [];
      if(data.result) {
        data.result.forEach(e => {
          if(e.lstRosterManagerDTO.length) {
            events.push(this.fortmatvalue(e.lstRosterManagerDTO));
          }
        });
        let resourcs = this.fortmatResource(data.result);
        this.resourcs = JSON.parse(JSON.stringify(resourcs));
        //format as fullcalendar event object
        this.events = events;
        this.error = undefined;
        if (!this.eventsRendered) {
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
                  , isAbsent: event[i].isAbsent
                  , url: window.location.origin + '/' + event[i].id
                  , backgroundColor: event[i].isAbsent ? '#8B0000' : '#3788d8'
                  , borderColor: event[i].isAbsent ? '#8B0000' : '#3788d8'
                }
              );
            }
          });
          this.eventsRendered = true;
        }
      }
    } else if (error) {
      this.events = [];
      this.error = data.error;
      this.showNotification('Error', this.error, 'error');
    }
  }

  doneTypingInterval = 1000;
  typingTimer;
  errorMsg;
  

  handleFilterByParam(value) {
    this.openSpinner = true;
    this.events = []; 
    this.typingTimer = setTimeout(() => {
      getRosterByConditon({ 
        lstStringContact: this.strInput,
        dteDate: value
      }).then(data => {
          if(data.success) {
            let events = [];
            console.log('data.result :' + JSON.stringify(data.result));
            data.result.forEach(e => {
              if(e.lstRosterManagerDTO.length) {
                events.push(this.fortmatvalue(e.lstRosterManagerDTO));
              }
            });
            this.events = events;
            let resourcs = this.fortmatResource(data.result);
    
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
                    , isAbsent: event.isAbsent
                    , url: window.location.origin + '/' + event[i].id
                    , backgroundColor: event[i].isAbsent ? '#8B0000' : '#3788d8'
                  , borderColor: event[i].isAbsent ? '#8B0000' : '#3788d8'
                  }
                );
              }
            });
            this.calendar.gotoDate(this.defaultDate);
            //show toast message
            this.showNotification(
              "Success!!",
              "Searching successfully !",
              "success" 
            );
              
          } else {
              this.resourcs.map((event) => {
                var resourceId = this.calendar.getResourceById(event.id);
                if(resourceId) {
                  resourceId.remove();
                }
              });
              this.showToastMessage(data.error, 'Error');
          }
      })
      .catch(error => {
        this.openSpinner = false;

        //show toast message - TODO
        this.showNotification(
          "Oops",
          "Something went wrong, please review console",
          "error"
        );
      })
      .finally(() => {
        this.openSpinner = false;
      });
    }, this.doneTypingInterval);
  }

  fortmatResource(data) {
    let resourcs = [];
    
    data.map((event) => {
      const resourc = {
        id: event.Id,
        title: event.Name ,
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
      const startTime = moment(event.StartDate).format("HH:mm");
      const endTime = moment(event.EndDate).format("HH:mm");

      const calendarEvent = {
        id: event.Id,
        title: startTime + '-' + endTime,
        resourceId: event.StaffId,
        isAbsent: event.isAbsent,
        start: start,
        end: end,
      };
      events.push(calendarEvent);
    });
    return events;
  }

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

  @wire(getRecentlyContactViewed)
  getRecentlyContactViewed({ data }) {
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
    getRecentlyContactViewed()
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
    console.log('value selected:' + value);
    let listBoxOption = event.currentTarget.firstChild;
    if (listBoxOption.classList.contains("slds-is-selected")) {
      
      this.value = this.value.filter((option) => option.value !== value);
      console.log('this.value Case1:' + JSON.stringify(this.value));
    } else {
      let allOption = this.template.querySelector('[data-id="All"]');
      allOption.firstChild.classList.remove("slds-is-selected");

      let option = this.options.find((option) => option.value === value);
      console.log('this.option selection:' + JSON.stringify(this.options));
      this.value.push(option);
      console.log('this.value Case2:' + JSON.stringify(this.value));
    }
    
    if (this.value.length > 1) {
      this.inputValue = this.value.length + " options selected";
    } else if (this.value.length === 1) {
      this.inputValue = this.value[0].label;
    }
    listBoxOption.classList.toggle("slds-is-selected");
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

  @track events = []; //all calendar events are stored in this field
  @track resourcs = [];
  //To store the orignal wire object to use in refreshApex method
  eventOriginalData = [];

  //Get data from server - in this example, it fetches from the event object
  
  

  //TODO: add the logic to support multiple input texts
  handleKeyup(event) {
    this.title = event.target.value;
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

  showToastMessage(msg, type) {
    this.dispatchEvent(
        new ShowToastEvent({
            variant: type,
            message: msg
        })
    );
}
}