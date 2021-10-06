import "./hint.less";
import "./locales";

webix.protoUI({
	name: "hint",
	defaults: {
		steps: [],
		borderless: true,
		nextButton: true,
		prevButton: true,
		top: false,
		left: false,
		stepTimeout:500
	},
	$init() {
		this.$view.className += " webix_hint_view";
		this._i = -1;
		this.attachEvent("onDestruct", () => {
			this._setBodyClass("remove");
			if(this._eventObj) {
				webix.eventRemove(this._eventObj);
			}
			if(this._eventObjEsc) {
				webix.eventRemove(this._eventObjEsc);
			}
			if(this._eventResize) {
				webix.detachEvent(this._eventResize);
			}
		});
		this._eventObjEsc = webix.event(document.body,"keydown", (e) => {
			// escape
			if (e.keyCode == 27){
				this._skip();
			}
		});
		this._setResize();
	},
	steps_setter(config) {
		let newConfig = [];
		for (var i = 0; i < config.length; i++) {
			config[i].padding = config[i].padding || 0;
			config[i].text = config[i].text || "";
			newConfig.push(config[i]);
		}
		return newConfig;
	},
	_drawOver(stepEl) {
		this.$view.innerHTML += `<svg preserveAspectRatio="none" width="100%" height="100%" class="webix_hint_overlay" preserveAspectRatio="none">
			<defs>
				<mask id="hole">
					<rect class="webix_hint_overlay_hole" width="100%" height="100%" fill="white"/>
					<rect class="webix_hint_overlay_hole webix_hint_overlay_hole_el" x="0" y="0" width="0" height="0" fill="white"/>
				</mask>
			</defs>
			<rect class="webix_hint_overlay_hole" width="100%" height="100%" mask="url(#hole)" />
		</svg>`;
		this._setProperties(stepEl);
		this.callEvent("onAfterStart", []);
	},
	_drawHint() {
		let settings = this.config;
		this.$view.innerHTML += `<div class="webix_hint">
			<div class='webix_hint_title'>${this._step.title?this._step.title:""}</div>
			<div class="webix_hint_label">${this._step.text}</div>
			<div class="webix_hint_progress">
				${this._i+1}/${this.config.steps.length}
			</div>
			<div class="webix_hint_buttons">
				${settings.prevButton!== false?`<button class="webix_hint_button webix_hint_button_prev webix_hint_button_hidden">${typeof settings.prevButton == "string"?settings.prevButton:`${webix.i18n.hint.prev}`}</button>`:""}
				${settings.nextButton!== false?`<button class="webix_hint_button webix_hint_button_next">${typeof settings.nextButton == "string"?settings.nextButton:`${webix.i18n.hint.next}`}</button>`:""}
			</div>
			<button class="webix_hint_button_close" title="Close">&#10005;</button>
		</div>`;
	},
	_setProperties(stepEl, refresh) {
		if(!stepEl) {
			return;
		}

		if(!webix.env.mobile) {
			stepEl.scrollIntoView(false);
		}
		this._step = this.config.steps[this._i];
		this._reDraw(stepEl, refresh);
		this._hint = this.$view.querySelector(".webix_hint");

		let padding = 30;
		let docElem = document.documentElement;
		let box = stepEl.getBoundingClientRect();
		let elLeft = box.left + this._step.padding;
		let highlightWidth = box.width;
		let highlightHeight = box.height;
		let hintLeft = elLeft - this._step.padding;
		let hintWidth = this._hint.offsetWidth;
		let hintHeight = this._hint.offsetHeight;
		let elTop = webix.env.mobile ? box.top + this._step.padding : box.top + this._step.padding + window.pageYOffset;
		let hintTop = elTop + highlightHeight + this._step.padding + padding;
		let windowWidth = window.innerWidth && docElem.clientWidth ? Math.min(window.innerWidth, docElem.clientWidth) : window.innerWidth || docElem.clientWidth || document.getElementsByTagName("body")[0].clientWidth;
		let windowHeight = window.innerHeight && docElem.clientHeight ? Math.min(window.innerHeight, docElem.clientHeight) : window.innerHeight || docElem.clientHeight || document.getElementsByTagName("body")[0].clientHeight;
		
		stepEl.style.pointerEvents = "all";
		stepEl.style.userSelect = "initial";

		// set hint position
		if(elLeft - windowWidth > 0) {
			elLeft = elLeft - windowWidth + hintWidth + highlightWidth;
		}

		if(windowHeight /2 < elTop) { // bottom
			hintTop = elTop - hintHeight - padding - this._step.padding*2;
		} else if(windowWidth /2 < elLeft && elLeft + hintWidth < windowWidth && highlightWidth + hintWidth < windowWidth) { // right
			hintTop = highlightHeight / 2 + elTop - this._step.padding;
			hintLeft = elLeft - hintWidth - this._step.padding - padding;
		} else if(windowWidth /2 > elLeft && elLeft + hintWidth + highlightWidth < windowWidth) { // left
			hintLeft = highlightWidth + elLeft + padding;
			hintTop = elTop - this._step.padding;
		} else if(hintTop>windowHeight && hintHeight+highlightHeight<windowHeight){//top, but hint does not fit
			hintTop = elTop - hintHeight - padding - this._step.padding*2;
		} else if(hintTop >windowHeight || hintTop+hintHeight>windowHeight){
			hintLeft = elLeft - hintWidth - this._step.padding*2 - padding;
			hintTop = elTop - this._step.padding;
		}

		if(hintLeft + hintWidth > windowWidth) { // for overflow
			hintLeft = windowWidth - hintWidth;
		} else if(hintTop < 0 || hintTop > windowHeight) {
			hintTop = padding;
		} else if(windowWidth < highlightWidth || hintLeft < 0) {
			hintLeft = padding;
		}
		hintTop = this._setPos("top")?this._setPos("top"):hintTop;
		hintLeft = this._setPos("left")?this._setPos("left"):hintLeft;

		if(webix.env.mobile) {
			stepEl.scrollIntoView(false);
		}
		if(this._timer) {clearTimeout(this._timer);}
		this._timer = setTimeout(() => {
			this._hint.style.cssText = `top:${hintTop}px; left:${hintLeft}px;`;
			this._setAttributes(this.$view.getElementsByClassName("webix_hint_overlay_hole_el")[0], {"x":elLeft-this._step.padding*2, "y":elTop-this._step.padding*2, "width":highlightWidth+this._step.padding *2, "height":highlightHeight+this._step.padding*2});
			webix.html.addCss(this.getNode(), "webix_hint_animated");
		}, this.config.stepTimeout);
	},
	_setPos(name) {
		if(this._isInteger(this._step[name])) {
			return this._step[name];
		} else if(this._isInteger(this.config[name]) && this._step[name] !== false){
			return this.config[name];
		}
	},
	_setResize() {
		this._eventResize = webix.attachEvent("onResize", () => {
			if(this.getCurrentStep() && this._i !== this.config.steps.length) {
				this._refresh(this.getCurrentStep(), false, true);
			}
		});
	},
	_isInteger(value) {
		if(Number.isInteger) return Number.isInteger(value);
		return typeof value === "number" && 
			isFinite(value) && 
			Math.floor(value) === value;
	},
	_setAttributes(el, attrs) {
		for(var key in attrs) {
			el.setAttribute(key, attrs[key]);
		}
	},
	_reDraw(stepEl, refresh) {
		let title = this.$view.querySelector(".webix_hint_title");
		let el;

		this._step.eventEl?el = this._getEl(this._step.eventEl):el = stepEl;
		if(this._i > 0 && !refresh) {
			webix.html.removeCss(this.getNode(), "webix_hint_animated");
			title.innerHTML = this._step.title || "";
			this.$view.querySelector(".webix_hint_label").innerHTML = this._step.text || "";
			this.$view.querySelector(".webix_hint_progress").innerHTML = `${this._i+1}/${this.config.steps.length}`;
		} else {
			this._drawHint();
			this._setEventsButtons(el);
		}
		if(!this._step.title && title) {
			title.style.margin = "0";
		}
		this._setElEvents(el);

		if(this._prevButton) {
			if(this._i > 0) { // previous button show
				webix.html.removeCss(this._prevButton, "webix_hint_button_hidden");
			} else if(this._prevButton && !this._prevButton.classList.contains("webix_hint_button_hidden")) {
				webix.html.addCss(this._prevButton, "webix_hint_button_hidden");
			}
		}
		
		if(this._i === this.config.steps.length -1 && this._nextButton) { // next button text
			this._nextButton.innerHTML = `${typeof this.config.nextButton == "string"?this.config.nextButton:`${webix.i18n.hint.last}`}`;
		}
	},
	_setBodyClass(remove) {
		let body = document.body;
		if(remove) {
			webix.html.removeCss(body, "webix_hint_overflow");
		} else if(!body.classList.contains("webix_hint_overflow")) {
			webix.html.addCss(body, "webix_hint_overflow");
		}
	},
	_getEl(el) {
		if($$(el)) {
			return $$(el).getNode();
		} else {
			return document.querySelector(el);
		}
	},
	_drawSteps(refresh) {
		if(this.config.steps[this._i]) {
			let el = this._getEl(this.config.steps[this._i].el);
			if(this._i === 0 && !refresh) {
				this.callEvent("onBeforeStart", []);
				setTimeout(() => { // for first init
					this._drawOver(el);
				}, 100);
			} else {
				this._setProperties(el, refresh);
			}
		} else {
			this._skip();
		}
	},
	_setEventsButtons() {
		this._prevButton = this.$view.querySelectorAll(".webix_hint_button_prev")[0];
		this._nextButton = this.$view.querySelectorAll(".webix_hint_button_next")[0];
		let el;
		if(this._nextButton) {
			webix.event(this._nextButton, "click", () => {
				this._next(el, "next");
			});
		}
		if(this._prevButton) {
			webix.event(this._prevButton, "click", () => {
				this._next(el, "previous");
			});
		}
		webix.event(this.$view.querySelector(".webix_hint_button_close"), "click", () => { this._skip(); });
	},
	_setElEvents(stepEl) {
		let eventStep = this._step.event;
		stepEl.focus();
		if(eventStep) {
			if(eventStep === "enter") {
				eventStep = "keydown";
			}
			if(this._eventObj) {
				webix.eventRemove(this._eventObj);
			}
			this._eventObj = webix.event(stepEl, eventStep, (e) => {
				if(eventStep == e.type) {
					if(e.type === "keydown" && e.keyCode !== 13) return;
					stepEl.focus();
					this._next(stepEl);
				}
			});
		} else {
			return;
		}
	},
	_next(stepEl, action) {
		action = action || "next";
		if (this._step.next && action === "next" || this._step.previous && action === "previous") {
			let promise = this._step[action]();
			if (promise){
				promise.resolve().then(() => {
					this._nextStep(stepEl, action);
				});
			} else {
				this._nextStep(stepEl, action);
			}
		} else {
			this._nextStep(stepEl, action);
		}
	},
	_nextStep(stepEl, action) {
		let el = this._getEl(this._step.el);
		el.style.pointerEvents = "";
		el.style.userSelect = "";
		el.blur();
		if(action !== "previous") {
			this._i++;
			this._drawSteps();
			this.callEvent("onNext", [this._i+1]);
		}
		if(action === "previous") {
			this.callEvent("onPrevious", [this._i]);
			this._refresh(this._i--, false);
		}
	},
	_skip() {
		if (this._i === -1) return;
		if(this._eventObj) {
			webix.eventRemove(this._eventObj);
			delete this._eventObj;
		}
		if(this._eventResize) {
			webix.detachEvent(this._eventResize);
			delete this._eventResize;
		}
		this.callEvent("onSkip", [this._i+1]);
		this.hide();
		this._setBodyClass("remove");
		if(this._i === this.config.steps.length) {
			this.callEvent("onEnd", [this._i+1]);
		}
	},
	_refresh(i, firstDraw) {
		if(!this._eventResize) {
			this._setResize();
		}
		this._i = i-1;
		this._setBodyClass();
		if(this._hint) {
			if(this._hint.parentNode)
				this._hint.parentNode.removeChild(this._hint);
			webix.html.removeCss(this.getNode(), "webix_hint_animated");
		}
		this.show();
		if(firstDraw) {
			let svg = this.$view.querySelector("svg");
			if (svg)
				svg.parentNode.removeChild(svg);
			this._drawSteps();
		} else {
			this._drawSteps("refresh");
		}
	},
	start() {
		this._refresh(1, true);
	},
	end() {
		this._skip();
	},
	getCurrentStep() {
		return this._i+1;
	},
	resume(stepNumber) {
		if(this._hint){
			stepNumber = stepNumber || 1;
			this._refresh(stepNumber);
		}
	},
	getSteps() {
		return this.config.steps;
	},
	setSteps(value) {
		this.define("steps", value);
	}
}, webix.ui.view, webix.EventSystem);