/*!
*
* jQuery Remember Plugin
* Version 0.1.1
*
* Copyright Nick Dreckshage, licensed GPL & MIT
* https://github.com/ndreckshage/jquery-remember
*
* A fork of jQuery Cookie Plugin
* https://github.com/carhartl/jquery-cookie
* Copyright Klaus Hartl
* Released under the MIT licensed
*
*/

(function($){

  // recommend changing to return function(options) { if using require.js...
  $.remember = function(options){
    var settings,
        remember,
        controller;

    settings = $.extend({
      name: null,         // name/key of the cookie/localstorage item
      value: undefined,   // value pair of cookie/localstorage
      getSet: false,      // if true, will get if available, set if not. default is to just get OR set
      remove: false,      // if true, will remove based on name/key
      use: 'default',     // whether to use localstorage or cookies. default localstorage with cookie fallback.
      expires: null,      // forces cookie (invalid localstorage attribue).
      path: null,         // forces cookie.
      domain: null,       // forces cookie.
      secure: null,       // forces cookie.
      json: false,        // will convert to json when set. parse with get.
      fallback: true,     // whether to fallback to cookies if localstorage not available.
      raw: false,         // if true, will skip uri encoding/decoding
      modernizr: false    // set true if youd rather handle localstorage detection through modernizr
    }, options);

    remember = {
      init: function(){
        var controller;

        // controls what to do with the input. set - get - set/get - erase
        // set if name exists, value exists, and not set to remove cookie.
        // get if name exists, value does not exist, and not set to remove
        // remove if remove set to true
        if (settings.name !== null && settings.value !== undefined && settings.remove !== true){
          if (settings.getSet === true){
            var get = this.get();
            // if the value of get exists, return it. otherwise, set the value as specified.
            if (get === null){
              this.set();
            } else {
              controller = get;
            }
          } else {
            this.set();
          }
        } else if (settings.name !== null && settings.value === undefined && settings.remove !== true){
          controller = this.get();
        } else if (settings.name !== null && settings.remove === true){
          this.erase();
        }

        // will return result of everything to calling js
        return controller;
      },
      get: function(){
        var use = this._use(),
            value = null,
            cookies,
            parts,
            name;

        // grab the key value pair from localstorage
        if (use === 'localstorage') {
          value = localStorage.getItem(settings.name);
        }

        // hit if cookie requested, and when double checking a get on an empty localstorage item
        if ((use === 'cookie') || (use === 'localstorage' && value === null && settings.fallback !== false)) {

          // grab all the cookies from the browser, check if set, and loop through
          cookies = document.cookie ? document.cookie : null;
          if (cookies !== null){
            cookies = cookies.split(';');
            for (var i = 0; i < cookies.length; i++){
              // separate the key value pair
              parts = cookies[i].split('=');
              // set name and value to split parts, cleaning up whitespace
              name = parts.shift();
              name = settings.raw === false ? this._trim(this._decode(name)) : this._trim(name);
              value = parts[0];
              // break when we hit a match, or cookie is empty
              if (settings.name === name) {
                break;
              } else if (settings.fallback !== false) {
                value = localStorage.getItem(settings.name) || null;
              } else {
                value = null;
              }
            }
          }
        }

        // decode uri and if json is requested, parse the cookie/localstorage and return to controller
        value = (value && settings.raw === false) ? this._decode(value) : value;
        value = (value && settings.json === true) ? JSON.parse(value) : value;

        return value;
      },
      set: function(){
        var use = this._use();

        // if set is hit, user has intentionally tried to set (get/set not hit)
        // clear the storage alternative, so the same value isnt stored in both
        this.erase();

        // convert the value to store in json if requested
        settings.value = settings.json === true ? JSON.stringify(settings.value) : settings.value;

        // encode
        settings.name = settings.raw === false ? encodeURIComponent(settings.name) : settings.name;
        settings.value = settings.raw === false ? encodeURIComponent(settings.value) : settings.value;

        // store the key value pair in appropriate storage. set unless storage requirements failed
        if (use === 'localstorage'){
          localStorage.setItem(settings.name, settings.value);
        } else if (use !== false){
          // convert values that cant be stored and set
          settings.value = settings.value === null ? 'null' : settings.value;
          this._setCookie();
        }
      },
      erase: function(){
        var use = this._use();

        // clear localstorage and cookies by setting expiration to negative
        if (use !== 'cookie' || settings.fallback !== false){
          localStorage.removeItem(settings.name);
        }
        if (use !== 'localstorage' || settings.fallback !== false){
          this._setCookie('', -1);
        }
      },
      _use: function(){
        var use,
            localStorageSupport = this._localStorage();

        // if cookie requested, or any options set that only apply to cookies
        if (settings.use === 'cookie' || settings.expires !== null || settings.path !== null || settings.domain !== null || settings.secure !== null){
          use = 'cookie';
        } else {
          // use local storage if available
          if (localStorageSupport){
            use = 'localstorage';
          } else if (settings.fallback !== false) {
            // default to cookie, unless fallback banned
            use = 'cookie';
          } else {
            // if all this fails, nothing can be set
            use = false;
          }
        }

        return use;
      },
      _setCookie: function(){
        // allow for varying parameters with defaults. value then expires as optional params
        var value = arguments.length > 0 ? arguments[0] : settings.value,
            expires = arguments.length > 1 ? arguments[1] : settings.expires,
            expire;

        // set a date in the future (or negative to  delete) based on expires date offset
        if (typeof expires === 'number') {
          expire = new Date();
          expire.setDate(expire.getDate() + expires);
        }

        // set the cookies with all the varying settings
        document.cookie = [
          settings.name,
          '=',
          value,
          expire          ? '; expires=' + expire.toUTCString() : '',
          settings.path   ? '; path=' + settings.path : '',
          settings.domain ? '; domain=' + settings.domain : '',
          settings.secure ? '; secure' : ''
        ].join('');
      },
      _localStorage: function(){
        if (settings.modernizr === true && typeof Modernizr !== 'undefined'){
          return Modernizr.localstorage;
        } else {
          // check if a browser supports localstorage with simple try catch
          try {
            localStorage.setItem('jquery-remember-test','jquery-remember-test');
            localStorage.removeItem('jquery-remember-test');
            return true;
          } catch(e){
            return false;
          }
        }
      },
      _trim: function(s){
        // trail a strings leading/ending whitespace
        return s.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
      },
      _decode: function(s){
        return decodeURIComponent(s.replace(/\+/g, ' '));
      }
    };

    return remember.init();
  };

  return $.remember;

}(jQuery));
