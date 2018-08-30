var isInView = function($el)
{
    var elemTop = $el.getBoundingClientRect().top;
    var elemBottom = $el.getBoundingClientRect().bottom;

    var isVisible = (elemTop >= 0) && (elemBottom <= window.innerHeight);
    return isVisible;
};