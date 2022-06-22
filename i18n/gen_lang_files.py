#!/usr/bin/env python3
import csv
import glob
import os
import logging
import json


class Translation:
    def __init__(self, translation_tuple):
        self.key, self.translation = translation_tuple

    def __repr__(self):
        return f'{self.key} => {self.translation}'

    def get_key(self):
        return self.key

    def get_translation(self):
        return self.translation


def parse_language_csv(filename):
    with open(filename, 'r') as file:
        return [Translation(t) for t in csv.reader(file, delimiter=',', quotechar='"')]


def generate_mobile_translations(lang, translations):
    with open(os.path.join('..', 'mobile', 'assets', 'i18n', f'{lang}.json'), 'w') as file:
        translations_obj = {}
        for t in translations:
            translations_obj[t.get_key()] = t.get_translation()

        file.write(json.dumps(translations_obj, indent=2))


def generate_language_files():
    for file in glob.glob(os.path.join('translations', '*.csv'), recursive=False):
        language_code = os.path.basename(file)[:-4]
        logging.info('Language Code: %s', language_code)

        translations = parse_language_csv(file)
        logging.debug(translations)

        generate_mobile_translations(language_code, translations)


if __name__ == '__main__':
    logging.basicConfig(format='%(levelname)s : %(message)s', level=logging.DEBUG)
    generate_language_files()