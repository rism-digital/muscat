/*
    Relator codes for a single <select>
    it expects a <input class="single_select_target"> at the same level
    used in _subfield_relator_codes_710

*/
(function (jQuery) {

    jQuery.fn.relatorCodesSingle = function () {
        var handler = function () {
            if (!this.relatorCodesSingle) {
                this.relatorCodesSingle = new jQuery.relatorCodesSingle(this);
            }
        };

        if (jQuery.fn.on !== undefined) {
            return jQuery(document).on('focus', this.selector, handler);
        } else {
            return this.live('focus', handler);
        }
    };

    jQuery.relatorCodesSingle = function (e) {
        _e = e;
        this.init(_e);
    };

    jQuery.relatorCodesSingle.fn = jQuery.relatorCodesSingle.prototype = {
        relatorCodesSingle: '0.0.1'
    };

    jQuery.relatorCodesSingle.fn.extend = jQuery.relatorCodesSingle.extend = jQuery.extend;
    jQuery.relatorCodesSingle.fn.extend({
        init: function (e) {
            var select = $(e);

            select.change(function (e, data) {
                var hidden = select.parent().children(".single_select_target");
                hidden.val(this.value);
            });
        }
    });

    jQuery(document).ready(function () {
        jQuery(".single_relator_select").relatorCodesSingle();
    });

})(jQuery);
