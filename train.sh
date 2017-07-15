#!/usr/bin/env bash

CONFIG_PATH=/home/logan/Projects/cheeky-chatbot/config/train.config

validate_bash_version_above_3() {
    # check if $BASH_VERSION is set at all
    [ -z $BASH_VERSION ] && return 1

    # If it's set, check the version
    case $BASH_VERSION in 
        3.*) return 0 ;;
        4.*) return 0 ;;
        ?) return 1;; 
    esac
}

if ! validate_bash_version_above_3; then
    echo "Scripts requires bash version >= 3"
    exit 1
fi

usage() {
    printf "\n"
    echo "Usage $0 [-h] [-f]"
    echo "where  [-h] displays usage information"
    echo "where [-f] forces confirmation to all prompts"
    printf "\n";
    exit 1
}

read_args() {
    ARGS_SHIFT=1
    case $1 in 
        "-h") usage;;   
        "-f") FORCE_CONFIRM="y";;
        *)
        echo "Unexpected parameter $1."
        usage;
    esac
    return $ARGS_SHIFT
}

prompt_confirmation() {
    CONFIRMATION="n"
    if [ -z $2 ]
    then
        read -p "$1" CONFIRMATION
    else
        CONFIRMATION=$2
    fi
}

config_read_file() {
    (grep -E "^${2}=" -m 1 "${1}" 2>/dev/null || echo "VAR=__UNDEFINED__") | head -n 1 | cut -d '=' -f 2-;
}

config_get() {
    val="$(config_read_file "${CONFIG_PATH}" "${1}")";
    if [ "${val}" = "__UNDEFINED__" ]; then
        val="$(config_read_file config.cfg.defaults "${1}")";
    fi
    printf -- "%s" "${val}";
}

# read user input
while [ $# != 0 ]
do
    read_args $*
    NB_SHIFT=$?
    I=1
    while [[ $I -le $NB_SHIFT ]]
    do
        shift
        ((I = I + 1))
    done
done

PYTHON2_PATH="$(config_get PYTHON2_PATH)";
PYTHON3_PATH="$(config_get PYTHON3_PATH)";
FBCAP_PATH="$(config_get FBCAP_PATH)";
FACEBOOK_ARCHIVE_PATH="$(config_get FACEBOOK_ARCHIVE_PATH)";
FACEBOOK_STRUCTURED_OUTPUT_TYPE="$(config_get FACEBOOK_STRUCTURED_OUTPUT_TYPE)";
FACEBOOK_STRUCTURED_OUTFILE_PATH="$(config_get FACEBOOK_STRUCTURED_OUTFILE_PATH)";
PARSED_DATA_FORMAT="$(config_get PARSED_DATA_FORMAT)";
PARSED_DATA_PATH="$(config_get PARSED_DATA_PATH)";
TRAINED_MODELS_PATH="$(config_get TRAINED_MODELS_PATH)";

declare -a target_user_raw_strings="$(config_get TARGET_USER_RAW_STRINGS_ARRAY)";
declare -a sentence_lengths="$(config_get SENTENCE_LENGTHS_ARRAY)";

# PARSE UNSTRUCTURED FACEBOOK ARCHIVE DATA TO INTENDED STRUCTURE FORMAT

FACEBOOK_STRUCTURED_OUTFILE_DIR_PATH=$(dirname "${FACEBOOK_STRUCTURED_OUTFILE_PATH}")
mkdir -p $FACEBOOK_STRUCTURED_OUTFILE_DIR_PATH
if [ ! -f "$FACEBOOK_STRUCTURED_OUTFILE_PATH" ]; then
    $FBCAP_PATH "$FACEBOOK_ARCHIVE_PATH"/html/messages.htm -f "$FACEBOOK_STRUCTURED_OUTPUT_TYPE" > "$FACEBOOK_STRUCTURED_OUTFILE_PATH" --resolve
fi

# PARSE STRUCTURED FACEBOOK DATA FOR EACH USER TO REQUESTED TRAINABLE FORMAT

mkdir -p $PARSED_DATA_PATH

for target_user_raw_string in "${target_user_raw_strings[@]}"
do
    for sentence_length in "${sentence_lengths[@]}"
    do
        "$PYTHON2_PATH" python/fb_messages_parser.py parse_to_"$PARSED_DATA_FORMAT" -u "$target_user_raw_string" \
        -i "$FACEBOOK_STRUCTURED_OUTFILE_PATH" -o "$PARSED_DATA_PATH" -l "$sentence_length";
    done
done

printf "\n"
echo "Successfully parsed trainable data for all target users"

train_user_bots() {
    mkdir -p $TRAINED_MODELS_PATH
    MODEL_TRAINING_ROOT_DIR="$(config_get MODEL_TRAINING_ROOT_DIR)"
    TRAINABLE_MODEL_TAG_STR="$(config_get TRAINABLE_MODEL_TAG)"
    TRAINED_MODELS_ORIGINAL_DESTINATION="$(config_get TRAINED_MODELS_ORIGINAL_DESTINATION)"
    MODEL_TRAINING_EXECUTION_COMMAND="$(config_get MODEL_TRAINING_EXECUTION_COMMAND)"
    for target_user_raw_string in "${target_user_raw_strings[@]}"
    do
        for sentence_length in "${sentence_lengths[@]}"
        do
            formatted_target_user_str="$(echo "$target_user_raw_string" | tr '[:upper:]' '[:lower:]')"
            formatted_target_user_str="$(echo ${formatted_target_user_str// /_})"
            TRAINABLE_MODEL_TAG="$(eval "echo ${TRAINABLE_MODEL_TAG_STR}")"
            eval "${MODEL_TRAINING_EXECUTION_COMMAND}"
            cur_trained_model_destination="$(eval "echo ${TRAINED_MODELS_ORIGINAL_DESTINATION}")"
            mv $cur_trained_model_destination $TRAINED_MODELS_PATH/
        done
    done
}

if [[ $CONFIRMATION =~ ^[Yy]$ ]]; then
    train_user_bots
else
    prompt_confirmation "Proceed to train bots for all target users (y/n)? " $FORCE_CONFIRM
    if [[ $CONFIRMATION =~ ^[Yy]$ ]]; then
        train_user_bots
    fi
    CONFIRMATION="n"
fi
