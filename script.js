$(function() {
  // build navigation
  var $navRoot = $('#sidebar'), $navParent = null;
  $('content > section, content > section > section').each(function(i, $el) {
    if ($el.id) {
      var $titleEl = $('h2,h3', $el).eq(0);
      var $li = $('<li />').append(
        $('<a />').attr('href', '#' + $el.id).text($titleEl.text())
      );
      var $parent;

      if ($titleEl.is('h2')) {
        $parent = $navRoot;
        $navParent = $li;
      } else {
        if ($navParent.is('li')) {
          var $ul = $('<ul />').attr('class', 'nav nav-stacked');
          $navParent.append($ul);
          $navParent = $ul;
        }

        $parent = $navParent;
      }

      $parent.append($li);
    }
  });
  $('body').scrollspy({
    target: '.navsidebar',
    offset: 40
  });

  // build packet table of contents
  var rows = [];
  $('#packet-types section > section').each(function(i, $el) {
    if ($el.id) {
      var $titleEl = $('h3', $el).eq(0);
      var $props = $('.pkt-props', $el);
      var $types = $props.children('code');
      var whoFrom = $props.children('span').text();
      var mainType = $types.eq(0).text();

      var $link = $('<a />').attr('href', '#' + $el.id).text($titleEl.text());
      if ($titleEl.hasClass('removed')) $link.addClass('removed');

      var $row = $('<tr />').append(
        $('<td />').append($link),
        $('<td />').text(whoFrom),
        $('<td />').append(
          $('<code />').text(mainType)
        )
      );
      
      if ($types.length > 1) {
        var $subTypeCode = $('<code />').text($types.eq(1).text());
        $row.append(
          $('<td />').append($subTypeCode)
        );

        if ($types.length > 2) {
          $subTypeCode.after('-',
            $('<code />').text($types.eq(2).text())
          );
        }
      } else $row.append('<td />');

      rows.push($row);
    }
  });

  // sort packet list by (direction, major, minor)
  rows.sort(function(a, b) {
    var text_a = a[0].cells[1].innerText + a[0].cells[2].innerText + a[0].cells[3].innerText;
    var text_b = b[0].cells[1].innerText + b[0].cells[2].innerText + b[0].cells[3].innerText;
    return text_a.localeCompare(text_b);
  });

  // add sorted packet list to body
  var $packetTable = $('#packet-table tbody');
  $(rows).each(function(i, el) {
    $packetTable.append(el);
  });
});
