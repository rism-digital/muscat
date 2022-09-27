jQuery(document).ready(function () {
    $('a.diff-button').on('click', function (e) {
        if ($("#" + this.name).is(":visible") == false) {
            $("#" + this.name).fadeIn();
            $('a[name="' + this.name + '"]').text(I18n.t("compare_versions.hide"));
        } else {
            $("#" + this.name).hide();
            $('a[name="' + this.name + '"]').text(I18n.t("compare_versions.show"));
        }
        e.preventDefault();
        e.stopPropagation();
    });
});