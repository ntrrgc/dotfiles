function! s:ParseIntervalToMinutes(interval)
    let matches = matchlist(a:interval, '\v(\d+h)?(\d+)?m?')
    let ret = 0
    if strlen(matches[1]) > 0
        let hours = str2nr(matches[1])
        let ret += hours * 60
    endif
    if strlen(matches[2]) > 0
        let minutes = str2nr(matches[2])
        let ret += minutes
    endif
    return ret
endfunction

function! s:ParseHoursLine(line)
    let matches = matchlist(a:line, '\v(\d+)[;:](\d+)-(\d+)[;:](\d+)\s*([0-9hm]+)?\s*([0-9hm]+)?.*')
    if empty(matches)
        return {}
    end

    let dict = {}
    let dict.start = str2nr(matches[1]) * 60 + str2nr(matches[2])
    let dict.end = str2nr(matches[3]) * 60 + str2nr(matches[4])
    if strlen(matches[5]) > 0
        let dict.duration = s:ParseIntervalToMinutes(matches[5])
        if strlen(matches[6]) > 0
            let dict.accumulated = s:ParseIntervalToMinutes(matches[6])
        else
            " Assume this is the first interval, so accumulated matches
            " duration.
            let dict.accumulated = dict.duration
        endif
    endif
    return dict
endfunction

function! s:Duration(start, end)
    let diff = a:end - a:start
    while diff < 0
        let diff += 24 * 60
    endwhile
    return diff
endfunction

function! s:FormatClock(minutesOfDay)
    return printf("%02d:%02d", a:minutesOfDay / 60, a:minutesOfDay % 60)
endfunction

function! s:FormatDuration(totalMinutes)
    let hours = a:totalMinutes / 60
    let minutes = a:totalMinutes % 60
    let ret = ""
    if hours > 0
        let ret .= printf("%dh", hours)
    endif
    if minutes > 0
        let ret .= printf("%02dm", minutes)
    endif
    return ret
endfunction

function! s:FormatHoursLine(dict)
    let interval = a:dict
    return printf("%s-%s %-6s %s", s:FormatClock(interval.start), s:FormatClock(interval.end),
                \ s:FormatDuration(interval.duration), s:FormatDuration(interval.accumulated))
endfunction

function! CalculateHours()
    " Get accumulated from the previous line
    let accumulated = get(s:ParseHoursLine(getline(line(".") - 1)), "accumulated", 0)

    let interval = s:ParseHoursLine(getline("."))
    if empty(interval)
        return
    end

    let interval.duration = s:Duration(interval.start, interval.end)
    let interval.accumulated = accumulated + interval.duration
    call setline(".", s:FormatHoursLine(interval))
    normal j
endfunction

augroup calculatehours
    autocmd BufReadPost horas.txt :noremap <silent> <F8> :call CalculateHours()<CR>
    autocmd BufReadPost tasks-*.txt :noremap <silent> <F8> :call CalculateHours()<CR>
augroup END
