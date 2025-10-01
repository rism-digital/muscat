
(function ($) {

    function $tbody($table) { return $table.find('tbody').length ? $table.find('tbody') : $table; }

    function renumber($table) {
        const $rows = $tbody($table).children('tr.inv-row');
        const total = $rows.length;

        $rows.each(function (i) {
            const idx1 = i + 1;
            const $row = $(this);
            $row.find('td.inv-index').text(idx1);
            $row.find('.reorder-input').attr({ min: 1, max: total }).val(idx1);
        });

        // edge buttons
        $rows.find('.move-up, .move-down').prop('disabled', false);
        $rows.first().find('.move-up').prop('disabled', true);
        $rows.last().find('.move-down').prop('disabled', true);
    }

    function isElementVisible($el) {
        const rect = $el[0].getBoundingClientRect();
        const viewHeight = $(window).height();

        return !(rect.bottom < 0 || rect.top > viewHeight);
    }

    function flashAndScroll($row) {
        $row.addClass('just-moved');

        if (!isElementVisible($row))
            $row[0]?.scrollIntoView({ behavior: 'smooth', block: 'center' });

        setTimeout(() => $row.removeClass('just-moved'), 2000);
    }

    function moveUpOne($row) {
        const $p = $row.prev('tr');
        if ($p.length)
            $row.insertBefore($p);
    }

    function moveDownOne($row) { 
        const $n = $row.next('tr'); 
        if ($n.length) 
            $row.insertAfter($n); 
    }

    function moveRelative($row, targetPos1, action, $table) {
        const $rows = $tbody($table).children('tr.inv-row');
        const total = $rows.length;
        let pos = parseInt(targetPos1, 10);
        let old_pos = parseInt($row.find('td.inv-index').text());
        
        if (isNaN(pos) || isNaN(old_pos))
            return false;

        pos = Math.min(Math.max(pos, 1), total);

        const refIndex0 = pos - 1;
        const $ref = $rows.eq(refIndex0);

        if (!$ref.length || $ref[0] === $row[0])
            return false;

        if (pos > old_pos)
            $row.insertAfter($ref);
        else
            $row.insertBefore($ref)

        return true;
        
/* use actions?
        if (action === 'before')
            $row.insertBefore($ref);
        else
            $row.insertAfter($ref);
*/
    }

    $(document).on('click', '.move-up, .move-down, .before, .after, .goto', function (e) {
        e.preventDefault();
        const $btn = $(this);
        const $row = $btn.closest('tr.inv-row');
        const $table = $row.closest('table');
        const $cell = $btn.closest('.reorder-cells');
        const $input = $cell.find('.reorder-input');
        let moved = true;

        if ($btn.hasClass('move-up'))
            moveUpOne($row);
        else if ($btn.hasClass('move-down'))
            moveDownOne($row);
        else
            moved = moveRelative($row, $input.val(), $btn.data('action'), $table);

        if (moved) {
            console.log("urca");
            renumber($table);
            flashAndScroll($row);
        }

    });

    // Initial sync
    $(function () {
        $('table.index_table.list_striped').each(function () { renumber($(this)); });
    });

})(jQuery);

// Serialization stuff
(function ($) {

    function findInventoryTable($btn) {
        const sel = $btn.data('target');

        if (sel && $(sel).length)
            return $(sel);

        return $('table.index_table.list_striped').first();
    }

    // Build [{ idx, composer }] using ONLY .inv-composer cells
    function serializeInventory($table) {
        const $tbody = $table.find('tbody').length ? $table.find('tbody') : $table;
        const items = [];

        $tbody.children('tr').each(function (i) {
            const $composerCell = $(this).find('td.inv-id');

            if (!$composerCell.length) 
                return; // skip rows without the class

            const composer = $.trim($composerCell.text());
            items.push({ idx: i, id: composer });
        });

        return items;
    }

    // Commit: populate hidden input and submit the form
    $(document).on('click', '#commit, .commit-order', function (e) {
        e.preventDefault();
        const $btn = $(this);
        const $table = findInventoryTable($btn);
        const items = serializeInventory($table);

        if (!items.length) {
            alert('No rows with .inv-id found.');
            return;
        }

        $('#commit-items').val(JSON.stringify(items));
        document.getElementById('commit-form').submit();
    });

})(jQuery);