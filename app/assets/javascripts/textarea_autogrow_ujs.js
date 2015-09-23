/*
    Attach autosize to textareas
    http://www.jacklmoore.com/autosize/

*/
(function(jQuery) {

    jQuery.fn.textareaAutogrow = function() {
        var handler = function () {
            if (!this.textareaAutogrow) {
                this.textareaAutogrow = new jQuery.textareaAutogrow(this);
            }
        };

        if (!this.textareaAutogrow) {
            this.textareaAutogrow = new jQuery.textareaAutogrow(this);
        }

        if (jQuery.fn.on !== undefined) {
            jQuery(document).on('update', this.selector, handler);
            return jQuery(document).on('focus', this.selector, handler);
        } else {
            return this.live('load', handler);
        }
    };

    jQuery.textareaAutogrow = function (e) {
        var _e = e;
        this.init(_e);
    };

    jQuery.textareaAutogrow.fn = jQuery.textareaAutogrow.prototype = {
        textareaAutogrow: '0.0.1'
    };

    jQuery.textareaAutogrow.fn.extend = jQuery.textareaAutogrow.extend = jQuery.extend;
    jQuery.textareaAutogrow.fn.extend({
        init: function (e) {
            var te = $(e);
            te.autosize({append: false});
            te.trigger('autosize.resize');
        }
    });

    jQuery(document).ready(function () {
        jQuery(".autogrow").textareaAutogrow();
        jQuery(".autogrow").trigger('update');
    });

})(jQuery);
