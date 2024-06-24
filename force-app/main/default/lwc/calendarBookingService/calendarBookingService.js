import { LightningElement, track, wire, api } from "lwc";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FullCalendarJS from "@salesforce/resourceUrl/FullCalendarJS";
import getBookingInit from "@salesforce/apex/CalendarBookingController.getBookingInit";
import getBookingByCondition from "@salesforce/apex/CalendarBookingController.getBookingByCondition";

import { refreshApex } from "@salesforce/apex";
const { userAgent } = navigator;
export default class CalendarBookingService extends LightningElement {
    
    showToastMessage(msg, type) {
        this.dispatchEvent(
          new ShowToastEvent({
            variant: type,
            message: msg,
          })
        );
      }
      
    
      //To avoid the recursion from renderedcallback
      fullCalendarJsInitialised = false;
    
      //Fields to store the event data -- add all other fields you want to add
      popover = null;
      title;
      startDate;
      endDate;
      error;
      eventsRendered = false; //To render initial events only once
    
      @track
      events = []; //all calendar events are stored in this field
    
      //To store the orignal wire object to use in refreshApex method
      eventOriginalData = [];
    
      //Get data from server - in this example, it fetches from the event object
      @wire(getBookingInit)
      getBookingInitial(value) {
        this.eventOriginalData = value; //To use in refresh cache
    
        const { data, error } = value;
        if (data) {
          //format as fullcalendar event object
          
          let events = this.fortmatvalue(data.result);

          
          this.events = JSON.parse(JSON.stringify(events));
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
          const start = event.ConfirmStart ? moment(event.ConfirmStart).format("YYYY-MM-DD HH:mm") : moment(event.BookingStart).format("YYYY-MM-DD HH:mm");
          const end = event.ConfirmEnd ? moment(event.ConfirmEnd).format("YYYY-MM-DD HH:mm") : moment(event.BookingEnd).format("YYYY-MM-DD HH:mm");
          const startTime = event.ConfirmStart ? moment(event.ConfirmStart).format("HH:mm") : moment(event.BookingStart).format("HH:mm");
          const endTime = event.ConfirmEnd ? moment(event.ConfirmEnd).format("HH:mm") : moment(event.BookingEnd).format("HH:mm");
          let description = "";
          let popoverContent = "";
          let title = event.ServiceType  +  " - " + event.NameCustomer;
          description = `<div class='descriptText' style='margin-top:10px;'>${startTime}  &nbsp-&nbsp  ${endTime}</div>`;
    
          popoverContent = `
                <article>
                <div class="tooltip-header">
                    <h2 class="slds-card__header-title">
                    <a href="#" class="slds-card__header-link slds-truncate" title="${title}">
                        <span>${title}</span>
                    </a>
                    </h2>
                </div>
                <dl class="tooltip-content">
                    <dt>Range Time: </dt>
                    <dd>${startTime}  -  ${endTime}</dd>
                </dl>
                </article>        
            `;
          const calendarEvent = {
            id: event.Id,
            type: event.ServiceType,
            isConfirm: event.ConfirmStart ? true : false,
            title: title,
            color: "grey",
            start: start,
            end: end,
            url: window.location.origin + '/' + event.Id,
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
    
      
      deviceMobile;
  initialiseFullCalendarJs() {
    const _this = this;
    if (userAgent.match(/Android/i) != null || userAgent.match(/iPhone|iPad|iPod/i) != null || userAgent.match(/BlackBerry/i) != null) {
      _this.deviceMobile = true;
    } else {
      _this.deviceMobile = false;
    }
    const ele = this.template.querySelector("div.fullcalendarjs");
    $(ele).fullCalendar({
      schedulerLicenseKey: "CC-Attribution-NonCommercial-NoDerivatives",
      header: {
        left: "prev,next today",
        center: "title",
        right: "month,agendaWeek,agendaDay,listWeek" ,
      },
      views: {
        month: {
          eventLimit: 10,
        },
      },
      minTime: "08:00",
      maxTime: "18:00",

      defaultView: 'agendaWeek',
      displayEventTime:  true,
      editable: true,
      navLinks: true,
      droppable: false,
      height: "parent",
      contentHeight: '9999',
      ignoreTimezone: false,
      timezone: _this.initialTimezone,
      handleWindowResize: true,
      eventOrder: "displayOrder",
      allDaySlot: false,
      events: _this.events,

      slotDuration: '00:15',
      allDaySlot : false,
      eventStartditable: false,
      eventDurationEditable:false,
      slotLabelInterval: "00:15",
      businessHours: {
        // days of week. an array of zero-based day of week integers (0=Sunday)
        dow: [ 1, 2, 3, 4, 5], // Monday - Thursday
      
        start: '10:00', // a start time (10am in this example)
        end: '18:00', // an end time (6pm in this example)
      },

      eventDrop: function (event, delta, revertFunc, jsEvent, ui, view) {
        revertFunc();
      },
      dayClick: (date, jsEvent, view) => {
        const now = moment();
        if (!now.isSame(date, "day") && now.isAfter(date)) {
          showToastMessage.bind(_this)("error", "Error", "Test");
          return;
        }
        _this.events.dispatchCreateNewEvent(date);
      },
      eventRender: function (event, element) {
        const containerRect = _this.containerElement.getBoundingClientRect();
        const containerRectRight = containerRect.right;
        const containerRectBottom = containerRect.bottom;
        element.find(".fc-time").remove();
        element
          .find(".fc-title")
          .html("<div class='titleText'>" + event.title + "</div>");
        const divDot = document.createElement("div");
        divDot.classList.add("dot");
        divDot.style.background = event.id;
        divDot.style.height = "9px";
        divDot.style.width = "9px";
        divDot.style.marginTop = "2px";
        divDot.style.marginRight = "2px";
        divDot.style.borderRadius = "50%";
        divDot.style.display = "inline-block";
        element.find(".fc-title").prepend(divDot);
        //element.find(".fc-title").append("<br/>" + event.description);

        element.find(".dot").css("background-color", "grey");
        if(event.type == 'Service') {
          element.find(".dot").css("background-color", "red");
        } else if(event.type == 'Detailing') {
          element.find(".dot").css("background-color", "yellow");
        } else if(event.type == 'Service & Detailing') {
          element.find(".dot").css("background-color", "blue");
        }

        element.find(".fc-event-dot").css("background-color", "grey");
        if(event.type == 'Service') {
          element.find(".fc-event-dot").css("background-color", "red");
        } else if(event.type == 'Detailing') {
          element.find(".fc-event-dot").css("background-color", "yellow");
        } else if(event.type == 'Service & Detailing') {
          element.find(".fc-event-dot").css("background-color", "blue");
        }
        try {
          if (event.id && event.id != 'break-time') {
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
      eventClick: function(event, jsEvent, view) {
        jsEvent.preventDefault();
        window.open(event.url);
      },
      eventAfterRender: function (event, element, view) {
        
        if(!event.isConfirm) {
          element.css("background-color", "#C5C5C5");
        } else {
          element.css("background-color", "#f5f5f5");
        }
      },
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

    openSpinner = false;
    //To save the event
  handleFilter(event) {
    let events = this.events;
    this.openSpinner = true;
    this.events = [];
    console.log(this.events);
    //Close the modal
    //this.openModal = false;
    //Server call to create the event
    getBookingByCondition({ 
      lstStrDODL: this.lstStrDODL,
      lstServiceType: this.lstServiceType,
      lstEmployee: this.lstEmployee 
    }).then(apiResponse => {
        if(apiResponse.success) {
            const data = apiResponse.result;
            const ele = this.template.querySelector("div.fullcalendarjs");
            $(ele).fullCalendar("removeEvents");
            let events = this.fortmatvalue(data);
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
        } else {
            this.openSpinner = false;
            this.showToastMessage(apiResponse.error, 'Error');
        }
    }).catch(error => {
        this.openSpinner = false;
        if(error) {
            if (Array.isArray(error.body)) {
                this.errorMsg = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.errorMsg = error.body.message;
            }
        }
    })
  }

  flagDisableBtnFilter = false;

  @track lstStrDODL;
  @track lstServiceType;
  @track lstEmployee;

  handelChangeDODL(event) {
    console.log('FUll calendar:' + JSON.stringify(event.detail));
    this.lstStrDODL = event.detail;
  }

  handelChangeServiceType(event) {
    console.log('FUll calendar:' + JSON.stringify(event.detail));
    this.lstServiceType = event.detail;
  }

  handelChangeEmployee(event) {
    console.log('FUll calendar:' + JSON.stringify(event.detail));
    this.lstEmployee = event.detail;
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
}