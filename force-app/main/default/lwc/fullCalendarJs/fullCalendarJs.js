import { LightningElement, track, wire, api } from "lwc";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FullCalendarJS from "@salesforce/resourceUrl/FullCalendarJS";
import fetchEvents from "@salesforce/apex/FullCalendarController.getRosterAll";
import getRosterByContactId from "@salesforce/apex/FullCalendarController.getRosterByContactId";
import deleteEvent from "@salesforce/apex/FullCalendarController.deleteEvent";

import getRecentlyContactViewed from "@salesforce/apex/FullCalendarController.getRecentlyContactViewed";
import { refreshApex } from "@salesforce/apex";
/**
 * @description: FullcalendarJs class with all the dependencies
 */
export default class FullCalendarJs extends LightningElement {
  errors = [];
  recentlyViewed = [];
  strInput = [];
  @track disabledContact = true;
  lstContact = [];
  @track flagContact = true;
  dropdownSelectedContact = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
  dropdownUnSelectedContact = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center';
  //Region Colunm 2-12
  /**
   * Loads recently viewed records and set them as default lookpup search results (optional)
   */
  

  connectedCallback() {
    this.handleLookupSelectionChange();
  }




  @api
  isValid() {
    this.checkForErrors();
    return !this.errors.length;
  }

  get selectedContactMessage() {
    return this.strInput.length + ' values are selected'; 
  }


  handleLookupSelectionChange() {
    let options = [
      {
        value: "All",
        label: "All",
        class: this.dropdownUnSelectedContact
      },
    ];
    this.disabledContact = false;
    getRecentlyContactViewed().then(apiResponse => {
      if(apiResponse.success) {
            this.lstContact = apiResponse.result;
            for (let obj of this.lstContact) {
            let option = {
                value: obj.Id,
                label: obj.Name,
                class: this.dropdownUnSelectedContact
            };
                options.push(option);
            }
            this.inputOptions = options;
          } else {
              this.showToastMessage(apiResponse.error, 'Error');
          }
      })
      .catch(error => {
          this.isShowSpinner = false;
          if(error) {
              if (Array.isArray(error.body)) {
                  this.errorMsg = error.body.map(e => e.message).join(', ');
              } else if (typeof error.body.message === 'string') {
                  this.errorMsg = error.body.message;
              }
          }
      })
      this.checkForErrors();
  }



  showToastMessage(msg, type) {
    this.dispatchEvent(
        new ShowToastEvent({
            variant: type,
            message: msg
        })
    );
}

  // Displays an error message if something is wrong
  checkForErrors() {
    this.errors = [];
  }

  // Shows a toast in case an APEX callback fails
  notifyUser(title, message, variant) {
    // Notify via toast (only works in LEX)
    const toastEvent = new ShowToastEvent({ title, message, variant });
    this.dispatchEvent(toastEvent);
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
  clear() {
    this.handleAllOption();
  }
  value = [];
  @track inputValue = "All";

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

  //To store the orignal wire object to use in refreshApex method
  eventOriginalData = [];

  //Get data from server - in this example, it fetches from the event object
  @wire(fetchEvents)
  lstRosterManagerDTO(value) {
    this.eventOriginalData = value; //To use in refresh cache

    const { data, error } = value;
    if (data) {
      //format as fullcalendar event object
      let events = this.fortmatvalue(data);
      this.events = JSON.parse(JSON.stringify(events));
      console.log(this.events);
      this.error = undefined;

      //load only on first wire call -
      // if events are not rendered, try to remove this 'if' condition and add directly
      if (!this.eventsRendered) {
        //Add events to calendar
        const ele = this.template.querySelector("div.fullcalendarjs");
        $(ele).fullCalendar("renderEvents", this.events, true);
        this.eventsRendered = true;
      }
    } else if (error) {
      this.events = [];
      this.error = "No events are found";
    }
  }

  fortmatvalue(data) {
    let events = [];
    data.map((event) => {
      const start = moment(event.DateTimeFrom).format("YYYY-MM-DD HH:mm:ss");
      const end = moment(event.DateTimeTo).format("YYYY-MM-DD HH:mm:ss");
      let description = "";
      let popoverContent = "";
      description = `
        <p style="font-size:13px;font-weight:bold;">${
          event.Name ? event.Name : ""
        }</p>
        ${start}
        <br/>
        ${end}`;

      popoverContent = `
            <article>
            <div class="tooltip-header">
                <h2 class="slds-card__header-title">
                <a href="#" class="slds-card__header-link slds-truncate" title="${event.Name}">
                    <span>${event.Name}</span>
                </a>
                </h2>
            </div>
            <dl class="tooltip-content">
                <dt>Shift Code: </dt>
                <dd>${event.shiftcode}  &nbsp;  ${event.shiftname}</dd>
            </dl>
            <dl class="tooltip-content">
                <dt>Checkin date: </dt>
                <dd>${start}</dd>
            </dl>
            <dl class="tooltip-content">
                <dt>Checkout date: </dt>
                <dd>${end}</dd>
            </dl>          
            </article>        
        `;
      const calendarEvent = {
        id: event.Id,
        title: event.shiftcode + " " + `(${event.shiftname})`,
        start: start,
        end: end,
        //allDay : event.IsAllDayEvent,
        description: description,
        popoverContent: popoverContent,
      };
      events.push(calendarEvent);
    });
    return events;
  }

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
      loadScript(this, FullCalendarJS + "/fullcalendar.min.js"),
      loadStyle(this, FullCalendarJS + "/fullcalendar.min.css"),
    ])
      .then(() => {
        //initialize the full calendar
        this.initialiseFullCalendarJs();
      })
      .catch((error) => {
        console.error({
          message: "Error occured on FullCalendarJS",
          error,
        });
      });
  }

  initialiseFullCalendarJs() {
    const _this = this;
    const ele = this.template.querySelector("div.fullcalendarjs");
    const modal = this.template.querySelector("div.modalclass");
    console.log(FullCalendar);

    var self = this;

    $(ele).fullCalendar({
      schedulerLicenseKey: "CC-Attribution-NonCommercial-NoDerivatives",
      header: {
        left: "prev,next today",
        center: "title",
        right: "month,agendaWeek,agendaDay,listWeek"
      },
      views: {
        month: {
          eventLimit: 2,
          eventLimitClick: "listDay"
        }
      },
      defaultView: "month",

      editable: true,
      navLinks: true,
      eventLimit: true,
      droppable: false,
      height: "parent",
      ignoreTimezone: false,
      timezone: _this.initialTimezone,
      handleWindowResize: true,
      allDaySlot: false,
      events: _this.events,

      eventDrop: function (event, delta, revertFunc, jsEvent, ui, view) {
        revertFunc();
      },
      dayClick: (date, jsEvent, view) => {
        const now = moment();
        if (!now.isSame(date, "day") && now.isAfter(date)) {
          showToastMessage.bind(_this)(
            "error",
            "Error",
            'Test'
          );
          return;
        }

        _this.events.dispatchCreateNewEvent(date);
      },
      //events: this.formatEventData(this.events), // all the events that are to be rendered - can be a duplicate statement here
      eventRender: function (event, element) {
        const containerRect = _this.containerElement.getBoundingClientRect();
        const containerRectRight = containerRect.right;
        const containerRectBottom = containerRect.bottom;

        element.find(".fc-title").append("<br/>" + event.description);
        try {
          if (event.id) {
            element.mousemove(function (e) {
              let $tooltip;
              const locationX = e.pageX;
              const locationY = e.pageY;

              if (_this.popover) {
                $tooltip = _this.popover;
              } else {
                let popoverContent = event.popoverContent;
                const tooltip = document.createElement("div");
                // eslint-disable-next-line @lwc/lwc/no-inner-html
                tooltip.innerHTML = popoverContent;
                tooltip.classList.add("schedule-tooltip");
                _this.popoverContentElement.appendChild(tooltip);
                $tooltip = $(tooltip);
              }

              let width = $tooltip.width() > 400 ? 400 : $tooltip.width();
              let height = $tooltip.height() > 300 ? 300 : $tooltip.height();

              if (locationX + width > containerRectRight) {
                $tooltip.css("right", containerRectRight - locationX - 20);
                $tooltip.css("left", "auto");
              } else {
                $tooltip.css("left", locationX + 20);
                $tooltip.css("right", "auto");
              }

              if (locationY + height > containerRectBottom) {
                $tooltip.css("bottom", containerRectBottom - locationY - 10);
                $tooltip.css("top", "auto");
              } else {
                $tooltip.css("top", locationY + 10);
                $tooltip.css("bottom", "auto");
              }

              if (!_this.popover) {
                $tooltip.addClass("show");
                _this.popover = $tooltip;
              }
            });
          }
        } catch (e) {
          console.error(e);
        }
      },
      eventAfterRenderHandler: function (event, element) {},
      eventMouseover: function (event, jsEvent, view) {},
      eventMouseout: function (event, jsEvent, view) {
        if (_this.popover) {
          _this.popover.remove();
          _this.popover = null;
        }
      },
      loading: function (isLoading, view) {},
    });
  }


  //To close the modal form
  refresh() {
    location.reload();
  }

  //To save the event
  handleFilter(event) {
    let events = this.events;
    this.openSpinner = true;
    this.events = [];
    console.log(this.events);
    //Close the modal
    //this.openModal = false;
    //Server call to create the event
    getRosterByContactId({ lstContact: this.strInput })
      .then((result) => {
        const ele = this.template.querySelector("div.fullcalendarjs");
        $(ele).fullCalendar("removeEvents");
        let events = this.fortmatvalue(result);
        this.events = JSON.parse(JSON.stringify(events));
        $(ele).fullCalendar("renderEvents", this.events, true);
        //$(ele).fullCalendar("addEventSource", this.events);
        //Documentation: https://fullcalendar.io/docs/v3/renderEvent

        //To close spinner and modal
        this.openSpinner = false;

        //show toast message
        this.showNotification(
          "Success!!",
          "Searching successfully",
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

  formatEventData(scheduleEvents) {
    const calendarEvents = [];

    for (let event of scheduleEvents) {
      //event.trainerNames =
      //trainerNames.length > 0 ? trainerNames.join(", ") : "None";

      const start = moment(event.DateTimeFrom).format("HH:mm YYYY-MM-DD ");
      const end = moment(event.DateTimeTo).format("HH:mm YYYY-MM-DD");

      event.popoverContent = `
          <article>
            <div class="tooltip-header">
              <h2 class="slds-card__header-title">
                <a href="#" class="slds-card__header-link slds-truncate" title="${event.Name}">
                  <span>${event.Name}</span>
                </a>
              </h2>
              <div>${start}</div>
            </div>
            <dl class="tooltip-content">
              <dt>Checkin Date: </dt>
              <dd>${start}</dd>
            </dl>  
            <dl class="tooltip-content">
              <dt>Checkout Date: </dt>
              <dd>${end}</dd>
            </dl>      
          </article>       
        `;

      const calendarEvent = {
        title: event.Name,
        start: start,
        end: end,
        id: event.Id,
        description: description,
        popoverContent: event.popoverContent,
      };

      calendarEvents.push(calendarEvent);
    }
    return calendarEvents;
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