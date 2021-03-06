from fb_messages_parser import parse_to_deep_qa


def parse_to_deep_qa_args_parsing(subparsers):
    """ Parse fb message archive csv to deepQA format. """
    help_str = "Parse fb message archive csv to deepQA format."
    parser_t = subparsers.add_parser('parse_to_deep_qa', help=help_str)
    help_str = 'Facebook target user on which to parse trainable conversations\n'
    parser_t.add_argument('-u', '--user', required=False, type=str,
                          dest='target_user_name', action='store',
                          default="", help=help_str)
    help_str = 'Path for structured facebook data input\n'
    parser_t.add_argument('-i', '--input', required=False, type=str,
                          dest='structured_facebook_data_infile_path', action='store',
                          default="", help=help_str)
    help_str = 'Path for parsed facebook data output\n'
    parser_t.add_argument('-o', '--output', required=False, type=str,
                          dest='parsed_facebook_data_output_path', action='store',
                          default="", help=help_str)
    help_str = 'Sentence length (in # words) for which to extract messages'
    parser_t.add_argument('-l', '--sentence_length', required=False, type=int,
                          dest='allowed_words_per_sentence', action='store',
                          default=0, help=help_str)
    parser_t.set_defaults(func=parse_to_deep_qa)


def arg_parsing():
    """ Parse the subcommand along with its arguments. """

    description = '''
    Parse fb message archive csv to a trainable format.
    '''
    import argparse
    parser = argparse.ArgumentParser(
        description=description,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    subparsers = parser.add_subparsers(
        help='Parse fb message archive csv to a trainable format',
        title='SubCommands', description='Valid SubCommands')
    parse_to_deep_qa_args_parsing(subparsers)
    argu = parser.parse_args()
    return argu
