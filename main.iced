# TO FIX:
# filename with space
# fix styling
#  line height
#  extra width
#  when comparing to empty file
#  intra line changes
#  balance of diff window is off

# features:
#   patience diff(?)
#   view full original
#   expand diff level
#   click on line number to jump to that number in full file
#   view full screen diff in lightbox
#   syntax highlighting of diff

BUTTON_HTML = '<li><a href="#" class="sidebyside grouped-button minibutton bigger lighter" rel="nofollow">Side-by-Side</a></li>'


fetch_url = (url, cb) ->
    # there's a bug in how chrome lets extensions follow redirects, so we have
    # to do async
    # http://code.google.com/p/chromium/issues/detail?id=68105
    $.ajax url,
        success: (data) -> cb(data)
        error: (a,b,c) -> cb("") # most likely the file doesn't exist, so just presume it is empty


previous_raw_link_base = (url) ->
    [_, repo, previous_user, previous_ref] = url.match(/(?:github.com|^)\/([^\/]+)\/.*?\/([^\/]+):([^\/]+)\.\.\.[^\/]+:[^\/]+/)
    return "/#{previous_user}/#{repo}/raw/#{previous_ref}"


find_diff_url = () ->
    $diff_url = $('link[type="text/x-diff"]')
    if $diff_url.length == 1
        return $diff_url.attr('href')

    $diff_url = $('link[type="text/plain+diff"]')
    if $diff_url.length == 1
        return url_unescape($diff_url.attr('href'))

    return null


url_unescape = (url) ->
    return unescape(url.replace(/&#x(..);/g, '%$1'))


display_sidebyside = ($button, $diff_table, $container, current_raw_path, relative_path, change_set) ->
    await fetch_url(current_raw_path, defer current)
    parent = diff.apply_changes(relative_path, change_set, current)

    if parent == current
        $content = $('<div>Files are the same</div>')
    else
        $content = $(diff.jsdiff(parent, current))
    $diff_table.detach()
    $container.append($content)
    $button.removeClass('sidebyside').addClass('normaldiff').text('Normal')


display_normal = ($button, $diff_table, $container) ->
    $container.find('table.diff').remove()
    $container.append($diff_table)
    $button.removeClass('normaldiff').addClass('sidebyside').text('Side-by-Side')


main = () ->
    if $('#files.diff-view').length == 0
        # no diff view, fuck it
        return

    # find the diff for this page, seems easier to work from that than try to
    # find the original files
    diff_url = find_diff_url()
    if not diff_url?
        return

    await fetch_url(diff_url, defer diff_contents)
    change_set = diff.parse_diff(diff.invert_diff(diff_contents))

    $('.diff-view .file').each (_index, elem) ->
        $button_group = $(elem).find('.button-group')
        file_url = $button_group.find('li a').first().attr('href')
        if file_url == undefined
            return

        current_raw_path = file_url.replace("/blob/", "/raw/")
        relative_path = $(elem).find('.meta').data('path')

        # add new button
        $button = $(BUTTON_HTML)
        $diff_table = $(elem).find('.diff-table')
        $container = $diff_table.parent()

        $(elem).find('.meta').on 'dblclick', (e) ->
            $container.toggle()

        $button.on 'click', '.sidebyside', (e) ->
            e.preventDefault()
            display_sidebyside($(e.target), $diff_table, $container, current_raw_path, relative_path, change_set)

        $button.on 'click', '.normaldiff', (e) ->
            e.preventDefault()
            display_normal($(e.target), $diff_table, $container)

        $button_group.prepend($button)

main()
