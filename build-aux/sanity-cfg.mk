## Without the cast to (void *), we get a warning about discarded
## type qualifiers, so the cast is preferred.
exclude_file_name_regexp--sc_cast_of_argument_to_free = ^ext/yaml/emitter.c$$

EXTRA_DIST += build-aux/sanity-cfg.mk
