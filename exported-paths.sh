register_path() {
    # Usage:
    #   register_path <env_var_name> <provided_path> [after]
    #
    # Registers a path in a PATH-like environment variable.
    # The provided_path is prepended unless the "after"
    # argument is provided, in which case it's appended.
    #
    # Example:
    #   register_path LD_LIBRARY_PATH /an/important/path
    #   register_path LD_LIBRARY_PATH /a/less/important/path after
    #
    local separator=":"
    local env_var_name="$1"
    local provided_path="$2"
    local mode="prepend"
    if [[ $# -ge 3 ]]; then
        if [[ "$3" == "after" ]]; then
            mode="append"
        else
            echo "register_path: WARNING: Unexpected arguments: $@"
        fi
    fi

    # If the variable is not defined at this point,
    # or it's blank, just set it to the provided path.
    if [[ "${!env_var_name:-}" == "" ]]; then
        export "$env_var_name=$provided_path"
        return
    fi

    local wrapped_paths="$separator${!env_var_name}$separator"
    # Remove any existing instances of provided_path within the path list
    wrapped_paths="${wrapped_paths//$separator$provided_path$separator/$separator}"
    # Add the wanted path on the desired side of the list
    if [[ "$mode" == "prepend" ]]; then
        wrapped_paths=":$provided_path$wrapped_paths"
    else
        wrapped_paths="$wrapped_paths$provided_path:"
    fi
    # Remove the wrapping separators
    new_paths="${wrapped_paths#$separator}"
    new_paths="${new_paths%$separator}"
    # Export the clean version
    export "$env_var_name=$new_paths"
}

# To run the unit test, this script should be executed (not sourced) and receive
# the --unit-test argument.
if ! (return 0 2>/dev/null) && [[ $# -gt 0 ]] && [[ $1 == "--unit-test" ]]; then
    assert_var() {
        local env_var="$1"
        local expected="$2"
        local actual="${!env_var}"
        if [[ "$actual" != "$expected" ]]; then
            echo "Test failed: $test_name"
            echo "  \$$env_var expected: $expected"
            echo "  \$$env_var   actual: $actual"
            exit 1
        fi
    }

    test_name="Registering the first path for a variable"
    register_path TEST_VAR "/test1/bin"
    assert_var TEST_VAR "/test1/bin"

    test_name="Appending to the beginning of a variable"
    register_path TEST_VAR "/test2/bin"
    assert_var TEST_VAR "/test2/bin:/test1/bin"

    test_name="Appending to the end of a variable"
    register_path TEST_VAR "/test3/bin" after
    assert_var TEST_VAR "/test2/bin:/test1/bin:/test3/bin"

    echo "Tests succeeded."
    exit 0
fi

DOTFILES_DIR=$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd )

# Later entries have priority

register_path PATH "$DOTFILES_DIR/bin" after
register_path PATH "$DOTFILES_DIR/bin-override"

register_path PATH "$HOME/webkit-scripts"
register_path PATH "/webkit/Tools/Scripts"
register_path PATH "$HOME/Apps/Bento4-SDK-1-5-1-621.x86_64-unknown-linux/bin"

register_path PATH "$HOME/Apps/nrf-command-line-tools-10.17.3_linux-amd64/nrf-command-line-tools/bin"
register_path PATH "$HOME/Apps/JLink_Linux_V766a_x86_64"
register_path PATH "$HOME/.platformio/penv/bin" after
register_path LD_LIBRARY_PATH "$HOME/Apps/jlink-dlls"
register_path PATH "$HOME/Apps/indent-2.2.12/build/bin"
register_path PATH "$HOME/Apps/picotool/build"

register_path PATH "$HOME/.local/bin"
register_path PATH "$HOME/bin"
register_path PATH "$HOME/Apps/bin"

# Rust setup in a synchronized directory
export PICO_SDK_PATH="$HOME/Apps/pico-sdk"
export CARGO_HOME="$HOME/Apps/rust/cargo"
export RUSTUP_HOME="$HOME/Apps/rust/rustup"
register_path PATH "$HOME/Apps/rust/cargo/bin"
export CONDA_ROOT="$HOME/Apps/conda-root"

if [ -f ~/.ghcup/env ]; then
    . ~/.ghcup/env
fi
