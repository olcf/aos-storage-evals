#!/bin/bash

# First check if ".default_answers" directory already exists
# If the directory ".default_answers" doesn't exist, create it
if [[ ! -d ".default_answers" ]]; then
    # Create directory ".default_answers"
    mkdir -p ".default_answers"
fi

# Function to store the last answer for a question
store_last_answer() {
    echo "$2" > ".default_answers/.last_answer_$1"
}

# Function to retrieve the last answer for a question
retrieve_last_answer() {
    if [ -f ".default_answers/.last_answer_$1" ]; then
        cat ".default_answers/.last_answer_$1"
    else
        echo ""
    fi
}

# Help function
help() {
    echo "Create sub-directory tree in AOS repo"
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  experiments    Perform experiments"
    echo "  platforms      Configure platforms"
    echo "  scripts        Execute scripts"
    echo "  source         Source files"
    echo
    echo "  find_subdirs   Display all sub-trees <dir name>"
    echo "  delete_dir     Delete \"rm -rf\" <dir name>"
    echo
    exit 0
}

# find . -type d -name rigel -exec rm -rf {} +
# Find and delete sub-trees of a directory name
delete_sub-tree() {
    echo "Enter the directory name that shoule be deleted."
    read -rp "dir_name: " dir_name
    if [[ "${dir_name}" == "" ]]; then
        echo "Usage: delete_dir <dir name>"
        exit 1
    fi

    echo
    # Use find command to generate the output lines
    find_output=$(find . -type d -name "$dir_name")
    if [[ "${find_output}" == "" ]]; then
        echo "No \"${dir_name}\" directory has been found!"
    else
        echo "The following sub-trees have been found:"
        echo "${find_output}"
    fi
    echo

    echo "Do you want to delete all \"${dir_name}\" subdirectories and files in them?"
    echo "WARNING --- All directories '$dir_name' and files in them will be deleted!"
    read -rp "WARNING ---Do you want to continue? [Yes/No]: " answer
    case ${answer:0:1} in
        yes|Yes|YES)
            find . -type d -name "${dir_name}" -exec rm -rf {} +
            ;;
        y|Y)
            echo "If you really want to delete all \"${dir_name}\" subdirectories and files in them, please type \"Yes\" or \"yes\""
            ;;
        *)
            echo "Aborted."
            exit 1
            ;;
    esac

    # Initialize the base_path variable
    sub_tree_base=""
    old_sub_tree_base=""
    current_dir="$(pwd)"

    # Read and process each directory path
    while IFS= read -r line; do
        # Remove leading dot and slash
        line=${line#./}  # Remove leading dot
        line=${line#/}   # Remove leading slash

        path_base=""
        IFS='/' read -r -a sub_tree_array <<< "$line"
        for element in "${sub_tree_array[@]}"; do
            # Append the element to the path_base
            if [[ "${element}" != "${dir_name}" ]]; then
                # If the array element contains a white space insert "\ "
                # element=${element//" "/"\\ "}
                if [[ "${path_base}" == "" ]]; then
                    path_base="${element}"
                else
                    path_base="${path_base}/${element}"
                fi
            fi
        done

        if [[ "${path_base}" == "${old_sub_tree_base}" ]]; then
            continue
        fi
        old_sub_tree_base="${path_base}"

        current_dir="$(pwd)"
        cd "$path_base"
        pwd
        rm -rf "${dir_name}"
        cd "$current_dir"
    done <<< "$find_output"
    echo "All instances of \"${dir_name}\" directory have been deleted!"
    echo "rm -rf \"${dir_name}\" "

    exit 0
}

# Find and display sub-trees of a directory name
find_sub-trees() {
    echo "Enter the directory name."
    read -rp "dir_name: " dir_name
    echo

    # Use find command to generate the output lines
    find_output=$(find . -type d -name "$dir_name")
    if [[ "${find_output}" == "" ]]; then
        echo "No \"${dir_name}\" directory has been found!"
    else
        echo "The following sub-trees have been found:"
        echo "${find_output}"
    fi
    echo

    # Initialize the base_path variable
    sub_tree_base=""
    old_sub_tree_base=""
    current_dir="$(pwd)"

    # Read and process each directory path
    while IFS= read -r line; do
        # Remove leading dot and slash
        line=${line#./}  # Remove leading dot
        line=${line#/}   # Remove leading slash

        path_base=""
        IFS='/' read -r -a sub_tree_array <<< "$line"
        for element in "${sub_tree_array[@]}"; do
            # Append the element to the path_base
            if [[ "${element}" != "${dir_name}" ]]; then
                # If the array element contains a white space insert "\ "
                # element=${element//" "/"\\ "}
                if [[ "${path_base}" == "" ]]; then
                    path_base="${element}"
                else
                    path_base="${path_base}/${element}"
                fi
            fi
        done

        if [[ "${path_base}" == "${old_sub_tree_base}" ]]; then
            continue
        fi
        old_sub_tree_base="${path_base}"

        current_dir="$(pwd)"
        cd "$path_base"
        pwd
        tree -C $dir_name
        echo
        cd "$current_dir"
    done <<< "$find_output"

    exit 0
}

# Check if a directory exists and warn the user
check_directory() {
    if [ -d "$1" ]; then
        read -rp "Directory '$1' already exists. Do you want to continue? [y/N]: " answer
        case ${answer:0:1} in
            y|Y)
                ;;
            *)
                echo "Aborted."
                exit 1
                ;;
        esac
    fi
}

# Experiments function
experiments() {
    echo "Enter parameters for 'experiments':"
    exp_name=$(retrieve_last_answer "exp_name")
    test_name=$(retrieve_last_answer "test_name")
    client_platform_name=$(retrieve_last_answer "client_platform_name")
    server_platform_name=$(retrieve_last_answer "server_platform_name")

    read -rp "exp_name [$exp_name]: " new_exp_name
    read -rp "test_name [$test_name]: " new_test_name
    read -rp "client_platform_name [$client_platform_name]: " new_client_platform_name
    read -rp "server_platform_name [$server_platform_name]: " new_server_platform_name

    exp_name=${new_exp_name:-$exp_name}
    test_name=${new_test_name:-$test_name}
    client_platform_name=${new_client_platform_name:-$client_platform_name}
    server_platform_name=${new_server_platform_name:-$server_platform_name}

    store_last_answer "exp_name" "$exp_name"
    store_last_answer "test_name" "$test_name"
    store_last_answer "client_platform_name" "$client_platform_name"
    store_last_answer "server_platform_name" "$server_platform_name"

    # Check if directories exist and warn the user
    check_directory "experiments/$exp_name"
    check_directory "experiments/$exp_name/$test_name"
    check_directory "experiments/$exp_name/$test_name/scripts"
    check_directory "experiments/$exp_name/$test_name/scripts/analysis"
    check_directory "experiments/$exp_name/$test_name/scripts/config/client/$client_platform_name"
    check_directory "experiments/$exp_name/$test_name/scripts/config/server/$server_platform_name"
    check_directory "experiments/$exp_name/$test_name/scripts/config/run"
    check_directory "experiments/$exp_name/$test_name/results/$server_platform_name/$client_platform_name/raw"
    check_directory "experiments/$exp_name/$test_name/results/$server_platform_name/$client_platform_name/processed"
    check_directory "experiments/$exp_name/scripts/analysis"
    check_directory "experiments/$exp_name/scripts/config"
    check_directory "experiments/$exp_name/scripts/config/client/$client_platform_name"
    check_directory "experiments/$exp_name/scripts/config/server/$server_platform_name"
    check_directory "experiments/$exp_name/scripts/run"
    check_directory "experiments/$exp_name/results/$server_platform_name"

    # Create directory structure
    mkdir -p "experiments/$exp_name/description"
    mkdir -p "experiments/$exp_name/$test_name/scripts"
    mkdir -p "experiments/$exp_name/$test_name/scripts/analysis"
    mkdir -p "experiments/$exp_name/$test_name/scripts/config/client/$client_platform_name"
    mkdir -p "experiments/$exp_name/$test_name/scripts/config/server/$server_platform_name"
    mkdir -p "experiments/$exp_name/$test_name/scripts/config/run"
    mkdir -p "experiments/$exp_name/$test_name/results/$server_platform_name/$client_platform_name/raw"
    mkdir -p "experiments/$exp_name/$test_name/results/$server_platform_name/$client_platform_name/processed"
    mkdir -p "experiments/$exp_name/scripts/analysis"
    mkdir -p "experiments/$exp_name/scripts/config"
    mkdir -p "experiments/$exp_name/scripts/config/client/$client_platform_name"
    mkdir -p "experiments/$exp_name/scripts/config/server/$server_platform_name"
    mkdir -p "experiments/$exp_name/scripts/run"
    mkdir -p "experiments/$exp_name/results/$server_platform_name"
    return 0
}

# Platforms function
platforms() {
    echo "Enter parameters for 'platforms':"
    client_platforms_name=$(retrieve_last_answer "client_platforms_name")
    server_platforms_name=$(retrieve_last_answer "server_platforms_name")

    read -rp "client_platforms_name [$client_platforms_name]: " new_client_platforms_name
    read -rp "server_platforms_name [$server_platforms_name]: " new_server_platforms_name

    client_platforms_name=${new_client_platforms_name:-$client_platforms_name}
    server_platforms_name=${new_server_platforms_name:-$server_platforms_name}

    store_last_answer "client_platforms_name" "$client_platforms_name"
    store_last_answer "server_platforms_name" "$server_platforms_name"

    # Check if directories exist and warn the user
    check_directory "platforms/client/$client_platforms_name"
    check_directory "platforms/server/$server_platforms_name"

    # Create directory structure
    mkdir -p "platforms/client/$client_platforms_name"
    mkdir -p "platforms/server/$server_platforms_name"
    return 0
}

# Scripts function
scripts() {
    # Check if directories exist and warn the user
    check_directory "scripts/configuration"
    check_directory "scripts/experiment"
    check_directory "scripts/installation"

    # Create directory structure
    mkdir -p "scripts/configuration"
    mkdir -p "scripts/experiment"
    mkdir -p "scripts/installation"
    return 0
}

# Source function
source() {
    echo "Enter parameters for 'source':"
    benchmark_name=$(retrieve_last_answer "benchmark_name")
    benchmark_version=$(retrieve_last_answer "benchmark_version")
    app_name=$(retrieve_last_answer "app_name")

    read -rp "benchmark_name [$benchmark_name]: " new_benchmark_name
    read -rp "benchmark_version [$benchmark_version]: " new_benchmark_version
    read -rp "app_name [$app_name]: " new_app_name

    benchmark_name=${new_benchmark_name:-$benchmark_name}
    benchmark_version=${new_benchmark_version:-$benchmark_version}
    app_name=${new_app_name:-$app_name}

    store_last_answer "benchmark_name" "$benchmark_name"
    store_last_answer "benchmark_version" "$benchmark_version"
    store_last_answer "app_name" "$app_name"

    # Check if directories exist and warn the user
    check_directory "source/benchmarks/$benchmark_name"
    check_directory "source/benchmarks/$benchmark_name/$benchmark_version"
    check_directory "source/applications/$app_name"

    # Create directory structure
    mkdir -p "source/benchmarks/$benchmark_name/$benchmark_version"
    mkdir -p "source/applications/$app_name"
    return 0
}

# Check if no parameters are provided
if [ $# -eq 0 ]; then
    echo
    echo "No parameters provided."
    help
fi

# Process each parameter
for param in "$@"; do
    case $param in
        experiments)
            experiments
            ;;
        platforms)
            platforms
            ;;
        scripts)
            scripts
            ;;
        source)
            source
            ;;
        delete_dir)
            delete_sub-tree
            ;;
        find_subdirs)
            find_sub-trees
            ;;
        -h|--help)
            help
            ;;
        *)
            echo "Invalid parameter: $param"
            ;;
    esac
done

