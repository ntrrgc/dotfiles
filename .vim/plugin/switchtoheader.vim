pythonx << EOF
import vim
import os

header_extensions = [".h", ".hpp", ".hxx"]
source_extensions = [".c", ".cpp", ".m", ".mm", ".cxx"]

def switch_between_header_and_source():
    path = vim.current.buffer.name
    if any(ext for ext in header_extensions if path.lower().endswith(ext)):
        try_extensions = source_extensions
    elif any(ext for ext in source_extensions if path.lower().endswith(ext)):
        try_extensions = header_extensions
    else:
        print("This is not a file with a known C family extension.")
        return

    base_name = os.path.splitext(path)[0]
    companion = next((base_name + ext for ext in try_extensions if os.path.exists(base_name + ext)), None)
    if not companion:
        print("Couldn't find a companion file.")
        return

    if not vim.current.buffer.options["modified"]:
        # Open it in the same window
        vim.command("e " + companion)
    else:
        # Open it in a split
        vim.command("sp " + companion)

EOF

augroup switchtoheader
    autocmd FileType c,cpp,objc,objcpp noremap <buffer> <silent> <F4> :pythonx switch_between_header_and_source()<CR>
augroup END
