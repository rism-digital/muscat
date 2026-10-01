jQuery(document).ready(function () {
    $('[data-save-comparison-rule]').on('click', function () {
        var sourceForm = this.closest('.compare-versions-options');
        var targetForm = document.getElementById(this.getAttribute('form'));
        if (!sourceForm || !targetForm) return;

        ['comparison_rule', 'time_frame', 'compare_version_quantity'].forEach(function (name) {
            var source = sourceForm.querySelector('[name="' + name + '"]');
            var target = targetForm.querySelector('[name="' + name + '"]');
            if (source && target) target.value = source.value;
        });
    });

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
