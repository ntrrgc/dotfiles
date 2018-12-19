#!/bin/bash
set -eu
if [ $# -lt 3 ]; then
    echo "Rebaseline a WebKit test."
    echo
    echo "Usage: rebaseline.sh <results.html URL> <comma separated list of platforms> <test> [ [<test>] ... ]"
    echo "Run from WebKit repo root directory."
    echo
    echo "Example:"
    echo
    echo "rebaseline.sh \"https://build.webkit.org/results/GTK%20Linux%2064-bit%20Release%20(Tests)/r239379%20(9206)/results.html\" \\"
    echo "    gtk,wpe animations/lineheight-animation.html animations/simultaneous-start-transform.html animations/width-using-ems.html"
    exit 1
fi

results_url="$1"
IFS="," read -ra platforms <<< "$2"

while [ $# -ge 3 ]; do
    test="$3"

    test_expected_path="$(perl -pe 's/\.html$/-expected.txt/' <<< "$test")"

    test_actual_path="$(perl -pe 's/-expected\.txt$/-actual.txt/' <<< "$test_expected_path")"
    test_expected_url="$(t="$test_actual_path" perl -pe 's/\/results.html.*/\/$ENV{t}/' <<< "$results_url")"
    test_expected_tmp_file="$(mktemp -t "rebaseline.XXXXXXXXXX")"
    function remove_tmp_file {
       rm "$test_expected_tmp_file"
    }
    trap remove_tmp_file EXIT
    curl -s -o "$test_expected_tmp_file" "$test_expected_url"

    for platform in "${platforms[@]}"; do
        platform_dir="LayoutTests/platform/$platform"
        if [ ! -d "$platform_dir" ]; then
            echo "Directory does not exist: $platform_dir"
            exit 2
        fi

        mkdir -p "$(dirname "$platform_dir/$test_expected_path")"
        if ! cmp -s "$platform_dir/$test_expected_path" "$test_expected_tmp_file"; then
            cat > "$platform_dir/$test_expected_path" < "$test_expected_tmp_file"
            echo "$platform_dir/$test_expected_path"
        fi
    done

    shift
    trap - EXIT
    remove_tmp_file
done
