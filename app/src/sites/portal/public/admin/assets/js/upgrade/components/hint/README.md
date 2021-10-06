Webix Hint
=====

A JavaScript component for adding instructions for users to help them navigate through an application.

[See the detailed Hint description and API in the Webix documentation](https://docs.webix.com/desktop__hint.html).

[Live Demo](http://webix-hub.github.io/hint-component/samples/01_init.html)

## How to View the Samples

Go to the folder and run the following commands:

~~~
npm install
npm start
~~~

In your browser open [http://localhost:8080/](http://localhost:8080/).

## Other Commands

~~~
npm run lint 
npm watch
~~~

## How to Use

Include Webix files:

~~~html
<!-- Webix -->
<script type="text/javascript" src="http://cdn.webix.com/edge/webix.js"></script>
<link rel="stylesheet" type="text/css" href="http://cdn.webix.com/edge/webix.css">
<!-- Webix Hint, use CDN or files in this repo -->
<script type="text/javascript" src="http://cdn.webix.com/components/hint/hint.js"></script>
<link rel="stylesheet" type="text/css" href="http://cdn.webix.com/components/hint/hint.css">
~~~

Create the hint view:

~~~js
var hint = webix.ui({
    view: "hint",
    id: "hint",
    steps: [
      {
        el: "div[button_id='start']",
        title: "Welcome!",
        text: "Click here to start",
        event:"click"
      }
      //other step objects
    ] 
});
~~~

Start the Hint

~~~js
hint.start();
~~~


## Main API

### Hiding/showing a hint

Use the *start()/end()* methods to start or end a tutorial.

~~~js
$$("hint").start();
...
$$("hint").end();
~~~

### Setting/getting steps

To get the current step, use the *getCurrentStep()* method. Note that the count of Hint steps starts from 0.

~~~js
var step = $$("hint").getCurrentStep();
~~~

To get the list of all Hint steps, use the *getSteps()* method.

~~~js
var steps = $$("hint").getSteps(); // -> an array of step objects
~~~

To set your own steps for Hint, use the *setSteps()* method and pass an array of step objects into it:

~~~js
$$("hint").setSteps(
    [
        {
            el: ".div1",
            title: "Welcome to Booking App!",
            text: "Click here to check out regular flights. Click the tab to proceed",
            event:"click"
        }
    ]
);
~~~

### Resuming hints

To resume displaying of hints from some step, pass the number of the necessary step to the *resume()* method. Or jump to a next step by calling the method without parameter.

~~~js
webix.ui({
    view: "hint",
    id: "hint",
    on: {
        onEnd: function(step) {
            $$("hint").resume(2); // resume from the second step
        }
    },
    steps:[
        {
            el: ".div1",
            title: "Welcome to Booking App!",
            text: "Click here to check out regular flights",
            event:"click"
        },
        {
            el: ".div2",
            title: "Get Flights Info in a Click!",
            text: "Click here to take a look at all flights info",
            event:"click"
        }
    ]
})
~~~


## Managing Next/Previous buttons

Use the *nextButton/prevButton* configs to define the buttons look and behavior. 

~~~js
webix.ui({
    view: "hint",
    id: "hint",
    steps: [
        {
            el: ".div1",
            title: "Welcome to Booking App!",
            text: "Click here to check out regular flights",
            event:"click"
        },
        {
            el: ".div2",
            title: "Get Flights Info in a Click!",
            text: "Click here to take a look at all flights info",
            event:"click"
        }
    ],
    nextButton: "Show next",    // the new caption of the button
    prevButton: false           // the "Previous" button won't be rendered
});
~~~

Both configs can be set to either a boolean value to enable/disable them or a string value with a new caption for the button. The default value is true.

## Position

Positionn is set automatically by deafult. Alternatively, you can provide top and left values in hint config or any step.

~~~js
webix.ui({
    view: "hint",
    id: "hint",
    top: 10, // value for all steps
    steps: [
        {
            el: ".div1",
            title: "Welcome to Booking App!",
            text: "Click here to check out regular flights",
            event: "click",
            top: 50, // value for this step
            left: 0
        },
        {
            el: ".div2",
            title: "Get Flights Info in a Click!",
            text: "Click here to take a look at all flights info",
            event:"click"
        }
    ]
});
~~~

The position of the hint is calculated relative to the left top corner.

## Async steps

If you need to fire some action before showing the next step of tutorial, you can use "next" property of the step. It can be defined as a function with an arbitrary code, which can return a promise. Hint will activate next step on promise resolving. For example:

~~~js
{
    el: "masterPager1",
    eventEl: "button",
    title: "Datatable can be used with a pager",
    text: "Please click the second button to open page number two",
    padding: 10,
    event: "click",
    next: function() {
        //load data into the table
        //switch to the next step only after data loading
        return $$("mytable").load("extradata.php");
    }
}
~~~

In the above example we have a datatable with a pager and a hint widget, which must be activated only after loading of the next page of the datatable.

If you want to trigger some actions on return to the previous step, make use of the previous property.


## License

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.